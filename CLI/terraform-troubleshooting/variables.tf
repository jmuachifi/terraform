variable "region" {
  description = "The AWS region your resources will be deployed"
  type        = string
  default     = "us-east-2"
}

variable "name" {
  description = "The operator name running this configuration"
}
