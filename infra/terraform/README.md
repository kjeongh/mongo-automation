# MongoDB Cluster Terraform Configuration

## 개요
GCP에서 MongoDB Sharded Cluster를 자동으로 배포하기 위한 Terraform 설정입니다.

## 📁 정리된 구조
```
terraform/
├── main.tf                          # 기본 네트워크 인프라 (VPC, 서브넷, 방화벽)
├── mongodb-cluster.tf                # 모듈 기반 MongoDB 클러스터 (메인)
├── variables.tf                      # 모든 변수 정의 (통합)
├── modules/
│   └── mongodb-instances/            # 재사용 가능한 MongoDB 인스턴스 모듈
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── terraform.tfvars.example          # 메인 설정 예제 ⭐ 사용 권장
├── terraform.tfvars.legacy.example   # 레거시 네트워크 전용
├── terraform.tfvars.cluster.example  # 상세 클러스터 설정
├── variables/                        # [DEPRECATED] 변수 분리 디렉토리
│   └── README.md
└── README.md                         # 이 파일
```

## 🚀 빠른 시작

### 1. 설정 파일 준비
```bash
# 권장: 메인 설정 사용
cp terraform.tfvars.example terraform.tfvars
```

### 2. 필수 값 수정
`terraform.tfvars` 파일에서 다음 값들을 반드시 변경:
```hcl
project_id = "your-actual-gcp-project-id"    # GCP 프로젝트 ID
source_ranges = ["YOUR_IP/32"]               # 본인 IP 주소
ssh_key_path = "~/.ssh/id_rsa.pub"          # SSH 공개키 경로
```

### 3. 배포 실행
```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## 🏗️ 배포되는 리소스

### 자동 생성되는 인프라
| 컴포넌트 | 개수 | 인스턴스명 | 포트 | 서브넷 |
|---------|------|------------|------|--------|
| **Config Servers** | 3개 | config-server-1~3 | 27019 | 10.0.10.0/24 |
| **Shard Servers** | 9개 | shard-server-1~9 | 27017 | 10.0.20.0/24 |
| **Routers (mongos)** | 2개 | mongo-router-1~2 | 27016 | 10.0.30.0/24 |

### 네트워크 구성
- **VPC**: 전용 VPC 네트워크
- **서브넷**: 컴포넌트별 전용 서브넷 자동 생성
- **방화벽**: 최소 권한 원칙 적용
- **AZ 분산**: 자동으로 서로 다른 가용 영역에 배치

## 📊 주요 출력값 확인

배포 완료 후 다음 명령으로 정보 확인:

```bash
# Config Server 정보
terraform output config_servers

# Shard Server 정보  
terraform output shard_servers

# Router 정보
terraform output mongo_routers

# 전체 클러스터 요약
terraform output cluster_summary
```

## ⚙️ 설정 사용자화

### 클러스터 규모 조정
```hcl
# terraform.tfvars에서
shard_count = 5    # 샤드 개수 (기본: 3)
router_count = 3   # 라우터 개수 (기본: 2)
```

### 인스턴스 사양 변경
```hcl
# Config Server (가벼운 작업)
config_server_machine_type = "e2-small"
config_server_disk_size = 10

# Shard Server (주요 데이터 저장)
shard_server_machine_type = "e2-standard-8"
shard_server_disk_size = 500

# Router (쿼리 처리)
router_machine_type = "e2-standard-4"
```

### 보안 설정
```hcl
# 외부 접근 제어
config_server_allow_external_access = false  # Config Server 보호
shard_server_allow_external_access = false   # Shard Server 보호  
router_allow_external_access = true          # 애플리케이션 접근용

# IP 제한 (보안 강화)
source_ranges = [
  "203.0.113.0/32",    # 사무실 IP
  "198.51.100.0/32"    # 집 IP
]
```

## 🔧 고급 사용법

### 개발/테스트 환경 구성
```hcl
# 비용 절약 설정
shard_count = 1
router_count = 1
config_server_machine_type = "e2-micro"
shard_server_machine_type = "e2-small"
enable_backup = false
```

### 프로덕션 환경 구성
```hcl
# 고성능 설정
shard_count = 6
router_count = 3
shard_server_machine_type = "c2-standard-16"
shard_server_disk_size = 1000
shard_server_disk_type = "pd-ssd"
enable_backup = true
backup_retention_days = 90
```

## 🛠️ 문제 해결

### 일반적인 오류들

**1. 프로젝트 ID 오류**
```
Error: google: could not find default credentials
```
→ `gcloud auth application-default login` 실행

**2. 할당량 초과**
```
Error: quota exceeded for resource 'CPUS'
```
→ GCP 콘솔에서 컴퓨트 엔진 할당량 증가 요청

**3. 방화벽 규칙 충돌**
```
Error: googleapi: Error 409: already exists
```
→ 기존 방화벽 규칙 이름 변경 또는 제거

### 디버깅 방법
```bash
# 상세 로그 확인
export TF_LOG=DEBUG
terraform apply

# 특정 리소스 재생성
terraform taint module.config_servers.google_compute_instance.mongodb_instances[0]
terraform apply
```

## 📈 모니터링 및 관리

### 리소스 상태 확인
```bash
# 인스턴스 상태 확인  
gcloud compute instances list --filter='name~mongodb'

# 네트워크 상태 확인
gcloud compute networks list
gcloud compute firewall-rules list
```

### 비용 모니터링
```bash
# 현재 월 비용 확인
gcloud billing accounts list
gcloud billing projects describe PROJECT_ID
```

## 🔄 업그레이드 및 변경

### 인스턴스 사양 업그레이드
```bash
# 1. terraform.tfvars에서 machine_type 변경
# 2. 계획 확인
terraform plan -var-file=terraform.tfvars

# 3. 적용 (자동으로 인스턴스 재생성)
terraform apply
```

### 샤드 추가
```bash
# 1. shard_count 증가
shard_count = 4  # 3에서 4로 증가

# 2. 적용 (새 샤드 인스턴스 3개 자동 생성)
terraform apply
```

## 🗑️ 리소스 정리

### 전체 삭제
```bash
terraform destroy -var-file=terraform.tfvars
```

### 특정 컴포넌트만 삭제
```bash
# Config Server만 삭제
terraform destroy -target=module.config_servers

# 특정 샤드만 삭제  
terraform destroy -target=module.shard_servers.google_compute_instance.mongodb_instances[6]
```

## 📚 다음 단계

1. **Ansible 배포**: `../ansible/` 디렉토리에서 MongoDB 설정
2. **클러스터 초기화**: Config Server Replica Set 및 Sharding 구성
3. **모니터링 설정**: Prometheus, Grafana 설치
4. **백업 구성**: 자동 백업 스크립트 설정
5. **로드 테스트**: 클러스터 성능 및 부하 테스트

## 🔗 관련 문서

- [MongoDB 클러스터 모듈 상세 문서](./modules/mongodb-instances/)
- [Ansible 플레이북 가이드](../ansible/README.md)  
- [운영 가이드](../../docs/operational-guide.md)
- [보안 정책](../../docs/security-policy.md)
- [프로젝트 전체 문서](../../docs/)

---

💡 **팁**: 처음 사용하시는 경우 `terraform.tfvars.example`을 복사해서 시작하시고, 프로젝트 ID와 IP 주소만 변경하면 바로 테스트할 수 있습니다!