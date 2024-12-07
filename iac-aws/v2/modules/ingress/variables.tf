# modules/ingress/variables.tf

variable "project_name" {
  type        = string
  description = "The project name"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}