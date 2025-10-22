resource "azurerm_public_ip" "dryrun_public_ip" {
  name                = "dryrun-public-ip"
  location            = azurerm_resource_group.dryrun_rg.location
  resource_group_name = azurerm_resource_group.dryrun_rg.name
  allocation_method   = "Static"

  tags = merge({ Name = "dryrun-public-ip" }, var.tags)
}
