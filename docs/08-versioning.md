# CRD 버전 관리

## CRD 버전 관리란?

**CRD 버전 관리**는 Kubernetes API의 핵심 개념으로, API 스키마의 변경사항을 관리하고 하위 호환성을 보장하는 방법입니다.

[검증 및 기본값 설정](./07-validation-defaulting.md)에서 CRD의 데이터 무결성을 보장했으니, 이제 CRD의 장기적인 발전과 관리가 가능한 버전 관리 시스템을 구현해보겠습니다.

## 버전 관리의 중요성

### 1. 하위 호환성
- 기존 클라이언트가 계속 작동하도록 보장
- API 변경사항을 안전하게 도입
- 점진적인 마이그레이션 지원

### 2. API 안정성
- 프로덕션 환경에서의 안정성 보장
- 예측 가능한 API 동작
- 장기간 지원 가능

## 버전 관리 전략

### 1. 버전 명명 규칙

```
v1alpha1  # 알파 버전 (실험적, 불안정)
v1beta1   # 베타 버전 (안정화 중, 일부 변경 가능)
v1        # 안정 버전 (안정적, 하위 호환성 보장)
```

### 2. 버전 전환 단계

```
v1alpha1 → v1beta1 → v1
    ↓         ↓       ↓
  실험적   안정화 중   안정
```

## 다중 버전 CRD 구현

### 1. CRD 정의

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: websites.example.com
spec:
  group: example.com
  names:
    plural: websites
    singular: website
    kind: Website
    shortNames: ["ws"]
  scope: Namespaced
  versions:
    # v1 (안정 버전)
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required: ["url", "replicas"]
              properties:
                url:
                  type: string
                  pattern: '^https?://.+'
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 100
                  default: 3
                image:
                  type: string
                  default: "nginx:latest"
                port:
                  type: integer
                  minimum: 1
                  maximum: 65535
                  default: 80
                environment:
                  type: string
                  enum: ["development", "staging", "production"]
                  default: "development"
                resources:
                  type: object
                  properties:
                    requests:
                      type: object
                      properties:
                        cpu:
                          type: string
                          pattern: '^[0-9]+m?$'
                        memory:
                          type: string
                          pattern: '^[0-9]+[KMGTPEZYkmgtpezy]i?$'
                    limits:
                      type: object
                      properties:
                        cpu:
                          type: string
                          pattern: '^[0-9]+m?$'
                        memory:
                          type: string
                          pattern: '^[0-9]+[KMGTPEZYkmgtpezy]i?$'
      subresources:
        status: {}
      additionalPrinterColumns:
        - name: URL
          type: string
          jsonPath: .spec.url
        - name: Replicas
          type: integer
          jsonPath: .spec.replicas
        - name: Available
          type: integer
          jsonPath: .status.availableReplicas
        - name: Age
          type: date
          jsonPath: .metadata.creationTimestamp
    
    # v1beta1 (베타 버전 - 하위 호환성 유지)
    - name: v1beta1
      served: true
      storage: false
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required: ["url", "replicas"]
              properties:
                url:
                  type: string
                  pattern: '^https?://.+'
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 100
                  default: 3
                image:
                  type: string
                  default: "nginx:latest"
                port:
                  type: integer
                  minimum: 1
                  maximum: 65535
                  default: 80
                environment:
                  type: string
                  enum: ["development", "staging", "production"]
                  default: "development"
                # v1beta1에서 제거된 필드들
                oldField:
                  type: string
                  deprecated: true
                  deprecationWarning: "이 필드는 v1에서 제거되었습니다. 대신 newField를 사용하세요."
      subresources:
        status: {}
      additionalPrinterColumns:
        - name: URL
          type: string
          jsonPath: .spec.url
        - name: Replicas
          type: integer
          jsonPath: .spec.replicas
        - name: Age
          type: date
          jsonPath: .metadata.creationTimestamp
    
    # v1alpha1 (알파 버전 - 더 이상 지원되지 않음)
    - name: v1alpha1
      served: false  # 더 이상 서비스되지 않음
      storage: false
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required: ["url", "replicas"]
              properties:
                url:
                  type: string
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 100
                image:
                  type: string
                port:
                  type: integer
                # v1alpha1에서만 사용되던 필드들
                deprecatedField:
                  type: string
```

### 2. Go 타입 정의

#### v1 타입

```go
// api/v1/website_types.go
package v1

