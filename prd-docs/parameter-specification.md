# MongoDB 자동화 도구 파라미터 명세서

## 1. 파라미터 분류 체계

### 1.1 기본 카테고리
- **인프라 파라미터**: 클라우드 리소스 및 네트워크 설정
- **MongoDB 구성 파라미터**: MongoDB 인스턴스 설정 
- **클러스터 파라미터**: 복제 및 샤딩 설정
- **보안 파라미터**: 인증, 인가, 암호화 설정
- **운영 파라미터**: 모니터링, 백업, 유지보수 설정

## 2. 파라미터 구조 설계

### 2.1 계층 구조
```
dbprovision [COMMAND] [OPTIONS]
├── 글로벌 옵션
├── 명령어별 옵션
├── 인프라 관련 옵션
├── MongoDB 관련 옵션
├── 클러스터 관련 옵션
├── 보안 관련 옵션
└── 운영 관련 옵션
```

### 2.2 파라미터 네이밍 규칙
- 케밥 케이스 사용: `--replica-set-name`
- 계층 구조 반영: `--cluster-config-servers`
- 축약형 제공: `-n, --nodes`
- 불린 플래그: `--enable-auth` / `--no-auth`

## 3. 인프라 파라미터

### 3.1 클라우드 환경
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--cloud-provider` | string | O | gcp | 클라우드 제공자 (gcp, aws, azure) |
| `--project-id` | string | O | - | 클라우드 프로젝트 ID |
| `--region` | string | O | - | 배포 리전 |
| `--zones` | array | X | auto | 가용 영역 리스트 |
| `--vpc-name` | string | X | mongodb-vpc | VPC 이름 |
| `--subnet-cidr` | string | X | 10.0.0.0/16 | 서브넷 CIDR |

### 3.2 VM 인스턴스
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--instance-type` | string | X | e2-standard-4 | 인스턴스 타입 |
| `--disk-size` | int | X | 100 | 디스크 크기 (GB) |
| `--disk-type` | string | X | pd-ssd | 디스크 타입 |
| `--ssh-key-path` | string | X | ~/.ssh/id_rsa.pub | SSH 공개키 경로 |
| `--ssh-user` | string | X | ubuntu | SSH 사용자명 |

### 3.3 네트워크
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--mongodb-port` | int | X | 27017 | MongoDB 포트 |
| `--mongos-port` | int | X | 27018 | mongos 포트 (샤딩 시) |
| `--config-port` | int | X | 27019 | Config 서버 포트 |
| `--allowed-cidrs` | array | X | ["0.0.0.0/0"] | 허용된 CIDR 블록 |
| `--private-network` | bool | X | false | 프라이빗 네트워크 사용 |

## 4. MongoDB 구성 파라미터

### 4.1 기본 설정
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--mongodb-version` | string | X | 7.0.18 | MongoDB 버전 |
| `--storage-engine` | string | X | wiredTiger | 스토리지 엔진 |
| `--oplog-size` | int | X | 1024 | Oplog 크기 (MB) |
| `--cache-size` | int | X | auto | WiredTiger 캐시 크기 (MB) |
| `--journal-enabled` | bool | X | true | 저널링 활성화 |

### 4.2 성능 튜닝
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--max-connections` | int | X | 65536 | 최대 연결 수 |
| `--slow-query-threshold` | int | X | 100 | 느린 쿼리 임계값 (ms) |
| `--profiling-level` | int | X | 0 | 프로파일링 레벨 (0-2) |
| `--index-build-retry` | bool | X | true | 인덱스 빌드 재시도 |
| `--read-concern` | string | X | majority | 기본 읽기 관심사 |
| `--write-concern` | string | X | majority | 기본 쓰기 관심사 |

## 5. 클러스터 파라미터

### 5.1 복제 설정
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--cluster-type` | string | O | - | 클러스터 타입 (standalone, replicaset, sharded) |
| `--replica-set-name` | string | X | rs0 | 복제 세트 이름 |
| `--replica-nodes` | int | X | 3 | 복제 노드 수 |
| `--arbiter-nodes` | int | X | 0 | 중재자 노드 수 |
| `--priority-settings` | array | X | - | 노드별 우선순위 설정 |
| `--hidden-nodes` | int | X | 0 | 숨겨진 노드 수 |

### 5.2 샤딩 설정
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--shard-count` | int | X | 2 | 샤드 수 |
| `--shard-nodes` | int | X | 3 | 샤드당 노드 수 |
| `--config-servers` | int | X | 3 | Config 서버 수 |
| `--mongos-count` | int | X | 2 | mongos 인스턴스 수 |
| `--chunk-size` | int | X | 64 | 청크 크기 (MB) |
| `--balancer-enabled` | bool | X | true | 밸런서 활성화 |

## 6. 보안 파라미터

### 6.1 인증 및 인가
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--enable-auth` | bool | X | true | 인증 활성화 |
| `--auth-mechanism` | string | X | SCRAM-SHA-256 | 인증 메커니즘 |
| `--admin-username` | string | X | admin | 관리자 사용자명 |
| `--admin-password` | string | X | - | 관리자 비밀번호 (생성 또는 지정) |
| `--keyfile-path` | string | X | auto | 키파일 경로 |
| `--rbac-enabled` | bool | X | true | RBAC 활성화 |

