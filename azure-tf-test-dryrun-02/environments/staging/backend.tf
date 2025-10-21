# Backend configuration for Staging environment
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaksproject"
    container_name       = "tfstate"
    key                  = "staging.terraform.tfstate"
  }
}
