# terraform provider 설정 - google provider
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

# 최신 버전의 google provider사용
provider "google" {
  project = var.project_id
  region  = "asia-northeast3"
  zone    = "asia-northeast3-a"
}

# VPC 생성
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

######
# 서브넷 생성
# 동일 리전 내, 서로 다른 AZ에 배치
######
resource "google_compute_subnetwork" "subnet-a" {
  name          = "subnet-a"
  ip_cidr_range = "10.10.1.0/24"
  region        = "asia-northeast3"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "subnet-b" {
  name          = "subnet-b"
  ip_cidr_range = "10.10.2.0/24"
  region        = "asia-northeast3"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "subnet-c" {
  name          = "subnet-c"
  ip_cidr_range = "10.10.3.0/24"
  region        = "asia-northeast3"
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
    ports    = ["27017"]
  }

  source_ranges = ["0.0.0.0/0"] # 테스트용
}

######
# VM 생성 및 네트워크 구성
# Ubuntu 20.04 LTS
# 각 서브넷에 배치
######

# MongoDB 1번 인스턴스 생성
resource "google_compute_instance" "mongodb-1" {
  name         = "mongodb-1"
  machine_type = "e2-medium"
  zone         = "asia-northeast3-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet-a.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# MongoDB 2번 인스턴스 생성
resource "google_compute_instance" "mongodb-2" {
  name         = "mongodb-2"
  machine_type = "e2-medium"
  zone         = "asia-northeast3-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet-b.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# MongoDB 3번 인스턴스 생성
resource "google_compute_instance" "mongodb-3" {
  name         = "mongodb-3"
  machine_type = "e2-medium"
  zone         = "asia-northeast3-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet-c.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
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

