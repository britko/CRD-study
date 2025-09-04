# 첫 번째 CRD 만들기

## 실습 개요

이 가이드에서는 [개발 환경 설정](./02-environment-setup.md)에서 생성한 `simple-crd` 프로젝트를 사용하여 간단한 `Website` CRD를 만들어보고, 이를 Kubernetes 클러스터에 배포해보겠습니다.

**📋 사전 준비사항**
- [개발 환경 설정](./02-environment-setup.md) 완료
- `simple-crd` 프로젝트 생성 완료
- Kubernetes 클러스터 (kind 또는 minikube) 실행 중

## 1단계: 프로젝트 구조 확인

먼저 [개발 환경 설정](./02-environment-setup.md)에서 생성한 `simple-crd` 프로젝트의 구조를 확인해보세요.

```bash
# 프로젝트 디렉토리로 이동
cd simple-crd

# 프로젝트 전체 구조 확인
ls -la

# kubebuilder가 생성한 디렉토리 구조 확인
tree .  # 또는 ls -R (tree 명령어가 없는 경우)
```

**📁 kubebuilder 프로젝트 구조:**
```
simple-crd/
├── api/                    # API 타입 정의
│   └── v1/
│       ├── website_types.go    # Website 타입 정의
│       ├── website_webhook.go  # 웹훅 (선택사항)
│       └── groupversion_info.go
├── config/                 # 배포 설정
│   ├── crd/              # CRD 매니페스트
│   │   ├── bases/        # CRD 기본 정의
│   │   ├── patches/      # CRD 패치
│   │   └── kustomization.yaml
│   ├── rbac/             # RBAC 설정
│   ├── manager/          # 매니저 배포
│   └── webhook/          # 웹훅 설정 (선택사항)
├── controllers/           # 컨트롤러 구현
│   └── website_controller.go
├── hack/                  # 유틸리티 스크립트
├── main.go               # 메인 함수
├── Makefile              # 빌드 및 배포
└── go.mod                # Go 모듈
```

**📝 주요 구성 요소:**
- **API 그룹**: `mygroup.example.com` (02에서 설정한 그룹)
- **버전**: `v1`
- **리소스 종류**: `Website`
- **스코프**: `Namespaced` (네임스페이스별로 관리)

## 2단계: CRD 배포

```bash
# 프로젝트 디렉토리에서
cd simple-crd

# kubebuilder로 CRD 배포 (권장)
make install

# 배포 확인
kubectl get crd | grep mygroup.example.com
kubectl describe crd websites.mygroup.example.com

# 또는 직접 kubectl 사용 (kustomization.yaml 사용)
kubectl apply -k config/crd/

# 또는 개별 파일 사용
kubectl apply -f config/crd/bases/mygroup.example.com_websites.yaml
```

**📝 참고**: 
- 이 단계에서는 초기 CRD만 설치합니다
- 4단계에서 API 타입을 수정한 후 `make install`로 CRD를 재설치해야 합니다
- 컨트롤러 이미지 빌드와 로드는 4단계에서 진행합니다

## 3단계: CRD 상태 확인

```bash
# CRD 목록 확인
kubectl get crd

# Website CRD 상세 정보 (02에서 설정한 그룹 사용)
kubectl describe crd websites.mygroup.example.com

# CRD 스키마 확인
kubectl get crd websites.mygroup.example.com -o yaml

# API 리소스 확인
kubectl api-resources | grep website
```

## 4단계: CRD 스키마 수정 및 재설치

```bash
# 프로젝트 디렉토리에서
cd simple-crd

# 1. API 타입 정의 수정 (Go 소스 코드 수정)
vi api/v1/website_types.go

# WebsiteSpec 구조체에 필요한 필드 추가
# 예시:
# type WebsiteSpec struct {
#     URL      string `json:"url"`
#     Replicas int    `json:"replicas"`
#     Image    string `json:"image"`
#     Port     int    `json:"port"`
# }

# Website 타입에 short-name 및 컬럼 추가 (선택사항)
# +kubebuilder:resource:shortName=ws
# +kubebuilder:printcolumn:name="URL",type="string",JSONPath=".spec.url"
# +kubebuilder:printcolumn:name="Replicas",type="integer",JSONPath=".spec.replicas"
# +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"

# 2. kubebuilder가 자동으로 CRD YAML 생성
make manifests

# 3. 생성된 CRD 확인
cat config/crd/bases/mygroup.example.com_websites.yaml

# 4. 수정된 CRD 재설치
make install
```

