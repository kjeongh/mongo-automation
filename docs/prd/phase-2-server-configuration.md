# 2단계: 서버 초기 구성 자동화 (Ansible)

## 목표
생성된 GCP VM 인스턴스에 Docker 환경 및 MongoDB 실행을 위한 기본 소프트웨어 자동 설치

## 세부 작업 계획

### 2.1 Ansible 환경 구성
**담당자**: DevOps Engineer  
**예상 소요 시간**: 3시간  
**산출물**:
- Ansible 디렉토리 구조
- 인벤토리 파일 템플릿
- ansible.cfg 설정

**상세 작업**:
- [ ] `infra/ansible/inventories/` 구조 생성
- [ ] `infra/ansible/playbooks/` 구조 생성
- [ ] `infra/ansible/roles/` 공통 역할 정의
- [ ] 동적 인벤토리 스크립트 작성 (Terraform output 연동)
- [ ] SSH 연결 설정 및 키 관리 방안

### 2.2 기본 시스템 설정 플레이북
**담당자**: System Administrator  
**예상 소요 시간**: 6시간  
**산출물**:
- `base-system.yml` 플레이북
- 시스템 보안 설정 역할

**상세 작업**:
- [ ] OS 패키지 업데이트 자동화
- [ ] 타임존 설정 (Asia/Seoul)
- [ ] 기본 패키지 설치 (curl, wget, unzip, git)
- [ ] 시스템 사용자 계정 생성 및 권한 설정
- [ ] SSH 보안 설정 (포트 변경, 키 인증만 허용)
- [ ] 방화벽 기본 설정 (ufw)

### 2.3 Docker 설치 자동화
**담당자**: Container Engineer  
**예상 소요 시간**: 4시간  
**산출물**:
- `install-docker.yml` 플레이북
- Docker 보안 설정 역할

**상세 작업**:
- [ ] Docker CE 최신 버전 설치
- [ ] Docker Compose v2 설치
- [ ] MongoDB 사용자를 docker 그룹에 추가
- [ ] Docker 데몬 설정 (/etc/docker/daemon.json)
- [ ] Docker 로그 로테이션 설정
- [ ] Docker 서비스 자동 시작 설정

### 2.4 MongoDB 전용 시스템 최적화
**담당자**: Database Administrator  
**예상 소요 시간**: 5시간  
**산출물**:
- `mongodb-optimization.yml` 플레이북
- 성능 튜닝 설정 역할

**상세 작업**:
- [ ] MongoDB 데이터 디렉토리 생성 및 권한 설정
- [ ] 시스템 파라미터 튜닝 (ulimit, vm.swappiness 등)
- [ ] 디스크 마운트 옵션 최적화 (noatime, nobarrier)
- [ ] 투명한 큰 페이지(THP) 비활성화
- [ ] NUMA 설정 (필요시)
- [ ] 로그 디렉토리 생성 및 logrotate 설정

### 2.5 네트워크 및 보안 설정
**담당자**: Security Engineer  
**예상 소요 시간**: 4시간  
**산출물**:
- `security-hardening.yml` 플레이북
- 네트워크 보안 역할

**상세 작업**:
- [ ] MongoDB 포트별 방화벽 규칙 적용
  - Config Server: 27019
  - Shard Server: 27017  
  - Router: 27016
- [ ] fail2ban 설치 및 설정
- [ ] 불필요한 서비스 비활성화
- [ ] 커널 보안 파라미터 설정
- [ ] 로그 수집 설정 (rsyslog)

### 2.6 모니터링 에이전트 사전 설치
**담당자**: Monitoring Engineer  
**예상 소요 시간**: 3시간  
**산출물**:
- `monitoring-agents.yml` 플레이북
- Node Exporter 설치 역할

**상세 작업**:
- [ ] Prometheus Node Exporter 설치
- [ ] 시스템 메트릭 수집 설정
- [ ] 로그 수집 에이전트 준비 (향후 연동용)
- [ ] 헬스체크 스크립트 배치
- [ ] 모니터링 사용자 계정 생성

