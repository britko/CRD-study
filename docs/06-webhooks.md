# 웹훅 구현

## 웹훅이란?

**웹훅(Webhook)**은 Kubernetes API 서버가 특정 작업을 수행하기 전에 외부 서비스에 요청을 보내 검증하거나 리소스를 변환할 수 있게 해주는 기능입니다.

[컨트롤러 개발](./05-controller-development.md)에서 CRD의 비즈니스 로직을 구현했으니, 이제 데이터 검증과 변환을 위한 웹훅을 구현해보겠습니다.

**📝 참고**: 이 문서는 `docs/05-controller-development.md`에서 사용한 `advanced-crd-project`를 계속 사용합니다.

## 웹훅과 Admission Controller의 관계

### Admission Controller란?
- **Kubernetes의 내장 메커니즘**으로, API 서버가 요청을 처리하기 **전후**에 실행되는 **플러그인 시스템**
- **두 가지 타입**:
  - **Mutating Admission Controller**: 요청을 **수정** (변경)
  - **Validating Admission Controller**: 요청을 **검증** (승인/거부)

### 웹훅이란?
- **Admission Controller의 한 종류**
- **외부 서비스**로 HTTP 요청을 보내서 admission 결정을 받는 방식
- **Dynamic Admission Control**의 핵심 구성요소

### 구체적인 관계

```
Kubernetes API Server
├── Built-in Admission Controllers (내장)
│   ├── ResourceQuota
│   ├── LimitRanger  
│   ├── ServiceAccount
│   └── ...
└── Webhook Admission Controllers (외부)
    ├── ValidatingWebhookConfiguration
    └── MutatingWebhookConfiguration
```

### 내장 vs 웹훅 비교

| 구분 | 내장 Admission Controller | 웹훅 Admission Controller |
|------|---------------------------|---------------------------|
| **위치** | API 서버 내부 | 외부 서비스 |
| **언어** | Go (컴파일된 바이너리) | 어떤 언어든 가능 |
| **수정** | Kubernetes 소스 수정 필요 | 독립적으로 개발/배포 |
| **로직** | 정적, 미리 정의됨 | 동적, 커스텀 로직 |
| **예시** | ResourceQuota, LimitRanger | CRD 웹훅, 보안 정책 웹훅 |

### 요청 처리 순서

```
1. Authentication (인증)
2. Authorization (인가)  
3. Mutating Admission Controllers
   ├── 내장 Mutating Controllers
   └── Mutating Webhooks ← 우리가 만든 것
4. Validating Admission Controllers
   ├── 내장 Validating Controllers  
   └── Validating Webhooks ← 우리가 만든 것
5. API Object 저장
```

### 웹훅의 장점

1. **확장성**: Kubernetes 재컴파일 없이 새로운 로직 추가
2. **유연성**: 어떤 언어로든 구현 가능
3. **독립성**: 별도 서비스로 관리
4. **재사용성**: 다른 클러스터에서도 사용 가능

### 사용 사례

- **CRD 검증**: 우리가 만든 Website CRD의 유효성 검사
- **보안 정책**: 특정 이미지나 네임스페이스 제한
- **비용 관리**: 리소스 할당량 검증
- **컴플라이언스**: 회사 정책 준수 검증

**요약**: **웹훅 = Admission Controller의 한 종류**로, 외부 서비스로 구현된 admission controller입니다.

## 웹훅의 동작 원리

### 웹훅 실행 순서

웹훅은 Kubernetes API 서버의 요청 처리 파이프라인에서 특정 시점에 실행됩니다:

```mermaid
flowchart LR
    A[kubectl apply<br/>리소스 요청] --> B[Authentication<br/>인증]
    B --> C[Authorization<br/>인가]
    C --> D[Mutating Webhook<br/>기본값 설정]
    D --> E[Validating Webhook<br/>검증]
    E --> F[API Object<br/>저장]
    
    style A fill:#e1f5fe
    style D fill:#f3e5f5
    style E fill:#e8f5e8
    style F fill:#f1f8e9
```

**웹훅 실행 과정:**

1. **Mutating Webhook**: 리소스 생성/수정 **전**에 실행되어 기본값 설정, 라벨/어노테이션 추가
2. **Validating Webhook**: 리소스 생성/수정 **후**에 실행되어 비즈니스 규칙 검증, 데이터 유효성 검사
3. **API Object 저장**: 모든 검증을 통과한 리소스가 클러스터에 저장

### 웹훅의 종류

### 1. Validating Webhook
- 리소스 생성/수정/삭제 전에 검증
- 잘못된 리소스 요청을 거부
- 비즈니스 규칙 검증

