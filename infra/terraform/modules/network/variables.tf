variable "replica_set_name" {
  description = "ReplicaSet 이름 (네트워크 리소스 명명에 사용)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9\\-]*[a-z0-9]$", var.replica_set_name))
    error_message = "ReplicaSet 이름은 소문자로 시작/끝나고 소문자, 숫자, -만 포함할 수 있습니다."
  }
}

variable "region" {
  description = "GCP 리전"
  type        = string
}

variable "subnet_cidr" {
  description = "서브넷 CIDR 블록"
  type        = string
  default     = "10.0.0.0/24"
  
  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "올바른 CIDR 형식이 아닙니다."
  }
}

variable "mongodb_port" {
  description = "MongoDB 포트"
  type        = number
  default     = 27017
  
  validation {
    condition     = var.mongodb_port > 1024 && var.mongodb_port < 65535
    error_message = "MongoDB 포트는 1024-65535 범위여야 합니다."
  }
}

variable "ssh_allowed_sources" {
  description = "SSH 접근 허용 소스 IP/CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition = alltrue([
      for cidr in var.ssh_allowed_sources : can(cidrhost(cidr, 0))
    ])
    error_message = "모든 SSH 소스는 올바른 CIDR 형식이어야 합니다."
  }
}

variable "labels" {
  description = "네트워크 리소스에 적용할 라벨"
  type        = map(string)
  default     = {}
}