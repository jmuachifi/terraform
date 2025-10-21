# General Variables
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "aksproject"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# Networking Variables
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "pods_subnet_address_prefix" {
  description = "Address prefix for pods subnet (CNI Overlay)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ingress_subnet_address_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# AKS Cluster Variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "sku_tier" {
  description = "SKU tier for AKS cluster (Free, Standard, Premium)"
  type        = string
  default     = "Standard"
}

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
  default = {
    name            = "system"
    vm_size         = "Standard_D4s_v3"
    node_count      = 3
    min_count       = 2
    max_count       = 5
    os_disk_size_gb = 128
    os_disk_type    = "Managed"
    os_sku          = "AzureLinux"
    auto_scaling    = true
    zones           = [1, 2, 3]
    max_pods        = 50
    node_labels = {
      "role" = "system"
    }
  }
}

variable "additional_node_pools" {
  description = "Additional node pools for workloads"
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

# Monitoring Variables
variable "log_analytics_workspace_sku" {
  description = "SKU for Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Retention period for Log Analytics"
  type        = number
  default     = 30
}

# Network Policy
variable "network_policy" {
  description = "Network policy to use (azure, calico, cilium)"
  type        = string
  default     = "azure"
}

variable "network_plugin" {
  description = "Network plugin to use (azure, kubenet)"
  type        = string
  default     = "azure"
}

variable "network_plugin_mode" {
  description = "Network plugin mode (overlay or blank)"
  type        = string
  default     = "overlay"
}

# DNS
variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
  default     = "10.2.0.10"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "pod_cidr" {
  description = "CIDR for pods when using CNI Overlay"
  type        = string
  default     = "10.244.0.0/16"
}

# RBAC
variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "AAD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

# Azure Policy
variable "azure_policy_enabled" {
  description = "Enable Azure Policy addon"
  type        = bool
  default     = true
}

# Monitoring
variable "enable_container_insights" {
  description = "Enable Container Insights monitoring"
  type        = bool
  default     = true
}

# Auto-scaling
variable "cluster_autoscaler_profile" {
  description = "Cluster autoscaler profile configuration"
  type = object({
    scale_down_delay_after_add       = string
    scale_down_unneeded              = string
    scale_down_utilization_threshold = string
    max_graceful_termination_sec     = string
    balance_similar_node_groups      = bool
    skip_nodes_with_system_pods      = bool
  })
  default = {
    scale_down_delay_after_add       = "10m"
    scale_down_unneeded              = "10m"
    scale_down_utilization_threshold = "0.5"
    max_graceful_termination_sec     = "600"
    balance_similar_node_groups      = true
    skip_nodes_with_system_pods      = true
  }
}

# GitOps - ArgoCD
variable "install_argocd" {
  description = "Install ArgoCD via Helm"
  type        = bool
  default     = true
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.7.12"
}

# Ingress Controller
variable "install_nginx_ingress" {
  description = "Install NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "nginx_ingress_namespace" {
  description = "Namespace for NGINX Ingress Controller"
  type        = string
  default     = "ingress-nginx"
}

# Cert Manager
variable "install_cert_manager" {
  description = "Install Cert Manager for TLS certificates"
  type        = bool
  default     = true
}

variable "cert_manager_namespace" {
  description = "Namespace for Cert Manager"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_email" {
  description = "Email for Let's Encrypt certificate notifications"
  type        = string
  default     = ""
}

# Private Cluster
variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

# Key Vault Secrets Provider
variable "enable_key_vault_secrets_provider" {
  description = "Enable Key Vault Secrets Provider addon"
  type        = bool
  default     = true
}

# Workload Identity
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
