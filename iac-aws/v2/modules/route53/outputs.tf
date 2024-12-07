# modules/route53/outputs.tf
output "zone_id" {
  value = aws_route53_zone.main.zone_id
}
output "record_fqdn" {
  value = aws_route53_record.www.fqdn
}

