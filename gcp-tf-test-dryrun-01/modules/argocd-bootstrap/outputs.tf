output "namespace" {
  description = "Namespace where Argo CD is installed."
  value       = var.namespace
}

output "chart_version" {
  description = "Argo CD helm chart version deployed."
  value       = helm_release.argocd.version
}
