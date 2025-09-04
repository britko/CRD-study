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

// +kubebuilder:webhook:path=/validate-mygroup-example-com-v1-website,mutating=false,failurePolicy=fail,sideEffects=None,admissionReviewVersions=v1,groups=mygroup.example.com,resources=websites,verbs=create;update,versions=v1,name=vwebsite.kb.io

var _ webhook.Validator = &Website{}

// ValidateCreate는 Website 생성 시 검증합니다
func (r *Website) ValidateCreate() error {
    return r.validateWebsite()
}

// ValidateUpdate는 Website 수정 시 검증합니다
func (r *Website) ValidateUpdate(old runtime.Object) error {
    return r.validateWebsite()
}

// ValidateDelete는 Website 삭제 시 검증합니다
func (r *Website) ValidateDelete() error {
    return nil
}

// validateWebsite는 Website의 유효성을 검증합니다
func (r *Website) validateWebsite() error {
    var allErrs field.ErrorList
    
    // URL 검증
    if err := r.validateURL(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // Replicas 검증
    if err := r.validateReplicas(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // Port 검증
    if err := r.validatePort(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // Image 검증
    if err := r.validateImage(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    if len(allErrs) == 0 {
        return nil
    }
    
    return webhook.NewInvalid(schema.GroupKind{Group: "mygroup.example.com", Kind: "Website"}, r.Name, allErrs)
}
```

#### 상세 검증 로직

```go
func (r *Website) validateURL() *field.Error {
    if r.Spec.URL == "" {
        return field.Required(field.NewPath("spec", "url"), "URL은 필수입니다")
    }
    
    // URL 형식 검증
    if !strings.HasPrefix(r.Spec.URL, "http://") && !strings.HasPrefix(r.Spec.URL, "https://") {
        return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "URL은 http:// 또는 https://로 시작해야 합니다")
    }
    
    // URL 길이 검증
    if len(r.Spec.URL) > 2048 {
        return field.TooLong(field.NewPath("spec", "url"), r.Spec.URL, 2048)
    }
    
    return nil
}

func (r *Website) validateReplicas() *field.Error {
    if r.Spec.Replicas < 1 {
        return field.Invalid(field.NewPath("spec", "replicas"), r.Spec.Replicas, "복제본 수는 1 이상이어야 합니다")
    }
    
    if r.Spec.Replicas > 100 {
        return field.Invalid(field.NewPath("spec", "replicas"), r.Spec.Replicas, "복제본 수는 100 이하여야 합니다")
    }
    
    return nil
}

func (r *Website) validatePort() *field.Error {
    if r.Spec.Port < 1 || r.Spec.Port > 65535 {
        return field.Invalid(field.NewPath("spec", "port"), r.Spec.Port, "포트는 1-65535 범위여야 합니다")
    }
    
    // 특정 포트 제한
    if r.Spec.Port == 22 || r.Spec.Port == 3306 {
        return field.Invalid(field.NewPath("spec", "port"), r.Spec.Port, "포트 22와 3306는 사용할 수 없습니다")
    }
    
    return nil
}

func (r *Website) validateImage() *field.Error {
    if r.Spec.Image == "" {
        return field.Required(field.NewPath("spec", "image"), "이미지는 필수입니다")
    }
    
    // Docker 이미지 형식 검증 (간단한 검증)
    if !strings.Contains(r.Spec.Image, ":") {
        return field.Invalid(field.NewPath("spec", "image"), r.Spec.Image, "이미지는 태그를 포함해야 합니다 (예: nginx:latest)")
    }
    
    // 허용되지 않는 이미지 검증
    forbiddenImages := []string{"alpine:latest", "busybox:latest"}
    for _, forbidden := range forbiddenImages {
        if r.Spec.Image == forbidden {
            return field.Invalid(field.NewPath("spec", "image"), r.Spec.Image, "이 이미지는 사용할 수 없습니다")
        }
    }
    
    return nil
}

func (r *Website) validateBusinessRules() *field.Error {
    // 비즈니스 규칙: 프로덕션 환경에서는 HTTPS만 허용
    if strings.HasPrefix(r.Spec.URL, "http://") {
        // 라벨이나 어노테이션으로 환경 확인
        if r.Labels["environment"] == "production" {
            return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "프로덕션 환경에서는 HTTPS만 허용됩니다")
        }
    }
    
    return nil
}
```

### 3단계: Mutating Webhook 구현

#### 기본 구조

```go
// +kubebuilder:webhook:path=/mutate-mygroup-example-com-v1-website,mutating=true,failurePolicy=fail,sideEffects=None,admissionReviewVersions=v1,groups=mygroup.example.com,resources=websites,verbs=create;update,versions=v1,name=mwebsite.kb.io

var _ webhook.Defaulter = &Website{}

// Default는 Website의 기본값을 설정합니다
func (r *Website) Default() {
    // 이미지 기본값 설정
    if r.Spec.Image == "" {
        r.Spec.Image = "nginx:latest"
    }
    
    // 포트 기본값 설정
    if r.Spec.Port == 0 {
        r.Spec.Port = 80
    }
    
    // 복제본 기본값 설정
    if r.Spec.Replicas == 0 {
        r.Spec.Replicas = 3
    }
    
    // 라벨 기본값 설정
    if r.Labels == nil {
        r.Labels = make(map[string]string)
    }
    
    if r.Labels["app"] == "" {
        r.Labels["app"] = r.Name
    }
    
    if r.Labels["managed-by"] == "" {
        r.Labels["managed-by"] = "website-controller"
    }
    
    // 어노테이션 기본값 설정
    if r.Annotations == nil {
        r.Annotations = make(map[string]string)
    }
    
    if r.Annotations["created-by"] == "" {
        r.Annotations["created-by"] = "website-controller"
    }
    
    if r.Annotations["created-at"] == "" {
        r.Annotations["created-at"] = time.Now().Format(time.RFC3339)
    }
}
```

#### 고급 변환 로직

```go
func (r *Website) Default() {
    // 기본값 설정
    r.setDefaults()
    
    // 보안 강화
    r.enhanceSecurity()
    
    // 모니터링 설정
    r.setupMonitoring()
}

func (r *Website) setDefaults() {
    // 이미지 태그가 latest인 경우 특정 버전으로 변경
    if strings.HasSuffix(r.Spec.Image, ":latest") {
        r.Spec.Image = strings.TrimSuffix(r.Spec.Image, ":latest") + ":1.21"
    }
    
    // 프로덕션 환경에서는 더 안전한 이미지 사용
    if r.Labels["environment"] == "production" {
        if strings.Contains(r.Spec.Image, "nginx") {
            r.Spec.Image = "nginx:1.21-alpine"
        }
    }
}

func (r *Website) enhanceSecurity() {
    // 보안 컨텍스트 설정
    if r.Annotations["security-context"] == "" {
        r.Annotations["security-context"] = "restricted"
    }
    
    // 네트워크 정책 설정
    if r.Annotations["network-policy"] == "" {
        r.Annotations["network-policy"] = "default-deny"
    }
}

func (r *Website) setupMonitoring() {
    // Prometheus 메트릭 수집 활성화
    if r.Annotations["prometheus.io/scrape"] == "" {
        r.Annotations["prometheus.io/scrape"] = "true"
    }
    
    if r.Annotations["prometheus.io/port"] == "" {
        r.Annotations["prometheus.io/port"] = strconv.Itoa(int(r.Spec.Port))
    }
    
    if r.Annotations["prometheus.io/path"] == "" {
        r.Annotations["prometheus.io/path"] = "/metrics"
    }
}
```

### 4단계: 웹훅 설정

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
// 특정 조건에서만 웹훅 실행
func (r *Website) ValidateCreate() error {
    // 특정 네임스페이스에서만 검증
    if r.Namespace != "production" && r.Namespace != "staging" {
        return nil
    }
    
    return r.validateWebsite()
}
```

### 2. 캐싱 활용

```go
var (
    urlCache = make(map[string]bool)
    urlMutex sync.RWMutex
)

func (r *Website) validateURL() *field.Error {
    urlMutex.RLock()
    if valid, exists := urlCache[r.Spec.URL]; exists {
        urlMutex.RUnlock()
        if !valid {
            return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "URL이 유효하지 않습니다")
        }
        return nil
    }
    urlMutex.RUnlock()
    
    // URL 검증 로직
    valid := validateURLFormat(r.Spec.URL)
    
    // 캐시에 저장
    urlMutex.Lock()
    urlCache[r.Spec.URL] = valid
    urlMutex.Unlock()
    
    if !valid {
        return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "URL이 유효하지 않습니다")
    }
    
    return nil
}
```

## 실습: 웹훅 구현 및 테스트

### 1단계: 웹훅 활성화

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

### 2단계: 웹훅 코드 구현

생성된 `api/v1/website_webhook.go` 파일에 위의 검증 로직을 추가합니다.

### 3단계: 매니페스트 생성 및 배포

```bash
# 매니페스트 생성
make manifests

# 웹훅 배포
make deploy
```

### 4단계: 웹훅 테스트

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

### 5단계: 기본값 설정 테스트

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

### 6단계: 웹훅 로그 확인

```bash
# 웹훅 컨트롤러 로그 확인
kubectl logs -n advanced-crd-project-system deployment/advanced-crd-project-controller-manager -f
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