### 2. Mutating Webhook
- 리소스 생성/수정 전에 변환
- 기본값 설정, 라벨 추가 등
- 리소스 수정 후 검증

## 완성된 웹훅 코드

먼저 완성된 웹훅 코드를 전체적으로 살펴보겠습니다:

```go
// internal/webhook/v1/website_webhook.go
package v1

import (
    "context"
    "fmt"
    "net/url"
    "regexp"
    "strings"
    "strconv"
    "sync"
    "time"
    
    "k8s.io/apimachinery/pkg/runtime"
    "k8s.io/apimachinery/pkg/runtime/schema"
    "k8s.io/apimachinery/pkg/util/validation/field"
    ctrl "sigs.k8s.io/controller-runtime"
    logf "sigs.k8s.io/controller-runtime/pkg/log"
    "sigs.k8s.io/controller-runtime/pkg/webhook"
    "sigs.k8s.io/controller-runtime/pkg/webhook/admission"
    
    mygroupv1 "github.com/britko/advanced-crd-project/api/v1"
)

// 웹훅 등록 함수
func SetupWebsiteWebhookWithManager(mgr ctrl.Manager) error {
    return ctrl.NewWebhookManagedBy(mgr).For(&mygroupv1.Website{}).
        WithValidator(&WebsiteCustomValidator{}).
        WithDefaulter(&WebsiteCustomDefaulter{}).
        Complete()
}

// Mutating Webhook - 기본값 설정
// +kubebuilder:webhook:path=/mutate-mygroup-example-com-v1-website,mutating=true,failurePolicy=fail,sideEffects=None,admissionReviewVersions=v1,groups=mygroup.example.com,resources=websites,verbs=create;update,versions=v1,name=mwebsite-v1.kb.io

type WebsiteCustomDefaulter struct{}

var _ webhook.CustomDefaulter = &WebsiteCustomDefaulter{}

func (d *WebsiteCustomDefaulter) Default(_ context.Context, obj runtime.Object) error {
    website, ok := obj.(*mygroupv1.Website)
    if !ok {
        return fmt.Errorf("expected an Website object but got %T", obj)
    }
    
    // 기본값 설정 로직
    if website.Spec.Image == "" {
        website.Spec.Image = "nginx:latest"
    }
    if website.Spec.Port == 0 {
        website.Spec.Port = 80
    }
    if website.Spec.Replicas == 0 {
        website.Spec.Replicas = 3
    }
    
    return nil
}

// Validating Webhook - 검증
// +kubebuilder:webhook:path=/validate-mygroup-example-com-v1-website,mutating=false,failurePolicy=fail,sideEffects=None,admissionReviewVersions=v1,groups=mygroup.example.com,resources=websites,verbs=create;update,versions=v1,name=vwebsite-v1.kb.io

type WebsiteCustomValidator struct{}

var _ webhook.CustomValidator = &WebsiteCustomValidator{}

func (v *WebsiteCustomValidator) ValidateCreate(_ context.Context, obj runtime.Object) (admission.Warnings, error) {
    website, ok := obj.(*mygroupv1.Website)
    if !ok {
        return nil, fmt.Errorf("expected an Website object but got %T", obj)
    }
    return nil, v.validateWebsite(website)
}

func (v *WebsiteCustomValidator) ValidateUpdate(_ context.Context, oldObj, newObj runtime.Object) (admission.Warnings, error) {
    website, ok := newObj.(*mygroupv1.Website)
    if !ok {
        return nil, fmt.Errorf("expected an Website object but got %T", newObj)
    }
    return nil, v.validateWebsite(website)
}

func (v *WebsiteCustomValidator) ValidateDelete(_ context.Context, obj runtime.Object) (admission.Warnings, error) {
    return nil, nil
}

func (v *WebsiteCustomValidator) validateWebsite(website *mygroupv1.Website) error {
    var allErrs field.ErrorList
    
    // URL 검증
    if website.Spec.URL == "" {
        allErrs = append(allErrs, field.Required(field.NewPath("spec", "url"), "URL은 필수입니다"))
    }
    
    // Replicas 검증
    if website.Spec.Replicas < 1 || website.Spec.Replicas > 100 {
        allErrs = append(allErrs, field.Invalid(field.NewPath("spec", "replicas"), website.Spec.Replicas, "복제본 수는 1-100 범위여야 합니다"))
    }
    
    // Port 검증
    if website.Spec.Port < 1 || website.Spec.Port > 65535 {
        allErrs = append(allErrs, field.Invalid(field.NewPath("spec", "port"), website.Spec.Port, "포트는 1-65535 범위여야 합니다"))
    }
    
    if len(allErrs) == 0 {
        return nil
    }
    
    return webhook.NewInvalid(schema.GroupKind{Group: "mygroup.example.com", Kind: "Website"}, website.Name, allErrs)
}
```

