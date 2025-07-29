# MongoDB Cluster Infrastructure - Base Network Resources
# 기본 네트워크 인프라만 관리 (인스턴스는 mongodb-cluster.tf에서 관리)

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

# Google Provider 설정
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone_a
}

######
# VPC 네트워크 생성
######
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description            = "VPC network for MongoDB cluster"
}

######
# 기본 서브넷들 생성 (호환성 유지용)
# Note: 모듈 기반 배포에서는 각 컴포넌트별 전용 서브넷을 자동 생성
######
resource "google_compute_subnetwork" "subnet-a" {
  name          = "subnet-a"
  ip_cidr_range = var.subnet_a_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  description   = "Legacy subnet for zone A"
}

resource "google_compute_subnetwork" "subnet-b" {
  name          = "subnet-b"
  ip_cidr_range = var.subnet_b_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  description   = "Legacy subnet for zone B"
}

resource "google_compute_subnetwork" "subnet-c" {
  name          = "subnet-c"
  ip_cidr_range = var.subnet_c_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  description   = "Legacy subnet for zone C"
}

######
# 기본 방화벽 규칙 (범용)
######
resource "google_compute_firewall" "mongodb-general" {
  name    = "allow-mongodb-general"
  network = google_compute_network.vpc_network.name
  
  description = "General MongoDB and SSH access"

  allow {
    protocol = "tcp"
    ports    = var.allowed_ports
  }

  source_ranges = var.source_ranges
  target_tags   = ["mongodb"]
}

######
# SSH 접근을 위한 방화벽 규칙
######
resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name
  
  description = "Allow SSH access to all instances"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.source_ranges
  target_tags   = ["mongodb", "config-server", "shard-server", "router"]
}

######
# 기본 출력값들 (네트워크 정보)
######
output "vpc_network" {
  description = "VPC network information"
  value = {
    id   = google_compute_network.vpc_network.id
    name = google_compute_network.vpc_network.name
    self_link = google_compute_network.vpc_network.self_link
  }
}

output "subnets" {
  description = "Created subnets information"
  value = {
    subnet_a = {
      id   = google_compute_subnetwork.subnet-a.id
      name = google_compute_subnetwork.subnet-a.name
      cidr = google_compute_subnetwork.subnet-a.ip_cidr_range
    }
    subnet_b = {
      id   = google_compute_subnetwork.subnet-b.id
      name = google_compute_subnetwork.subnet-b.name
      cidr = google_compute_subnetwork.subnet-b.ip_cidr_range
    }
    subnet_c = {
      id   = google_compute_subnetwork.subnet-c.id
      name = google_compute_subnetwork.subnet-c.name
      cidr = google_compute_subnetwork.subnet-c.ip_cidr_range
    }
  }
}