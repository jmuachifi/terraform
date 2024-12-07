# modules/vpc/outputs.tf
# output "vpc_id" {
#   description = "The ID of the VPC"
#   value       = module.vpc.vpc_id
# }

# output "public_subnets" {
#   description = "The public subnets"
#   value       = module.vpc.public_subnets
# }

# output "private_subnets" {
#   description = "The private subnets"
#   value       = module.vpc.private_subnets
# }
# Outputs for VPC module

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

