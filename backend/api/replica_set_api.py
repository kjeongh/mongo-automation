from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends, status
from fastapi.responses import JSONResponse
from typing import List, Optional
import logging

from backend.models.replica_set import (
    ReplicaSetCreateRequest, ReplicaSetResponse, ReplicaSetStatusResponse,
    ReplicaSetListResponse, ReplicaSetDestroyRequest, ReplicaSetDestroyResponse
)
from backend.services.terraform_service import TerraformService
from backend.validators.mongodb_validator import MongoDBVersionValidator

# 로거 설정
logger = logging.getLogger(__name__)

# 라우터 생성
router = APIRouter(prefix="/api/replica-sets", tags=["ReplicaSet 관리"])

# 의존성: TerraformService 인스턴스
def get_terraform_service() -> TerraformService:
    return TerraformService()

@router.post("/", 
             response_model=ReplicaSetResponse,
             status_code=status.HTTP_202_ACCEPTED,
             summary="ReplicaSet 생성",
             description="MongoDB ReplicaSet을 Terraform을 통해 GCP에 비동기적으로 생성합니다.")
async def create_replica_set(
    request: ReplicaSetCreateRequest,
    terraform_service: TerraformService = Depends(get_terraform_service)
) -> ReplicaSetResponse:
    """
    MongoDB ReplicaSet 생성 요청을 받아 비동기적으로 처리합니다.
    
    - **즉시 응답**: 작업 ID와 함께 202 Accepted 상태로 응답
    - **백그라운드 처리**: Terraform을 통한 인프라 생성 및 MongoDB 설정
    - **상태 추적**: GET /jobs/{job_id} 엔드포인트로 진행 상황 확인 가능
    
    **지원 MongoDB 버전**: 7.0, 8.0만 지원
    """
    try:
        logger.info(f"ReplicaSet 생성 요청: {request.config.replica_set_name}")
        
        # ReplicaSet 생성 처리
        response = await terraform_service.create_replica_set(request)
        
        logger.info(f"ReplicaSet 생성 작업 시작: job_id={response.job_id}")
        return response
        
    except ValueError as e:
        logger.error(f"입력 값 오류: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"입력 값 오류: {str(e)}"
        )
    except Exception as e:
        logger.error(f"ReplicaSet 생성 요청 처리 실패: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"서버 내부 오류: {str(e)}"
        )

@router.get("/jobs/{job_id}",
            response_model=ReplicaSetStatusResponse,
            summary="작업 상태 조회",
            description="ReplicaSet 생성/삭제 작업의 진행 상황을 조회합니다.")
async def get_job_status(
    job_id: str,
    terraform_service: TerraformService = Depends(get_terraform_service)
) -> ReplicaSetStatusResponse:
    """
    작업 ID로 ReplicaSet 생성/삭제 작업의 상태를 조회합니다.
    
    **응답 정보**:
    - 현재 상태 (pending, creating, ready, failed 등)
    - 진행률 (0-100%)
    - 상세 메시지 및 에러 정보
    - 생성된 리소스 정보 (완료 시)
    """
    try:
        status_response = await terraform_service.get_job_status(job_id)
        
        if not status_response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"작업 ID를 찾을 수 없습니다: {job_id}"
            )
        
        logger.info(f"작업 상태 조회: job_id={job_id}, status={status_response.status}")
        return status_response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"작업 상태 조회 실패: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"서버 내부 오류: {str(e)}"
        )

@router.get("/",
            response_model=ReplicaSetListResponse,
            summary="ReplicaSet 목록 조회",
            description="현재 생성된 모든 ReplicaSet의 목록을 조회합니다.")
async def list_replica_sets(
    status_filter: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    terraform_service: TerraformService = Depends(get_terraform_service)
) -> ReplicaSetListResponse:
    """
    생성된 ReplicaSet 목록을 조회합니다.
    
    **쿼리 파라미터**:
    - status_filter: 상태별 필터링 (ready, creating, failed 등)
    - limit: 반환할 최대 항목 수 (기본값: 50)
    - offset: 시작 오프셋 (기본값: 0)
    """
    try:
        # 모든 작업 상태 조회 (실제로는 데이터베이스에서 조회)
        all_jobs = []
        for job_id in terraform_service.job_status.keys():
            job_status = await terraform_service.get_job_status(job_id)
            if job_status:
                if not status_filter or job_status.status == status_filter:
                    all_jobs.append(job_status)
        
        # 페이징 적용
        total_count = len(all_jobs)
        paginated_jobs = all_jobs[offset:offset + limit]
        
        return ReplicaSetListResponse(
            total_count=total_count,
            replica_sets=paginated_jobs
        )
        
    except Exception as e:
        logger.error(f"ReplicaSet 목록 조회 실패: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"서버 내부 오류: {str(e)}"
        )

@router.delete("/{replica_set_name}",
               response_model=ReplicaSetDestroyResponse,
               status_code=status.HTTP_202_ACCEPTED,
               summary="ReplicaSet 삭제",
               description="지정된 ReplicaSet을 삭제합니다.")
