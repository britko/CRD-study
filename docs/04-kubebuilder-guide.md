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

#### **object:root 마커**
```go
//+kubebuilder:object:root=true
```
- **역할**: 이 구조체가 Kubernetes API의 루트 오브젝트임을 표시
- **필수성**: CRD의 메인 리소스 타입에 반드시 필요
- **효과**: `make generate` 실행 시 Deep Copy 함수와 Scheme 등록 코드 생성
- **사용법**: `Website` 구조체 위에 배치

#### **subresource:status 마커**
```go
//+kubebuilder:subresource:status
```
- **역할**: Status 서브리소스를 활성화하여 상태 정보를 별도로 관리
- **효과**: `kubectl get`과 `kubectl describe`에서 Status 정보 표시
- **사용법**: Status 필드가 있는 구조체에 적용

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

#### **make generate vs make manifests**

**`make generate`**:
- **역할**: Go 코드 자동 생성
- **생성 파일**: `zz_generated.deepcopy.go` (항상), `zz_generated.openapi.go` (필요시)
- **사용 시기**: API 타입 정의 후, 빌드 전
- **생성 내용**: Deep Copy 함수, OpenAPI 스키마 (선택사항) 등

**`make manifests`**:
- **역할**: Kubernetes 매니페스트 생성
- **생성 파일**: `config/crd/bases/*.yaml`, RBAC 설정 등
- **사용 시기**: API 타입 정의 후, 배포 전
- **생성 내용**: CRD YAML, RBAC 매니페스트 등

#### **생성되는 파일들**

```bash
# make generate 실행 후 생성되는 파일들
api/v1/
├── zz_generated.deepcopy.go    # Deep Copy 함수 (항상 생성)
└── zz_generated.openapi.go     # OpenAPI 스키마 (필요시에만 생성)
└── zz_generated.conversion.go  # 변환 함수 (버전 변환시에만 생성)

# make manifests 실행 후 생성되는 파일들
config/
├── crd/bases/mygroup.example.com_websites.yaml  # CRD 정의
├── rbac/role.yaml                               # RBAC 설정
└── manager/manager.yaml                         # 매니저 배포
```

#### **실행 순서**

```bash
# 1. API 타입 정의 수정
vi api/v1/website_types.go

# 2. Go 코드 생성 (Deep Copy 등)
make generate

# 3. Kubernetes 매니페스트 생성
make manifests

# 4. 빌드
make build
```

#### **OpenAPI 스키마 생성 (선택사항)**

OpenAPI 스키마가 필요한 경우:

```bash
# OpenAPI 스키마 생성
make generate OPENAPI=1

# 또는 controller-gen 직접 사용
controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..." openapi
```

**OpenAPI 스키마가 필요한 경우**:
- 고급 검증 규칙이 필요할 때
- API 문서 자동 생성이 필요할 때
- OpenAPI 기반 클라이언트 코드 생성 시

**기본적으로는 생성되지 않음**:
- CRD 검증은 OpenAPI 스키마 없이도 가능
- 성능상 불필요한 파일 생성 방지

### 2. 빌드

```bash
# 컨트롤러 빌드
make build
```

### 3. 배포

```bash
# 1. CRD 배포
make install

# 2. Docker 이미지 빌드
make docker-build

# 3. kind 클러스터에 이미지 로드 (kind 사용 시)
kind load docker-image controller:latest --name crd-study

# 4. imagePullPolicy 추가 (중요!)
vi config/manager/manager.yaml
# imagePullPolicy: IfNotPresent 추가

# 5. 컨트롤러 배포
make deploy
```

**📝 참고**: 
- **kind 사용 시**: `kind load docker-image` 명령으로 이미지 로드 필요
- **minikube 사용 시**: `eval $(minikube docker-env)` 후 `make docker-build`
- **imagePullPolicy**: 로컬 이미지 사용을 위해 `IfNotPresent`로 설정

## 실제 리소스 배포 및 확인

