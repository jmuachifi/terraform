# modules/eks/variables.tf

# Project name to create resources with proper naming
variable "project_name" {
  description = "The name of the project or environment"
  type        = string
}

# The version of Kubernetes to use for the EKS cluster
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  default     = "1.21" # Can be overridden
  type        = string
}

# VPC ID where the EKS cluster will be deployed
variable "vpc_id" {
  description = "The ID of the VPC to deploy the EKS cluster"
  type        = string
}

# Subnet IDs in the VPC for the EKS cluster
variable "subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

