# modules/acm/main.tf
resource "aws_acm_certificate" "certificate" {
  domain_name       = var.domain
  validation_method = "DNS"

  subject_alternative_names = [var.domain]
  tags = {
    Name = var.domain
  }
}
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [var.validation_record_fqdn] # Accept this from the Route 53 module
}
