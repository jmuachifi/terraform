output "public_ip" {
  value = azurerm_public_ip.dryrun_public_ip.ip_address
}
output "vm_id" {
  value = azurerm_virtual_machine.dryrun_vm.id
}
output "resource_group_name" {
  value = azurerm_resource_group.dryrun_rg.name
}
output "network_interface_id" {
  value = azurerm_network_interface.dryrun_nic.id
}
output "location" {
  value = azurerm_resource_group.dryrun_rg.location
}
output "admin_username" {
  value = var.admin_username
}
output "zones" {
  value = var.zones
}
output "tags" {
  value = var.tags
}
