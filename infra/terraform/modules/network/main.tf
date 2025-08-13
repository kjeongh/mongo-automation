# VPC 네트워크
resource "google_compute_network" "mongodb_vpc" {
  name                    = "${var.replica_set_name}-vpc"
  auto_create_subnetworks = false
  
  labels = var.labels
}

# 서브넷
resource "google_compute_subnetwork" "mongodb_subnet" {
  name          = "${var.replica_set_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.mongodb_vpc.id
}

# 방화벽 규칙 - MongoDB 포트
resource "google_compute_firewall" "mongodb_internal" {
  name    = "${var.replica_set_name}-mongodb-internal"
  network = google_compute_network.mongodb_vpc.name

  allow {
    protocol = "tcp"
    ports    = [tostring(var.mongodb_port)]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["mongodb", var.replica_set_name]
}

# 방화벽 규칙 - SSH
resource "google_compute_firewall" "ssh" {
  name    = "${var.replica_set_name}-ssh"
  network = google_compute_network.mongodb_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_allowed_sources
  target_tags   = ["mongodb", var.replica_set_name]
}

# 방화벽 규칙 - 모니터링 포트
resource "google_compute_firewall" "monitoring" {
  name    = "${var.replica_set_name}-monitoring"
  network = google_compute_network.mongodb_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["9100", "9216"]  # Node Exporter, MongoDB Exporter
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["mongodb", var.replica_set_name]
}