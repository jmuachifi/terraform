## Replace this file with your configuration from following the scenario.
##
## Final configuration:
#
# resource "docker_image" "nginx" {
#   name = "nginx:latest"
# }
#
# # docker_container.web:
# resource "docker_container" "web" {
#   name  = "hashicorp-learn"
#
#   image = docker_image.nginx.latest
#
#   ports {
#     external = 8081
#     internal = 80
#   }
# }
resource "docker_image" "nginx" {
  name = "nginx:latest"
}
resource "docker_container" "web" {
      name  = "hashicorp-learn" #"nginx-latest" 
      image = docker_image.nginx.latest 
      #"sha256:f8f4ffc8092c956ddd6a3a64814f36882798065799b8aedeebedf2855af3395b"

      env = []

      ports{
            external = 8081
            internal = 80
      }
}

