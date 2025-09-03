# 개발 환경 설정

## 필수 도구 설치

### 0. Windows 환경 준비 (Windows 사용자)

#### Chocolatey 설치 (권장)
```cmd
# PowerShell을 관리자 권한으로 실행 후
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 설치 확인
choco --version
```

#### WSL2 설치 (권장)
```cmd
# Windows 기능에서 "Linux용 Windows 하위 시스템" 활성화
# Microsoft Store에서 Ubuntu 설치
# 또는 PowerShell에서
wsl --install
```

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

#### Windows
```cmd
# Chocolatey 사용 (권장)
choco install kubernetes-cli

# 또는 직접 다운로드
# 1. https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/ 에서 kubectl.exe 다운로드
# 2. PATH에 추가하거나 kubectl.exe가 있는 디렉토리에서 실행
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

#### Windows
```cmd
# Chocolatey 사용 (권장)
choco install golang

# 또는 직접 다운로드
# 1. https://go.dev/dl/ 에서 Windows용 MSI 설치 파일 다운로드
# 2. 설치 프로그램 실행 및 PATH 설정 확인
# 3. PowerShell에서 환경 변수 설정
#    $env:PATH += ";C:\Go\bin"
# 4. 영구 설정을 위해 시스템 환경 변수에 추가
```

### 3. kubebuilder 설치

```bash
# kubebuilder 설치
curl -L -o kubebuilder https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)
chmod +x kubebuilder
sudo mv kubebuilder /usr/local/bin/
```

#### Windows
```cmd
# Chocolatey 사용 (권장)
choco install kubebuilder

# 또는 직접 다운로드
# 1. https://go.kubebuilder.io/dl/latest/windows/amd64 에서 kubebuilder.exe 다운로드
# 2. PATH에 추가하거나 kubebuilder.exe가 있는 디렉토리에서 실행
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

#### Windows
```cmd
# Chocolatey 사용 (권장)
choco install minikube

# 또는 직접 다운로드
# 1. https://minikube.sigs.k8s.io/docs/start/ 에서 Windows용 설치 파일 다운로드
# 2. 설치 프로그램 실행
# 3. 클러스터 시작
minikube start

# WSL2 사용 시 (권장)
minikube start --driver=hyperv
# 또는
minikube start --driver=docker
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

#### Windows
```cmd
# Chocolatey 사용 (권장)
choco install make

# 또는 Git for Windows와 함께 설치된 make 사용
# Git Bash에서 make 명령어 사용 가능

# 또는 WSL2 사용 시 Linux와 동일하게 설치
wsl
sudo apt-get install make
```

## 환경 검증

설치가 완료되었는지 확인:

### Linux/macOS
```bash
# 버전 확인
kubectl version --client
go version
kubebuilder version
kind version  # 또는 minikube version

# 클러스터 연결 확인
kubectl get nodes
```

### Windows
```cmd
# PowerShell에서 버전 확인
kubectl version --client
go version
kubebuilder version
minikube version

# 클러스터 연결 확인
kubectl get nodes

# 또는 Git Bash에서
kubectl version --client
go version
kubebuilder version
minikube version
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
