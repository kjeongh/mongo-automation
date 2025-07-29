# MongoDB Instances Module Variables

######
# 필수 변수들
######
variable "instance_prefix" {
  description = "Prefix for instance names (e.g., 'config-server', 'shard-server')"
  type        = string
  
  validation {
    condition = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.instance_prefix))
    error_message = "Instance prefix must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 3
  
  validation {
    condition = var.instance_count > 0 && var.instance_count <= 20
    error_message = "Instance count must be between 1 and 20."
  }
}

variable "component_type" {
  description = "Type of MongoDB component (config-server, shard-server, router)"
  type        = string
  
  validation {
    condition = contains(["config-server", "shard-server", "router", "mongodb"], var.component_type)
    error_message = "Component type must be one of: config-server, shard-server, router, mongodb."
  }
}

variable "component_role" {
  description = "Role of the component for labeling purposes"
  type        = string
  default     = ""
}

variable "zones" {
  description = "List of zones to distribute instances across"
  type        = list(string)
  
  validation {
    condition = length(var.zones) > 0
    error_message = "At least one zone must be specified."
  }
}

variable "network_id" {
  description = "ID of the VPC network"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network (for firewall rules)"
  type        = string
}

######
# 인스턴스 설정
######
variable "machine_type" {
  description = "Machine type for instances"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2004-lts"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
  
  validation {
    condition = var.disk_size >= 10 && var.disk_size <= 1000
    error_message = "Disk size must be between 10 and 1000 GB."
  }
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-ssd"
  
  validation {
    condition = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.disk_type)
    error_message = "Disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

variable "ssh_key_path" {
  description = "Path to SSH public key file"
  type        = string
}

######
# 네트워크 설정
######
variable "subnetwork_id" {
  description = "ID of the subnetwork to use"
  type        = string
  default     = ""
}

variable "create_dedicated_subnet" {
  description = "Whether to create a dedicated subnet for this component"
  type        = bool
  default     = false
}

variable "subnet_cidr" {
  description = "CIDR block for dedicated subnet (if created)"
  type        = string
  default     = ""
}

variable "region" {
  description = "GCP region (required if creating dedicated subnet)"
  type        = string
  default     = ""
}

variable "mongodb_ports" {
  description = "List of MongoDB ports to allow in firewall"
  type        = list(string)
  default     = ["27017"]
}

variable "allow_external_access" {
  description = "Whether to allow external access to MongoDB ports"
  type        = bool
  default     = false
}

variable "internal_source_ranges" {
  description = "Source IP ranges for internal access"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "external_source_ranges" {
  description = "Source IP ranges for external access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

######
# 메타데이터 및 태그
######
variable "base_tags" {
  description = "Base network tags to apply to all instances"
  type        = list(string)
  default     = ["mongodb"]
}

variable "base_labels" {
  description = "Base labels to apply to all instances"
  type        = map(string)
  default = {
    managed-by  = "terraform"
    environment = "production"
  }
}

variable "startup_script" {
  description = "Custom startup script (optional)"
  type        = string
  default     = ""
}

variable "depends_on_resources" {
  description = "List of resources this module depends on"
  type        = list(any)
  default     = []
}