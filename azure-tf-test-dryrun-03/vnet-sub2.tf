resource "azurerm_subnet" "dryrun_vnet_sub2" {
  name                 = "dryrun-subnet2"
  virtual_network_name = azurerm_virtual_network.dryrun_vnet.name
  resource_group_name  = azurerm_resource_group.dryrun_rg.name
  address_prefixes     = ["10.0.2.0/24"]
}

