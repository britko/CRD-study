# 웹훅 성능 최적화

## 개요

이 문서는 Kubernetes 웹훅의 성능을 극대화하고 운영 환경에서의 안정성을 보장하기 위한 고급 최적화 기법들을 다룹니다.

**목표**: 웹훅의 성능을 극대화하고 운영 환경에서의 안정성을 보장

## 목차

- [1. 웹훅 필터링 최적화](#1-웹훅-필터링-최적화)
- [2. 고급 캐싱 전략](#2-고급-캐싱-전략)
- [3. 비동기 처리 최적화](#3-비동기-처리-최적화)
- [4. 메모리 최적화](#4-메모리-최적화)
- [5. 성능 모니터링 및 메트릭](#5-성능-모니터링-및-메트릭)
- [6. 성능 최적화 체크리스트](#6-성능-최적화-체크리스트)

## 1. 웹훅 필터링 최적화

### 1-1. 네임스페이스 기반 필터링

```go
// 네임스페이스 기반 필터링: 중요한 환경에서만 엄격한 검증 수행
func (v *WebsiteCustomValidator) ValidateCreate(_ context.Context, obj runtime.Object) (admission.Warnings, error) {
    website, ok := obj.(*mygroupv1.Website)
    if !ok {
        return nil, fmt.Errorf("expected an Website object but got %T", obj)
    }
    
    // 개발 환경에서는 검증 생략 (성능 최적화)
    if website.Namespace != "production" && website.Namespace != "staging" {
        return nil, nil
    }
    
    // 중요한 환경에서만 전체 검증 수행
    return nil, v.validateWebsite(website)
}
```

**📝 설명**:
- **성능 최적화**: 개발 환경에서는 검증을 생략하여 웹훅 응답 시간 단축
- **환경별 차등 적용**: 프로덕션/스테이징 환경에서만 엄격한 검증 수행
- **리소스 절약**: 불필요한 검증 로직 실행을 방지하여 CPU/메모리 사용량 감소

### 1-2. 라벨 기반 필터링

```go
// 라벨 기반 필터링: 특정 라벨이 있는 리소스만 검증
func (v *WebsiteCustomValidator) ValidateCreate(_ context.Context, obj runtime.Object) (admission.Warnings, error) {
    website, ok := obj.(*mygroupv1.Website)
    if !ok {
        return nil, fmt.Errorf("expected an Website object but got %T", obj)
    }
    
    // 특정 라벨이 있는 리소스만 검증
    if website.Labels["webhook-validation"] != "enabled" {
        return nil, nil
    }
    
    return nil, v.validateWebsite(website)
}
```

**📝 설명**:
- **선택적 검증**: `webhook-validation: enabled` 라벨이 있는 리소스만 검증
- **유연성**: 사용자가 검증이 필요한 리소스만 선택적으로 지정 가능
- **성능 향상**: 대부분의 리소스에서 검증을 생략하여 전체 성능 향상

## 2. 고급 캐싱 전략

### 2-1. 다층 캐싱 시스템

```go
// 다층 캐싱 시스템: L1(메모리) + L2(Redis) + L3(데이터베이스)
type CacheManager struct {
    // L1 캐시: 메모리 캐시 (가장 빠름)
    memoryCache map[string]CacheEntry
    memoryMutex sync.RWMutex
    
    // L2 캐시: Redis 캐시 (중간 속도)
    redisClient *redis.Client
    
    // L3 캐시: 데이터베이스 캐시 (가장 느리지만 영구 저장)
    dbClient *sql.DB
}

type CacheEntry struct {
    Value     interface{}
    ExpiresAt time.Time
    HitCount  int64
}

// 캐시 조회 (L1 → L2 → L3 순서로 조회)
func (cm *CacheManager) Get(key string) (interface{}, bool) {
    // L1 캐시 조회
    cm.memoryMutex.RLock()
    if entry, exists := cm.memoryCache[key]; exists {
        if time.Now().Before(entry.ExpiresAt) {
            cm.memoryMutex.RUnlock()
            cm.updateHitCount(key)
            return entry.Value, true
        }
    }
    cm.memoryMutex.RUnlock()
    
    // L2 캐시 조회
    if value, err := cm.redisClient.Get(context.Background(), key).Result(); err == nil {
        cm.setMemoryCache(key, value, 5*time.Minute)
        return value, true
    }
    
    // L3 캐시 조회
    if value, err := cm.getFromDatabase(key); err == nil {
        cm.setMemoryCache(key, value, 5*time.Minute)
        cm.setRedisCache(key, value, 30*time.Minute)
        return value, true
    }
    
    return nil, false
}
```

**📝 설명**:
- **다층 캐싱**: L1(메모리) → L2(Redis) → L3(DB) 순서로 캐시 조회
- **성능 최적화**: 가장 빠른 캐시부터 조회하여 응답 시간 최소화
- **캐시 계층화**: 각 계층별로 적절한 TTL과 용량 설정

### 2-2. 지능형 캐시 무효화

```go
// 지능형 캐시 무효화: TTL + LRU + 사용 빈도 기반
type IntelligentCache struct {
    cache      map[string]CacheEntry
    mutex      sync.RWMutex
    maxSize    int
    hitCounts  map[string]int64
    lastAccess map[string]time.Time
}

func (ic *IntelligentCache) Set(key string, value interface{}, ttl time.Duration) {
    ic.mutex.Lock()
    defer ic.mutex.Unlock()
    
    // 캐시 크기 제한 확인
    if len(ic.cache) >= ic.maxSize {
        ic.evictLeastUsed()
    }
    
    ic.cache[key] = CacheEntry{
        Value:     value,
        ExpiresAt: time.Now().Add(ttl),
    }
    ic.hitCounts[key] = 0
    ic.lastAccess[key] = time.Now()
}

// LRU + 사용 빈도 기반 캐시 제거
func (ic *IntelligentCache) evictLeastUsed() {
    var oldestKey string
    var oldestScore float64 = math.MaxFloat64
    
    for key := range ic.cache {
        // 점수 계산: (마지막 접근 시간 + 사용 빈도) 기반
        lastAccess := ic.lastAccess[key]
        hitCount := ic.hitCounts[key]
        
        // 시간이 지날수록 점수가 낮아지고, 사용 빈도가 높을수록 점수가 높아짐
        score := float64(lastAccess.Unix()) + float64(hitCount)*1000
        
        if score < oldestScore {
            oldestScore = score
            oldestKey = key
        }
    }
    
    if oldestKey != "" {
        delete(ic.cache, oldestKey)
        delete(ic.hitCounts, oldestKey)
        delete(ic.lastAccess, oldestKey)
    }
}
```

**📝 설명**:
- **지능형 제거**: LRU(Least Recently Used) + 사용 빈도 기반 캐시 제거
- **점수 시스템**: 마지막 접근 시간과 사용 빈도를 종합한 점수로 제거 대상 결정
- **메모리 효율성**: 캐시 크기 제한으로 메모리 사용량 제어

## 3. 비동기 처리 최적화

### 3-1. 워커 풀 패턴

```go
// 워커 풀 패턴: 동시 처리 수 제한으로 성능 최적화
type WorkerPool struct {
    workers    int
    jobQueue   chan Job
    resultChan chan Result
    wg         sync.WaitGroup
}

type Job struct {
    ID       string
    Website  *mygroupv1.Website
    Callback func(*mygroupv1.Website) error
}

type Result struct {
    ID    string
    Error error
}

// 워커 풀 시작
func (wp *WorkerPool) Start() {
    for i := 0; i < wp.workers; i++ {
        wp.wg.Add(1)
        go wp.worker(i)
    }
}

// 워커 함수
func (wp *WorkerPool) worker(id int) {
    defer wp.wg.Done()
    
    for job := range wp.jobQueue {
        err := job.Callback(job.Website)
        wp.resultChan <- Result{
            ID:    job.ID,
            Error: err,
        }
    }
}

// 비동기 검증 처리
func (v *WebsiteCustomValidator) ValidateCreateAsync(ctx context.Context, obj runtime.Object) (admission.Warnings, error) {
    website, ok := obj.(*mygroupv1.Website)
    if !ok {
        return nil, fmt.Errorf("expected an Website object but got %T", obj)
    }
    
    // 즉시 응답 (비동기 검증)
    go func() {
        if err := v.validateWebsiteAsync(website); err != nil {
            // 검증 실패 시 리소스 상태 업데이트
            v.updateWebsiteStatus(website, "ValidationFailed", err.Error())
        }
    }()
    
    return nil, nil
}
```

**📝 설명**:
- **워커 풀**: 동시 처리 수를 제한하여 시스템 과부하 방지
- **비동기 처리**: 웹훅 응답 시간 단축을 위한 비동기 검증
- **상태 관리**: 검증 실패 시 리소스 상태를 업데이트하여 추후 처리

## 4. 메모리 최적화

### 4-1. 객체 풀링

```go
// 객체 풀링: 자주 생성/삭제되는 객체 재사용
type ObjectPool struct {
    pool sync.Pool
}

// Website 객체 풀
var websitePool = &ObjectPool{
    pool: sync.Pool{
        New: func() interface{} {
            return &mygroupv1.Website{}
        },
    },
}

// 객체 풀에서 Website 가져오기
func (op *ObjectPool) GetWebsite() *mygroupv1.Website {
    website := op.pool.Get().(*mygroupv1.Website)
    // 객체 초기화
    website.Reset()
    return website
}

// 객체 풀에 Website 반환
func (op *ObjectPool) PutWebsite(website *mygroupv1.Website) {
    op.pool.Put(website)
}

// Website 객체 초기화 메서드
func (w *Website) Reset() {
    w.Name = ""
    w.Namespace = ""
    w.Spec = WebsiteSpec{}
    w.Status = WebsiteStatus{}
    w.Labels = nil
    w.Annotations = nil
}
```

**📝 설명**:
- **객체 풀링**: 자주 생성/삭제되는 Website 객체를 재사용
- **메모리 절약**: GC 압박 감소 및 메모리 할당/해제 비용 절약
- **성능 향상**: 객체 생성 시간 단축

## 5. 성능 모니터링 및 메트릭

### 5-1. 성능 메트릭 수집

```go
// 성능 메트릭 수집
type PerformanceMetrics struct {
    RequestCount     int64
    ResponseTime     time.Duration
    ErrorCount       int64
    CacheHitRate     float64
    MemoryUsage      int64
    mutex            sync.RWMutex
}

// 메트릭 업데이트
func (pm *PerformanceMetrics) UpdateRequest(duration time.Duration, err error) {
    pm.mutex.Lock()
    defer pm.mutex.Unlock()
    
    pm.RequestCount++
    pm.ResponseTime = duration
    
    if err != nil {
        pm.ErrorCount++
    }
}

// 메트릭 조회
func (pm *PerformanceMetrics) GetMetrics() map[string]interface{} {
    pm.mutex.RLock()
    defer pm.mutex.RUnlock()
    
    return map[string]interface{}{
        "request_count":     pm.RequestCount,
        "response_time_ms":  pm.ResponseTime.Milliseconds(),
        "error_count":       pm.ErrorCount,
        "error_rate":        float64(pm.ErrorCount) / float64(pm.RequestCount),
        "cache_hit_rate":    pm.CacheHitRate,
        "memory_usage_mb":   pm.MemoryUsage / 1024 / 1024,
    }
}
```

**📝 설명**:
- **성능 메트릭**: 요청 수, 응답 시간, 에러율, 캐시 히트율 등 핵심 지표 수집
- **실시간 모니터링**: 성능 지표를 실시간으로 모니터링
- **데이터 기반 최적화**: 메트릭 데이터를 기반으로 성능 최적화 방향 결정

## 6. 성능 최적화 체크리스트

### 6-1. 구현 체크리스트

```bash
# 성능 최적화 구현 체크리스트
cat << 'EOF'
=== 웹훅 성능 최적화 체크리스트 ===

✅ 필터링 최적화:
  - 네임스페이스 기반 필터링 구현
  - 라벨 기반 필터링 구현
  - 리소스 크기 기반 필터링 구현

✅ 캐싱 최적화:
  - 다층 캐싱 시스템 구현
  - 지능형 캐시 무효화 구현
  - 분산 캐싱 구현

✅ 비동기 처리:
  - 워커 풀 패턴 구현
  - 배치 처리 구현
  - 비동기 검증 구현

✅ 메모리 최적화:
  - 객체 풀링 구현
  - 메모리 압축 구현
  - 가비지 컬렉션 최적화

✅ 모니터링:
  - 성능 메트릭 수집 구현
  - Prometheus 연동 구현
  - 자동 성능 튜닝 구현
EOF
```

### 6-2. 성능 벤치마크

```bash
# 성능 벤치마크 실행
echo "=== 웹훅 성능 벤치마크 ==="

# 1. 응답 시간 벤치마크
echo "1. 응답 시간 벤치마크:"
for i in {1..100}; do
  start_time=$(date +%s.%N)
  kubectl apply -f - <<EOF >/dev/null 2>&1
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: benchmark-website-$i
spec:
  url: "https://benchmark-$i.com"
  replicas: 1
  image: "nginx:latest"
  port: 80
EOF
  end_time=$(date +%s.%N)
  duration=$(echo "$end_time - $start_time" | bc)
  echo "요청 $i: ${duration}초"
done

# 2. 동시성 벤치마크
echo "2. 동시성 벤치마크:"
start_time=$(date +%s.%N)
for i in {1..50}; do
  kubectl apply -f - <<EOF >/dev/null 2>&1 &
apiVersion: mygroup.example.com/v1
kind: Website
metadata:
  name: concurrent-benchmark-$i
spec:
  url: "https://concurrent-$i.com"
  replicas: 1
  image: "nginx:latest"
  port: 80
EOF
done
wait
end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc)
echo "50개 동시 요청 처리 시간: ${duration}초"

# 3. 메모리 사용량 벤치마크
echo "3. 메모리 사용량 벤치마크:"
POD_NAME=$(kubectl get pods -n advanced-crd-project-system -o name | head -1)
kubectl top $POD_NAME -n advanced-crd-project-system --containers
```

**📝 설명**:
- **종합 벤치마크**: 응답 시간, 동시성, 메모리 사용량 등 종합 측정
- **성능 기준**: 각 벤치마크별 성능 기준 설정
- **지속적 모니터링**: 정기적인 벤치마크 실행으로 성능 추이 모니터링

## 성능 향상 효과

### 예상 성능 개선

- **응답 시간**: 50-80% 단축 (캐싱 + 비동기 처리)
- **동시 처리**: 3-5배 향상 (워커 풀 + 필터링)
- **메모리 사용량**: 30-50% 감소 (객체 풀링 + 지능형 캐시)
- **CPU 사용률**: 20-40% 감소 (필터링 + 캐싱)

### 운영 안정성

- **과부하 방지**: 워커 풀을 통한 동시 처리 수 제한
- **메모리 관리**: 지능형 캐시 무효화로 메모리 누수 방지
- **모니터링**: 실시간 성능 지표로 사전 문제 감지

## 다음 단계

웹훅 성능 최적화를 완료했습니다! 이제 CRD의 다른 고급 기능들을 구현해보겠습니다:

- [웹훅 구현](./06-webhooks.md) - 웹훅 기본 구현
- [검증 및 기본값 설정](./07-validation-defaulting.md) - 스키마 검증 및 기본값
- [CRD 버전 관리](./08-versioning.md) - CRD 버전 관리 및 마이그레이션