컨트롤러가 정상적으로 배포되었는지 확인하기 위해 실제 Website 리소스를 배포하고 테스트해보겠습니다.

### 1. 기본 샘플 리소스 배포

kubebuilder가 생성한 기본 샘플 리소스는 빈 스펙으로 되어 있습니다. CRD 검증 규칙에 맞게 수정해야 합니다:

```bash
# 1. 샘플 리소스 확인 (빈 스펙 상태)
cat config/samples/mygroup_v1_website.yaml

# 2. 샘플 리소스에 스펙 추가
cat > config/samples/mygroup_v1_website.yaml << EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  labels:
    app.kubernetes.io/name: advanced-crd-project
    app.kubernetes.io/managed-by: kustomize
  name: website-sample
spec:
  url: "https://example.com"
  replicas: 3
  image: "nginx:alpine"
  port: 80
EOF

# 3. 수정된 샘플 리소스 배포
kubectl apply -f config/samples/mygroup_v1_website.yaml

# 4. 리소스 상태 확인
kubectl get websites
kubectl get website website-sample -o yaml

# 5. 리소스 상세 정보 확인
kubectl describe website website-sample

# 6. 컨트롤러 로그에서 조정 과정 확인
kubectl logs -f -n advanced-crd-project-system deployment/advanced-crd-project-controller-manager

# 7. 리소스 이벤트 확인
kubectl get events --field-selector involvedObject.name=website-sample

# 8. 테스트 완료 후 리소스 정리
kubectl delete -f config/samples/mygroup_v1_website.yaml
```

**📝 참고**: 기본 샘플 리소스는 빈 스펙이므로 CRD 검증 규칙에 맞게 다음 스펙을 추가해야 합니다:
- `url: "https://example.com"` (필수 필드)
- `replicas: 3` (기본값)
- `image: "nginx:alpine"` (기본값)
- `port: 80` (기본값)

### 2. 추가 테스트 및 확인

기본 샘플 리소스 배포 후 추가적인 테스트를 진행해보겠습니다:

```bash
# 리소스 수정 테스트
kubectl patch website website-sample --type='merge' -p='{"spec":{"replicas":5}}'
kubectl get website website-sample -o jsonpath='{.spec.replicas}'

# 다른 설정값으로 새 리소스 생성
cat > /tmp/test-website.yaml << EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: test-website
spec:
  url: "https://test.example.com"
  replicas: 2
  image: "httpd:alpine"
  port: 8080
EOF

kubectl apply -f /tmp/test-website.yaml
kubectl get websites
kubectl delete -f /tmp/test-website.yaml
rm /tmp/test-website.yaml

# 시스템 상태 종합 확인
kubectl get crd websites.mygroup.example.com
kubectl get pods -n advanced-crd-project-system
kubectl api-resources | grep mygroup
```

## 테스트

### 1. 단위 테스트

#### **테스트 코드 구조**

kubebuilder가 자동으로 생성한 테스트 파일 `internal/controller/website_controller_test.go`:

```go
package controller

import (
    "context"

    . "github.com/onsi/ginkgo/v2"
    . "github.com/onsi/gomega"
    "k8s.io/apimachinery/pkg/api/errors"
    "k8s.io/apimachinery/pkg/types"
    "sigs.k8s.io/controller-runtime/pkg/reconcile"

    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    mygroupv1 "github.com/britko/advanced-crd-project/api/v1"
)

var _ = Describe("Website Controller", func() {
    Context("When reconciling a resource", func() {
        const resourceName = "test-resource"

        ctx := context.Background()

        typeNamespacedName := types.NamespacedName{
            Name:      resourceName,
            Namespace: "default",
        }
        website := &mygroupv1.Website{}

        BeforeEach(func() {
            By("creating the custom resource for the Kind Website")
            err := k8sClient.Get(ctx, typeNamespacedName, website)
            if err != nil && errors.IsNotFound(err) {
                resource := &mygroupv1.Website{
                    ObjectMeta: metav1.ObjectMeta{
                        Name:      resourceName,
                        Namespace: "default",
                    },
                    Spec: mygroupv1.WebsiteSpec{
                        URL:      "https://example.com",
                        Replicas: 3,
                        Image:    "nginx:alpine",
                        Port:     80,
                    },
                }
                Expect(k8sClient.Create(ctx, resource)).To(Succeed())
            }
        })

        AfterEach(func() {
            resource := &mygroupv1.Website{}
            err := k8sClient.Get(ctx, typeNamespacedName, resource)
            Expect(err).NotTo(HaveOccurred())

            By("Cleanup the specific resource instance Website")
            Expect(k8sClient.Delete(ctx, resource)).To(Succeed())
        })

        It("should successfully reconcile the resource", func() {
            By("Reconciling the created resource")
            controllerReconciler := &WebsiteReconciler{
                Client: k8sClient,
                Scheme: k8sClient.Scheme(),
            }

            _, err := controllerReconciler.Reconcile(ctx, reconcile.Request{
                NamespacedName: typeNamespacedName,
            })
            Expect(err).NotTo(HaveOccurred())
        })
    })
})
```

