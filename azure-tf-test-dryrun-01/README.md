# Azure AKS Infrastructure with GitOps and ArgoCD

## 🏗️ Architecture Overview

This project implements a production-ready Azure Kubernetes Service (AKS) infrastructure using Terraform with GitOps principles and ArgoCD for continuous delivery. The architecture follows enterprise best practices for security, scalability, and maintainability.

### Key Components

- **Azure AKS Cluster**: Multi-node pool cluster with auto-scaling
- **Azure Container Registry (ACR)**: Private container registry with geo-replication
- **Azure Key Vault**: Secrets management with RBAC
- **Azure Monitor**: Comprehensive logging and monitoring
- **Virtual Network**: Isolated network with multiple subnets
- **ArgoCD**: GitOps-based continuous delivery
- **NGINX Ingress Controller**: Layer 7 load balancing with TLS
- **cert-manager**: Automated TLS certificate management
- **Cluster Autoscaler**: Automatic node scaling

### Environment Structure

```
├── dev/        # Development environment (develop branch)
├── staging/    # Staging environment (main branch)
└── prod/       # Production environment (main branch with manual approval)
```

## 📋 Prerequisites

1. **Azure CLI**: Install and configure
   ```bash
   az login
   az account set --subscription "<subscription-id>"
   ```

2. **Terraform**: Version >= 1.5.0
   ```bash
   # Windows (using winget)
   winget install Hashicorp.Terraform
   ```

3. **kubectl**: Kubernetes command-line tool
   ```bash
   az aks install-cli
   ```

4. **Azure DevOps**: Account with permissions to create pipelines

5. **Domain Name**: For ingress and TLS certificates (optional)

## 🚀 Quick Start

### Step 1: Initialize Terraform Backend

Create storage accounts for Terraform state:

```bash
# Create resource group for Terraform state
az group create --name tfstate-rg --location eastus

# Create storage accounts for each environment
az storage account create --name tfstatedevaks --resource-group tfstate-rg --location eastus --sku Standard_LRS
az storage account create --name tfstatestgaks --resource-group tfstate-rg --location eastus --sku Standard_LRS
az storage account create --name tfstateprodaks --resource-group tfstate-rg --location eastus --sku Standard_LRS

# Create containers
az storage container create --name tfstate --account-name tfstatedevaks
az storage container create --name tfstate --account-name tfstatestgaks
az storage container create --name tfstate --account-name tfstateprodaks
```

### Step 2: Configure Variables

Copy the example files and update with your values:

```bash
# Dev environment
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Repeat for staging and prod
cd ../staging
cp terraform.tfvars.example terraform.tfvars

cd ../prod
cp terraform.tfvars.example terraform.tfvars
```

### Step 3: Deploy Infrastructure

#### Deploy Dev Environment

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

#### Get AKS Credentials

```bash
# Get cluster credentials
az aks get-credentials \
  --resource-group rg-akscluster-dev \
  --name aks-akscluster-dev \
  --overwrite-existing

# Verify connection
kubectl get nodes
```

### Step 4: Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access ArgoCD at https://localhost:8080 (username: `admin`, password from above command)

### Step 5: Bootstrap GitOps

```bash
# Apply ArgoCD bootstrap configuration
kubectl apply -f gitops/bootstrap/

# Apply infrastructure applications
kubectl apply -f gitops/bootstrap/infrastructure-applicationset.yaml
kubectl apply -f gitops/bootstrap/microservices-applicationset.yaml
```

## 📁 Project Structure

```
azure-tf-test-dryrun-01/
├── environments/              # Environment-specific configurations
│   ├── dev/                  # Development environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   ├── staging/              # Staging environment
│   └── prod/                 # Production environment
├── modules/                  # Reusable Terraform modules
│   ├── aks/                  # AKS cluster module
│   ├── networking/           # Virtual network module
│   ├── acr/                  # Container registry module
│   ├── keyvault/             # Key Vault module
│   └── monitoring/           # Log Analytics & App Insights
├── gitops/                   # GitOps manifests
│   ├── bootstrap/            # ArgoCD bootstrap configs
│   ├── infrastructure/       # Infrastructure components
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── apps/                 # Application manifests
│       └── microservices/
├── azure-pipelines/          # Azure DevOps pipelines
│   ├── terraform-infrastructure.yml
│   └── gitops-sync.yml
├── versions.tf               # Terraform version constraints
├── .gitignore
└── README.md
```

## 🔧 Terraform Modules

### AKS Module

**Features:**
- Managed Identity authentication
- Azure CNI networking
- Separate system and user node pools
- Auto-scaling enabled
- Azure Monitor integration
- Azure Key Vault integration
- Multiple availability zones
- Azure AD RBAC

**Usage:**
```hcl
module "aks" {
  source = "../../modules/aks"
  
  cluster_name               = "aks-myapp-dev"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = "eastus"
  kubernetes_version         = "1.28.3"
  vnet_subnet_id             = module.networking.aks_subnet_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  # ... additional configuration
}
```

### Networking Module

**Features:**
- VNet with multiple subnets
- Network Security Groups
- Private endpoint support
- Subnet for AKS, Application Gateway, and Private Endpoints

### ACR Module

**Features:**
- Premium SKU with geo-replication
- Network rules and private endpoints
- Diagnostic settings
- Integration with AKS via Managed Identity

### Key Vault Module

**Features:**
- RBAC-based access control
- Network ACLs
- Soft delete and purge protection
- Private endpoint support
- Diagnostic logging

### Monitoring Module

