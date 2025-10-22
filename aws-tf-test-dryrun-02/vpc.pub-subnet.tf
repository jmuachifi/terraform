resource "aws_subnet" "dryrun_pub_subnet_1a" {
  vpc_id                  = aws_vpc.dryrun_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = merge({ Name = "dryrun-vpc-pub-subnet-1a" }, var.tags)
}