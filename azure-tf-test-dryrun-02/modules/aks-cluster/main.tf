# User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Role assignment for AKS identity to manage networking
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                              = "aks-${var.project_name}-${var.environment}-${var.location}"
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = "${var.project_name}-${var.environment}"
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = var.sku_tier
  private_cluster_enabled           = var.private_cluster_enabled
  automatic_upgrade_channel         = "patch"
  node_os_upgrade_channel           = "SecurityPatch"
  oidc_issuer_enabled               = var.oidc_issuer_enabled
  workload_identity_enabled         = var.workload_identity_enabled
  azure_policy_enabled              = var.azure_policy_enabled
  role_based_access_control_enabled = true
  cost_analysis_enabled             = var.sku_tier != "Free"
  disk_encryption_set_id            = var.disk_encryption_set_id
  local_account_disabled            = var.local_account_disabled

  # Default Node Pool (System)
  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    os_sku                       = var.default_node_pool.os_sku
    os_disk_type                 = var.default_node_pool.os_disk_type
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    vnet_subnet_id               = var.aks_subnet_id
    pod_subnet_id                = var.pods_subnet_id
    zones                        = var.default_node_pool.zones
    max_pods                     = var.default_node_pool.max_pods
    auto_scaling_enabled         = var.default_node_pool.auto_scaling
    node_count                   = var.default_node_pool.node_count
    min_count                    = var.default_node_pool.auto_scaling ? var.default_node_pool.min_count : null
    max_count                    = var.default_node_pool.auto_scaling ? var.default_node_pool.max_count : null
    only_critical_addons_enabled = true
    node_labels                  = var.default_node_pool.node_labels

    upgrade_settings {
      max_surge                     = "33%"
      drain_timeout_in_minutes      = 30
      node_soak_duration_in_minutes = 0
    }

    tags = merge(
      var.tags,
      {
        Environment = var.environment
        NodePool    = "system"
      }
    )
  }

  # Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network Profile
  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin_mode
    network_policy      = var.network_policy
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    pod_cidr            = var.network_plugin_mode == "overlay" ? var.pod_cidr : null
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"

    load_balancer_profile {
      managed_outbound_ip_count = 1
      idle_timeout_in_minutes   = 4
    }
  }

  # Azure Active Directory RBAC
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_rbac_enabled ? [1] : []
    content {
      azure_rbac_enabled     = true
      tenant_id              = data.azurerm_client_config.current.tenant_id
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  # API Server access restrictions (authorized IP ranges)
  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # OMS Agent (Container Insights)
  dynamic "oms_agent" {
    for_each = var.enable_container_insights ? [1] : []
    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  # Key Vault Secrets Provider
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  # Storage Profile
  storage_profile {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  # Cluster Autoscaler Profile
  auto_scaler_profile {
    balance_similar_node_groups      = var.cluster_autoscaler_profile.balance_similar_node_groups
    scale_down_delay_after_add       = var.cluster_autoscaler_profile.scale_down_delay_after_add
    scale_down_unneeded              = var.cluster_autoscaler_profile.scale_down_unneeded
    scale_down_utilization_threshold = var.cluster_autoscaler_profile.scale_down_utilization_threshold
    max_graceful_termination_sec     = var.cluster_autoscaler_profile.max_graceful_termination_sec
    skip_nodes_with_system_pods      = var.cluster_autoscaler_profile.skip_nodes_with_system_pods
  }

  # Maintenance Window
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "04:00"
    utc_offset  = "+00:00"
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )

  depends_on = [
    azurerm_role_assignment.aks_network_contributor
  ]
}

# Data source for current Azure client config
data "azurerm_client_config" "current" {}

# Additional Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = { for np in var.additional_node_pools : np.name => np }

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  vnet_subnet_id        = var.aks_subnet_id
  pod_subnet_id         = var.pods_subnet_id
  zones                 = each.value.zones
  max_pods              = each.value.max_pods
  auto_scaling_enabled  = each.value.auto_scaling
  node_count            = each.value.node_count
  min_count             = each.value.auto_scaling ? each.value.min_count : null
  max_count             = each.value.auto_scaling ? each.value.max_count : null
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints

  upgrade_settings {
    max_surge                     = "33%"
    drain_timeout_in_minutes      = 30
    node_soak_duration_in_minutes = 0
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      NodePool    = each.value.name
    }
  )
}