#### **테스트 프레임워크**

- **Ginkgo**: BDD 스타일 테스트 프레임워크
- **Gomega**: 매처 라이브러리
- **envtest**: Kubernetes API 서버 테스트 환경

#### **테스트 구조**

1. **BeforeEach**: 테스트 전 Website 리소스 생성
2. **AfterEach**: 테스트 후 리소스 정리
3. **It**: 실제 테스트 케이스 실행

#### **중요한 포인트**

- **검증 규칙 준수**: 테스트 데이터가 CRD 검증 규칙을 만족해야 함
- **리소스 정리**: 테스트 후 생성된 리소스 반드시 삭제
- **envtest 환경**: 실제 Kubernetes 클러스터 없이 테스트 가능

#### **테스트 실행**

```bash
# 테스트 실행
make test

# 특정 테스트 실행
go test ./internal/controller/ -v
```

### 2. 통합 테스트 (E2E 테스트)

```bash
# 1. 현재 kubectl context 백업
kubectl config current-context > /tmp/original-context.txt

# 2. E2E 테스트 환경 설정 (Kind 클러스터 생성)
make setup-test-e2e

# 3. E2E 테스트 실행
make test-e2e

# 4. E2E 테스트 환경 정리
make cleanup-test-e2e

# 5. 원래 kubectl context로 복원
kubectl config use-context $(cat /tmp/original-context.txt)
```

#### **E2E 테스트 설명**

- **setup-test-e2e**: Kind 클러스터를 생성하여 E2E 테스트 환경을 준비
- **test-e2e**: 실제 Kubernetes 클러스터에서 통합 테스트 실행
- **cleanup-test-e2e**: 테스트용 Kind 클러스터 삭제

#### **⚠️ 중요: kubectl context 관리**

E2E 테스트는 별도의 Kind 클러스터를 생성하므로 kubectl context가 변경될 수 있습니다:

```bash
# 테스트 전 현재 context 확인
kubectl config current-context
# 예: kind-crd-study

# E2E 테스트 실행 후 context 확인
kubectl config current-context
# 예: kind-test (테스트용 클러스터로 변경됨)

# 원래 context로 복원
kubectl config use-context kind-crd-study
```

#### **Context 복원 방법들**

```bash
# 방법 1: 백업 파일 사용 (권장)
kubectl config current-context > /tmp/original-context.txt
# ... 테스트 실행 ...
kubectl config use-context $(cat /tmp/original-context.txt)

# 방법 2: 직접 context 이름 지정
kubectl config use-context kind-crd-study

# 방법 3: 사용 가능한 context 목록 확인
kubectl config get-contexts
```

#### **E2E 테스트 vs 단위 테스트**

