# Database Operator 실습 프로젝트

📝 **실습 목표**: MySQL/PostgreSQL 데이터베이스를 Kubernetes에서 관리하는 CRD Operator 개발

## 프로젝트 개요

### 비즈니스 요구사항
- 개발팀이 간단한 YAML로 데이터베이스 인스턴스를 생성/관리
- 자동 백업, 모니터링, 스케일링 기능
- 개발/스테이징/프로덕션 환경별 다른 설정

### 학습 목표
- [ ] CRD 설계 및 구현
- [ ] Controller 개발 (StatefulSet, Service, ConfigMap 관리)
- [ ] Webhook 구현 (검증, 기본값 설정)
- [ ] 고급 기능 (백업, 모니터링, 스케일링)
- [ ] 운영 기능 (상태 관리, 에러 복구)

## 📋 요구사항 분석

### 🎬 시나리오: Database Operator 개발 요구사항 도출

#### 배경 상황
**TechCorp**는 중견 IT 기업으로, 현재 50여 개의 마이크로서비스가 운영되고 있습니다. 각 서비스마다 MySQL/PostgreSQL 데이터베이스가 필요하며, 개발팀은 다음과 같은 문제를 겪고 있습니다:

#### 현재 문제점
1. **수동 데이터베이스 관리**: 개발자가 직접 데이터베이스 인스턴스를 생성하고 관리
2. **일관성 부족**: 환경별로 다른 설정과 리소스 할당
3. **백업 누락**: 수동 백업으로 인한 데이터 손실 위험
4. **모니터링 부재**: 데이터베이스 상태를 실시간으로 모니터링하지 못함
5. **운영 부담**: 인프라 팀의 수동 작업으로 인한 운영 비용 증가

#### 비즈니스 요구사항 도출 과정

##### 1단계: 이해관계자 인터뷰

**개발팀 리더 (김개발)**
> "개발팀이 데이터베이스 인스턴스를 빠르게 생성하고 관리할 수 있는 자동화된 솔루션이 필요합니다. 현재는 인프라 팀에 요청해서 2-3일이 걸리는데, 이를 몇 분 내로 단축하고 싶습니다."

**인프라 팀장 (박인프라)**
> "수동으로 데이터베이스 인스턴스를 관리하는 것이 너무 번거롭습니다. 자동화된 솔루션으로 운영 부담을 줄이고, 일관된 설정을 보장하고 싶습니다."

**보안팀장 (이보안)**
> "데이터베이스 보안 정책을 자동으로 적용하고, 환경별로 적절한 보안 설정이 적용되도록 하고 싶습니다."

**운영팀장 (최운영)**
> "데이터베이스 상태를 실시간으로 모니터링하고, 문제 발생 시 자동으로 알림을 받고 싶습니다."

##### 2단계: 기술적 요구사항 도출

**아키텍처팀 (정아키)**
> "Kubernetes 환경에서 동작하는 Operator 패턴을 사용하여 데이터베이스 생명주기를 관리하는 솔루션이 필요합니다. CRD를 통해 개발자가 간단한 YAML로 데이터베이스 인스턴스를 생성할 수 있어야 합니다."

**개발팀 (김개발)**
> "MySQL과 PostgreSQL을 지원하고, 개발/스테이징/프로덕션 환경별로 다른 설정을 적용할 수 있어야 합니다. 또한 자동 백업과 모니터링 기능이 필요합니다."

##### 3단계: 비기능적 요구사항 도출

**성능팀 (박성능)**
> "동시에 10개 이상의 데이터베이스 인스턴스를 관리할 수 있어야 하고, 리소스 생성은 30초 내에 완료되어야 합니다."

**보안팀 (이보안)**
> "RBAC 권한 관리, 네트워크 격리, 데이터 암호화 등 보안 요구사항을 충족해야 합니다."

**운영팀 (최운영)**
> "99.9% 가용성을 보장하고, Pod 실패 시 자동 복구가 가능해야 합니다."

#### 최종 요구사항 정리

위의 시나리오를 바탕으로 다음과 같은 요구사항이 도출되었습니다:

### 1. 기능 요구사항

#### 1.1 기본 CRD 기능
- **Database 리소스**: MySQL/PostgreSQL 데이터베이스 인스턴스 관리
- **필수 필드**: type (mysql/postgresql), version, replicas, storage
- **선택 필드**: backup, monitoring, environment, resources
- **상태 관리**: phase, ready, replicas, lastBackup, conditions

#### 1.2 Controller 기능
- **StatefulSet 관리**: 데이터베이스 Pod 생성/관리
- **Service 관리**: 데이터베이스 접근을 위한 Service 생성
- **ConfigMap 관리**: 데이터베이스 설정 파일 관리
- **CronJob 관리**: 백업 스케줄링 (백업 활성화 시)

#### 1.3 Webhook 기능
- **Mutating Webhook**: 기본값 설정 (replicas, environment, resources)
- **Validating Webhook**: 비즈니스 규칙 검증 (환경별 제약사항)

#### 1.4 고급 기능
- **자동 백업**: CronJob 기반 백업 스케줄링
- **환경별 설정**: dev/staging/prod 다른 리소스 할당
- **상태 모니터링**: 실시간 상태 추적 및 업데이트

### 2. 비기능 요구사항

#### 2.1 성능 요구사항
- **응답 시간**: Database 리소스 생성 후 30초 내 StatefulSet 생성
- **처리량**: 동시에 10개 이상의 Database 인스턴스 관리 가능
- **확장성**: 복제본 수 1-10개 지원

#### 2.2 안정성 요구사항
- **가용성**: 99.9% 가용성 보장
- **복구**: Pod 실패 시 자동 재시작
- **백업**: 일일 자동 백업 및 보관 기간 관리

#### 2.3 보안 요구사항
- **RBAC**: 적절한 권한 설정
- **검증**: 잘못된 설정 차단
- **격리**: 네임스페이스별 격리

### 3. 제약사항

#### 3.1 기술 제약사항
- **Kubernetes**: 1.20+ 버전 지원
- **Go**: 1.19+ 버전 사용
- **Kubebuilder**: 3.0+ 버전 사용

#### 3.2 비즈니스 제약사항
- **데이터베이스 타입**: MySQL, PostgreSQL만 지원
- **환경**: development, staging, production만 지원
- **복제본**: 최대 10개까지 지원

## 🎯 실습 가이드

### 단계별 실습 방법

1. **요구사항 분석**: 위의 요구사항을 자세히 읽고 이해
2. **직접 구현**: 요구사항에 따라 코드를 직접 작성
3. **솔루션 비교**: 작성한 코드와 제공된 솔루션 비교
4. **개선점 파악**: 차이점을 분석하고 개선점 도출

### 실습 순서

1. **CRD 스키마 설계** → 직접 구현 → 솔루션 비교
2. **Controller 기본 구조** → 직접 구현 → 솔루션 비교
3. **StatefulSet 관리** → 직접 구현 → 솔루션 비교
4. **Service/ConfigMap 관리** → 직접 구현 → 솔루션 비교
5. **Webhook 구현** → 직접 구현 → 솔루션 비교
6. **고급 기능** → 직접 구현 → 솔루션 비교

## 1단계: 프로젝트 초기 설정

### 1.1 프로젝트 생성

```bash
# 프로젝트 디렉터리 생성
mkdir database-operator
cd database-operator

# Kubebuilder 프로젝트 초기화
kubebuilder init --domain database.example.com

# Database API 생성
kubebuilder create api --group database --version v1 --kind Database

# Webhook 생성
kubebuilder create webhook --group database --version v1 --kind Database
```

### 1.2 프로젝트 구조 확인

```
database-operator/
├── api/
│   └── v1/
│       ├── database_types.go
│       ├── database_webhook.go
│       └── groupversion_info.go
├── config/
│   ├── crd/
│   ├── rbac/
│   └── samples/
├── controllers/
│   └── database_controller.go
├── internal/
│   └── webhook/
└── main.go
```

## 2단계: Database CRD 스키마 정의

### 🎬 시나리오: CRD 스키마 설계 회의

#### 상황
TechCorp의 아키텍처팀과 개발팀이 Database CRD의 스키마를 설계하는 회의를 진행하고 있습니다.

**아키텍처팀 (정아키)**
> "Database CRD의 스키마를 설계해야 합니다. 개발팀이 어떤 필드들을 필요로 하는지 파악해보겠습니다."

**개발팀 (김개발)**
> "우리가 데이터베이스 인스턴스를 생성할 때 필요한 정보들을 정리해보겠습니다."

#### 요구사항 도출 과정

##### 1단계: 필수 필드 식별

**개발팀 (김개발)**
> "데이터베이스 타입(mysql/postgresql)과 버전은 필수입니다. 복제본 수와 스토리지 크기도 반드시 필요합니다."

**인프라팀 (박인프라)**
> "환경별로 다른 설정을 적용할 수 있어야 합니다. development, staging, production 환경을 구분해야 합니다."

##### 2단계: 선택 필드 식별

**운영팀 (최운영)**
> "백업 설정은 선택적으로 활성화할 수 있어야 합니다. 스케줄과 보관 기간을 설정할 수 있어야 합니다."

**모니터링팀 (이모니터)**
> "모니터링 기능도 선택적으로 활성화할 수 있어야 합니다. 메트릭 수집과 로그 수집을 개별적으로 설정할 수 있어야 합니다."

##### 3단계: 상태 필드 설계

