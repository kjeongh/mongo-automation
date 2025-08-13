# 3단계: MongoDB Sharded Cluster 컨테이너 배포 자동화

## 목표
Docker 환경에서 MongoDB Sharded Cluster (Config Server, Shard Server, Router) 완전 자동 배포 및 초기화

## 세부 작업 계획

### 3.1 MongoDB Docker 이미지 및 설정 준비
**담당자**: Container Engineer  
**예상 소요 시간**: 6시간  
**산출물**:
- Docker Compose 파일 세트
- MongoDB 설정 파일 템플릿
- 초기화 스크립트

**상세 작업**:
- [ ] `infra/docker/mongodb/common/` 공통 스크립트 작성
  - `init-keyfile.sh`: keyfile 생성 및 권한 설정
  - `wait-for-mongo.sh`: MongoDB 서비스 대기 스크립트
  - `health-check.sh`: 컨테이너 헬스체크 스크립트
- [ ] `infra/docker/mongodb/config-server/` 구성
  - `docker-compose.yml`: Config Server 3대 구성
  - `mongod.conf`: Config Server 전용 설정
  - `init-config-rs.sh`: Config Replica Set 초기화
- [ ] `infra/docker/mongodb/shard-server/` 구성 (샤드별)
  - `docker-compose.shard1.yml`, `docker-compose.shard2.yml`
  - `mongod.conf`: Shard Server 전용 설정
  - `init-shard-rs.sh`: Shard Replica Set 초기화
- [ ] `infra/docker/mongodb/router/` 구성
  - `docker-compose.yml`: Router 2대 구성
  - `mongos.conf`: Router 전용 설정

### 3.2 Config Server 배포 자동화
**담당자**: Database Administrator  
**예상 소요 시간**: 8시간  
**산출물**:
- Config Server 배포 플레이북
- Replica Set 초기화 스크립트

**상세 작업**:
- [ ] `deploy-config-servers.yml` 플레이북 작성
  - Docker Compose 파일 배포
  - 환경변수 템플릿 생성 (.env 파일)
  - 키파일 생성 및 배포
  - Config Server 컨테이너 시작
- [ ] `init-config-replica-set.yml` 플레이북 작성
  - Primary 노드에서 rs.initiate() 실행
  - Secondary 노드 자동 추가
  - 인증 계정 생성 (admin, root)
  - Replica Set 상태 확인
- [ ] Config Server 상태 모니터링 스크립트
  - rs.status() 정기 확인
  - 로그 수집 및 분석

### 3.3 Shard Server 배포 자동화
**담당자**: Database Administrator  
**예상 소요 시간**: 10시간  
**산출물**:
- Shard Server 배포 플레이북
- 다중 샤드 관리 스크립트

**상세 작업**:
- [ ] `deploy-shard-servers.yml` 플레이북 작성
  - 샤드별 Docker Compose 배포
  - 샤드별 환경변수 설정 (SHARD_NAME, REPLICA_SET_NAME)
  - 데이터 볼륨 자동 생성 및 마운트
  - Shard 컨테이너 시작 및 상태 확인
- [ ] `init-shard-replica-sets.yml` 플레이북 작성
  - 각 샤드별 Replica Set 초기화
  - Primary-Secondary 역할 자동 할당
  - 샤드별 인증 계정 생성
  - 인덱싱 및 초기 설정
- [ ] 샤드 확장 자동화
  - 새로운 샤드 추가 스크립트
  - 기존 샤드 스케일아웃 지원

### 3.4 Router (mongos) 배포 자동화
**담당자**: Database Administrator  
**예상 소요 시간**: 6시간  
**산출물**:
- Router 배포 플레이북
- 클러스터 초기화 스크립트

**상세 작업**:
- [ ] `deploy-routers.yml` 플레이북 작성
  - Router Docker Compose 배포
  - Config Server 연결 설정
  - 로드밸런싱 설정
  - Router 컨테이너 시작
- [ ] `init-sharded-cluster.yml` 플레이북 작성
  - sh.addShard() 를 통한 샤드 등록
  - 샤딩 활성화 (sh.enableSharding())
  - 컬렉션별 샤드 키 설정
  - 클러스터 상태 확인
- [ ] Router 고가용성 설정
  - 헬스체크 및 failover 메커니즘
  - 연결 풀 최적화

### 3.5 보안 및 인증 설정 자동화
**담당자**: Security Engineer  
**예상 소요 시간**: 8시간  
**산출물**:
- 보안 설정 플레이북
- 인증 계정 관리 스크립트

**상세 작업**:
- [ ] `configure-security.yml` 플레이북 작성
  - Keyfile 기반 클러스터 인증 설정
  - SCRAM-SHA-256 사용자 인증 활성화
  - TLS/SSL 인증서 배포 (선택적)
  - 네트워크 보안 설정 적용
- [ ] 사용자 계정 관리 자동화
  - 관리자 계정 생성 (admin DB)
  - 애플리케이션 계정 생성 (업무 DB별)
  - 읽기전용 계정 생성 (모니터링용)
  - 계정 권한 매트릭스 관리
- [ ] 감사 로깅 설정
  - 인증 실패 로그 수집
  - 권한 변경 추적
  - 데이터 접근 감사

### 3.6 데이터 백업 및 복구 준비
**담당자**: Database Administrator  
**예상 소요 시간**: 6시간  
**산출물**:
- 백업 스크립트 세트
- 복구 절차 문서

**상세 작업**:
- [ ] 자동 백업 스크립트 작성
  - mongodump 기반 논리적 백업
  - 스냅샷 기반 물리적 백업
  - 증분 백업 메커니즘
  - GCS 업로드 자동화
