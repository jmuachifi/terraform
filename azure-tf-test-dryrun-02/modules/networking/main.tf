# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Network Security Group for AKS Subnet
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# AKS Subnet
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-${var.project_name}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_address_prefix]

  # Service endpoints for enhanced security
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Sql",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

# Associate NSG with AKS Subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Pods Subnet (for CNI Overlay or Azure CNI)
resource "azurerm_subnet" "pods" {
  name                 = "snet-pods-${var.project_name}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.pods_subnet_address_prefix]

  delegation {
    name = "aks-delegation"
    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Ingress Subnet (for Application Gateway or Load Balancer)
resource "azurerm_subnet" "ingress" {
  name                 = "snet-ingress-${var.project_name}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.ingress_subnet_address_prefix]
}

# Route Table for AKS (if needed for custom routing)
resource "azurerm_route_table" "aks" {
  name                = "rt-aks-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Associate Route Table with AKS Subnet
resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.aks.id
}

# NAT Gateway for outbound connectivity (optional, for better security)
resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

resource "azurerm_nat_gateway" "main" {
  name                = "nat-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
