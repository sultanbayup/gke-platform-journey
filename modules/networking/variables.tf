variable "project_id" {
  type        = string
  description = "The project ID to deploy resources"
}

variable "network_name" {
  type        = string
  description = "The name of the VPC network"
}

variable "routing_mode" {
  type        = string
  description = "The network routing mode (GLOBAL or REGIONAL)"
  default     = "GLOBAL"
}

variable "subnets" {
  type = map(object({
    subnet_name           = string
    subnet_ip            = string
    subnet_region        = string
    subnet_private_access = optional(bool)
    secondary_ranges     = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })))
  }))
  description = "The subnets to create"
  default     = {}
}

variable "firewall_rules" {
  type = map(object({
    name          = string
    priority      = optional(number)
    direction     = optional(string)
    source_ranges = optional(list(string))
    source_tags   = optional(list(string))
    target_tags   = optional(list(string))
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
  }))
  description = "Firewall rules to create"
  default     = {}
}

variable "create_nat" {
  type        = bool
  description = "Whether to create Cloud NAT"
  default     = false
}

variable "nat_region" {
  type        = string
  description = "The region for Cloud NAT"
  default     = ""
}