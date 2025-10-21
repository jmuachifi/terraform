resource "tls_private_key" "dryrun_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "dryrun_key_pair" {
  key_name   = "dryrun-private-key"
  public_key = tls_private_key.dryrun_private_key.public_key_openssh
}