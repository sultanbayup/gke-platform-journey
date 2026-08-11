variable "project_id" {
  type        = string
  description = "The project ID to deploy resources"
}

variable "network" {
  type        = string
  description = "The self-link of the VPC network"
}

variable "instances" {
  type = map(object({
    name               = string
    machine_type       = string
    zone               = string
    subnetwork         = string
    tags               = list(string)
    labels             = map(string)
    enable_external_ip = bool
    startup_script     = optional(string)
  }))
  description = "Map of instances to create"
  default     = {}
}