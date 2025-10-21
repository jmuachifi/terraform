# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

# Networking Outputs
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = module.networking.aks_subnet_id
}

output "pods_subnet_id" {
  description = "ID of the pods subnet"
  value       = module.networking.pods_subnet_id
}

# AKS Cluster Outputs
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks_cluster.cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks_cluster.cluster_id
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks_cluster.cluster_fqdn
}

output "aks_node_resource_group" {
  description = "Name of the node resource group"
  value       = module.aks_cluster.node_resource_group
}

output "aks_kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity"
  value       = module.aks_cluster.kubelet_identity_object_id
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = module.aks_cluster.oidc_issuer_url
}

output "aks_key_vault_secrets_provider_identity" {
  description = "Identity of the Key Vault secrets provider"
  value       = module.aks_cluster.key_vault_secrets_provider_identity
  sensitive   = true
}

# Log Analytics Workspace
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# Kubeconfig (Sensitive)
output "kube_config" {
  description = "Kubernetes config for kubectl"
  value       = module.aks_cluster.kube_config_raw
  sensitive   = true
}

# Instructions for connecting to the cluster
output "connect_instructions" {
  description = "Instructions for connecting to the AKS cluster"
  value       = <<-EOT
    To connect to the AKS cluster, run:
    
    az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks_cluster.cluster_name}
    
    Or use the kubeconfig from Terraform output:
    
    terraform output -raw kube_config > ~/.kube/config-${var.environment}
    export KUBECONFIG=~/.kube/config-${var.environment}
    kubectl get nodes
  EOT
}

# ArgoCD Outputs
output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = var.install_argocd ? var.argocd_namespace : null
}

output "argocd_instructions" {
  description = "Instructions for accessing ArgoCD"
  value = var.install_argocd ? (<<-EOT
    To access ArgoCD UI:
    
    1. Get the initial admin password:
       kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
    
    2. Port forward to access the UI:
       kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:443
    
    3. Open browser to: https://localhost:8080
       Username: admin
       Password: (from step 1)
EOT
  ) : null
}
