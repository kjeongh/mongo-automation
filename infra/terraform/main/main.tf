terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 네트워크 모듈 - VPC, 서브넷, 방화벽 규칙들
module "network" {
  source = "../modules/network"
  
  replica_set_name     = var.replica_set_name
  region              = var.region
  subnet_cidr         = var.subnet_cidr
  mongodb_port        = var.mongodb_port
  ssh_allowed_sources = var.ssh_allowed_sources
  labels              = var.labels
}

# MongoDB 인스턴스 모듈 - MongoDB 인스턴스들과 설정
module "mongodb_instances" {
  source = "../modules/mongodb-instance"
  
  replica_set_name      = var.replica_set_name
  mongodb_version       = var.mongodb_version
  environment          = var.environment
  network_config       = module.network.network_config
  mongodb_port         = var.mongodb_port
  vm_image             = var.vm_image
  service_account_email = var.service_account_email
  members              = var.members
  auth_enabled         = var.auth_enabled
  keyfile_content      = var.keyfile_content
  root_password        = var.root_password
  backup_enabled       = var.backup_enabled
  backup_schedule      = var.backup_schedule
  backup_retention_days = var.backup_retention_days
  labels               = var.labels
  
  # 네트워크 모듈 완료 후 인스턴스 생성
  depends_on = [module.network]
}