# modules/ingress/outputs.tf
output "alb_dns" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)"
  value       = aws_lb.alb.zone_id
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.alb.arn
}

output "alb_security_group_id" {
  description = "The ID of the security group associated with the ALB"
  value       = aws_security_group.alb_sg.id
}