# Setup vpc networking
module "networking" {
  source = "../../modules/networking"

  project_id   = var.project_id
  routing_mode = "REGIONAL"
  network_name = "${var.name_prefix}-vpc"

  subnets = {
    subnet-01 = {
      subnet_name          = "${var.name_prefix}-asia-southeast-jakarta"
      subnet_ip            = var.subnet_01_ip
      subnet_region        = var.region
      subnet_private_access = true
      secondary_ranges = [
          {
            range_name    = "pods-secondary-range"
            ip_cidr_range = "10.0.0.0/16"
          },
          {
            range_name    = "services-secondary-range"
            ip_cidr_range = "10.1.0.0/20"
          }
        ]
    }
  }

  firewall_rules = {
    allow-ssh = {
      name          = "${var.name_prefix}-vpc-allow-ssh"
      description   = "Allows TCP connections from any source to any instance on the network using port 22."
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["ssh"]
      priority      = 65534
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    }
    allow-rdp = {
      name          = "${var.name_prefix}-vpc-allow-rdp"
      description   = "Allows RDP connections from any source to any instance on the network using port 3389."
      source_ranges = [var.subnet_01_ip]
      target_tags   = ["rdp-server"]
      priority      = 65534
      allow = [{
        protocol = "tcp"
        ports    = ["3389"]
      }]
    }
    allow-custom = {
      name          = "${var.name_prefix}-vpc-allow-custom"
      description   = "Allows connection from any source to any instance on the network using custom protocols."
      source_ranges = [var.subnet_01_ip]
      priority      = 65534
      allow = [{
        protocol = "tcp"
        ports    = ["0-65535"]
      }]
    }
    allow-icmp = {
      name          = "${var.name_prefix}-vpc-allow-icmp"
      description   = "Allows ICMP connections from any source to any instance on the network."
      source_ranges = [var.subnet_01_ip]
      priority      = 65534
      allow = [{
        protocol = "icmp"
      }]
    }
  }

  create_nat = true
  nat_region = var.region
}

module "gke_private_cluster" {
  source = "../../modules/gke-private-cluster"
  project_id                   = var.project_id
  cluster_name                 = "${var.name_prefix}-cluster"
  location                     = var.zone
  network                      = module.networking.network_name
  subnetwork                   = module.networking.subnets["subnet-01"].name
  pods_secondary_range_name    = "pods-secondary-range"
  services_secondary_range_name = "services-secondary-range"
  master_ipv4_cidr_block       = var.master_ipv4_cidr_block
  enable_private_endpoint      = var.enable_private_endpoint
  master_global_access_enabled = var.master_global_access_enabled
  master_authorized_networks   = var.master_authorized_networks
  node_pools = {
    # Default node pool
    default-pool = {
      name         = "default-pool"
      machine_type = "e2-medium"
      disk_size_gb = 50
      autoscaling = {
        min_node_count = 1
        max_node_count = 2
      }
    }
    # Spot node pool
    spot-pool = {
      name         = "spot-pool"
      machine_type = "e2-standard-2"
      spot = true
      disk_size_gb = 50
      autoscaling = {
        min_node_count = 1
        max_node_count = 2
      }
    }
  }
}

# 1) The service account itself (new resource in live/main/ or compute module)
resource "google_service_account" "jump_host" {
  project      = var.project_id
  account_id   = "${var.name_prefix}-jump-host"
  display_name = "Jump host service account"
}

# 2) IAM binding: give it permission to talk to the cluster
resource "google_project_iam_member" "jump_host_cluster_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${google_service_account.jump_host.email}"
}

module "compute" {
  source = "../../modules/compute"

  project_id = var.project_id
  network    = module.networking.network_self_link

  # Add compute instances as needed
  instances = {
    jump-host = {
      name                = "${var.name_prefix}-jump-host"
      machine_type        = "e2-micro"
      zone                = "${var.region}-a"
      subnetwork          = module.networking.subnets["subnet-01"].self_link
      tags                = ["ssh"]
      enable_external_ip  = true
      service_account     = google_service_account.jump_host.email
      scopes              = ["cloud-platform"]
      labels             = {
        role        = "jump-host"
      }
      startup_script      = file("./scripts/jump-host.sh")
      
    }
    # Example for another instance:
    # app-01 = {
    #   name                = "${var.environment}-app-01"
    #   machine_type        = "e2-small"
    #   zone                = "${var.region}-b"
    #   subnetwork          = module.networking.subnets["subnet-01"].self_link
    #   tags                = ["ssh"]
    #   enable_external_ip  = false
    # }
  }
}