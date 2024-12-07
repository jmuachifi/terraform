# variables.tf
variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "project_name" {
  description = "The project name for tagging"
  default     = "nginx-webapp"
}

variable "domain" {
  description = "The domain name to associate with the web app"
  default = "eks-demo.duckdns.org"
  type        = string
}

