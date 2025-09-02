.PHONY: help setup deploy-crd delete-crd deploy-example delete-example clean

# 기본 타겟
help: ## 도움말 표시
	@echo "사용 가능한 명령어:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# 개발 환경 설정
setup: ## 개발 환경 설정
	@echo "개발 환경을 설정합니다..."
	@echo "1. kubectl 설치 확인..."
	@kubectl version --client || (echo "kubectl이 설치되지 않았습니다. docs/02-environment-setup.md를 참고하세요." && exit 1)
	@echo "2. Go 설치 확인..."
	@go version || (echo "Go가 설치되지 않았습니다. docs/02-environment-setup.md를 참고하세요." && exit 1)
	@echo "3. kubebuilder 설치 확인..."
	@kubebuilder version || (echo "kubebuilder가 설치되지 않았습니다. docs/02-environment-setup.md를 참고하세요." && exit 1)
	@echo "✅ 개발 환경 설정이 완료되었습니다!"

# CRD 배포
deploy-crd: ## Website CRD 배포
	@echo "Website CRD를 배포합니다..."
	kubectl apply -f examples/simple-crd/website-crd.yaml
	@echo "✅ Website CRD가 배포되었습니다!"

# CRD 삭제
delete-crd: ## Website CRD 삭제
	@echo "Website CRD를 삭제합니다..."
	kubectl delete -f examples/simple-crd/website-crd.yaml
	@echo "✅ Website CRD가 삭제되었습니다!"

# 예제 리소스 배포
deploy-example: ## 예제 Website 리소스 배포
	@echo "예제 Website 리소스를 배포합니다..."
	kubectl apply -f examples/simple-crd/website-example.yaml
	@echo "✅ 예제 Website 리소스가 배포되었습니다!"

# 예제 리소스 삭제
delete-example: ## 예제 Website 리소스 삭제
	@echo "예제 Website 리소스를 삭제합니다..."
	kubectl delete -f examples/simple-crd/website-example.yaml
	@echo "✅ 예제 Website 리소스가 삭제되었습니다!"

# CRD 상태 확인
status: ## CRD 상태 확인
	@echo "CRD 상태를 확인합니다..."
	@echo "=== CRD 목록 ==="
	kubectl get crd | grep websites.example.com || echo "Website CRD가 아직 배포되지 않았습니다."
	@echo ""
	@echo "=== Website 리소스 목록 ==="
	kubectl get websites || echo "Website 리소스가 아직 생성되지 않았습니다."

# 클러스터 정보 확인
cluster-info: ## 클러스터 정보 확인
	@echo "클러스터 정보를 확인합니다..."
	kubectl cluster-info
	@echo ""
	@echo "=== 노드 정보 ==="
	kubectl get nodes

# 정리
clean: delete-example delete-crd ## 모든 리소스 정리
	@echo "✅ 모든 리소스가 정리되었습니다!"

# 전체 배포
deploy: deploy-crd deploy-example ## CRD와 예제 리소스 전체 배포
	@echo "✅ 전체 배포가 완료되었습니다!"
