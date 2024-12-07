# modules/vpc/outputs.tf
# variable "project_name" {

#   description = "The name of the project"

#   type = string
# }

# variable "vpc_id" {
#   description = "The ID of the VPC"
#   type        = string
# }

# variable "subnet_ids" {
#   description = "List of subnet IDs"
#   type        = list(string)
# }
# Define the project name to tag resources appropriately
variable "project_name" {
  description = "The name of the project, used for tagging resources"
  type        = string
}

# Define the CIDR block for the VPC
variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Availability zones for the VPC subnets
variable "azs" {
  description = "A list of availability zones to use for the subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Define the CIDR blocks for the private subnets
variable "private_subnets" {
  description = "A list of CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Define the CIDR blocks for the public subnets
variable "public_subnets" {
  description = "A list of CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Enable or disable the NAT gateway
variable "enable_nat_gateway" {
  description = "Flag to enable or disable NAT Gateway"
  type        = bool
  default     = true
}

# Whether to use a single NAT gateway or one per availability zone
variable "single_nat_gateway" {
  description = "Flag to specify if only a single NAT gateway should be created"
  type        = bool
  default     = true
}

# Optional tags for the resources
variable "tags" {
  description = "Optional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

