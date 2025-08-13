# 4단계: 모니터링 시스템 배포 및 연동 구성

## 목표
MongoDB Sharded Cluster의 완전한 관찰성(Observability) 구현 - 메트릭 수집, 시각화, 알림 자동화

## 세부 작업 계획

### 4.1 MongoDB Exporter 배포 자동화
**담당자**: Monitoring Engineer  
**예상 소요 시간**: 6시간  
**산출물**:
- MongoDB Exporter 배포 플레이북
- 노드별 메트릭 수집 설정

**상세 작업**:
- [ ] `infra/docker/monitoring/mongodb-exporter/` 구성
  - `docker-compose.yml`: 각 MongoDB 노드별 Exporter
  - `exporter.yml`: MongoDB Exporter 설정 파일
  - 사용자 정의 메트릭 정의
- [ ] `deploy-mongodb-exporters.yml` 플레이북 작성
  - Config Server용 Exporter (포트 9216)
  - Shard Server용 Exporter (포트 9217)
  - Router용 Exporter (포트 9218)
  - 읽기전용 계정으로 MongoDB 연결
- [ ] Exporter 보안 설정
  - MongoDB 인증 정보 환경변수 관리
  - Exporter 전용 사용자 계정 생성
  - 네트워크 접근 제한 설정
- [ ] 사용자 정의 메트릭 개발
  - Replica Set 지연시간
  - 샤딩 균형 상태
  - 연결 풀 사용률

### 4.2 Node Exporter 및 시스템 메트릭 수집
**담당자**: Infrastructure Engineer  
**예상 소요 시간**: 4시간  
**산출물**:
- Node Exporter 배포 설정
- 시스템 메트릭 수집 규칙

**상세 작업**:
- [ ] `deploy-node-exporters.yml` 플레이북 작성
  - 모든 VM에 Node Exporter 설치 (포트 9100)
  - 시스템 메트릭 수집 설정
  - Docker 컨테이너 메트릭 연동
- [ ] 커스텀 메트릭 수집기 개발
  - 디스크 I/O 지연시간
  - 네트워크 대역폭 사용률
  - 메모리 사용 패턴 분석
  - CPU 코어별 사용률
- [ ] 로그 수집 에이전트 설정
  - MongoDB 로그 수집 (Filebeat/Promtail)
  - 시스템 로그 수집
  - 에러 로그 패턴 분석

### 4.3 Prometheus 서버 배포 및 구성
**담당자**: Monitoring Engineer  
**예상 소요 시간**: 8시간  
**산출물**:
- Prometheus 서버 배포 설정
- 스크래핑 및 규칙 설정

**상세 작업**:
- [ ] `infra/docker/monitoring/prometheus/` 구성
  - `docker-compose.yml`: Prometheus 서버 설정
  - `prometheus.yml`: 스크래핑 타겟 설정
  - `recording-rules.yml`: 사전 계산된 메트릭 규칙
  - `alerting-rules.yml`: 알림 규칙 정의
- [ ] `deploy-prometheus.yml` 플레이북 작성
  - Prometheus 서버 컨테이너 배포
  - 설정 파일 자동 생성 및 배포
  - 데이터 스토리지 볼륨 설정
  - 백업 및 복구 메커니즘
- [ ] 서비스 디스커버리 설정
  - GCP 인스턴스 자동 발견
  - Consul 기반 동적 타겟 관리
  - DNS 기반 서비스 발견
- [ ] 메트릭 보존 정책 설정
  - 고해상도 데이터: 7일
  - 중해상도 데이터: 30일
  - 저해상도 데이터: 1년

### 4.4 Grafana 대시보드 및 시각화 설정
**담당자**: Data Visualization Engineer  
**예상 소요 시간**: 10시간  
**산출물**:
- Grafana 배포 설정
- MongoDB 전용 대시보드 세트

**상세 작업**:
- [ ] `infra/docker/monitoring/grafana/` 구성
  - `docker-compose.yml`: Grafana 서버 설정
  - `datasources.yml`: Prometheus 데이터소스 설정
  - `dashboards/`: 사전 구성된 대시보드들
  - `provisioning/`: 자동 프로비저닝 설정
- [ ] `deploy-grafana.yml` 플레이북 작성
  - Grafana 서버 컨테이너 배포
  - 관리자 계정 및 조직 설정
  - LDAP/OAuth 연동 (선택적)
  - 플러그인 자동 설치
- [ ] MongoDB 클러스터 대시보드 개발
  - **Overview Dashboard**: 전체 클러스터 상태
  - **Config Server Dashboard**: Config Server 모니터링
  - **Shard Dashboard**: 샤드별 성능 지표
  - **Router Dashboard**: Router 상태 및 연결
  - **Replication Dashboard**: Replica Set 상태