async def destroy_replica_set(
    replica_set_name: str,
    request: ReplicaSetDestroyRequest,
    terraform_service: TerraformService = Depends(get_terraform_service)
) -> ReplicaSetDestroyResponse:
    """
    ReplicaSet을 삭제합니다.
    
    **주의사항**:
    - 기본적으로 삭제 전 자동 백업이 수행됩니다
    - force=true 옵션 사용 시 백업 없이 즉시 삭제됩니다
    - 삭제는 비동기적으로 처리되며 작업 상태를 추적할 수 있습니다
    """
    try:
        logger.info(f"ReplicaSet 삭제 요청: {replica_set_name}")
        
        # TODO: 삭제 로직 구현
        # 1. 기존 ReplicaSet 존재 여부 확인
        # 2. 백업 수행 (옵션에 따라)
        # 3. Terraform destroy 실행
        
        return ReplicaSetDestroyResponse(
            job_id="delete-job-id",
            replica_set_name=replica_set_name,
            status="pending",
            message="ReplicaSet 삭제 작업이 시작되었습니다",
            backup_job_id="backup-job-id" if request.backup_before_destroy else None
        )
        
    except Exception as e:
        logger.error(f"ReplicaSet 삭제 요청 실패: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"서버 내부 오류: {str(e)}"
        )

@router.get("/{replica_set_name}/connection",
            summary="연결 정보 조회",
            description="ReplicaSet의 연결 문자열 및 접속 정보를 조회합니다.")
async def get_connection_info(
    replica_set_name: str,
    terraform_service: TerraformService = Depends(get_terraform_service)
) -> dict:
    """
    ReplicaSet의 연결 정보를 조회합니다.
    
    **응답 정보**:
    - MongoDB 연결 문자열
    - Primary/Secondary 노드 정보
    - 포트 및 인증 정보
    """
    try:
        # ReplicaSet 이름으로 해당 작업 찾기
        target_job = None
        for job_id, job_data in terraform_service.job_status.items():
            if job_data.get("replica_set_name") == replica_set_name:
                target_job = await terraform_service.get_job_status(job_id)
                break
        
        if not target_job or target_job.status != "ready":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"실행 중인 ReplicaSet을 찾을 수 없습니다: {replica_set_name}"
            )
        
        return {
            "replica_set_name": replica_set_name,
            "connection_string": target_job.connection_string,
            "primary_instance": target_job.primary_instance,
            "secondary_instances": target_job.secondary_instances,
            "monitoring_urls": target_job.monitoring_urls
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"연결 정보 조회 실패: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"서버 내부 오류: {str(e)}"
        )

@router.get("/versions",
            summary="지원 MongoDB 버전 조회",
            description="현재 지원하는 MongoDB 버전 목록을 조회합니다.")
async def get_supported_versions() -> dict:
    """
    지원하는 MongoDB 버전 및 권장사항을 조회합니다.
    """
    try:
        return {
            "supported_versions": [version.value for version in MongoDBVersionValidator.get_supported_versions()],
            "recommended_version": MongoDBVersionValidator.get_recommended_version().value,
            "version_info": {
                "7.0": {
                    "features": ["Compound Wildcard Index", "Bulkwrite API"],
                    "min_requirements": {"memory_gb": 2, "disk_gb": 20}
                },
                "8.0": {
                    "features": ["Sharded Time Series", "Density-based Outlier Detection", "Range Deletion"],
                    "min_requirements": {"memory_gb": 4, "disk_gb": 20},
                    "recommended": True
                }
            }
        }
        
    except Exception as e:
        logger.error(f"버전 정보 조회 실패: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"서버 내부 오류: {str(e)}"
        )

@router.post("/validate",
             summary="설정 검증",
             description="ReplicaSet 생성 전 설정을 검증합니다.")
async def validate_configuration(request: ReplicaSetCreateRequest) -> dict:
    """
    ReplicaSet 설정을 사전 검증합니다.
    
    **검증 항목**:
    - MongoDB 버전 호환성
    - 머신 타입 및 리소스 요구사항
    - 네트워크 구성
    - 보안 설정
    """
    try:
        logger.info(f"설정 검증 요청: {request.config.replica_set_name}")
        
        is_valid, messages = MongoDBVersionValidator.validate_mongodb_version(request.config)
        
        return {
            "valid": is_valid,
            "messages": messages,
            "estimated_cost": {
                "monthly_usd": len(request.config.members) * 50,  # 대략적인 비용
                "currency": "USD"
            },
            "estimated_completion_time_minutes": 10 + len(request.config.members) * 2
        }
        
    except Exception as e:
        logger.error(f"설정 검증 실패: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"서버 내부 오류: {str(e)}"
        )

# 헬스체크 엔드포인트
@router.get("/health",
            summary="서비스 상태 확인",
            description="ReplicaSet 서비스의 상태를 확인합니다.")
async def health_check():
    """서비스 상태 확인"""
    return {
        "status": "healthy",
        "service": "replica-set-api",
        "version": "1.0.0"
    }