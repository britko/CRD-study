# Kubernetes CRD (Custom Resource Definition) 학습 레포지토리

이 레포지토리는 Kubernetes CRD에 대한 학습과 실습을 위한 것입니다.

## 🎯 학습 목표

- Kubernetes CRD의 기본 개념 이해
- CRD 개발 및 배포 방법 학습
- kubebuilder를 사용한 컨트롤러 개발
- 실제 프로덕션 환경에서의 CRD 활용

## 📚 학습 순서

### 1단계: 기본 개념
- [CRD 기본 개념](./docs/01-basic-concepts.md)
- [개발 환경 설정](./docs/02-environment-setup.md)
- [첫 번째 CRD 만들기](./docs/03-first-crd.md)

### 2단계: 실습
- [간단한 CRD 예제](./examples/simple-crd/)
- [kubebuilder 사용법](./docs/04-kubebuilder-guide.md)
- [컨트롤러 개발](./docs/05-controller-development.md)

### 3단계: 고급 기능
- [웹훅 구현](./docs/06-webhooks.md)
- [검증 및 기본값 설정](./docs/07-validation-defaulting.md)
- [CRD 버전 관리](./docs/08-versioning.md)

## 🛠️ 필요한 도구

- kubectl
- kind 또는 minikube
- Go 1.19+
- kubebuilder
- make

## 🚀 빠른 시작

```bash
# 저장소 클론
git clone <repository-url>
cd CRD-study

# 개발 환경 설정
make setup

# 첫 번째 CRD 배포
make deploy-simple-crd
```

## 📖 참고 자료

- [Kubernetes 공식 CRD 문서](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [kubebuilder 공식 문서](https://book.kubebuilder.io/)
- [Kubernetes API 컨벤션](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)

## 🤝 기여하기

이 레포지토리에 기여하고 싶으시다면 Pull Request를 보내주세요!

## �� 라이선스

MIT License
