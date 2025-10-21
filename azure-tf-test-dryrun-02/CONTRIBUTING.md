# Contributing to AKS Terraform Project

Thank you for considering contributing to this project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Branch Strategy](#branch-strategy)
- [Development Workflow](#development-workflow)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Coding Standards](#coding-standards)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/azure-tf-test-dryrun-02.git
   cd azure-tf-test-dryrun-02
   ```

3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL-ORG/azure-tf-test-dryrun-02.git
   ```

4. Install required tools:
   - Terraform >= 1.5.0
   - Azure CLI >= 2.50.0
   - kubectl
   - pre-commit (optional but recommended)

### Set Up Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## Branch Strategy

We follow a GitFlow-inspired branching model:

```
main (production)
  │
  ├── staging (staging environment)
  │     │
  │     └── develop (development environment)
  │           │
  │           ├── feature/feature-name
  │           ├── bugfix/bug-name
  │           └── hotfix/hotfix-name
  │
  └── hotfix/critical-fix (emergency production fixes)
```

### Branch Types

- **main**: Production-ready code
- **staging**: Pre-production testing
- **develop**: Integration branch for features
- **feature/\***: New features or enhancements
- **bugfix/\***: Bug fixes
- **hotfix/\***: Critical production fixes
- **docs/\***: Documentation updates

## Development Workflow

### 1. Create a Feature Branch

```bash
# Update your local repository
git checkout develop
git pull upstream develop

# Create feature branch
git checkout -b feature/my-new-feature
```

### 2. Make Changes

- Write clean, well-documented code
- Follow Terraform best practices
- Add or update tests as needed
- Update documentation

### 3. Test Your Changes

```bash
# Format Terraform code
terraform fmt -recursive

# Validate Terraform
cd environments/dev
terraform init
terraform validate

# Run plan to check for errors
terraform plan -var-file=terraform.tfvars
```

### 4. Commit Changes

```bash
# Stage changes
git add .

# Commit with conventional commit message
git commit -m "feat: add new networking feature"
```

### 5. Push to Your Fork

```bash
git push origin feature/my-new-feature
```

### 6. Create Pull Request

- Go to the original repository on GitHub
- Click "New Pull Request"
- Select your branch
- Fill in the PR template
- Link related issues

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks
- **perf**: Performance improvements
- **ci**: CI/CD changes

### Examples

```bash
# Feature
git commit -m "feat(aks): add cluster autoscaler configuration"

# Bug fix
git commit -m "fix(networking): correct NSG rule priority"

# Documentation
git commit -m "docs: update deployment guide with new steps"

# Breaking change
git commit -m "feat(terraform)!: upgrade to Terraform 1.6

BREAKING CHANGE: Requires Terraform >= 1.6.0"
```

## Pull Request Process

### PR Checklist

Before submitting a PR, ensure:

- [ ] Code follows project conventions
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Commit messages follow convention
- [ ] PR title follows conventional commits
- [ ] Related issues are linked
- [ ] No sensitive information is committed

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Closes #123

## Testing
Describe how you tested your changes

## Checklist
- [ ] Terraform fmt passed
- [ ] Terraform validate passed
- [ ] Documentation updated
- [ ] No secrets in code
```

### Review Process

1. **Automated Checks**: CI/CD runs automatically
2. **Code Review**: At least one approval required
3. **Testing**: Test in dev environment
4. **Merge**: Squash and merge to target branch

### Merge Requirements

- ✅ All CI checks pass
- ✅ At least 1 approval
- ✅ No unresolved comments
- ✅ Branch is up-to-date with base

## Testing Guidelines

### Terraform Testing

```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Plan (no apply)
terraform plan -var-file=terraform.tfvars

# Check for security issues
checkov -d .

# Lint
tflint --recursive
```

### Integration Testing

```bash
# Deploy to dev environment
cd environments/dev
terraform apply -var-file=terraform.tfvars -auto-approve

# Run tests
kubectl get nodes
kubectl get pods --all-namespaces

# Verify ArgoCD
kubectl get applications -n argocd

# Clean up
terraform destroy -var-file=terraform.tfvars -auto-approve
```

### Test Checklist

- [ ] Terraform fmt passes
- [ ] Terraform validate passes
- [ ] Plan generates expected resources
- [ ] Apply succeeds in dev environment
- [ ] All pods are running
- [ ] Ingress is accessible
- [ ] ArgoCD is syncing
- [ ] No errors in logs

## Coding Standards

### Terraform Style Guide

#### File Organization

```
module/
├── main.tf           # Primary resources
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── versions.tf       # Provider versions
├── locals.tf         # Local values (if needed)
└── README.md         # Module documentation
```

#### Naming Conventions

- **Resources**: Use descriptive names with underscores
  ```hcl
  resource "azurerm_kubernetes_cluster" "aks_cluster" {
    # ...
  }
  ```

- **Variables**: Use snake_case
  ```hcl
  variable "node_pool_min_count" {
    description = "Minimum number of nodes"
    type        = number
  }
  ```

- **Outputs**: Clear, descriptive names
  ```hcl
  output "aks_cluster_id" {
    description = "The ID of the AKS cluster"
    value       = azurerm_kubernetes_cluster.aks_cluster.id
  }
  ```

#### Best Practices

1. **Always provide descriptions**
   ```hcl
   variable "location" {
     description = "Azure region for resources"
     type        = string
   }
   ```

2. **Use input validation**
   ```hcl
   variable "environment" {
     description = "Environment name"
     type        = string
     validation {
       condition     = contains(["dev", "staging", "prod"], var.environment)
       error_message = "Environment must be dev, staging, or prod."
     }
   }
   ```

3. **Set appropriate defaults**
   ```hcl
   variable "enable_auto_scaling" {
     description = "Enable auto-scaling for node pools"
     type        = bool
     default     = true
   }
   ```

4. **Mark sensitive outputs**
   ```hcl
   output "admin_password" {
     description = "Admin password"
     value       = random_password.admin.result
     sensitive   = true
   }
   ```

### Kubernetes Manifests

#### YAML Style

- Use 2 spaces for indentation
- Include resource limits
- Add labels and annotations
- Use namespaces

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production
  labels:
    app: my-app
    version: "1.0"
    environment: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: myapp:1.0
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

### Documentation Standards

- Keep README.md up-to-date
- Document all modules
- Include examples
- Add inline comments for complex logic
- Update CHANGELOG.md

## Environment-Specific Changes

### Development Environment

- Can be deployed and destroyed frequently
- Used for testing new features
- Auto-sync enabled in ArgoCD

### Staging Environment

- Should mirror production configuration
- Used for pre-production testing
- Requires approval for significant changes

### Production Environment

- Requires extra scrutiny
- Changes must be tested in staging first
- Manual ArgoCD sync for safety
- Requires 2 approvals

## Security Guidelines

### DO NOT

- ❌ Commit secrets, passwords, or API keys
- ❌ Commit `*.tfvars` files (except `.example`)
- ❌ Use hardcoded credentials
- ❌ Expose sensitive outputs

### DO

- ✅ Use Azure Key Vault for secrets
- ✅ Use Workload Identity for pod authentication
- ✅ Mark sensitive outputs
- ✅ Use `.gitignore` properly
- ✅ Scan code with security tools

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Creating a Release

1. Update CHANGELOG.md
2. Update version in versions.tf
3. Create and push tag:
   ```bash
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin v1.2.0
   ```
4. Create GitHub release with notes

## Getting Help

- 📖 Read the [documentation](../README.md)
- 💬 Ask in GitHub Discussions
- 🐛 Report bugs via GitHub Issues
- 📧 Contact maintainers

## Recognition

Contributors are recognized in:
- CHANGELOG.md
- GitHub Contributors page
- Release notes

Thank you for contributing! 🎉
