# 검증 및 기본값 설정

## 검증과 기본값이란?

**검증(Validation)**과 **기본값(Defaulting)**은 CRD의 데이터 무결성을 보장하고 사용자 경험을 향상시키는 중요한 기능입니다.

[웹훅 구현](./06-webhooks.md)에서 프로그래밍 방식의 검증을 구현했으니, 이제 OpenAPI 스키마를 사용한 선언적 검증과 기본값 설정을 구현해보겠습니다.

### 검증(Validation)
- 리소스 생성/수정 시 데이터 유효성 검사
- 잘못된 데이터로 인한 오류 방지
- 비즈니스 규칙 강제 적용

### 기본값(Defaulting)
- 사용자가 명시하지 않은 필드에 자동으로 값 설정
- 일관된 리소스 구성 보장
- 사용자 편의성 향상

## OpenAPI 스키마 검증

### 1. 기본 타입 검증

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
          required: ["spec"]
          properties:
            spec:
              type: object
              required: ["url", "replicas"]
              properties:
                url:
                  type: string
                  description: "웹사이트의 URL"
                  pattern: '^https?://.+'
                  minLength: 10
                  maxLength: 2048
                  example: "https://example.com"
                replicas:
                  type: integer
                  description: "배포할 복제본 수"
                  minimum: 1
                  maximum: 100
                  default: 3
                image:
                  type: string
                  description: "사용할 Docker 이미지"
                  default: "nginx:latest"
                port:
                  type: integer
                  description: "컨테이너 포트"
                  minimum: 1
                  maximum: 65535
                  default: 80
                environment:
                  type: string
                  description: "배포 환경"
                  enum: ["development", "staging", "production"]
                  default: "development"
                resources:
                  type: object
                  properties:
                    requests:
                      type: object
                      properties:
                        cpu:
                          type: string
                          pattern: '^[0-9]+m?$'
                          example: "100m"
                        memory:
                          type: string
                          pattern: '^[0-9]+[KMGTPEZYkmgtpezy]i?$'
                          example: "128Mi"
                    limits:
                      type: object
                      properties:
                        cpu:
                          type: string
                          pattern: '^[0-9]+m?$'
                          example: "500m"
                        memory:
                          type: string
                          pattern: '^[0-9]+[KMGTPEZYkmgtpezy]i?$'
                          example: "512Mi"
```

### 2. 고급 검증 규칙

```yaml
                # 배열 검증
                ports:
                  type: array
                  items:
                    type: object
                    required: ["name", "port"]
                    properties:
                      name:
                        type: string
                        minLength: 1
                        maxLength: 63
                        pattern: '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'
                      port:
                        type: integer
                        minimum: 1
                        maximum: 65535
                      protocol:
                        type: string
                        enum: ["TCP", "UDP", "SCTP"]
                        default: "TCP"
                  minItems: 1
                  maxItems: 10
                  uniqueItems: true
                
                # 객체 검증
                config:
                  type: object
                  additionalProperties: false
                  properties:
                    nginx:
                      type: object
                      properties:
                        worker_processes:
                          type: integer
                          minimum: 1
                          maximum: 16
                          default: 4
                        worker_connections:
                          type: integer
                          minimum: 1
                          maximum: 65535
                          default: 1024
                    redis:
                      type: object
                      properties:
                        enabled:
                          type: boolean
                          default: false
                        host:
                          type: string
                          format: hostname
                        port:
                          type: integer
                          minimum: 1
                          maximum: 65535
                          default: 6379
```

### 3. 조건부 검증

```yaml
                # 조건부 필드 검증
                ssl:
                  type: object
                  properties:
                    enabled:
                      type: boolean
                      default: false
                    certificate:
                      type: string
                      format: uri
                    privateKey:
                      type: string
                      format: uri
                  allOf:
                    - if:
                        properties:
                          enabled:
                            const: true
                      then:
                        required: ["certificate", "privateKey"]
                        properties:
                          certificate:
                            minLength: 1
                          privateKey:
                            minLength: 1
                    - if:
                        properties:
                          enabled:
                            const: false
                      then:
                        not:
                          required: ["certificate", "privateKey"]