## 웹훅 구현 단계

위의 완성된 코드를 단계별로 구현해보겠습니다:

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

#### 명령어 옵션 설명

| 옵션 | 설명 | 예시 |
|------|------|------|
| `--group` | API 그룹명 (기존 CRD와 동일) | `mygroup` |
| `--version` | API 버전 (기존 CRD와 동일) | `v1` |
| `--kind` | 리소스 종류 (기존 CRD와 동일) | `Website` |
| `--defaulting` | Mutating Webhook 활성화 | 기본값 설정 기능 |
| `--programmatic-validation` | Validating Webhook 활성화 | 프로그래밍 방식 검증 |

#### 생성되는 파일들

이 명령어는 다음 파일들을 생성합니다:

**1. 웹훅 구현 파일**
- `internal/webhook/v1/website_webhook.go` - 웹훅 로직 구현 파일
  - **Validating Webhook**: `ValidateCreate()`, `ValidateUpdate()`, `ValidateDelete()` 함수
  - **Mutating Webhook**: `Default()` 함수 (기본값 설정)
  - **웹훅 등록**: `SetupWebsiteWebhookWithManager()` 함수

**2. 웹훅 매니페스트 파일들**
- `config/webhook/` 디렉터리 생성
  - `kustomization.yaml` - 웹훅 리소스 관리
  - `manifests.yaml` - ValidatingWebhookConfiguration, MutatingWebhookConfiguration
  - `service.yaml` - 웹훅 서비스 정의
  - `certificate.yaml` - TLS 인증서 설정

**3. 기존 파일 수정**
- `main.go` - 웹훅 서버 설정 추가
- `config/manager/manager.yaml` - 웹훅 포트 설정 추가

#### 웹훅 타입별 기능

**Mutating Webhook (`--defaulting`)**
- 리소스 생성/수정 **전**에 실행
- 기본값 설정, 라벨/어노테이션 추가
- 리소스 내용을 **변경**할 수 있음

**Validating Webhook (`--programmatic-validation`)**
- 리소스 생성/수정 **후**에 실행 (Mutating Webhook 이후)
- 비즈니스 규칙 검증, 데이터 유효성 검사
- 리소스 내용을 **변경하지 않고** 승인/거부만 결정

### 2단계: Validating Webhook 구현

생성된 `internal/webhook/v1/website_webhook.go` 파일에 검증 로직을 구현합니다:

```go
// Validating Webhook 구조체 및 인터페이스 구현
type WebsiteCustomValidator struct{}

var _ webhook.CustomValidator = &WebsiteCustomValidator{}

// 검증 함수들
func (v *WebsiteCustomValidator) ValidateCreate(_ context.Context, obj runtime.Object) (admission.Warnings, error) {
    website, ok := obj.(*mygroupv1.Website)
    if !ok {
        return nil, fmt.Errorf("expected an Website object but got %T", obj)
    }
    return nil, v.validateWebsite(website)
}

func (v *WebsiteCustomValidator) ValidateUpdate(_ context.Context, oldObj, newObj runtime.Object) (admission.Warnings, error) {
    website, ok := newObj.(*mygroupv1.Website)
    if !ok {
        return nil, fmt.Errorf("expected an Website object but got %T", newObj)
    }
    return nil, v.validateWebsite(website)
}

func (v *WebsiteCustomValidator) ValidateDelete(_ context.Context, obj runtime.Object) (admission.Warnings, error) {
    return nil, nil
}

// 메인 검증 함수
func (v *WebsiteCustomValidator) validateWebsite(website *mygroupv1.Website) error {
    var allErrs field.ErrorList
    
    // URL 검증
    if website.Spec.URL == "" {
        allErrs = append(allErrs, field.Required(field.NewPath("spec", "url"), "URL은 필수입니다"))
    }
    
    // Replicas 검증
    if website.Spec.Replicas < 1 || website.Spec.Replicas > 100 {
        allErrs = append(allErrs, field.Invalid(field.NewPath("spec", "replicas"), website.Spec.Replicas, "복제본 수는 1-100 범위여야 합니다"))
    }
    
    // Port 검증
    if website.Spec.Port < 1 || website.Spec.Port > 65535 {
        allErrs = append(allErrs, field.Invalid(field.NewPath("spec", "port"), website.Spec.Port, "포트는 1-65535 범위여야 합니다"))
    }
    
    if len(allErrs) == 0 {
        return nil
    }
    
    return webhook.NewInvalid(schema.GroupKind{Group: "mygroup.example.com", Kind: "Website"}, website.Name, allErrs)
}
```

