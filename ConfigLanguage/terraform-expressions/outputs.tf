#output "tags" {
output "first_tags" {
  #value = aws_instance.ubuntu.tags
  value = aws_instance.ubuntu[0].tags
}
output "private_addresses" {
  value = aws_instance.ubuntu[*].private_dns
}
