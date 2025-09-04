# 웹훅 구현

📝 **참고**: 이 문서는 [컨트롤러 개발](./05-controller-development.md)에서 사용한 `advanced-crd-project`를 계속 사용합니다.

## 웹훅이란?

**웹훅(Webhook)**은 Kubernetes API 서버가 특정 작업을 수행하기 전에 외부 서비스에 요청을 보내 검증하거나 리소스를 변환할 수 있게 해주는 기능입니다.

[컨트롤러 개발](./05-controller-development.md)에서 CRD의 비즈니스 로직을 구현했으니, 이제 데이터 검증과 변환을 위한 웹훅을 구현해보겠습니다.

## 웹훅의 종류

### 1. Validating Webhook
- 리소스 생성/수정/삭제 전에 검증
- 잘못된 리소스 요청을 거부
- 비즈니스 규칙 검증

### 2. Mutating Webhook
- 리소스 생성/수정 전에 변환
- 기본값 설정, 라벨 추가 등
- 리소스 수정 후 검증

## 웹훅 구현 단계

### 1단계: 웹훅 활성화

기존 `advanced-crd-project`에 웹훅을 추가합니다:

```bash
# advanced-crd-project 디렉터리로 이동
cd advanced-crd-project

# 웹훅 활성화
kubebuilder create webhook \
  --group mygroup \
  --version v1 \
  --kind Website \
  --defaulting \
  --programmatic-validation
```

이 명령어는 다음 파일들을 생성합니다:
- `api/v1/website_webhook.go` - 웹훅 구현 파일
- `config/webhook/` - 웹훅 매니페스트 파일들

### 2단계: Validating Webhook 구현

생성된 `api/v1/website_webhook.go` 파일을 수정하여 검증 로직을 구현합니다:

```go
// api/v1/website_webhook.go
package v1

import (
    "fmt"
    "net/url"
    "regexp"
    "strings"
    
    "k8s.io/apimachinery/pkg/runtime"
    "k8s.io/apimachinery/pkg/runtime/schema"
    "k8s.io/apimachinery/pkg/util/validation/field"
    "sigs.k8s.io/controller-runtime/pkg/webhook"
)

// kubebuilder 웹훅 마커: Validating Webhook 설정
// path: 웹훅 엔드포인트 경로
// mutating=false: 검증 전용 웹훅 (변환하지 않음)
// failurePolicy=fail: 웹훅 실패 시 요청 거부
// sideEffects=None: 부작용 없음 (읽기 전용)
// admissionReviewVersions=v1: AdmissionReview API 버전
// groups, resources, verbs: 대상 리소스 정의
// versions=v1: 대상 API 버전
// name: 웹훅 이름
// +kubebuilder:webhook:path=/validate-mygroup-example-com-v1-website,mutating=false,failurePolicy=fail,sideEffects=None,admissionReviewVersions=v1,groups=mygroup.example.com,resources=websites,verbs=create;update,versions=v1,name=vwebsite.kb.io

// webhook.Validator 인터페이스 구현 확인
// 컴파일 타임에 인터페이스 구현 여부 검증
var _ webhook.Validator = &Website{}

// ValidateCreate는 Website 리소스 생성 시 호출되는 검증 함수
// kubectl apply, kubectl create 등으로 리소스를 생성할 때 실행됨
func (r *Website) ValidateCreate() error {
    return r.validateWebsite()
}

// ValidateUpdate는 Website 리소스 수정 시 호출되는 검증 함수
// kubectl apply, kubectl edit 등으로 리소스를 수정할 때 실행됨
// old: 수정 전의 리소스 객체 (변경사항 비교에 사용 가능)
func (r *Website) ValidateUpdate(old runtime.Object) error {
    return r.validateWebsite()
}

// ValidateDelete는 Website 리소스 삭제 시 호출되는 검증 함수
// kubectl delete로 리소스를 삭제할 때 실행됨
// 일반적으로 삭제는 허용하므로 nil 반환
func (r *Website) ValidateDelete() error {
    return nil
}

// validateWebsite는 Website 리소스의 전체적인 유효성을 검증하는 메인 함수
// 각 필드별 검증 함수를 호출하여 모든 에러를 수집
func (r *Website) validateWebsite() error {
    // field.ErrorList: Kubernetes에서 사용하는 에러 리스트 타입
    // 여러 필드의 검증 에러를 하나의 리스트로 관리
    var allErrs field.ErrorList
    
    // URL 필드 검증
    if err := r.validateURL(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // Replicas 필드 검증
    if err := r.validateReplicas(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // Port 필드 검증
    if err := r.validatePort(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // Image 필드 검증
    if err := r.validateImage(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // 에러가 없으면 nil 반환 (검증 성공)
    if len(allErrs) == 0 {
        return nil
    }
    
    // 에러가 있으면 webhook.NewInvalid로 에러 반환
    // GroupKind: API 그룹과 리소스 종류 정의
    // r.Name: 리소스 이름
    // allErrs: 검증 실패한 필드들의 에러 리스트
    return webhook.NewInvalid(schema.GroupKind{Group: "mygroup.example.com", Kind: "Website"}, r.Name, allErrs)
}
```

