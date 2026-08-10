# GKE Private Cluster
resource "google_container_cluster" "private_cluster" {
  name     = var.cluster_name
  location = var.location
  project  = var.project_id
  deletion_protection = false
  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork
  # Private cluster configuration (enforced)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    master_global_access_config {
      enabled = var.master_global_access_enabled
    }
  }
  # IP allocation policy for VPC-native clusters
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }
  # Master authorized networks configuration
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = lookup(cidr_blocks.value, "display_name", null)
        }
      }
    }
  }
  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = !var.http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.horizontal_pod_autoscaling
    }
    network_policy_config {
      disabled = !var.network_policy
    }
    gcp_filestore_csi_driver_config {
      enabled = var.filestore_csi_driver
    }
    gce_persistent_disk_csi_driver_config {
      enabled = var.gce_pd_csi_driver
    }
  }
  # Network policy
  dynamic "network_policy" {
    for_each = var.network_policy ? [1] : []
    content {
      enabled  = true
      provider = "PROVIDER_UNSPECIFIED"
    }
  }
  # Binary authorization
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }
  # Maintenance policy
  dynamic "maintenance_policy" {
    for_each = var.maintenance_window != null ? [1] : []
    content {
      daily_maintenance_window {
        start_time = var.maintenance_window.start_time
      }
    }
  }
  # Release channel
  release_channel {
    channel = var.release_channel
  }
  # Resource labels
  resource_labels = merge(
    var.labels,
    {
      cluster_type = "private"
      managed_by   = "terraform"
    }
  )
  # Cluster autoscaling
  dynamic "cluster_autoscaling" {
    for_each = var.cluster_autoscaling != null ? [1] : []
    content {
      enabled = true
      dynamic "resource_limits" {
        for_each = var.cluster_autoscaling.resource_limits
        content {
          resource_type = resource_limits.value.resource_type
          minimum       = resource_limits.value.minimum
          maximum       = resource_limits.value.maximum
        }
      }
      auto_provisioning_defaults {
        service_account = var.cluster_autoscaling.service_account
        oauth_scopes    = var.cluster_autoscaling.oauth_scopes
      }
    }
  }
  # Logging and monitoring
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service
  # Minimum master version
  min_master_version = var.kubernetes_version
  # Enable shielded nodes
  enable_shielded_nodes = var.enable_shielded_nodes
  # Lifecycle
  lifecycle {
    ignore_changes = [
      initial_node_count,
      node_config,
    ]
  }
  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}
# Node pools
resource "google_container_node_pool" "node_pools" {
  for_each = var.node_pools
  name     = each.value.name
  location = var.location
  cluster  = google_container_cluster.private_cluster.name
  project  = var.project_id
  # Node count configuration
  initial_node_count = lookup(each.value, "initial_node_count", 1)
  # Autoscaling
  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", null) != null ? [each.value.autoscaling] : []
    content {
      min_node_count  = autoscaling.value.min_node_count
      max_node_count  = autoscaling.value.max_node_count
      location_policy = lookup(autoscaling.value, "location_policy", "BALANCED")
    }
  }
  # Management
  management {
    auto_repair  = lookup(each.value, "auto_repair", true)
    auto_upgrade = lookup(each.value, "auto_upgrade", true)
  }
  # Upgrade settings
  upgrade_settings {
    max_surge       = lookup(each.value, "max_surge", 1)
    max_unavailable = lookup(each.value, "max_unavailable", 0)
    strategy        = lookup(each.value, "strategy", "SURGE")
  }
  # Node configuration
  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = lookup(each.value, "disk_size_gb", 100)
    disk_type    = lookup(each.value, "disk_type", "pd-standard")
    image_type   = lookup(each.value, "image_type", "COS_CONTAINERD")
    # Service account
    service_account = lookup(each.value, "service_account", null)
    oauth_scopes = lookup(each.value, "oauth_scopes", [
      "https://www.googleapis.com/auth/cloud-platform"
    ])
    # Metadata
    metadata = merge(
      lookup(each.value, "metadata", {}),
      {
        disable-legacy-endpoints = "true"
      }
    )
    # Labels
    labels = merge(
      lookup(each.value, "labels", {}),
      var.labels,
      {
        cluster_name = var.cluster_name
        node_pool    = each.value.name
      }
    )
    # Tags
    tags = concat(
      coalesce(lookup(each.value, "tags", []), []),
      ["gke-${var.cluster_name}"]
    )
    # Preemptible nodes
    preemptible  = lookup(each.value, "preemptible", false)
    spot         = lookup(each.value, "spot", false)
    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = lookup(each.value, "enable_secure_boot", true)
      enable_integrity_monitoring = lookup(each.value, "enable_integrity_monitoring", true)
    }
    # Taints
    dynamic "taint" {
      for_each = coalesce(lookup(each.value, "taints", []), [])
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
    # Guest accelerator (GPU)
    dynamic "guest_accelerator" {
      for_each = lookup(each.value, "accelerator", null) != null ? [each.value.accelerator] : []
      content {
        type  = guest_accelerator.value.type
        count = guest_accelerator.value.count
        gpu_partition_size = lookup(guest_accelerator.value, "gpu_partition_size", null)
      }
    }
  }
  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}