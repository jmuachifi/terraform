# Enterprise AKS Terraform Project with GitOps - Best practice

A production-ready Azure Kubernetes Service (AKS) infrastructure project using Terraform and ArgoCD for GitOps, following industry best practices.

## 🏗️ Architecture

This project provisions a complete AKS infrastructure with:

- **Multi-environment support**: Dev, Staging, and Production
- **High Availability**: Zone-redundant deployments across Azure Availability Zones
- **GitOps**: ArgoCD with App of Apps pattern for declarative application management
- **Networking**: Azure CNI Overlay with dedicated subnets for nodes and pods
- **Security**: Azure Policy, RBAC, Workload Identity, Private endpoints support
- **Monitoring**: Container Insights with Log Analytics
- **Ingress**: NGINX Ingress Controller with automatic TLS via cert-manager
- **CI/CD**: GitHub Actions workflows for automated deployments

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/           # GitHub Actions CI/CD pipelines
│       ├── terraform-plan.yml
│       ├── terraform-apply.yml
│       └── argocd-sync.yml
├── environments/            # Environment-specific configurations
│   ├── dev/
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── backend.tf
│       └── terraform.tfvars
├── k8s/                    # Kubernetes manifests
│   ├── argocd/
│   │   └── bootstrap/      # ArgoCD App of Apps pattern
│   │       ├── app-of-apps.yaml
│   │       ├── infrastructure-appset.yaml
│   │       └── microservices-appset.yaml
│   └── applications/       # Application manifests per environment
│       ├── dev/
│       ├── staging/
│       └── prod/
├── modules/                # Terraform modules
│   ├── networking/         # VNet, subnets, NSG, NAT Gateway
│   ├── aks-cluster/        # AKS cluster with node pools
│   ├── argocd/             # ArgoCD Helm installation
│   ├── nginx-ingress/      # NGINX Ingress Controller
│   └── cert-manager/       # cert-manager for TLS
├── main.tf                 # Root Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── versions.tf             # Provider versions
└── terraform.tfvars.example # Example variables file
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** >= 1.5.0
3. **kubectl** for Kubernetes management
4. **Git** for version control
5. Azure subscription with appropriate permissions

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd azure-tf-test-dryrun-02
   ```

2. **Set up Azure credentials**
   ```bash
   az login
   az account set --subscription "<your-subscription-id>"
   ```

3. **Create backend storage for Terraform state**
   ```bash
   # Create resource group
   az group create --name tfstate-rg --location eastus
   
   # Create storage account
   az storage account create \
     --resource-group tfstate-rg \
     --name tfstateaksproject \
     --sku Standard_LRS \
     --encryption-services blob
   
   # Create blob container
   az storage container create \
     --name tfstate \
     --account-name tfstateaksproject
   ```

4. **Configure environment variables**
   ```bash
   # Copy and edit the example file
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

### Deploy Infrastructure

#### Option 1: Deploy using Terraform CLI

```bash
# Navigate to environment directory
cd environments/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file=terraform.tfvars

# Apply the configuration
terraform apply -var-file=terraform.tfvars -auto-approve

# Get AKS credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name)

# Verify cluster access
kubectl get nodes
```

#### Option 2: Deploy using GitHub Actions

1. Set up GitHub Secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_CREDENTIALS` (JSON format)
   - `TFSTATE_RESOURCE_GROUP`
   - `TFSTATE_STORAGE_ACCOUNT`

2. Push to appropriate branch:
   - `develop` → Dev environment
   - `staging` → Staging environment
   - `main` → Production environment

## 🔧 Configuration

### Environment-Specific Settings

Each environment has its own configuration in `environments/<env>/terraform.tfvars`:

- **Dev**: Minimal resources, single AZ, Free tier
- **Staging**: Medium resources, 2 AZs, Standard tier
- **Production**: Maximum HA, 3 AZs, Standard tier with private cluster

### Network Configuration

The project uses Azure CNI Overlay mode for better IP management:

- **Dev**: 10.10.0.0/16
- **Staging**: 10.20.0.0/16
- **Production**: 10.0.0.0/16

### Node Pools

- **System Node Pool**: For system pods (CoreDNS, metrics-server, etc.)
- **Workload Node Pool**: For application workloads (staging/prod only)

Both pools support auto-scaling and are deployed across availability zones.

## 🎯 GitOps with ArgoCD

### App of Apps Pattern

The project implements the ArgoCD "App of Apps" pattern:

```yaml
app-of-apps (root)
├── infrastructure-appset
│   ├── ingress-nginx
│   ├── cert-manager
│   └── external-dns
└── microservices-appset
    ├── demo-app-dev
    ├── demo-app-staging
    └── demo-app-prod
