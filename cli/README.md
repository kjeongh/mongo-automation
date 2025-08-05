# MongoDB 클러스터 자동화 CLI (dbprovision)

GCP 환경에서 MongoDB 클러스터를 자동으로 구성하고 관리하는 CLI 도구입니다.

## 🚀 설치

### 1. 필수 요구사항

- Python 3.8 이상
- Terraform
- Ansible
- GCP CLI (`gcloud`)

### 2. CLI 설치

```bash
cd cli/
./install.sh
```

## 📋 지원하는 클러스터 유형

- **Standalone**: 단일 MongoDB 인스턴스
- **Replica Set**: 3개 노드 복제 세트
- **Sharded Cluster**: Config Servers + Shard Servers + mongos

## 🛠️ 사용법

### 기본 명령어

```bash
# 도움말
dbprovision --help

# Replica Set 생성 (기본)
dbprovision create --cluster-type replicaset --replica-nodes 3 --project-id my-gcp-project

# Sharded Cluster 생성
dbprovision create --cluster-type sharded --shards 3 --project-id my-gcp-project

# 클러스터 상태 확인
dbprovision status --cluster my-cluster

# 헬스체크
dbprovision health --cluster my-cluster --check-all

# 클러스터 삭제
dbprovision destroy --cluster my-cluster
```

### 상세 설정 예시

```bash
# 고급 Replica Set 구성
dbprovision create \
  --cluster-name production-rs \
  --cluster-type replicaset \
  --replica-nodes 3 \
  --project-id my-project \
  --region asia-northeast3 \
  --zones a,b,c \
  --mongodb-version 8.0 \
  --instance-type e2-standard-4 \
  --disk-size 100 \
  --disk-type pd-ssd \
  --enable-auth \
  --enable-tls \
  --monitoring-enabled \
  --backup-enabled

# 대규모 Sharded Cluster 구성
dbprovision create \
  --cluster-name production-sharded \
  --cluster-type sharded \
  --shard-count 5 \
  --replica-nodes 3 \
  --config-servers 3 \
  --mongos-count 3 \
  --project-id my-project \
  --instance-type e2-standard-8 \
  --disk-size 500 \
  --enable-auth \
  --monitoring-enabled
```

## ⚙️ 주요 파라미터

### 클러스터 구성

| 파라미터 | 설명 | 기본값 | 예시 |
|---------|------|--------|------|
| `--cluster-name` | 클러스터 이름 | mongodb-cluster | production-db |
| `--cluster-type` | 클러스터 유형 | replicaset | standalone, replicaset, sharded |
| `--project-id` | GCP 프로젝트 ID | 필수 | my-gcp-project |
| `--region` | GCP 리전 | asia-northeast3 | us-central1 |
| `--zones` | 가용영역 | 자동 선택 | a,b,c |

### MongoDB 설정

| 파라미터 | 설명 | 기본값 | 예시 |
|---------|------|--------|------|
| `--mongodb-version` | MongoDB 버전 | 8.0 | 7.0, 8.0 |
| `--replica-nodes` | 복제 노드 수 | 3 | 3, 5, 7 |
| `--replica-set-name` | 복제 세트 이름 | rs0 | production-rs |
| `--storage-engine` | 스토리지 엔진 | wiredTiger | wiredTiger |

### 샤딩 설정 (sharded 전용)

| 파라미터 | 설명 | 기본값 | 예시 |
|---------|------|--------|------|
| `--shard-count` | 샤드 수 | 3 | 2, 3, 5, 10 |
| `--config-servers` | Config 서버 수 | 3 | 3 (고정) |
| `--mongos-count` | mongos 인스턴스 수 | 2 | 2, 3, 4 |

### 인프라 설정

| 파라미터 | 설명 | 기본값 | 예시 |
|---------|------|--------|------|
| `--instance-type` | VM 인스턴스 타입 | e2-standard-4 | e2-medium, e2-standard-8 |
| `--disk-size` | 디스크 크기 (GB) | 100 | 50, 200, 500 |
| `--disk-type` | 디스크 타입 | pd-ssd | pd-standard, pd-ssd |

### 보안 설정

