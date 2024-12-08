terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "tutorial"
  ports {
    internal = 80
    external = 8080
  }

  volumes {
    host_path      = abspath("${path.module}/index.html")
    container_path = "/usr/share/nginx/html/index.html"
    read_only      = true
  }
}

output "container_ip" {
  value = docker_container.nginx.network_data[0].ip_address
}


output "container_ports" {
  value = docker_container.nginx.ports
}



