#!/bin/bash

# MongoDB 설치 및 설정 시작 스크립트
# Terraform에서 template_file로 변수 치환되어 실행

set -euo pipefail

# 로그 설정
LOG_FILE="/var/log/mongodb-startup.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "============================================"
echo "MongoDB ReplicaSet 설정 시작: $(date)"
echo "MongoDB Version: ${mongodb_version}"
echo "ReplicaSet Name: ${replica_set_name}"
echo "============================================"

# 시스템 업데이트
echo "시스템 패키지 업데이트 중..."
apt-get update -y
apt-get upgrade -y

# 필수 패키지 설치
echo "필수 패키지 설치 중..."
apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    jq

# MongoDB 공식 저장소 추가
echo "MongoDB 저장소 추가 중..."
curl -fsSL https://pgp.mongodb.com/server-${mongodb_version}.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-${mongodb_version}.gpg

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${mongodb_version}.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/${mongodb_version} multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-${mongodb_version}.list

# MongoDB 설치
echo "MongoDB ${mongodb_version} 설치 중..."
apt-get update -y
apt-get install -y mongodb-org

# MongoDB 서비스 비활성화 (수동 설정 후 시작)
systemctl stop mongod
systemctl disable mongod

# MongoDB 사용자 및 디렉토리 설정
echo "MongoDB 디렉토리 설정 중..."
mkdir -p /data/db
mkdir -p /data/logs
mkdir -p /data/config
chown -R mongodb:mongodb /data

# MongoDB 설정 파일 생성
echo "MongoDB 설정 파일 생성 중..."
cat > /etc/mongod.conf << 'EOF'
# MongoDB 설정 파일 (ReplicaSet용)
storage:
  dbPath: /data/db
  journal:
    enabled: true
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      journalCompressor: snappy
      directoryForIndexes: false
    collectionConfig:
      blockCompressor: snappy
    indexConfig:
      prefixCompression: true

systemLog:
  destination: file
  logAppend: true
  path: /data/logs/mongod.log
  logRotate: reopen

net:
  port: ${mongodb_port}
  bindIp: 0.0.0.0
  maxIncomingConnections: 1000

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongod.pid
  timeZoneInfo: /usr/share/zoneinfo

replication:
  replSetName: ${replica_set_name}

%{ if auth_enabled }
security:
  authorization: enabled
  keyFile: /data/config/keyfile
%{ endif }

operationProfiling:
  slowOpThresholdMs: 100
  mode: slowOp

setParameter:
  enableLocalhostAuthBypass: false

EOF

%{ if auth_enabled }
# 키파일 생성
echo "클러스터 인증 키파일 생성 중..."
echo "${keyfile_content}" > /data/config/keyfile
chmod 400 /data/config/keyfile
chown mongodb:mongodb /data/config/keyfile
%{ endif }

# 시스템 최적화 설정
echo "시스템 최적화 설정 적용 중..."

# 투명한 큰 페이지 비활성화
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

# 영구 설정을 위한 rc.local 추가
cat >> /etc/rc.local << 'EOF'
# MongoDB 최적화 설정
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
exit 0
EOF
chmod +x /etc/rc.local

# 시스템 리밋 설정
cat >> /etc/security/limits.conf << 'EOF'
# MongoDB 권장 설정
mongodb soft nofile 64000
mongodb hard nofile 64000
mongodb soft nproc 64000
mongodb hard nproc 64000
EOF

# sysctl 설정
cat >> /etc/sysctl.conf << 'EOF'
# MongoDB 최적화 설정
vm.swappiness=1
vm.dirty_ratio=15
vm.dirty_background_ratio=5
net.core.somaxconn=4096
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_time=120
EOF

sysctl -p

# 모니터링 에이전트 설치
echo "모니터링 에이전트 설치 중..."

# Node Exporter 설치
NODE_EXPORTER_VERSION="1.6.1"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar xvfz node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64*

# Node Exporter 서비스 등록
cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
Group=nogroup
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# MongoDB Exporter 설치
MONGODB_EXPORTER_VERSION="0.40.0"
wget https://github.com/percona/mongodb_exporter/releases/download/v$MONGODB_EXPORTER_VERSION/mongodb_exporter-$MONGODB_EXPORTER_VERSION.linux-amd64.tar.gz
tar xvfz mongodb_exporter-$MONGODB_EXPORTER_VERSION.linux-amd64.tar.gz
mv mongodb_exporter-$MONGODB_EXPORTER_VERSION.linux-amd64/mongodb_exporter /usr/local/bin/
rm -rf mongodb_exporter-$MONGODB_EXPORTER_VERSION.linux-amd64*

# MongoDB Exporter 서비스 등록
cat > /etc/systemd/system/mongodb_exporter.service << 'EOF'
[Unit]
Description=MongoDB Exporter
After=network.target mongod.service

[Service]
User=mongodb
Group=mongodb
Type=simple
ExecStart=/usr/local/bin/mongodb_exporter --mongodb.uri=mongodb://localhost:${mongodb_port}
Restart=always
Environment=MONGODB_URI=mongodb://localhost:${mongodb_port}

[Install]
WantedBy=multi-user.target
EOF

# 백업 스크립트 설치 (옵션)
%{ if backup_enabled }
echo "백업 스크립트 설정 중..."
mkdir -p /data/backup/scripts

cat > /data/backup/scripts/mongodb-backup.sh << 'EOF'
#!/bin/bash
# MongoDB 자동 백업 스크립트

BACKUP_DIR="/data/backup/$(date +%Y%m%d)"
RETENTION_DAYS=${backup_retention_days}

mkdir -p $BACKUP_DIR

# 백업 실행
mongodump --host localhost:${mongodb_port} --out $BACKUP_DIR --gzip

# 오래된 백업 정리
find /data/backup -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;
EOF

chmod +x /data/backup/scripts/mongodb-backup.sh
chown -R mongodb:mongodb /data/backup

# 백업 크론 작업 등록
echo "${backup_schedule} mongodb /data/backup/scripts/mongodb-backup.sh" >> /etc/crontab
%{ endif }

# 서비스 시작
echo "서비스 시작 중..."
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

# 모니터링 에이전트 시작
systemctl enable node_exporter
systemctl start node_exporter

# MongoDB가 완전히 시작될 때까지 대기
echo "MongoDB 서비스 시작 대기 중..."
for i in {1..30}; do
    if mongo --host localhost:${mongodb_port} --eval "db.adminCommand('ping')" &> /dev/null; then
        echo "MongoDB 서비스가 시작되었습니다."
        break
    fi
    echo "MongoDB 시작 대기 중... ($i/30)"
    sleep 10
done

%{ if !auth_enabled }
# 인증이 비활성화된 경우 MongoDB Exporter 시작
systemctl enable mongodb_exporter
systemctl start mongodb_exporter
%{ endif }

# 인스턴스 메타데이터에서 역할 정보 가져오기
INSTANCE_METADATA=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/)
MONGODB_ROLE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/mongodb-role)

echo "MongoDB 인스턴스 역할: $MONGODB_ROLE"

# 역할별 초기 설정 정보를 파일로 저장
cat > /data/config/instance-info.json << EOF
{
    "role": "$MONGODB_ROLE",
    "replica_set": "${replica_set_name}",
    "mongodb_version": "${mongodb_version}",
    "setup_completed": "$(date -Iseconds)",
    "mongodb_port": ${mongodb_port}
}
EOF

echo "============================================"
echo "MongoDB 설정 완료: $(date)"
echo "역할: $MONGODB_ROLE"
echo "ReplicaSet: ${replica_set_name}"
echo "포트: ${mongodb_port}"
echo "============================================"