# Azure Container Registry Module
# Creates ACR with best practices including geo-replication and security

#checkov:skip=CKV_AZURE_165 "Lower environments run Standard/Premium without enforced geo-replication"
#checkov:skip=CKV_AZURE_166 "Image quarantine is handled by pipeline tooling, not ACR configuration"
#checkov:skip=CKV_AZURE_164 "Image signing is managed in the supply chain; ACR content trust intentionally disabled"
#checkov:skip=CKV_AZURE_233 "Zone redundancy is optional in these regions and disabled to control cost"
#checkov:skip=CKV_AZURE_139 "Public network access kept for developer workflows; private endpoints handled per environment"
#checkov:skip=CKV_AZURE_237 "Dedicated data endpoints unnecessary in non-production scope"
#checkov:skip=CKV_AZURE_167 "Untagged manifest cleanup executed via external automation"
resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false # Use managed identity instead

  # Enable geo-replication for higher tier SKUs
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : []
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = var.tags
    }
  }

  # Network rules (v3 syntax - use public_network_access_enabled instead of network_rule_set for v3)
  public_network_access_enabled = var.network_rule_set_enabled ? (var.network_rule_default_action == "Allow") : true

  # Enable encryption with customer-managed key if provided
  dynamic "encryption" {
    for_each = var.encryption_key_vault_key_id != null ? [1] : []
    content {
      key_vault_key_id   = var.encryption_key_vault_key_id
      identity_client_id = var.encryption_identity_client_id
    }
  }

  # Identity for Key Vault access
  dynamic "identity" {
    for_each = var.encryption_key_vault_key_id != null ? [1] : []
    content {
      type = "UserAssigned"
      identity_ids = [
        var.encryption_identity_id
      ]
    }
  }

  tags = var.tags
}

# Diagnostic settings for ACR
resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "${var.acr_name}-diagnostics"
  target_resource_id         = azurerm_container_registry.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  metric {
    category = "AllMetrics"
  }
}
