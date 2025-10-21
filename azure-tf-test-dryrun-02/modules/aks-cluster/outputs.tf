output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "node_resource_group" {
  description = "Name of the node resource group"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "kube_config" {
  description = "Kubernetes configuration"
  value = {
    host                   = azurerm_kubernetes_cluster.main.kube_config[0].host
    client_certificate     = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
    client_key             = azurerm_kubernetes_cluster.main.kube_config[0].client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  }
  sensitive = true
}

output "kube_config_raw" {
  description = "Raw kubeconfig"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "key_vault_secrets_provider_identity" {
  description = "Key Vault Secrets Provider identity"
  value = var.enable_key_vault_secrets_provider ? {
    client_id                 = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id
    object_id                 = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].user_assigned_identity_id
  } : null
  sensitive = true
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the cluster identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "cluster_identity_client_id" {
  description = "Client ID of the cluster identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}