- [ ] 복구 테스트 스크립트
  - 단일 컬렉션 복구
  - 전체 DB 복구
  - Point-in-time 복구
  - 크로스 샤드 복구
- [ ] 백업 스케줄링
  - Cron 기반 정기 백업
  - 보존 정책 설정
  - 백업 검증 자동화

### 3.7 배포 테스트 및 검증
**담당자**: QA Engineer  
**예상 소요 시간**: 8시간  
**산출물**:
- 통합 테스트 스위트
- 성능 벤치마크 결과

**상세 작업**:
- [ ] 클러스터 연결 테스트
  - 모든 노드 간 통신 확인
  - Router를 통한 CRUD 작업 테스트
  - 샤딩 동작 확인
- [ ] 장애 시나리오 테스트
  - Primary 노드 장애 복구 테스트
  - Config Server 장애 대응 테스트
  - 네트워크 분할 복구 테스트
- [ ] 성능 벤치마크
  - 읽기/쓰기 성능 측정
  - 동시 연결 수 테스트
  - 샤딩 성능 확인
- [ ] 전체 배포 프로세스 검증
  - 클린 환경에서 전체 배포 테스트
  - 배포 시간 측정 및 최적화
  - 에러 처리 시나리오 검증

## MongoDB 클러스터 구성

### Config Server 구성 (3대)
```yaml
# docker-compose.yml
services:
  config-server-1:
    image: mongo:8.0
    container_name: config-server-1
    command: >
      mongod --configsvr 
             --replSet csRS 
             --port 27019
             --keyFile /data/keyfile
             --auth
    volumes:
      - config1_data:/data/configdb
      - ./keyfile:/data/keyfile:ro
    ports:
      - "27019:27019"
    networks:
      - mongodb_network
```

### Shard Server 구성 (샤드당 3대)
```yaml
# docker-compose.shard1.yml  
services:
  shard1-primary:
    image: mongo:8.0
    container_name: shard1-primary
    command: >
      mongod --shardsvr 
             --replSet shard1RS 
             --port 27017
             --keyFile /data/keyfile
             --auth
    volumes:
      - shard1_primary_data:/data/db
      - ./keyfile:/data/keyfile:ro
```

### Router 구성 (2대)
```yaml
# docker-compose.yml
services:
  mongos-1:
    image: mongo:8.0
    container_name: mongos-1
    command: >
      mongos --configdb csRS/config-server-1:27019,config-server-2:27019,config-server-3:27019
             --port 27016
             --keyFile /data/keyfile
    depends_on:
      - config-server-1
      - config-server-2
      - config-server-3
```

## 완료 기준 (Definition of Done)

### 기능적 요구사항
- [ ] Config Server Replica Set 정상 동작 (3대)
- [ ] Shard Server Replica Set 정상 동작 (2개 샤드, 각 3대)
- [ ] Router 정상 동작 및 샤드 연결 확인 (2대)
- [ ] sh.status() 명령으로 클러스터 상태 확인 가능
- [ ] 샤딩된 컬렉션에서 CRUD 작업 정상 동작

### 보안 요구사항
- [ ] Keyfile 기반 클러스터 인증 활성화
- [ ] SCRAM-SHA-256 사용자 인증 활성화
- [ ] 관리자/애플리케이션/읽기전용 계정 생성 완료
- [ ] 네트워크 보안 그룹 적용 완료
- [ ] 감사 로깅 활성화

### 성능 요구사항
- [ ] 기본 성능 벤치마크 통과
- [ ] Primary-Secondary 지연시간 5초 이내
- [ ] Router 응답시간 100ms 이내
- [ ] 동시 연결 수 1000개 이상 지원

### 운영 요구사항
- [ ] 자동 백업 스케줄 설정 완료
- [ ] 모니터링 메트릭 수집 가능
- [ ] 로그 로테이션 설정 완료
- [ ] 장애 복구 절차 검증 완료

## 환경변수 설정

### Config Server 환경변수
```bash
# .env
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD}
REPLICA_SET_NAME=csRS
CONFIG_DB_PATH=/data/configdb
KEYFILE_PATH=/data/keyfile
```

### Shard Server 환경변수
```bash
# .env.shard1
SHARD_NAME=shard1
REPLICA_SET_NAME=shard1RS
SHARD_DB_PATH=/data/db
PRIMARY_HOST=shard1-primary
SECONDARY_HOSTS=shard1-secondary1,shard1-secondary2
```

### Router 환경변수
```bash
# .env.router
CONFIG_SERVERS=csRS/config-server-1:27019,config-server-2:27019,config-server-3:27019
ROUTER_PORT=27016
LOG_LEVEL=1
```

## 다음 단계 준비사항
- MongoDB 클러스터 메트릭 수집을 위한 Exporter 설정 준비
- Prometheus 스크래핑 타겟 정보 (IP:PORT 목록)
- 4단계 모니터링 시스템과 연동을 위한 서비스 디스커버리 설정

## 리스크 및 대응방안

### 높은 리스크
- **Replica Set 초기화 실패**: 단계별 검증 및 자동 재시도 메커니즘
- **샤드 등록 실패**: 네트워크 연결 상태 사전 확인 강화

### 중간 리스크
- **키파일 권한 문제**: 자동화된 권한 설정 및 검증
- **포트 충돌**: 동적 포트 할당 또는 사전 포트 점검

### 낮은 리스크
- **컨테이너 재시작 실패**: 헬스체크 강화 및 자동 복구
- **데이터 볼륨 마운트 오류**: 볼륨 존재 여부 사전 확인