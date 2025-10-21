# Setup Guide

This guide walks you through the complete setup process.

## Prerequisites Checklist

- [ ] Azure subscription with appropriate permissions
- [ ] Azure CLI installed and configured
- [ ] Terraform >= 1.5.0 installed
- [ ] kubectl installed
- [ ] Azure DevOps project created
- [ ] Git repository initialized
- [ ] (Optional) Domain name for ingress

## Step-by-Step Setup

### 1. Configure Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<subscription-id>"

# Get subscription ID
az account show --query id -o tsv

# Create service principal for Terraform (if needed)
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/<subscription-id>"
```

Save the output for Azure DevOps configuration.

### 2. Create Terraform Backend Storage

```bash
# Variables
RESOURCE_GROUP_NAME="tfstate-rg"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage accounts for each environment
declare -a envs=("dev" "stg" "prod")

for env in "${envs[@]}"
do
  STORAGE_ACCOUNT_NAME="tfstate${env}aks"
  
  echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
  
  az storage account create \
    --name $STORAGE_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --sku Standard_LRS \
    --encryption-services blob
  
  # Get storage account key
  ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
  
  # Create container
  az storage container create \
    --name tfstate \
    --account-name $STORAGE_ACCOUNT_NAME \
    --account-key $ACCOUNT_KEY
  
  echo "Storage account $STORAGE_ACCOUNT_NAME created successfully"
done
```

### 3. Configure Azure DevOps

#### Create Service Connection

1. Go to Azure DevOps → Project Settings → Service connections
2. Click "New service connection"
3. Select "Azure Resource Manager"
4. Choose "Service principal (manual)"
5. Enter the service principal details from Step 1
6. Name it `azure-service-connection`
7. Grant access to all pipelines

#### Create Variable Groups

1. Go to Pipelines → Library
2. Create variable group: `terraform-azure-credentials`
3. Add variables:
   - `ARM_CLIENT_ID`: Service principal app ID
   - `ARM_CLIENT_SECRET`: Service principal password (mark as secret)
   - `ARM_SUBSCRIPTION_ID`: Your subscription ID
   - `ARM_TENANT_ID`: Your tenant ID

### 4. Configure Terraform Variables

For each environment (dev, staging, prod):

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
location            = "eastus"
kubernetes_version  = "1.28.3"
admin_group_object_ids = ["<your-azure-ad-group-object-id>"]
```

To get your Azure AD group object ID:

```bash
# List your groups
az ad signed-in-user list-groups --query "[].{Name:displayName, ObjectId:id}" -o table

# Or create a new group for AKS admins
az ad group create --display-name "AKS-Admins" --mail-nickname "aks-admins"
```

### 5. Deploy Dev Environment

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan deployment
terraform plan -out=tfplan

# Review the plan, then apply
terraform apply tfplan
```

This will take 10-15 minutes. Output will include:
- Resource group name
- AKS cluster name
- ACR login server
- Key Vault URI

### 6. Connect to AKS Cluster

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --overwrite-existing

# Verify connection
kubectl get nodes
kubectl get pods --all-namespaces
```

### 7. Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $ARGOCD_PASSWORD"

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access ArgoCD at: https://localhost:8080
- Username: `admin`
- Password: From above command

### 8. Configure ArgoCD

```bash
# Install ArgoCD CLI
winget install argoproj.argocd-cli

# Login to ArgoCD
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure

# Change admin password
argocd account update-password
```

### 9. Bootstrap GitOps

Update the repository URLs in the GitOps manifests:

```bash
# Update all files with your repository URL
find gitops/ -name "*.yaml" -exec sed -i 's|https://dev.azure.com/your-org/your-project/_git/gitops-manifests|<your-repo-url>|g' {} +
```

Apply bootstrap configuration:

```bash
# Apply ArgoCD project
kubectl apply -f gitops/bootstrap/argocd-project.yaml

# Apply ApplicationSets
kubectl apply -f gitops/bootstrap/infrastructure-applicationset.yaml
kubectl apply -f gitops/bootstrap/microservices-applicationset.yaml

# Apply root App of Apps
kubectl apply -f gitops/bootstrap/app-of-apps.yaml
```

Check ArgoCD UI - you should see applications being created and synced.

### 10. Configure Azure DevOps Pipelines

#### Infrastructure Pipeline

1. Go to Pipelines → New Pipeline
2. Select "Azure Repos Git"
3. Choose your repository
4. Select "Existing Azure Pipelines YAML file"
5. Choose `/azure-pipelines/terraform-infrastructure.yml`
6. Save and run

#### GitOps Sync Pipeline

