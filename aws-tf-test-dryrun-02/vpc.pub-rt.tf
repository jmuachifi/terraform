resource "aws_route_table" "dryrun_pub_rt" {
  vpc_id = aws_vpc.dryrun_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dryrun_vpc_igw.id
  }

  tags = merge({ Name = "dryrun-vpc-pub-rt" }, var.tags)
}

resource "aws_route_table_association" "dryrun_pub_subnet_rt_association" {
  subnet_id      = aws_subnet.dryrun_pub_subnet_1a.id
  route_table_id = aws_route_table.dryrun_pub_rt.id
}