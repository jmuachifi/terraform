# modules/eks/main.tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.21.0" # Specify the version of the EKS module

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  # Enable IAM Roles for Service Accounts (IRSA)
  enable_irsa = true

  # Control public and private API access
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Tags for the EKS cluster
  tags = {
    "Environment" = var.project_name
  }

  # EKS Managed Node Groups configuration
  eks_managed_node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3.medium"

      # Node group-specific tags
      tags = {
        "Name"        = "${var.project_name}-eks-nodes"
        "Environment" = var.project_name
      }
    }
  }

}