#### 상세 검증 로직

```go
// validateURL은 Website의 URL 필드를 검증하는 함수
// *field.Error: Kubernetes의 필드 에러 타입 (nil이면 검증 성공)
func (r *Website) validateURL() *field.Error {
    // 필수 필드 검증: URL이 비어있으면 에러 반환
    if r.Spec.URL == "" {
        // field.Required: 필수 필드가 누락되었을 때 사용
        // field.NewPath("spec", "url"): 에러가 발생한 필드 경로
        return field.Required(field.NewPath("spec", "url"), "URL은 필수입니다")
    }
    
    // URL 프로토콜 검증: http:// 또는 https://로 시작해야 함
    if !strings.HasPrefix(r.Spec.URL, "http://") && !strings.HasPrefix(r.Spec.URL, "https://") {
        // field.Invalid: 필드 값이 유효하지 않을 때 사용
        return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "URL은 http:// 또는 https://로 시작해야 합니다")
    }
    
    // URL 길이 검증: 최대 2048자로 제한 (RFC 7230 표준)
    if len(r.Spec.URL) > 2048 {
        // field.TooLong: 필드 값이 너무 길 때 사용
        return field.TooLong(field.NewPath("spec", "url"), r.Spec.URL, 2048)
    }
    
    // 모든 검증을 통과하면 nil 반환 (에러 없음)
    return nil
}

// validateReplicas는 Website의 Replicas 필드를 검증하는 함수
// 복제본 수의 범위를 검증하여 리소스 낭비 방지
func (r *Website) validateReplicas() *field.Error {
    // 최소 복제본 수 검증: 1개 이상이어야 함 (0개는 의미 없음)
    if r.Spec.Replicas < 1 {
        return field.Invalid(field.NewPath("spec", "replicas"), r.Spec.Replicas, "복제본 수는 1 이상이어야 합니다")
    }
    
    // 최대 복제본 수 검증: 100개 이하여야 함 (리소스 보호)
    if r.Spec.Replicas > 100 {
        return field.Invalid(field.NewPath("spec", "replicas"), r.Spec.Replicas, "복제본 수는 100 이하여야 합니다")
    }
    
    // 범위 내의 값이면 nil 반환 (검증 성공)
    return nil
}

// validatePort는 Website의 Port 필드를 검증하는 함수
// 포트 번호의 유효성과 보안 정책을 검증
func (r *Website) validatePort() *field.Error {
    // 포트 범위 검증: 1-65535 (표준 TCP/UDP 포트 범위)
    if r.Spec.Port < 1 || r.Spec.Port > 65535 {
        return field.Invalid(field.NewPath("spec", "port"), r.Spec.Port, "포트는 1-65535 범위여야 합니다")
    }
    
    // 보안 정책: 특정 포트 사용 금지
    // 포트 22: SSH (보안상 웹 서비스에서 사용 금지)
    // 포트 3306: MySQL (데이터베이스 포트, 웹 서비스에서 사용 금지)
    if r.Spec.Port == 22 || r.Spec.Port == 3306 {
        return field.Invalid(field.NewPath("spec", "port"), r.Spec.Port, "포트 22와 3306는 사용할 수 없습니다")
    }
    
    // 유효한 포트 번호면 nil 반환 (검증 성공)
    return nil
}

// validateImage는 Website의 Image 필드를 검증하는 함수
// Docker 이미지 형식과 보안 정책을 검증
func (r *Website) validateImage() *field.Error {
    // 필수 필드 검증: 이미지가 비어있으면 에러 반환
    if r.Spec.Image == "" {
        return field.Required(field.NewPath("spec", "image"), "이미지는 필수입니다")
    }
    
    // Docker 이미지 형식 검증: 태그가 포함되어야 함
    // 예: nginx:latest, ubuntu:20.04 (태그 없으면 latest로 가정되지만 명시적 태그 권장)
    if !strings.Contains(r.Spec.Image, ":") {
        return field.Invalid(field.NewPath("spec", "image"), r.Spec.Image, "이미지는 태그를 포함해야 합니다 (예: nginx:latest)")
    }
    
    // 보안 정책: 허용되지 않는 이미지 목록
    // alpine:latest: 최소한의 이미지로 웹 서비스에 부적합
    // busybox:latest: 디버깅용 이미지로 프로덕션에 부적합
    forbiddenImages := []string{"alpine:latest", "busybox:latest"}
    for _, forbidden := range forbiddenImages {
        if r.Spec.Image == forbidden {
            return field.Invalid(field.NewPath("spec", "image"), r.Spec.Image, "이 이미지는 사용할 수 없습니다")
        }
    }
    
    // 모든 검증을 통과하면 nil 반환 (검증 성공)
    return nil
}

// validateBusinessRules는 Website의 비즈니스 규칙을 검증하는 함수
// 조직의 정책이나 보안 요구사항을 반영한 검증 로직
func (r *Website) validateBusinessRules() *field.Error {
    // 비즈니스 규칙: 프로덕션 환경에서는 HTTPS만 허용
    // 보안상 HTTP는 개발/테스트 환경에서만 허용
    if strings.HasPrefix(r.Spec.URL, "http://") {
        // 라벨이나 어노테이션으로 환경 확인
        // metadata.labels.environment 값으로 배포 환경 구분
        if r.Labels["environment"] == "production" {
            return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "프로덕션 환경에서는 HTTPS만 허용됩니다")
        }
    }
    
    // 추가 비즈니스 규칙들을 여기에 구현 가능
    // 예: 특정 도메인만 허용, 특정 시간대에만 배포 등
    
    // 모든 비즈니스 규칙을 통과하면 nil 반환 (검증 성공)
    return nil
}
```

