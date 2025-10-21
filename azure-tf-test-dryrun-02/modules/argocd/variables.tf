variable "namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.7.12"
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  type        = string
  default     = ""
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}
