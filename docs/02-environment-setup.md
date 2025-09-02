# 개발 환경 설정

## 필수 도구 설치

### 1. kubectl 설치

#### macOS (Homebrew)
```bash
brew install kubectl
```

#### Linux
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### 2. Go 설치

#### macOS (Homebrew)
```bash
brew install go
```

#### Linux
```bash
# Go 1.19 이상 버전 설치
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### 3. kubebuilder 설치

```bash
# kubebuilder 설치
curl -L -o kubebuilder https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)
chmod +x kubebuilder
sudo mv kubebuilder /usr/local/bin/
```

### 4. 로컬 Kubernetes 클러스터 설정

#### kind (권장)
```bash
# kind 설치
go install sigs.k8s.io/kind@latest

# 클러스터 생성
kind create cluster --name crd-study

# 컨텍스트 설정
kubectl cluster-info --context kind-crd-study
```

#### minikube (대안)
```bash
# minikube 설치
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 클러스터 시작
minikube start
```

### 5. make 설치

#### macOS
```bash
brew install make
```

#### Linux
```bash
sudo apt-get install make  # Ubuntu/Debian
sudo yum install make      # CentOS/RHEL
```

## 환경 검증

설치가 완료되었는지 확인:

```bash
# 버전 확인
kubectl version --client
go version
kubebuilder version
kind version  # 또는 minikube version

# 클러스터 연결 확인
kubectl get nodes
```

## 프로젝트 초기화

```bash
# 프로젝트 디렉토리 생성
mkdir my-crd-project
cd my-crd-project

# kubebuilder로 프로젝트 초기화
kubebuilder init --domain example.com --repo github.com/username/my-crd-project

# API 생성
kubebuilder create api --group mygroup --version v1 --kind MyResource
```

## 다음 단계

- [첫 번째 CRD 만들기](./03-first-crd.md)
- [kubebuilder 사용법](./04-kubebuilder-guide.md)
