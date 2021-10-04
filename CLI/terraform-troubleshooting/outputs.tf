output "instance_id" {
  description = "ID of the EC2 instance"
  value       = [for instance in aws_instance.web_app : instance.id] #aws_instance.web_app.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = [for instance in aws_instance.web_app : instance.public_ip] #aws_instance.web_app.public_ip
}

output "instance_name" {
  description = "Tags of the EC2 instance"
  value       = [for instance in aws_instance.web_app : instance.tags.Name] #aws_instance.web_app.tags
}
