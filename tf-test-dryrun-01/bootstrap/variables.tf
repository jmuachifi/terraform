variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name, e.g., prod, dev"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub organization or user name"
  type        = string
}

variable "github_repository" {
  description = "Full repo name like owner/repo"
  type        = string
}

variable "state_bucket_name" {
  description = "Optional pre-existing S3 bucket name for Terraform state"
  type        = string
  default     = null
}

variable "state_table_name" {
  description = "Optional pre-existing DynamoDB table name for state locking"
  type        = string
  default     = null
}

variable "github_oidc_provider_arn" {
  description = "Optional existing GitHub OIDC provider ARN"
  type        = string
  default     = null
}
