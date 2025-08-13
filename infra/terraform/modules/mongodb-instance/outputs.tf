output "mongodb_instances" {
  description = "생성된 MongoDB 인스턴스 정보"
  value = {
    for k, v in google_compute_instance.mongodb_instances : k => {
      name         = v.name
      internal_ip  = v.network_interface[0].network_ip
      external_ip  = v.network_interface[0].access_config[0].nat_ip
      zone         = v.zone
      machine_type = v.machine_type
      role         = v.metadata.mongodb-role
      priority     = v.metadata.mongodb-priority
      votes        = v.metadata.mongodb-votes
      disk_size    = v.boot_disk[0].initialize_params[0].size
      disk_type    = v.boot_disk[0].initialize_params[0].type
    }
  }
}

output "primary_instance" {
  description = "Primary 노드 정보"
  value = {
    for k, v in google_compute_instance.mongodb_instances : k => {
      name        = v.name
      internal_ip = v.network_interface[0].network_ip
      external_ip = v.network_interface[0].access_config[0].nat_ip
      zone        = v.zone
    }
    if v.metadata.mongodb-role == "primary"
  }
}

output "secondary_instances" {
  description = "Secondary 노드들 정보"
  value = {
    for k, v in google_compute_instance.mongodb_instances : k => {
      name        = v.name
      internal_ip = v.network_interface[0].network_ip
      external_ip = v.network_interface[0].access_config[0].nat_ip
      zone        = v.zone
    }
    if v.metadata.mongodb-role == "secondary"
  }
}

output "arbiter_instances" {
  description = "Arbiter 노드들 정보"
  value = {
    for k, v in google_compute_instance.mongodb_instances : k => {
      name        = v.name
      internal_ip = v.network_interface[0].network_ip
      external_ip = v.network_interface[0].access_config[0].nat_ip
      zone        = v.zone
    }
    if v.metadata.mongodb-role == "arbiter"
  }
}

output "connection_info" {
  description = "MongoDB 연결 정보"
  value = {
    replica_set_name = var.replica_set_name
    mongodb_port     = var.mongodb_port
    
    # Primary 호스트 (첫 번째 primary만)
    primary_host = [
      for k, v in google_compute_instance.mongodb_instances :
      v.network_interface[0].network_ip
      if v.metadata.mongodb-role == "primary"
    ][0]
    
    # Secondary 호스트들
    secondary_hosts = [
      for k, v in google_compute_instance.mongodb_instances :
      v.network_interface[0].network_ip
      if v.metadata.mongodb-role == "secondary"
    ]
    
    # 전체 호스트 목록 (연결 문자열용)
    all_hosts = [
      for k, v in google_compute_instance.mongodb_instances :
      "${v.network_interface[0].network_ip}:${var.mongodb_port}"
      if v.metadata.mongodb-role != "arbiter"
    ]
  }
}

output "connection_strings" {
  description = "MongoDB 연결 문자열들"
  value = {
    # 내부 IP 기반 연결 문자열
    internal = "mongodb://${join(",", [
      for k, v in google_compute_instance.mongodb_instances :
      "${v.network_interface[0].network_ip}:${var.mongodb_port}"
      if v.metadata.mongodb-role != "arbiter"
    ])}/?replicaSet=${var.replica_set_name}"
    
    # 외부 IP 기반 연결 문자열 (개발/테스트용)
    external = "mongodb://${join(",", [
      for k, v in google_compute_instance.mongodb_instances :
      "${v.network_interface[0].access_config[0].nat_ip}:${var.mongodb_port}"
      if v.metadata.mongodb-role != "arbiter"
    ])}/?replicaSet=${var.replica_set_name}"
  }
}

output "monitoring_info" {
  description = "모니터링 관련 정보"
  value = {
    node_exporter_targets = [
      for k, v in google_compute_instance.mongodb_instances :
      "${v.network_interface[0].network_ip}:9100"
    ]
    
    mongodb_exporter_targets = [
      for k, v in google_compute_instance.mongodb_instances :
      "${v.network_interface[0].network_ip}:9216"
    ]
    
    grafana_url = "http://${[
      for k, v in google_compute_instance.mongodb_instances :
      v.network_interface[0].access_config[0].nat_ip
      if v.metadata.mongodb-role == "primary"
    ][0]}:3000"
    
    prometheus_url = "http://${[
      for k, v in google_compute_instance.mongodb_instances :
      v.network_interface[0].access_config[0].nat_ip
      if v.metadata.mongodb-role == "primary"
    ][0]}:9090"
  }
}

output "resource_summary" {
  description = "생성된 리소스 요약"
  value = {
    total_instances = length(google_compute_instance.mongodb_instances)
    
    instance_summary = {
      primary   = length([for k, v in google_compute_instance.mongodb_instances : k if v.metadata.mongodb-role == "primary"])
      secondary = length([for k, v in google_compute_instance.mongodb_instances : k if v.metadata.mongodb-role == "secondary"])
      arbiter   = length([for k, v in google_compute_instance.mongodb_instances : k if v.metadata.mongodb-role == "arbiter"])
    }
    
    zones_used = distinct([
      for k, v in google_compute_instance.mongodb_instances : v.zone
    ])
    
    machine_types_used = distinct([
      for k, v in google_compute_instance.mongodb_instances : v.machine_type
    ])
    
    total_disk_size = sum([
      for k, v in google_compute_instance.mongodb_instances : tonumber(v.boot_disk[0].initialize_params[0].size)
    ])
  }
}