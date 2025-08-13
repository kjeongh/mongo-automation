from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from enum import Enum
import re

class NodeRole(str, Enum):
    PRIMARY = "primary"
    SECONDARY = "secondary" 
    ARBITER = "arbiter"

class MongoDBVersion(str, Enum):
    V7_0 = "7.0"
    V8_0 = "8.0"

class MachineType(str, Enum):
    E2_MICRO = "e2-micro"
    E2_SMALL = "e2-small" 
    E2_MEDIUM = "e2-medium"
    E2_STANDARD_2 = "e2-standard-2"
    E2_STANDARD_4 = "e2-standard-4"
    N2_STANDARD_2 = "n2-standard-2"
    N2_STANDARD_4 = "n2-standard-4"

class DiskType(str, Enum):
    PD_STANDARD = "pd-standard"
    PD_SSD = "pd-ssd"
    PD_BALANCED = "pd-balanced"

class ReplicaSetMember(BaseModel):
    name: str = Field(..., description="노드 인스턴스 이름")
    role: NodeRole = Field(NodeRole.SECONDARY, description="노드 역할") 
    zone: str = Field(..., description="GCP 가용성 존")
    machine_type: MachineType = Field(MachineType.E2_MEDIUM, description="VM 머신 타입")
    disk_size: int = Field(50, ge=10, le=1000, description="디스크 크기 (GB)")
    disk_type: DiskType = Field(DiskType.PD_SSD, description="디스크 타입")
    
    # MongoDB 전용 설정
    priority: float = Field(1.0, ge=0, le=1000, description="선출 우선순위")
    votes: int = Field(1, ge=0, le=1, description="투표 권한")
    arbiter_only: bool = Field(False, description="아비터 전용 노드 여부")
    hidden: bool = Field(False, description="숨겨진 노드 여부")
    slave_delay: int = Field(0, ge=0, description="복제 지연 시간(초)")
    
    @validator('name')
    def validate_name(cls, v):
        if not re.match(r'^[a-z]([a-z0-9\-]{0,61}[a-z0-9])?$', v):
            raise ValueError('인스턴스 이름은 소문자로 시작하고 소문자, 숫자, -만 포함할 수 있습니다')
        return v
    
    @validator('zone')
    def validate_zone(cls, v):
        if not re.match(r'^[a-z]+-[a-z]+\d+-[a-z]$', v):
            raise ValueError('올바르지 않은 GCP 존 형식입니다 (예: asia-northeast3-a)')
        return v

class NetworkConfig(BaseModel):
    vpc_name: str = Field("mongodb-vpc", description="VPC 네트워크 이름")
    subnet_name: str = Field("mongodb-subnet", description="서브넷 이름")
    subnet_cidr: str = Field("10.0.0.0/24", description="서브넷 CIDR")
    
    # 방화벽 설정
    allow_internal_traffic: bool = Field(True, description="내부 트래픽 허용")
    mongodb_port: int = Field(27017, description="MongoDB 포트")
    allowed_sources: List[str] = Field(default_factory=lambda: ["10.0.0.0/24"], description="허용된 소스 IP/CIDR")

class ReplicaSetConfig(BaseModel):
    replica_set_name: str = Field(..., min_length=1, max_length=50, description="ReplicaSet 이름")
    mongodb_version: MongoDBVersion = Field(MongoDBVersion.V8_0, description="MongoDB 버전")
    members: List[ReplicaSetMember] = Field(..., min_items=3, max_items=50, description="ReplicaSet 멤버 목록")
    
    # GCP 프로젝트 설정
    project_id: str = Field(..., description="GCP 프로젝트 ID")
    region: str = Field("asia-northeast3", description="GCP 리전")
    
    # 네트워크 설정
    network: NetworkConfig = Field(default_factory=NetworkConfig, description="네트워크 설정")
    
    # MongoDB 설정
    auth_enabled: bool = Field(True, description="인증 활성화")
    keyfile_content: Optional[str] = Field(None, description="클러스터 인증 키파일 내용")
    root_password: str = Field(..., min_length=8, description="MongoDB root 패스워드")
    
    # 백업 설정
    backup_enabled: bool = Field(True, description="자동 백업 활성화")
    backup_schedule: str = Field("0 2 * * *", description="백업 스케줄 (cron 형식)")
    backup_retention_days: int = Field(7, ge=1, le=365, description="백업 보존 기간(일)")
    
    # 태그 및 라벨
    labels: Dict[str, str] = Field(default_factory=dict, description="리소스 라벨")
    
    @validator('replica_set_name')
    def validate_replica_set_name(cls, v):
        if not re.match(r'^[a-z][a-z0-9\-]*[a-z0-9]$', v):
            raise ValueError('ReplicaSet 이름은 소문자로 시작/끝나고 소문자, 숫자, -만 포함할 수 있습니다')
        return v
    
    @validator('project_id')  
    def validate_project_id(cls, v):
        if not re.match(r'^[a-z][a-z0-9\-]{4,28}[a-z0-9]$', v):
            raise ValueError('올바르지 않은 GCP 프로젝트 ID 형식입니다')
        return v
    
    @validator('members')
    def validate_members(cls, v):
        if len(v) < 3:
            raise ValueError('ReplicaSet은 최소 3개의 멤버가 필요합니다')
            
        # Primary 노드 검증
        primary_count = sum(1 for member in v if member.role == NodeRole.PRIMARY)
        if primary_count != 1:
            raise ValueError('정확히 1개의 Primary 노드가 필요합니다')
        
        # 총 투표 노드 수는 홀수여야 함
        voting_members = sum(1 for member in v if member.votes > 0)
        if voting_members % 2 == 0:
            raise ValueError('투표권을 가진 멤버 수는 홀수여야 합니다')
        
        # 인스턴스 이름 중복 검사
        names = [member.name for member in v]
        if len(names) != len(set(names)):
            raise ValueError('중복된 인스턴스 이름이 있습니다')
        
        # 존 분산 검사 (권장)
        zones = [member.zone for member in v]
        if len(set(zones)) < 2:
            raise ValueError('고가용성을 위해 최소 2개 이상의 존에 분산 배치하세요')
            
        return v
    
    @validator('keyfile_content')
    def validate_keyfile_content(cls, v, values):
        if values.get('auth_enabled', True) and not v:
            # 자동 생성된 키파일 사용
            import secrets
            import string
            alphabet = string.ascii_letters + string.digits
            return ''.join(secrets.choice(alphabet) for _ in range(756))
        if v and len(v) < 6:
            raise ValueError('keyfile은 최소 6자 이상이어야 합니다')
        return v

