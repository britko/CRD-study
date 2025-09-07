# Kubernetes CRD (Custom Resource Definition) 학습 레포지토리

이 레포지토리는 Kubernetes CRD에 대한 체계적인 학습과 실습을 위한 것입니다. **Website CRD**를 중심으로 실제 kubebuilder 프로젝트를 통해 CRD 개발부터 배포까지 전 과정을 학습할 수 있습니다.

## 🎯 학습 목표

- **기본 개념**: Kubernetes CRD의 동작 원리와 API 확장 메커니즘 이해
- **실습 경험**: kubebuilder를 사용한 실제 CRD 개발 및 배포
- **고급 기능**: Webhook, 검증, 기본값 설정 등 프로덕션 수준 기능 구현
- **실무 적용**: 요구사항 기반 Database Operator 프로젝트 개발

## 📚 학습 순서

### 🥇 기초 단계
- [CRD 기본 개념](./docs/01-basic-concepts.md) - CRD의 기본 개념과 동작 원리
- [개발 환경 설정](./docs/02-environment-setup.md) - kubectl, Go, kubebuilder 환경 구축
- [첫 번째 CRD 만들기](./docs/03-first-crd.md) - 간단한 CRD 정의 및 배포

### 🥈 실습 단계
- [kubebuilder 가이드](./docs/04-kubebuilder-guide.md) - kubebuilder 프레임워크 활용법
- [컨트롤러 개발](./docs/05-controller-development.md) - Website Controller 구현
- [웹훅 구현](./docs/06-webhooks.md) - Mutating/Validating Webhook 개발
- [웹훅 성능 최적화](./docs/06a-performance-optimization.md) - 고급 웹훅 최적화 기법

### 🥉 고급 단계
- [검증 및 기본값](./docs/07-validation-defaulting.md) - OpenAPI 스키마 검증 및 기본값 설정
- [CRD 버전 관리](./docs/08-versioning.md) - API 버전 관리 전략
- [Database Operator 프로젝트](./docs/09-database-operator-project.md) - 실무 프로젝트 (요구사항 기반 학습)

## 🏗️ 프로젝트 구조

```
CRD-study/
├── README.md                           # 프로젝트 메인 문서
└── docs/                               # 학습 문서 (9개 단계)
    ├── 00-overview.md                 # 프로젝트 개요
    ├── 01-basic-concepts.md           # CRD 기본 개념
    ├── 02-environment-setup.md        # 개발 환경 설정
    ├── 03-first-crd.md                # 첫 번째 CRD 만들기
    ├── 04-kubebuilder-guide.md        # kubebuilder 사용법 (프로젝트 생성)
    ├── 05-controller-development.md   # 컨트롤러 개발
    ├── 06-webhooks.md                 # 웹훅 구현
    ├── 06a-performance-optimization.md # 웹훅 성능 최적화
    ├── 07-validation-defaulting.md    # 검증 및 기본값
    ├── 08-versioning.md               # CRD 버전 관리
    └── 09-database-operator-project.md # 실무 프로젝트
```

### 📝 참고사항

- **04단계에서 프로젝트 생성**: `04-kubebuilder-guide.md`에서 `advanced-crd-project` 디렉토리를 생성합니다
- **실습 중심**: 각 단계별로 실제 프로젝트를 만들면서 학습합니다
- **점진적 학습**: 간단한 CRD부터 시작해서 점점 복잡한 기능을 추가합니다

## 🛠️ 필요한 도구

- **kubectl** - Kubernetes 클러스터 관리
- **kind** 또는 **minikube** - 로컬 Kubernetes 클러스터
- **Go 1.19+** - 개발 언어
- **kubebuilder** - CRD 개발 프레임워크
- **make** - 빌드 자동화

## 🚀 빠른 시작

```bash
# 저장소 클론
git clone <repository-url>
cd CRD-study

# 개발 환경 설정
make setup

# 학습 순서대로 진행
# 1. docs/01-basic-concepts.md 읽기
# 2. docs/02-environment-setup.md 따라하기
# 3. docs/03-first-crd.md 따라하기
# 4. docs/04-kubebuilder-guide.md에서 advanced-crd-project 생성
# 5. 이후 단계별로 실습 진행
```

## 🎯 실습 프로젝트: Website CRD

이 프로젝트에서는 **Website CRD**를 중심으로 학습합니다:

### 📚 학습 단계별 프로젝트
- **01-03단계**: 기본 개념 이해 및 간단한 CRD 실습
- **04단계**: `advanced-crd-project` 생성 (kubebuilder 프로젝트)
- **05-08단계**: Website CRD 개발 (Controller, Webhook, 검증 등)
- **09단계**: Database Operator 프로젝트 (실무 프로젝트)

### 🏗️ 04단계 이후 프로젝트 구조
```
advanced-crd-project/              # 04단계에서 생성
├── api/v1/                        # CRD API 정의
│   ├── website_types.go           # Website CRD 스키마
│   └── zz_generated.deepcopy.go   # 자동 생성 코드
├── internal/                      # 내부 구현
│   ├── controller/                # Website Controller
│   └── webhook/                   # Mutating/Validating Webhooks
├── config/                        # 배포 설정
│   ├── crd/                       # CRD 매니페스트
│   ├── rbac/                      # RBAC 설정
│   ├── webhook/                   # Webhook 설정
│   └── samples/                   # 예제 리소스
├── test/                          # 테스트 코드
│   ├── e2e/                       # E2E 테스트
│   └── utils/                     # 테스트 유틸리티
└── cmd/main.go                    # 메인 애플리케이션
```

### 주요 기능
- ✅ **CRD 정의**: Website 리소스 스키마 및 검증 규칙
- ✅ **Controller**: Deployment, Service, ConfigMap 자동 생성/관리
- ✅ **Mutating Webhook**: 기본값 설정 및 라벨 자동 추가
- ✅ **Validating Webhook**: 비즈니스 규칙 검증
- ✅ **테스트**: 단위/통합/E2E 테스트 완비
- ✅ **배포**: CRD, RBAC, Webhook 자동 배포

### 공식 문서
- [Kubernetes CRD 공식 문서](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [kubebuilder 공식 가이드](https://book.kubebuilder.io/)
- [Kubernetes API 컨벤션](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)

### 추가 자료
- [Kubernetes Patterns](https://www.oreilly.com/library/view/kubernetes-patterns/9781492050278/)
- [Programming Kubernetes](https://www.oreilly.com/library/view/programming-kubernetes/9781492047094/)

## 🤝 기여하기

이 레포지토리는 학습 목적으로 만들어졌습니다. 개선 사항이나 추가하고 싶은 내용이 있다면:

1. **Issue 생성** - 버그 리포트나 기능 제안
2. **Pull Request 제출** - 코드 개선이나 문서 수정
3. **문서 개선 제안** - 학습 경험 향상을 위한 제안

모든 기여를 환영합니다!

## �� 라이선스

MIT License