**아키텍처팀 (정아키)**
> "Database 리소스의 상태를 추적할 수 있는 필드들이 필요합니다. 현재 단계, 준비 상태, 복제본 수, 마지막 백업 시간 등을 포함해야 합니다."

### 📋 요구사항

#### 2.1 CRD 스키마 요구사항
- **Database 리소스**: `database.example.com/v1` API 그룹
- **필수 필드**: 
  - `type`: mysql 또는 postgresql
  - `version`: 데이터베이스 버전 (예: "8.0", "14")
  - `replicas`: 복제본 수 (1-10)
  - `storage`: 스토리지 크기와 클래스
- **선택 필드**:
  - `backup`: 백업 설정 (enabled, schedule, retention)
  - `monitoring`: 모니터링 설정 (enabled, metrics, logging)
  - `environment`: 환경 (development, staging, production)
  - `resources`: 리소스 요구사항
- **상태 필드**:
  - `phase`: 현재 단계 (Pending, Creating, Ready, PartiallyReady)
  - `ready`: 준비 상태
  - `replicas`: 현재 복제본 수
  - `lastBackup`: 마지막 백업 시간
  - `conditions`: 상태 조건들

#### 2.2 kubebuilder 마커 요구사항
- **검증 마커**: 필수 필드, 범위 제한, 열거형 값
- **기본값 마커**: 환경별 기본값 설정
- **출력 컬럼**: kubectl get에서 보여줄 컬럼들
- **리소스 마커**: 단축 이름, 서브리소스 설정

### 🎯 실습: 직접 구현해보세요!

요구사항을 보고 `api/v1/database_types.go` 파일을 직접 작성해보세요.

<details>
<summary>💡 힌트</summary>

- `kubebuilder:validation:Required` - 필수 필드
- `kubebuilder:validation:Enum` - 열거형 값
- `kubebuilder:validation:Minimum/Maximum` - 범위 제한
- `kubebuilder:default` - 기본값
- `kubebuilder:printcolumn` - 출력 컬럼
- `kubebuilder:subresource:status` - 상태 서브리소스

</details>

### 📝 솔루션: Database CRD 스키마

<details>
<summary>🔍 솔루션 보기</summary>

`api/v1/database_types.go` 파일을 수정합니다:

```go
package v1

import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    corev1 "k8s.io/api/core/v1"
)

// DatabaseSpec defines the desired state of Database
type DatabaseSpec struct {
    // Type은 데이터베이스 타입입니다
    // +kubebuilder:validation:Required
    // +kubebuilder:validation:Enum=mysql;postgresql
    Type string `json:"type"`

    // Version은 데이터베이스 버전입니다
    // +kubebuilder:validation:Required
    Version string `json:"version"`

    // Replicas는 복제본 수입니다
    // +kubebuilder:validation:Minimum=1
    // +kubebuilder:validation:Maximum=10
    // +kubebuilder:default=1
    Replicas int32 `json:"replicas,omitempty"`

    // Storage는 스토리지 설정입니다
    Storage DatabaseStorage `json:"storage"`

    // Backup은 백업 설정입니다
    // +kubebuilder:validation:Optional
    Backup *DatabaseBackup `json:"backup,omitempty"`

    // Monitoring은 모니터링 설정입니다
    // +kubebuilder:validation:Optional
    Monitoring *DatabaseMonitoring `json:"monitoring,omitempty"`

    // Environment는 배포 환경입니다
    // +kubebuilder:validation:Enum=development;staging;production
    // +kubebuilder:default=development
    Environment string `json:"environment,omitempty"`

    // Resources는 리소스 요구사항입니다
    // +kubebuilder:validation:Optional
    Resources *corev1.ResourceRequirements `json:"resources,omitempty"`
}

// DatabaseStorage defines the storage configuration
type DatabaseStorage struct {
    // Size는 스토리지 크기입니다
    // +kubebuilder:validation:Required
    Size string `json:"size"`

    // Class는 스토리지 클래스입니다
    // +kubebuilder:validation:Optional
    Class string `json:"class,omitempty"`
}

// DatabaseBackup defines the backup configuration
type DatabaseBackup struct {
    // Enabled는 백업 활성화 여부입니다
    // +kubebuilder:default=false
    Enabled bool `json:"enabled"`

    // Schedule은 백업 스케줄입니다 (Cron 형식)
    // +kubebuilder:validation:Optional
    Schedule string `json:"schedule,omitempty"`

    // Retention은 백업 보관 기간입니다
    // +kubebuilder:validation:Optional
    Retention string `json:"retention,omitempty"`
}

// DatabaseMonitoring defines the monitoring configuration
type DatabaseMonitoring struct {
    // Enabled는 모니터링 활성화 여부입니다
    // +kubebuilder:default=false
    Enabled bool `json:"enabled"`

    // Metrics는 메트릭 수집 여부입니다
    // +kubebuilder:default=false
    Metrics bool `json:"metrics"`

    // Logging은 로그 수집 여부입니다
    // +kubebuilder:default=false
    Logging bool `json:"logging"`
}

// DatabaseStatus defines the observed state of Database
type DatabaseStatus struct {
    // Phase는 현재 단계입니다
    Phase string `json:"phase,omitempty"`

    // Ready는 준비 상태입니다
    Ready bool `json:"ready"`

    // Replicas는 현재 복제본 수입니다
    Replicas int32 `json:"replicas"`

    // LastBackup은 마지막 백업 시간입니다
    LastBackup string `json:"lastBackup,omitempty"`

    // Conditions는 상태 조건들입니다
    Conditions []metav1.Condition `json:"conditions,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:shortName=db
// +kubebuilder:printcolumn:name="Type",type="string",JSONPath=".spec.type"
// +kubebuilder:printcolumn:name="Version",type="string",JSONPath=".spec.version"
// +kubebuilder:printcolumn:name="Replicas",type="integer",JSONPath=".spec.replicas"
// +kubebuilder:printcolumn:name="Environment",type="string",JSONPath=".spec.environment"
// +kubebuilder:printcolumn:name="Ready",type="boolean",JSONPath=".status.ready"
// +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"

// Database is the Schema for the databases API
type Database struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`

    Spec   DatabaseSpec   `json:"spec,omitempty"`
    Status DatabaseStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// DatabaseList contains a list of Database
type DatabaseList struct {
    metav1.TypeMeta `json:",inline"`
    metav1.ListMeta `json:"metadata,omitempty"`
    Items           []Database `json:"items"`
}

func init() {
    SchemeBuilder.Register(&Database{}, &DatabaseList{})
}
```

## 3단계: 기본 Controller 구현

### 🎬 시나리오: Controller 설계 및 구현 계획

#### 상황
TechCorp의 개발팀이 Database CRD 스키마를 완성한 후, 이제 Controller를 구현해야 합니다.

**개발팀 (김개발)**
> "CRD 스키마는 완성되었습니다. 이제 Database 리소스가 생성될 때 실제로 StatefulSet, Service, ConfigMap 등을 생성하는 Controller를 구현해야 합니다."

**아키텍처팀 (정아키)**
> "Controller는 Database 리소스의 변경사항을 감지하고, 원하는 상태와 실제 상태를 비교하여 조정하는 역할을 해야 합니다."

#### 요구사항 도출 과정

##### 1단계: Controller 역할 정의

**아키텍처팀 (정아키)**
> "Controller는 Reconcile 패턴을 사용해야 합니다. Database 리소스가 생성/수정/삭제될 때마다 호출되어야 합니다."

**개발팀 (김개발)**
> "Database 리소스가 생성되면 StatefulSet, Service, ConfigMap을 생성해야 합니다. 백업이 활성화된 경우 CronJob도 생성해야 합니다."

##### 2단계: 에러 처리 전략

**운영팀 (최운영)**
> "리소스 생성에 실패하거나 조회에 실패하는 경우를 대비한 에러 처리 로직이 필요합니다. 재시도 메커니즘도 구현해야 합니다."

**개발팀 (김개발)**
> "로깅도 중요합니다. 각 단계별로 상세한 로그를 남겨서 문제 발생 시 디버깅할 수 있어야 합니다."

##### 3단계: 권한 및 보안

**보안팀 (이보안)**
> "Controller가 필요한 리소스들에 대한 적절한 권한을 가져야 합니다. RBAC 설정이 필요합니다."

### 📋 요구사항

#### 3.1 Controller 기본 구조 요구사항
- **Reconcile 함수**: Database 리소스 변경 시 호출되는 메인 함수
- **RBAC 권한**: Database, StatefulSet, Service, ConfigMap, CronJob 관리 권한
- **Watch 설정**: Database 리소스와 하위 리소스들 감시
- **에러 처리**: 리소스 조회 실패, 생성/업데이트 실패 처리
- **로깅**: 각 단계별 상세 로깅

#### 3.2 Reconcile 로직 요구사항
1. **Database 리소스 조회**: 요청된 Database 리소스 가져오기
2. **StatefulSet 관리**: 데이터베이스 Pod 생성/업데이트
3. **Service 관리**: 데이터베이스 접근을 위한 Service 생성/업데이트
4. **ConfigMap 관리**: 데이터베이스 설정 파일 생성/업데이트
5. **백업 CronJob 관리**: 백업이 활성화된 경우 CronJob 생성/업데이트
6. **상태 업데이트**: Database 리소스의 상태 업데이트

#### 3.3 에러 처리 요구사항
- **리소스 없음**: Database가 삭제된 경우 무시
- **리소스 조회 실패**: 에러 로깅 후 재시도
- **생성/업데이트 실패**: 에러 로깅 후 재시도
- **재시도 간격**: 30초마다 재시도