class ReplicaSetCreateRequest(BaseModel):
    config: ReplicaSetConfig = Field(..., description="ReplicaSet 설정")
    
    # Terraform 실행 옵션
    auto_approve: bool = Field(False, description="자동 승인 (주의: 프로덕션에서 사용 금지)")
    destroy_on_failure: bool = Field(True, description="실패 시 생성된 리소스 자동 정리")
    
    # 알림 설정
    notification_webhook: Optional[str] = Field(None, description="완료 시 호출할 웹훅 URL")
    notification_email: Optional[str] = Field(None, description="알림 받을 이메일")

class ReplicaSetStatus(str, Enum):
    PENDING = "pending"
    VALIDATING = "validating"
    TERRAFORM_PLANNING = "terraform_planning"
    TERRAFORM_APPLYING = "terraform_applying"
    CONFIGURING_MONGODB = "configuring_mongodb"
    INITIALIZING_REPLICA_SET = "initializing_replica_set"
    READY = "ready"
    FAILED = "failed"
    DESTROYING = "destroying"
    DESTROYED = "destroyed"

class TerraformResource(BaseModel):
    resource_type: str = Field(..., description="리소스 타입")
    resource_name: str = Field(..., description="리소스 이름")
    status: str = Field(..., description="리소스 상태")
    
class ReplicaSetResponse(BaseModel):
    job_id: str = Field(..., description="작업 ID")
    replica_set_name: str = Field(..., description="ReplicaSet 이름")
    status: ReplicaSetStatus = Field(..., description="현재 상태")
    message: str = Field(..., description="상태 메시지")
    created_at: str = Field(..., description="생성 시간")
    estimated_completion_time: Optional[str] = Field(None, description="예상 완료 시간 (분)")
    
    # Terraform 상태
    terraform_workspace: str = Field(..., description="Terraform 워크스페이스")
    
class ReplicaSetStatusResponse(BaseModel):
    job_id: str = Field(..., description="작업 ID")
    replica_set_name: str = Field(..., description="ReplicaSet 이름")
    status: ReplicaSetStatus = Field(..., description="현재 상태")
    progress: int = Field(..., ge=0, le=100, description="진행률(%)")
    message: str = Field(..., description="상태 메시지")
    error_details: Optional[str] = Field(None, description="에러 상세 정보")
    
    # 시간 정보
    created_at: str = Field(..., description="생성 시간")
    updated_at: str = Field(..., description="마지막 업데이트 시간")
    completed_at: Optional[str] = Field(None, description="완료 시간")
    
    # Terraform 상태
    terraform_resources: Optional[List[TerraformResource]] = Field(None, description="생성된 Terraform 리소스 목록")
    terraform_outputs: Optional[Dict[str, Any]] = Field(None, description="Terraform 출력값")
    
    # ReplicaSet 상세 정보 (생성 완료 후)
    primary_instance: Optional[Dict[str, str]] = Field(None, description="Primary 인스턴스 정보")
    secondary_instances: Optional[List[Dict[str, str]]] = Field(None, description="Secondary 인스턴스 목록")
    connection_string: Optional[str] = Field(None, description="MongoDB 연결 문자열")
    monitoring_urls: Optional[Dict[str, str]] = Field(None, description="모니터링 대시보드 URL")

class ReplicaSetListResponse(BaseModel):
    total_count: int = Field(..., description="전체 ReplicaSet 개수")
    replica_sets: List[ReplicaSetStatusResponse] = Field(..., description="ReplicaSet 목록")
    
class ReplicaSetDestroyRequest(BaseModel):
    replica_set_name: str = Field(..., description="삭제할 ReplicaSet 이름")
    force: bool = Field(False, description="강제 삭제 (데이터 백업 무시)")
    backup_before_destroy: bool = Field(True, description="삭제 전 백업 수행")
    
class ReplicaSetDestroyResponse(BaseModel):
    job_id: str = Field(..., description="삭제 작업 ID")
    replica_set_name: str = Field(..., description="ReplicaSet 이름")
    status: str = Field(..., description="삭제 상태")
    message: str = Field(..., description="상태 메시지")
    backup_job_id: Optional[str] = Field(None, description="백업 작업 ID (수행된 경우)")