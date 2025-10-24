output "cluster_name" {
  description = "Name of the created GKE cluster."
  value       = google_container_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes API server."
  value       = google_container_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded public certificate for the cluster."
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identity pool bound to the cluster."
  value       = google_container_cluster.this.workload_identity_config[0].workload_pool
}

output "node_pool_names" {
  description = "Node pool names managed by this module."
  value       = keys(local.node_pools_by_name)
}