### 2.7 배포 검증 및 테스트
**담당자**: QA Engineer  
**예상 소요 시간**: 4시간  
**산출물**:
- 배포 검증 스크립트
- 시스템 상태 확인 플레이북

**상세 작업**:
- [ ] 전체 플레이북 실행 테스트
- [ ] Docker 설치 상태 확인
- [ ] 시스템 최적화 적용 검증
- [ ] 네트워크 연결성 테스트
- [ ] 보안 설정 검증
- [ ] 성능 벤치마크 기본 테스트

## Ansible 플레이북 구조

```
infra/ansible/
├── ansible.cfg
├── inventories/
│   ├── config-servers.ini
│   ├── shard-servers.ini
│   ├── routers.ini
│   └── dynamic-inventory.py
├── playbooks/
│   ├── site.yml                    # 마스터 플레이북
│   ├── base-system.yml
│   ├── install-docker.yml
│   ├── mongodb-optimization.yml
│   ├── security-hardening.yml
│   ├── monitoring-agents.yml
│   └── verify-installation.yml
├── roles/
│   ├── common/
│   ├── docker/
│   ├── mongodb-base/
│   ├── security/
│   └── monitoring/
└── group_vars/
    ├── all.yml
    ├── config_servers.yml
    ├── shard_servers.yml
    └── routers.yml
```

## 완료 기준 (Definition of Done)

### 기술적 요구사항
- [ ] 모든 VM에 Docker CE 최신 버전 설치 완료
- [ ] MongoDB 최적화 설정 모든 노드 적용
- [ ] 네트워크 보안 규칙 정상 적용
- [ ] 시스템 모니터링 에이전트 작동 확인
- [ ] 플레이북 실행 시 멱등성 보장

### 보안 요구사항
- [ ] SSH 키 기반 인증만 허용
- [ ] 불필요한 포트 모두 차단
- [ ] fail2ban 정상 작동
- [ ] 시스템 로그 정상 수집
- [ ] 보안 패치 자동 업데이트 설정

### 성능 요구사항
- [ ] MongoDB 권장 시스템 파라미터 모두 적용
- [ ] 투명한 큰 페이지(THP) 비활성화 확인
- [ ] 디스크 I/O 최적화 설정 적용
- [ ] 메모리 설정 최적화

### 문서화 요구사항
- [ ] 각 플레이북별 실행 가이드
- [ ] 변수 설정 방법 문서화
- [ ] 에러 발생 시 트러블슈팅 가이드
- [ ] 롤백 절차 문서화

## 환경변수 설정

### group_vars/all.yml
```yaml
# 시스템 설정
timezone: "Asia/Seoul"
mongodb_user: "mongodb"
mongodb_group: "mongodb"

# Docker 설정
docker_edition: "ce"
docker_compose_version: "2.20.2"

# 보안 설정
ssh_port: 2222
fail2ban_enabled: true

# 모니터링 설정
node_exporter_port: 9100
```

### 노드별 특화 설정
```yaml
# config_servers.yml
mongodb_port: 27019
data_directory: "/data/configdb"

# shard_servers.yml  
mongodb_port: 27017
data_directory: "/data/db"

# routers.yml
mongodb_port: 27016
config_servers: "{{ groups['config_servers'] }}"
```

## 다음 단계 준비사항
- Docker 환경에서 MongoDB 컨테이너 실행 준비 완료
- 각 노드별 역할에 맞는 디렉토리 구조 생성
- 3단계 MongoDB 배포를 위한 환경 설정 완료

## 리스크 및 대응방안

### 높은 리스크
- **SSH 연결 실패**: 키 교환 자동화 및 연결 테스트 강화
- **권한 오류**: sudo 권한 사전 확인 및 설정

### 중간 리스크
- **패키지 설치 실패**: 패키지 저장소 미러 다중화
- **네트워크 설정 충돌**: 기존 설정 백업 및 롤백 절차

### 낮은 리스크
- **디스크 용량 부족**: 사전 용량 체크 태스크 추가
- **서비스 시작 실패**: 의존성 체크 및 재시작 로직