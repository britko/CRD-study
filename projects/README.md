# CRD 프로젝트 가이드

이 디렉토리는 실제 CRD 프로젝트를 개발하고 관리하기 위한 가이드와 예제를 포함합니다.

## 🚀 프로젝트 시작하기

### 1. 새 프로젝트 생성

```bash
# 프로젝트 디렉토리 생성
mkdir my-crd-project
cd my-crd-project

# kubebuilder로 프로젝트 초기화
kubebuilder init \
  --domain example.com \
  --repo github.com/username/my-crd-project \
  --license apache2 \
  --owner "Your Name <your.email@example.com>"
```

### 2. API 정의

```bash
# Website API 생성
kubebuilder create api \
  --group mygroup \
  --version v1 \
  --kind Website \
  --resource \
  --controller
```

### 3. 개발 및 테스트

```bash
# 코드 생성
make manifests
make generate

# 테스트
make test

# 로컬 실행
make run
```

### 4. 배포

```bash
# CRD 설치
make install

# 컨트롤러 배포
make deploy
```

## 📁 프로젝트 구조 예시

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

## 🔧 개발 워크플로우

### 1. 코드 수정
- `api/v1/` 디렉토리에서 타입 정의 수정
- `controllers/` 디렉토리에서 비즈니스 로직 구현

### 2. 코드 생성
```bash
make manifests  # CRD 매니페스트 생성
make generate   # Go 코드 생성
```

### 3. 테스트
```bash
make test      # 단위 테스트
make test-env  # 통합 테스트
```

### 4. 배포
```bash
make install   # CRD 설치
make deploy    # 컨트롤러 배포
```

## 📚 학습 자료

- [kubebuilder 공식 가이드](https://book.kubebuilder.io/)
- [Kubernetes API 컨벤션](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- [controller-runtime 문서](https://pkg.go.dev/sigs.k8s.io/controller-runtime)

## 🎯 다음 단계

1. **기본 CRD 개발**: [첫 번째 CRD 만들기](../docs/03-first-crd.md)
2. **kubebuilder 활용**: [kubebuilder 사용법](../docs/04-kubebuilder-guide.md)
3. **컨트롤러 개발**: [컨트롤러 개발](../docs/05-controller-development.md)
4. **고급 기능**: [웹훅 구현](../docs/06-webhooks.md)

## 🤝 기여하기

프로젝트 개선을 위한 제안이나 질문이 있으시면:

1. Issue 생성
2. Pull Request 제출
3. 문서 개선 제안

모든 기여를 환영합니다!
