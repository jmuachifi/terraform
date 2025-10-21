terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  bucket_name = var.state_bucket_name != null ? var.state_bucket_name : lower(replace("${var.project}-tfstate-${var.environment}", "_", "-"))
  table_name  = var.state_table_name != null ? var.state_table_name : lower(replace("${var.project}-tf-lock-${var.environment}", "_", "-"))
  repo_name   = element(split("/", var.github_repository), 1)
}

resource "aws_s3_bucket" "tf_state" {
  bucket = local.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

# GitHub OIDC provider for AWS (if not already present in the account)
data "aws_iam_openid_connect_provider" "github" {
  arn = var.github_oidc_provider_arn
  count = var.github_oidc_provider_arn != null ? 1 : 0
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_oidc_provider_arn == null ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  oidc_provider_arn = var.github_oidc_provider_arn != null ? var.github_oidc_provider_arn : aws_iam_openid_connect_provider.github[0].arn
}


data "aws_iam_policy_document" "gha_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Allow main branch and PRs from same repo
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${local.repo_name}:ref:refs/heads/main",
        "repo:${var.github_owner}/${local.repo_name}:ref:refs/heads/stage",
        "repo:${var.github_owner}/${local.repo_name}:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "gha_oidc_role" {
  name               = "${var.project}-${var.environment}-gha-oidc"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
  description        = "Role assumed by GitHub Actions via OIDC to run Terraform"
  max_session_duration = 3600
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "gha_permissions" {
  statement {
    sid     = "TerraformCore"
    actions = [
      "sts:GetCallerIdentity",
      "ec2:Describe*",
      "iam:Get*",
      "iam:List*",
      "eks:Describe*",
      "eks:List*",
      "cloudformation:Describe*",
      "cloudformation:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid = "TerraformManage"
    actions = [
      "s3:*",
      "dynamodb:*",
      "iam:*",
      "eks:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "ecr:*",
      "logs:*",
      "cloudwatch:*",
      "kms:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gha_permissions" {
  name        = "${var.project}-${var.environment}-gha-tf"
  description = "Permissions for Terraform to manage EKS and supporting resources"
  policy      = data.aws_iam_policy_document.gha_permissions.json
}

resource "aws_iam_role_policy_attachment" "gha_permissions" {
  role       = aws_iam_role.gha_oidc_role.name
  policy_arn = aws_iam_policy.gha_permissions.arn
}

output "state_bucket_name" { value = aws_s3_bucket.tf_state.id }
output "state_lock_table" { value = aws_dynamodb_table.tf_lock.name }
output "github_oidc_provider_arn" { value = local.oidc_provider_arn }
output "github_actions_role_arn" { value = aws_iam_role.gha_oidc_role.arn }
