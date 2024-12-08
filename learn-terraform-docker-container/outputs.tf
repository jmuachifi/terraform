output "container_id" {
  description = "ID of the Docker container"
  value       = docker_container.nginx.id
}

output "image_id" {
  description = "ID of the Docker image"
  value       = docker_image.nginx.id
}

output "container_ip" {
  value = docker_container.nginx.network_data[0].ip_address
}


output "container_ports" {
  value = docker_container.nginx.ports
}

