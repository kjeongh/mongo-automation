output "vpc_network" {
  description = "생성된 VPC 네트워크 정보"
  value = {
    id           = google_compute_network.mongodb_vpc.id
    name         = google_compute_network.mongodb_vpc.name
    self_link    = google_compute_network.mongodb_vpc.self_link
  }
}

output "subnet" {
  description = "생성된 서브넷 정보"
  value = {
    id            = google_compute_subnetwork.mongodb_subnet.id
    name          = google_compute_subnetwork.mongodb_subnet.name
    ip_cidr_range = google_compute_subnetwork.mongodb_subnet.ip_cidr_range
    region        = google_compute_subnetwork.mongodb_subnet.region
    self_link     = google_compute_subnetwork.mongodb_subnet.self_link
  }
}

output "firewall_rules" {
  description = "생성된 방화벽 규칙 정보"
  value = {
    mongodb_internal = {
      id    = google_compute_firewall.mongodb_internal.id
      name  = google_compute_firewall.mongodb_internal.name
      ports = google_compute_firewall.mongodb_internal.allow[0].ports
    }
    ssh = {
      id    = google_compute_firewall.ssh.id
      name  = google_compute_firewall.ssh.name
      ports = google_compute_firewall.ssh.allow[0].ports
    }
    monitoring = {
      id    = google_compute_firewall.monitoring.id
      name  = google_compute_firewall.monitoring.name
      ports = google_compute_firewall.monitoring.allow[0].ports
    }
  }
}

# MongoDB 인스턴스 모듈에서 사용할 네트워크 정보
output "network_config" {
  description = "MongoDB 인스턴스에서 사용할 네트워크 설정"
  value = {
    network_id    = google_compute_network.mongodb_vpc.id
    subnet_id     = google_compute_subnetwork.mongodb_subnet.id
    subnet_cidr   = google_compute_subnetwork.mongodb_subnet.ip_cidr_range
  }
}