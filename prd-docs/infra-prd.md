# 인프라 요구사항

## 1. 프로젝트 개요

- **목표**  
  - GCP 환경에서 여러 AZ에 분산된 VM 인스턴스 기반의 MongoDB ReplicaSet 클러스터를 자동화된 인프라 코드(Terraform, Ansible 등)로 구축한다.  
  - Docker 기반 서비스로 일관된 배포/복구/운영을 보장한다.  
  - Prometheus, Grafana, Alertmanager 기반의 모니터링 및 알림 시스템을 포함한다.  
  - 백업/복원, 운영 편의 스크립트를 제공한다.  

## 2. 상세 요구사항

### 2.1 인프라 환경

- **클라우드**: Google Cloud Platform (GCP)  
- **VM 인스턴스 수**: 3대  
- **배치**: 각 VM은 서로 다른 가용영역(AZ)에 위치해야 한다.  
- **프로비저닝**: Terraform으로 VM, 네트워크, 방화벽 등 인프라 자동화  
- **운영체제**: Ubuntu 등 MongoDB 공식 이미지 베이스 (Alpine 사용 안함, 공식 지원 OS 우선)  
- **환경변수, 비밀정보 분리**: `.env` 템플릿 제공  

### 2.2 MongoDB 클러스터 아키텍처

- **구성**: Replica Set  
  - 총 3개의 voting 멤버 (각 VM 동일)  
  - 각 VM에 2개 MongoDB 인스턴스(Docker 컨테이너) 배치:  
    - VM1: master-1, secondary-2  
    - VM2: master-2, secondary-3  
    - VM3: master-3, secondary-1  
- **고리형(Cyclic) 교차 배치**로 AZ 장애 시 생존성 확보 및 Quorum 보장  
- **MongoDB Docker**: 공식 `mongo` 이미지를 사용하며, 버전 태그 명시  
- **초기화/설정**:  
  - `mongod.conf`, 초기화 스크립트, Replica Set 구성 자동화  

### 2.3 자동화 & 관리 도구

- **Terraform**: GCP VM, 네트워크, 방화벽, 기타 인프라 리소스 관리  
- **Ansible**:  
  - Docker 설치, MongoDB 컨테이너 배포, Exporter, Prometheus, Grafana, Alertmanager 등 서비스 구성 자동화 플레이북  
- **Docker**: 모든 서비스 컨테이너 기반 운영. 필요 시 docker-compose로 로컬 테스트 지원  
- **스크립트**: 백업, 복원, 배포 자동화 쉘 스크립트  

### 2.4 모니터링/알림

- **Prometheus**:  
  - MongoDB Exporter를 통한 메트릭 수집  
  - 직접 구성한 `prometheus.yml`, Alert 룰 자동 적용  
- **Grafana**: 대시보드 JSON 및 프로비저닝 자동화  
- **Alertmanager**: 알림 설정용 `alertmanager.yml` 제공  

### 2.5 보안 및 유지관리

- **네트워크**:  
  - 최소한의 Inbound 포트만 오픈  
  - Docker, MongoDB, Prometheus 등 보안설정 권장사항 반영  
- **업데이트 정책**:  
  - 공식 MongoDB 이미지 사용(보안 지원)  
  - 커스텀 이미지 시, 별도 빌드 안함 (Alpine 미사용)  
- **Backup/Restore**: 주기적 백업, 신속 복구 스크립트  

## 3. 폴더/파일 구조
```
/
├── infrastructure/ # Terraform IaC
├── ansible/ # Ansible Playbooks
├── docker/
│ ├── mongodb/
│ ├── exporter/
├── prometheus/
├── grafana/
├── alertmanager/
├── scripts/
├── .env.example
├── README.md
└── .gitignore
```