### 🎯 실습: 직접 구현해보세요!

요구사항을 보고 `controllers/database_controller.go` 파일의 기본 구조를 직접 작성해보세요.

<details>
<summary>💡 힌트</summary>

- `ctrl.Request`로 Database 리소스 정보 가져오기
- `r.Get()`으로 Database 리소스 조회
- `errors.IsNotFound()`로 리소스 존재 여부 확인
- `log.FromContext(ctx)`로 로깅
- `ctrl.Result{RequeueAfter: 30 * time.Second}`로 재시도 설정

</details>

### 📝 솔루션: Controller 기본 구조

<details>
<summary>🔍 솔루션 보기</summary>

`controllers/database_controller.go` 파일을 수정합니다:

```go
package controllers

import (
    "context"
    "fmt"
    "time"

    "github.com/go-logr/logr"
    appsv1 "k8s.io/api/apps/v1"
    corev1 "k8s.io/api/core/v1"
    "k8s.io/apimachinery/pkg/api/errors"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/apimachinery/pkg/runtime"
    "k8s.io/apimachinery/pkg/types"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/client"
    "sigs.k8s.io/controller-runtime/pkg/log"

    databasev1 "database-operator/api/v1"
)

// DatabaseReconciler reconciles a Database object
type DatabaseReconciler struct {
    client.Client
    Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=database.example.com,resources=databases,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=database.example.com,resources=databases/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=database.example.com,resources=databases/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=statefulsets,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=services,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=configmaps,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=batch,resources=cronjobs,verbs=get;list;watch;create;update;patch;delete

// Reconcile is part of the main kubernetes reconciliation loop
func (r *DatabaseReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    logger := log.FromContext(ctx)

    // 1. Database 리소스 조회
    var database databasev1.Database
    if err := r.Get(ctx, req.NamespacedName, &database); err != nil {
        if errors.IsNotFound(err) {
            logger.Info("Database resource not found. Ignoring since object must be deleted")
            return ctrl.Result{}, nil
        }
        logger.Error(err, "Failed to get Database")
        return ctrl.Result{}, err
    }

    logger.Info("Reconciling Database", "name", database.Name, "type", database.Spec.Type)

    // 2. StatefulSet 생성/업데이트
    if err := r.reconcileStatefulSet(ctx, &database); err != nil {
        logger.Error(err, "Failed to reconcile StatefulSet")
        return ctrl.Result{}, err
    }

    // 3. Service 생성/업데이트
    if err := r.reconcileService(ctx, &database); err != nil {
        logger.Error(err, "Failed to reconcile Service")
        return ctrl.Result{}, err
    }

    // 4. ConfigMap 생성/업데이트
    if err := r.reconcileConfigMap(ctx, &database); err != nil {
        logger.Error(err, "Failed to reconcile ConfigMap")
        return ctrl.Result{}, err
    }

    // 5. 백업 CronJob 생성/업데이트 (백업이 활성화된 경우)
    if database.Spec.Backup != nil && database.Spec.Backup.Enabled {
        if err := r.reconcileBackupJob(ctx, &database); err != nil {
            logger.Error(err, "Failed to reconcile Backup Job")
            return ctrl.Result{}, err
        }
    }

    // 6. 상태 업데이트
    if err := r.updateStatus(ctx, &database); err != nil {
        logger.Error(err, "Failed to update status")
        return ctrl.Result{}, err
    }

    return ctrl.Result{RequeueAfter: 30 * time.Second}, nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *DatabaseReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&databasev1.Database{}).
        Owns(&appsv1.StatefulSet{}).
        Owns(&corev1.Service{}).
        Owns(&corev1.ConfigMap{}).
        Complete(r)
}
```

## 4단계: Controller 핵심 함수 구현

### 4.1 StatefulSet 관리 함수

### 📋 요구사항

#### 4.1 StatefulSet 관리 요구사항
- **reconcileStatefulSet 함수**: StatefulSet 생성/업데이트/삭제 관리
- **buildStatefulSet 함수**: Database 스펙으로부터 StatefulSet 생성
- **statefulSetNeedsUpdate 함수**: StatefulSet 업데이트 필요 여부 판단
- **헬퍼 함수들**:
  - `getDatabaseImage`: 데이터베이스 타입별 이미지 반환
  - `getDatabasePort`: 데이터베이스 타입별 포트 반환
  - `getResourceRequirements`: 환경별 리소스 요구사항 반환
  - `getDatabaseEnv`: 데이터베이스 환경 변수 반환
  - `getLabels`: Database 리소스의 라벨 반환

#### 4.2 StatefulSet 스펙 요구사항
- **Pod 템플릿**: 데이터베이스 컨테이너, 포트, 리소스, 환경 변수
- **볼륨 마운트**: 데이터 볼륨, 설정 볼륨
- **PVC 템플릿**: 영구 스토리지 볼륨
- **OwnerReference**: Database 리소스와의 소유권 관계 설정

#### 4.3 환경별 설정 요구사항
- **Development**: CPU 100m-500m, Memory 256Mi-512Mi
- **Staging**: CPU 200m-1000m, Memory 512Mi-1Gi
- **Production**: CPU 500m-2000m, Memory 1Gi-4Gi

### 🎯 실습: 직접 구현해보세요!

요구사항을 보고 StatefulSet 관리 함수들을 직접 작성해보세요.

<details>
<summary>💡 힌트</summary>

- `appsv1.StatefulSet` 구조체 사용
- `corev1.PodTemplateSpec`으로 Pod 템플릿 설정
- `corev1.PersistentVolumeClaim`으로 PVC 템플릿 설정
- `ctrl.SetControllerReference()`로 OwnerReference 설정
- `resource.MustParse()`로 리소스 파싱

</details>

### 📝 솔루션: StatefulSet 관리 함수

<details>
<summary>🔍 솔루션 보기</summary>

`controllers/database_controller.go`에 다음 함수들을 추가합니다:

