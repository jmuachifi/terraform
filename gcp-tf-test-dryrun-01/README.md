# Overview

This repository provisions Google Kubernetes Engine (GKE) clusters for multiple environments using Terraform modules and bootstraps GitOps delivery with Argo CD in an App-of-Apps pattern. GitHub Actions drives both the Terraform workflow and GitOps validation.

## Repository layout

```text
envs/                  # Environment-specific Terraform entrypoints
modules/               # Reusable Terraform modules
.gitops/workflows/     # GitHub Actions pipelines (Terraform + GitOps)
gitops/                # Argo CD configuration (bootstrap + infrastructure + services)
```

### Environments

| Environment | Branch        | Backend prefix        | Notes                                  |
|-------------|---------------|-----------------------|----------------------------------------|
| dev         | `develop`     | `state/dev`           | Fast feedback, non-production settings |
| staging     | `staging`     | `state/staging`       | Pre-production, mirrors prod settings  |
| prod        | `main`        | `state/prod`          | Production workloads                    |

Each environment directory (`envs/<env>`) contains its own `backend.tf`, `providers.tf`, and `main.tf` entrypoints. Remote state is stored in a Google Cloud Storage bucket; update the bucket name before applying.

## Bootstrapping

1. **Create shared resources (once):**
   - GCS bucket for Terraform state (enable versioning).
   - Artifact Registry for container images (optional, not managed here).
   - Google Cloud IAM Workload Identity Pool & Provider for GitHub Actions.
2. **Configure secrets:**
   - `TF_VAR_project_id` for each environment.
   - `GOOGLE_WORKLOAD_IDENTITY_PROVIDER` and `GOOGLE_SERVICE_ACCOUNT` at the repository level.
3. **Bootstrap Terraform:**
   ```bash
   cd envs/dev
   terraform init -backend-config="bucket=<state-bucket>" -backend-config="prefix=state/dev"
   terraform plan
   ```
4. **Deploy Argo CD:**
   - Terraform installs Argo CD via Helm (module `argocd-bootstrap`).
   - Apply `gitops/bootstrap/argocd-root-application.yaml` once so Argo CD starts managing itself and downstream workloads.

## GitOps structure

- `gitops/bootstrap/` contains the App-of-Apps entrypoint and namespace bootstrap.
- `gitops/platform/` hosts infrastructure add-ons delivered through Argo CD (Ingress NGINX, cert-manager, cluster-autoscaler).
- `gitops/applicationsets/` defines ApplicationSets for multi-environment services sourced from `gitops/services/`.
- `gitops/services/service-template/` provides a Kustomize skeleton for team services.

Argo CD watches the repository branch that matches the environment (e.g., `staging` branch syncs to staging cluster).

## GitHub Actions pipelines

- `terraform-gke.yml` runs plan/apply for Terraform using OIDC to authenticate with Google Cloud. Plans run for PRs; applies run on merges to the designated environment branch.
- `gitops-ci.yml` validates GitOps manifests (Kubernetes schema + Kustomize build) on pull requests and can optionally trigger Argo CD sync.

Configure required repository secrets/variables referenced in the workflows before enabling them.

## Next steps

1. Update variables (`terraform.tfvars`) per environment with CIDR ranges, node pool sizing, and release channels.
2. Create `letsencrypt` DNS challenge configuration inside `gitops/platform/cert-manager/values.yaml`.
3. Duplicate `service-template` to onboard applications using the provided ApplicationSet pattern.

> **Note:** The sample configuration enables Workload Identity for GKE, network policies, managed control plane upgrades, and autoscaling-ready node pools. Adjust limits based on your workload requirements.
