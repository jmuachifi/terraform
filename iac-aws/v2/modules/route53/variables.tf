# modules/route53/variables.tf
# variable "alb_dns" {
#   description = "DNS name of the Application Load Balancer"
#   type        = string
# }

# variable "alb_zone_id" {
#   description = "Zone ID of the Application Load Balancer"
#   type        = string
# }

# variable "domain" {
#   description = "The domain name to associate with the ALB"
#   type        = string
# }

# modules/route53/variables.tf
variable "alb_dns" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

variable "domain" {
  type = string
}


