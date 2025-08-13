from typing import List, Dict, Any, Tuple
from backend.models.replica_set import MongoDBVersion, MachineType, ReplicaSetConfig
import re

class MongoDBVersionValidator:
    """MongoDB 버전별 검증 및 호환성 체크 (v7.0, v8.0만 지원)"""
    
    # MongoDB 버전별 최소 요구사항 (7.0, 8.0만)
    VERSION_REQUIREMENTS = {
        MongoDBVersion.V7_0: {
            "min_memory_gb": 2,
            "min_disk_gb": 20,
            "supported_machine_types": [
                MachineType.E2_MEDIUM, MachineType.E2_STANDARD_2, MachineType.E2_STANDARD_4,
                MachineType.N2_STANDARD_2, MachineType.N2_STANDARD_4
            ],
            "max_replica_set_size": 50,
            "deprecated": False,
            "security_features": ["SCRAM-SHA-256", "x.509", "LDAP", "Queryable Encryption"],
            "storage_engines": ["WiredTiger"],
            "new_features": ["Compound Wildcard Index", "Bulkwrite API"]
        },
        MongoDBVersion.V8_0: {
            "min_memory_gb": 4,
            "min_disk_gb": 20,
            "supported_machine_types": [
                MachineType.E2_STANDARD_2, MachineType.E2_STANDARD_4,
                MachineType.N2_STANDARD_2, MachineType.N2_STANDARD_4
            ],
            "max_replica_set_size": 50,
            "deprecated": False,
            "security_features": ["SCRAM-SHA-256", "x.509", "LDAP", "Queryable Encryption", "Range Deletion"],
            "storage_engines": ["WiredTiger"],
            "new_features": ["Sharded Time Series", "Density-based Outlier Detection"],
            "recommended": True
        }
    }
    
    # 머신 타입별 스펙 정보
    MACHINE_TYPE_SPECS = {
        MachineType.E2_MEDIUM: {"cpu": 2, "memory_gb": 4},
        MachineType.E2_STANDARD_2: {"cpu": 2, "memory_gb": 8},
        MachineType.E2_STANDARD_4: {"cpu": 4, "memory_gb": 16},
        MachineType.N2_STANDARD_2: {"cpu": 2, "memory_gb": 8},
        MachineType.N2_STANDARD_4: {"cpu": 4, "memory_gb": 16}
    }

    @classmethod
    def validate_mongodb_version(cls, config: ReplicaSetConfig) -> Tuple[bool, List[str]]:
        """MongoDB 버전 및 설정 종합 검증"""
        errors = []
        warnings = []
        
        version = config.mongodb_version
        
        # 지원하지 않는 버전 체크
        if version not in [MongoDBVersion.V7_0, MongoDBVersion.V8_0]:
            errors.append(f"지원하지 않는 MongoDB 버전: {version}. 지원 버전: 7.0, 8.0")
            return False, errors
            
        version_req = cls.VERSION_REQUIREMENTS[version]
        
        # 1. 머신 타입 호환성 검증
        for member in config.members:
            if member.machine_type not in version_req["supported_machine_types"]:
                errors.append(
                    f"MongoDB {version}은 머신 타입 {member.machine_type}을 지원하지 않습니다. "
                    f"지원 타입: {version_req['supported_machine_types']}"
                )
                
            # 메모리 요구사항 검증
            machine_spec = cls.MACHINE_TYPE_SPECS.get(member.machine_type)
            if machine_spec and machine_spec["memory_gb"] < version_req["min_memory_gb"]:
                errors.append(
                    f"MongoDB {version}은 최소 {version_req['min_memory_gb']}GB 메모리가 필요합니다. "
                    f"{member.machine_type}는 {machine_spec['memory_gb']}GB만 제공합니다."
                )
                
            # 디스크 요구사항 검증
            if member.disk_size < version_req["min_disk_gb"]:
                errors.append(
                    f"MongoDB {version}은 최소 {version_req['min_disk_gb']}GB 디스크가 필요합니다. "
                    f"노드 {member.name}의 디스크 크기: {member.disk_size}GB"
                )
        
        # 2. ReplicaSet 크기 검증
        if len(config.members) > version_req["max_replica_set_size"]:
            errors.append(
                f"MongoDB {version}은 최대 {version_req['max_replica_set_size']}개의 멤버를 지원합니다. "
                f"요청된 멤버 수: {len(config.members)}"
            )
        
        # 3. 버전별 특별 검증
        version_specific_errors = cls._validate_version_specific(config, version)
        errors.extend(version_specific_errors)
        
        # 4. 성능 최적화 권고사항
        performance_warnings = cls._get_performance_recommendations(config, version)
        warnings.extend(performance_warnings)
        
        return len(errors) == 0, errors + [f"WARNING: {w}" for w in warnings]

    @classmethod
    def _validate_version_specific(cls, config: ReplicaSetConfig, version: MongoDBVersion) -> List[str]:
        """버전별 특별 검증 로직"""
        errors = []
        
        if version == MongoDBVersion.V7_0:
            # Compound Wildcard Index는 더 많은 CPU 필요
            for member in config.members:
                machine_spec = cls.MACHINE_TYPE_SPECS.get(member.machine_type)
                if machine_spec and machine_spec["cpu"] < 2:
                    errors.append(
                        f"MongoDB 7.0의 새로운 인덱싱 기능 사용 시 최소 2 vCPU 권장. "
                        f"노드 {member.name}: {machine_spec['cpu']} vCPU"
                    )
                    
        elif version == MongoDBVersion.V8_0:
            # MongoDB 8.0은 더 엄격한 요구사항
            if len(config.members) > 7:
                errors.append("MongoDB 8.0에서 7개 이상의 멤버 구성 시 추가 네트워크 최적화 필요")
            
            # Range Deletion 기능을 위한 디스크 성능 권고
            for member in config.members:
                if member.disk_type.value == "pd-standard":
                    errors.append(
                        f"MongoDB 8.0의 성능 최적화를 위해 SSD 디스크(pd-ssd) 사용 권장. "
                        f"노드 {member.name}: {member.disk_type}"
                    )
        
        return errors

    @classmethod
    def _get_performance_recommendations(cls, config: ReplicaSetConfig, version: MongoDBVersion) -> List[str]:
        """성능 최적화 권고사항"""
        recommendations = []
        
        # 1. 존 분산 최적화
        zones = [member.zone for member in config.members]
        unique_zones = set(zones)
        if len(unique_zones) < 3 and len(config.members) >= 3:
            recommendations.append(
                f"고가용성을 위해 3개 이상의 가용성 존에 분산 배치 권장. 현재: {len(unique_zones)}개 존"
            )
        
        # 2. 디스크 타입 최적화
        standard_disk_count = sum(1 for member in config.members if member.disk_type.value == "pd-standard")
        if standard_disk_count > 0:
            recommendations.append(
                f"성능 향상을 위해 SSD 디스크(pd-ssd 또는 pd-balanced) 사용 권장. "
                f"표준 디스크 사용 노드: {standard_disk_count}개"
            )
        
        # 3. 메모리 최적화
        total_memory = 0
        for member in config.members:
            machine_spec = cls.MACHINE_TYPE_SPECS.get(member.machine_type)
            if machine_spec:
                total_memory += machine_spec["memory_gb"]
        
        if total_memory < 24:  # ReplicaSet 전체 메모리가 24GB 미만
            recommendations.append(
                f"대용량 데이터 처리를 위해 총 메모리 24GB 이상 권장. 현재: {total_memory}GB"
            )
        
        # 4. MongoDB 8.0 권장
        if version == MongoDBVersion.V7_0:
            recommendations.append("최신 기능 및 성능 향상을 위해 MongoDB 8.0 사용 권장")
        
        return recommendations

    @classmethod
    def get_supported_versions(cls) -> List[MongoDBVersion]:
        """지원하는 MongoDB 버전 목록 반환"""
        return [MongoDBVersion.V7_0, MongoDBVersion.V8_0]

    @classmethod
    def get_recommended_version(cls) -> MongoDBVersion:
        """권장 MongoDB 버전 반환"""
        return MongoDBVersion.V8_0

    @classmethod
    def suggest_optimal_configuration(cls, data_size_estimate: str = "small") -> Dict[str, Any]:
        """최적 구성 제안"""
        
        configs = {
            "small": {
                "mongodb_version": MongoDBVersion.V8_0,
                "machine_type": MachineType.E2_STANDARD_2,
                "disk_size": 50,
                "member_count": 3
            },
            "medium": {
                "mongodb_version": MongoDBVersion.V8_0, 
                "machine_type": MachineType.E2_STANDARD_2,
                "disk_size": 100,
                "member_count": 3
            },
            "large": {
                "mongodb_version": MongoDBVersion.V8_0,
                "machine_type": MachineType.E2_STANDARD_4,
                "disk_size": 200,
                "member_count": 5
            }
        }
        
        return configs.get(data_size_estimate, configs["medium"])