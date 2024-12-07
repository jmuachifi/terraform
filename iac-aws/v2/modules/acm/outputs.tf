# modules/acm/outputs.tf
output "certificate_arn" {
  value = aws_acm_certificate.certificate.arn
}
