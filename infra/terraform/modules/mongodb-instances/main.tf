# MongoDB Instances Module
# 재사용 가능한 MongoDB 인스턴스 생성 모듈

# MongoDB 인스턴스들 생성
resource "google_compute_instance" "mongodb_instances" {
  count        = var.instance_count
  name         = "${var.instance_prefix}-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zones[count.index % length(var.zones)]

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id
    access_config {
      # Ephemeral external IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
    startup-script = var.startup_script != "" ? var.startup_script : <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y docker.io docker-compose
      systemctl start docker
      systemctl enable docker
      usermod -aG docker ubuntu
    EOF
  }

  tags = concat(var.base_tags, [var.component_type])

  labels = merge(var.base_labels, {
    component = var.component_type
    role      = var.component_role
  })

  # 의존성 관리
  depends_on = var.depends_on_resources
}

# 전용 서브넷 생성 (필요한 경우)
resource "google_compute_subnetwork" "mongodb_subnet" {
  count         = var.create_dedicated_subnet ? 1 : 0
  name          = "${var.instance_prefix}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = var.network_id
  
  description = "Subnet for ${var.component_type} instances"
}

# 전용 방화벽 규칙 생성
resource "google_compute_firewall" "mongodb_internal" {
  name    = "allow-${var.instance_prefix}-internal"
  network = var.network_name
  
  description = "Allow internal communication for ${var.component_type}"

  allow {
    protocol = "tcp"
    ports    = var.mongodb_ports
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]  # SSH
  }

  source_ranges = var.internal_source_ranges
  target_tags   = [var.component_type]
}

# 외부 접근용 방화벽 규칙 (선택적)
resource "google_compute_firewall" "mongodb_external" {
  count   = var.allow_external_access ? 1 : 0
  name    = "allow-${var.instance_prefix}-external"
  network = var.network_name
  
  description = "Allow external access to ${var.component_type}"

  allow {
    protocol = "tcp"
    ports    = var.mongodb_ports
  }

  source_ranges = var.external_source_ranges
  target_tags   = [var.component_type]
}