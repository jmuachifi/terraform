variable "project_id" {
  description = "Google Cloud project identifier where the services are enabled."
  type        = string
}

variable "services" {
  description = "List of Google Cloud APIs to enable for the project."
  type        = list(string)
  default = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
}

variable "disable_on_destroy" {
  description = "Disable APIs when the module is destroyed. Keep false to avoid accidental outages."
  type        = bool
  default     = false
}
