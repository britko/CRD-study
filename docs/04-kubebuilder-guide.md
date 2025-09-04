# kubebuilder 사용법

## kubebuilder란?

**kubebuilder**는 Kubernetes CRD와 컨트롤러를 개발하기 위한 Go 프레임워크입니다. [첫 번째 CRD 만들기](./03-first-crd.md)에서 이미 기본적인 사용법을 경험했으며, 이제 kubebuilder의 고급 기능들을 자세히 살펴보겠습니다.

**주요 기능:**
- **코드 생성**: CRD 스키마, 컨트롤러, 테스트 코드 자동 생성
- **프로젝트 구조**: 표준화된 프로젝트 구조 제공
- **테스트 지원**: 단위 테스트 및 통합 테스트 환경 구축
- **배포 자동화**: CRD 및 컨트롤러 배포 자동화

## 주요 기능

- **코드 생성**: CRD 스키마, 컨트롤러, 테스트 코드 자동 생성
- **프로젝트 구조**: 표준화된 프로젝트 구조 제공
- **테스트 지원**: 단위 테스트 및 통합 테스트 환경 구축
- **배포 자동화**: CRD 및 컨트롤러 배포 자동화

## 프로젝트 생성

### 1. 프로젝트 초기화

```bash
# 새 디렉토리 생성 (03과 다른 이름 사용)
mkdir advanced-crd-project
cd advanced-crd-project

# kubebuilder 프로젝트 초기화
kubebuilder init \
  --domain example.com \
  --repo github.com/username/advanced-crd-project \
  --license apache2 \
  --owner "Your Name <your.email@example.com>"
```

**📝 참고**: [첫 번째 CRD 만들기](./03-first-crd.md)에서는 `simple-crd` 프로젝트를 사용했지만, 여기서는 더 고급 기능을 위한 `advanced-crd-project`를 생성합니다.

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
advanced-crd-project/
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
├── internal/              # 내부 패키지
│   └── controller/       # 컨트롤러 구현
│       └── website_controller.go
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
//+kubebuilder:resource:shortName=ws
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
```

### 2. kubebuilder 마커 설명

#### **shortName 마커**
```go
//+kubebuilder:resource:shortName=ws
```
- **역할**: `kubectl`에서 사용할 수 있는 짧은 이름 제공
- **사용법**: `kubectl get ws` (전체 이름 `websites` 대신)
- **장점**: 빠른 타이핑, 자동완성 지원

#### **printcolumn 마커**
```go
//+kubebuilder:printcolumn:name="URL",type="string",JSONPath=".spec.url"
//+kubebuilder:printcolumn:name="Replicas",type="integer",JSONPath=".spec.replicas"
//+kubebuilder:printcolumn:name="Available",type="integer",JSONPath=".status.availableReplicas"
//+kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"
```
- **역할**: `kubectl get` 명령어에서 표시할 컬럼 정의
- **JSONPath**: 리소스의 어떤 필드를 표시할지 지정
- **사용자 경험**: 중요한 정보를 한눈에 확인 가능

//+kubebuilder:object:root=true

// WebsiteList는 Website 리소스들의 컬렉션을 포함합니다
type WebsiteList struct {
    metav1.TypeMeta `json:",inline"`
    metav1.ListMeta `json:"metadata,omitempty"`
    Items           []Website `json:"items"`
}
```

### 3. shortName 사용 예시

shortName을 추가한 후 `make manifests`를 실행하면 다음과 같이 사용할 수 있습니다:

```bash
# 전체 이름 사용
kubectl get websites
kubectl get website my-website

# shortName 사용 (더 간단)
kubectl get ws
kubectl get ws my-website

# 컬럼 표시 확인
kubectl get websites -o wide
kubectl get ws -o wide
```

**📝 참고**: shortName은 사용자 편의를 위한 것이므로, 전체 이름과 함께 사용할 수 있습니다.

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

`internal/controller/website_controller.go`에서 비즈니스 로직을 구현합니다:

