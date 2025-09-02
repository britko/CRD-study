# kubebuilder 사용법

## kubebuilder란?

**kubebuilder**는 Kubernetes CRD와 컨트롤러를 개발하기 위한 Go 프레임워크입니다. 코드 생성, 테스트, 배포를 자동화하여 개발 생산성을 크게 향상시킵니다.

## 주요 기능

- **코드 생성**: CRD 스키마, 컨트롤러, 테스트 코드 자동 생성
- **프로젝트 구조**: 표준화된 프로젝트 구조 제공
- **테스트 지원**: 단위 테스트 및 통합 테스트 환경 구축
- **배포 자동화**: CRD 및 컨트롤러 배포 자동화

## 프로젝트 생성

### 1. 프로젝트 초기화

```bash
# 새 디렉토리 생성
mkdir my-crd-project
cd my-crd-project

# kubebuilder 프로젝트 초기화
kubebuilder init \
  --domain example.com \
  --repo github.com/username/my-crd-project \
  --license apache2 \
  --owner "Your Name <your.email@example.com>"
```

### 2. API 생성

```bash
# Website API 생성
kubebuilder create api \
  --group mygroup \
  --version v1 \
  --kind Website \
  --resource \
  --controller
```

## 프로젝트 구조

```
my-crd-project/
├── api/                    # API 정의
│   └── v1/
│       ├── website_types.go    # Website 타입 정의
│       ├── website_webhook.go  # 웹훅 정의
│       └── groupversion_info.go
├── config/                 # 배포 설정
│   ├── crd/              # CRD 매니페스트
│   ├── rbac/             # RBAC 설정
│   ├── manager/          # 매니저 배포
│   └── webhook/          # 웹훅 설정
├── controllers/           # 컨트롤러 구현
│   └── website_controller.go
├── hack/                  # 유틸리티 스크립트
├── main.go               # 메인 함수
├── Makefile              # 빌드 및 배포
└── go.mod                # Go 모듈
```

## API 타입 정의

### 1. 기본 타입 구조

`api/v1/website_types.go` 파일에서 Website 리소스의 스키마를 정의합니다:

```go
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
    // +kubebuilder:validation:Maximum=10
    // +kubebuilder:default=3
    Replicas int32 `json:"replicas,omitempty"`

    // Image는 사용할 Docker 이미지입니다
    // +kubebuilder:default="nginx:latest"
    Image string `json:"image,omitempty"`

    // Port는 컨테이너 포트입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=65535
    // +kubebuilder:default=80
    Port int32 `json:"port,omitempty"`
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

### 2. kubebuilder 마커

- `+kubebuilder:validation:*`: OpenAPI 검증 규칙
- `+kubebuilder:default:*`: 기본값 설정
- `+kubebuilder:printcolumn:*`: kubectl 출력 컬럼 정의
- `+kubebuilder:subresource:*`: 서브리소스 활성화

## 컨트롤러 구현

### 1. 기본 컨트롤러 구조

`controllers/website_controller.go`에서 비즈니스 로직을 구현합니다:

```go
package controllers

import (
    "context"
    "fmt"

    "k8s.io/apimachinery/pkg/runtime"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/client"
    "sigs.k8s.io/controller-runtime/pkg/log"

    mygroupv1 "github.com/username/my-crd-project/api/v1"
    appsv1 "k8s.io/api/apps/v1"
    corev1 "k8s.io/api/core/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// WebsiteReconciler는 Website 리소스를 조정합니다
type WebsiteReconciler struct {
    client.Client
    Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=mygroup.example.com,resources=websites,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=mygroup.example.com,resources=websites/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=mygroup.example.com,resources=websites/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=services,verbs=get;list;watch;create;update;patch;delete

// Reconcile은 Website 리소스를 조정합니다
func (r *WebsiteReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    logger := log.FromContext(ctx)

    // Website 리소스 조회
    var website mygroupv1.Website
    if err := r.Get(ctx, req.NamespacedName, &website); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    logger.Info("Website 조정 시작", "name", website.Name, "namespace", website.Namespace)

    // Deployment 생성/업데이트
    if err := r.reconcileDeployment(ctx, &website); err != nil {
        return ctrl.Result{}, err
    }

    // Service 생성/업데이트
    if err := r.reconcileService(ctx, &website); err != nil {
        return ctrl.Result{}, err
    }

    // 상태 업데이트
    if err := r.updateStatus(ctx, &website); err != nil {
        return ctrl.Result{}, err
    }

    return ctrl.Result{}, nil
}

// SetupWithManager는 컨트롤러를 매니저에 설정합니다
func (r *WebsiteReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&mygroupv1.Website{}).
        Owns(&appsv1.Deployment{}).
        Owns(&corev1.Service{}).
        Complete(r)
}
```

## 빌드 및 배포

### 1. 코드 생성

```bash
# CRD 매니페스트 생성
make manifests

# Go 코드 생성
make generate
```

### 2. 빌드

```bash
# 컨트롤러 빌드
make build

# Docker 이미지 빌드
make docker-build
```

### 3. 배포

```bash
# CRD 배포
make install

# 컨트롤러 배포
make deploy

# 또는 전체 배포
make deploy
```

## 테스트

### 1. 단위 테스트

```bash
# 테스트 실행
make test

# 특정 테스트 실행
go test ./controllers/ -v
```

### 2. 통합 테스트

```bash
# 테스트 환경에서 실행
make test-env
```

## 디버깅

### 1. 로그 확인

```bash
# 컨트롤러 로그 확인
kubectl logs -n my-crd-project-system deployment/my-crd-project-controller-manager

# 특정 리소스 이벤트 확인
kubectl describe website my-website
```

### 2. 로컬 실행

```bash
# 컨트롤러를 로컬에서 실행
make run
```

## 다음 단계

- [컨트롤러 개발](./05-controller-development.md) - 컨트롤러 구현 상세 가이드
- [웹훅 구현](./06-webhooks.md) - 검증 및 변환 웹훅 구현

## 문제 해결

### 일반적인 문제들

1. **CRD 생성 실패**: API 서버 버전 호환성 확인
2. **컨트롤러 시작 실패**: RBAC 권한 및 의존성 확인
3. **리소스 조정 실패**: 로그 및 이벤트 확인

### 유용한 명령어

```bash
# CRD 상태 확인
kubectl get crd

# 컨트롤러 상태 확인
kubectl get pods -n my-crd-project-system

# API 리소스 확인
kubectl api-resources | grep mygroup
```
