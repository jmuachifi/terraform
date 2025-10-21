output "namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.argocd.name
}

output "chart_version" {
  description = "Installed chart version"
  value       = helm_release.argocd.version
}
