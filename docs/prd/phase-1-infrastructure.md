# 1단계: 프로젝트 초기 준비 및 인프라 세팅

## 목표
GCP 환경에서 MongoDB Sharded Cluster를 위한 기본 인프라 구조 자동화

## 세부 작업 계획

### 1.1 프로젝트 구조 초기화
**담당자**: DevOps Engineer  
**예상 소요 시간**: 4시간  
**산출물**: 
- 프로젝트 디렉토리 구조
- 기본 README.md
- .gitignore 설정

**상세 작업**:
- [ ] `infra/terraform/` 디렉토리 구조 생성
- [ ] `infra/ansible/` 플레이북 골격 생성
- [ ] `infra/docker/mongodb/` 컨테이너 구성 디렉토리 생성
- [ ] `scripts/` 배포 스크립트 디렉토리 생성
- [ ] `monitoring/` Prometheus/Grafana 설정 디렉토리 생성

### 1.2 Terraform 기본 인프라 정의
**담당자**: Infrastructure Engineer  
**예상 소요 시간**: 8시간  
**산출물**:
- `main.tf`, `variables.tf`, `outputs.tf`
- `terraform.tfvars.example`

**상세 작업**:
- [ ] GCP Provider 및 기본 설정
- [ ] VPC 네트워크 및 서브넷 정의 (config-server, shard-server, router별)
- [ ] 방화벽 규칙 (MongoDB 포트: 27016, 27017, 27019)
- [ ] Compute Engine VM 템플릿 정의
  - Config Server: e2-medium, 20GB SSD (3대)
  - Shard Server: e2-standard-2, 50GB SSD (6대, 2개 샤드)
  - Router: e2-small, 10GB SSD (2대)

### 1.3 멀티 AZ 배치 전략 구현
**담당자**: Infrastructure Engineer  
**예상 소요 시간**: 6시간  
**산출물**:
- 고가용성 VM 배치 코드
- Load Balancer 구성

**상세 작업**:
- [ ] Config Server 3대 서로 다른 Zone 배치
- [ ] Shard Server Primary-Secondary 교차 배치
- [ ] Router 인스턴스 가용성 존 분산
- [ ] 내부 Load Balancer 구성 (Router 앞단)

### 1.4 보안 및 네트워크 설정
**담당자**: Security Engineer  
**예상 소요 시간**: 6시간  
**산출물**:
- IAM 역할 및 정책
- VPC 보안 그룹
- SSH 키 관리 방안

**상세 작업**:
- [ ] MongoDB 클러스터용 서비스 계정 생성
- [ ] VM 접근을 위한 IAM 역할 정의
- [ ] MongoDB 포트별 방화벽 규칙 (internal only)
- [ ] SSH 키 페어 생성 및 배포 전략
- [ ] Cloud NAT 구성 (외부 인터넷 접근용)

### 1.5 환경변수 및 설정 관리
**담당자**: DevOps Engineer  
**예상 소요 시간**: 3시간  
**산출물**:
- `.env.example` 템플릿
- Terraform variables 정의

**상세 작업**:
- [ ] GCP 프로젝트 ID, 리전, 존 설정
- [ ] MongoDB 인증 정보 템플릿
- [ ] 모니터링 관련 환경변수
- [ ] VM 스펙 및 네트워크 설정 변수

### 1.6 배포 테스트 및 검증
**담당자**: QA Engineer  
**예상 소요 시간**: 4시간  
**산출물**:
- 배포 검증 스크립트
- 인프라 상태 확인 문서

**상세 작업**:
- [ ] `terraform plan` 검증
- [ ] `terraform apply` 실행 및 리소스 생성 확인
- [ ] VM 인스턴스 SSH 접근 테스트
- [ ] 네트워크 연결성 확인 (ping, port check)
- [ ] Cloud Console에서 리소스 상태 확인

## 완료 기준 (Definition of Done)

### 기술적 요구사항
- [ ] 모든 VM 인스턴스가 정상 생성됨
- [ ] 네트워크 간 통신이 정상 작동함
- [ ] SSH 접근이 모든 인스턴스에서 가능함
- [ ] Terraform state가 원격 저장소에 안전하게 보관됨

### 문서화 요구사항
- [ ] 인프라 아키텍처 다이어그램 작성
- [ ] Terraform 변수 설명 문서
- [ ] 배포 가이드 작성
- [ ] 롤백 절차 문서화

### 보안 요구사항
- [ ] 모든 민감한 정보가 환경변수로 관리됨
- [ ] IAM 최소 권한 원칙 적용됨
- [ ] 방화벽 규칙이 최소 필요 포트만 허용함
- [ ] SSH 키가 안전하게 관리됨

## 다음 단계 준비사항
- VM 인스턴스 목록 및 IP 정보
- Ansible 인벤토리 파일 생성을 위한 데이터
- 2단계에서 사용할 환경변수 설정

## 리스크 및 대응방안

### 높은 리스크
- **GCP 할당량 부족**: 사전에 할당량 확인 및 증량 요청
- **네트워크 설정 오류**: 단계별 테스트로 조기 발견

### 중간 리스크  
- **비용 초과**: 리소스 스펙 최적화 및 모니터링
- **권한 문제**: IAM 역할 사전 검증

### 낮은 리스크
- **Terraform 상태 충돌**: 원격 state 잠금 메커니즘 활용