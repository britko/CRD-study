# 개발 환경 설정

## 필수 도구 설치

### 0. Windows 환경 준비 (Windows 사용자)

**권장 버전**: 
- **Docker**: 24.0+ (최소: 20.10+)
- **Chocolatey**: 최신 버전

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

**권장 버전**: 1.28+ (최소: 1.24+)

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

**권장 버전**: 1.21+ (최소: 1.19+)

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

**권장 버전**: 3.14+ (최소: 3.0+)

#### Linux/macOS
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

**권장 버전**: 
- **kind**: 0.20+ (최소: 0.17+)
- **minikube**: 1.32+ (최소: 1.28+)

#### kind (권장)

**kind란?**
kind (Kubernetes IN Docker)는 Docker 컨테이너를 노드로 사용하여 로컬 Kubernetes 클러스터를 실행하는 도구입니다. 실제 프로덕션 환경과 유사한 다중 노드 클러스터를 로컬에서 쉽게 구성할 수 있습니다.

**장점:**
- 🚀 **빠른 시작**: Docker만 있으면 즉시 실행 가능
- 🔧 **다중 노드 지원**: 단일 노드부터 다중 노드 클러스터까지 구성 가능
- 🧪 **테스트 환경**: 실제 클러스터와 유사한 환경에서 테스트
- 💾 **경량**: 가상머신보다 가벼우고 빠름
- 🔄 **재생성 용이**: 클러스터를 쉽게 삭제하고 재생성 가능

```bash
# kind 설치
go install sigs.k8s.io/kind@latest

# Go bin 디렉토리를 PATH에 추가 (중요!)
export PATH=$PATH:$(go env GOPATH)/bin

# 설치 확인
kind version

# 기본 클러스터 생성 (단일 노드)
kind create cluster

# 사용자 정의 클러스터 생성 (다중 노드)
kind create cluster --name crd-study --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 6443
    hostPort: 6443
- role: worker
- role: worker
EOF

# 또는 설정 파일 사용
cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: crd-study
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 6443
    hostPort: 6443
  - containerPort: 80
    hostPort: 80
  - containerPort: 443
    hostPort: 443
- role: worker
- role: worker
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 6443
EOF

kind create cluster --config kind-config.yaml

# 클러스터 목록 확인
kind get clusters

# 클러스터 정보 확인
kind cluster-info --name crd-study

# 컨텍스트 설정
kubectl cluster-info --context kind-crd-study

# 클러스터 삭제
kind delete cluster --name crd-study
```

**⚠️ 주의: kind 명령어가 인식되지 않는 경우**

`go install`로 설치한 kind가 명령어로 인식되지 않으면 다음을 확인하세요:

```bash
# 1. Go bin 디렉토리 확인
go env GOPATH
go env GOBIN

# 2. PATH에 Go bin 디렉토리 추가 (일시적)
export PATH=$PATH:$(go env GOPATH)/bin

# 3. PATH에 Go bin 디렉토리 추가 (영구적)
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc

# 4. kind 재설치 및 확인
go install sigs.k8s.io/kind@latest
which kind
kind version
```

**대안: 직접 다운로드 설치**
```bash
# Linux/macOS
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Windows
# https://kind.sigs.k8s.io/dl/latest/kind-windows-amd64 에서 kind.exe 다운로드
```

**Windows에서 kind 설치 문제 해결**

Windows에서 `go install`로 설치한 kind가 인식되지 않는 경우:

```cmd
# PowerShell에서
# 1. Go bin 디렉토리 확인
go env GOPATH
go env GOBIN

# 2. PATH에 Go bin 디렉토리 추가 (일시적)
$env:PATH += ";$(go env GOPATH)\bin"

# 3. kind 재설치 및 확인
go install sigs.k8s.io/kind@latest
Get-Command kind
kind version

# Git Bash에서
# 1. PATH에 Go bin 디렉토리 추가
export PATH=$PATH:$(go env GOPATH)/bin

# 2. kind 재설치 및 확인
go install sigs.k8s.io/kind@latest
which kind
kind version
```

