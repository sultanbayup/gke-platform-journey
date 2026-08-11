output "instances" {
  description = "Map of instance names to their details"
  value = {
    for k, v in google_compute_instance.instances : k => {
      name                = v.name
      id                  = v.id
      self_link           = v.self_link
      zone                = v.zone
      machine_type        = v.machine_type
      network_interfaces  = v.network_interface
      tags                = v.tags
      labels              = v.labels
    }
  }
}