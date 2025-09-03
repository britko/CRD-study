# 첫 번째 CRD 만들기

## 실습 개요

이 가이드에서는 [개발 환경 설정](./02-environment-setup.md)에서 생성한 `simple-crd` 프로젝트를 사용하여 간단한 `Website` CRD를 만들어보고, 이를 Kubernetes 클러스터에 배포해보겠습니다.

**📋 사전 준비사항**
- [개발 환경 설정](./02-environment-setup.md) 완료
- `simple-crd` 프로젝트 생성 완료
- Kubernetes 클러스터 (kind 또는 minikube) 실행 중

## 1단계: CRD 정의 파일 생성

먼저 [개발 환경 설정](./02-environment-setup.md)에서 생성한 `simple-crd` 프로젝트의 CRD 정의를 확인해보세요. kubebuilder가 자동으로 생성한 CRD 관련 파일들은 `config/crd/` 디렉토리에 있습니다.

```bash
# 프로젝트 디렉토리로 이동
cd simple-crd

# CRD 디렉토리 구조 확인
ls config/crd/
cat config/crd/kustomization.yaml

# CRD 매니페스트 확인 (kustomization.yaml에서 참조하는 파일들)
ls config/crd/patches/
ls config/crd/bases/  # 이 디렉토리가 있을 수도 있음

# 또는 전체 CRD 매니페스트 생성 확인
make manifests
ls config/crd/bases/
```

**📝 참고**: kubebuilder 버전에 따라 디렉토리 구조가 다를 수 있습니다. `make manifests` 명령어를 실행하면 최신 구조로 CRD 매니페스트가 생성됩니다.

주요 구성 요소:
- **API 그룹**: `example.com`
- **버전**: `v1`
- **리소스 종류**: `Website`
- **스코프**: `Namespaced` (네임스페이스별로 관리)

## 2단계: CRD 배포

```bash
# 프로젝트 디렉토리에서
cd simple-crd

# kubebuilder로 CRD 배포 (권장)
make install

# 또는 직접 kubectl 사용 (kustomization.yaml 사용)
kubectl apply -k config/crd/

# 또는 개별 파일 사용 (파일이 존재하는 경우)
kubectl apply -f config/crd/bases/mygroup.example.com_websites.yaml

# 또는 이 레포지토리의 예제 사용
kubectl apply -f examples/simple-crd/website-crd.yaml
```

## 3단계: CRD 상태 확인

```bash
# CRD 목록 확인
kubectl get crd

# Website CRD 상세 정보
kubectl describe crd websites.example.com

# CRD 스키마 확인
kubectl get crd websites.example.com -o yaml
```

## 4단계: Custom Resource 생성

```bash
# 프로젝트 디렉토리에서
cd simple-crd

# kubebuilder로 컨트롤러 배포
make deploy

# 예제 Website 리소스 생성
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

# 또는 이 레포지토리의 예제 사용
kubectl apply -f examples/simple-crd/website-example.yaml
```

## 5단계: 리소스 확인

```bash
# Website 리소스 목록 확인
kubectl get websites
kubectl get ws  # shortNames 사용

# 특정 Website 리소스 상세 정보
kubectl describe website my-website

# YAML 형태로 확인
kubectl get website my-website -o yaml
```

## 6단계: 리소스 수정

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
```

## 7단계: 정리

```bash
# 프로젝트 디렉토리에서
cd simple-crd

# kubebuilder로 리소스 정리
make uninstall

# 또는 단계별로 정리
kubectl delete website my-website

# CRD 정리 (kustomization.yaml 사용)
kubectl delete -k config/crd/

# 또는 개별 파일 사용 (파일이 존재하는 경우)
kubectl delete -f config/crd/bases/mygroup.example.com_websites.yaml

# 프로젝트 디렉토리 정리 (선택사항)
cd ..
rm -rf simple-crd
```

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
