resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode           = var.routing_mode
  project                = var.project_id
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name                     = each.value.subnet_name
  ip_cidr_range           = each.value.subnet_ip
  region                  = each.value.subnet_region
  network                 = google_compute_network.vpc.id
  private_ip_google_access = lookup(each.value, "subnet_private_access", true)
  project                 = var.project_id

  dynamic "secondary_ip_range" {
    for_each = coalesce(lookup(each.value, "secondary_ranges", []), [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

resource "google_compute_firewall" "rules" {
  for_each = var.firewall_rules

  name    = each.value.name
  network = google_compute_network.vpc.name
  project = var.project_id

  priority  = lookup(each.value, "priority", 1000)
  direction = lookup(each.value, "direction", "INGRESS")

  source_ranges = lookup(each.value, "source_ranges", null)
  source_tags   = lookup(each.value, "source_tags", null)
  target_tags   = lookup(each.value, "target_tags", null)

  dynamic "allow" {
    for_each = coalesce(lookup(each.value, "allow", []), [])
    content {
      protocol = allow.value.protocol
      ports    = lookup(allow.value, "ports", null)
    }
  }

  dynamic "deny" {
    for_each = coalesce(lookup(each.value, "deny", []), [])
    content {
      protocol = deny.value.protocol
      ports    = lookup(deny.value, "ports", null)
    }
  }
}

resource "google_compute_router" "router" {
  count   = var.create_nat ? 1 : 0
  name    = "${var.network_name}-router"
  network = google_compute_network.vpc.id
  region  = var.nat_region
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  count  = var.create_nat ? 1 : 0
  name   = "${var.network_name}-nat"
  router = google_compute_router.router[0].name
  region = var.nat_region
  project = var.project_id

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}