```go
// reconcileStatefulSet는 StatefulSet을 생성/업데이트합니다
func (r *DatabaseReconciler) reconcileStatefulSet(ctx context.Context, database *databasev1.Database) error {
    logger := log.FromContext(ctx)
    
    // StatefulSet 조회
    var statefulSet appsv1.StatefulSet
    err := r.Get(ctx, types.NamespacedName{
        Name:      database.Name,
        Namespace: database.Namespace,
    }, &statefulSet)
    
    if err != nil && errors.IsNotFound(err) {
        // StatefulSet이 없으면 생성
        statefulSet = r.buildStatefulSet(database)
        if err := r.Create(ctx, &statefulSet); err != nil {
            return fmt.Errorf("failed to create StatefulSet: %w", err)
        }
        logger.Info("Created StatefulSet", "name", statefulSet.Name)
    } else if err != nil {
        return fmt.Errorf("failed to get StatefulSet: %w", err)
    } else {
        // StatefulSet이 있으면 업데이트
        if r.statefulSetNeedsUpdate(&statefulSet, database) {
            updatedStatefulSet := r.buildStatefulSet(database)
            updatedStatefulSet.ResourceVersion = statefulSet.ResourceVersion
            if err := r.Update(ctx, &updatedStatefulSet); err != nil {
                return fmt.Errorf("failed to update StatefulSet: %w", err)
            }
            logger.Info("Updated StatefulSet", "name", statefulSet.Name)
        }
    }
    
    return nil
}

// buildStatefulSet는 Database 스펙으로부터 StatefulSet을 생성합니다
func (r *DatabaseReconciler) buildStatefulSet(database *databasev1.Database) appsv1.StatefulSet {
    labels := r.getLabels(database)
    
    // 환경별 리소스 설정
    resources := r.getResourceRequirements(database)
    
    // 데이터베이스 타입별 이미지 설정
    image := r.getDatabaseImage(database)
    
    statefulSet := appsv1.StatefulSet{
        ObjectMeta: metav1.ObjectMeta{
            Name:      database.Name,
            Namespace: database.Namespace,
            Labels:    labels,
        },
        Spec: appsv1.StatefulSetSpec{
            Replicas: &database.Spec.Replicas,
            Selector: &metav1.LabelSelector{
                MatchLabels: labels,
            },
            Template: corev1.PodTemplateSpec{
                ObjectMeta: metav1.ObjectMeta{
                    Labels: labels,
                },
                Spec: corev1.PodSpec{
                    Containers: []corev1.Container{
                        {
                            Name:  "database",
                            Image: image,
                            Ports: []corev1.ContainerPort{
                                {
                                    ContainerPort: r.getDatabasePort(database),
                                    Name:          "database",
                                },
                            },
                            Resources: resources,
                            VolumeMounts: []corev1.VolumeMount{
                                {
                                    Name:      "data",
                                    MountPath: "/var/lib/mysql",
                                },
                                {
                                    Name:      "config",
                                    MountPath: "/etc/mysql/conf.d",
                                },
                            },
                            Env: r.getDatabaseEnv(database),
                        },
                    },
                    Volumes: []corev1.Volume{
                        {
                            Name: "config",
                            VolumeSource: corev1.VolumeSource{
                                ConfigMap: &corev1.ConfigMapVolumeSource{
                                    LocalObjectReference: corev1.LocalObjectReference{
                                        Name: database.Name + "-config",
                                    },
                                },
                            },
                        },
                    },
                },
            },
            VolumeClaimTemplates: []corev1.PersistentVolumeClaim{
                {
                    ObjectMeta: metav1.ObjectMeta{
                        Name: "data",
                    },
                    Spec: corev1.PersistentVolumeClaimSpec{
                        AccessModes: []corev1.PersistentVolumeAccessMode{
                            corev1.ReadWriteOnce,
                        },
                        Resources: corev1.ResourceRequirements{
                            Requests: corev1.ResourceList{
                                corev1.ResourceStorage: resource.MustParse(database.Spec.Storage.Size),
                            },
                        },
                        StorageClassName: &database.Spec.Storage.Class,
                    },
                },
            },
        },
    }
    
    // OwnerReference 설정
    if err := ctrl.SetControllerReference(database, &statefulSet, r.Scheme); err != nil {
        log.Log.Error(err, "Failed to set controller reference for StatefulSet")
    }
    
    return statefulSet
}

// getDatabaseImage는 데이터베이스 타입에 따른 이미지를 반환합니다
func (r *DatabaseReconciler) getDatabaseImage(database *databasev1.Database) string {
    switch database.Spec.Type {
    case "mysql":
        return fmt.Sprintf("mysql:%s", database.Spec.Version)
    case "postgresql":
        return fmt.Sprintf("postgres:%s", database.Spec.Version)
    default:
        return fmt.Sprintf("mysql:%s", database.Spec.Version)
    }
}

// getDatabasePort는 데이터베이스 타입에 따른 포트를 반환합니다
func (r *DatabaseReconciler) getDatabasePort(database *databasev1.Database) int32 {
    switch database.Spec.Type {
    case "mysql":
        return 3306
    case "postgresql":
        return 5432
    default:
        return 3306
    }
}

// getResourceRequirements는 환경별 리소스 요구사항을 반환합니다
func (r *DatabaseReconciler) getResourceRequirements(database *databasev1.Database) corev1.ResourceRequirements {
    if database.Spec.Resources != nil {
        return *database.Spec.Resources
    }
    
    // 환경별 기본 리소스 설정
    switch database.Spec.Environment {
    case "development":
        return corev1.ResourceRequirements{
            Requests: corev1.ResourceList{
                corev1.ResourceCPU:    resource.MustParse("100m"),
                corev1.ResourceMemory: resource.MustParse("256Mi"),
            },
            Limits: corev1.ResourceList{
                corev1.ResourceCPU:    resource.MustParse("500m"),
                corev1.ResourceMemory: resource.MustParse("512Mi"),
            },
        }
    case "staging":
        return corev1.ResourceRequirements{
            Requests: corev1.ResourceList{
                corev1.ResourceCPU:    resource.MustParse("200m"),
                corev1.ResourceMemory: resource.MustParse("512Mi"),
            },
            Limits: corev1.ResourceList{
                corev1.ResourceCPU:    resource.MustParse("1000m"),
                corev1.ResourceMemory: resource.MustParse("1Gi"),
            },
        }
    case "production":
        return corev1.ResourceRequirements{
            Requests: corev1.ResourceList{
                corev1.ResourceCPU:    resource.MustParse("500m"),
                corev1.ResourceMemory: resource.MustParse("1Gi"),
            },
            Limits: corev1.ResourceList{
                corev1.ResourceCPU:    resource.MustParse("2000m"),
                corev1.ResourceMemory: resource.MustParse("4Gi"),
            },
        }
    default:
        return corev1.ResourceRequirements{
            Requests: corev1.ResourceList{
                corev1.ResourceCPU:    resource.MustParse("100m"),
                corev1.ResourceMemory: resource.MustParse("256Mi"),
            },
        }
    }
}

// getDatabaseEnv는 데이터베이스 환경 변수를 반환합니다
func (r *DatabaseReconciler) getDatabaseEnv(database *databasev1.Database) []corev1.EnvVar {
    envVars := []corev1.EnvVar{
        {
            Name:  "MYSQL_ROOT_PASSWORD",
            Value: "rootpassword",
        },
        {
            Name:  "MYSQL_DATABASE",
            Value: database.Name,
        },
        {
            Name:  "MYSQL_USER",
            Value: database.Name,
        },
        {
            Name:  "MYSQL_PASSWORD",
            Value: "userpassword",
        },
    }
    
    if database.Spec.Type == "postgresql" {
        envVars = []corev1.EnvVar{
            {
                Name:  "POSTGRES_DB",
                Value: database.Name,
            },
            {
                Name:  "POSTGRES_USER",
                Value: database.Name,
            },
            {
                Name:  "POSTGRES_PASSWORD",
                Value: "userpassword",
            },
        }
    }
    
    return envVars
}

// getLabels는 Database 리소스의 라벨을 반환합니다
func (r *DatabaseReconciler) getLabels(database *databasev1.Database) map[string]string {
    return map[string]string{
        "app":                    "database",
        "database.example.com":   database.Name,
        "database.example.com/type": database.Spec.Type,
        "database.example.com/environment": database.Spec.Environment,
    }
}

// statefulSetNeedsUpdate는 StatefulSet 업데이트가 필요한지 확인합니다
func (r *DatabaseReconciler) statefulSetNeedsUpdate(statefulSet *appsv1.StatefulSet, database *databasev1.Database) bool {
    // 복제본 수 변경 확인
    if statefulSet.Spec.Replicas == nil || *statefulSet.Spec.Replicas != database.Spec.Replicas {
        return true
    }
    
    // 컨테이너 이미지 변경 확인
    if len(statefulSet.Spec.Template.Spec.Containers) > 0 {
        expectedImage := r.getDatabaseImage(database)
        if statefulSet.Spec.Template.Spec.Containers[0].Image != expectedImage {
            return true
        }
    }
    
    return false
}
```

### 4.2 Service 관리 함수

```go
// reconcileService는 Service를 생성/업데이트합니다
func (r *DatabaseReconciler) reconcileService(ctx context.Context, database *databasev1.Database) error {
    logger := log.FromContext(ctx)
    
    // Service 조회
    var service corev1.Service
    err := r.Get(ctx, types.NamespacedName{
        Name:      database.Name,
        Namespace: database.Namespace,
    }, &service)
    
    if err != nil && errors.IsNotFound(err) {
        // Service가 없으면 생성
        service = r.buildService(database)
        if err := r.Create(ctx, &service); err != nil {
            return fmt.Errorf("failed to create Service: %w", err)
        }
        logger.Info("Created Service", "name", service.Name)
    } else if err != nil {
        return fmt.Errorf("failed to get Service: %w", err)
    } else {
        // Service가 있으면 업데이트
        if r.serviceNeedsUpdate(&service, database) {
            updatedService := r.buildService(database)
            updatedService.ResourceVersion = service.ResourceVersion
            if err := r.Update(ctx, &updatedService); err != nil {
                return fmt.Errorf("failed to update Service: %w", err)
            }
            logger.Info("Updated Service", "name", service.Name)
        }
    }
    
    return nil
}

// buildService는 Database 스펙으로부터 Service를 생성합니다
func (r *DatabaseReconciler) buildService(database *databasev1.Database) corev1.Service {
    labels := r.getLabels(database)
    port := r.getDatabasePort(database)
    
    service := corev1.Service{
        ObjectMeta: metav1.ObjectMeta{
            Name:      database.Name,
            Namespace: database.Namespace,
            Labels:    labels,
        },
        Spec: corev1.ServiceSpec{
            Selector: labels,
            Ports: []corev1.ServicePort{
                {
                    Name:       "database",
                    Port:       port,
                    TargetPort: intstr.FromInt(int(port)),
                    Protocol:   corev1.ProtocolTCP,
                },
            },
            Type: corev1.ServiceTypeClusterIP,
        },
    }
    
    // OwnerReference 설정
    if err := ctrl.SetControllerReference(database, &service, r.Scheme); err != nil {
        log.Log.Error(err, "Failed to set controller reference for Service")
    }
    
    return service
}

// serviceNeedsUpdate는 Service 업데이트가 필요한지 확인합니다
func (r *DatabaseReconciler) serviceNeedsUpdate(service *corev1.Service, database *databasev1.Database) bool {
    // 포트 변경 확인
    expectedPort := r.getDatabasePort(database)
    if len(service.Spec.Ports) > 0 && service.Spec.Ports[0].Port != expectedPort {
        return true
    }
    
    return false
}
```

### 4.3 ConfigMap 관리 함수