1. Create another pipeline
2. Choose `/azure-pipelines/gitops-sync.yml`
3. Save and run

### 11. Configure DNS and TLS

If using a custom domain:

1. Update DNS records to point to the ingress controller's public IP:

```bash
# Get ingress controller public IP
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

2. Update domain in manifests:
   - `gitops/infrastructure/dev/cluster-issuer.yaml`: Update email
   - `gitops/apps/microservices/demo-app/dev/deployment.yaml`: Update domain

3. Apply changes:

```bash
kubectl apply -f gitops/infrastructure/dev/cluster-issuer.yaml
```

### 12. Verify Deployment

```bash
# Check all namespaces
kubectl get ns

# Check infrastructure components
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager
kubectl get pods -n kube-system | grep autoscaler

# Check demo application
kubectl get pods -n demo-app
kubectl get ingress -n demo-app

# Check ArgoCD applications
argocd app list
```

### 13. Deploy Staging and Production

Once dev is stable:

```bash
# Deploy staging
cd ../../staging
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Deploy production
cd ../prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Post-Setup Tasks

### 1. Configure Monitoring

```bash
# Access Log Analytics workspace
az monitor log-analytics workspace show \
  --resource-group rg-akscluster-dev \
  --workspace-name law-akscluster-dev

# Set up alerts
az monitor metrics alert create \
  --name high-cpu-alert \
  --resource-group rg-akscluster-dev \
  --scopes $(terraform output -raw aks_cluster_id) \
  --condition "avg Percentage CPU > 80" \
  --description "Alert when CPU usage exceeds 80%"
```

### 2. Configure Backup

```bash
# Enable AKS diagnostics
az aks enable-addons \
  --resource-group rg-akscluster-dev \
  --name aks-akscluster-dev \
  --addons monitoring
```

### 3. Configure Access Control

```bash
# Grant AKS access to Azure AD group
az role assignment create \
  --role "Azure Kubernetes Service Cluster User Role" \
  --assignee-object-id <group-object-id> \
  --scope $(terraform output -raw aks_cluster_id)
```

### 4. Test Autoscaling

```bash
# Deploy a test load
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://demo-app.demo-app; done"

# Watch HPA
kubectl get hpa -n demo-app --watch

# Watch nodes
kubectl get nodes --watch
```

## Troubleshooting Common Issues

### Issue: Terraform Backend Access Denied

```bash
# Grant yourself Storage Blob Data Contributor role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --scope "/subscriptions/<subscription-id>/resourceGroups/tfstate-rg/providers/Microsoft.Storage/storageAccounts/tfstatedevaks"
```

### Issue: AKS Cluster Creation Failed

```bash
# Check Azure subscription limits
az vm list-usage --location eastus -o table

# Request quota increase if needed
```

### Issue: ArgoCD Applications Not Syncing

```bash
# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Check repository access
argocd repo list

# Force sync
argocd app sync <app-name> --force
```

### Issue: Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check ingress resource
kubectl describe ingress -n demo-app
```

## Next Steps

1. **Add more applications**: Create new directories in `gitops/apps/microservices/`
2. **Configure monitoring dashboards**: Import Grafana dashboards
3. **Set up CI/CD for applications**: Create build pipelines
4. **Implement network policies**: Add network segmentation
5. **Configure backup and DR**: Set up backup policies
6. **Performance tuning**: Optimize resource requests/limits
7. **Security hardening**: Implement Pod Security Standards

## Useful Commands Reference

```bash
# Terraform
terraform fmt -recursive          # Format code
terraform validate                # Validate configuration
terraform plan                    # Preview changes
terraform apply                   # Apply changes
terraform destroy                 # Destroy infrastructure
terraform output                  # Show outputs

# kubectl
kubectl get all -A                # List all resources
kubectl describe <resource>       # Describe resource
kubectl logs <pod>                # View logs
kubectl exec -it <pod> -- bash    # Shell into pod
kubectl port-forward <pod> 8080:80 # Port forward

# ArgoCD
argocd app list                   # List applications
argocd app get <name>             # Get application details
argocd app sync <name>            # Sync application
argocd app delete <name>          # Delete application
argocd app logs <name>            # View application logs

# Azure CLI
az aks list                       # List AKS clusters
az aks show                       # Show cluster details
az aks get-credentials            # Get kubeconfig
az aks browse                     # Open Kubernetes dashboard
az monitor log-analytics query    # Query logs
```

---

**Setup Complete!** 🎉

You now have a production-ready AKS infrastructure with GitOps! For questions, refer to the main README.md or Azure documentation.
