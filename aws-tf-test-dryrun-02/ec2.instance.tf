data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "dryrun_ec2_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
    key_name      = aws_key_pair.dryrun_key_pair.key_name
  subnet_id     = aws_subnet.dryrun_pub_subnet_1a.id
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags          = merge({Name = "dryrun-ec2-instance"}, var.tags)
}