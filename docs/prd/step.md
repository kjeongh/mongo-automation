## 1단계. 프로젝트 초기 준비 및 인프라 세팅

## 주요 목표

- GCP 인프라 리소스 프로비저닝 준비 및 자동화 코드 기본 구조 확립
- 레포지토리 기본 골격/작업 환경 세팅

## 태스크

- [ ]  레포지토리 초기화 및 위 구조에 맞는 폴더, README 작성(프로젝트 목표/설명 포함)
- [ ]  Terraform 초기 파일 생성 (infrastructure/main.tf 등) 및 GCP 프로젝트, VPC, 방화벽, Compute Engine VM 기본 리소스 정의
- [ ]  VM 인스턴스(최소 3대, Replica Set 노드용) 프로비저닝 코드 작성
- [ ]  IAM 서비스 계정 및 권한 정책 준비 (필요할 경우)
- [ ]  **`.env.example`** 환경변수 템플릿 작성 (MongoDB 접속 정보, 모니터링 계정 등 포함)
- [ ]  Terraform 실행 테스트 및 인프라 생성 검증

## 산출물

- Terraform IaC 코드 베이스
- 배포 및 인프라 상태 확인 문서

## 2단계. 서버 초기 구성 자동화 (Ansible 등)

## 주요 목표

- GCE VM에 필요한 기본 소프트웨어 설치 및 설정 자동화
- Docker, Docker Compose 설치 및 환경 준비하기

## 태스크

- [ ]  Ansible 설치 플레이북(**`install_docker.yml`**) 작성—Docker 엔진, Compose 설치
- [ ]  SSH 연결, 인증 키, 베이스 OS 업데이트 및 설정 플레이북 작성
- [ ]  VM 기본 보안 설정 자동화 (firewall, 사용자 계정, 로그 설정 등 옵션)
- [ ]  Ansible 실행 테스트로 VM 준비 상태 확인
- [ ]  문서에 플레이북 사용법 및 환경 변수 관리 정리

## 산출물

- Ansible 플레이북 및 역할(roles) 기본 템플릿
- 자동화 운영 문서

## 3단계. MongoDB Replica Set 컨테이너 배포 자동화

## 주요 목표

- MongoDB Docker 컨테이너 배포 및 Replica Set 초기화 자동화
- 환경변수로 인증 정보, mongod.conf 설정 자동화

## 태스크

- [ ]  **`docker/mongodb`** 내 Dockerfile(필요시), mongod.conf, 초기화 스크립트 준비
- [ ]  Ansible 플레이북(**`deploy_mongodb.yml`**)로 MongoDB 컨테이너 배포 스크립트 자동화
- [ ]  Replica Set 초기화 절차 스크립트 자동 실행 구현 (예: init 스크립트 또는 별도 커맨드)
- [ ]  MongoDB 서비스 상태 체크 및 Replica Set 상태 확인 메커니즘 포함
- [ ]  **`.env`**에서 인증 정보, Replica Set 이름, 포트 등 주입 구현
- [ ]  테스트 수행: Replica Set 정상 구동 및 장애 대응 확인

## 산출물

- MongoDB 컨테이너 배포 플레이북
- Replica Set 초기화 및 상태 점검 스크립트
- 처리 결과 자동 보고 및 로그

## 4단계. 모니터링 시스템 배포 및 연동 구성

## 주요 목표

- mongodb-exporter, Prometheus, Grafana 컨테이너 배포 및 기본 모니터링 자동화
- Prometheus scrape targets 설정 및 Grafana 대시보드 프로비저닝 구성

## 태스크

- [ ]  **`docker/exporter`**에 mongodb-exporter 이미지 및 Dockerfile(필요시) 준비
- [ ]  Ansible 플레이북(**`deploy_exporter.yml`**) 작성하여 노드별 exporter 자동 배포
- [ ]  **`prometheus/prometheus.yml`** 설정 작성 및 Ansible로 Prometheus VM 또는 컨테이너 배포 자동화 (**`deploy_prometheus.yml`**)
- [ ]  Grafana 컨테이너 및 provisioning 설정 작성, 자동 배포 Ansible 플레이북 (**`deploy_grafana.yml`**) 작성
- [ ]  Alertmanager 구성 파일(**`alertmanager/alertmanager.yml`**) 작성 및 연동 플레이북(**`configure_alertmanager.yml`**) 작성
- [ ]  Prometheus와 Exporter 간 네트워크, 방화벽 및 인증 구성 확인
- [ ]  운영 모드에서 대시보드 정상 동작 확인 및 주요 메트릭 시각화 검증

## 산출물

- 모니터링 구성 자동화 플레이북 집합
- Prometheus 및 Grafana 설정 파일들
- Alertmanager 알림 정책 및 통합 문서

## 5단계. 배포 스크립트 및 운영 보조 도구 준비

## 주요 목표

- 전체 배포를 한 번에 실행 가능한 스크립트 및 운영 도구 완성
- 백업, 복원 등 운영 관련 자동화 스크립트 준비

## 태스크

- [ ]  **`scripts/deploy.sh`**: Terraform 적용부터 Ansible 배포까지 전체 프로세스 자동화 스크립트 작성
- [ ]  **`scripts/backup.sh`**, **`restore.sh`**: MongoDB 데이터 백업 및 복원 자동화 스크립트 작성
- [ ]  주요 명령 및 환경설정 문서화/메인트넌스 지침 작성
- [ ]  CI/CD 연동 가능성 검토 및 문서화 (향후 자동배포 대비)

## 산출물

- 자동화 배포 및 운영 스크립트
- 실전 운영 가이드 및 유지보수 매뉴얼