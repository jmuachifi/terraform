# Azure AKS Deployment Guide

## Prerequisites

### Required Tools

1. **Azure CLI** (version 2.50.0 or later)
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. **Terraform** (version 1.5.0 or later)
   ```bash
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

3. **kubectl** (latest version)
   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

4. **ArgoCD CLI** (optional but recommended)
   ```bash
   curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
   sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
   rm argocd-linux-amd64
   ```

### Azure Account Setup

1. **Login to Azure**
   ```bash
   az login
   ```

2. **Set subscription**
   ```bash
   az account list --output table
   az account set --subscription "<your-subscription-id>"
   ```

3. **Create Service Principal for Terraform**
   ```bash
   az ad sp create-for-rbac --name "terraform-aks" --role Contributor --scopes /subscriptions/<subscription-id>
   ```
   
   Save the output:
   ```json
   {
     "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
     "displayName": "terraform-aks",
     "password": "xxxxxxxxxxxxxxxxxxxx",
     "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   }
   ```

## Step-by-Step Deployment

### Step 1: Prepare Backend Storage

```bash
# Variables
RESOURCE_GROUP_NAME="tfstate-rg"
STORAGE_ACCOUNT_NAME="tfstateaksproject"  # Must be globally unique
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob \
  --location $LOCATION

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --account-key $ACCOUNT_KEY
```

### Step 2: Configure Environment

```bash
# Clone repository
git clone <your-repo-url>
cd azure-tf-test-dryrun-02

# Choose environment (dev, staging, or prod)
ENVIRONMENT="dev"

# Copy and configure variables
cp terraform.tfvars.example environments/$ENVIRONMENT/terraform.tfvars

# Edit the file with your values
nano environments/$ENVIRONMENT/terraform.tfvars
```

### Step 3: Initialize Terraform

```bash
cd environments/$ENVIRONMENT

# Set Azure credentials
export ARM_CLIENT_ID="<your-app-id>"
export ARM_CLIENT_SECRET="<your-password>"
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_TENANT_ID="<your-tenant-id>"

# Initialize Terraform
terraform init \
  -backend-config="resource_group_name=$RESOURCE_GROUP_NAME" \
  -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" \
  -backend-config="container_name=$CONTAINER_NAME" \
  -backend-config="key=${ENVIRONMENT}.terraform.tfstate"
```

### Step 4: Plan and Apply

```bash
# Review the plan
terraform plan -var-file=terraform.tfvars -out=tfplan

# Apply the configuration
terraform apply tfplan

# This will take 10-15 minutes
```

### Step 5: Configure kubectl

```bash
# Get cluster credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --overwrite-existing

# Verify access
kubectl get nodes
kubectl get namespaces
```

### Step 6: Deploy ArgoCD Applications

```bash
# Go back to project root
cd ../..

# Update Git repository URL in ArgoCD manifests
# Edit k8s/argocd/bootstrap/*.yaml files and replace YOUR-ORG/YOUR-REPO

# Apply ArgoCD bootstrap
kubectl apply -f k8s/argocd/bootstrap/

# Wait for applications to sync
kubectl get applications -n argocd -w
```

### Step 7: Access ArgoCD UI

```bash
# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $ARGOCD_PASSWORD"

# Port forward to ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Open browser to https://localhost:8080
# Username: admin
# Password: (from above)
```

### Step 8: Verify Installation

```bash
# Check all pods are running
kubectl get pods --all-namespaces

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check cert-manager
kubectl get pods -n cert-manager

# Check demo application
kubectl get pods -n demo-app
```

## GitHub Actions Setup

### Configure GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions

Add the following secrets:

1. **AZURE_CLIENT_ID**: Service Principal App ID
2. **AZURE_CLIENT_SECRET**: Service Principal Password
3. **AZURE_SUBSCRIPTION_ID**: Your Azure Subscription ID
4. **AZURE_TENANT_ID**: Your Azure Tenant ID
5. **AZURE_CREDENTIALS**: JSON format
   ```json
   {
     "clientId": "<client-id>",
     "clientSecret": "<client-secret>",
     "subscriptionId": "<subscription-id>",
     "tenantId": "<tenant-id>"
   }
   ```
6. **TFSTATE_RESOURCE_GROUP**: tfstate-rg
7. **TFSTATE_STORAGE_ACCOUNT**: tfstateaksproject

### Configure Branch Protection

1. Go to Settings → Branches → Add rule
2. Branch name pattern: `main`
3. Enable:
   - Require a pull request before merging
   - Require status checks to pass
   - Require branches to be up to date

### Trigger Deployment

```bash
# For dev environment
git checkout -b feature/my-change
# Make changes
git add .
git commit -m "feat: add new feature"
git push origin feature/my-change
# Create PR to develop branch

# For production
# Merge to main branch (requires approval)
```

## Post-Deployment Configuration

### Configure DNS

1. Get ingress IP address:
   ```bash
   kubectl get svc -n ingress-nginx
   ```

2. Create DNS A records pointing to the ingress IP:
   - `demo-dev.example.com` → Ingress IP
   - `demo.example.com` → Ingress IP

### Enable Monitoring

1. Azure Portal → Your AKS Cluster → Monitoring → Insights
2. Review:
   - Cluster health
   - Node performance
   - Pod metrics
   - Container logs

### Configure Alerts

```bash
# Example: Create alert for high CPU usage
az monitor metrics alert create \
  --name high-cpu-alert \
  --resource-group $(terraform output -raw resource_group_name) \
  --scopes $(terraform output -raw aks_cluster_id) \
  --condition "avg Percentage CPU > 80" \
  --description "Alert when CPU usage exceeds 80%"
```

## Upgrading

### Upgrade Kubernetes Version

1. Check available versions:
   ```bash
   az aks get-upgrades --resource-group <rg> --name <cluster-name>
   ```

2. Update `kubernetes_version` in terraform.tfvars

3. Apply changes:
   ```bash
   terraform plan -var-file=terraform.tfvars
   terraform apply -var-file=terraform.tfvars
   ```

### Upgrade ArgoCD

```bash
# Update chart version in modules/argocd/main.tf
# Then run terraform apply
```

## Cleanup

### Destroy Infrastructure

```bash
cd environments/$ENVIRONMENT

# Review what will be destroyed
terraform plan -destroy -var-file=terraform.tfvars

# Destroy resources
terraform destroy -var-file=terraform.tfvars -auto-approve

# This will take 5-10 minutes
```

### Remove Backend Storage

```bash
# Optional: Delete terraform state storage
az group delete --name tfstate-rg --yes --no-wait
```

## Troubleshooting

### Issue: Terraform State Lock

```bash
# List locks
az storage blob list --container-name tfstate --account-name $STORAGE_ACCOUNT_NAME

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: AKS Authentication Failed

```bash
# Re-login to Azure
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

# Get new credentials
az aks get-credentials \
  --resource-group <rg> \
  --name <cluster-name> \
  --overwrite-existing
```

### Issue: ArgoCD Not Syncing

```bash
# Check application status
kubectl describe application <app-name> -n argocd

# Manual sync
argocd app sync <app-name> --force

# Or via kubectl
kubectl patch application <app-name> -n argocd \
  -p '{"metadata": {"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge
```

## Next Steps

1. **Add more applications** to `k8s/applications/`
2. **Configure monitoring** with Prometheus and Grafana
3. **Set up backup** with Velero
4. **Implement network policies** for pod communication
5. **Configure external-dns** for automatic DNS management
6. **Add WAF** with Azure Application Gateway
7. **Implement pod security policies**
8. **Configure Azure Key Vault integration**

## Support

For issues:
- Check the [Troubleshooting](#troubleshooting) section
- Review Azure AKS documentation
- Open an issue in the GitHub repository
