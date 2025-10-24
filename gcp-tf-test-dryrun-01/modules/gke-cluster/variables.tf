variable "project_id" {
  description = "Project that owns the GKE cluster."
  type        = string
}

variable "name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "location" {
  description = "Region or zone for the regional GKE cluster."
  type        = string
}

variable "network" {
  description = "VPC self link the cluster will use."
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self link the cluster will use."
  type        = string
}

variable "pods_secondary_range" {
  description = "Secondary range name on the subnetwork for pod IPs."
  type        = string
}

variable "services_secondary_range" {
  description = "Secondary range name on the subnetwork for service IPs."
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the control plane when private endpoint is enabled."
  type        = string
  default     = null
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)."
  type        = string
  default     = "REGULAR"
}

variable "workload_pool" {
  description = "Workload Identity pool in format <project>.svc.id.goog."
  type        = string
}

variable "master_authorized_networks" {
  description = "List of authorized networks for the control plane endpoint."
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default = []
}

variable "node_pools" {
  description = "Node pool configurations to create after the default pool is removed."
  type = list(object({
    name              = string
    machine_type      = string
    min_count         = number
    max_count         = number
    disk_size_gb      = optional(number, 100)
    disk_type         = optional(string, "pd-balanced")
    image_type        = optional(string, "COS_CONTAINERD")
    spot              = optional(bool, false)
    preemptible       = optional(bool, false)
    auto_upgrade      = optional(bool, true)
    auto_repair       = optional(bool, true)
    service_account   = string
    labels            = optional(map(string), {})
    tags              = optional(list(string), [])
    locations         = optional(list(string), [])
    max_pods_per_node = optional(number, 110)
  }))
  default = []
}

variable "cluster_resource_limits" {
  description = "Cluster autoscaler resource limits definitions."
  type = list(object({
    resource_type = string
    minimum       = number
    maximum       = number
  }))
  default = [
    {
      resource_type = "cpu"
      minimum       = 4
      maximum       = 200
    },
    {
      resource_type = "memory"
      minimum       = 16
      maximum       = 1024
    }
  ]
}

variable "enable_private_nodes" {
  description = "Create private nodes for the cluster."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Expose a private control plane endpoint."
  type        = bool
  default     = false
}

variable "logging_components" {
  description = "Control plane logging components to enable."
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "Monitoring components to enable."
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}
