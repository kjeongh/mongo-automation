# MongoDB Cluster Variables for Modular Approach

######
# 클러스터 구성 변수
######
variable "shard_count" {
  description = "Number of shards to create"
  type        = number
  default     = 3
  
  validation {
    condition = var.shard_count >= 1 && var.shard_count <= 10
    error_message = "Shard count must be between 1 and 10."
  }
}

variable "router_count" {
  description = "Number of mongos routers to create"
  type        = number
  default     = 2
  
  validation {
    condition = var.router_count >= 1 && var.router_count <= 5
    error_message = "Router count must be between 1 and 5."
  }
}

######
# Config Server 변수
######
variable "config_server_machine_type" {
  description = "Machine type for config servers"
  type        = string
  default     = "e2-medium"
}

variable "config_server_disk_size" {
  description = "Disk size in GB for config servers"
  type        = number
  default     = 20
}

variable "config_server_disk_type" {
  description = "Disk type for config servers"
  type        = string
  default     = "pd-ssd"
}

variable "config_server_subnet_cidr" {
  description = "CIDR block for config server subnet"
  type        = string
  default     = "10.0.10.0/24"
}

variable "config_server_allow_external_access" {
  description = "Whether to allow external access to config servers"
  type        = bool
  default     = false
}

######
# Shard Server 변수
######
variable "shard_server_machine_type" {
  description = "Machine type for shard servers"
  type        = string
  default     = "e2-standard-4"
}

variable "shard_server_disk_size" {
  description = "Disk size in GB for shard servers"
  type        = number
  default     = 100
}

variable "shard_server_disk_type" {
  description = "Disk type for shard servers"
  type        = string
  default     = "pd-ssd"
}

variable "shard_server_subnet_cidr" {
  description = "CIDR block for shard server subnet"
  type        = string
  default     = "10.0.20.0/24"
}

variable "shard_server_allow_external_access" {
  description = "Whether to allow external access to shard servers"
  type        = bool
  default     = false
}

######
# Router (mongos) 변수
######
variable "router_machine_type" {
  description = "Machine type for MongoDB routers"
  type        = string
  default     = "e2-standard-2"
}

variable "router_disk_size" {
  description = "Disk size in GB for MongoDB routers"
  type        = number
  default     = 20
}

variable "router_disk_type" {
  description = "Disk type for MongoDB routers"
  type        = string
  default     = "pd-ssd"
}

variable "router_subnet_cidr" {
  description = "CIDR block for router subnet"
  type        = string
  default     = "10.0.30.0/24"
}

variable "router_allow_external_access" {
  description = "Whether to allow external access to routers"
  type        = bool
  default     = true
}

######
# MongoDB 설정 변수
######
variable "mongodb_version" {
  description = "MongoDB version to use"
  type        = string
  default     = "8.0"
  
  validation {
    condition = contains(["7.0", "8.0"], var.mongodb_version)
    error_message = "MongoDB version must be 7.0 or 8.0."
  }
}

variable "replica_set_config" {
  description = "Replica set configuration for each shard"
  type = object({
    primary_priority   = number
    secondary_priority = number
    arbiter_priority   = number
  })
  default = {
    primary_priority   = 2
    secondary_priority = 1
    arbiter_priority   = 0
  }
}

######
# 환경 및 라벨링 변수
######
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "production"
  
  validation {
    condition = contains(["dev", "development", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, development, staging, prod, production."
  }
}

variable "project_name" {
  description = "Project name for labeling"
  type        = string
  default     = "mongodb-cluster"
}

variable "team" {
  description = "Team responsible for the cluster"
  type        = string
  default     = "devops"
}

variable "additional_tags" {
  description = "Additional network tags to apply to all instances"
  type        = list(string)
  default     = []
}

variable "additional_labels" {
  description = "Additional labels to apply to all instances"
  type        = map(string)
  default     = {}
}

######
# 백업 및 모니터링 변수
######
variable "enable_backup" {
  description = "Whether to enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Whether to enable monitoring agents"
  type        = bool
  default     = true
}

variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    prometheus_port = number
    grafana_port   = number
    alert_email    = string
  })
  default = {
    prometheus_port = 9090
    grafana_port   = 3000
    alert_email    = "admin@example.com"
  }
}

######
# 보안 변수
######
variable "enable_ssl" {
  description = "Whether to enable SSL/TLS encryption"
  type        = bool
  default     = true
}

variable "ssl_cert_path" {
  description = "Path to SSL certificate file"
  type        = string
  default     = ""
}

variable "enable_auth" {
  description = "Whether to enable MongoDB authentication"
  type        = bool
  default     = true
}

variable "keyfile_content" {
  description = "Content of MongoDB keyfile for cluster authentication"
  type        = string
  default     = ""
  sensitive   = true
}

######
# 성능 튜닝 변수
######
variable "wiredtiger_cache_size_gb" {
  description = "WiredTiger cache size in GB (0 = auto)"
  type        = number
  default     = 0
}

variable "enable_compression" {
  description = "Whether to enable compression"
  type        = bool
  default     = true
}

variable "compression_algorithm" {
  description = "Compression algorithm to use"
  type        = string
  default     = "snappy"
  
  validation {
    condition = contains(["snappy", "lz4", "zstd", "none"], var.compression_algorithm)
    error_message = "Compression algorithm must be one of: snappy, lz4, zstd, none."
  }
}

######
# 고급 설정 변수
######
variable "custom_startup_script" {
  description = "Custom startup script for MongoDB instances"
  type        = string
  default     = ""
}

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day_of_week = string
    hour        = number
    minute      = number
  })
  default = {
    day_of_week = "sunday"
    hour        = 2
    minute      = 0
  }
}

variable "auto_scaling_config" {
  description = "Auto scaling configuration for future use"
  type = object({
    enabled     = bool
    min_nodes   = number
    max_nodes   = number
    cpu_target  = number
  })
  default = {
    enabled     = false
    min_nodes   = 3
    max_nodes   = 9
    cpu_target  = 70
  }
}