**📝 참고**: 
- **Go 소스 코드 수정**: `api/v1/website_types.go`에서 API 타입 정의
- **자동 생성**: `make manifests`로 kubebuilder가 CRD YAML 자동 생성
- **직접 수정 금지**: `config/crd/bases/` 파일을 직접 수정하면 `make manifests` 실행 시 덮어써짐

**🔧 API 타입 수정 상세 가이드**:

1. **`api/v1/website_types.go` 파일 열기**
2. **`WebsiteSpec` 구조체 찾기** (보통 30-50번째 줄 근처)
3. **필요한 필드 추가**:
   ```go
   type WebsiteSpec struct {
       // 기존 필드들...
       
       // 새로 추가할 필드들
       URL      string `json:"url"`
       Replicas int    `json:"replicas"`
       Image    string `json:"image"`
       Port     int    `json:"port"`
   }
   ```
4. **short-name 및 컬럼 추가** (선택사항):
   ```go
   // +kubebuilder:resource:shortName=ws
   // +kubebuilder:printcolumn:name="URL",type="string",JSONPath=".spec.url"
   // +kubebuilder:printcolumn:name="Replicas",type="integer",JSONPath=".spec.replicas"
   // +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"
   type Website struct {
       metav1.TypeMeta   `json:",inline"`
       metav1.ObjectMeta `json:"metadata,omitempty"`
       
       Spec   WebsiteSpec   `json:"spec,omitempty"`
       Status WebsiteStatus `json:"status,omitempty"`
   }
   ```
5. **파일 저장 후 `make manifests` 실행**

## 5단계: 컨트롤러 배포

```bash
# 프로젝트 디렉토리에서
cd simple-crd

# 1. 이미지 빌드
make docker-build

# 2. kind 클러스터에 이미지 로드
kind load docker-image controller:latest --name crd-study

# 3. imagePullPolicy 추가 (⚠️중요!)
vi config/manager/manager.yaml

# 4. kubebuilder로 컨트롤러 배포
make deploy

# 배포 상태 확인
kubectl get pods -n simple-crd-system
kubectl get deployment -n simple-crd-system
```

**📝 참고**: 이 단계에서는 컨트롤러 이미지를 빌드하고 Kubernetes 클러스터에 배포합니다.

## 6단계: Custom Resource 생성 및 확인

```bash
# 예제 Website 리소스 생성 (수정된 스키마에 맞춰서)
kubectl apply -f - <<EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: my-website
  namespace: default
spec:
  url: "https://my-website.example.com"
  replicas: 3
  image: "nginx:alpine"
  port: 80
EOF

# 리소스 생성 확인
kubectl get websites
kubectl get ws  # shortNames 사용 (short-name 추가 시)

# 특정 Website 리소스 상세 정보
kubectl describe website my-website

# 📚 추가 학습: fieldsV1과 Server-Side Apply

`kubectl describe website my-website` 실행 시 `fieldsV1` 섹션이 보입니다. 이는 Kubernetes의 **Server-Side Apply (SSA)** 기능과 관련된 메타데이터입니다.

## **fieldsV1이란?**

- **역할**: 리소스의 각 필드가 어떤 사용자/컨트롤러에 의해 설정되었는지 추적
- **용도**: 필드 소유권(ownership)과 충돌 해결을 위한 메타데이터
- **자동 생성**: `kubectl apply` 사용 시 자동으로 생성됨

## **fieldsV1 구조 예시**

```yaml
fieldsV1:
  f:spec:
    .:                    # spec 필드 자체가 설정됨
    f:url:               # url 필드가 설정됨
    f:replicas:          # replicas 필드가 설정됨
    f:image:             # image 필드가 설정됨
    f:port:              # port 필드가 설정됨
