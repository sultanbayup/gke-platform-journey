output "cluster_id" {
  description = "The ID of the cluster"
  value       = google_container_cluster.private_cluster.id
}

output "cluster_name" {
  description = "The name of the cluster"
  value       = google_container_cluster.private_cluster.name
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = google_container_cluster.private_cluster.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = google_container_cluster.private_cluster.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the cluster"
  value       = google_container_cluster.private_cluster.location
}

output "cluster_region" {
  description = "The region of the cluster (for regional clusters)"
  value       = google_container_cluster.private_cluster.location
}

output "cluster_zones" {
  description = "The zones in which the cluster resides"
  value       = google_container_cluster.private_cluster.node_locations
}

output "network" {
  description = "The VPC network of the cluster"
  value       = google_container_cluster.private_cluster.network
}

output "subnetwork" {
  description = "The subnetwork of the cluster"
  value       = google_container_cluster.private_cluster.subnetwork
}

output "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation used for the master network"
  value       = google_container_cluster.private_cluster.private_cluster_config[0].master_ipv4_cidr_block
}

output "master_version" {
  description = "The current version of the master in the cluster"
  value       = google_container_cluster.private_cluster.master_version
}

output "node_pools" {
  description = "Map of node pool details"
  value = {
    for k, v in google_container_node_pool.node_pools : k => {
      name               = v.name
      location           = v.location
      node_count         = v.node_count
      version            = v.version
      instance_group_urls = v.instance_group_urls
      managed_instance_group_urls = v.managed_instance_group_urls
    }
  }
}

output "node_pool_names" {
  description = "List of node pool names"
  value       = [for np in google_container_node_pool.node_pools : np.name]
}

output "workload_identity_pool" {
  description = "The workload identity pool for the cluster"
  value       = "${var.project_id}.svc.id.goog"
}

output "cluster_resource_labels" {
  description = "The resource labels applied to the cluster"
  value       = google_container_cluster.private_cluster.resource_labels
}

output "services_ipv4_cidr" {
  description = "The IP address range of the services IPs in this cluster"
  value       = google_container_cluster.private_cluster.services_ipv4_cidr
}

output "cluster_ipv4_cidr" {
  description = "The IP address range of the pods in this cluster"
  value       = google_container_cluster.private_cluster.cluster_ipv4_cidr
}

output "tpu_ipv4_cidr_block" {
  description = "The IP address range of the Cloud TPUs in this cluster"
  value       = google_container_cluster.private_cluster.tpu_ipv4_cidr_block
}

output "release_channel" {
  description = "The release channel of the cluster"
  value       = google_container_cluster.private_cluster.release_channel[0].channel
}

output "logging_service" {
  description = "The logging service used by the cluster"
  value       = google_container_cluster.private_cluster.logging_service
}

output "monitoring_service" {
  description = "The monitoring service used by the cluster"
  value       = google_container_cluster.private_cluster.monitoring_service
}