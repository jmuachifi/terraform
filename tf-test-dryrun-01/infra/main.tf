terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

locals {
  name = "${var.project}-${var.environment}"
  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

data "aws_availability_zones" "available" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = "${local.name}-eks"
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
      disk_size      = 20
      tags           = local.tags
    }
  }

  enable_irsa = true

  tags = local.tags
}

# Set up Kubernetes and Helm providers using EKS cluster auth
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}
# Resolve latest compatible addon versions
data "aws_eks_addon_version" "cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = var.cluster_version
  most_recent        = true
}
# EKS Addons
resource "aws_eks_addon" "cni" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "vpc-cni"
  addon_version = data.aws_eks_addon_version.cni.version
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "coredns"
  addon_version = data.aws_eks_addon_version.coredns.version
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "kube-proxy"
  addon_version = data.aws_eks_addon_version.kube_proxy.version
}

# IRSA for Cluster Autoscaler
data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name   = "${local.name}-cluster-autoscaler"
  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name                       = "${local.name}-cluster-autoscaler"
  attach_cluster_autoscaler_policy = false
  cluster_autoscaler_cluster_ids   = []
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ca_attach" {
  role       = module.cluster_autoscaler_irsa.iam_role_name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

# Deploy Cluster Autoscaler via GitOps (Argo CD Application)
resource "kubectl_manifest" "app_cluster_autoscaler" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "cluster-autoscaler"
      namespace = var.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://kubernetes.github.io/autoscaler"
        chart          = "cluster-autoscaler"
        targetRevision = "9.36.0"
        helm = {
          values = <<EOT
autoDiscovery:
  clusterName: ${module.eks.cluster_name}
awsRegion: ${var.aws_region}
rbac:
  serviceAccount:
    create: true
    name: cluster-autoscaler
    annotations:
      eks.amazonaws.com/role-arn: ${module.cluster_autoscaler_irsa.iam_role_arn}
extraArgs:
  balance-similar-node-groups: "true"
  skip-nodes-with-system-pods: "false"
  expander: "least-waste"
EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "kube-system"
      }
      syncPolicy = {
        automated = { prune = true, selfHeal = true }
      }
    }
  })
  depends_on = [kubectl_manifest.argocd_core]
}

# cert-manager via Argo CD
resource "kubectl_manifest" "app_cert_manager" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "cert-manager"
      namespace = var.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://charts.jetstack.io"
        chart          = "cert-manager"
        targetRevision = "v1.15.1"
        helm = { values = "installCRDs=true" }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "cert-manager"
      }
      syncPolicy = { automated = { prune = true, selfHeal = true } }
    }
  })
  depends_on = [kubectl_manifest.argocd_core]
}

# AWS Load Balancer Controller IRSA and Application
data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name   = "${local.name}-alb-controller"
  policy = data.http.alb_policy.response_body
}

module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${local.name}-alb-controller"
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = module.alb_controller_irsa.iam_role_name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubectl_manifest" "app_aws_load_balancer_controller" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "aws-load-balancer-controller"
      namespace = var.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://aws.github.io/eks-charts"
        chart          = "aws-load-balancer-controller"
        targetRevision = "1.7.2"
        helm = {
          values = <<EOT
clusterName: ${module.eks.cluster_name}
region: ${var.aws_region}
vpcId: ${module.vpc.vpc_id}
serviceAccount:
  create: true
  name: aws-load-balancer-controller
  annotations:
    eks.amazonaws.com/role-arn: ${module.alb_controller_irsa.iam_role_arn}
EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "kube-system"
      }
      syncPolicy = { automated = { prune = true, selfHeal = true } }
    }
  })
  depends_on = [kubectl_manifest.argocd_core]
}



resource "kubernetes_namespace" "argocd" {
  count = var.enable_argocd ? 1 : 0
  metadata {
    name = var.argocd_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Install Argo CD via official pinned manifest
data "http" "argocd" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.7/manifests/install.yaml"
}

data "kubectl_file_documents" "argocd" {
  content = data.http.argocd.response_body
}

locals {
  argocd_all_docs = { for idx, doc in data.kubectl_file_documents.argocd.documents : idx => doc }
  argocd_crd_docs = {
    for idx, doc in local.argocd_all_docs : idx => doc
    if try(yamldecode(doc).kind, null) == "CustomResourceDefinition"
  }
  argocd_non_crd_docs = {
    for idx, doc in local.argocd_all_docs : idx => doc
    if try(yamldecode(doc).kind, null) != "CustomResourceDefinition" && try(yamldecode(doc).kind, null) != "Namespace"
  }
}

resource "kubectl_manifest" "argocd_crds" {
  for_each  = var.enable_argocd ? local.argocd_crd_docs : {}
  yaml_body = each.value
  depends_on = [kubernetes_namespace.argocd]
}

resource "kubectl_manifest" "argocd_core" {
  for_each  = var.enable_argocd ? local.argocd_non_crd_docs : {}
  yaml_body = each.value
  depends_on = [kubectl_manifest.argocd_crds]
}

# ArgoCD Root Application that points to this repo's gitops/apps path
resource "kubectl_manifest" "argocd_root_app" {
  count = var.enable_argocd ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-apps"
      namespace = var.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.github_repo_url
        targetRevision = var.github_repo_revision
        path           = var.github_repo_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.argocd_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  })
  depends_on = [kubectl_manifest.argocd_core]
}
