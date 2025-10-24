output "network_self_link" {
  description = "Self link of the created VPC."
  value       = google_compute_network.this.self_link
}

output "subnet_self_links" {
  description = "Map of subnet names to self links."
  value = {
    for name, subnet in google_compute_subnetwork.this : name => subnet.self_link
  }
}

output "subnet_secondary_ranges" {
  description = "Map of subnet names to their secondary ranges."
  value = {
    for name, subnet in google_compute_subnetwork.this : name => subnet.secondary_ip_range
  }
}
