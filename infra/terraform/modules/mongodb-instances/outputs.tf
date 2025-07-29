# MongoDB Instances Module Outputs

######
# 인스턴스 정보
######
output "instance_names" {
  description = "Names of created MongoDB instances"
  value       = google_compute_instance.mongodb_instances[*].name
}

output "instance_ids" {
  description = "IDs of created MongoDB instances"
  value       = google_compute_instance.mongodb_instances[*].id
}

output "instance_self_links" {
  description = "Self links of created MongoDB instances"
  value       = google_compute_instance.mongodb_instances[*].self_link
}

######
# IP 주소 정보
######
output "external_ips" {
  description = "External IP addresses of MongoDB instances"
  value       = google_compute_instance.mongodb_instances[*].network_interface[0].access_config[0].nat_ip
}

output "internal_ips" {
  description = "Internal IP addresses of MongoDB instances"
  value       = google_compute_instance.mongodb_instances[*].network_interface[0].network_ip
}

######
# Zone 및 위치 정보
######
output "zones" {
  description = "Zones where instances are deployed"
  value       = google_compute_instance.mongodb_instances[*].zone
}

output "zone_distribution" {
  description = "Map of zones to instance names"
  value = {
    for instance in google_compute_instance.mongodb_instances :
    instance.zone => instance.name...
  }
}

######
# 연결 정보
######
output "connection_strings" {
  description = "MongoDB connection strings for each instance"
  value = [
    for i, instance in google_compute_instance.mongodb_instances :
    "${instance.network_interface[0].network_ip}:${var.mongodb_ports[0]}"
  ]
}

output "replica_set_connection_string" {
  description = "MongoDB replica set connection string"
  value = "mongodb://${join(",", [
    for i, instance in google_compute_instance.mongodb_instances :
    "${instance.network_interface[0].network_ip}:${var.mongodb_ports[0]}"
  ])}/?replicaSet=${var.component_type}RS"
}

######
# SSH 접근 정보
######
output "ssh_commands" {
  description = "SSH commands to connect to each instance"
  value = [
    for instance in google_compute_instance.mongodb_instances :
    "ssh ubuntu@${instance.network_interface[0].access_config[0].nat_ip}"
  ]
}

######
# 네트워크 정보
######
output "subnet_id" {
  description = "ID of the subnet used (or created)"
  value = var.create_dedicated_subnet ? google_compute_subnetwork.mongodb_subnet[0].id : var.subnetwork_id
}

output "subnet_name" {
  description = "Name of the subnet used (or created)"
  value = var.create_dedicated_subnet ? google_compute_subnetwork.mongodb_subnet[0].name : ""
}

output "firewall_rule_names" {
  description = "Names of created firewall rules"
  value = concat(
    [google_compute_firewall.mongodb_internal.name],
    var.allow_external_access ? [google_compute_firewall.mongodb_external[0].name] : []
  )
}

######
# 구성 요약 정보
######
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    component_type  = var.component_type
    instance_count  = var.instance_count
    instance_prefix = var.instance_prefix
    machine_type    = var.machine_type
    zones          = distinct(google_compute_instance.mongodb_instances[*].zone)
    mongodb_ports  = var.mongodb_ports
  }
}

######
# Ansible 인벤토리 생성용 정보
######
output "ansible_inventory" {
  description = "Ansible inventory format information"
  value = {
    group_name = replace(var.component_type, "-", "_")
    hosts = {
      for instance in google_compute_instance.mongodb_instances :
      instance.name => {
        ansible_host = instance.network_interface[0].access_config[0].nat_ip
        internal_ip  = instance.network_interface[0].network_ip
        zone        = instance.zone
      }
    }
  }
}