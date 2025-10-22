# Terraform Local Dry-Run Guide

## Overview

The `dry-run.sh` script validates and tests Terraform configurations locally without touching remote state or deploying to Azure. It's designed for safe, local validation before committing or applying changes.

## What It Does

### 6-Step Validation Process

1. **Format** - Runs `terraform fmt -recursive` to ensure consistent formatting
2. **Validate Environments** - Validates each `environments/*` configuration
3. **Validate Modules** - Validates each `modules/*` independently
4. **Lint** - Runs `tflint` if installed (optional)
5. **Security Scan** - Runs `checkov` if installed (optional)
6. **Plan** - Creates Terraform plans per environment (requires Azure authentication)

### Key Features

- ✅ No backend initialization - never touches remote state
- ✅ Clean provider cache on each run - ensures correct provider versions
- ✅ Dynamic environment discovery
- ✅ Optional environment filtering via arguments
- ✅ Comprehensive validation without cloud access (steps 1-5)
- ✅ Optional plan generation when authenticated (step 6)

## Prerequisites

### Required
- Terraform >= 1.5.0
- Bash shell (Git Bash, WSL, or native Linux/macOS bash)

### Optional
- Azure CLI (`az`) - for authentication and plan generation
- `tflint` - for linting
- `checkov` - for security scanning

## Usage

### Basic Validation (No Azure Needed)

```bash
./dry-run.sh
```

Runs steps 1-5 (format, validate, lint, scan). Skips plan generation if not authenticated.

### Full Validation with Plans (Azure Auth Required)

```bash
# Authenticate first
az login

# Run full validation
./dry-run.sh
```

Runs all 6 steps including plan generation for all environments.

### Target Specific Environments

```bash
# Validate only dev
./dry-run.sh dev

# Validate dev and staging
./dry-run.sh dev staging
```

## Configuration

### Provider Versions

Each environment (`environments/dev`, `environments/staging`, `environments/prod`) has a `versions.tf` file pinning providers to azurerm ~> 3.85:

```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    # ... other providers
  }
}
```

### Environment Variables

If you don't want to use `az login`, you can set environment variables:

```bash
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id"

./dry-run.sh
```

### Terraform Variables

Each environment needs a `terraform.tfvars` file:

```bash
# Copy from example
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars

# Edit with your values
vim environments/dev/terraform.tfvars
```

## Output

### Validation Output

The script shows real-time progress:
- ✅ Success messages for valid configurations
- ⚠️ Warnings for deprecated features (safe to proceed)
- ❌ Errors for invalid configurations (must fix)

### Plan Files

When authenticated, plans are generated per environment:
- `plan-dev.tfplan` - Binary plan file
- `plan-dev.txt` - Human-readable plan output
- `plan-staging.tfplan` / `plan-staging.txt`
- `plan-prod.tfplan` / `plan-prod.txt`

## Common Scenarios

### Before Committing Changes

```bash
# Validate syntax and structure
./dry-run.sh

# If valid, commit
git add .
git commit -m "Update infrastructure configuration"
```

### Before Pull Request

```bash
# Validate all environments
./dry-run.sh

# Or validate specific envs
./dry-run.sh dev staging
```

### Pre-Deployment Validation

```bash
# Authenticate
az login

# Generate and review plans
./dry-run.sh prod

# Review plan
less plan-prod.txt
```

## Troubleshooting

### CRLF Line Ending Issues (Windows)

If you see: `[WARN] Windows line endings detected`

```bash
# Convert to Unix line endings
dos2unix dry-run.sh

# Or use Git to normalize
git add --renormalize dry-run.sh
```

### Provider Version Conflicts

The script automatically cleans `.terraform` directories and lock files to ensure correct provider versions are used. If you see version conflicts:

1. The script will handle it automatically on next run
2. Provider cache is cleaned before each init
3. Version constraints in `versions.tf` are enforced

### Missing terraform.tfvars

If you see: `[SKIP] env: missing terraform.tfvars`

```bash
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
# Edit with your values
```

### Azure Authentication Issues

If plans are skipped with auth message:

```bash
# Option 1: Azure CLI
az login

# Option 2: Service Principal
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_TENANT_ID="..."
export ARM_SUBSCRIPTION_ID="..."
```

## Deprecation Warnings (Expected)

These warnings are safe and expected when using azurerm v3.85:

- ⚠️ `private_endpoint_network_policies_enabled` - Will change in v4, works fine in v3
- ⚠️ `enable_rbac_authorization` - Renamed in v4, works fine in v3
- ⚠️ `metric` in diagnostic settings - Changed to `enabled_metric` in v5

These warnings indicate forward-compatibility notices and don't affect functionality in v3.

## Integration with CI/CD

The script can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Terraform Dry-Run
  run: |
    bash dry-run.sh
  env:
    ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
    ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
    ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
    ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
```

## Best Practices

1. **Run locally before commit** - Catch issues early
2. **Review deprecation warnings** - Plan for future provider upgrades
3. **Check plan output** - Understand what will change before applying
4. **Use version control for plans** - Add `*.tfplan` to `.gitignore`, but keep `.txt` output for review
5. **Validate per environment** - Test changes in dev, staging, then prod
6. **Keep providers pinned** - Avoid unexpected breaking changes

## Exit Codes

- `0` - Success (all validations passed)
- `1` - Validation failures detected
- `127` - Terraform not found in PATH

## What's NOT Done by This Script

- ❌ Does not initialize remote backend
- ❌ Does not read or write remote state
- ❌ Does not apply changes to Azure
- ❌ Does not create or modify Azure resources
- ❌ Does not commit changes to Git

This script is purely for local validation and planning.

## Support

For issues or questions:
1. Check error messages carefully
2. Review this guide
3. Verify provider versions in `versions.tf`
4. Ensure `terraform.tfvars` files exist and are valid
5. Check Azure authentication if planning is needed