- [ ] 시스템 대시보드 개발
  - **Node Overview**: 서버 리소스 사용률
  - **Network Dashboard**: 네트워크 트래픽 분석
  - **Storage Dashboard**: 디스크 사용률 및 I/O
- [ ] 비즈니스 메트릭 대시보드
  - **Application Metrics**: 애플리케이션 성능
  - **User Analytics**: 사용자 행동 분석
  - **SLA Dashboard**: 서비스 수준 목표

### 4.5 Alertmanager 구성 및 알림 설정
**담당자**: SRE Engineer  
**예상 소요 시간**: 8시간  
**산출물**:
- Alertmanager 배포 설정
- 알림 규칙 및 라우팅 설정

**상세 작업**:
- [ ] `infra/docker/monitoring/alertmanager/` 구성
  - `docker-compose.yml`: Alertmanager 서버 설정
  - `alertmanager.yml`: 알림 라우팅 규칙
  - `templates/`: 알림 메시지 템플릿
- [ ] `deploy-alertmanager.yml` 플레이북 작성
  - Alertmanager 클러스터 구성 (고가용성)
  - 알림 라우팅 규칙 설정
  - 알림 채널 연동 (Slack, Email, PagerDuty)
- [ ] MongoDB 전용 알림 규칙 개발
  - **Critical**: Primary 노드 다운, Replica Set 실패
  - **Warning**: 복제 지연, 디스크 사용률 80% 초과
  - **Info**: 새로운 노드 추가, 설정 변경
- [ ] 알림 그룹핑 및 억제 규칙
  - 동일 인시던트 중복 알림 방지
  - 알림 에스컬레이션 정책
  - 유지보수 모드 알림 억제

### 4.6 로그 수집 및 분석 시스템
**담당자**: Log Analysis Engineer  
**예상 소요 시간**: 6시간  
**산출물**:
- ELK/PLG 스택 배포 설정
- 로그 분석 대시보드

**상세 작업**:
- [ ] `infra/docker/monitoring/logging/` 구성
  - `docker-compose.yml`: ELK 또는 PLG 스택
  - `logstash.conf` 또는 `loki-config.yml`
  - `filebeat.yml`: 로그 수집 설정
- [ ] MongoDB 로그 파싱 규칙 개발
  - 쿼리 성능 로그 분석
  - 에러 로그 패턴 인식
  - 슬로우 쿼리 추출 및 분석
- [ ] 로그 기반 알림 설정
  - 에러 로그 임계치 초과 시 알림
  - 보안 이벤트 실시간 알림
  - 성능 이상 패턴 감지

### 4.7 성능 모니터링 및 용량 계획
**담당자**: Performance Engineer  
**예상 소요 시간**: 6시간  
**산출물**:
- 성능 벤치마크 도구
- 용량 계획 대시보드

**상세 작업**:
- [ ] 성능 메트릭 수집 자동화
  - QPS (Queries Per Second) 측정
  - 응답시간 분포 분석
  - 처리량 트렌드 분석
- [ ] 용량 계획 도구 개발
  - 리소스 사용률 예측 모델
  - 스케일링 포인트 자동 감지
  - 비용 최적화 권고사항
- [ ] SLI/SLO 대시보드 구현
  - 가용성 SLI: 99.9% uptime
  - 성능 SLI: 95% 응답시간 < 100ms
  - 신뢰성 SLI: 에러율 < 0.1%

### 4.8 통합 테스트 및 검증
**담당자**: QA Engineer  
**예상 소요 시간**: 6시간  
**산출물**:
- 모니터링 시스템 테스트 스위트
- 장애 시뮬레이션 결과

**상세 작업**:
- [ ] 모니터링 파이프라인 테스트
  - 메트릭 수집 정상 동작 확인
  - 대시보드 데이터 정확성 검증
  - 알림 발송 테스트
- [ ] 장애 시뮬레이션 테스트
  - MongoDB 노드 장애 시나리오
  - 네트워크 분할 시나리오
  - 디스크 용량 부족 시나리오
- [ ] 성능 벤치마크 실행
  - 모니터링 오버헤드 측정
  - 대규모 메트릭 수집 성능 테스트
  - 알림 지연시간 측정

