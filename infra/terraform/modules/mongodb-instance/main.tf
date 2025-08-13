# Startup script 템플릿
data "template_file" "startup_script" {
  template = file("${path.module}/scripts/mongodb-startup.sh")
  
  vars = {
    mongodb_version     = var.mongodb_version
    replica_set_name    = var.replica_set_name
    mongodb_port        = var.mongodb_port
    keyfile_content     = var.keyfile_content
    root_password       = var.root_password
    auth_enabled        = var.auth_enabled
    backup_enabled      = var.backup_enabled
    backup_schedule     = var.backup_schedule
    backup_retention_days = var.backup_retention_days
  }
}

# MongoDB 인스턴스들
resource "google_compute_instance" "mongodb_instances" {
  for_each = { for member in var.members : member.name => member }

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone

  tags = ["mongodb", var.replica_set_name, "mongodb-${each.value.role}"]

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = each.value.disk_size
      type  = each.value.disk_type
    }
  }

  network_interface {
    network    = var.network_config.network_id
    subnetwork = var.network_config.subnet_id
    
    access_config {
      # 외부 IP 할당
    }
  }

  metadata = {
    mongodb-role        = each.value.role
    mongodb-priority    = each.value.priority
    mongodb-votes       = each.value.votes
    mongodb-arbiter     = each.value.arbiter_only
    mongodb-hidden      = each.value.hidden
    mongodb-slave-delay = each.value.slave_delay
    replica-set-name    = var.replica_set_name
    mongodb-version     = var.mongodb_version
    startup-script      = data.template_file.startup_script.rendered
  }

  service_account {
    email  = var.service_account_email != "" ? var.service_account_email : null
    scopes = ["cloud-platform"]
  }

  labels = merge(var.labels, {
    mongodb-role = each.value.role
    environment  = var.environment
  })

  # 네트워크 리소스에 의존
  depends_on = [
    data.template_file.startup_script
  ]
}