import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// WebsiteSpec은 Website의 원하는 상태를 정의합니다
type WebsiteSpec struct {
    // URL은 웹사이트의 URL입니다
    // +kubebuilder:validation:Required
    // +kubebuilder:validation:Pattern=`^https?://`
    URL string `json:"url"`
    
    // Replicas는 배포할 복제본 수입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=100
    // +kubebuilder:default=3
    Replicas int32 `json:"replicas"`
    
    // Image는 사용할 Docker 이미지입니다
    // +kubebuilder:default="nginx:latest"
    Image string `json:"image,omitempty"`
    
    // Port는 컨테이너 포트입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=65535
    // +kubebuilder:default=80
    Port int32 `json:"port,omitempty"`
    
    // Environment는 배포 환경입니다
    // +kubebuilder:validation:Enum=development;staging;production
    // +kubebuilder:default=development
    Environment string `json:"environment,omitempty"`
    
    // Resources는 리소스 요구사항입니다
    Resources *ResourceRequirements `json:"resources,omitempty"`
}

// WebsiteStatus는 Website의 현재 상태를 정의합니다
type WebsiteStatus struct {
    // AvailableReplicas는 사용 가능한 복제본 수입니다
    AvailableReplicas int32 `json:"availableReplicas,omitempty"`
    
    // Conditions는 현재 상태 조건들입니다
    Conditions []metav1.Condition `json:"conditions,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
//+kubebuilder:printcolumn:name="URL",type="string",JSONPath=".spec.url"
//+kubebuilder:printcolumn:name="Replicas",type="integer",JSONPath=".spec.replicas"
//+kubebuilder:printcolumn:name="Available",type="integer",JSONPath=".status.availableReplicas"
//+kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"

// Website은 웹사이트 리소스를 정의합니다
type Website struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`
    
    Spec   WebsiteSpec   `json:"spec,omitempty"`
    Status WebsiteStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// WebsiteList는 Website 리소스들의 컬렉션을 포함합니다
type WebsiteList struct {
    metav1.TypeMeta `json:",inline"`
    metav1.ListMeta `json:"metadata,omitempty"`
    Items           []Website `json:"items"`
}

func init() {
    SchemeBuilder.Register(&Website{}, &WebsiteList{})
}
```

#### v1beta1 타입

```go
// api/v1beta1/website_types.go
package v1beta1

import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// WebsiteSpec은 Website의 원하는 상태를 정의합니다
type WebsiteSpec struct {
    // URL은 웹사이트의 URL입니다
    // +kubebuilder:validation:Required
    // +kubebuilder:validation:Pattern=`^https?://`
    URL string `json:"url"`
    
    // Replicas는 배포할 복제본 수입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=100
    // +kubebuilder:default=3
    Replicas int32 `json:"replicas"`
    
    // Image는 사용할 Docker 이미지입니다
    // +kubebuilder:default="nginx:latest"
    Image string `json:"image,omitempty"`
    
    // Port는 컨테이너 포트입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=65535
    // +kubebuilder:default=80
    Port int32 `json:"port,omitempty"`
    
    // Environment는 배포 환경입니다
    // +kubebuilder:validation:Enum=development;staging;production
    // +kubebuilder:default=development
    Environment string `json:"environment,omitempty"`
    
    // OldField는 v1beta1에서만 사용되는 필드입니다 (v1에서 제거됨)
    // +kubebuilder:deprecated
    // +kubebuilder:deprecationWarning="이 필드는 v1에서 제거되었습니다. 대신 newField를 사용하세요."
    OldField string `json:"oldField,omitempty"`
}

// WebsiteStatus는 Website의 현재 상태를 정의합니다
type WebsiteStatus struct {
    // AvailableReplicas는 사용 가능한 복제본 수입니다
    AvailableReplicas int32 `json:"availableReplicas,omitempty"`
    
    // Conditions는 현재 상태 조건들입니다
    Conditions []metav1.Condition `json:"conditions,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
//+kubebuilder:printcolumn:name="URL",type="string",JSONPath=".spec.url"
//+kubebuilder:printcolumn:name="Replicas",type="integer",JSONPath=".spec.replicas"
//+kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"

// Website은 웹사이트 리소스를 정의합니다
type Website struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`
    
    Spec   WebsiteSpec   `json:"spec,omitempty"`
    Status WebsiteStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// WebsiteList는 Website 리소스들의 컬렉션을 포함합니다
type WebsiteList struct {
    metav1.TypeMeta `json:",inline"`
    metav1.ListMeta `json:"metadata,omitempty"`
    Items           []Website `json:"items"`
}

func init() {
    SchemeBuilder.Register(&Website{}, &WebsiteList{})
}
```

## 버전 변환 (Conversion)

### 1. Conversion Webhook 구현

```go
// api/v1/website_conversion.go
package v1

import (
    "unsafe"
    
    v1beta1 "github.com/username/my-crd-project/api/v1beta1"
    "k8s.io/apimachinery/pkg/conversion"
    "k8s.io/apimachinery/pkg/runtime"
)

// ConvertTo는 v1에서 v1beta1로 변환합니다
func (in *Website) ConvertTo(dst runtime.Object) error {
    beta1Dst := dst.(*v1beta1.Website)
    return in.convertTo(beta1Dst)
}

// ConvertFrom은 v1beta1에서 v1로 변환합니다
func (in *Website) ConvertFrom(src runtime.Object) error {
    beta1Src := src.(*v1beta1.Website)
    return in.convertFrom(beta1Src)
}

// convertTo는 v1에서 v1beta1로 변환합니다
func (in *Website) convertTo(out *v1beta1.Website) error {
    // 메타데이터 복사
    out.ObjectMeta = in.ObjectMeta
    
    // Spec 변환
    if err := in.convertSpecTo(&out.Spec); err != nil {
        return err
    }
    
    // Status 변환
    if err := in.convertStatusTo(&out.Status); err != nil {
        return err
    }
    
    return nil
}

// convertFrom은 v1beta1에서 v1로 변환합니다
func (in *Website) convertFrom(out *v1beta1.Website) error {
    // 메타데이터 복사
    in.ObjectMeta = out.ObjectMeta
    
    // Spec 변환
    if err := in.convertSpecFrom(&out.Spec); err != nil {
        return err
    }
    
    // Status 변환
    if err := in.convertStatusFrom(&out.Status); err != nil {
        return err
    }
    
    return nil
}

// convertSpecTo는 Spec을 v1에서 v1beta1로 변환합니다
func (in *Website) convertSpecTo(out *v1beta1.WebsiteSpec) error {
    // 기본 필드 복사
    out.URL = in.Spec.URL
    out.Replicas = in.Spec.Replicas
    out.Image = in.Spec.Image
    out.Port = in.Spec.Port
    out.Environment = in.Spec.Environment
    
    // v1beta1에서만 사용되는 필드 설정
    // v1에서는 이 필드가 없으므로 기본값 설정
    out.OldField = ""
    
    return nil
}

// convertSpecFrom은 Spec을 v1beta1에서 v1로 변환합니다
func (in *Website) convertSpecFrom(out *v1beta1.WebsiteSpec) error {
    // 기본 필드 복사
    in.Spec.URL = out.URL
    in.Spec.Replicas = out.Replicas
    in.Spec.Image = out.Image
    in.Spec.Port = out.Port
    in.Spec.Environment = out.Environment
    
    // v1beta1의 OldField를 v1의 적절한 필드로 변환
    // 여기서는 단순히 무시하지만, 필요에 따라 변환 로직 추가 가능
    if out.OldField != "" {
        // OldField 값을 적절히 처리
        // 예: 로그 기록, 경고 등
    }
    
    return nil
}

// convertStatusTo는 Status를 v1에서 v1beta1로 변환합니다
func (in *Website) convertStatusTo(out *v1beta1.WebsiteStatus) error {
    out.AvailableReplicas = in.Status.AvailableReplicas
    out.Conditions = in.Status.Conditions
    return nil
}

// convertStatusFrom은 Status를 v1beta1에서 v1로 변환합니다
func (in *Website) convertStatusFrom(out *v1beta1.WebsiteStatus) error {
    in.Status.AvailableReplicas = out.AvailableReplicas
    in.Status.Conditions = out.Conditions
    return nil
}
```

### 2. Conversion Webhook 설정

```yaml
# config/webhook/manifests.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: website-validating-webhook-configuration
webhooks:
- name: vwebsite.kb.io
  rules:
  - apiGroups: ["mygroup.example.com"]
    apiVersions: ["v1", "v1beta1"]
    operations: ["CREATE", "UPDATE"]
    resources: ["websites"]
    scope: "Namespaced"
  clientConfig:
    service:
      namespace: my-crd-project-system
      name: webhook-service
      path: /validate-mygroup-example-com-v1-website
      port: 443
  admissionReviewVersions: ["v1"]
  sideEffects: None
  failurePolicy: Fail
---
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: website-mutating-webhook-configuration
webhooks:
- name: mwebsite.kb.io
  rules:
  - apiGroups: ["mygroup.example.com"]
    apiVersions: ["v1", "v1beta1"]
    operations: ["CREATE", "UPDATE"]
    resources: ["websites"]
    scope: "Namespaced"
  clientConfig:
    service:
      namespace: my-crd-project-system
      name: webhook-service
      path: /mutate-mygroup-example-com-v1-website
      port: 443
  admissionReviewVersions: ["v1"]
  sideEffects: None
  failurePolicy: Fail
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: websites.example.com
spec:
  group: example.com
  names:
    plural: websites
    singular: website
    kind: Website
    shortNames: ["ws"]
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          # v1 스키마 정의
      subresources:
        status: {}
      additionalPrinterColumns:
        # v1 컬럼 정의
    - name: v1beta1
      served: true
      storage: false
      schema:
        openAPIV3Schema:
          # v1beta1 스키마 정의
      subresources:
        status: {}
      additionalPrinterColumns:
        # v1beta1 컬럼 정의
  conversion:
    strategy: Webhook
    webhook:
      clientConfig:
        service:
          namespace: my-crd-project-system
          name: webhook-service
          path: /convert
          port: 443
      conversionReviewVersions: ["v1"]
```

## 마이그레이션 전략

### 1. 점진적 마이그레이션

```bash
# 1단계: 새 버전 배포 (기존 버전과 함께)
kubectl apply -f config/crd/patches/webhook_in_websites.yaml

# 2단계: 기존 리소스를 새 버전으로 변환
kubectl get websites --all-namespaces -o yaml | \
  sed 's/apiVersion: mygroup.example.com\/v1beta1/apiVersion: mygroup.example.com\/v1/g' | \
  kubectl apply -f -

# 3단계: 기존 버전 서비스 중단
kubectl patch crd websites.example.com --type='merge' \
  -p='{"spec":{"versions":[{"name":"v1beta1","served":false}]}}'

# 4단계: 기존 버전 완전 제거
kubectl patch crd websites.example.com --type='merge' \
  -p='{"spec":{"versions":[{"name":"v1beta1","served":false,"storage":false}]}}'
```

### 2. 자동 마이그레이션 스크립트

```bash
#!/bin/bash
# migrate-websites.sh

NAMESPACE="default"
CRD_NAME="websites.example.com"
OLD_VERSION="v1beta1"
NEW_VERSION="v1"

echo "Website 리소스를 $OLD_VERSION에서 $NEW_VERSION으로 마이그레이션합니다..."

# 모든 네임스페이스의 Website 리소스 조회
NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

for ns in $NAMESPACES; do
    echo "네임스페이스: $ns"
    
    # 해당 네임스페이스의 Website 리소스 조회
    WEBSITES=$(kubectl get websites -n $ns -o name 2>/dev/null)
    
    if [ -n "$WEBSITES" ]; then
        for website in $WEBSITES; do
            echo "  마이그레이션 중: $website"
            
            # 리소스를 새 버전으로 변환하여 적용
            kubectl get $website -n $ns -o yaml | \
                sed "s/apiVersion: mygroup.example.com\/$OLD_VERSION/apiVersion: mygroup.example.com\/$NEW_VERSION/g" | \
                kubectl apply -f -
            
            if [ $? -eq 0 ]; then
                echo "    성공: $website"
            else
                echo "    실패: $website"
            fi
        done
    else
        echo "  Website 리소스가 없습니다"
    fi
done

echo "마이그레이션이 완료되었습니다."
```

### 3. 검증 스크립트

```bash
#!/bin/bash
# verify-migration.sh

CRD_NAME="websites.example.com"
OLD_VERSION="v1beta1"
NEW_VERSION="v1"

echo "마이그레이션 검증을 시작합니다..."

# 1. CRD 상태 확인
echo "1. CRD 상태 확인..."
kubectl get crd $CRD_NAME

# 2. 버전별 서비스 상태 확인
echo "2. 버전별 서비스 상태 확인..."
kubectl get crd $CRD_NAME -o jsonpath='{.spec.versions[*].name}' | tr ' ' '\n' | while read version; do
    served=$(kubectl get crd $CRD_NAME -o jsonpath="{.spec.versions[?(@.name=='$version')].served}")
    storage=$(kubectl get crd $CRD_NAME -o jsonpath="{.spec.versions[?(@.name=='$version')].storage}")
    echo "  $version: served=$served, storage=$storage"
done

# 3. 리소스 버전 확인
echo "3. 리소스 버전 확인..."
kubectl get websites --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.apiVersion}{"\n"}{end}' | sort

# 4. 변환 테스트
echo "4. 변환 테스트..."
kubectl create -f - <<EOF
apiVersion: mygroup.example.com/v1beta1
kind: Website
metadata:
  name: test-migration
spec:
  url: "https://example.com"
  replicas: 3
EOF

# 잠시 대기
sleep 5

# v1으로 조회 시도
kubectl get website test-migration -o yaml | grep apiVersion

# 테스트 리소스 정리
kubectl delete website test-migration

echo "검증이 완료되었습니다."
```

## 버전 관리 모범 사례

### 1. 버전 전환 가이드

```markdown
# Website CRD 버전 전환 가이드

## 개요
Website CRD가 v1beta1에서 v1으로 전환됩니다.

## 변경사항

### 추가된 기능
- 리소스 요구사항 지원
- 고급 검증 규칙
- 향상된 상태 관리

### 제거된 기능
- `oldField` 필드 (v1beta1에서 deprecated)
- 일부 레거시 설정 옵션

### 변경된 기능
- 환경별 기본값 설정
- 보안 정책 강화

## 마이그레이션 단계

### 1단계: 준비 (v1beta1 + v1)
- 새 버전 배포
- 변환 웹훅 활성화
- 테스트 및 검증

### 2단계: 전환 (v1beta1 + v1)
- 기존 리소스를 새 버전으로 변환
- 클라이언트 업데이트
- 모니터링 및 검증

### 3단계: 정리 (v1만)
- 기존 버전 서비스 중단
- 기존 버전 완전 제거
- 문서 및 예제 업데이트

## 클라이언트 업데이트

### kubectl
```bash
# 기존 명령어는 그대로 작동
kubectl get websites
kubectl describe website my-website

# 새 기능 사용
kubectl get websites -o custom-columns=NAME:.metadata.name,RESOURCES:.spec.resources
```

### Go 클라이언트
```go
// 기존 코드
import v1beta1 "github.com/username/my-crd-project/api/v1beta1"

// 새 코드
import v1 "github.com/username/my-crd-project/api/v1"

// 타입 변경
var website v1.Website
```

## 문제 해결

### 일반적인 문제들
1. **변환 실패**: 변환 웹훅 상태 확인
2. **API 호환성**: 클라이언트 버전 확인
3. **데이터 손실**: 백업 및 검증 수행

### 지원
- GitHub Issues: [링크]
- 문서: [링크]
- 예제: [링크]
```

## 다음 단계

축하합니다! CRD 버전 관리에 대한 모든 내용을 학습했습니다. 이제 전체 CRD 개발 생명주기를 완성했습니다:

### 🎯 **학습 완료 내용**
1. ✅ **환경 설정** - 개발 도구 및 Kubernetes 클러스터 구축
2. ✅ **첫 번째 CRD** - 기본 CRD 생성 및 배포
3. ✅ **kubebuilder 활용** - 프레임워크를 사용한 효율적인 개발
4. ✅ **컨트롤러 개발** - CRD의 비즈니스 로직 구현
5. ✅ **웹훅 구현** - 데이터 검증 및 변환
6. ✅ **검증 및 기본값** - 스키마 검증 및 자동 기본값 설정
7. ✅ **버전 관리** - CRD의 장기적인 발전과 관리

### 🚀 **다음 단계 제안**
1. **실제 프로젝트에서 버전 관리 적용**
2. **자동화된 마이그레이션 도구 개발**
3. **모니터링 및 알림 시스템 구축**
4. **프로덕션 환경에서의 CRD 운영**

이제 Kubernetes CRD 개발의 전문가가 되었습니다! 🎉

## 문제 해결

### 일반적인 문제들

1. **변환 실패**: 변환 웹훅 설정 및 로그 확인
2. **버전 충돌**: API 그룹 및 버전 호환성 확인
3. **마이그레이션 실패**: 단계별 검증 및 롤백 계획 수립

### 디버깅 팁

```bash
# CRD 버전 상태 확인
kubectl get crd websites.example.com -o yaml

# 변환 웹훅 로그 확인
kubectl logs -n my-crd-project-system deployment/webhook-server

# API 리소스 버전 확인
kubectl api-resources | grep website
```
