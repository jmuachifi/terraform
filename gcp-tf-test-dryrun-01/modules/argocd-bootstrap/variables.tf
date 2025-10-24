variable "namespace" {
  description = "Namespace where Argo CD will be installed."
  type        = string
  default     = "argocd"
}

variable "create_namespace" {
  description = "Create the namespace if it does not exist."
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Helm chart version for Argo CD."
  type        = string
  default     = "6.9.2"
}

variable "ingress_host" {
  description = "Hostname for the Argo CD server ingress. Leave null to disable ingress."
  type        = string
  default     = null
}

variable "ingress_class_name" {
  description = "IngressClass to target (e.g., nginx)."
  type        = string
  default     = "nginx"
}

variable "tls_secret_name" {
  description = "TLS secret the ingress should reference."
  type        = string
  default     = "argocd-server-tls"
}

variable "issuer_kind" {
  description = "cert-manager issuer kind used for TLS (Issuer or ClusterIssuer)."
  type        = string
  default     = "ClusterIssuer"
}

variable "issuer_name" {
  description = "Name of the cert-manager issuer for TLS."
  type        = string
  default     = "letsencrypt-prod"
}

variable "additional_settings" {
  description = "Additional Helm values to merge with the defaults."
  type        = map(any)
  default     = {}
}
