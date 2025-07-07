# MongoCraft Backend API

MongoDB 자동화 플랫폼의 백엔드 API 서버입니다.

## 기술 스택

- **Python**: 3.10+
- **Framework**: FastAPI
- **ASGI Server**: Uvicorn
- **Validation**: Pydantic v2
- **Environment**: python-dotenv

## 프로젝트 구조

```
backend/
├── app/
│   ├── api/
│   │   └── api_v1/
│   │       ├── endpoints/
│   │       │   ├── health.py      # 헬스체크 엔드포인트
│   │       │   └── clusters.py    # 클러스터 관리 엔드포인트
│   │       └── api.py             # API 라우터 설정
│   ├── core/
│   │   └── config.py              # 설정 관리
│   ├── models/                    # 데이터 모델
│   ├── services/                  # 비즈니스 로직
│   ├── utils/                     # 유틸리티 함수
│   └── main.py                    # FastAPI 애플리케이션
├── requirements.txt
├── pyproject.toml
└── .env.example
```

## 설치 및 실행

### 1. 가상환경 설정 (Python 3.10)

```bash
# pyenv 사용 시
pyenv install 3.10.12
pyenv local 3.10.12

# 또는 python3.10 직접 사용
python3.10 -m venv venv
source venv/bin/activate  # Windows: venv\\Scripts\\activate
```

### 2. 의존성 설치

```bash
cd backend
pip install -r requirements.txt
```

### 3. 환경변수 설정

```bash
cp .env.example .env
# .env 파일을 편집하여 필요한 설정값 입력
```

### 4. 개발 서버 실행

```bash
# 기본 실행
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 또는 Python 모듈로 실행
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API 문서

서버 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/api/v1/openapi.json

## 주요 엔드포인트

### 기본 엔드포인트
- `GET /` - 서비스 정보
- `GET /health` - 기본 헬스체크

### API v1 엔드포인트
- `GET /api/v1/health/` - 상세 헬스체크
- `GET /api/v1/health/ready` - 준비상태 체크
- `GET /api/v1/clusters/` - 클러스터 목록 조회
- `GET /api/v1/clusters/{cluster_id}` - 특정 클러스터 조회
- `POST /api/v1/clusters/` - 클러스터 생성 (placeholder)
- `DELETE /api/v1/clusters/{cluster_id}` - 클러스터 삭제 (placeholder)

## 개발 도구

### 코드 포맷팅 및 린팅

```bash
# Black (코드 포맷팅)
pip install black
black app/

# isort (import 정렬)
pip install isort
isort app/

# flake8 (린팅)
pip install flake8
flake8 app/

# mypy (타입 체킹)
pip install mypy
mypy app/
```

### 테스트

```bash
# pytest 설치 및 실행
pip install pytest pytest-asyncio
pytest
```

## 환경 설정

### 주요 환경변수

- `ENVIRONMENT`: 실행 환경 (development/staging/production)
- `DEBUG`: 디버그 모드 (True/False)
- `HOST`: 서버 호스트 (기본값: 0.0.0.0)
- `PORT`: 서버 포트 (기본값: 8000)
- `SECRET_KEY`: JWT 토큰 서명용 시크릿 키
- `BACKEND_CORS_ORIGINS`: CORS 허용 오리진 (쉼표로 구분)

### CORS 설정

프론트엔드 개발 서버와의 연동을 위해 다음 오리진이 기본 허용됩니다:
- http://localhost:3000 (React 기본)
- http://localhost:5173 (Vite 기본)

## 향후 개발 계획

1. **데이터베이스 연동** - PostgreSQL/MongoDB 설정
2. **인증/인가** - JWT 기반 사용자 인증
3. **클러스터 관리** - 실제 MongoDB 클러스터 CRUD
4. **모니터링** - 클러스터 상태 모니터링
5. **배포 자동화** - Terraform/Ansible 연동
6. **보안 강화** - API 키, 암호화, 감사 로그

## 라이센스

MIT License