| 구분 | 단위 테스트 (`make test`) | E2E 테스트 (`make test-e2e`) |
|------|-------------------------|---------------------------|
| **테스트 파일** | `internal/controller/website_controller_test.go` | `test/e2e/e2e_test.go` |
| **환경** | envtest (가상 API 서버) | 실제 Kind 클러스터 |
| **속도** | 빠름 | 느림 |
| **범위** | 컨트롤러 로직만 | 전체 시스템 통합 |
| **용도** | 개발 중 빠른 피드백 | 배포 전 최종 검증 |

#### **E2E 테스트 코드 구조**

E2E 테스트는 별도의 테스트 파일 `test/e2e/e2e_test.go`를 사용합니다:

```go
//go:build e2e
// +build e2e

package e2e

import (
    . "github.com/onsi/ginkgo/v2"
    . "github.com/onsi/gomega"
    "github.com/britko/advanced-crd-project/test/utils"
)

var _ = Describe("Manager", Ordered, func() {
    BeforeAll(func() {
        By("creating manager namespace")
        // kubectl create ns advanced-crd-project-system
        
        By("installing CRDs")
        // make install
        
        By("deploying the controller-manager")
        // make deploy
    })

    AfterAll(func() {
        By("undeploying the controller-manager")
        // make undeploy
        
        By("uninstalling CRDs")
        // make uninstall
    })

    Context("Manager", func() {
        It("should run successfully", func() {
            // 컨트롤러 Pod가 정상 실행되는지 확인
        })

        It("should ensure the metrics endpoint is serving metrics", func() {
            // 메트릭 엔드포인트가 정상 작동하는지 확인
        })
    })
})
```

#### **E2E 테스트 특징**

- **실제 클러스터**: Kind 클러스터에서 실제 배포 테스트
- **전체 워크플로우**: CRD 설치 → 컨트롤러 배포 → 기능 테스트 → 정리
- **시스템 검증**: 컨트롤러 Pod 상태, 메트릭 엔드포인트, RBAC 등 전체 시스템 검증
- **자동 정리**: 테스트 후 모든 리소스 자동 삭제

## 문제 해결 및 디버깅

### 일반적인 문제들

1. **CRD 생성 실패**: API 서버 버전 호환성 확인
2. **컨트롤러 시작 실패**: RBAC 권한 및 의존성 확인
3. **리소스 조정 실패**: 로그 및 이벤트 확인
4. **테스트 실패**: 검증 규칙에 맞지 않는 테스트 데이터

### 디버깅 방법

#### **1. 로그 확인**

```bash
# 컨트롤러 로그 확인
kubectl logs -n advanced-crd-project-system deployment/advanced-crd-project-controller-manager

# 특정 리소스 이벤트 확인 (샘플 리소스가 있다면)
kubectl describe website website-sample

# 실시간 로그 모니터링
kubectl logs -f -n advanced-crd-project-system deployment/advanced-crd-project-controller-manager
```

#### **2. 로컬 실행**

```bash
# 컨트롤러를 로컬에서 실행 (디버깅용)
make run

# 특정 로그 레벨로 실행
make run ARGS="--zap-log-level=debug"
```

#### **3. 리소스 상태 확인**

```bash
# CRD 상태 확인
kubectl get crd websites.mygroup.example.com -o yaml

# 컨트롤러 Pod 상태 확인
kubectl get pods -n advanced-crd-project-system

# 이벤트 확인
kubectl get events -n advanced-crd-project-system --sort-by=.lastTimestamp
```

#### **4. 디버깅을 위한 리소스 배포**

문제가 발생했을 때 디버깅을 위해 리소스를 배포하고 확인하는 방법:

```bash
# 기본 샘플 리소스로 빠른 테스트
kubectl apply -f config/samples/mygroup_v1_website.yaml
kubectl describe website website-sample
kubectl delete -f config/samples/mygroup_v1_website.yaml

# 완전한 스펙으로 상세 테스트
cat > /tmp/debug-website.yaml << EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: debug-website
spec:
  url: "https://debug.example.com"
  replicas: 2
  image: "nginx:alpine"
  port: 8080
EOF

kubectl apply -f /tmp/debug-website.yaml
kubectl describe website debug-website
kubectl delete -f /tmp/debug-website.yaml
rm /tmp/debug-website.yaml
```

