output "dryrun_private_key" {
  value     = tls_private_key.dryrun_private_key.private_key_pem
  sensitive = true
}