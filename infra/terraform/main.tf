# terraform provider 설정 - google provider
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

# 변수 정의
variable "project_id" {}
variable "region" {}
variable "zone_a" {}
variable "zone_b" {}
variable "zone_c" {}

variable "vpc_name" {}
variable "subnet_a_cidr" {}
variable "subnet_b_cidr" {}
variable "subnet_c_cidr" {}

variable "machine_type" {}
variable "image" {}
variable "ssh_key_path" {}

variable "allowed_ports" {}
variable "source_ranges" {}

# 최신 버전의 google provider사용
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone_a
}

# VPC 생성
resource "google_compute_network" "vpc_network" {
  name = var.vpc_name
}

######
# 서브넷 생성
# 동일 리전 내, 서로 다른 AZ에 배치
######
resource "google_compute_subnetwork" "subnet-a" {
  name          = "subnet-a"
  ip_cidr_range = var.subnet_a_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "subnet-b" {
  name          = "subnet-b"
  ip_cidr_range = var.subnet_b_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "subnet-c" {
  name          = "subnet-c"
  ip_cidr_range = var.subnet_c_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

######
# 방화벽 규칙 설정
######
resource "google_compute_firewall" "mongodb" {
  name    = "allow-mongodb"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = var.allowed_ports
  }

  source_ranges = var.source_ranges
}

######
# VM 생성 및 네트워크 구성
# Ubuntu 20.04 LTS
# 각 서브넷에 배치
######

# MongoDB 1번 인스턴스 생성
resource "google_compute_instance" "mongodb-1" {
  name         = "mongodb-1"
  machine_type = var.machine_type
  zone         = var.zone_a

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet-a.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
  }
}

# MongoDB 2번 인스턴스 생성
resource "google_compute_instance" "mongodb-2" {
  name         = "mongodb-2"
  machine_type = var.machine_type
  zone         = var.zone_b

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet-b.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
  }
}

# MongoDB 3번 인스턴스 생성
resource "google_compute_instance" "mongodb-3" {
  name         = "mongodb-3"
  machine_type = var.machine_type
  zone         = var.zone_c

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet-c.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
  }
}

######
# OUTPUT 정의
# 퍼블릭IP 출력 (각 노드의 IP를 Ansible에서 알기 위함)
######
output "mongo_instance_ips" {
  value = [
    google_compute_instance.mongodb-1.network_interface[0].access_config[0].nat_ip, # NAT IP
    google_compute_instance.mongodb-2.network_interface[0].access_config[0].nat_ip,
    google_compute_instance.mongodb-3.network_interface[0].access_config[0].nat_ip
  ]
}

