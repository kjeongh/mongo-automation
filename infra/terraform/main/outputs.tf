# 네트워크 모듈 출력값 전달
output "vpc_network" {
  description = "생성된 VPC 네트워크 정보"
  value       = module.network.vpc_network
}

output "subnet" {
  description = "생성된 서브넷 정보"
  value       = module.network.subnet
}

output "firewall_rules" {
  description = "생성된 방화벽 규칙 정보"
  value       = module.network.firewall_rules
}

# MongoDB 인스턴스 모듈 출력값 전달
output "mongodb_instances" {
  description = "생성된 MongoDB 인스턴스 정보"
  value       = module.mongodb_instances.mongodb_instances
}

output "primary_instance" {
  description = "Primary 노드 정보"
  value       = module.mongodb_instances.primary_instance
}

output "secondary_instances" {
  description = "Secondary 노드들 정보"
  value       = module.mongodb_instances.secondary_instances
}

output "arbiter_instances" {
  description = "Arbiter 노드들 정보"
  value       = module.mongodb_instances.arbiter_instances
}

output "connection_info" {
  description = "MongoDB 연결 정보"
  value       = module.mongodb_instances.connection_info
}

output "connection_strings" {
  description = "MongoDB 연결 문자열들"
  value       = module.mongodb_instances.connection_strings
}

output "monitoring_info" {
  description = "모니터링 관련 정보"
  value       = module.mongodb_instances.monitoring_info
}

output "resource_summary" {
  description = "생성된 리소스 요약"
  value       = module.mongodb_instances.resource_summary
}

# 통합 출력 정보
output "replica_set_summary" {
  description = "ReplicaSet 전체 요약 정보"
  value = {
    # 기본 정보
    replica_set_name = var.replica_set_name
    mongodb_version  = var.mongodb_version
    environment      = var.environment
    region           = var.region
    
    # 네트워크 정보
    vpc_name     = module.network.vpc_network.name
    subnet_name  = module.network.subnet.name
    subnet_cidr  = module.network.subnet.ip_cidr_range
    
    # 인스턴스 요약
    total_instances    = module.mongodb_instances.resource_summary.total_instances
    instance_breakdown = module.mongodb_instances.resource_summary.instance_summary
    zones_used         = module.mongodb_instances.resource_summary.zones_used
    total_disk_size_gb = module.mongodb_instances.resource_summary.total_disk_size
    
    # 연결 정보
    internal_connection_string = module.mongodb_instances.connection_strings.internal
    external_connection_string = module.mongodb_instances.connection_strings.external
    
    # 모니터링 정보
    grafana_url    = module.mongodb_instances.monitoring_info.grafana_url
    prometheus_url = module.mongodb_instances.monitoring_info.prometheus_url
  }
}