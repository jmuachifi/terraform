variable "project_id" {
  description = "Google Cloud project ID for the production environment."
  type        = string
}

variable "region" {
  description = "Primary region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "cluster_location" {
  description = "Region or zone where the GKE cluster will run."
  type        = string
  default     = "us-central1"
}

variable "network_name" {
  description = "Name of the VPC to create."
  type        = string
  default     = "gke-prod-shared-vpc"
}

variable "subnets" {
  description = "Subnet definitions for the environment."
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    secondary_ip_ranges = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
  default = [
    {
      name          = "gke-prod-subnet"
      ip_cidr_range = "10.128.0.0/20"
      region        = "us-central1"
      secondary_ip_ranges = [
        {
          range_name    = "gke-prod-pods"
          ip_cidr_range = "10.144.0.0/18"
        },
        {
          range_name    = "gke-prod-services"
          ip_cidr_range = "10.160.0.0/24"
        }
      ]
    }
  ]
}

variable "pods_secondary_range_name" {
  description = "Secondary range name used for pod IPs."
  type        = string
  default     = "gke-prod-pods"
}

variable "services_secondary_range_name" {
  description = "Secondary range name used for service IPs."
  type        = string
  default     = "gke-prod-services"
}

variable "master_ipv4_cidr_block" {
  description = "CIDR reserved for the GKE control plane; keep null to let Google manage it."
  type        = string
  default     = null
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "STABLE"
}

variable "node_pools" {
  description = "Node pool definitions for the cluster."
  type = list(object({
    name            = string
    machine_type    = string
    min_count       = number
    max_count       = number
    disk_size_gb    = optional(number, 150)
    spot            = optional(bool, false)
    preemptible     = optional(bool, false)
    auto_upgrade    = optional(bool, true)
    auto_repair     = optional(bool, true)
    service_account = string
    labels          = optional(map(string), {})
    tags            = optional(list(string), [])
    locations       = optional(list(string), [])
  }))
  default = []
}

variable "enable_private_nodes" {
  description = "Whether the cluster should use private nodes."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Whether to expose the private control plane endpoint."
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "Authorized networks for the control plane endpoint."
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default = []
}

variable "logging_components" {
  description = "Control plane logging components."
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "Control plane monitoring components."
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "APISERVER", "SCHEDULER"]
}

variable "workload_identity_pool" {
  description = "Workload Identity pool in format PROJECT_ID.svc.id.goog."
  type        = string
  default     = ""
}

variable "argocd_host" {
  description = "FQDN for the Argo CD server ingress in production."
  type        = string
  default     = "argocd.prod.example.com"
}