```

## kubebuilder 마커를 사용한 검증

### 1. 기본 검증 마커

```go
type WebsiteSpec struct {
    // URL은 웹사이트의 URL입니다
    // +kubebuilder:validation:Required
    // +kubebuilder:validation:Pattern=`^https?://`
    // +kubebuilder:validation:MinLength=10
    // +kubebuilder:validation:MaxLength=2048
    URL string `json:"url"`
    
    // Replicas는 배포할 복제본 수입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=100
    // +kubebuilder:default=3
    Replicas int32 `json:"replicas"`
    
    // Image는 사용할 Docker 이미지입니다
    // +kubebuilder:default="nginx:latest"
    Image string `json:"image,omitempty"`
    
    // Port는 컨테이너 포트입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=65535
    // +kubebuilder:default=80
    Port int32 `json:"port,omitempty"`
    
    // Environment는 배포 환경입니다
    // +kubebuilder:validation:Enum=development;staging;production
    // +kubebuilder:default=development
    Environment string `json:"environment,omitempty"`
}
```

### 2. 고급 검증 마커

```go
type WebsiteSpec struct {
    // Resources는 리소스 요구사항입니다
    // +kubebuilder:validation:Optional
    Resources *ResourceRequirements `json:"resources,omitempty"`
    
    // Config는 웹사이트 설정입니다
    // +kubebuilder:validation:Optional
    Config *WebsiteConfig `json:"config,omitempty"`
    
    // SSL은 SSL 설정입니다
    // +kubebuilder:validation:Optional
    SSL *SSLConfig `json:"ssl,omitempty"`
}

type ResourceRequirements struct {
    // Requests는 최소 리소스 요구사항입니다
    // +kubebuilder:validation:Required
    Requests ResourceList `json:"requests"`
    
    // Limits는 최대 리소스 제한입니다
    // +kubebuilder:validation:Optional
    Limits ResourceList `json:"limits,omitempty"`
}

type ResourceList struct {
    // CPU는 CPU 요구사항입니다
    // +kubebuilder:validation:Pattern=`^[0-9]+m?$`
    // +kubebuilder:validation:MinLength=2
    CPU string `json:"cpu"`
    
    // Memory는 메모리 요구사항입니다
    // +kubebuilder:validation:Pattern=`^[0-9]+[KMGTPEZYkmgtpezy]i?$`
    // +kubebuilder:validation:MinLength=2
    Memory string `json:"memory"`
}

type WebsiteConfig struct {
    // Nginx는 Nginx 설정입니다
    // +kubebuilder:validation:Optional
    Nginx *NginxConfig `json:"nginx,omitempty"`
    
    // Redis는 Redis 설정입니다
    // +kubebuilder:validation:Optional
    Redis *RedisConfig `json:"redis,omitempty"`
}

type NginxConfig struct {
    // WorkerProcesses는 워커 프로세스 수입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=16
    // +kubebuilder:default=4
    WorkerProcesses int32 `json:"workerProcesses,omitempty"`
    
    // WorkerConnections는 워커 연결 수입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=65535
    // +kubebuilder:default=1024
    WorkerConnections int32 `json:"workerConnections,omitempty"`
}

type SSLConfig struct {
    // Enabled는 SSL 활성화 여부입니다
    // +kubebuilder:default=false
    Enabled bool `json:"enabled"`
    
    // Certificate는 SSL 인증서 경로입니다
    // +kubebuilder:validation:Optional
    Certificate string `json:"certificate,omitempty"`
    
    // PrivateKey는 SSL 개인키 경로입니다
    // +kubebuilder:validation:Optional
    PrivateKey string `json:"privateKey,omitempty"`
}
```

## 프로그래밍 방식 검증

### 1. 웹훅을 사용한 검증

```go
// ValidateCreate는 Website 생성 시 검증합니다
func (r *Website) ValidateCreate() error {
    return r.validateWebsite()
}