```

### Accessing ArgoCD

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward to ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser to https://localhost:8080
# Username: admin
# Password: (from above command)
```

### ApplicationSets

The project uses ApplicationSets for managing multiple applications:

1. **Infrastructure ApplicationSet**: Core infrastructure components
2. **Microservices ApplicationSet**: Application workloads per environment

## 🔐 Security Features

### Enabled by Default

- ✅ Azure Policy for governance
- ✅ Azure RBAC for Kubernetes authorization
- ✅ Workload Identity for pod authentication
- ✅ Key Vault Secrets Provider
- ✅ Network policies (Azure CNI)
- ✅ Pod Security Standards
- ✅ Automatic security updates

### Private Cluster (Production)

Enable private cluster for production:

```hcl
private_cluster_enabled = true
```

### RBAC Configuration

Add Azure AD group object IDs for cluster admin access:

```hcl
admin_group_object_ids = [
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
]
```

## 📊 Monitoring and Observability

### Container Insights

Automatically enabled with Log Analytics workspace integration:
- Node and pod metrics
- Container logs
- Cluster health monitoring
- Performance analytics

### Access Monitoring

```bash
# Azure Portal
Open Azure Portal → Your AKS Cluster → Monitoring → Insights

# Or use kubectl
kubectl top nodes
kubectl top pods --all-namespaces
```

## 🔄 Cluster Autoscaling

### Cluster Autoscaler

Configured with best practices:
- Scale down delay: 10 minutes
- Utilization threshold: 50%
- Skip nodes with system pods
- Balance similar node groups

### Horizontal Pod Autoscaler

Example HPA for applications (see prod demo-app):
- CPU-based scaling (70% threshold)
- Memory-based scaling (80% threshold)
- Min replicas: 3
- Max replicas: 10

## 🌐 Ingress and TLS

### NGINX Ingress Controller

- High availability (2 replicas)
- Auto-scaling enabled (2-10 replicas)
- Azure Load Balancer integration

### TLS Certificates

Automatic TLS via cert-manager with Let's Encrypt:
- **Dev/Staging**: Let's Encrypt Staging
- **Production**: Let's Encrypt Production

Example ingress with TLS:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 80
```

## 🧪 Testing

### Validate Terraform

```bash
terraform validate
terraform fmt -check -recursive
```

### Test Connectivity

```bash
# Test cluster access
kubectl get nodes
kubectl get pods --all-namespaces

# Test ingress
kubectl get ingress --all-namespaces

# Test ArgoCD
kubectl get applications -n argocd
```

## 🔨 Maintenance

### Upgrade Kubernetes Version

```hcl
# Update in terraform.tfvars
kubernetes_version = "1.31"
```

### Scale Node Pools

```hcl
# Update node pool configuration
default_node_pool = {
  # ...
  min_count = 3
  max_count = 10
}
```

### Backup and Disaster Recovery

Consider implementing:
- Azure Backup for AKS
- Velero for Kubernetes backups
- Azure Site Recovery for DR

## 📝 Best Practices Implemented

1. **Infrastructure as Code**: Everything defined in Terraform
2. **GitOps**: Declarative application management with ArgoCD
3. **Multi-environment**: Separate configurations for dev/staging/prod
4. **High Availability**: Zone-redundant deployments
5. **Security**: Multiple layers (RBAC, policies, network security)
6. **Monitoring**: Comprehensive observability
7. **Automation**: CI/CD pipelines for all operations
8. **Scalability**: Auto-scaling at both cluster and pod level
9. **Cost Optimization**: Right-sizing per environment

## 🐛 Troubleshooting

### Common Issues

1. **Terraform State Lock**
   ```bash
   # Force unlock (use with caution)
   terraform force-unlock <lock-id>
   ```

2. **AKS Node Issues**
   ```bash
   # Check node status
   kubectl describe node <node-name>
   
   # View node logs
   az aks show -g <rg> -n <cluster> --query agentPoolProfiles
   ```

3. **ArgoCD Sync Failures**
   ```bash
   # Check application status
   kubectl describe application <app-name> -n argocd
   
   # Force sync
   argocd app sync <app-name> --force
   ```

## 📚 Additional Resources

- [Azure AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 👥 Support

For issues and questions:
- Open an issue in GitHub
- Contact the DevOps team

---

**Built with ❤️ by DevOps Engineering Team**