```go
// reconcileConfigMap는 ConfigMap을 생성/업데이트합니다
func (r *DatabaseReconciler) reconcileConfigMap(ctx context.Context, database *databasev1.Database) error {
    logger := log.FromContext(ctx)
    
    // ConfigMap 조회
    var configMap corev1.ConfigMap
    err := r.Get(ctx, types.NamespacedName{
        Name:      database.Name + "-config",
        Namespace: database.Namespace,
    }, &configMap)
    
    if err != nil && errors.IsNotFound(err) {
        // ConfigMap이 없으면 생성
        configMap = r.buildConfigMap(database)
        if err := r.Create(ctx, &configMap); err != nil {
            return fmt.Errorf("failed to create ConfigMap: %w", err)
        }
        logger.Info("Created ConfigMap", "name", configMap.Name)
    } else if err != nil {
        return fmt.Errorf("failed to get ConfigMap: %w", err)
    } else {
        // ConfigMap이 있으면 업데이트
        if r.configMapNeedsUpdate(&configMap, database) {
            updatedConfigMap := r.buildConfigMap(database)
            updatedConfigMap.ResourceVersion = configMap.ResourceVersion
            if err := r.Update(ctx, &updatedConfigMap); err != nil {
                return fmt.Errorf("failed to update ConfigMap: %w", err)
            }
            logger.Info("Updated ConfigMap", "name", configMap.Name)
        }
    }
    
    return nil
}

// buildConfigMap은 Database 스펙으로부터 ConfigMap을 생성합니다
func (r *DatabaseReconciler) buildConfigMap(database *databasev1.Database) corev1.ConfigMap {
    labels := r.getLabels(database)
    
    // 데이터베이스 타입별 설정 파일 생성
    configData := r.getDatabaseConfig(database)
    
    configMap := corev1.ConfigMap{
        ObjectMeta: metav1.ObjectMeta{
            Name:      database.Name + "-config",
            Namespace: database.Namespace,
            Labels:    labels,
        },
        Data: configData,
    }
    
    // OwnerReference 설정
    if err := ctrl.SetControllerReference(database, &configMap, r.Scheme); err != nil {
        log.Log.Error(err, "Failed to set controller reference for ConfigMap")
    }
    
    return configMap
}

// getDatabaseConfig는 데이터베이스 타입별 설정을 반환합니다
func (r *DatabaseReconciler) getDatabaseConfig(database *databasev1.Database) map[string]string {
    configData := make(map[string]string)
    
    switch database.Spec.Type {
    case "mysql":
        configData["my.cnf"] = r.getMySQLConfig(database)
    case "postgresql":
        configData["postgresql.conf"] = r.getPostgreSQLConfig(database)
    }
    
    return configData
}

// getMySQLConfig는 MySQL 설정을 반환합니다
func (r *DatabaseReconciler) getMySQLConfig(database *databasev1.Database) string {
    config := `[mysqld]
# 기본 설정
bind-address = 0.0.0.0
port = 3306
max_connections = 100

# 환경별 설정
`
    
    switch database.Spec.Environment {
    case "development":
        config += `
# 개발 환경 설정
innodb_buffer_pool_size = 128M
query_cache_size = 32M
`
    case "staging":
        config += `
# 스테이징 환경 설정
innodb_buffer_pool_size = 256M
query_cache_size = 64M
`
    case "production":
        config += `
# 프로덕션 환경 설정
innodb_buffer_pool_size = 1G
query_cache_size = 128M
innodb_log_file_size = 256M
`
    }
    
    return config
}

// getPostgreSQLConfig는 PostgreSQL 설정을 반환합니다
func (r *DatabaseReconciler) getPostgreSQLConfig(database *databasev1.Database) string {
    config := `# PostgreSQL 설정
listen_addresses = '*'
port = 5432
max_connections = 100

# 환경별 설정
`
    
    switch database.Spec.Environment {
    case "development":
        config += `
# 개발 환경 설정
shared_buffers = 128MB
effective_cache_size = 256MB
`
    case "staging":
        config += `
# 스테이징 환경 설정
shared_buffers = 256MB
effective_cache_size = 512MB
`
    case "production":
        config += `
# 프로덕션 환경 설정
shared_buffers = 1GB
effective_cache_size = 2GB
wal_buffers = 16MB
`
    }
    
    return config
}

// configMapNeedsUpdate는 ConfigMap 업데이트가 필요한지 확인합니다
func (r *DatabaseReconciler) configMapNeedsUpdate(configMap *corev1.ConfigMap, database *databasev1.Database) bool {
    // 설정 변경 확인
    expectedConfig := r.getDatabaseConfig(database)
    for key, value := range expectedConfig {
        if configMap.Data[key] != value {
            return true
        }
    }
    
    return false
}
```

### 4.4 백업 CronJob 관리 함수

```go
// reconcileBackupJob는 백업 CronJob을 생성/업데이트합니다
func (r *DatabaseReconciler) reconcileBackupJob(ctx context.Context, database *databasev1.Database) error {
    logger := log.FromContext(ctx)
    
    // CronJob 조회
    var cronJob batchv1.CronJob
    err := r.Get(ctx, types.NamespacedName{
        Name:      database.Name + "-backup",
        Namespace: database.Namespace,
    }, &cronJob)
    
    if err != nil && errors.IsNotFound(err) {
        // CronJob이 없으면 생성
        cronJob = r.buildBackupCronJob(database)
        if err := r.Create(ctx, &cronJob); err != nil {
            return fmt.Errorf("failed to create Backup CronJob: %w", err)
        }
        logger.Info("Created Backup CronJob", "name", cronJob.Name)
    } else if err != nil {
        return fmt.Errorf("failed to get Backup CronJob: %w", err)
    } else {
        // CronJob이 있으면 업데이트
        if r.backupCronJobNeedsUpdate(&cronJob, database) {
            updatedCronJob := r.buildBackupCronJob(database)
            updatedCronJob.ResourceVersion = cronJob.ResourceVersion
            if err := r.Update(ctx, &updatedCronJob); err != nil {
                return fmt.Errorf("failed to update Backup CronJob: %w", err)
            }
            logger.Info("Updated Backup CronJob", "name", cronJob.Name)
        }
    }
    
    return nil
}

// buildBackupCronJob은 Database 스펙으로부터 백업 CronJob을 생성합니다
func (r *DatabaseReconciler) buildBackupCronJob(database *databasev1.Database) batchv1.CronJob {
    labels := r.getLabels(database)
    
    // 백업 스크립트 생성
    backupScript := r.getBackupScript(database)
    
    cronJob := batchv1.CronJob{
        ObjectMeta: metav1.ObjectMeta{
            Name:      database.Name + "-backup",
            Namespace: database.Namespace,
            Labels:    labels,
        },
        Spec: batchv1.CronJobSpec{
            Schedule: database.Spec.Backup.Schedule,
            JobTemplate: batchv1.JobTemplateSpec{
                ObjectMeta: metav1.ObjectMeta{
                    Labels: labels,
                },
                Spec: batchv1.JobSpec{
                    Template: corev1.PodTemplateSpec{
                        ObjectMeta: metav1.ObjectMeta{
                            Labels: labels,
                        },
                        Spec: corev1.PodSpec{
                            RestartPolicy: corev1.RestartPolicyOnFailure,
                            Containers: []corev1.Container{
                                {
                                    Name:  "backup",
                                    Image: r.getBackupImage(database),
                                    Command: []string{"/bin/bash", "-c"},
                                    Args:   []string{backupScript},
                                    Env: []corev1.EnvVar{
                                        {
                                            Name:  "DATABASE_NAME",
                                            Value: database.Name,
                                        },
                                        {
                                            Name:  "DATABASE_TYPE",
                                            Value: database.Spec.Type,
                                        },
                                        {
                                            Name:  "DATABASE_HOST",
                                            Value: database.Name,
                                        },
                                        {
                                            Name:  "BACKUP_RETENTION",
                                            Value: database.Spec.Backup.Retention,
                                        },
                                    },
                                    VolumeMounts: []corev1.VolumeMount{
                                        {
                                            Name:      "backup-storage",
                                            MountPath: "/backup",
                                        },
                                    },
                                },
                            },
                            Volumes: []corev1.Volume{
                                {
                                    Name: "backup-storage",
                                    VolumeSource: corev1.VolumeSource{
                                        PersistentVolumeClaim: &corev1.PersistentVolumeClaimVolumeSource{
                                            ClaimName: database.Name + "-backup-pvc",
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
    
    // OwnerReference 설정
    if err := ctrl.SetControllerReference(database, &cronJob, r.Scheme); err != nil {
        log.Log.Error(err, "Failed to set controller reference for CronJob")
    }
    
    return cronJob
}

// getBackupScript는 데이터베이스 타입별 백업 스크립트를 반환합니다
func (r *DatabaseReconciler) getBackupScript(database *databasev1.Database) string {
    switch database.Spec.Type {
    case "mysql":
        return `#!/bin/bash
set -e

BACKUP_FILE="/backup/mysql-${DATABASE_NAME}-$(date +%Y%m%d_%H%M%S).sql"
mysqldump -h ${DATABASE_HOST} -u root -p${MYSQL_ROOT_PASSWORD} ${DATABASE_NAME} > ${BACKUP_FILE}

# 압축
gzip ${BACKUP_FILE}

# 오래된 백업 삭제
find /backup -name "mysql-${DATABASE_NAME}-*.sql.gz" -mtime +${BACKUP_RETENTION} -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
`
    case "postgresql":
        return `#!/bin/bash
set -e

BACKUP_FILE="/backup/postgresql-${DATABASE_NAME}-$(date +%Y%m%d_%H%M%S).dump"
pg_dump -h ${DATABASE_HOST} -U ${POSTGRES_USER} ${DATABASE_NAME} > ${BACKUP_FILE}

# 압축
gzip ${BACKUP_FILE}

# 오래된 백업 삭제
find /backup -name "postgresql-${DATABASE_NAME}-*.dump.gz" -mtime +${BACKUP_RETENTION} -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
`
    default:
        return `echo "Unsupported database type: ${DATABASE_TYPE}"`
    }
}

// getBackupImage는 백업에 사용할 이미지를 반환합니다
func (r *DatabaseReconciler) getBackupImage(database *databasev1.Database) string {
    switch database.Spec.Type {
    case "mysql":
        return "mysql:8.0"
    case "postgresql":
        return "postgres:14"
    default:
        return "mysql:8.0"
    }
}

// backupCronJobNeedsUpdate는 백업 CronJob 업데이트가 필요한지 확인합니다
func (r *DatabaseReconciler) backupCronJobNeedsUpdate(cronJob *batchv1.CronJob, database *databasev1.Database) bool {
    // 스케줄 변경 확인
    if cronJob.Spec.Schedule != database.Spec.Backup.Schedule {
        return true
    }
    
    return false
}
```