### 3단계: Mutating Webhook 구현

#### 기본 구조

```go
// kubebuilder 웹훅 마커: Mutating Webhook 설정
// path: 웹훅 엔드포인트 경로
// mutating=true: 변환 웹훅 (리소스 수정)
// failurePolicy=fail: 웹훅 실패 시 요청 거부
// sideEffects=None: 부작용 없음
// admissionReviewVersions=v1: AdmissionReview API 버전
// groups, resources, verbs: 대상 리소스 정의
// versions=v1: 대상 API 버전
// name: 웹훅 이름
// +kubebuilder:webhook:path=/mutate-mygroup-example-com-v1-website,mutating=true,failurePolicy=fail,sideEffects=None,admissionReviewVersions=v1,groups=mygroup.example.com,resources=websites,verbs=create;update,versions=v1,name=mwebsite.kb.io

// webhook.Defaulter 인터페이스 구현 확인
// 컴파일 타임에 인터페이스 구현 여부 검증
var _ webhook.Defaulter = &Website{}

// Default는 Website 리소스의 기본값을 설정하는 함수
// kubectl apply, kubectl create 등으로 리소스를 생성/수정할 때 실행됨
// Validating Webhook보다 먼저 실행되어 기본값을 설정한 후 검증
func (r *Website) Default() {
    // Spec 필드들의 기본값 설정
    
    // 이미지 기본값: 사용자가 지정하지 않으면 nginx:latest 사용
    if r.Spec.Image == "" {
        r.Spec.Image = "nginx:latest"
    }
    
    // 포트 기본값: 사용자가 지정하지 않으면 80번 포트 사용
    if r.Spec.Port == 0 {
        r.Spec.Port = 80
    }
    
    // 복제본 기본값: 사용자가 지정하지 않으면 3개 복제본 사용
    if r.Spec.Replicas == 0 {
        r.Spec.Replicas = 3
    }
    
    // Metadata 라벨 기본값 설정
    
    // Labels 맵이 nil이면 초기화
    if r.Labels == nil {
        r.Labels = make(map[string]string)
    }
    
    // app 라벨: 리소스 이름과 동일하게 설정 (쿠버네티스 관례)
    if r.Labels["app"] == "" {
        r.Labels["app"] = r.Name
    }
    
    // managed-by 라벨: 이 리소스를 관리하는 컨트롤러 표시
    if r.Labels["managed-by"] == "" {
        r.Labels["managed-by"] = "website-controller"
    }
    
    // Metadata 어노테이션 기본값 설정
    
    // Annotations 맵이 nil이면 초기화
    if r.Annotations == nil {
        r.Annotations = make(map[string]string)
    }
    
    // created-by 어노테이션: 리소스를 생성한 컨트롤러 표시
    if r.Annotations["created-by"] == "" {
        r.Annotations["created-by"] = "website-controller"
    }
    
    // created-at 어노테이션: 리소스 생성 시간 기록 (RFC3339 형식)
    if r.Annotations["created-at"] == "" {
        r.Annotations["created-at"] = time.Now().Format(time.RFC3339)
    }
}
```