```go
package controller

import (
    "context"

    "k8s.io/apimachinery/pkg/runtime"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/client"
    logf "sigs.k8s.io/controller-runtime/pkg/log"

    mygroupv1 "github.com/britko/advanced-crd-project/api/v1"
    // 추가 import 예시 (구현 시 필요):
    // appsv1 "k8s.io/api/apps/v1"
    // corev1 "k8s.io/api/core/v1"
    // metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// WebsiteReconciler reconciles a Website object
type WebsiteReconciler struct {
    client.Client
    Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=mygroup.example.com,resources=websites,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=mygroup.example.com,resources=websites/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=mygroup.example.com,resources=websites/finalizers,verbs=update

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// TODO(user): Modify the Reconcile function to compare the state specified by
// the Website object against the actual cluster state, and then
// perform operations to make the cluster state reflect the state specified by
// the user.
//
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.21.0/pkg/reconcile
func (r *WebsiteReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    _ = logf.FromContext(ctx)

    // TODO(user): your logic here
    // 아래는 구현 예시입니다:
    // logger := logf.FromContext(ctx)

    // 1. Website 리소스 조회
    var website mygroupv1.Website
    if err := r.Get(ctx, req.NamespacedName, &website); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    // logger.Info("Website 조정 시작", "name", website.Name, "namespace", website.Namespace)

    // 2. 원하는 상태와 실제 상태 비교
    // 예: Deployment가 존재하는지, 올바른 설정인지 확인

    // 3. 필요한 작업 수행
    // 예: Deployment 생성/업데이트, Service 생성/업데이트

    // 4. 상태 업데이트
    // 예: website.Status.AvailableReplicas 업데이트

    return ctrl.Result{}, nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *WebsiteReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&mygroupv1.Website{}).
        Named("website").
        // 추가 옵션 예시:
        // Owns(&appsv1.Deployment{}).        // Deployment 변경 감지
        // Owns(&corev1.Service{}).            // Service 변경 감지
        // Watches(&source.Kind{Type: &corev1.Pod{}}, handler.EnqueueRequestsFromMapFunc(r.findObjectsForPod)). // Pod 변경 감지
        Complete(r)
}
```

### 2. 구현 가이드

#### **Reconcile 함수 구현 단계**

1. **리소스 조회**: `r.Get()`으로 Website 리소스 가져오기
2. **상태 비교**: 원하는 상태와 실제 클러스터 상태 비교
3. **작업 수행**: 필요한 리소스 생성/업데이트/삭제
4. **상태 업데이트**: Website의 Status 필드 업데이트

#### **자주 사용하는 패턴**

```go
// 리소스 존재 여부 확인
if err := r.Get(ctx, types.NamespacedName{Name: name, Namespace: namespace}, &deployment); err != nil {
    if errors.IsNotFound(err) {
        // 리소스가 없음 - 생성 필요
        return r.createDeployment(ctx, website)
    }
    return ctrl.Result{}, err
}

// 리소스 업데이트
if err := r.Update(ctx, &deployment); err != nil {
    return ctrl.Result{}, err
}

// 상태 업데이트
website.Status.AvailableReplicas = deployment.Status.AvailableReplicas
if err := r.Status().Update(ctx, website); err != nil {
    return ctrl.Result{}, err
}
```

#### **에러 처리**

```go
// 리소스가 없을 때 (정상적인 상황)
return ctrl.Result{}, client.IgnoreNotFound(err)

// 재시도가 필요한 에러
return ctrl.Result{Requeue: true}, err

// 일정 시간 후 재시도
return ctrl.Result{RequeueAfter: time.Minute}, nil
```
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

kubebuilder의 기본 사용법을 학습했습니다. 이제 실제 컨트롤러를 구현해보겠습니다:

- [컨트롤러 개발](./05-controller-development.md) - CRD의 비즈니스 로직을 구현하는 컨트롤러 개발
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