## 모니터링 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Config        │    │    Shard        │    │    Router       │
│   Servers       │    │   Servers       │    │   (mongos)      │
│                 │    │                 │    │                 │
│ mongodb-exporter│    │ mongodb-exporter│    │ mongodb-exporter│
│    :9216        │    │    :9217        │    │    :9218        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────────────────────────────────────┐
         │                Prometheus                       │
         │                 :9090                          │
         │  ┌─────────────────────────────────────────┐   │
         │  │         Recording Rules               │   │
         │  │         Alerting Rules                │   │
         │  └─────────────────────────────────────────┘   │
         └─────────────────────────────────────────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 │                               │
     ┌─────────────────┐              ┌─────────────────┐
     │    Grafana      │              │  Alertmanager   │
     │     :3000       │              │     :9093       │
     │                 │              │                 │
     │ ┌─────────────┐ │              │ ┌─────────────┐ │
     │ │ Dashboards  │ │              │ │   Slack     │ │
     │ │ - Overview  │ │              │ │   Email     │ │
     │ │ - MongoDB   │ │              │ │ PagerDuty   │ │
     │ │ - System    │ │              │ └─────────────┘ │
     │ └─────────────┘ │              └─────────────────┘
     └─────────────────┘
```

## 완료 기준 (Definition of Done)

### 기능적 요구사항
- [ ] 모든 MongoDB 노드에서 메트릭 수집 정상 동작
- [ ] Prometheus에서 모든 타겟 UP 상태 확인
- [ ] Grafana 대시보드에서 실시간 데이터 표시
- [ ] Alertmanager 알림 규칙 정상 동작 확인
- [ ] 로그 수집 및 분석 시스템 정상 동작

### 성능 요구사항
- [ ] 메트릭 수집 오버헤드 < 5%
- [ ] 알림 발송 지연시간 < 30초
- [ ] 대시보드 응답시간 < 2초
- [ ] 로그 수집 처리량 > 10K logs/sec

### 가용성 요구사항
- [ ] Prometheus 고가용성 구성 (HA)
- [ ] Grafana 세션 지속성 보장
- [ ] Alertmanager 클러스터링 구성
- [ ] 백업 및 복구 절차 검증

### 보안 요구사항
- [ ] 모니터링 계정 최소 권한 원칙 적용
- [ ] 대시보드 접근 권한 관리
- [ ] 메트릭 데이터 암호화 (선택적)
- [ ] 알림 채널 보안 인증

## 주요 메트릭 정의

### MongoDB 메트릭
```yaml
# Config Server 메트릭
- mongodb_config_server_operations_total
- mongodb_config_server_connections_current
- mongodb_config_server_memory_usage

# Shard Server 메트릭  
- mongodb_shard_operations_total
- mongodb_shard_replication_lag_seconds
- mongodb_shard_index_usage_count

# Router 메트릭
- mongodb_mongos_connections_total
- mongodb_mongos_query_executor_total
- mongodb_mongos_chunks_total
```

### 시스템 메트릭
```yaml
# Node 메트릭
- node_cpu_seconds_total
- node_memory_MemAvailable_bytes
- node_disk_io_time_seconds_total
- node_network_receive_bytes_total
```

## 알림 규칙 예시

### Critical 알림
```yaml
# Primary 노드 다운
- alert: MongoDBPrimaryDown
  expr: mongodb_rs_state{state="PRIMARY"} == 0
  for: 30s
  labels:
    severity: critical
  annotations:
    summary: "MongoDB Primary node is down"

# 복제 지연 심각
- alert: MongoDBReplicationLagHigh  
  expr: mongodb_rs_members_optimeDate{state="SECONDARY"} - mongodb_rs_members_optimeDate{state="PRIMARY"} > 300
  for: 2m
  labels:
    severity: critical
```

### Warning 알림
```yaml
# 디스크 사용률 높음
- alert: DiskUsageHigh
  expr: (1 - node_filesystem_free_bytes / node_filesystem_size_bytes) > 0.8
  for: 5m
  labels:
    severity: warning

# 연결 수 높음
- alert: MongoDBConnectionsHigh
  expr: mongodb_connections{state="current"} > 800
  for: 5m
  labels:
    severity: warning
```

## 다음 단계 준비사항
- 모니터링 데이터를 활용한 자동 스케일링 정책 준비
- 5단계 운영 도구에서 활용할 메트릭 API 엔드포인트 설정
- 백업/복구 작업의 모니터링 연동 준비

## 리스크 및 대응방안

### 높은 리스크
- **메트릭 수집 실패**: 백업 수집 경로 및 알림 설정
- **대시보드 성능 저하**: 쿼리 최적화 및 캐싱 전략

### 중간 리스크
- **알림 폭주**: 알림 그룹핑 및 억제 규칙 강화
- **스토리지 부족**: 자동 정리 정책 및 압축 설정

### 낮은 리스크
- **권한 오류**: 모니터링 계정 권한 사전 검증
- **네트워크 지연**: 로컬 캐싱 및 배치 전송 최적화