# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}-${var.location}"
  location = var.location

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  )
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${var.environment}-${var.location}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_analytics_retention_days

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  project_name                  = var.project_name
  environment                   = var.environment
  location                      = var.location
  resource_group_name           = azurerm_resource_group.main.name
  vnet_address_space            = var.vnet_address_space
  aks_subnet_address_prefix     = var.aks_subnet_address_prefix
  pods_subnet_address_prefix    = var.pods_subnet_address_prefix
  ingress_subnet_address_prefix = var.ingress_subnet_address_prefix
  tags                          = var.tags
}

# AKS Cluster Module
module "aks_cluster" {
  source = "./modules/aks-cluster"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  # Networking
  vnet_id             = module.networking.vnet_id
  aks_subnet_id       = module.networking.aks_subnet_id
  pods_subnet_id      = module.networking.pods_subnet_id
  dns_service_ip      = var.dns_service_ip
  service_cidr        = var.service_cidr
  pod_cidr            = var.pod_cidr
  network_policy      = var.network_policy
  network_plugin      = var.network_plugin
  network_plugin_mode = var.network_plugin_mode

  # Node Pools
  default_node_pool     = var.default_node_pool
  additional_node_pools = var.additional_node_pools

  # Monitoring
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  enable_container_insights  = var.enable_container_insights

  # RBAC
  azure_rbac_enabled     = var.azure_rbac_enabled
  admin_group_object_ids = var.admin_group_object_ids

  # Features
  azure_policy_enabled              = var.azure_policy_enabled
  private_cluster_enabled           = var.private_cluster_enabled
  enable_key_vault_secrets_provider = var.enable_key_vault_secrets_provider
  workload_identity_enabled         = var.workload_identity_enabled
  oidc_issuer_enabled               = var.oidc_issuer_enabled

  # Auto-scaling
  cluster_autoscaler_profile = var.cluster_autoscaler_profile

  tags = var.tags
}

# GitOps - ArgoCD Installation
module "argocd" {
  source = "./modules/argocd"
  count  = var.install_argocd ? 1 : 0

  namespace                = var.argocd_namespace
  chart_version            = var.argocd_chart_version
  oidc_issuer_url          = module.aks_cluster.oidc_issuer_url
  enable_workload_identity = var.workload_identity_enabled

  depends_on = [module.aks_cluster]
}

# NGINX Ingress Controller
module "nginx_ingress" {
  source = "./modules/nginx-ingress"
  count  = var.install_nginx_ingress ? 1 : 0

  namespace = var.nginx_ingress_namespace

  depends_on = [module.aks_cluster]
}

# Cert Manager for TLS
module "cert_manager" {
  source = "./modules/cert-manager"
  count  = var.install_cert_manager ? 1 : 0

  namespace   = var.cert_manager_namespace
  acme_email  = var.cert_manager_email
  environment = var.environment

  depends_on = [module.aks_cluster]
}