**Windows 권장 설치 방법**
```cmd
# Chocolatey 사용 (가장 간단)
choco install kind

# 또는 WSL2 사용 시 Linux와 동일하게 설치
wsl
go install sigs.k8s.io/kind@latest
export PATH=$PATH:$(go env GOPATH)/bin
```

#### minikube (대안)

**minikube란?**
minikube는 로컬에서 단일 노드 Kubernetes 클러스터를 실행하는 도구입니다. 가상머신이나 Docker를 사용하여 격리된 환경에서 Kubernetes를 실행할 수 있습니다.

**장점:**
- 🎯 **단순함**: 단일 노드로 간단한 테스트 환경 구성
- 🔒 **격리**: 가상머신으로 완전히 격리된 환경
- 📚 **학습**: Kubernetes 기본 개념 학습에 적합
- 🛠️ **안정성**: 검증된 도구로 안정적인 실행

**kind vs minikube 비교:**

| 기능 | kind | minikube |
|------|------|----------|
| **노드 수** | 다중 노드 지원 | 단일 노드만 |
| **성능** | Docker 기반으로 빠름 | 가상머신 기반으로 상대적으로 느림 |
| **리소스** | 경량 (Docker 컨테이너) | 상대적으로 무거움 (가상머신) |
| **복잡성** | 다중 노드 구성 가능 | 단순한 구성 |
| **사용 사례** | 다중 노드 테스트, CI/CD | 학습, 단순한 테스트 |

```bash
# minikube 설치
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 클러스터 시작
minikube start

# 클러스터 상태 확인
minikube status

# 클러스터 중지
minikube stop

# 클러스터 삭제
minikube delete
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

**권장 버전**: 최신 버전 (대부분의 시스템에 기본 포함)

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

## kubectl 설정 및 최적화

### kubectl 자동완성 설정

#### Linux/macOS
```bash
# Bash 자동완성
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc

# Zsh 자동완성
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
echo 'alias k=kubectl' >> ~/.zshrc
echo 'compdef _kubectl k' >> ~/.zshrc

# 설정 적용
source ~/.bashrc  # 또는 source ~/.zshrc
```

#### Windows
```cmd
# PowerShell 자동완성
kubectl completion powershell | Out-String | Invoke-Expression

# PowerShell 프로필에 추가 (영구 설정)
kubectl completion powershell >> $PROFILE

# Git Bash 자동완성
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
```

### 유용한 kubectl alias 설정

#### Linux/macOS
```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
alias k='kubectl'
alias ka='kubectl apply -f'
alias kd='kubectl delete'
alias kg='kubectl get'
alias kdp='kubectl describe pod'
alias kdn='kubectl describe node'
alias kds='kubectl describe service'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kctx='kubectl config use-context'
alias kgctx='kubectl config get-contexts'
alias kgns='kubectl get namespaces'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kgcrd='kubectl get crd'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kpf='kubectl port-forward'
alias ktop='kubectl top nodes && kubectl top pods'
```

#### Windows PowerShell
```powershell
# PowerShell 프로필에 추가
Set-Alias -Name k -Value kubectl
Set-Alias -Name ka -Value 'kubectl apply -f'
Set-Alias -Name kd -Value 'kubectl delete'
Set-Alias -Name kg -Value 'kubectl get'
Set-Alias -Name kdp -Value 'kubectl describe pod'
Set-Alias -Name kdn -Value 'kubectl describe node'
Set-Alias -Name kds -Value 'kubectl describe service'
Set-Alias -Name kl -Value 'kubectl logs'
Set-Alias -Name kex -Value 'kubectl exec -it'
Set-Alias -Name kctx -Value 'kubectl config use-context'
Set-Alias -Name kgctx -Value 'kubectl config get-contexts'
Set-Alias -Name kgns -Value 'kubectl get namespaces'
Set-Alias -Name kgp -Value 'kubectl get pods'
Set-Alias -Name kgs -Value 'kubectl get services'
Set-Alias -Name kgn -Value 'kubectl get nodes'
Set-Alias -Name kgcrd -Value 'kubectl get crd'
Set-Alias -Name kaf -Value 'kubectl apply -f'
Set-Alias -Name kdf -Value 'kubectl delete -f'
Set-Alias -Name kpf -Value 'kubectl port-forward'
Set-Alias -Name ktop -Value 'kubectl top nodes; kubectl top pods'
```

### kubectl 플러그인 및 도구

#### k9s (터미널 기반 Kubernetes 클러스터 뷰어)
```bash
# Linux/macOS
wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/

