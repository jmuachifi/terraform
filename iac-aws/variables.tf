# variables.tf
variable "key_name" {
  description = "Name of the SSH key pair"
  type       = string
  default = "key_pair"
}

variable "aws_region" {
  description = "AWS region"
  type = string
  default = "us-west-2"
}

variable "aws_access_key" {
  description = "AWS access key"
}

variable "aws_secret_key" {
  description = "AWS secret key"
}
variable "subnet_ids" {
  description = "List of subnet IDs"
  type = list(string)
  default = ["subnet-05a3acd1df6160e45", "subnet-0a86b5b762c97e73e"] 
}
variable "vpc_id" {
  description = "VPC ID"
  type = string
  default = "vpc-0c79b80b22ab20beb"
  
}