#### **테스트 실패 해결**

테스트에서 Website 리소스 생성 시 검증 규칙을 준수해야 합니다:

```go
// 잘못된 예시 (테스트 실패)
resource := &mygroupv1.Website{
    ObjectMeta: metav1.ObjectMeta{
        Name:      "test-resource",
        Namespace: "default",
    },
    // Spec 필드가 없음 - 검증 실패
}

// 올바른 예시 (테스트 성공)
resource := &mygroupv1.Website{
    ObjectMeta: metav1.ObjectMeta{
        Name:      "test-resource",
        Namespace: "default",
    },
    Spec: mygroupv1.WebsiteSpec{
        URL:      "https://example.com",  // 검증 규칙 준수
        Replicas: 3,
        Image:    "nginx:alpine",
        Port:     80,
    },
}
```

### 유용한 명령어

```bash
# CRD 상태 확인
kubectl get crd

# 컨트롤러 상태 확인
kubectl get pods -n advanced-crd-project-system

# API 리소스 확인
kubectl api-resources | grep mygroup
```

## 실습 결과

kubebuilder를 사용하여 CRD와 컨트롤러를 성공적으로 생성하고 배포했습니다. 다음과 같은 결과를 얻었습니다:

### ✅ **완성된 프로젝트 구조**

```
advanced-crd-project/
├── api/v1/
│   ├── website_types.go           # Website CRD 정의
│   └── zz_generated.deepcopy.go   # 자동 생성된 Deep Copy 함수
├── internal/controller/
│   ├── website_controller.go      # 컨트롤러 구현
│   └── website_controller_test.go # 단위 테스트
├── config/
│   ├── crd/bases/                 # CRD 매니페스트
│   ├── manager/                   # 컨트롤러 배포 설정
│   └── samples/                   # 샘플 리소스
└── test/e2e/                      # E2E 테스트
```

### 🎯 **배포된 리소스**

```bash
# CRD 확인
kubectl get crd websites.mygroup.example.com

# 컨트롤러 확인
kubectl get pods -n advanced-crd-project-system

# 샘플 리소스 확인
kubectl get websites
kubectl describe website website-sample
```

### 🔧 **사용 가능한 기능**

- **CRD 검증**: URL 패턴, 복제본 수 범위 등 자동 검증
- **shortName**: `kubectl get ws`로 간단한 명령어 사용
- **printcolumn**: `kubectl get websites`에서 URL, Replicas 등 컬럼 표시
- **컨트롤러**: Website 리소스 변경 감지 및 조정
- **테스트**: 단위 테스트 및 E2E 테스트 환경 구축

### 📊 **학습한 내용**

1. **kubebuilder 프로젝트 생성**: `kubebuilder init` 및 `kubebuilder create api`
2. **API 타입 정의**: Go 구조체로 CRD 스키마 정의
3. **kubebuilder 마커**: 검증 규칙, 기본값, shortName, printcolumn 설정
4. **코드 생성**: `make generate`, `make manifests`로 자동 코드 생성
5. **빌드 및 배포**: Docker 이미지 빌드, Kind 클러스터 배포
6. **실제 리소스 테스트**: 샘플 리소스 배포 및 동작 확인
7. **테스트**: 단위 테스트와 E2E 테스트 실행
8. **디버깅**: 로그 확인, 리소스 상태 점검, 문제 해결

## 다음 단계

kubebuilder의 기본 사용법을 학습했습니다. 이제 실제 컨트롤러를 구현해보겠습니다:

- [컨트롤러 개발](./05-controller-development.md) - CRD의 비즈니스 로직을 구현하는 컨트롤러 개발
- [웹훅 구현](./06-webhooks.md) - 검증 및 변환 웹훅 구현

**📝 참고**: 다음 문서들에서는 이번에 생성한 `advanced-crd-project`를 계속 사용하여 컨트롤러의 실제 비즈니스 로직을 구현하고 웹훅을 추가해보겠습니다.
