variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.3"
}

variable "sku_tier" {
  description = "SKU tier for AKS (Free, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "automatic_channel_upgrade" {
  description = "Automatic channel upgrade (patch, stable, rapid, node-image)"
  type        = string
  default     = "stable"
}

variable "vnet_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "vnet_id" {
  description = "VNet ID for role assignment"
  type        = string
}

variable "system_node_count" {
  description = "Initial number of system nodes"
  type        = number
  default     = 3
}

variable "system_node_min_count" {
  description = "Minimum number of system nodes"
  type        = number
  default     = 3
}

variable "system_node_max_count" {
  description = "Maximum number of system nodes"
  type        = number
  default     = 5
}

variable "system_node_size" {
  description = "VM size for system nodes"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_node_count" {
  description = "Initial number of user nodes"
  type        = number
  default     = 3
}

variable "user_node_min_count" {
  description = "Minimum number of user nodes"
  type        = number
  default     = 3
}

variable "user_node_max_count" {
  description = "Maximum number of user nodes"
  type        = number
  default     = 10
}

variable "user_node_size" {
  description = "VM size for user nodes"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "availability_zones" {
  description = "Availability zones for nodes"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "dns_service_ip" {
  description = "DNS service IP address"
  type        = string
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
}

variable "enable_azure_ad_rbac" {
  description = "Enable Azure AD RBAC"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admins"
  type        = list(string)
  default     = []
}

variable "acr_id" {
  description = "Azure Container Registry ID"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Azure Key Vault ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
