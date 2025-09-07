# CRD 학습 프로젝트 개요

## 🎯 프로젝트 목표

이 프로젝트는 Kubernetes CRD(Custom Resource Definition)에 대한 체계적인 학습을 위한 것입니다. 단계별로 CRD의 개념을 이해하고, 실제로 개발하고 배포해보면서 실무에 필요한 역량을 기를 수 있습니다.

## 📚 학습 로드맵

### 🥇 초급 단계 (1-3주)
- **CRD 기본 개념 이해**
  - Kubernetes API 확장의 개념
  - CRD vs Aggregated API
  - OpenAPI 스키마 이해
  
- **개발 환경 구축**
  - kubectl, Go, kubebuilder 설치
  - 로컬 Kubernetes 클러스터 설정 (kind/minikube)
  
- **첫 번째 CRD 만들기**
  - 간단한 CRD 정의 작성
  - CRD 배포 및 테스트
  - Custom Resource 생성 및 관리

### 🥈 중급 단계 (4-6주)
- **kubebuilder 프레임워크 활용**
  - kubebuilder 프로젝트 구조 이해
  - API 타입 정의 및 생성
  - 컨트롤러 기본 구조
  
- **컨트롤러 개발**
  - Reconcile 루프 이해
  - 상태 관리 및 이벤트 처리
  - 에러 핸들링 및 재시도 로직

### 🥉 고급 단계 (7-10주)
- **고급 CRD 기능**
  - 웹훅 구현 (Validating/Mutating)
  - 기본값 설정 및 검증
  - CRD 버전 관리 및 마이그레이션
  
- **프로덕션 환경 고려사항**
  - 보안 및 권한 관리
  - 모니터링 및 로깅
  - 성능 최적화

## 🏗️ 프로젝트 구조

```
CRD-study/
├── README.md                           # 프로젝트 메인 문서
├── Makefile                            # 빌드 및 배포 자동화
└── docs/                               # 학습 문서
    ├── 00-overview.md                 # 프로젝트 개요 (현재 문서)
    ├── 01-basic-concepts.md           # CRD 기본 개념
    ├── 02-environment-setup.md        # 개발 환경 설정
    ├── 03-first-crd.md                # 첫 번째 CRD 만들기
    ├── 04-kubebuilder-guide.md        # kubebuilder 사용법 (프로젝트 생성)
    ├── 05-controller-development.md   # 컨트롤러 개발
    ├── 06-webhooks.md                 # 웹훅 구현
    ├── 06a-performance-optimization.md # 웹훅 성능 최적화
    ├── 07-validation-defaulting.md    # 검증 및 기본값
    ├── 08-versioning.md               # CRD 버전 관리
    └── 09-database-operator-project.md # 실무 프로젝트 (Database Operator)
```

### 📝 참고사항

- **04단계에서 프로젝트 생성**: `04-kubebuilder-guide.md`에서 `advanced-crd-project` 디렉토리를 생성합니다
- **실습 중심**: 각 단계별로 실제 프로젝트를 만들면서 학습합니다
- **점진적 학습**: 간단한 CRD부터 시작해서 점점 복잡한 기능을 추가합니다



## 📖 학습 자료

### 공식 문서
- [Kubernetes CRD 공식 문서](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [kubebuilder 공식 가이드](https://book.kubebuilder.io/)
- [Kubernetes API 컨벤션](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)

### 추가 자료
- [Kubernetes Patterns](https://www.oreilly.com/library/view/kubernetes-patterns/9781492050278/)
- [Programming Kubernetes](https://www.oreilly.com/library/view/programming-kubernetes/9781492047094/)

## 🎯 실습 목표

각 단계별로 다음을 달성할 수 있습니다:

1. **기본 개념**: CRD의 동작 원리와 Kubernetes API 확장 메커니즘 이해
2. **개발 환경**: 로컬에서 CRD 개발 및 테스트가 가능한 환경 구축
3. **실습 경험**: 실제 CRD를 만들고 배포해보는 경험
4. **프로덕션 준비**: 실제 운영 환경에서 사용할 수 있는 CRD 개발 능력

## 🤝 기여 및 피드백

이 프로젝트는 학습 목적으로 만들어졌습니다. 개선 사항이나 추가하고 싶은 내용이 있다면:

1. Issue 생성
2. Pull Request 제출
3. 문서 개선 제안

모든 기여를 환영합니다!

## 📝 학습 순서

### 🥇 기초 단계
- [CRD 기본 개념](./01-basic-concepts.md) - CRD의 기본 개념부터 시작
- [개발 환경 설정](./02-environment-setup.md) - 개발 환경 구축
- [첫 번째 CRD 만들기](./03-first-crd.md) - 실제 CRD 개발 실습

### 🥈 실습 단계
- [kubebuilder 가이드](./04-kubebuilder-guide.md) - kubebuilder 프레임워크 활용
- [컨트롤러 개발](./05-controller-development.md) - Website Controller 구현
- [웹훅 구현](./06-webhooks.md) - Mutating/Validating Webhook 개발
- [웹훅 성능 최적화](./06a-performance-optimization.md) - 고급 웹훅 최적화 기법

### 🥉 고급 단계
- [검증 및 기본값](./07-validation-defaulting.md) - OpenAPI 스키마 검증
- [CRD 버전 관리](./08-versioning.md) - API 버전 관리 전략
- [Database Operator 프로젝트](./09-database-operator-project.md) - 실무 프로젝트 (요구사항 기반 학습)

## 🎯 실습 프로젝트

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