### 4.5 상태 업데이트 함수

```go
// updateStatus는 Database의 상태를 업데이트합니다
func (r *DatabaseReconciler) updateStatus(ctx context.Context, database *databasev1.Database) error {
    logger := log.FromContext(ctx)
    
    // StatefulSet 상태 확인
    var statefulSet appsv1.StatefulSet
    err := r.Get(ctx, types.NamespacedName{
        Name:      database.Name,
        Namespace: database.Namespace,
    }, &statefulSet)
    
    if err != nil {
        if errors.IsNotFound(err) {
            // StatefulSet이 없으면 Pending 상태
            database.Status.Phase = "Pending"
            database.Status.Ready = false
            database.Status.Replicas = 0
        } else {
            return fmt.Errorf("failed to get StatefulSet: %w", err)
        }
    } else {
        // StatefulSet 상태에 따라 Database 상태 설정
        if statefulSet.Status.ReadyReplicas == database.Spec.Replicas {
            database.Status.Phase = "Ready"
            database.Status.Ready = true
        } else if statefulSet.Status.ReadyReplicas > 0 {
            database.Status.Phase = "PartiallyReady"
            database.Status.Ready = false
        } else {
            database.Status.Phase = "Creating"
            database.Status.Ready = false
        }
        
        database.Status.Replicas = statefulSet.Status.ReadyReplicas
    }
    
    // 백업 상태 확인
    if database.Spec.Backup != nil && database.Spec.Backup.Enabled {
        if err := r.updateBackupStatus(ctx, database); err != nil {
            logger.Error(err, "Failed to update backup status")
        }
    }
    
    // 조건 업데이트
    r.updateConditions(database)
    
    // 상태 업데이트
    if err := r.Status().Update(ctx, database); err != nil {
        return fmt.Errorf("failed to update Database status: %w", err)
    }
    
    logger.Info("Updated Database status", "phase", database.Status.Phase, "ready", database.Status.Ready)
    return nil
}

// updateBackupStatus는 백업 상태를 업데이트합니다
func (r *DatabaseReconciler) updateBackupStatus(ctx context.Context, database *databasev1.Database) error {
    // 최근 백업 시간 확인 (실제 구현에서는 백업 로그나 파일 시스템에서 확인)
    // 여기서는 간단히 현재 시간으로 설정
    database.Status.LastBackup = time.Now().Format(time.RFC3339)
    return nil
}

// updateConditions는 Database의 조건을 업데이트합니다
func (r *DatabaseReconciler) updateConditions(database *databasev1.Database) {
    now := metav1.Now()
    
    // Ready 조건
    readyCondition := metav1.Condition{
        Type:               "Ready",
        Status:             metav1.ConditionFalse,
        LastTransitionTime: now,
        Reason:             "NotReady",
        Message:            "Database is not ready",
    }
    
    if database.Status.Ready {
        readyCondition.Status = metav1.ConditionTrue
        readyCondition.Reason = "Ready"
        readyCondition.Message = "Database is ready"
    }
    
    // Phase에 따른 조건 설정
    switch database.Status.Phase {
    case "Ready":
        readyCondition.Status = metav1.ConditionTrue
        readyCondition.Reason = "Ready"
        readyCondition.Message = "Database is ready"
    case "PartiallyReady":
        readyCondition.Status = metav1.ConditionFalse
        readyCondition.Reason = "PartiallyReady"
        readyCondition.Message = "Database is partially ready"
    case "Creating":
        readyCondition.Status = metav1.ConditionFalse
        readyCondition.Reason = "Creating"
        readyCondition.Message = "Database is being created"
    case "Pending":
        readyCondition.Status = metav1.ConditionFalse
        readyCondition.Reason = "Pending"
        readyCondition.Message = "Database is pending"
    }
    
    // 조건 업데이트
    metav1.SetMetaDataAnnotation(&database.ObjectMeta, "database.example.com/conditions", readyCondition.Type)
    
    // 기존 조건 찾기 및 업데이트
    conditionIndex := -1
    for i, condition := range database.Status.Conditions {
        if condition.Type == readyCondition.Type {
            conditionIndex = i
            break
        }
    }
    
    if conditionIndex >= 0 {
        database.Status.Conditions[conditionIndex] = readyCondition
    } else {
        database.Status.Conditions = append(database.Status.Conditions, readyCondition)
    }
}
```

## 5단계: Webhook 구현

### 🎬 시나리오: Webhook 설계 및 구현 계획

#### 상황
TechCorp의 개발팀이 Controller 구현을 완료한 후, 이제 Webhook을 구현해야 합니다.

**개발팀 (김개발)**
> "Controller는 완성되었습니다. 이제 Database 리소스가 생성/수정될 때 검증과 기본값 설정을 위한 Webhook을 구현해야 합니다."

**보안팀 (이보안)**
> "잘못된 설정으로 인한 보안 문제를 방지하기 위해 Validating Webhook이 필요합니다. 예를 들어, 프로덕션 환경에서 복제본 수가 1개인 경우를 차단해야 합니다."

**운영팀 (최운영)**
> "개발자가 모든 필드를 명시하지 않아도 되도록 Mutating Webhook으로 기본값을 설정해야 합니다. 환경별로 적절한 리소스 할당도 자동으로 설정되어야 합니다."

#### 요구사항 도출 과정

##### 1단계: Mutating Webhook 요구사항

**개발팀 (김개발)**
> "개발자가 Database 리소스를 생성할 때 필수 필드만 입력하고, 나머지는 자동으로 기본값이 설정되도록 해야 합니다."

**인프라팀 (박인프라)**
> "환경별로 다른 리소스 할당이 자동으로 적용되어야 합니다. development는 작은 리소스, production은 큰 리소스가 자동으로 설정되어야 합니다."

##### 2단계: Validating Webhook 요구사항

**보안팀 (이보안)**
> "비즈니스 규칙을 검증해야 합니다. 프로덕션 환경에서는 최소 2개 복제본이 필요하고, 리소스 제한도 필수입니다."

**운영팀 (최운영)**
> "백업이 활성화된 경우 스케줄과 보관 기간이 설정되어야 합니다. 잘못된 설정은 사전에 차단해야 합니다."

### 5.1 Mutating Webhook (기본값 설정)

### 📋 요구사항

#### 5.1 Mutating Webhook 요구사항
- **Default 함수**: Database 리소스 생성/업데이트 시 기본값 설정
- **기본값 설정 함수들**:
  - `setBasicDefaults`: 기본 기본값 (replicas, environment, storage class)
  - `setEnvironmentDefaults`: 환경별 리소스 기본값
  - `setBackupDefaults`: 백업 기본값 (schedule, retention)
  - `setMonitoringDefaults`: 모니터링 기본값

#### 5.2 기본값 설정 규칙
- **replicas**: 0인 경우 1로 설정
- **environment**: 빈 문자열인 경우 "development"로 설정
- **storage.class**: 빈 문자열인 경우 "standard"로 설정
- **backup**: nil인 경우 기본 백업 설정 생성
- **monitoring**: nil인 경우 기본 모니터링 설정 생성

#### 5.3 환경별 리소스 기본값
- **Development**: CPU 100m-500m, Memory 256Mi-512Mi
- **Staging**: CPU 200m-1000m, Memory 512Mi-1Gi
- **Production**: CPU 500m-2000m, Memory 1Gi-4Gi

### 🎯 실습: 직접 구현해보세요!

요구사항을 보고 Mutating Webhook 함수들을 직접 작성해보세요.

<details>
<summary>💡 힌트</summary>

- `webhook.Defaulter` 인터페이스 구현
- `kubebuilder:webhook` 마커로 webhook 설정
- `logf.Log.WithName()`으로 로깅 설정
- `resource.MustParse()`로 리소스 파싱

</details>

### 📝 솔루션: Mutating Webhook

<details>
<summary>🔍 솔루션 보기</summary>

`api/v1/database_webhook.go` 파일을 수정합니다:

```go
package v1

import (
    "context"
    "fmt"
    "strings"

    "k8s.io/apimachinery/pkg/runtime"
    ctrl "sigs.k8s.io/controller-runtime"
    logf "sigs.k8s.io/controller-runtime/pkg/log"
    "sigs.k8s.io/controller-runtime/pkg/webhook"
    "sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

// log는 webhook을 위한 logger입니다
var databaselog = logf.Log.WithName("database-resource")

// SetupWebhookWithManager는 webhook을 설정합니다
func (r *Database) SetupWebhookWithManager(mgr ctrl.Manager) error {
    return ctrl.NewWebhookManagedBy(mgr).
        For(r).
        Complete()
}

//+kubebuilder:webhook:path=/mutate-database-example-com-v1-database,mutating=true,failurePolicy=fail,sideEffects=None,groups=database.example.com,resources=databases,verbs=create;update,versions=v1,name=mdatabase.kb.io,admissionReviewVersions=v1

var _ webhook.Defaulter = &Database{}

// Default는 Database의 기본값을 설정합니다
func (r *Database) Default() {
    databaselog.Info("default", "name", r.Name)

    // 기본값 설정
    r.setBasicDefaults()
    
    // 환경별 기본값 설정
    r.setEnvironmentDefaults()
    
    // 백업 기본값 설정
    r.setBackupDefaults()
    
    // 모니터링 기본값 설정
    r.setMonitoringDefaults()
}

// setBasicDefaults는 기본 기본값을 설정합니다
func (r *Database) setBasicDefaults() {
    // 복제본 수 기본값
    if r.Spec.Replicas == 0 {
        r.Spec.Replicas = 1
    }
    
    // 환경 기본값
    if r.Spec.Environment == "" {
        r.Spec.Environment = "development"
    }
    
    // 스토리지 클래스 기본값
    if r.Spec.Storage.Class == "" {
        r.Spec.Storage.Class = "standard"
    }
}

// setEnvironmentDefaults는 환경별 기본값을 설정합니다
func (r *Database) setEnvironmentDefaults() {
    // 환경별 리소스 기본값 설정
    if r.Spec.Resources == nil {
        switch r.Spec.Environment {
        case "development":
            r.Spec.Resources = &corev1.ResourceRequirements{
                Requests: corev1.ResourceList{
                    corev1.ResourceCPU:    resource.MustParse("100m"),
                    corev1.ResourceMemory: resource.MustParse("256Mi"),
                },
                Limits: corev1.ResourceList{
                    corev1.ResourceCPU:    resource.MustParse("500m"),
                    corev1.ResourceMemory: resource.MustParse("512Mi"),
                },
            }
        case "staging":
            r.Spec.Resources = &corev1.ResourceRequirements{
                Requests: corev1.ResourceList{
                    corev1.ResourceCPU:    resource.MustParse("200m"),
                    corev1.ResourceMemory: resource.MustParse("512Mi"),
                },
                Limits: corev1.ResourceList{
                    corev1.ResourceCPU:    resource.MustParse("1000m"),
                    corev1.ResourceMemory: resource.MustParse("1Gi"),
                },
            }
        case "production":
            r.Spec.Resources = &corev1.ResourceRequirements{
                Requests: corev1.ResourceList{
                    corev1.ResourceCPU:    resource.MustParse("500m"),
                    corev1.ResourceMemory: resource.MustParse("1Gi"),
                },
                Limits: corev1.ResourceList{
                    corev1.ResourceCPU:    resource.MustParse("2000m"),
                    corev1.ResourceMemory: resource.MustParse("4Gi"),
                },
            }
        }
    }
}

// setBackupDefaults는 백업 기본값을 설정합니다
func (r *Database) setBackupDefaults() {
    if r.Spec.Backup == nil {
        r.Spec.Backup = &DatabaseBackup{
            Enabled:   false,
            Schedule:  "0 2 * * *", // 매일 새벽 2시
            Retention: "7d",
        }
    } else {
        if r.Spec.Backup.Schedule == "" {
            r.Spec.Backup.Schedule = "0 2 * * *"
        }
        if r.Spec.Backup.Retention == "" {
            r.Spec.Backup.Retention = "7d"
        }
    }
}

// setMonitoringDefaults는 모니터링 기본값을 설정합니다
func (r *Database) setMonitoringDefaults() {
    if r.Spec.Monitoring == nil {
        r.Spec.Monitoring = &DatabaseMonitoring{
            Enabled: false,
            Metrics: false,
            Logging: false,
        }
    }
}
```

### 5.2 Validating Webhook (검증)

### 📋 요구사항

#### 5.2 Validating Webhook 요구사항
- **ValidateCreate 함수**: Database 생성 시 검증
- **ValidateUpdate 함수**: Database 수정 시 검증
- **ValidateDelete 함수**: Database 삭제 시 검증
- **검증 함수들**:
  - `validateDatabase`: 전체 검증 로직
  - `validateBasicFields`: 기본 필드 검증
  - `validateBusinessRules`: 비즈니스 규칙 검증
  - `validateBackupConfig`: 백업 설정 검증

#### 5.3 기본 필드 검증 규칙
- **type**: 필수, mysql 또는 postgresql만 허용
- **version**: 필수, 빈 문자열 불가
- **replicas**: 1-10 범위
- **storage.size**: 필수, 빈 문자열 불가
- **environment**: development, staging, production만 허용

#### 5.4 비즈니스 규칙 검증
- **프로덕션 환경**: 최소 2개 복제본 필요
- **프로덕션 환경**: 리소스 제한 필수
- **백업 활성화**: 스케줄과 보관 기간 필수

### 🎯 실습: 직접 구현해보세요!

요구사항을 보고 Validating Webhook 함수들을 직접 작성해보세요.

<details>
<summary>💡 힌트</summary>

- `webhook.Validator` 인터페이스 구현
- `admission.Warnings`와 `error` 반환
- `fmt.Errorf()`로 에러 메시지 생성
- `strings.Join()`으로 에러 메시지 조합

</details>

### 📝 솔루션: Validating Webhook

<details>
<summary>🔍 솔루션 보기</summary>

```go
//+kubebuilder:webhook:path=/validate-database-example-com-v1-database,mutating=false,failurePolicy=fail,sideEffects=None,groups=database.example.com,resources=databases,verbs=create;update,versions=v1,name=vdatabase.kb.io,admissionReviewVersions=v1

var _ webhook.Validator = &Database{}

// ValidateCreate는 Database 생성 시 검증합니다
func (r *Database) ValidateCreate() (admission.Warnings, error) {
    databaselog.Info("validate create", "name", r.Name)
    return nil, r.validateDatabase()
}

// ValidateUpdate는 Database 수정 시 검증합니다
func (r *Database) ValidateUpdate(old runtime.Object) (admission.Warnings, error) {
    databaselog.Info("validate update", "name", r.Name)
    return nil, r.validateDatabase()
}

// ValidateDelete는 Database 삭제 시 검증합니다
func (r *Database) ValidateDelete() (admission.Warnings, error) {
    databaselog.Info("validate delete", "name", r.Name)
    return nil, nil
}

// validateDatabase는 Database의 유효성을 검증합니다
func (r *Database) validateDatabase() error {
    // 기본 필드 검증
    if err := r.validateBasicFields(); err != nil {
        return err
    }
    
    // 비즈니스 규칙 검증
    if err := r.validateBusinessRules(); err != nil {
        return err
    }
    
    // 백업 설정 검증
    if err := r.validateBackupConfig(); err != nil {
        return err
    }
    
    return nil
}

// validateBasicFields는 기본 필드를 검증합니다
func (r *Database) validateBasicFields() error {
    // 데이터베이스 타입 검증
    if r.Spec.Type == "" {
        return fmt.Errorf("database type is required")
    }
    
    if r.Spec.Type != "mysql" && r.Spec.Type != "postgresql" {
        return fmt.Errorf("unsupported database type: %s. Supported types: mysql, postgresql", r.Spec.Type)
    }
    
    // 버전 검증
    if r.Spec.Version == "" {
        return fmt.Errorf("database version is required")
    }
    
    // 복제본 수 검증
    if r.Spec.Replicas < 1 {
        return fmt.Errorf("replicas must be at least 1")
    }
    
    if r.Spec.Replicas > 10 {
        return fmt.Errorf("replicas cannot exceed 10")
    }
    
    // 스토리지 크기 검증
    if r.Spec.Storage.Size == "" {
        return fmt.Errorf("storage size is required")
    }
    
    // 환경 검증
    if r.Spec.Environment != "" {
        validEnvironments := []string{"development", "staging", "production"}
        if !contains(validEnvironments, r.Spec.Environment) {
            return fmt.Errorf("invalid environment: %s. Valid environments: %s", 
                r.Spec.Environment, strings.Join(validEnvironments, ", "))
        }
    }
    
    return nil
}

// validateBusinessRules는 비즈니스 규칙을 검증합니다
func (r *Database) validateBusinessRules() error {
    // 프로덕션 환경에서는 복제본 수 제한
    if r.Spec.Environment == "production" && r.Spec.Replicas < 2 {
        return fmt.Errorf("production environment requires at least 2 replicas")
    }
    
    // 프로덕션 환경에서는 리소스 제한 필수
    if r.Spec.Environment == "production" {
        if r.Spec.Resources == nil || r.Spec.Resources.Limits == nil {
            return fmt.Errorf("production environment requires resource limits")
        }
    }
    
    return nil
}

// validateBackupConfig는 백업 설정을 검증합니다
func (r *Database) validateBackupConfig() error {
    if r.Spec.Backup != nil && r.Spec.Backup.Enabled {
        // 백업 스케줄 검증 (간단한 cron 형식 검증)
        if r.Spec.Backup.Schedule == "" {
            return fmt.Errorf("backup schedule is required when backup is enabled")
        }
        
        // 백업 보관 기간 검증
        if r.Spec.Backup.Retention == "" {
            return fmt.Errorf("backup retention is required when backup is enabled")
        }
    }
    
    return nil
}

// contains는 슬라이스에 특정 값이 포함되어 있는지 확인합니다
func contains(slice []string, item string) bool {
    for _, s := range slice {
        if s == item {
            return true
        }
    }
    return false
}
```

## 6단계: 테스트 및 배포

### 🎬 시나리오: Database Operator 테스트 및 배포 계획

#### 상황
TechCorp의 개발팀이 Database Operator의 모든 기능을 구현 완료한 후, 이제 테스트 및 배포를 진행해야 합니다.

**개발팀 (김개발)**
> "Database Operator의 모든 기능이 구현되었습니다. 이제 실제 환경에서 테스트하고 배포해야 합니다."

**QA팀 (박QA)**
> "기능 테스트와 통합 테스트를 진행해야 합니다. 기본 기능부터 고급 기능까지 모든 시나리오를 테스트해야 합니다."

**운영팀 (최운영)**
> "프로덕션 환경에 배포하기 전에 충분한 테스트가 필요합니다. 성능 테스트와 부하 테스트도 진행해야 합니다."