#### 고급 변환 로직

```go
// Default는 고급 변환 로직을 포함한 기본값 설정 함수
// 모듈화된 접근 방식으로 각 기능을 분리하여 관리
func (r *Website) Default() {
    // 1단계: 기본값 설정 (이미지, 포트, 복제본 등)
    r.setDefaults()
    
    // 2단계: 보안 강화 (보안 컨텍스트, 네트워크 정책 등)
    r.enhanceSecurity()
    
    // 3단계: 모니터링 설정 (Prometheus 메트릭 수집 등)
    r.setupMonitoring()
}

// setDefaults는 이미지와 관련된 고급 기본값 설정을 담당
// 프로덕션 환경에 맞는 안전한 이미지 선택 로직 포함
func (r *Website) setDefaults() {
    // 이미지 태그 최적화: latest 태그를 특정 버전으로 변경
    // latest 태그는 불안정할 수 있으므로 안정적인 버전 사용
    if strings.HasSuffix(r.Spec.Image, ":latest") {
        r.Spec.Image = strings.TrimSuffix(r.Spec.Image, ":latest") + ":1.21"
    }
    
    // 환경별 이미지 최적화: 프로덕션 환경에서는 더 안전한 이미지 사용
    // alpine 기반 이미지는 보안상 더 안전하고 크기도 작음
    if r.Labels["environment"] == "production" {
        if strings.Contains(r.Spec.Image, "nginx") {
            r.Spec.Image = "nginx:1.21-alpine"
        }
    }
}

// enhanceSecurity는 보안 관련 어노테이션을 자동으로 설정
// 쿠버네티스 보안 모범 사례를 자동으로 적용
func (r *Website) enhanceSecurity() {
    // 보안 컨텍스트 설정: 컨테이너 실행 권한 제한
    // restricted 정책은 최소 권한 원칙을 적용
    if r.Annotations["security-context"] == "" {
        r.Annotations["security-context"] = "restricted"
    }
    
    // 네트워크 정책 설정: 기본적으로 모든 트래픽 차단
    // 필요한 트래픽만 명시적으로 허용하는 화이트리스트 방식
    if r.Annotations["network-policy"] == "" {
        r.Annotations["network-policy"] = "default-deny"
    }
}

// setupMonitoring은 모니터링 관련 어노테이션을 자동으로 설정
// Prometheus가 메트릭을 수집할 수 있도록 설정
func (r *Website) setupMonitoring() {
    // Prometheus 스크래핑 활성화: 메트릭 수집 허용
    if r.Annotations["prometheus.io/scrape"] == "" {
        r.Annotations["prometheus.io/scrape"] = "true"
    }
    
    // 메트릭 포트 설정: Website의 포트와 동일하게 설정
    if r.Annotations["prometheus.io/port"] == "" {
        r.Annotations["prometheus.io/port"] = strconv.Itoa(int(r.Spec.Port))
    }
    
    // 메트릭 경로 설정: 표준 Prometheus 메트릭 경로
    if r.Annotations["prometheus.io/path"] == "" {
        r.Annotations["prometheus.io/path"] = "/metrics"
    }
}
```

