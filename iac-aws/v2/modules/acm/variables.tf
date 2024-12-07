# modules/acm/variables.tf
variable "domain" {
  type        = string
  description = "The domain name for which to create the certificate"
}
variable "validation_record_fqdn" {
  description = "The FQDN of the validation record in Route 53"
  type        = string
}
