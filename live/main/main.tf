# Setup vpc networking
module "networking" {
  source = "../../modules/networking"

  project_id   = var.project_id
  routing_mode = "REGIONAL"
  network_name = "${var.vpc_name}-vpc"

  subnets = {
    subnet-01 = {
      subnet_name          = "${var.vpc_name}-asia-southeast-jakarta"
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
      name          = "${var.vpc_name}-vpc-allow-ssh"
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
      name          = "${var.vpc_name}-vpc-allow-rdp"
      description   = "Allows RDP connections from any source to any instance on the network using port 3389."
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["rdp-server"]
      priority      = 65534
      allow = [{
        protocol = "tcp"
        ports    = ["3389"]
      }]
    }
    allow-custom = {
      name          = "${var.vpc_name}-vpc-allow-custom"
      description   = "Allows connection from any source to any instance on the network using custom protocols."
      source_ranges = [var.subnet_01_ip]
      priority      = 65534
      allow = [{
        protocol = "tcp"
        ports    = ["0-65535"]
      }]
    }
    allow-icmp = {
      name          = "${var.vpc_name}-vpc-allow-icmp"
      description   = "Allows ICMP connections from any source to any instance on the network."
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
  cluster_name                 = var.cluster_name
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
    default = {
      name         = "default-pool"
      machine_type = "e2-medium"
      disk_size_gb = 50
      autoscaling = {
        min_node_count = 1
        max_node_count = 2
      }
    }
    # Spot node pool
    spot = {
      name         = "spot-pool"
      machine_type = "e2-standard-2"
      spot = true
      disk_size_gb = 50
      initial_node_count = 1
      autoscaling = {
        min_node_count = 1
        max_node_count = 2
      }
    }
  }
}