### 6.2 암호화
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--enable-tls` | bool | X | true | TLS 활성화 |
| `--tls-cert-path` | string | X | auto | TLS 인증서 경로 |
| `--tls-key-path` | string | X | auto | TLS 키 경로 |
| `--tls-ca-path` | string | X | auto | CA 인증서 경로 |
| `--encryption-at-rest` | bool | X | false | 저장 데이터 암호화 |
| `--kmip-server` | string | X | - | KMIP 서버 주소 |

### 6.3 감사 및 로깅
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--audit-enabled` | bool | X | true | 감사 로깅 활성화 |
| `--audit-filter` | string | X | - | 감사 필터 JSON |
| `--log-level` | string | X | info | 로그 레벨 |
| `--log-destination` | string | X | file | 로그 대상 |
| `--log-rotation` | bool | X | true | 로그 로테이션 |

## 7. 운영 파라미터

### 7.1 모니터링
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--monitoring-enabled` | bool | X | true | 모니터링 활성화 |
| `--monitoring-system` | string | X | prometheus | 모니터링 시스템 |
| `--dashboard-type` | string | X | grafana | 대시보드 타입 |
| `--metrics-port` | int | X | 9216 | 메트릭 포트 |
| `--alert-rules` | array | X | default | 알림 규칙 |
| `--notification-webhook` | string | X | - | 알림 웹훅 URL |

### 7.2 백업
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--backup-enabled` | bool | X | true | 백업 활성화 |
| `--backup-schedule` | string | X | 0 2 * * * | 백업 스케줄 (cron) |
| `--backup-type` | string | X | incremental | 백업 타입 |
| `--backup-storage` | string | X | gcs | 백업 스토리지 |
| `--backup-retention` | int | X | 30 | 백업 보관 기간 (일) |
| `--backup-encryption` | bool | X | true | 백업 암호화 |

### 7.3 유지보수
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `--maintenance-window` | string | X | 02:00-04:00 | 유지보수 시간 |
| `--auto-update` | bool | X | false | 자동 업데이트 |
| `--patch-schedule` | string | X | monthly | 패치 스케줄 |
| `--health-check-interval` | int | X | 30 | 헬스체크 간격 (초) |
| `--auto-recovery` | bool | X | true | 자동 복구 |

## 8. 파라미터 관리 방식

### 8.1 우선순위 (높음 → 낮음)
1. 명령행 인자 (CLI arguments)
2. 환경 변수 (Environment variables)
3. 설정 파일 (Configuration file)
4. 기본값 (Default values)

### 8.2 설정 파일 형식
```yaml
# mongodb-config.yaml
cluster:
  type: replicaset
  nodes: 3
  name: rs0

infrastructure:
  cloud_provider: gcp
  project_id: my-project
  region: asia-northeast3
  instance_type: e2-standard-4

mongodb:
  version: "7.0.18"
  storage_engine: wiredTiger
  max_connections: 65536

security:
  enable_auth: true
  enable_tls: true
  auth_mechanism: SCRAM-SHA-256

monitoring:
  enabled: true
  system: prometheus
  dashboard: grafana

backup:
  enabled: true
  schedule: "0 2 * * *"
  type: incremental
```

### 8.3 환경 변수 매핑
```bash
# 파라미터 -> 환경 변수
--cloud-provider     → MONGODB_CLOUD_PROVIDER
--project-id         → MONGODB_PROJECT_ID
--mongodb-version    → MONGODB_VERSION
--enable-auth        → MONGODB_ENABLE_AUTH
--backup-enabled     → MONGODB_BACKUP_ENABLED
```

## 9. 파라미터 검증 규칙

### 9.1 필수 파라미터 검증
- 클러스터 타입별 필수 파라미터 체크
- 클라우드 제공자별 필수 설정 확인
- 보안 설정 조합 유효성 검사

### 9.2 값 범위 검증
- 포트 번호: 1024-65535
- 노드 수: 1-100
- 디스크 크기: 10GB-65TB
- 메모리 설정: 1GB-1TB

### 9.3 상호 의존성 검증
- 샤딩 활성화 시 mongos 인스턴스 필수
- TLS 활성화 시 인증서 파일 필수
- 백업 활성화 시 스토리지 설정 필수

## 10. 사용 예시

### 10.1 기본 복제 세트 구성
```bash
dbprovision create \
  --cluster-type replicaset \
  --replica-nodes 3 \
  --cloud-provider gcp \
  --project-id my-project \
  --region asia-northeast3 \
  --enable-auth \
  --enable-tls \
  --monitoring-enabled \
  --backup-enabled
```

### 10.2 설정 파일 사용
```bash
dbprovision create --config mongodb-config.yaml
```

### 10.3 환경 변수 사용
```bash
export MONGODB_CLOUD_PROVIDER=gcp
export MONGODB_PROJECT_ID=my-project
export MONGODB_ENABLE_AUTH=true
dbprovision create --cluster-type replicaset --replica-nodes 3
```

## 11. 오류 처리 및 도움말

### 11.1 파라미터 오류 처리
- 잘못된 파라미터 값에 대한 명확한 오류 메시지
- 유효한 값 범위 및 형식 안내
- 상호 의존성 위반 시 해결 방법 제시

### 11.2 도움말 시스템
- `--help`: 전체 파라미터 목록
- `--help-category`: 카테고리별 파라미터 설명
- `--example`: 사용 예시 제공
- `--validate`: 파라미터 검증만 실행

## 12. 확장성 고려사항

### 12.1 새로운 파라미터 추가
- 하위 호환성 보장
- 기본값 설정을 통한 안전한 추가
- 단계적 마이그레이션 지원

### 12.2 클라우드 제공자 확장
- 공통 파라미터 인터페이스 유지
- 제공자별 특화 파라미터 네임스페이스
- 자동 변환 및 매핑 지원

이 명세서는 MongoDB 자동화 도구의 파라미터 관리를 위한 완전한 가이드라인을 제공합니다.