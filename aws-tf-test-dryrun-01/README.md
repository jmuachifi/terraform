# Terraform EKS + GitOps (Argo CD) Starter - Best practice

This repo provisions a production-grade AWS EKS cluster with Terraform and bootstraps GitOps with Argo CD, plus a GitHub Actions pipeline using OpenID Connect (OIDC) to assume an AWS IAM role (no long-lived secrets).

## What you get
- Remote Terraform state (S3 + DynamoDB locking)
- EKS cluster via community modules (IRSA enabled)
- VPC with public/private subnets and NAT
- Argo CD installed by Terraform (official manifest)
- GitOps root Application pointing to `gitops/cluster`
- GitHub Actions pipeline: fmt/validate/plan on PR, apply on main
- Sample app: `gitops/apps/sample-nginx`

## Prereqs
- Terraform >= 1.6
- AWS account and credentials to run the bootstrap step
- GitHub repository (this repo) with Actions enabled

## 1) Bootstrap remote state and GitHub OIDC
Run from `bootstrap/` once per account/region:

1. Set variables (example):
   - `project`: short name, e.g., `tf-test`
   - `environment`: e.g., `prod`
   - `aws_region`: e.g., `us-east-1`
   - `github_owner`: your org/user
   - `github_repository`: `owner/repo`

2. Init and apply:

```bash
cd bootstrap
terraform init
terraform apply -auto-approve \
  -var="project=tf-test" \
  -var="environment=prod" \
  -var="aws_region=us-east-1" \
  -var="github_owner=OWNER" \
  -var="github_repository=OWNER/REPO"
```

3. Note the outputs:
   - `state_bucket_name`
   - `state_lock_table`
   - `github_actions_role_arn`

4. Update `envs/prod/backend.hcl` with bucket+table, and set a repository secret:
   - Secret `AWS_GHA_ROLE_ARN` = the `github_actions_role_arn` output

## 2) Configure environment variables/values
Copy the example tfvars and edit:

```bash
cp envs/prod/terraform.tfvars.example.txt envs/prod/terraform.tfvars
# edit OWNER/REPO and tags as needed
```

Make sure `github_repo_url` matches your repository URL and `github_repo_path` stays `gitops/cluster`.

## 3) Provision infra locally (optional)
If you want to run Terraform locally first:

```bash
cd infra
terraform init -backend-config=../envs/prod/backend.hcl -reconfigure
terraform plan -var-file=../envs/prod/terraform.tfvars
terraform apply -var-file=../envs/prod/terraform.tfvars -auto-approve
```
> Extra commands - Global sanity(no chnages made) <br>
```
# From repo root
terraform -version

# Formatting check (fails if files need fmt)
terraform fmt -check -recursive

# Validate each Terraform package without touching backends
terraform -chdir=bootstrap init -backend=false
terraform -chdir=bootstrap validate

terraform -chdir=infra init -backend=false
terraform -chdir=infra validate
```
> Extra commands - Boostrap dry-run(plan only) <br>
```
# Initialize and plan bootstrap (remote state/prereqs)
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan -out .bootstrap.tfplan -detailed-exitcode
if ($LASTEXITCODE -eq 2) { "Bootstrap: changes pending" } elseif ($LASTEXITCODE -eq 0) { "Bootstrap: no changes" } else { "Bootstrap: error" }

# Human-readable plan (no apply)
terraform -chdir=bootstrap show -no-color .bootstrap.tfplan | Out-File -Encoding utf8 .bootstrap.plan.txt
```
> Exra commands - Infra dry-run for stage <br>
```
# Initialize with stage backend
terraform -chdir=infra init -backend-config=../envs/stage/backend.hcl

# Validate with real providers
terraform -chdir=infra validate

# Create stage plan (exit code 0=no changes, 2=changes, 1=error)
terraform -chdir=infra plan -var-file=../envs/stage/terraform.tfvars -out=stage.tfplan -detailed-exitcode
if ($LASTEXITCODE -eq 2) { "Stage: changes pending" } elseif ($LASTEXITCODE -eq 0) { "Stage: no changes" } else { "Stage: error" }

# Save a readable copy of the plan
terraform -chdir=infra show -no-color stage.tfplan | Out-File -Encoding utf8 stage.plan.txt
```
> Extra commands - Infra dry-run for prod <br>
```
# Initialize with prod backend
terraform -chdir=infra init -backend-config=../envs/prod/backend.hcl

# Validate with real providers
terraform -chdir=infra validate

# Create prod plan (exit code 0=no changes, 2=changes, 1=error)
terraform -chdir=infra plan -var-file=../envs/prod/terraform.tfvars -out=prod.tfplan -detailed-exitcode
if ($LASTEXITCODE -eq 2) { "Prod: changes pending" } elseif ($LASTEXITCODE -eq 0) { "Prod: no changes" } else { "Prod: error" }

# Save a readable copy of the plan
terraform -chdir=infra show -no-color prod.tfplan | Out-File -Encoding utf8 prod.plan.txt
```

## 4) GitHub Actions pipeline
- On PRs: fmt/validate/plan
- On main: plan+apply

Set repo secret `AWS_GHA_ROLE_ARN` to the OIDC role ARN from bootstrap. The workflow uses the backend config in `envs/prod/backend.hcl`.

## 5) Access Argo CD
Argo CD server is installed via the upstream manifest. Expose it via an ingress controller or patch the Service type as needed. For quick tests, you can port-forward:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
# Visit https://localhost:8080
```

Default admin password is the Argo CD admin secret:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

## 6) GitOps sample app
An example `sample-nginx` Application lives at `gitops/cluster/apps.yaml` which points to `gitops/apps/sample-nginx`. Argo CD will sync it automatically.

## Notes and best practices
- Versions are pinned for providers and modules.
- EKS IRSA enabled for future workload IAM roles.
- NAT gateway set to single to control cost; scale per need.
- Use separate AWS accounts per environment; duplicate `envs/<env>`.
- Consider cluster add-ons (Cluster Autoscaler, ExternalDNS, Cert-Manager, Ingress Controller) via GitOps.

## Destroy
From `infra/`:

```bash
terraform destroy -var-file=../envs/prod/terraform.tfvars -auto-approve
```

Then manually remove the S3 bucket and DynamoDB table after emptying them.