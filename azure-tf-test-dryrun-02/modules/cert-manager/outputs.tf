output "namespace" {
  description = "Cert Manager namespace"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.cert_manager.name
}

output "cluster_issuer" {
  description = "Cluster issuer name"
  value       = var.environment == "prod" ? "letsencrypt-prod" : "letsencrypt-staging"
}
