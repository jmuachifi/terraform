resource "azurerm_subnet" "dryrun_vnet_sub1" {
  name                 = "dryrun-subnet1"
  virtual_network_name = azurerm_virtual_network.dryrun_vnet.name
  resource_group_name  = azurerm_resource_group.dryrun_rg.name
  address_prefixes     = ["10.0.1.0/24"]
}

