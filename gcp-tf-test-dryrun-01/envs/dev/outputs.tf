output "network_self_link" {
  description = "VPC self link created for the environment."
  value       = module.network.network_self_link
}

output "subnet_secondary_ranges" {
  description = "Secondary ranges available for the cluster."
  value       = module.network.subnet_secondary_ranges
}
