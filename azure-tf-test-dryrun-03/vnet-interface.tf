resource "azurerm_network_interface" "dryrun_nic" {
  name                = "dryrun-nic"
  location            = azurerm_resource_group.dryrun_rg.location
  resource_group_name = azurerm_resource_group.dryrun_rg.name

  ip_configuration {
    name                          = "dryrun-nic-ipconfig"
    subnet_id                     = azurerm_subnet.dryrun_vnet_sub1.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge({ Name = "dryrun-nic" }, var.tags)
}