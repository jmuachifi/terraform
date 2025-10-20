variable "project" {
	type = string
}

variable "environment" {
	type = string
}

variable "aws_region" {
	type    = string
	default = "us-east-1"
}

variable "cluster_version" {
	type    = string
	default = "1.30"
}

variable "vpc_cidr" {
	type    = string
	default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
	type    = list(string)
	default = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
}

variable "private_subnet_cidrs" {
	type    = list(string)
	default = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
}

variable "min_size" {
	type    = number
	default = 2
}

variable "max_size" {
	type    = number
	default = 5
}

variable "desired_size" {
	type    = number
	default = 3
}

variable "enable_argocd" {
	type    = bool
	default = true
}

variable "argocd_namespace" {
	type    = string
	default = "argocd"
}

variable "github_repo_url" {
	type        = string
	description = "Git repo URL for ArgoCD root app"
}

variable "github_repo_path" {
	type        = string
	description = "Path within repo for ArgoCD apps"
	default     = "gitops/cluster"
}

variable "github_repo_revision" {
	type    = string
	default = "main"
}

variable "tags" {
	type    = map(string)
	default = {}
}
