output "namespace" {
  description = "NGINX Ingress namespace"
  value       = kubernetes_namespace.nginx_ingress.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.nginx_ingress.name
}
