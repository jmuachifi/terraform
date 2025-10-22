resource "azurerm_virtual_machine" "dryrun_vm" {
  name                  = "dryrun-vm"
  location              = azurerm_resource_group.dryrun_rg.location
  resource_group_name   = azurerm_resource_group.dryrun_rg.name
  network_interface_ids = [azurerm_network_interface.dryrun_nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "dryrun_os_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "dryrunvm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  zones = var.zones

  tags = merge({ Name = "dryrun-vm" }, var.tags)
}