// ValidateUpdate는 Website 수정 시 검증합니다
func (r *Website) ValidateUpdate(old runtime.Object) error {
    oldWebsite := old.(*Website)
    return r.validateWebsiteUpdate(oldWebsite)
}

// validateWebsite는 Website의 기본 유효성을 검증합니다
func (r *Website) validateWebsite() error {
    var allErrs field.ErrorList
    
    // 기본 필드 검증
    if err := r.validateBasicFields(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // 비즈니스 규칙 검증
    if err := r.validateBusinessRules(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // 리소스 검증
    if err := r.validateResources(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    if len(allErrs) == 0 {
        return nil
    }
    
    return webhook.NewInvalid(schema.GroupKind{Group: "mygroup.example.com", Kind: "Website"}, r.Name, allErrs)
}

// validateBasicFields는 기본 필드를 검증합니다
func (r *Website) validateBasicFields() *field.Error {
    // URL 검증
    if r.Spec.URL == "" {
        return field.Required(field.NewPath("spec", "url"), "URL은 필수입니다")
    }
    
    if !strings.HasPrefix(r.Spec.URL, "http://") && !strings.HasPrefix(r.Spec.URL, "https://") {
        return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "URL은 http:// 또는 https://로 시작해야 합니다")
    }
    
    // 복제본 수 검증
    if r.Spec.Replicas < 1 {
        return field.Invalid(field.NewPath("spec", "replicas"), r.Spec.Replicas, "복제본 수는 1 이상이어야 합니다")
    }
    
    if r.Spec.Replicas > 100 {
        return field.Invalid(field.NewPath("spec", "replicas"), r.Spec.Replicas, "복제본 수는 100 이하여야 합니다")
    }
    
    return nil
}

// validateBusinessRules는 비즈니스 규칙을 검증합니다
func (r *Website) validateBusinessRules() *field.Error {
    // 프로덕션 환경에서는 HTTPS만 허용
    if r.Spec.Environment == "production" {
        if !strings.HasPrefix(r.Spec.URL, "https://") {
            return field.Invalid(field.NewPath("spec", "url"), r.Spec.URL, "프로덕션 환경에서는 HTTPS만 허용됩니다")
        }
    }
    
    // 프로덕션 환경에서는 리소스 제한 필수
    if r.Spec.Environment == "production" {
        if r.Spec.Resources == nil || r.Spec.Resources.Limits == nil {
            return field.Required(field.NewPath("spec", "resources", "limits"), "프로덕션 환경에서는 리소스 제한이 필수입니다")
        }
    }
    
    return nil
}

// validateResources는 리소스 설정을 검증합니다
func (r *Website) validateResources() *field.Error {
    if r.Spec.Resources == nil {
        return nil
    }
    
    // CPU 검증
    if r.Spec.Resources.Requests.CPU != "" {
        if !isValidCPUValue(r.Spec.Resources.Requests.CPU) {
            return field.Invalid(field.NewPath("spec", "resources", "requests", "cpu"), r.Spec.Resources.Requests.CPU, "유효하지 않은 CPU 값입니다")
        }
    }
    
    // 메모리 검증
    if r.Spec.Resources.Requests.Memory != "" {
        if !isValidMemoryValue(r.Spec.Resources.Requests.Memory) {
            return field.Invalid(field.NewPath("spec", "resources", "requests", "memory"), r.Spec.Resources.Requests.Memory, "유효하지 않은 메모리 값입니다")
        }
    }
    
    // 제한이 요청보다 작은 경우 검증
    if r.Spec.Resources.Limits != nil {
        if err := r.validateResourceLimits(); err != nil {
            return err
        }
    }
    
    return nil
}

// validateResourceLimits는 리소스 제한을 검증합니다
func (r *Website) validateResourceLimits() *field.Error {
    if r.Spec.Resources.Limits.CPU != "" && r.Spec.Resources.Requests.CPU != "" {
        if !isResourceLimitValid(r.Spec.Resources.Requests.CPU, r.Spec.Resources.Limits.CPU) {
            return field.Invalid(field.NewPath("spec", "resources", "limits", "cpu"), r.Spec.Resources.Limits.CPU, "CPU 제한은 요청보다 크거나 같아야 합니다")
        }
    }
    
    if r.Spec.Resources.Limits.Memory != "" && r.Spec.Resources.Requests.Memory != "" {
        if !isResourceLimitValid(r.Spec.Resources.Requests.Memory, r.Spec.Resources.Limits.Memory) {
            return field.Invalid(field.NewPath("spec", "resources", "limits", "memory"), r.Spec.Resources.Limits.Memory, "메모리 제한은 요청보다 크거나 같아야 합니다")
        }
    }
    
    return nil
}
```

### 2. 업데이트 검증

```go
// validateWebsiteUpdate는 Website 업데이트를 검증합니다
func (r *Website) validateWebsiteUpdate(old *Website) error {
    var allErrs field.ErrorList
    
    // 기본 검증
    if err := r.validateWebsite(); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // 변경 불가능한 필드 검증
    if err := r.validateImmutableFields(old); err != nil {
        allErrs = append(allErrs, err)
    }
    
    // 업데이트 규칙 검증
    if err := r.validateUpdateRules(old); err != nil {
        allErrs = append(allErrs, err)
    }
    
    if len(allErrs) == 0 {
        return nil
    }
    
    return webhook.NewInvalid(schema.GroupKind{Group: "mygroup.example.com", Kind: "Website"}, r.Name, allErrs)
}

// validateImmutableFields는 변경 불가능한 필드를 검증합니다
func (r *Website) validateImmutableFields(old *Website) *field.Error {
    // URL은 변경 불가능
    if r.Spec.URL != old.Spec.URL {
        return field.Forbidden(field.NewPath("spec", "url"), "URL은 변경할 수 없습니다")
    }
    
    // 환경은 변경 불가능
    if r.Spec.Environment != old.Spec.Environment {
        return field.Forbidden(field.NewPath("spec", "environment"), "환경은 변경할 수 없습니다")
    }
    
    return nil
}

// validateUpdateRules는 업데이트 규칙을 검증합니다
func (r *Website) validateUpdateRules(old *Website) *field.Error {
    // 복제본 수 증가 제한
    if r.Spec.Replicas > old.Spec.Replicas {
        maxIncrease := old.Spec.Replicas * 2
        if r.Spec.Replicas > maxIncrease {
            return field.Invalid(field.NewPath("spec", "replicas"), r.Spec.Replicas, fmt.Sprintf("복제본 수는 한 번에 %d개까지 증가할 수 있습니다", maxIncrease-old.Spec.Replicas))
        }
    }
    
    return nil
}
```

## 기본값 설정

### 1. kubebuilder 마커를 사용한 기본값

```go
type WebsiteSpec struct {
    // URL은 웹사이트의 URL입니다
    // +kubebuilder:validation:Required
    URL string `json:"url"`
    
    // Replicas는 배포할 복제본 수입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=100
    // +kubebuilder:default=3
    Replicas int32 `json:"replicas"`
    
    // Image는 사용할 Docker 이미지입니다
    // +kubebuilder:default="nginx:latest"
    Image string `json:"image,omitempty"`
    
    // Port는 컨테이너 포트입니다
    // +kubebuilder:default=80
    Port int32 `json:"port,omitempty"`
    
    // Environment는 배포 환경입니다
    // +kubebuilder:default="development"
    Environment string `json:"environment,omitempty"`
    
    // Resources는 리소스 요구사항입니다
    // +kubebuilder:default={"requests":{"cpu":"100m","memory":"128Mi"}}
    Resources *ResourceRequirements `json:"resources,omitempty"`
}
```

### 2. 웹훅을 사용한 동적 기본값

```go
// Default는 Website의 기본값을 설정합니다
func (r *Website) Default() {
    // 기본값 설정
    r.setBasicDefaults()
    
    // 환경별 기본값 설정
    r.setEnvironmentDefaults()
    
    // 보안 기본값 설정
    r.setSecurityDefaults()
    
    // 모니터링 기본값 설정
    r.setMonitoringDefaults()
}

// setBasicDefaults는 기본 기본값을 설정합니다
func (r *Website) setBasicDefaults() {
    if r.Spec.Replicas == 0 {
        r.Spec.Replicas = 3
    }
    
    if r.Spec.Image == "" {
        r.Spec.Image = "nginx:latest"
    }
    
    if r.Spec.Port == 0 {
        r.Spec.Port = 80
    }
    
    if r.Spec.Environment == "" {
        r.Spec.Environment = "development"
    }
}

// setEnvironmentDefaults는 환경별 기본값을 설정합니다
func (r *Website) setEnvironmentDefaults() {
    switch r.Spec.Environment {
    case "development":
        if r.Spec.Resources == nil {
            r.Spec.Resources = &ResourceRequirements{
                Requests: ResourceList{
                    CPU:    "100m",
                    Memory: "128Mi",
                },
            }
        }
    case "staging":
        if r.Spec.Resources == nil {
            r.Spec.Resources = &ResourceRequirements{
                Requests: ResourceList{
                    CPU:    "200m",
                    Memory: "256Mi",
                },
                Limits: ResourceList{
                    CPU:    "500m",
                    Memory: "512Mi",
                },
            }
        }
    case "production":
        if r.Spec.Resources == nil {
            r.Spec.Resources = &ResourceRequirements{
                Requests: ResourceList{
                    CPU:    "500m",
                    Memory: "512Mi",
                },
                Limits: ResourceList{
                    CPU:    "1000m",
                    Memory: "1Gi",
                },
            }
        }
        
        // 프로덕션에서는 안전한 이미지 사용
        if strings.Contains(r.Spec.Image, ":latest") {
            r.Spec.Image = strings.TrimSuffix(r.Spec.Image, ":latest") + ":1.21"
        }
    }
}

// setSecurityDefaults는 보안 기본값을 설정합니다
func (r *Website) setSecurityDefaults() {
    if r.Annotations == nil {
        r.Annotations = make(map[string]string)
    }
    
    // 보안 컨텍스트 설정
    if r.Annotations["security-context"] == "" {
        r.Annotations["security-context"] = "restricted"
    }
    
    // 네트워크 정책 설정
    if r.Annotations["network-policy"] == "" {
        r.Annotations["network-policy"] = "default-deny"
    }
    
    // 프로덕션 환경에서는 추가 보안 설정
    if r.Spec.Environment == "production" {
        if r.Annotations["pod-security-standards"] == "" {
            r.Annotations["pod-security-standards"] = "restricted"
        }
        
        if r.Annotations["seccomp-profile"] == "" {
            r.Annotations["seccomp-profile"] = "runtime/default"
        }
    }
}

// setMonitoringDefaults는 모니터링 기본값을 설정합니다
func (r *Website) setMonitoringDefaults() {
    if r.Annotations == nil {
        r.Annotations = make(map[string]string)
    }
    
    // Prometheus 메트릭 수집
    if r.Annotations["prometheus.io/scrape"] == "" {
        r.Annotations["prometheus.io/scrape"] = "true"
    }
    
    if r.Annotations["prometheus.io/port"] == "" {
        r.Annotations["prometheus.io/port"] = strconv.Itoa(int(r.Spec.Port))
    }
    
    if r.Annotations["prometheus.io/path"] == "" {
        r.Annotations["prometheus.io/path"] = "/metrics"
    }
    
    // 로깅 설정
    if r.Annotations["logging.io/level"] == "" {
        r.Annotations["logging.io/level"] = "info"
    }
    
    if r.Annotations["logging.io/format"] == "" {
        r.Annotations["logging.io/format"] = "json"
    }
}
```

## 테스트 작성

### 1. 검증 테스트

```go
func TestWebsite_ValidateCreate(t *testing.T) {
    tests := []struct {
        name    string
        website *Website
        wantErr bool
    }{
        {
            name: "유효한 Website",
            website: &Website{
                Spec: WebsiteSpec{
                    URL:      "https://example.com",
                    Replicas: 3,
                    Port:     80,
                },
            },
            wantErr: false,
        },
        {
            name: "잘못된 URL",
            website: &Website{
                Spec: WebsiteSpec{
                    URL:      "invalid-url",
                    Replicas: 3,
                    Port:     80,
                },
            },
            wantErr: true,
        },
        {
            name: "잘못된 복제본 수",
            website: &Website{
                Spec: WebsiteSpec{
                    URL:      "https://example.com",
                    Replicas: 0,
                    Port:     80,
                },
            },
            wantErr: true,
        },
        {
            name: "프로덕션 환경에서 HTTP URL",
            website: &Website{
                Spec: WebsiteSpec{
                    URL:        "http://example.com",
                    Replicas:   3,
                    Port:       80,
                    Environment: "production",
                },
            },
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.website.ValidateCreate()
            if (err != nil) != tt.wantErr {
                t.Errorf("Website.ValidateCreate() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### 2. 기본값 테스트

```go
func TestWebsite_Default(t *testing.T) {
    tests := []struct {
        name     string
        website  *Website
        expected *Website
    }{
        {
            name: "기본값 설정",
            website: &Website{
                Spec: WebsiteSpec{
                    URL: "https://example.com",
                },
            },
            expected: &Website{
                Spec: WebsiteSpec{
                    URL:         "https://example.com",
                    Replicas:    3,
                    Image:       "nginx:latest",
                    Port:        80,
                    Environment: "development",
                },
            },
        },
        {
            name: "프로덕션 환경 기본값",
            website: &Website{
                Spec: WebsiteSpec{
                    URL:        "https://example.com",
                    Environment: "production",
                },
            },
            expected: &Website{
                Spec: WebsiteSpec{
                    URL:         "https://example.com",
                    Replicas:    3,
                    Image:       "nginx:1.21",
                    Port:        80,
                    Environment: "production",
                },
            },
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            tt.website.Default()
            
            if tt.website.Spec.Replicas != tt.expected.Spec.Replicas {
                t.Errorf("Replicas = %v, want %v", tt.website.Spec.Replicas, tt.expected.Spec.Replicas)
            }
            
            if tt.website.Spec.Image != tt.expected.Spec.Image {
                t.Errorf("Image = %v, want %v", tt.website.Spec.Image, tt.expected.Spec.Image)
            }
            
            if tt.website.Spec.Port != tt.expected.Spec.Port {
                t.Errorf("Port = %v, want %v", tt.website.Spec.Port, tt.expected.Spec.Port)
            }
            
            if tt.website.Spec.Environment != tt.expected.Spec.Environment {
                t.Errorf("Environment = %v, want %v", tt.website.Spec.Environment, tt.expected.Spec.Environment)
            }
        })
    }
}
```

## 다음 단계

검증 및 기본값 설정을 완료했습니다! 이제 CRD의 장기적인 관리와 발전을 위한 버전 관리 시스템을 구현해보겠습니다:

- [CRD 버전 관리](./08-versioning.md) - CRD 버전 관리 및 마이그레이션

## 문제 해결

### 일반적인 문제들

1. **검증 실패**: OpenAPI 스키마와 웹훅 검증 규칙 일치 확인
2. **기본값 미적용**: kubebuilder 마커와 웹훅 기본값 설정 확인
3. **성능 문제**: 복잡한 검증 로직 최적화

### 디버깅 팁

```bash
# CRD 스키마 확인
kubectl get crd websites.example.com -o yaml

# 웹훅 로그 확인
kubectl logs -n my-crd-project-system deployment/webhook-server

# 검증 실패 이벤트 확인
kubectl get events --sort-by='.lastTimestamp'
```
