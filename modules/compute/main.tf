resource "google_compute_instance" "instances" {
  for_each = var.instances

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = each.value.subnetwork

    dynamic "access_config" {
      for_each = each.value.enable_external_ip ? [1] : []
      content {}
    }
  }
  tags = each.value.tags
  labels = each.value.labels
  metadata_startup_script = lookup(each.value, "startup_script", null)

  # Use this block to ignore changes to certain attributes after the instance is created
  # lifecycle {
  #   ignore_changes = [
  #     machine_type,
  #     metadata,
  #     boot_disk[0].initialize_params[0].image,
  #     service_account,
  #   ]
  # }
}