### 3단계: Mutating Webhook 구현

**같은 파일**에 Mutating Webhook 로직을 추가합니다:

```go
// Mutating Webhook 구조체 및 인터페이스 구현
type WebsiteCustomDefaulter struct{}

var _ webhook.CustomDefaulter = &WebsiteCustomDefaulter{}

// 기본값 설정 함수
func (d *WebsiteCustomDefaulter) Default(_ context.Context, obj runtime.Object) error {
    website, ok := obj.(*mygroupv1.Website)
    if !ok {
        return fmt.Errorf("expected an Website object but got %T", obj)
    }
    
    // 기본값 설정
    if website.Spec.Image == "" {
        website.Spec.Image = "nginx:latest"
    }
    if website.Spec.Port == 0 {
        website.Spec.Port = 80
    }
    if website.Spec.Replicas == 0 {
        website.Spec.Replicas = 3
    }
    
    // 라벨 설정
    if website.Labels == nil {
        website.Labels = make(map[string]string)
    }
    if website.Labels["app"] == "" {
        website.Labels["app"] = website.Name
    }
    
    return nil
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

#### 잘못된 데이터로 테스트
```bash
# 잘못된 URL로 Website 생성 시도
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

예상 결과: `admission webhook "vwebsite-v1.kb.io" denied the request`

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

## 웹훅 테스트

### 단위 테스트

```go
func TestWebsite_ValidateCreate(t *testing.T) {
    tests := []struct {
        name    string
        website *mygroupv1.Website
        wantErr bool
    }{
        {
            name: "유효한 Website",
            website: &mygroupv1.Website{
                Spec: mygroupv1.WebsiteSpec{
                    URL:      "https://example.com",
                    Replicas: 3,
                    Port:     80,
                },
            },
            wantErr: false,
        },
        {
            name: "잘못된 URL",
            website: &mygroupv1.Website{
                Spec: mygroupv1.WebsiteSpec{
                    URL:      "invalid-url",
                    Replicas: 3,
                    Port:     80,
                },
            },
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            validator := &WebsiteCustomValidator{}
            _, err := validator.ValidateCreate(context.Background(), tt.website)
            if (err != nil) != tt.wantErr {
                t.Errorf("ValidateCreate() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### 통합 테스트

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

### 웹훅 상태 확인

```bash
# 웹훅 설정 확인
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# 웹훅 로그 확인
kubectl logs -n advanced-crd-project-system deployment/advanced-crd-project-controller-manager -f
```

## 성능 최적화

### 웹훅 필터링

```go
// 네임스페이스 기반 필터링: 중요한 환경에서만 엄격한 검증 수행
func (v *WebsiteCustomValidator) ValidateCreate(_ context.Context, obj runtime.Object) (admission.Warnings, error) {
    website, ok := obj.(*mygroupv1.Website)
    if !ok {
        return nil, fmt.Errorf("expected an Website object but got %T", obj)
    }
    
    // 개발 환경에서는 검증 생략
    if website.Namespace != "production" && website.Namespace != "staging" {
        return nil, nil
    }
    
    // 중요한 환경에서만 전체 검증 수행
    return nil, v.validateWebsite(website)
}
```

### 캐싱 활용

```go
// URL 검증 결과를 메모리에 캐싱
var (
    urlCache = make(map[string]bool)
    urlMutex sync.RWMutex
)

func (v *WebsiteCustomValidator) validateURL(website *mygroupv1.Website) *field.Error {
    urlMutex.RLock()
    if valid, exists := urlCache[website.Spec.URL]; exists {
        urlMutex.RUnlock()
        if !valid {
            return field.Invalid(field.NewPath("spec", "url"), website.Spec.URL, "URL이 유효하지 않습니다")
        }
        return nil
    }
    urlMutex.RUnlock()
    
    // 실제 검증 로직 수행
    valid := validateURLFormat(website.Spec.URL)
    
    urlMutex.Lock()
    urlCache[website.Spec.URL] = valid
    urlMutex.Unlock()
    
    if !valid {
        return field.Invalid(field.NewPath("spec", "url"), website.Spec.URL, "URL이 유효하지 않습니다")
    }
    
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
