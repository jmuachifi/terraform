variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "sku_tier" {
  description = "SKU tier for AKS cluster"
  type        = string
  default     = "Standard"
}

# Networking
variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "aks_subnet_id" {
  description = "ID of the AKS subnet"
  type        = string
}

variable "pods_subnet_id" {
  description = "ID of the pods subnet"
  type        = string
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
}

variable "pod_cidr" {
  description = "Pod CIDR"
  type        = string
}

variable "network_policy" {
  description = "Network policy"
  type        = string
  default     = "azure"
}

variable "network_plugin" {
  description = "Network plugin"
  type        = string
  default     = "azure"
}

variable "network_plugin_mode" {
  description = "Network plugin mode"
  type        = string
  default     = "overlay"
}

# Node Pools
variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name            = string
    vm_size         = string
    node_count      = number
    min_count       = number
    max_count       = number
    os_disk_size_gb = number
    os_disk_type    = string
    os_sku          = string
    auto_scaling    = bool
    zones           = list(number)
    max_pods        = number
    node_labels     = map(string)
  })
}

variable "additional_node_pools" {
  description = "Additional node pools"
  type = list(object({
    name            = string
    vm_size         = string
    node_count      = number
    min_count       = number
    max_count       = number
    os_disk_size_gb = number
    os_disk_type    = string
    auto_scaling    = bool
    zones           = list(number)
    max_pods        = number
    node_labels     = map(string)
    node_taints     = list(string)
  }))
  default = []
}

# Monitoring
variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable Container Insights"
  type        = bool
  default     = true
}

# RBAC
variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Admin group object IDs"
  type        = list(string)
  default     = []
}

# Features
variable "azure_policy_enabled" {
  description = "Enable Azure Policy"
  type        = bool
  default     = true
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "local_account_disabled" {
  description = "Disable the AKS local admin account (recommended)"
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "List of authorized IP ranges for the AKS API server. Leave empty to allow public access (not recommended)."
  type        = list(string)
  default     = []
}

variable "disk_encryption_set_id" {
  description = "Resource ID of the Disk Encryption Set to use for AKS (if required). Leave null to disable."
  type        = string
  default     = null
}

variable "enable_key_vault_secrets_provider" {
  description = "Enable Key Vault Secrets Provider"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable Workload Identity"
  type        = bool
  default     = true
}

variable "oidc_issuer_enabled" {
  description = "Enable OIDC issuer"
  type        = bool
  default     = true
}

# Auto-scaling
variable "cluster_autoscaler_profile" {
  description = "Cluster autoscaler profile"
  type = object({
    scale_down_delay_after_add       = string
    scale_down_unneeded              = string
    scale_down_utilization_threshold = string
    max_graceful_termination_sec     = string
    balance_similar_node_groups      = bool
    skip_nodes_with_system_pods      = bool
  })
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
