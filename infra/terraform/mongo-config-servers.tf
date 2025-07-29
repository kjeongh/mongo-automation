# MongoDB Config Server Infrastructure
# Config Server ReplicaSet 구성을 위한 인프라 셋업

######
# Config Server 전용 변수
######

variable "config_server_subnet_cidr" {
  description = "CIDR block for config server subnet"
  type        = string
  default     = "10.0.10.0/24"
}

variable "config_server_machine_type" {
  description = "Machine type for config servers"
  type        = string
  default     = "e2-medium"
}

######
# Config Server 전용 서브넷 생성
######
resource "google_compute_subnetwork" "config-server-subnet" {
  name          = "config-server-subnet"
  ip_cidr_range = var.config_server_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  
  description = "Subnet for MongoDB Config Servers"
}

######
# Config Server 전용 방화벽 규칙
######
resource "google_compute_firewall" "config-servers" {
  name    = "allow-config-servers"
  network = google_compute_network.vpc_network.name
  
  description = "Allow MongoDB Config Server traffic"

  allow {
    protocol = "tcp"
    ports    = ["27019"]  # Config Server 포트
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]     # SSH 포트
  }

  source_ranges = [
    var.config_server_subnet_cidr,  # Config Server 간 통신
    "10.0.0.0/8"                    # 내부 네트워크 통신
  ]
  
  target_tags = ["config-server"]
}

# 외부에서 Config Server 접근을 위한 방화벽 (필요시)
resource "google_compute_firewall" "config-servers-external" {
  name    = "allow-config-servers-external"
  network = google_compute_network.vpc_network.name
  
  description = "Allow external access to Config Servers"

  allow {
    protocol = "tcp"
    ports    = ["27019"]
  }

  source_ranges = var.source_ranges
  target_tags   = ["config-server"]
}

######
# Config Server VM 인스턴스들 (서로 다른 Zone에 배치)
######

# Config Server 1 (Zone A)
resource "google_compute_instance" "config-server-1" {
  name         = "config-server-1"
  machine_type = var.config_server_machine_type
  zone         = var.zone_a

  boot_disk {
    initialize_params {
      image = var.image
      size  = 20  # Config Server는 상대적으로 적은 저장공간 필요
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.config-server-subnet.id
    access_config {
      # Ephemeral external IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y docker.io docker-compose
      systemctl start docker
      systemctl enable docker
      usermod -aG docker ubuntu
    EOF
  }

  tags = ["config-server", "mongodb"]

  labels = {
    environment = "production"
    role        = "config-server"
    node        = "1"
  }
}

# Config Server 2 (Zone B)
resource "google_compute_instance" "config-server-2" {
  name         = "config-server-2"
  machine_type = var.config_server_machine_type
  zone         = var.zone_b

  boot_disk {
    initialize_params {
      image = var.image
      size  = 20
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.config-server-subnet.id
    access_config {
      # Ephemeral external IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y docker.io docker-compose
      systemctl start docker
      systemctl enable docker
      usermod -aG docker ubuntu
    EOF
  }

  tags = ["config-server", "mongodb"]

  labels = {
    environment = "production"
    role        = "config-server"
    node        = "2"
  }
}

# Config Server 3 (Zone C)
resource "google_compute_instance" "config-server-3" {
  name         = "config-server-3"
  machine_type = var.config_server_machine_type
  zone         = var.zone_c

  boot_disk {
    initialize_params {
      image = var.image
      size  = 20
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.config-server-subnet.id
    access_config {
      # Ephemeral external IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y docker.io docker-compose
      systemctl start docker
      systemctl enable docker
      usermod -aG docker ubuntu
    EOF
  }

  tags = ["config-server", "mongodb"]

  labels = {
    environment = "production"
    role        = "config-server"
    node        = "3"
  }
}

######
# Config Server 출력 값들
######
output "config_server_external_ips" {
  description = "External IP addresses of config servers"
  value = [
    google_compute_instance.config-server-1.network_interface[0].access_config[0].nat_ip,
    google_compute_instance.config-server-2.network_interface[0].access_config[0].nat_ip,
    google_compute_instance.config-server-3.network_interface[0].access_config[0].nat_ip
  ]
}

output "config_server_internal_ips" {
  description = "Internal IP addresses of config servers"
  value = [
    google_compute_instance.config-server-1.network_interface[0].network_ip,
    google_compute_instance.config-server-2.network_interface[0].network_ip,
    google_compute_instance.config-server-3.network_interface[0].network_ip
  ]
}

output "config_server_zones" {
  description = "Zones where config servers are deployed"
  value = [var.zone_a, var.zone_b, var.zone_c]
}

output "config_server_subnet" {
  description = "Subnet where config servers are deployed"
  value = google_compute_subnetwork.config-server-subnet.name
}

output "config_server_connection_string" {
  description = "MongoDB config server connection string"
  value = "mongodb://${join(",", [
    "${google_compute_instance.config-server-1.network_interface[0].network_ip}:27019",
    "${google_compute_instance.config-server-2.network_interface[0].network_ip}:27019",
    "${google_compute_instance.config-server-3.network_interface[0].network_ip}:27019"
  ])}/?replicaSet=csRS"
}