terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.49.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Backend configuration - uncomment and configure for remote state
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatexxxxxx"
  #   container_name       = "tfstate"
  #   key                  = "prod.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "kubernetes" {
  host                   = module.aks_cluster.kube_config.host
  client_certificate     = base64decode(module.aks_cluster.kube_config.client_certificate)
  client_key             = base64decode(module.aks_cluster.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks_cluster.kube_config.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = module.aks_cluster.kube_config.host
    client_certificate     = base64decode(module.aks_cluster.kube_config.client_certificate)
    client_key             = base64decode(module.aks_cluster.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks_cluster.kube_config.cluster_ca_certificate)
  }
}
