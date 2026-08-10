output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "The URI of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "Map of subnet names to their details"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => {
      name       = v.name
      id         = v.id
      ip_range   = v.ip_cidr_range
      region     = v.region
      self_link  = v.self_link
    }
  }
}

output "router_name" {
  description = "The name of the router (if created)"
  value       = var.create_nat ? google_compute_router.router[0].name : null
}

output "nat_name" {
  description = "The name of the NAT gateway (if created)"
  value       = var.create_nat ? google_compute_router_nat.nat[0].name : null
}