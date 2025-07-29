# MongoDB Cluster Infrastructure using Modular Approach
# Config Servers, Shard Servers, Routers 통합 관리

######
# Config Servers (3개 인스턴스, 서로 다른 AZ)
######
module "config_servers" {
  source = "./modules/mongodb-instances"

  # 기본 설정
  instance_prefix = "config-server"
  instance_count  = 3
  component_type  = "config-server"
  component_role  = "config-server"
  
  # 인프라 설정
  zones         = [var.zone_a, var.zone_b, var.zone_c]
  machine_type  = var.config_server_machine_type
  disk_size     = var.config_server_disk_size
  disk_type     = var.config_server_disk_type
  image         = var.image
  ssh_key_path  = var.ssh_key_path
  
  # 네트워크 설정
  network_id               = google_compute_network.vpc_network.id
  network_name             = google_compute_network.vpc_network.name
  create_dedicated_subnet  = true
  subnet_cidr             = var.config_server_subnet_cidr
  region                  = var.region
  
  # MongoDB 설정
  mongodb_ports            = ["27019"]
  allow_external_access    = var.config_server_allow_external_access
  internal_source_ranges   = ["10.0.0.0/8"]
  external_source_ranges   = var.source_ranges
  
  # 메타데이터
  base_tags = ["config-server", "mongodb"]
  base_labels = {
    managed-by  = "terraform"
    environment = "production"
    role        = "config-server"
  }
  
  depends_on_resources = [google_compute_network.vpc_network]
}

######
# Shard Servers (3개 샤드 × 3개 인스턴스 = 9개, 교차 배치)
######
module "shard_servers" {
  source = "./modules/mongodb-instances"

  # 기본 설정
  instance_prefix = "shard-server"
  instance_count  = var.shard_count * 3  # 샤드별 3개 인스턴스
  component_type  = "shard-server"
  component_role  = "shard-server"
  
  # 인프라 설정
  zones         = [var.zone_a, var.zone_b, var.zone_c]  # 순환 배치
  machine_type  = var.shard_server_machine_type
  disk_size     = var.shard_server_disk_size
  disk_type     = var.shard_server_disk_type
  image         = var.image
  ssh_key_path  = var.ssh_key_path
  
  # 네트워크 설정
  network_id               = google_compute_network.vpc_network.id
  network_name             = google_compute_network.vpc_network.name
  create_dedicated_subnet  = true
  subnet_cidr             = var.shard_server_subnet_cidr
  region                  = var.region
  
  # MongoDB 설정
  mongodb_ports            = ["27017"]
  allow_external_access    = var.shard_server_allow_external_access
  internal_source_ranges   = ["10.0.0.0/8", var.config_server_subnet_cidr]
  external_source_ranges   = var.source_ranges
  
  # 메타데이터
  base_tags = ["shard-server", "mongodb"]
  base_labels = {
    managed-by  = "terraform"
    environment = "production"
    role        = "shard-server"
  }
  
  depends_on_resources = [google_compute_network.vpc_network]
}

######
# MongoDB Routers (mongos) - 2개 인스턴스
######
module "mongo_routers" {
  source = "./modules/mongodb-instances"

  # 기본 설정
  instance_prefix = "mongo-router"
  instance_count  = var.router_count
  component_type  = "router"
  component_role  = "mongos"
  
  # 인프라 설정
  zones         = [var.zone_a, var.zone_b]  # 2개 Zone에 분산
  machine_type  = var.router_machine_type
  disk_size     = var.router_disk_size
  disk_type     = var.router_disk_type
  image         = var.image
  ssh_key_path  = var.ssh_key_path
  
  # 네트워크 설정
  network_id               = google_compute_network.vpc_network.id
  network_name             = google_compute_network.vpc_network.name
  create_dedicated_subnet  = true
  subnet_cidr             = var.router_subnet_cidr
  region                  = var.region
  
  # MongoDB 설정
  mongodb_ports            = ["27016"]
  allow_external_access    = var.router_allow_external_access
  internal_source_ranges   = ["10.0.0.0/8"]
  external_source_ranges   = var.source_ranges
  
  # 메타데이터
  base_tags = ["mongo-router", "mongodb"]
  base_labels = {
    managed-by  = "terraform"
    environment = "production"
    role        = "mongos"
  }
  
  depends_on_resources = [google_compute_network.vpc_network]
}

######
# 출력 값들
######
output "config_servers" {
  description = "Config server deployment information"
  value = {
    names              = module.config_servers.instance_names
    external_ips       = module.config_servers.external_ips
    internal_ips       = module.config_servers.internal_ips
    zones              = module.config_servers.zones
    connection_string  = module.config_servers.replica_set_connection_string
    ssh_commands       = module.config_servers.ssh_commands
    ansible_inventory  = module.config_servers.ansible_inventory
  }
}

output "shard_servers" {
  description = "Shard server deployment information"
  value = {
    names              = module.shard_servers.instance_names
    external_ips       = module.shard_servers.external_ips
    internal_ips       = module.shard_servers.internal_ips
    zones              = module.shard_servers.zones
    connection_strings = module.shard_servers.connection_strings
    ssh_commands       = module.shard_servers.ssh_commands
    ansible_inventory  = module.shard_servers.ansible_inventory
  }
}

output "mongo_routers" {
  description = "MongoDB router deployment information"
  value = {
    names              = module.mongo_routers.instance_names
    external_ips       = module.mongo_routers.external_ips
    internal_ips       = module.mongo_routers.internal_ips
    zones              = module.mongo_routers.zones
    connection_strings = module.mongo_routers.connection_strings
    ssh_commands       = module.mongo_routers.ssh_commands
    ansible_inventory  = module.mongo_routers.ansible_inventory
  }
}

output "cluster_summary" {
  description = "Complete MongoDB cluster summary"
  value = {
    config_servers = {
      count = length(module.config_servers.instance_names)
      ips   = module.config_servers.internal_ips
    }
    shard_servers = {
      count = length(module.shard_servers.instance_names)
      ips   = module.shard_servers.internal_ips
    }
    routers = {
      count = length(module.mongo_routers.instance_names)
      ips   = module.mongo_routers.internal_ips
    }
    total_instances = (
      length(module.config_servers.instance_names) +
      length(module.shard_servers.instance_names) +
      length(module.mongo_routers.instance_names)
    )
  }
}