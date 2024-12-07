# modules/eks/outputs.tf
# output "cluster_name" {
#   description = "The name of the EKS cluster"
#   value       = module.eks.cluster_id
# }

# output "cluster_endpoint" {
#   description = "The endpoint of the EKS cluster"
#   value       = module.eks.cluster_endpoint
# }

# output "cluster_certificate_authority_data" {
#   description = "The certificate authority data for the cluster"
#   value       = module.eks.cluster_certificate_authority_data
# }

# # Correct output for EKS managed node group ARNs
# output "managed_node_groups_arns" {
#   description = "The ARNs of the EKS managed node groups"
#   value       = module.eks.managed_node_groups_arns
# }

# # Correct output for EKS managed node group names
# output "managed_node_groups_names" {
#   description = "The names of the EKS managed node groups"
#   value       = module.eks.managed_node_groups_names
# }
# modules/eks/outputs.tf
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "The certificate authority data for the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "node_groups" {
  description = "Map of EKS managed node groups"
  value       = module.eks.eks_managed_node_groups
}
