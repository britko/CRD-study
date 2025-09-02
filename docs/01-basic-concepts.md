# CRD 기본 개념

## CRD란?

**CRD (Custom Resource Definition)**는 Kubernetes API를 확장하여 사용자 정의 리소스를 추가할 수 있게 해주는 기능입니다.

## 기본 구성 요소

### 1. Custom Resource Definition (CRD)
- 새로운 리소스 타입을 정의하는 스키마
- API 그룹, 버전, 리소스 종류를 정의
- OpenAPI v3 스키마를 사용하여 리소스 구조 정의

### 2. Custom Resource (CR)
- CRD로 정의된 리소스의 실제 인스턴스
- YAML/JSON 형태로 정의
- kubectl로 관리 가능

### 3. Controller
- CR의 상태를 관리하는 로직
- 원하는 상태와 실제 상태를 비교하여 조정
- Go로 작성되며 kubebuilder 프레임워크 사용 권장

## CRD의 장점

1. **API 확장성**: Kubernetes API를 확장하여 도메인별 리소스 정의
2. **일관된 관리**: kubectl, dashboard 등 기존 도구들과 호환
3. **권한 관리**: RBAC을 통한 세밀한 접근 제어
4. **검증**: OpenAPI 스키마를 통한 자동 검증

## 간단한 예제

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: websites.example.com
spec:
  group: example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                url:
                  type: string
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 10
  scope: Namespaced
  names:
    plural: websites
    singular: website
    kind: Website
    shortNames:
    - ws
```

## 다음 단계

- [개발 환경 설정](./02-environment-setup.md)
- [첫 번째 CRD 만들기](./03-first-crd.md)
