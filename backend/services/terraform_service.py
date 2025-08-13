import asyncio
import os
import json
import uuid
import subprocess
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from pathlib import Path
import tempfile
import shutil

from backend.models.replica_set import (
    ReplicaSetConfig, ReplicaSetStatus, ReplicaSetCreateRequest,
    ReplicaSetResponse, ReplicaSetStatusResponse, TerraformResource
)
from backend.validators.mongodb_validator import MongoDBVersionValidator

class TerraformService:
    """Terraform을 통한 비동기 ReplicaSet 생성 서비스"""
    
    def __init__(self, 
                 terraform_template_dir: str = "/Users/jhkim/dev/mongo-automation/infra/terraform/replica-set",
                 base_workspace_dir: str = "/tmp/terraform-workspaces"):
        self.terraform_template_dir = Path(terraform_template_dir)
        self.base_workspace_dir = Path(base_workspace_dir)
        self.base_workspace_dir.mkdir(parents=True, exist_ok=True)
        self.job_status = {}  # 작업 상태 저장 (실제로는 Redis 등 사용)
        
    async def create_replica_set(self, request: ReplicaSetCreateRequest) -> ReplicaSetResponse:
        """ReplicaSet 생성 요청 처리"""
        job_id = str(uuid.uuid4())
        config = request.config
        
        # 1. 파라미터 검증
        is_valid, validation_errors = MongoDBVersionValidator.validate_mongodb_version(config)
        if not is_valid:
            return ReplicaSetResponse(
                job_id=job_id,
                replica_set_name=config.replica_set_name,
                status=ReplicaSetStatus.FAILED,
                message=f"검증 실패: {'; '.join(validation_errors)}",
                created_at=datetime.now().isoformat(),
                terraform_workspace=f"{config.replica_set_name}-{job_id[:8]}"
            )
        
        # 2. 작업 상태 초기화
        workspace_name = f"{config.replica_set_name}-{job_id[:8]}"
        self.job_status[job_id] = {
            "job_id": job_id,
            "replica_set_name": config.replica_set_name,
            "status": ReplicaSetStatus.PENDING,
            "progress": 0,
            "message": "작업 대기 중",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "workspace_name": workspace_name,
            "config": config.dict(),
            "terraform_resources": [],
            "estimated_completion_minutes": self._estimate_completion_time(config)
        }
        
        # 3. 백그라운드에서 비동기 실행
        asyncio.create_task(self._execute_terraform_workflow(job_id, request))
        
        # 4. 즉시 응답 반환
        return ReplicaSetResponse(
            job_id=job_id,
            replica_set_name=config.replica_set_name,
            status=ReplicaSetStatus.PENDING,
            message="ReplicaSet 생성 작업이 시작되었습니다",
            created_at=datetime.now().isoformat(),
            estimated_completion_time=f"{self.job_status[job_id]['estimated_completion_minutes']}분",
            terraform_workspace=workspace_name
        )
    
    async def get_job_status(self, job_id: str) -> Optional[ReplicaSetStatusResponse]:
        """작업 상태 조회"""
        if job_id not in self.job_status:
            return None
            
        job_data = self.job_status[job_id]
        
        return ReplicaSetStatusResponse(
            job_id=job_id,
            replica_set_name=job_data["replica_set_name"],
            status=ReplicaSetStatus(job_data["status"]),
            progress=job_data["progress"],
            message=job_data["message"],
            error_details=job_data.get("error_details"),
            created_at=job_data["created_at"],
            updated_at=job_data["updated_at"],
            completed_at=job_data.get("completed_at"),
            terraform_resources=[
                TerraformResource(**resource) for resource in job_data.get("terraform_resources", [])
            ],
            terraform_outputs=job_data.get("terraform_outputs"),
            primary_instance=job_data.get("primary_instance"),
            secondary_instances=job_data.get("secondary_instances"),
            connection_string=job_data.get("connection_string"),
            monitoring_urls=job_data.get("monitoring_urls")
        )
    
    async def _execute_terraform_workflow(self, job_id: str, request: ReplicaSetCreateRequest):
        """Terraform 워크플로우 실행 (백그라운드)"""
        try:
            config = request.config
            workspace_name = self.job_status[job_id]["workspace_name"]
            workspace_dir = self.base_terraform_dir / workspace_name
            
            # 단계 1: 검증
            await self._update_job_status(job_id, ReplicaSetStatus.VALIDATING, 10, "파라미터 검증 중")
            
            # 단계 2: Terraform 워크스페이스 준비
            await self._update_job_status(job_id, ReplicaSetStatus.TERRAFORM_PLANNING, 20, "Terraform 워크스페이스 준비 중")
            await self._prepare_terraform_workspace(workspace_dir, config)
            
            # 단계 3: Terraform Plan
            await self._update_job_status(job_id, ReplicaSetStatus.TERRAFORM_PLANNING, 30, "Terraform Plan 실행 중")
            plan_result = await self._run_terraform_plan(workspace_dir, request.auto_approve)
            
            # 단계 4: Terraform Apply
            await self._update_job_status(job_id, ReplicaSetStatus.TERRAFORM_APPLYING, 50, "인프라 생성 중")
            apply_result = await self._run_terraform_apply(workspace_dir, request.auto_approve)
            
            # Terraform 리소스 정보 수집
            terraform_outputs = await self._get_terraform_outputs(workspace_dir)
            self.job_status[job_id]["terraform_outputs"] = terraform_outputs
            
            # 단계 5: MongoDB 설정
            await self._update_job_status(job_id, ReplicaSetStatus.CONFIGURING_MONGODB, 70, "MongoDB 설정 중")
            await self._configure_mongodb_instances(job_id, config, terraform_outputs)
            
            # 단계 6: ReplicaSet 초기화
            await self._update_job_status(job_id, ReplicaSetStatus.INITIALIZING_REPLICA_SET, 85, "ReplicaSet 초기화 중")
            connection_info = await self._initialize_replica_set(job_id, config, terraform_outputs)
            
            # 단계 7: 완료
            self.job_status[job_id].update({
                "primary_instance": connection_info.get("primary"),
                "secondary_instances": connection_info.get("secondaries", []),
                "connection_string": connection_info.get("connection_string"),
                "monitoring_urls": connection_info.get("monitoring_urls", {})
            })
            
            await self._update_job_status(job_id, ReplicaSetStatus.READY, 100, "ReplicaSet 생성 완료")
            
            # 알림 발송 (옵션)
            if request.notification_webhook or request.notification_email:
                await self._send_completion_notification(job_id, request, success=True)
                
        except Exception as e:
            error_msg = f"ReplicaSet 생성 실패: {str(e)}"
            await self._update_job_status(job_id, ReplicaSetStatus.FAILED, 
                                        self.job_status[job_id]["progress"], 
                                        error_msg, str(e))
            
            # 실패 시 리소스 정리 (옵션)
            if request.destroy_on_failure:
                await self._cleanup_failed_resources(job_id, workspace_name)
            
            # 실패 알림 발송
            if request.notification_webhook or request.notification_email:
                await self._send_completion_notification(job_id, request, success=False)
    
    async def _prepare_terraform_workspace(self, workspace_dir: Path, config: ReplicaSetConfig):
        """기존 Terraform 템플릿을 워크스페이스로 복사하고 변수 파일만 생성"""
        workspace_dir.mkdir(parents=True, exist_ok=True)
        
        # 템플릿 디렉토리에서 모든 .tf 파일과 modules 디렉토리 복사
        if not self.terraform_template_dir.exists():
            raise FileNotFoundError(f"Terraform 템플릿 디렉토리를 찾을 수 없습니다: {self.terraform_template_dir}")
        
        # .tf 파일들 복사
        for tf_file in self.terraform_template_dir.glob("*.tf"):
            shutil.copy2(tf_file, workspace_dir / tf_file.name)
        
        # modules 디렉토리 복사 (terraform/modules를 workspace/modules로)
        terraform_base_dir = self.terraform_template_dir.parent  # terraform/replica-set -> terraform
        modules_source = terraform_base_dir / "modules"
        if modules_source.exists():
            shutil.copytree(modules_source, workspace_dir / "modules", dirs_exist_ok=True)
        
        # terraform.tfvars 파일만 생성 (변수 값들)
        tfvars_content = self._generate_tfvars(config)
        (workspace_dir / "terraform.tfvars").write_text(tfvars_content)
    
    def _generate_tfvars(self, config: ReplicaSetConfig) -> str:
        """terraform.tfvars 파일 내용 생성 (변수 값만)"""
        # 멤버 설정을 Terraform 형식으로 변환
        members_list = []
        for member in config.members:
            members_list.append(f'''  {{
    name         = "{member.name}"
    role         = "{member.role.value}"
    zone         = "{member.zone}"
    machine_type = "{member.machine_type.value}"
    disk_size    = {member.disk_size}
    disk_type    = "{member.disk_type.value}"
    priority     = {member.priority}
    votes        = {member.votes}
    arbiter_only = {str(member.arbiter_only).lower()}
    hidden       = {str(member.hidden).lower()}
    slave_delay  = {member.slave_delay}
  }}''')
        
        # 네트워크 설정
        ssh_sources = '", "'.join(config.network.allowed_sources)
        
        # 라벨 설정
        labels_dict = []
        for key, value in config.labels.items():
            labels_dict.append(f'    {key} = "{value}"')
        labels_str = "{\n" + "\n".join(labels_dict) + "\n  }" if labels_dict else "{}"
        
        return f'''# GCP 기본 설정
project_id  = "{config.project_id}"
region      = "{config.region}"
environment = "prod"

# ReplicaSet 설정
replica_set_name = "{config.replica_set_name}"
mongodb_version  = "{config.mongodb_version.value}"

# 네트워크 설정
subnet_cidr         = "{config.network.subnet_cidr}"
mongodb_port        = {config.network.mongodb_port}
ssh_allowed_sources = ["{ssh_sources}"]

# VM 설정
vm_image               = "ubuntu-os-cloud/ubuntu-2204-lts"
service_account_email  = ""

# MongoDB 멤버 설정
members = [
{",".join(members_list)}
]

# MongoDB 인증 설정
auth_enabled    = {str(config.auth_enabled).lower()}
keyfile_content = "{config.keyfile_content}"
root_password   = "{config.root_password}"

# 백업 설정
backup_enabled       = {str(config.backup_enabled).lower()}
backup_schedule      = "{config.backup_schedule}"
backup_retention_days = {config.backup_retention_days}

# 라벨 설정
labels = {labels_str}
'''
    
    async def _run_terraform_plan(self, workspace_dir: Path, auto_approve: bool) -> Dict[str, Any]:
        """Terraform Plan 실행"""
        result = await self._run_terraform_command(workspace_dir, ["plan", "-out=tfplan"])
        return {"success": result.returncode == 0, "output": result.stdout}
    
    async def _run_terraform_apply(self, workspace_dir: Path, auto_approve: bool) -> Dict[str, Any]:
        """Terraform Apply 실행"""
        cmd = ["apply"]
        if auto_approve:
            cmd.append("-auto-approve")
        else:
            cmd.append("tfplan")
            
        result = await self._run_terraform_command(workspace_dir, cmd)
        return {"success": result.returncode == 0, "output": result.stdout}
    
    async def _run_terraform_command(self, workspace_dir: Path, cmd: List[str]) -> subprocess.CompletedProcess:
        """Terraform 명령어 실행"""
        terraform_cmd = ["terraform"] + cmd
        
        # Terraform 초기화 (필요시)
        init_result = await asyncio.create_subprocess_exec(
            "terraform", "init",
            cwd=workspace_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        await init_result.communicate()
        
        # 실제 명령어 실행
        process = await asyncio.create_subprocess_exec(
            *terraform_cmd,
            cwd=workspace_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        return subprocess.CompletedProcess(
            args=terraform_cmd,
            returncode=process.returncode,
            stdout=stdout.decode() if stdout else "",
            stderr=stderr.decode() if stderr else ""
        )
    
    async def _get_terraform_outputs(self, workspace_dir: Path) -> Dict[str, Any]:
        """Terraform 출력값 조회"""
        result = await self._run_terraform_command(workspace_dir, ["output", "-json"])
        if result.returncode == 0:
            return json.loads(result.stdout)
        return {}
    
    async def _configure_mongodb_instances(self, job_id: str, config: ReplicaSetConfig, terraform_outputs: Dict[str, Any]):
        """MongoDB 인스턴스 설정"""
        # Ansible 플레이북 실행하여 MongoDB 설치 및 설정
        await asyncio.sleep(60)  # MongoDB 설치 시뮬레이션
        
    async def _initialize_replica_set(self, job_id: str, config: ReplicaSetConfig, terraform_outputs: Dict[str, Any]) -> Dict[str, Any]:
        """ReplicaSet 초기화"""
        # MongoDB ReplicaSet 초기화 로직
        await asyncio.sleep(30)  # ReplicaSet 초기화 시뮬레이션
        
        # 연결 정보 생성
        instances = terraform_outputs.get("mongodb_instances", {}).get("value", {})
        primary_host = None
        secondary_hosts = []
        
        for instance_data in instances.values():
            if instance_data["role"] == "primary":
                primary_host = instance_data["internal_ip"]
            else:
                secondary_hosts.append(instance_data["internal_ip"])
        
        return {
            "primary": {"host": primary_host, "port": config.network.mongodb_port},
            "secondaries": [{"host": host, "port": config.network.mongodb_port} for host in secondary_hosts],
            "connection_string": f"mongodb://{primary_host}:{config.network.mongodb_port},{','.join(secondary_hosts)}/?replicaSet={config.replica_set_name}",
            "monitoring_urls": {
                "grafana": f"http://{primary_host}:3000",
                "prometheus": f"http://{primary_host}:9090"
            }
        }
    
    async def _update_job_status(self, job_id: str, status: ReplicaSetStatus, progress: int, message: str, error_details: Optional[str] = None):
        """작업 상태 업데이트"""
        if job_id in self.job_status:
            self.job_status[job_id].update({
                "status": status.value,
                "progress": progress,
                "message": message,
                "updated_at": datetime.now().isoformat(),
                "error_details": error_details
            })
            
            if status in [ReplicaSetStatus.READY, ReplicaSetStatus.FAILED]:
                self.job_status[job_id]["completed_at"] = datetime.now().isoformat()
    
    def _estimate_completion_time(self, config: ReplicaSetConfig) -> int:
        """완료 예상 시간 계산 (분)"""
        base_time = 10  # 기본 10분
        member_time = len(config.members) * 2  # 멤버당 2분
        return base_time + member_time
    
    async def _send_completion_notification(self, job_id: str, request: ReplicaSetCreateRequest, success: bool):
        """완료 알림 발송"""
        # 웹훅 또는 이메일 알림 구현
        pass
    
    async def _cleanup_failed_resources(self, job_id: str, workspace_name: str):
        """실패한 리소스 정리"""
        workspace_dir = self.base_terraform_dir / workspace_name
        if workspace_dir.exists():
            await self._run_terraform_command(workspace_dir, ["destroy", "-auto-approve"])
            shutil.rmtree(workspace_dir)