# macOS
brew install k9s

# Windows
choco install k9s
```

#### kubectx & kubens (컨텍스트 및 네임스페이스 전환)
```bash
# Linux/macOS
git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
echo 'export PATH=$PATH:~/.kubectx' >> ~/.bashrc
echo 'export PATH=$PATH:~/.kubectx' >> ~/.zshrc

# Windows
choco install kubectx
```

### kubectl 설정 파일 최적화

#### ~/.kube/config 최적화
```bash
# 현재 컨텍스트 확인
kubectl config current-context

# 컨텍스트 목록
kubectl config get-contexts

# 컨텍스트 전환
kubectl config use-context <context-name>

# 컨텍스트 정보 확인
kubectl config view

# 특정 컨텍스트 정보만 확인
kubectl config view --minify
```

### alias 사용 예제

#### 기본 명령어
```bash
# 기존 명령어
kubectl get pods
kubectl get services
kubectl get nodes

# alias 사용
kgp          # kubectl get pods
kgs          # kubectl get services
kgn          # kubectl get nodes
```

#### 파일 적용
```bash
# 기존 명령어
kubectl apply -f deployment.yaml
kubectl delete -f deployment.yaml

# alias 사용
ka deployment.yaml    # kubectl apply -f deployment.yaml
kd deployment.yaml    # kubectl delete -f deployment.yaml
```

#### 디버깅 및 모니터링
```bash
# 기존 명령어
kubectl describe pod my-pod
kubectl logs my-pod
kubectl exec -it my-pod -- /bin/bash

# alias 사용
kdp my-pod           # kubectl describe pod my-pod
kl my-pod            # kubectl logs my-pod
kex my-pod -- /bin/bash  # kubectl exec -it my-pod -- /bin/bash
```

#### 컨텍스트 관리
```bash
# 기존 명령어
kubectl config get-contexts
kubectl config use-context kind-crd-study

# alias 사용
kgctx                 # kubectl config get-contexts
kctx kind-crd-study   # kubectl config use-context kind-crd-study
```

## 환경 검증

설치가 완료되었는지 확인:

### 📋 **권장 버전 정보**

**현재 문서 작성 시점 (2024년 12월) 권장 버전:**

| 도구 | 권장 버전 | 최소 버전 | 설치 확인 명령어 |
|------|-----------|-----------|------------------|
| **kubectl** | 1.28+ | 1.24+ | `kubectl version --client` |
| **Go** | 1.21+ | 1.19+ | `go version` |
| **kubebuilder** | 3.14+ | 3.0+ | `kubebuilder version` |
| **kind** | 0.20+ | 0.17+ | `kind version` |
| **minikube** | 1.32+ | 1.28+ | `minikube version` |
| **Docker** | 24.0+ | 20.10+ | `docker --version` |

**📝 참고**: Kubernetes는 4개월마다 새로운 버전을 릴리스하므로, 최신 안정 버전 사용을 권장합니다.

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

이제 CRD 개발을 위한 기본 환경이 준비되었습니다. 다음 단계에서는 실제 CRD 프로젝트를 생성하고 개발해보겠습니다.

```bash
# 프로젝트 디렉토리 생성
mkdir simple-crd
cd simple-crd

# kubebuilder로 프로젝트 초기화
kubebuilder init --domain example.com --repo github.com/username/simple-crd

# Website API 생성 (03에서 사용할 CRD)
kubebuilder create api --group mygroup --version v1 --kind Website --resource --controller
```

**📝 다음 단계**
프로젝트가 생성되었습니다! 이제 [첫 번째 CRD 만들기](./03-first-crd.md)에서 이 프로젝트를 사용하여 실제 CRD를 개발하고 배포해보겠습니다.

## 다음 단계

- [첫 번째 CRD 만들기](./03-first-crd.md)
- [kubebuilder 사용법](./04-kubebuilder-guide.md)