```

## **Server-Side Apply (SSA)**

### **언제 사용하는가?**
- **GitOps**: Git 기반 배포 및 관리
- **협업**: 여러 개발자가 같은 리소스 관리
- **CI/CD**: 자동화된 배포 파이프라인
- **점진적 업데이트**: 기존 설정 유지하면서 수정

### **장점**
- **필드 소유권 추적**: 누가 언제 어떤 필드를 설정했는지 기록
- **충돌 해결**: 여러 사용자 수정 시 자동으로 충돌 방지
- **병합 전략**: 기존 필드와 새 필드를 안전하게 병합

### **사용 방법**
```bash
# Server-Side Apply (권장)
kubectl apply -f website.yaml

# Client-Side Apply (레거시)
kubectl apply --server-side=false -f website.yaml
```

## **정리**

- **`fieldsV1`**: 커스텀 리소스 생성 시 자동으로 생성되는 메타데이터
- **설정 불필요**: CRD 정의나 컨트롤러 코드에 추가 설정 불필요
- **자동 동작**: `kubectl apply` 사용 시 Kubernetes가 자동으로 처리
- **무시해도 됨**: 일반 사용자에게는 직접적인 의미가 없음

# YAML 형태로 확인
kubectl get website my-website -o yaml

# 컨트롤러 로그 확인
kubectl logs -n simple-crd-system deployment/simple-crd-controller-manager
```

**📝 참고**: 이 단계에서는 수정된 CRD 스키마에 맞는 Custom Resource를 생성하고 정상 작동을 확인합니다.

**🔍 short-name 및 자동완성 확인**:
```bash
# short-name 확인
kubectl api-resources | grep website

# 자동완성 확인 (short-name 추가 시)
kubectl get ws  # short-name 사용
kubectl get websites  # 전체 이름 사용

# 컬럼 표시 확인 (printcolumn 추가 시)
kubectl get websites -o wide
```

## 7단계: 리소스 수정

```bash
# 리소스 편집
kubectl edit website my-website

# 또는 직접 YAML 수정 후 적용
kubectl apply -f - <<EOF
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: my-website
  namespace: default
spec:
  url: "https://my-website.example.com"
  replicas: 5  # 복제본 수 증가
  image: "nginx:1.21-alpine"  # 이미지 버전 변경
  port: 8080  # 포트 변경
EOF

# 수정된 리소스 확인
kubectl get website my-website -o yaml
```

**📝 참고**: 이 단계에서는 생성된 Custom Resource를 수정하고 변경사항을 확인합니다.

## 8단계: 정리

```bash
# 프로젝트 디렉토리에서
cd simple-crd

# 모든 리소스 정리 (권장)
make undeploy

# 프로젝트 디렉토리 정리 (선택사항)
cd ..
rm -rf simple-crd
```

**📝 정리 내용**:
- **컨트롤러**: 실행 중인 컨트롤러 Pod 삭제
- **CRD**: Website 타입 정의 삭제
- **Custom Resource**: 생성했던 my-website 리소스 삭제
- **기타**: 관련된 모든 Kubernetes 리소스 삭제

**💡 팁**: `make undeploy` 하나의 명령어로 모든 것이 깔끔하게 정리됩니다!

## 실습 결과

이 실습을 통해 다음을 배울 수 있습니다:

1. **CRD 정의**: OpenAPI v3 스키마를 사용한 리소스 정의
2. **CRD 배포**: Kubernetes 클러스터에 CRD 등록
3. **Custom Resource 생성**: 정의된 스키마에 맞는 리소스 인스턴스 생성
4. **리소스 관리**: kubectl을 사용한 CRUD 작업
5. **스키마 검증**: 필수 필드, 타입, 범위 검증

## 다음 단계

축하합니다! 첫 번째 CRD를 성공적으로 만들고 배포했습니다. 이제 더 고급 기능을 학습해보겠습니다:

- [kubebuilder 사용법](./04-kubebuilder-guide.md) - kubebuilder 프레임워크의 고급 기능 활용
- [컨트롤러 개발](./05-controller-development.md) - CRD의 비즈니스 로직을 구현하는 컨트롤러 개발

## 문제 해결

### CRD가 생성되지 않는 경우
```bash
# API 서버 로그 확인
kubectl logs -n kube-system kube-apiserver-kind-control-plane

# CRD 상태 확인
kubectl get crd websites.example.com -o yaml
```

### 리소스 생성이 안 되는 경우
```bash
# CRD 상태 확인
kubectl get crd websites.example.com

# 이벤트 확인
kubectl get events --sort-by='.lastTimestamp'
```
