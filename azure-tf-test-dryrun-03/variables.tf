variable "tags" {
  description = "A map of tags to assign to the resource."
  type = object({
    Environment = string
    Project     = string
  })
  default = {
    Environment = "dev"
    Project     = "Azure-Terraform-DryRun"
  }
}

variable "subscription_id" {
  description = "The Azure subscription ID to manage resources in."
  type        = string
}

variable "tenant_id" {
  description = "The Azure Active Directory tenant ID."
  type        = string
}

variable "client_id" {
  description = "The client (application) ID for the Service Principal."
  type        = string
}

variable "client_secret" {
  description = "The client secret for the Service Principal."
  type        = string
  sensitive   = true
}
variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "dryrun-resource-group"
}
variable "location" {
  description = "The Azure region where the resource group will be created."
  type        = string
  default     = "East US"
}
variable "admin_username" {
  description = "The admin username for the virtual machine."
  type        = string
  default     = "azureuser"
}
variable "admin_password" {
  description = "The admin password for the virtual machine."
  type        = string
  default     = "P@ssw0rd!"
  sensitive   = true
}
variable "zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["1", "2"]
}