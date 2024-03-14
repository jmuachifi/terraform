# outputs.tf file is used to define the output variables for the module.
output "public_instance_id" {
  value = module.ec2.public_instance_id
}

output "public_ip" {
    value = module.ec2.public_ip
}
output "elb_dns_name" {
    value = module.ec2.elb_dns_name
}