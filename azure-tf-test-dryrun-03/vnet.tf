resource "azurerm_virtual_network" "dryrun_vnet" {
  name                = "example-network"
  location            = azurerm_resource_group.dryrun_rg.location
  resource_group_name = azurerm_resource_group.dryrun_rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = merge({ Name = "dryrun-vnet" }, var.tags)
}