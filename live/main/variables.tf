variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "name_prefix" {
  description = "Prefix used for resource naming"
  type        = string
}

variable "subnet_01_ip" {
  type        = string
  description = "CIDR range for subnet-01"
}

variable "region" {
  type        = string
  description = "The region to deploy resources"
}

variable "zone" {
  type        = string
  description = "The zone to deploy resources"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "Master IPv4 CIDR block"
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Whether to enable private endpoint"
}

variable "master_global_access_enabled" {
  type        = bool
  description = "Whether master global access is enabled"
}

variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  description = "Master authorized networks"
  default     = []
}

variable "node_pools" {
    type = map(object({
      name         = string
      machine_type = string
    }))
    description = "Node pools configuration"
    default     = {}
  }