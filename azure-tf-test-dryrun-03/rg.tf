resource "azurerm_resource_group" "dryrun_rg" {
  name     = var.resource_group_name
  location = var.location
}