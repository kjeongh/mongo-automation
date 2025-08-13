# ReplicaSet 기본 설정
variable "replica_set_name" {
  description = "ReplicaSet 이름"
  type        = string
}

variable "mongodb_version" {
  description = "MongoDB 버전"
  type        = string
  
  validation {
    condition     = contains(["7.0", "8.0"], var.mongodb_version)
    error_message = "지원하는 MongoDB 버전: 7.0, 8.0"
  }
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# 네트워크 설정 (network 모듈에서 전달받음)
variable "network_config" {
  description = "네트워크 모듈에서 전달받은 네트워크 설정"
  type = object({
    network_id  = string
    subnet_id   = string
    subnet_cidr = string
  })
}

variable "mongodb_port" {
  description = "MongoDB 포트"
  type        = number
  default     = 27017
}

# VM 설정
variable "vm_image" {
  description = "VM 부팅 이미지"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "service_account_email" {
  description = "VM에서 사용할 서비스 계정 이메일"
  type        = string
  default     = ""
}

# MongoDB 멤버 설정
variable "members" {
  description = "MongoDB ReplicaSet 멤버 설정"
  type = list(object({
    name         = string
    role         = string  # primary, secondary, arbiter
    zone         = string
    machine_type = string
    disk_size    = number
    disk_type    = string
    priority     = number
    votes        = number
    arbiter_only = bool
    hidden       = bool
    slave_delay  = number
  }))
  
  validation {
    condition     = length(var.members) >= 3
    error_message = "ReplicaSet은 최소 3개의 멤버가 필요합니다."
  }
  
  validation {
    condition = length([
      for member in var.members : member
      if member.role == "primary"
    ]) == 1
    error_message = "정확히 1개의 Primary 노드가 필요합니다."
  }
}

# MongoDB 인증 설정
variable "auth_enabled" {
  description = "MongoDB 인증 활성화"
  type        = bool
  default     = true
}

variable "keyfile_content" {
  description = "MongoDB 클러스터 인증 키파일 내용"
  type        = string
  sensitive   = true
}

variable "root_password" {
  description = "MongoDB root 사용자 패스워드"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.root_password) >= 8
    error_message = "Root 패스워드는 최소 8자 이상이어야 합니다."
  }
}

# 백업 설정
variable "backup_enabled" {
  description = "자동 백업 활성화"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "백업 스케줄 (cron 형식)"
  type        = string
  default     = "0 2 * * *"  # 매일 오전 2시
}

variable "backup_retention_days" {
  description = "백업 보존 기간 (일)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "백업 보존 기간은 1-365일 범위여야 합니다."
  }
}

# 라벨 및 태그
variable "labels" {
  description = "인스턴스에 적용할 라벨"
  type        = map(string)
  default     = {}
}