resource "aws_internet_gateway" "dryrun_vpc_igw" {
  vpc_id = aws_vpc.dryrun_vpc.id
  tags = merge({Name = "dryrun-vpc-igw"}, var.tags)
}