variable "namespace" {
  description = "Namespace for Cert Manager"
  type        = string
  default     = "cert-manager"
}

variable "acme_email" {
  description = "Email for ACME (Let's Encrypt) notifications"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
