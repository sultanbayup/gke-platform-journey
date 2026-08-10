variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "location" {
  description = "The location (region or zone) of the cluster"
  type        = string
}

variable "network" {
  description = "The VPC network to host the cluster"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "The name of the secondary range for pods"
  type        = string
}

variable "services_secondary_range_name" {
  description = "The name of the secondary range for services"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation for the master network"
  type        = string
  default     = "172.16.0.0/28"

  validation {
    condition     = can(cidrhost(var.master_ipv4_cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "enable_private_endpoint" {
  description = "Whether the master's internal IP address is used as the cluster endpoint"
  type        = bool
  default     = false
}

variable "master_global_access_enabled" {
  description = "Whether master could be accessed globally"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default = []
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the master and nodes"
  type        = string
  default     = null
}

variable "release_channel" {
  description = "The release channel of this cluster (UNSPECIFIED, RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be one of: UNSPECIFIED, RAPID, REGULAR, STABLE."
  }
}

variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    name               = string
    machine_type       = string
    initial_node_count = optional(number)
    disk_size_gb       = optional(number)
    disk_type          = optional(string)
    image_type         = optional(string)
    auto_repair        = optional(bool)
    auto_upgrade       = optional(bool)
    max_surge          = optional(number)
    max_unavailable    = optional(number)
    strategy           = optional(string)
    service_account    = optional(string)
    oauth_scopes       = optional(list(string))
    metadata           = optional(map(string))
    labels             = optional(map(string))
    tags               = optional(list(string))
    preemptible        = optional(bool)
    spot               = optional(bool)
    enable_secure_boot = optional(bool)
    enable_integrity_monitoring = optional(bool)
    autoscaling = optional(object({
      min_node_count  = number
      max_node_count  = number
      location_policy = optional(string)
    }))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
    accelerator = optional(object({
      type               = string
      count              = number
      gpu_partition_size = optional(string)
    }))
  }))
  default = {}
}

variable "http_load_balancing" {
  description = "Enable HTTP Load Balancing addon"
  type        = bool
  default     = true
}

variable "horizontal_pod_autoscaling" {
  description = "Enable Horizontal Pod Autoscaling addon"
  type        = bool
  default     = true
}

variable "network_policy" {
  description = "Enable Network Policy addon"
  type        = bool
  default     = true
}

variable "filestore_csi_driver" {
  description = "Enable Filestore CSI driver addon"
  type        = bool
  default     = false
}

variable "gce_pd_csi_driver" {
  description = "Enable GCE Persistent Disk CSI driver addon"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = false
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded GKE Nodes"
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    start_time = string
  })
  default = null
}

variable "cluster_autoscaling" {
  description = "Cluster autoscaling configuration"
  type = object({
    resource_limits = list(object({
      resource_type = string
      minimum       = number
      maximum       = number
    }))
    service_account = string
    oauth_scopes    = list(string)
  })
  default = null
}

variable "logging_service" {
  description = "The logging service to use (logging.googleapis.com/kubernetes or none)"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "The monitoring service to use (monitoring.googleapis.com/kubernetes or none)"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}