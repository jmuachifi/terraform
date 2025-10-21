resource "aws_vpc" "dryrun_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = merge({Name = "dryrun-vpc"}, var.tags)
}