**Features:**
- Log Analytics Workspace
- Application Insights
- Container Insights solution
- Key Vault Analytics solution

## 🔄 GitOps with ArgoCD

### App of Apps Pattern

The project uses the App of Apps pattern where a root application manages all other applications:

```yaml
Root App (app-of-apps)
├── Infrastructure Apps (ApplicationSet)
│   ├── nginx-ingress
│   ├── cert-manager
│   ├── cluster-autoscaler
│   └── external-dns
└── Microservices Apps (ApplicationSet)
    ├── demo-app
    └── ...
```

### ApplicationSets

**Infrastructure ApplicationSet:**
- Deploys infrastructure components across environments
- Managed per environment (dev, staging, prod)

**Microservices ApplicationSet:**
- Automatically discovers microservice directories
- Deploys to multiple environments using matrix generator

### Sync Policies

All applications use automated sync with:
- **Prune**: Remove resources deleted from Git
- **Self-heal**: Revert manual changes
- **Retry**: Automatic retry on failures

## 🚦 CI/CD Pipeline

### Infrastructure Pipeline (`terraform-infrastructure.yml`)

**Trigger:** Changes to `environments/`, `modules/`, or `versions.tf`

**Stages:**
1. **Validate**: Terraform validation and format check
2. **Plan Dev**: Create Terraform plan for dev
3. **Apply Dev**: Deploy to dev (develop branch)
4. **Plan Staging**: Create plan for staging
5. **Apply Staging**: Deploy to staging (main branch)
6. **Plan Prod**: Create plan for production
7. **Apply Prod**: Deploy to production (main branch with manual approval)

### GitOps Sync Pipeline (`gitops-sync.yml`)

**Trigger:** Changes to `gitops/` directory

**Stages:**
1. **Validate Manifests**: Validate Kubernetes YAML
2. **Sync to Dev**: Push to dev branch (develop branch)
3. **Sync to Staging**: Push to staging branch (main branch)
4. **Sync to Prod**: Push to prod branch (main branch with approval)

## 🔐 Security Best Practices

### Azure Security

1. **Managed Identity**: All services use managed identity instead of service principals
2. **Private Endpoints**: Key Vault and ACR can use private endpoints
3. **Network Policies**: Azure Network Policy enabled on AKS
4. **RBAC**: Azure AD integration with RBAC
5. **Secrets Management**: Azure Key Vault with CSI driver
6. **Encryption**: All data encrypted at rest and in transit

### Kubernetes Security

1. **Pod Security**: Security contexts configured
2. **Network Policies**: Control pod-to-pod communication
3. **Resource Limits**: CPU and memory limits on all pods
4. **TLS Everywhere**: cert-manager with Let's Encrypt
5. **Image Security**: Pull from private ACR only
6. **RBAC**: Least privilege access control

## 📊 Monitoring and Observability

### Azure Monitor

- **Container Insights**: Cluster and node metrics
- **Log Analytics**: Centralized logging
- **Application Insights**: Application telemetry
- **Alerts**: Configured for critical metrics

### Prometheus and Grafana (Optional)

Deploy via ArgoCD for advanced monitoring:
- Prometheus for metrics collection
- Grafana for visualization
- AlertManager for alerting

## 🔍 Troubleshooting

### Terraform Issues

```bash
# Check Terraform state
terraform show

# Refresh state
terraform refresh

# Import existing resource
terraform import <resource_type>.<name> <azure_resource_id>
```

### AKS Issues

```bash
# Check cluster status
az aks show --resource-group <rg> --name <cluster> --query powerState

# View cluster logs
az aks get-credentials --resource-group <rg> --name <cluster>
kubectl get events --all-namespaces

# Check node status
kubectl describe nodes
```

### ArgoCD Issues

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Check application sync status
kubectl describe application <app-name> -n argocd

# Force sync
argocd app sync <app-name>

# Restart ArgoCD server
kubectl rollout restart deployment argocd-server -n argocd
```

## 📈 Scaling

### Manual Scaling

```bash
# Scale node pool
az aks nodepool scale \
  --resource-group <rg> \
  --cluster-name <cluster> \
  --name <nodepool> \
  --node-count <count>

# Scale deployment
kubectl scale deployment <name> --replicas=<count>
```

### Auto-scaling

- **Node Auto-scaling**: Configured via Terraform (min/max counts)
- **Pod Auto-scaling**: HPA configured for all services
- **Cluster Autoscaler**: Deployed via GitOps

## 💰 Cost Optimization

1. **Use appropriate SKUs**: Free tier for dev, Standard for prod
2. **Right-size node pools**: Use smaller VMs for system pools
3. **Enable autoscaling**: Scale down during off-hours
4. **Use spot instances**: For non-critical workloads
5. **Monitor costs**: Set up cost alerts in Azure

## 🔄 Disaster Recovery

### Backup Strategy

1. **Terraform State**: Stored in Azure Storage with versioning
2. **Application Config**: Version controlled in Git
3. **Secrets**: Replicated in Key Vault with soft delete
4. **Persistent Data**: Use Azure managed disks with backups

### Recovery Procedure

1. Restore Terraform state from backup
2. Run `terraform apply` to recreate infrastructure
3. ArgoCD will automatically sync applications
4. Restore persistent data from backups

## 📚 Additional Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)

## 🤝 Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Test in dev environment
4. Create a pull request to `develop`
5. After approval, merge to `main` for staging/prod

## 📝 License

This project is provided as-is for educational and professional use.

## 👥 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Azure and Kubernetes documentation
3. Open an issue in the repository

---

**Built with ❤️ by DevOps Engineers, for DevOps Engineers**
