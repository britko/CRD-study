# 첫 번째 CRD 만들기

## 실습 개요

이 가이드에서는 간단한 `Website` CRD를 만들어보고, 이를 Kubernetes 클러스터에 배포해보겠습니다.

## 1단계: CRD 정의 파일 생성

먼저 `examples/simple-crd/website-crd.yaml` 파일을 확인해보세요. 이 파일은 Website 리소스의 스키마를 정의합니다.

주요 구성 요소:
- **API 그룹**: `example.com`
- **버전**: `v1`
- **리소스 종류**: `Website`
- **스코프**: `Namespaced` (네임스페이스별로 관리)

## 2단계: CRD 배포

```bash
# CRD 배포
make deploy-crd

# 또는 직접 kubectl 사용
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
# 예제 Website 리소스 배포
make deploy-example

# 또는 직접 kubectl 사용
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
kubectl apply -f examples/simple-crd/website-example.yaml
```

## 7단계: 정리

```bash
# 모든 리소스 정리
make clean

# 또는 단계별로 정리
make delete-example
make delete-crd
```

## 실습 결과

이 실습을 통해 다음을 배울 수 있습니다:

1. **CRD 정의**: OpenAPI v3 스키마를 사용한 리소스 정의
2. **CRD 배포**: Kubernetes 클러스터에 CRD 등록
3. **Custom Resource 생성**: 정의된 스키마에 맞는 리소스 인스턴스 생성
4. **리소스 관리**: kubectl을 사용한 CRUD 작업
5. **스키마 검증**: 필수 필드, 타입, 범위 검증

## 다음 단계

- [kubebuilder 사용법](./04-kubebuilder-guide.md)
- [컨트롤러 개발](./05-controller-development.md)

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