#### 요구사항 도출 과정

##### 1단계: 배포 전략

**인프라팀 (박인프라)**
> "단계별 배포 전략이 필요합니다. 먼저 개발 환경에서 테스트하고, 스테이징 환경에서 검증한 후 프로덕션에 배포해야 합니다."

**개발팀 (김개발)**
> "CRD 설치, Controller 배포, Webhook 활성화 순서로 진행해야 합니다. 각 단계별로 검증이 필요합니다."

##### 2단계: 테스트 시나리오

**QA팀 (박QA)**
> "기본 기능 테스트부터 시작해서 고급 기능까지 단계적으로 테스트해야 합니다. 백업, 스케일링, 모니터링 기능도 검증해야 합니다."

**보안팀 (이보안)**
> "보안 테스트도 필요합니다. 잘못된 설정으로 검증이 실패하는지, 권한이 올바르게 설정되었는지 확인해야 합니다."

##### 3단계: 모니터링 및 운영

**운영팀 (최운영)**
> "배포 후 모니터링이 중요합니다. Controller 로그, Database 상태, 리소스 사용량 등을 지속적으로 모니터링해야 합니다."

### 📋 요구사항

#### 6.1 배포 요구사항
- **매니페스트 생성**: kubebuilder 마커로부터 CRD, RBAC, Webhook 매니페스트 생성
- **CRD 설치**: Database CRD를 Kubernetes 클러스터에 설치
- **컨트롤러 배포**: Database Controller를 클러스터에 배포
- **Webhook 활성화**: Mutating/Validating Webhook 활성화

#### 6.2 기본 테스트 요구사항
- **Database 생성**: 개발 환경 MySQL Database 생성
- **리소스 확인**: StatefulSet, Service, ConfigMap 생성 확인
- **상태 확인**: Database 리소스의 상태 필드 확인
- **Pod 확인**: 데이터베이스 Pod 실행 상태 확인

#### 6.3 고급 기능 테스트 요구사항
- **백업 테스트**: 백업 활성화 및 CronJob 생성 확인
- **스케일링 테스트**: 복제본 수 변경 및 StatefulSet 업데이트 확인
- **모니터링 테스트**: 모니터링 활성화 및 관련 리소스 생성 확인
- **Webhook 테스트**: 잘못된 설정으로 검증 실패 확인

### 🎯 실습: 직접 테스트해보세요!

요구사항을 보고 Database Operator를 배포하고 테스트해보세요.

<details>
<summary>💡 힌트</summary>

- `make manifests`로 매니페스트 생성
- `make install`로 CRD 설치
- `make deploy`로 컨트롤러 배포
- `kubectl get database`로 리소스 확인
- `kubectl patch`로 설정 변경 테스트

</details>

### 📝 솔루션: 테스트 및 배포

<details>
<summary>🔍 솔루션 보기</summary>

#### 6.1 매니페스트 생성 및 배포

```bash
# 매니페스트 생성
make manifests

# CRD 설치
make install

# 컨트롤러 배포
make deploy
```

#### 6.2 기본 테스트

```bash
# 개발 환경 Database 생성
kubectl apply -f - <<EOF
apiVersion: database.example.com/v1
kind: Database
metadata:
  name: test-db
  namespace: default
spec:
  type: mysql
  version: "8.0"
  replicas: 1
  storage:
    size: 10Gi
    class: standard
  environment: development
EOF

# Database 상태 확인
kubectl get database test-db -o yaml

# 생성된 리소스 확인
kubectl get statefulset,service,configmap
```

#### 6.3 고급 기능 테스트

```bash
# 백업 활성화
kubectl patch database test-db --type='merge' -p='{"spec":{"backup":{"enabled":true,"schedule":"0 2 * * *","retention":"7d"}}}'

# 스케일링
kubectl patch database test-db --type='merge' -p='{"spec":{"replicas":3}}'

# 모니터링 활성화
kubectl patch database test-db --type='merge' -p='{"spec":{"monitoring":{"enabled":true,"metrics":true,"logging":true}}}'

# 백업 CronJob 확인
kubectl get cronjob
```

</details>

## 7단계: 고급 기능 구현

### 📋 요구사항

#### 7.1 자동 스케일링 요구사항
- **HorizontalPodAutoscaler**: CPU/메모리 사용률 기반 자동 스케일링
- **스케일링 정책**: 최소/최대 복제본 수 설정
- **메트릭 설정**: CPU/메모리 임계값 설정
- **스케일링 동작**: 증가/감소 속도 제한

#### 7.2 모니터링 통합 요구사항
- **ServiceMonitor**: Prometheus 메트릭 수집
- **Grafana Dashboard**: 데이터베이스 모니터링 대시보드
- **AlertManager**: 임계값 기반 알림 설정
- **로그 수집**: ELK 스택 연동

#### 7.3 보안 강화 요구사항
- **RBAC**: 세밀한 권한 관리
- **NetworkPolicy**: 네트워크 격리
- **PodSecurityPolicy**: 보안 컨텍스트 설정
- **암호화**: 데이터 암호화 및 TLS

### 🎯 실습: 직접 구현해보세요!

요구사항을 보고 고급 기능들을 직접 구현해보세요.

<details>
<summary>💡 힌트</summary>

- `autoscalingv2.HorizontalPodAutoscaler`로 HPA 생성
- `monitoringv1.ServiceMonitor`로 메트릭 수집 설정
- `networkingv1.NetworkPolicy`로 네트워크 정책 설정
- `corev1.SecurityContext`로 보안 컨텍스트 설정

</details>

### 📝 솔루션: 고급 기능 구현

<details>
<summary>🔍 솔루션 보기</summary>

#### 7.1 자동 스케일링

```go
// HorizontalPodAutoscaler 생성 함수 추가
func (r *DatabaseReconciler) reconcileHPA(ctx context.Context, database *databasev1.Database) error {
    if database.Spec.AutoScaling == nil || !database.Spec.AutoScaling.Enabled {
        return nil
    }
    
    // HPA 생성 로직
    // ...
}
```

#### 7.2 모니터링 통합

```go
// ServiceMonitor 생성 함수 추가
func (r *DatabaseReconciler) reconcileServiceMonitor(ctx context.Context, database *databasev1.Database) error {
    if database.Spec.Monitoring == nil || !database.Spec.Monitoring.Metrics {
        return nil
    }
    
    // ServiceMonitor 생성 로직
    // ...
}
```

</details>

## 완료!

Database Operator 프로젝트가 완성되었습니다! 🎉

### 구현된 기능
- ✅ **CRD 정의**: Database 리소스 스키마
- ✅ **Controller**: StatefulSet, Service, ConfigMap, CronJob 관리
- ✅ **Webhook**: 검증 및 기본값 설정
- ✅ **백업**: 자동 백업 스케줄링
- ✅ **모니터링**: 메트릭 및 로그 수집
- ✅ **환경별 설정**: dev/staging/prod 다른 설정

### 🎯 요구사항 기반 학습의 장점

#### 1. 실무 경험 시뮬레이션
- **요구사항 분석**: 실제 프로젝트에서 요구사항을 분석하는 경험
- **설계 사고**: 요구사항을 바탕으로 아키텍처를 설계하는 능력
- **구현 계획**: 단계별로 구현 계획을 세우는 능력

#### 2. 문제 해결 능력 향상
- **직접 구현**: 요구사항을 보고 직접 코드를 작성하는 경험
- **솔루션 비교**: 자신의 코드와 베스트 프랙티스 비교
- **개선점 도출**: 차이점을 분석하고 개선점을 찾는 능력

#### 3. 실무 적용 가능성
- **완전한 프로젝트**: 실제 사용 가능한 수준의 Operator
- **확장 가능성**: 추가 기능 구현이 쉬운 구조
- **운영 고려사항**: 백업, 모니터링, 상태 관리 포함

### 📚 학습 성과

#### 기술적 성과
- **CRD/Operator 개발**: 완전한 Operator 개발 경험
- **Kubernetes 심화**: StatefulSet, Service, ConfigMap, CronJob 활용
- **Go 프로그래밍**: 고급 Go 패턴 및 에러 처리
- **Webhook 구현**: 검증 및 기본값 설정

#### 실무적 성과
- **요구사항 분석**: 비즈니스 요구사항을 기술적 솔루션으로 변환
- **아키텍처 설계**: 확장 가능하고 유지보수 가능한 구조 설계
- **문제 해결**: 복잡한 문제를 단계별로 해결하는 능력

### 다음 단계
1. **실제 데이터베이스 연결 테스트**
2. **성능 최적화**
3. **보안 강화**
4. **CI/CD 파이프라인 구축**

이제 실무에서 사용할 수 있는 수준의 Database Operator가 완성되었습니다! 🚀

### 💡 추가 학습 권장사항

#### 1. 고급 Operator 패턴
- **Finalizer**: 리소스 정리 로직
- **Event**: Kubernetes 이벤트 생성
- **Metrics**: 커스텀 메트릭 노출

#### 2. 운영 최적화
- **성능 튜닝**: 대용량 환경에서의 최적화
- **모니터링**: Prometheus, Grafana 연동
- **로깅**: 구조화된 로깅 및 분석

#### 3. 보안 강화
- **RBAC**: 세밀한 권한 관리
- **NetworkPolicy**: 네트워크 격리
- **암호화**: 데이터 암호화 및 TLS

이제 CRD/Operator 개발의 모든 단계를 경험했으니, 실무에서 자신 있게 활용할 수 있습니다! 🎯
