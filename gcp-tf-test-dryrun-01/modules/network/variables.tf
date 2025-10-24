variable "project_id" {
  description = "Project where the VPC will be created."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC."
  type        = string
}

variable "routing_mode" {
  description = "VPC routing mode (GLOBAL or REGIONAL)."
  type        = string
  default     = "GLOBAL"
}

variable "subnets" {
  description = "Subnet definitions including secondary ranges for GKE."
  type = list(object({
    name                     = string
    ip_cidr_range            = string
    region                   = string
    private_ip_google_access = optional(bool, true)
    purpose                  = optional(string)
    role                     = optional(string)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
  default = []
}

variable "create_nat" {
  description = "Whether to create a Cloud NAT to allow private nodes outbound internet access."
  type        = bool
  default     = true
}

variable "nat_name" {
  description = "Name for the Cloud NAT resource if created."
  type        = string
  default     = "gke-cloud-nat"
}

variable "router_name" {
  description = "Name for the Cloud Router when NAT is enabled."
  type        = string
  default     = "gke-cloud-router"
}
