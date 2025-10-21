output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "Name of the AKS subnet"
  value       = azurerm_subnet.aks.name
}

output "pods_subnet_id" {
  description = "ID of the pods subnet"
  value       = azurerm_subnet.pods.id
}

output "pods_subnet_name" {
  description = "Name of the pods subnet"
  value       = azurerm_subnet.pods.name
}

output "ingress_subnet_id" {
  description = "ID of the ingress subnet"
  value       = azurerm_subnet.ingress.id
}

output "ingress_subnet_name" {
  description = "Name of the ingress subnet"
  value       = azurerm_subnet.ingress.name
}

output "nsg_id" {
  description = "ID of the AKS network security group"
  value       = azurerm_network_security_group.aks.id
}

output "route_table_id" {
  description = "ID of the AKS route table"
  value       = azurerm_route_table.aks.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = azurerm_nat_gateway.main.id
}
