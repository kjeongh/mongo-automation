#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== MongoDB Cluster Provisioning CLI 설치 ==="

# Python 버전 확인
python_version=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1-2)
required_version="3.8"

if [[ $(echo "$python_version >= $required_version" | bc) -eq 0 ]]; then
    echo "Error: Python 3.8 이상이 필요합니다. 현재 버전: $python_version"
    exit 1
fi

# 필수 도구 확인
echo "필수 도구 확인 중..."

if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform이 설치되지 않았습니다."
    echo "설치: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

if ! command -v ansible &> /dev/null; then
    echo "Error: Ansible이 설치되지 않았습니다."
    echo "설치: pip install ansible"
    exit 1
fi

# CLI 패키지 설치
echo "CLI 패키지 설치 중..."
cd "$SCRIPT_DIR"

# 가상환경이 있으면 활성화
if [[ -f "$PROJECT_ROOT/venv/bin/activate" ]]; then
    source "$PROJECT_ROOT/venv/bin/activate"
    echo "가상환경 활성화됨"
fi

# 의존성 설치
pip install -r requirements.txt

# 심볼릭 링크를 통한 전역 설치
if [[ -w "/usr/local/bin" ]]; then
    ln -sf "$SCRIPT_DIR/dbprovision.py" "/usr/local/bin/dbprovision"
    echo "dbprovision 명령어가 /usr/local/bin에 설치되었습니다."
else
    echo "Warning: /usr/local/bin에 쓰기 권한이 없습니다."
    echo "다음 명령어로 수동 설치하세요:"
    echo "sudo ln -sf $SCRIPT_DIR/dbprovision.py /usr/local/bin/dbprovision"
fi

echo ""
echo "=== 설치 완료 ==="
echo ""
echo "사용법:"
echo "  dbprovision create --cluster-type replicaset --replica-nodes 3 --project-id my-project"
echo "  dbprovision status --cluster my-cluster"
echo "  dbprovision health --cluster my-cluster"
echo "  dbprovision destroy --cluster my-cluster"
echo ""
echo "도움말:"
echo "  dbprovision --help"
echo ""

# 설치 테스트
echo "설치 테스트..."
if command -v dbprovision &> /dev/null; then
    dbprovision --help > /dev/null
    echo "✓ 설치가 성공적으로 완료되었습니다!"
else
    echo "⚠ 설치는 완료되었지만 PATH에서 dbprovision을 찾을 수 없습니다."
    echo "  직접 실행: $SCRIPT_DIR/dbprovision.py"
fi