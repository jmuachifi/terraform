# main.tf
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

module "eks" {
  source = "./modules/eks"
  project_name = var.project_name  # Replace "my_project" with the actual project name
  cluster_version = "1.21"         # Replace with the desired Kubernetes version
  # Passing outputs from the VPC module to the EKS module
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

module "ingress" {
  source = "./modules/ingress"
  project_name = var.project_name  # Replace "my_project" with the actual project name
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets
}

module "security" {
  source = "./modules/security"
  project_name = var.project_name  # Replace "my_project" with the actual project name
  vpc_id = module.vpc.vpc_id
}

module "monitoring" {
  source = "./modules/monitoring"
}

module "cicd" {
  source                  = "./modules/cicd"
  role_arn                = "arn:aws:iam::123456789012:role/YourRoleName"  # Replace with your actual role ARN
  artifact_store_location = "s3://your-artifact-store-location"            # Replace with your actual artifact store location
  project_name            = var.project_name                                   # Replace "my_project" with the actual project name
}

module "route53" {
  source = "./modules/route53"
  #alb_dns = module.ingress.alb_dns
  alb_zone_id = module.alb.zone_id
  alb_dns = module.alb.dns_name
  domain = var.domain  # Replace "my_domain.com" with the actual domain name
}

module "acm" {
  source = "./modules/acm"
  domain = var.domain  # Replace "my_domain.com" with the actual domain name
    # Pass the Route 53 record FQDN from the Route 53 module
  validation_record_fqdn = module.route53.record_fqdn
}
module "alb" {
  source          = "./modules/alb"
  project_name    = var.project_name
  internal        = false  # Set to true if you want an internal ALB
  alb_security_group = module.security.eks_sg_id
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id
  listener_port   = 80
  listener_protocol = "HTTP"
}

