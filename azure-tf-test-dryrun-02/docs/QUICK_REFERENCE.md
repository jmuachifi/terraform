# Quick Reference Guide

This document provides quick reference commands and configurations for common tasks.

## Table of Contents

1. [Quick Commands](#quick-commands)
2. [Configuration Cheat Sheet](#configuration-cheat-sheet)
3. [Troubleshooting Commands](#troubleshooting-commands)
4. [Useful Scripts](#useful-scripts)

## Quick Commands

### Terraform Operations

```bash
# Initialize Terraform
cd environments/<env>
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars

# Destroy infrastructure
terraform destroy -var-file=terraform.tfvars

# Show current state
terraform show

# List resources
terraform state list

# Output values
terraform output
terraform output -json > outputs.json
```

### Azure CLI Commands

```bash
# Login
az login

# Set subscription
az account set --subscription "subscription-name"

# Get AKS credentials
az aks get-credentials --resource-group <rg> --name <cluster-name>

# Browse AKS in portal
az aks browse --resource-group <rg> --name <cluster-name>

# List AKS clusters
az aks list --output table

# Get AKS versions
az aks get-versions --location eastus --output table

# Update kubeconfig
az aks get-credentials --resource-group <rg> --name <cluster-name> --overwrite-existing

# List node pools
az aks nodepool list --resource-group <rg> --cluster-name <cluster-name> --output table

# Scale node pool
az aks nodepool scale --resource-group <rg> --cluster-name <cluster-name> --name <pool-name> --node-count 5
```

### kubectl Commands

```bash
# Get cluster info
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Get all resources
kubectl get all --all-namespaces

# Get pods in specific namespace
kubectl get pods -n <namespace>
kubectl get pods -n <namespace> -o wide

# Describe resource
kubectl describe pod <pod-name> -n <namespace>
kubectl describe node <node-name>

# View logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --follow
kubectl logs <pod-name> -n <namespace> --previous

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Port forward
kubectl port-forward svc/<service-name> -n <namespace> 8080:80

# Get events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Top resources
kubectl top nodes
kubectl top pods --all-namespaces

# Config view
kubectl config view
kubectl config current-context
kubectl config get-contexts
```

### ArgoCD Commands

```bash
# Login to ArgoCD CLI
argocd login <server-address> --username admin --password <password>

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# List applications
argocd app list
kubectl get applications -n argocd

# Get application details
argocd app get <app-name>
kubectl describe application <app-name> -n argocd

# Sync application
argocd app sync <app-name>
argocd app sync <app-name> --force

# Get sync status
argocd app get <app-name> --refresh

# Set sync policy
argocd app set <app-name> --sync-policy automated

# Delete application
argocd app delete <app-name>

# Port forward to ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Configuration Cheat Sheet

### Environment Variables

```bash
# Azure credentials
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"

# Terraform state backend
export TF_BACKEND_RESOURCE_GROUP="tfstate-rg"
export TF_BACKEND_STORAGE_ACCOUNT="tfstateaksproject"
export TF_BACKEND_CONTAINER="tfstate"
```

### Common Terraform Variables

```hcl
# Basic configuration
project_name        = "myproject"
environment         = "dev"
location            = "eastus"
kubernetes_version  = "1.31"

# Networking
vnet_address_space      = ["10.10.0.0/16"]
aks_subnet_address      = ["10.10.0.0/24"]
pod_subnet_address      = ["10.10.1.0/24"]
ingress_subnet_address  = ["10.10.2.0/24"]

# Node pool
default_node_pool = {
  name       = "system"
  vm_size    = "Standard_D2s_v3"
  min_count  = 2
  max_count  = 3
  zones      = ["1"]
}

# Features
enable_argocd           = true
enable_nginx_ingress    = true
enable_cert_manager     = true
private_cluster_enabled = false
```

### Kubernetes Resource Limits

```yaml
# Small workload
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

# Medium workload
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi

# Large workload
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi
```

## Troubleshooting Commands

### Check Cluster Health

```bash
# Node status
kubectl get nodes
kubectl describe nodes

# Pod status in all namespaces
kubectl get pods --all-namespaces | grep -v Running

# Check system pods
kubectl get pods -n kube-system

# Check ArgoCD
kubectl get pods -n argocd

# Check ingress
kubectl get pods -n ingress-nginx
kubectl get ingress --all-namespaces
```

### Debug Pod Issues

```bash
# Get pod details
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>

# Get events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pod <pod-name> -n <namespace>

# Get pod YAML
kubectl get pod <pod-name> -n <namespace> -o yaml
```

### Network Troubleshooting

```bash
# Test connectivity from a pod
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- /bin/bash

# Inside the debug pod:
nslookup <service-name>.<namespace>.svc.cluster.local
curl http://<service-name>.<namespace>.svc.cluster.local
ping <pod-ip>

# Check services
kubectl get svc --all-namespaces

# Check endpoints
kubectl get endpoints --all-namespaces

# Check network policies
kubectl get networkpolicies --all-namespaces
```

### Certificate Issues

```bash
# Check cert-manager status
kubectl get pods -n cert-manager

# Check certificates
kubectl get certificates --all-namespaces
kubectl describe certificate <cert-name> -n <namespace>

# Check certificate requests
kubectl get certificaterequests --all-namespaces

# Check cluster issuers
kubectl get clusterissuers

# View cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### ArgoCD Sync Issues

```bash
# Check application status
kubectl get applications -n argocd
argocd app get <app-name>

# View sync errors
kubectl describe application <app-name> -n argocd

# Force sync
argocd app sync <app-name> --force

# Refresh application
argocd app get <app-name> --refresh

# View ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-repo-server
```

### Performance Issues

```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods --all-namespaces

# Check HPA status
kubectl get hpa --all-namespaces

# Check cluster autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler

# Azure Monitor
az monitor metrics list --resource <resource-id> --metric "Percentage CPU"
```

## Useful Scripts

### Deploy to Environment

```bash
#!/bin/bash
ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./deploy.sh <dev|staging|prod>"
  exit 1
fi

cd "environments/$ENVIRONMENT"
terraform init
terraform plan -var-file=terraform.tfvars
read -p "Apply changes? (yes/no): " confirm
if [ "$confirm" == "yes" ]; then
  terraform apply -var-file=terraform.tfvars
fi
```

### Get AKS Credentials

```bash
#!/bin/bash
ENVIRONMENT=$1

cd "environments/$ENVIRONMENT"
RG=$(terraform output -raw resource_group_name)
CLUSTER=$(terraform output -raw aks_cluster_name)

az aks get-credentials --resource-group "$RG" --name "$CLUSTER" --overwrite-existing
kubectl get nodes
```

### Check All Pods

```bash
#!/bin/bash
echo "=== Checking all pods ==="
kubectl get pods --all-namespaces | grep -v Running | grep -v Completed

echo ""
echo "=== Pod resource usage ==="
kubectl top pods --all-namespaces | sort -k3 -rn | head -20

echo ""
echo "=== Failed pods ==="
kubectl get pods --all-namespaces --field-selector=status.phase=Failed
```

### Backup Kubernetes Resources

```bash
#!/bin/bash
BACKUP_DIR="backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up resources to $BACKUP_DIR"

# Backup namespaces
kubectl get namespaces -o yaml > "$BACKUP_DIR/namespaces.yaml"

# Backup deployments
kubectl get deployments --all-namespaces -o yaml > "$BACKUP_DIR/deployments.yaml"

# Backup services
kubectl get services --all-namespaces -o yaml > "$BACKUP_DIR/services.yaml"

# Backup configmaps
kubectl get configmaps --all-namespaces -o yaml > "$BACKUP_DIR/configmaps.yaml"

# Backup secrets (be careful with these!)
kubectl get secrets --all-namespaces -o yaml > "$BACKUP_DIR/secrets.yaml"

# Backup ingresses
kubectl get ingresses --all-namespaces -o yaml > "$BACKUP_DIR/ingresses.yaml"

echo "Backup complete!"
```

### ArgoCD Status Check

```bash
#!/bin/bash
echo "=== ArgoCD Applications Status ==="
kubectl get applications -n argocd

echo ""
echo "=== Sync Status ==="
argocd app list

echo ""
echo "=== Out of Sync Applications ==="
argocd app list | grep OutOfSync

echo ""
echo "=== Failed Applications ==="
kubectl get applications -n argocd -o json | \
  jq -r '.items[] | select(.status.health.status=="Degraded") | .metadata.name'
```

### Scale Node Pool

```bash
#!/bin/bash
RG=$1
CLUSTER=$2
POOL=$3
COUNT=$4

if [ $# -ne 4 ]; then
  echo "Usage: ./scale-nodepool.sh <resource-group> <cluster-name> <pool-name> <count>"
  exit 1
fi

echo "Scaling node pool $POOL to $COUNT nodes..."
az aks nodepool scale \
  --resource-group "$RG" \
  --cluster-name "$CLUSTER" \
  --name "$POOL" \
  --node-count "$COUNT"

echo "Done! New node status:"
kubectl get nodes
```

## GitHub Actions Secrets

Required secrets for CI/CD:

```
AZURE_CLIENT_ID          = "<your-client-id>"
AZURE_CLIENT_SECRET      = "<your-client-secret>"
AZURE_SUBSCRIPTION_ID    = "<your-subscription-id>"
AZURE_TENANT_ID          = "<your-tenant-id>"
TFSTATE_RESOURCE_GROUP   = "tfstate-rg"
TFSTATE_STORAGE_ACCOUNT  = "tfstateaksproject"

AZURE_CREDENTIALS = {
  "clientId": "<client-id>",
  "clientSecret": "<client-secret>",
  "subscriptionId": "<subscription-id>",
  "tenantId": "<tenant-id>"
}
```

## Common URLs

```bash
# ArgoCD UI (after port-forward)
https://localhost:8080

# Kubernetes Dashboard (if enabled)
kubectl proxy
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# Azure Portal
https://portal.azure.com

# Terraform Registry
https://registry.terraform.io
```

## Resource Naming Convention

```
<project>-<environment>-<resource-type>-<region>

Examples:
- myproject-dev-aks-eastus
- myproject-prod-vnet-eastus
- myproject-staging-rg-eastus
```

## Tags Convention

```hcl
tags = {
  Environment = "dev"
  Project     = "myproject"
  ManagedBy   = "terraform"
  Owner       = "devops-team"
  CostCenter  = "engineering"
}
```

## Quick Links

- [Azure Documentation](https://learn.microsoft.com/en-us/azure/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager Documentation](https://cert-manager.io/docs/)

---

**Tip**: Bookmark this page for quick reference during operations!