| 파라미터 | 설명 | 기본값 | 비고 |
|---------|------|--------|------|
| `--enable-auth` | 인증 활성화 | true | SCRAM-SHA-256 |
| `--enable-tls` | TLS 암호화 | false | 프로덕션 권장 |
| `--auth-mechanism` | 인증 방식 | SCRAM-SHA-256 | 고정값 |

### 운영 설정

| 파라미터 | 설명 | 기본값 | 비고 |
|---------|------|--------|------|
| `--monitoring-enabled` | 모니터링 활성화 | false | Prometheus/Grafana |
| `--backup-enabled` | 백업 활성화 | false | 자동 백업 |
| `--backup-schedule` | 백업 스케줄 | 0 2 * * * | cron 형식 |

## 🏗️ 아키텍처

### Replica Set
```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Primary       │  │   Secondary     │  │   Secondary     │
│   Zone A        │  │   Zone B        │  │   Zone C        │
│   Port: 27017   │  │   Port: 27017   │  │   Port: 27017   │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Sharded Cluster
```
                        mongos (Router)
                    ┌─────────┬─────────┐
                    │ Zone A  │ Zone B  │
                    │ :27016  │ :27016  │
                    └─────────┴─────────┘
                            │
                    ┌───────────────────┐
                    │  Config Servers   │
                    │  (3 nodes, :27019)│
                    └───────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
    Shard 1             Shard 2             Shard 3
  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
  │Primary  :27017│ │Primary  :27017│ │Primary  :27017│
  │Secondary:27017│ │Secondary:27017│ │Secondary:27017│
  │Secondary:27017│ │Secondary:27017│ │Secondary:27017│
  └─────────────┘   └─────────────┘   └─────────────┘
```

## 📝 배포 프로세스

1. **파라미터 검증**: 입력값 유효성 검사
2. **Terraform 실행**: GCP 인프라 프로비저닝
3. **Ansible 배포**: MongoDB 설치 및 설정
4. **클러스터 초기화**: Replica Set 및 샤딩 구성
5. **연결 정보 출력**: 애플리케이션 연결 엔드포인트

## 🔍 운영 명령어

### 상태 확인
```bash
# 전체 클러스터 상태
dbprovision status --cluster my-cluster

# 상세 헬스체크
dbprovision health --cluster my-cluster --check-all
```

### 스케일링 (향후 지원 예정)
```bash
# 샤드 추가
dbprovision scale --cluster my-cluster --shards 5

# mongos 추가
dbprovision scale --cluster my-cluster --mongos 4
```

### 백업 (향후 지원 예정)
```bash
# 수동 백업
dbprovision backup --cluster my-cluster

# 백업 복구
dbprovision restore --cluster my-cluster --backup-id backup-20231201
```

## 🚨 주의사항

1. **GCP 인증**: `gcloud auth login` 및 적절한 권한 필요
2. **비용**: 인스턴스 및 디스크 사용량에 따른 GCP 비용 발생
3. **방화벽**: 자동으로 필요한 포트가 열림 (27016-27019)
4. **백업**: 중요한 데이터는 별도 백업 전략 수립 필요
5. **보안**: 프로덕션 환경에서는 반드시 `--enable-tls` 사용

## 🛠️ 트러블슈팅

### 일반적인 문제

**Terraform 권한 오류**
```bash
# GCP 서비스 계정 키 설정
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
gcloud auth application-default login
```

**Ansible 연결 실패**
```bash
# SSH 키 확인
ssh-add ~/.ssh/id_rsa
gcloud compute config-ssh
```

**MongoDB 연결 실패**
```bash
# 방화벽 규칙 확인
gcloud compute firewall-rules list --filter="name~mongodb"
```

### 로그 확인

```bash
# Terraform 로그
export TF_LOG=DEBUG

# Ansible 상세 로그
ansible-playbook -vvv playbook.yml
```

## 📞 지원

문제가 발생하면 다음 정보와 함께 이슈를 생성해주세요:

1. 사용한 정확한 명령어
2. 에러 메시지 전문
3. GCP 프로젝트 및 리전 정보
4. Python, Terraform, Ansible 버전

---

**주의**: 이 도구는 프로덕션 환경에서 사용 가능하도록 설계되었지만, 중요한 데이터의 경우 충분한 테스트 후 사용하시기 바랍니다.