# Staging Environment Configuration

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestgaks"
    container_name       = "tfstate"
    key                  = "staging.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Local variables
locals {
  environment = "staging"
  project     = "akscluster"
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.project}-${local.environment}"
  location = var.location
  tags     = local.common_tags
}

# Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  workspace_name      = "law-${local.project}-${local.environment}"
  app_insights_name   = "ai-${local.project}-${local.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  retention_in_days   = 60
  tags                = local.common_tags
}

# Networking
module "networking" {
  source = "../../modules/networking"

  vnet_name                                 = "vnet-${local.project}-${local.environment}"
  resource_group_name                       = azurerm_resource_group.main.name
  location                                  = var.location
  vnet_address_space                        = ["10.1.0.0/16"]
  aks_subnet_address_prefixes               = ["10.1.1.0/24"]
  appgw_subnet_address_prefixes             = ["10.1.2.0/24"]
  private_endpoints_subnet_address_prefixes = ["10.1.3.0/24"]
  tags                                      = local.common_tags
}

# Azure Container Registry
module "acr" {
  source = "../../modules/acr"

  acr_name                   = "acr${local.project}${local.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  sku                        = "Premium"
  log_analytics_workspace_id = module.monitoring.workspace_id
  tags                       = local.common_tags
}

# Key Vault
module "keyvault" {
  source = "../../modules/keyvault"

  key_vault_name             = "kv-${local.project}-${local.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  log_analytics_workspace_id = module.monitoring.workspace_id
  purge_protection_enabled   = true
  tags                       = local.common_tags
}

# AKS Cluster
module "aks" {
  source = "../../modules/aks"

  cluster_name               = "aks-${local.project}-${local.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  dns_prefix                 = "${local.project}-${local.environment}"
  kubernetes_version         = var.kubernetes_version
  sku_tier                   = "Standard"
  vnet_subnet_id             = module.networking.aks_subnet_id
  vnet_id                    = module.networking.vnet_id
  dns_service_ip             = "10.1.4.10"
  service_cidr               = "10.1.4.0/24"
  log_analytics_workspace_id = module.monitoring.workspace_id
  acr_id                     = module.acr.acr_id
  key_vault_id               = module.keyvault.key_vault_id
  # Node pool configuration for staging
  system_node_count = 3
  system_node_size  = "Standard_D4s_v5"

  user_node_count     = 3
  user_node_min_count = 3
  user_node_max_count = 8
  user_node_size      = "Standard_D4s_v5"

  availability_zones = ["1", "2", "3"]

  tags = local.common_tags

  depends_on = [
    module.monitoring,
    module.networking
  ]
}
