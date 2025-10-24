output "subnet_secondary_ranges" {
  description = "Secondary ranges available for the cluster."
  value       = module.network.subnet_secondary_ranges
}
