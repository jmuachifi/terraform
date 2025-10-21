# Backend configuration for Dev environment
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaksproject"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