### 4단계: 매니페스트 생성 및 배포

```bash
# 매니페스트 생성
make manifests

# 웹훅 배포
make deploy
```

### 5단계: 웹훅 테스트

#### 정상적인 Website 생성
```bash
# 정상적인 Website 생성
kubectl apply -f - <<EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: test-website
spec:
  url: "https://example.com"
  replicas: 3
  image: "nginx:latest"
  port: 80
EOF
```

#### 잘못된 URL로 테스트
```bash
# 잘못된 URL로 Website 생성 시도
kubectl apply -f - <<EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: invalid-website
spec:
  url: "invalid-url"
  replicas: 3
  image: "nginx:latest"
  port: 80
EOF
```

예상 결과: `admission webhook "vwebsite.kb.io" denied the request`

#### 잘못된 포트로 테스트
```bash
# 잘못된 포트로 Website 생성 시도
kubectl apply -f - <<EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: invalid-port-website
spec:
  url: "https://example.com"
  replicas: 3
  image: "nginx:latest"
  port: 22
EOF
```

예상 결과: `admission webhook "vwebsite.kb.io" denied the request`

#### 기본값 설정 테스트
```bash
# 기본값이 설정되는지 확인
kubectl apply -f - <<EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: default-website
spec:
  url: "https://example.com"
EOF

# 생성된 Website 확인
kubectl get website default-website -o yaml
```

예상 결과: `replicas: 3`, `image: "nginx:latest"`, `port: 80`이 자동으로 설정됨

#### 웹훅 로그 확인
```bash
# 웹훅 컨트롤러 로그 확인
kubectl logs -n advanced-crd-project-system deployment/advanced-crd-project-controller-manager -f
```

### 6단계: 웹훅 설정

#### 웹훅 매니페스트

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
    apiVersions: ["v1"]
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
    apiVersions: ["v1"]
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
```

## 웹훅 테스트

### 1. 단위 테스트

```go
func TestWebsite_ValidateCreate(t *testing.T) {
    tests := []struct {
        name    string
        website *Website
        wantErr bool
    }{
        {
            name: "유효한 Website",
            website: &Website{
                Spec: WebsiteSpec{
                    URL:      "https://example.com",
                    Replicas: 3,
                    Port:     80,
                },
            },
            wantErr: false,
        },
        {
            name: "잘못된 URL",
            website: &Website{
                Spec: WebsiteSpec{
                    URL:      "invalid-url",
                    Replicas: 3,
                    Port:     80,
                },
            },
            wantErr: true,
        },
        {
            name: "잘못된 복제본 수",
            website: &Website{
                Spec: WebsiteSpec{
                    URL:      "https://example.com",
                    Replicas: 0,
                    Port:     80,
                },
            },
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.website.ValidateCreate()
            if (err != nil) != tt.wantErr {
                t.Errorf("Website.ValidateCreate() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### 2. 통합 테스트

```bash
# 웹훅 배포
make deploy

# 유효한 리소스 생성 테스트
kubectl apply -f - <<EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: test-website
spec:
  url: "https://example.com"
  replicas: 3
  port: 80
EOF

# 잘못된 리소스 생성 테스트 (거부되어야 함)
kubectl apply -f - <<EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: invalid-website
spec:
  url: "invalid-url"
  replicas: 0
  port: 99999
EOF
```

## 웹훅 디버깅

### 1. 웹훅 상태 확인

```bash
# 웹훅 설정 확인
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# 웹훅 상세 정보
kubectl describe validatingwebhookconfiguration website-validating-webhook-configuration
kubectl describe mutatingwebhookconfiguration website-mutating-webhook-configuration
```

### 2. 웹훅 로그 확인

```bash
# 웹훅 서비스 로그
kubectl logs -n my-crd-project-system deployment/webhook-server

# API 서버 로그
kubectl logs -n kube-system kube-apiserver-kind-control-plane | grep webhook
```

### 3. 웹훅 테스트

```bash
# 웹훅 동작 테스트
kubectl create -f test-website.yaml

# 이벤트 확인
kubectl get events --sort-by='.lastTimestamp'
```

## 성능 최적화

### 1. 웹훅 필터링

```go
// ValidateCreate는 성능 최적화를 위한 조건부 검증을 수행
// 모든 리소스에 대해 동일한 검증을 수행하는 것은 비효율적
func (r *Website) ValidateCreate() error {
    // 네임스페이스 기반 필터링: 중요한 환경에서만 엄격한 검증 수행
    // production, staging 환경에서만 검증하여 개발 환경의 유연성 보장
    if r.Namespace != "production" && r.Namespace != "staging" {
        return nil  // 개발 환경에서는 검증 생략
    }
    
    // 중요한 환경에서만 전체 검증 수행
    return r.validateWebsite()
}
```

### 2. 캐싱 활용

```go
// 전역 변수: URL 검증 결과를 메모리에 캐싱
// 동일한 URL에 대한 반복적인 검증을 방지하여 성능 향상
var (
    // urlCache: URL 문자열을 키로, 검증 결과(bool)를 값으로 하는 맵
    urlCache = make(map[string]bool)
    // urlMutex: 동시성 안전성을 위한 읽기/쓰기 뮤텍스
    // RWMutex는 여러 고루틴이 동시에 읽기를 수행할 수 있음
    urlMutex sync.RWMutex
)

// validateURL은 캐싱을 활용한 URL 검증 함수
// 동일한 URL에 대한 반복 검증을 방지하여 성능 최적화
func (r *Website) validateURL() *field.Error {
    // 읽기 락 획득: 여러 고루틴이 동시에 캐시를 읽을 수 있음
    urlMutex.RLock()
    // 캐시에서 URL 검증 결과 확인
    if valid, exists := urlCache[r.Spec.URL]; exists {
        // 읽기 락 해제: 다른 고루틴이 읽기를 수행할 수 있음
        urlMutex.RUnlock()
        // 캐시된 결과가 유효하지 않으면 에러 반환
        if !valid {
            return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "URL이 유효하지 않습니다")
        }
        // 캐시된 결과가 유효하면 nil 반환 (검증 성공)
        return nil
    }
    // 캐시에 없으면 읽기 락 해제
    urlMutex.RUnlock()
    
    // 캐시에 없는 URL이므로 실제 검증 로직 수행
    // validateURLFormat: URL 형식 검증 함수 (외부 함수)
    valid := validateURLFormat(r.Spec.URL)
    
    // 쓰기 락 획득: 캐시에 결과 저장 (읽기/쓰기 모두 차단)
    urlMutex.Lock()
    // 검증 결과를 캐시에 저장
    urlCache[r.Spec.URL] = valid
    // 쓰기 락 해제: 다른 고루틴이 읽기/쓰기 수행 가능
    urlMutex.Unlock()
    
    // 검증 결과가 유효하지 않으면 에러 반환
    if !valid {
        return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "URL이 유효하지 않습니다")
    }
    
    // 검증 성공
    return nil
}
```


## 다음 단계

웹훅 구현을 완료했습니다! 이제 CRD의 데이터 검증과 기본값 설정을 위한 고급 기능들을 구현해보겠습니다:

- [검증 및 기본값 설정](./07-validation-defaulting.md) - 스키마 검증 및 기본값
- [CRD 버전 관리](./08-versioning.md) - CRD 버전 관리 및 마이그레이션

## 문제 해결

### 일반적인 문제들

1. **웹훅 서비스 연결 실패**: 서비스 및 엔드포인트 확인
2. **인증서 문제**: TLS 인증서 설정 확인
3. **권한 문제**: RBAC 설정 확인

### 디버깅 팁

```bash
# 웹훅 서비스 상태 확인
kubectl get svc -n my-crd-project-system

# 엔드포인트 확인
kubectl get endpoints -n my-crd-project-system

# 인증서 확인
kubectl get secret -n my-crd-project-system
```
