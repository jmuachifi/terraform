# Architecture Overview

## System Architecture

This project implements a multi-layered cloud-native architecture on Azure, following best practices for security, scalability, and reliability.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          GitHub Repository                       │
│  ┌─────────────────┐    ┌──────────────────┐                   │
│  │ Terraform Code  │    │  K8s Manifests   │                   │
│  │   (IaC Layer)   │    │  (GitOps Layer)  │                   │
│  └─────────────────┘    └──────────────────┘                   │
└──────────────┬────────────────────┬───────────────────────────┘
               │                    │
               │ GitHub Actions     │ ArgoCD Sync
               ▼                    ▼
┌──────────────────────────────────────────────────────────────────┐
│                        Azure Cloud Platform                       │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   AKS Cluster (Control Plane)              │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │          System Node Pool (Availability Zones)      │  │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │  │
│  │  │  │   AZ-1   │  │   AZ-2   │  │   AZ-3   │          │  │  │
│  │  │  │ CoreDNS  │  │  Metrics │  │  kube-   │          │  │  │
│  │  │  │  ArgoCD  │  │  Server  │  │  proxy   │          │  │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘          │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │      Workload Node Pool (Availability Zones)        │  │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │  │
│  │  │  │   AZ-1   │  │   AZ-2   │  │   AZ-3   │          │  │  │
│  │  │  │  NGINX   │  │   Apps   │  │  Cert    │          │  │  │
│  │  │  │ Ingress  │  │   Pods   │  │ Manager  │          │  │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘          │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Networking Layer                          │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │  │
│  │  │   VNet      │  │    Subnets   │  │   NSG/Routes    │  │  │
│  │  │ 10.x.0.0/16 │  │ - AKS Nodes  │  │  - Firewall     │  │  │
│  │  │             │  │ - Pods       │  │  - NAT Gateway  │  │  │
│  │  │             │  │ - Ingress    │  │                 │  │  │
│  │  └─────────────┘  └──────────────┘  └─────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Supporting Services                       │  │
│  │  ┌──────────────┐  ┌───────────┐  ┌──────────────────┐   │  │
│  │  │Log Analytics │  │ Key Vault │  │  Load Balancers  │   │  │
│  │  │  Workspace   │  │           │  │  - Public        │   │  │
│  │  │              │  │           │  │  - Internal      │   │  │
│  │  └──────────────┘  └───────────┘  └──────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Infrastructure Layer (Terraform)

#### Modules

- **Networking Module**
  - Creates isolated VNet per environment
  - Configures 3 subnets: AKS nodes, pods (CNI Overlay), ingress
  - Implements NSG rules and route tables
  - Deploys NAT Gateway for secure outbound traffic

- **AKS Cluster Module**
  - Provisions managed Kubernetes cluster
  - Configures system and workload node pools
  - Enables Azure CNI Overlay for efficient IP management
  - Integrates with Azure Monitor and Log Analytics

- **GitOps Modules**
  - ArgoCD: Continuous deployment platform
  - NGINX Ingress: Layer 7 load balancing
  - Cert-Manager: Automated TLS certificate management

### 2. Networking Architecture

#### Network Segmentation

```
Azure VNet (10.x.0.0/16)
├── AKS Subnet (10.x.0.0/24)
│   ├── System nodes
│   ├── Workload nodes
│   └── Service endpoints
├── Pod Subnet (10.x.1.0/24)
│   └── CNI Overlay pods
└── Ingress Subnet (10.x.2.0/24)
    └── Load balancer endpoints
```

#### Traffic Flow

```
Internet
    │
    ▼
Azure Load Balancer (Public)
    │
    ▼
NGINX Ingress Controller
    │
    ├──▶ TLS Termination
    │
    ▼
Kubernetes Services
    │
    ├──▶ Service A (Pods)
    ├──▶ Service B (Pods)
    └──▶ Service C (Pods)
         │
         ▼
    Azure Services
    (via Service Endpoints)
```

### 3. Security Architecture

#### Defense in Depth

```
┌─────────────────────────────────────────────────┐
│ Layer 1: Network Security                       │
│ - NSG rules                                     │
│ - Azure Firewall (optional)                     │
│ - Private Link/Endpoints                        │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Layer 2: Cluster Security                       │
│ - Azure Policy                                  │
│ - Azure RBAC                                    │
│ - Pod Security Standards                        │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Layer 3: Application Security                   │
│ - Network Policies                              │
│ - Service Mesh (optional)                       │
│ - Workload Identity                             │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Layer 4: Data Security                          │
│ - Encryption at rest                            │
│ - TLS in transit                                │
│ - Key Vault integration                         │
└─────────────────────────────────────────────────┘
```

### 4. GitOps Architecture

#### ArgoCD App of Apps Pattern

```
app-of-apps (Root Application)
│
├── Infrastructure ApplicationSet
│   ├── ingress-nginx
│   │   └── Helm Chart
│   ├── cert-manager
│   │   ├── CRDs
│   │   └── ClusterIssuers
│   └── external-dns (optional)
│       └── DNS automation
│
└── Microservices ApplicationSets
    ├── Dev Environment
    │   ├── Auto-sync: Enabled
    │   ├── Auto-prune: Enabled
    │   └── demo-app
    ├── Staging Environment
    │   ├── Auto-sync: Enabled
    │   ├── Auto-prune: Enabled
    │   └── demo-app
    └── Production Environment
        ├── Auto-sync: Manual
        ├── Auto-prune: Disabled
        └── demo-app
```

### 5. CI/CD Architecture

#### GitHub Actions Workflow

```
┌──────────────────────────────────────────────────┐
│         Developer Workflow                        │
└──────────────────────────────────────────────────┘
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
    Feature Branch        Main Branch
          │                   │
          ▼                   │
    Pull Request              │
          │                   │
          ▼                   │
    Terraform Plan            │
    (GitHub Actions)          │
          │                   │
          ▼                   │
    Code Review               │
          │                   │
          ▼                   │
    Merge to Target           │
          │                   │
          └─────────┬─────────┘
                    ▼
          Branch Detection
          (develop/staging/main)
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
         Dev    Staging     Prod
          │         │         │
          ▼         ▼         ▼
    Terraform Apply (Auto)
          │         │         │
          ▼         ▼         ▼
    ArgoCD Sync (Auto)
          │         │         │
          ▼         ▼         ▼
    Deploy to AKS
```

## Environment Strategy

### Environment Configurations

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Availability Zones** | 1 | 2 | 3 |
| **Node Count (System)** | 2-3 | 2-4 | 3-6 |
| **Node Count (Workload)** | N/A | 2-4 | 3-10 |
| **VM Size** | D2s_v3 | D4s_v3 | D4s_v3 |
| **SLA** | Free | Standard (99.9%) | Standard (99.95%) |
| **Private Cluster** | No | No | Yes (optional) |
| **Auto-scaling** | Yes | Yes | Yes |
| **Monitoring** | Basic | Full | Full |
| **Backup** | No | Optional | Yes |
| **DR** | No | Optional | Yes |

### State Management

```
Azure Storage Account
├── tfstate Container
│   ├── dev.terraform.tfstate
│   ├── staging.terraform.tfstate
│   └── prod.terraform.tfstate
```

## Scalability Architecture

### Horizontal Scaling

1. **Cluster Autoscaler**
   - Monitors pod resource requests
   - Scales node pool up/down based on demand
   - Respects min/max node counts

2. **Horizontal Pod Autoscaler (HPA)**
   - Scales pods based on CPU/memory
   - Custom metrics support (via KEDA)
   - Min/max replica configuration

### Vertical Scaling

1. **Node Pool Scaling**
   - Change VM size via Terraform
   - Zero-downtime node upgrades
   - Blue-green node pool strategy

## Monitoring Architecture

### Observability Stack

```
┌────────────────────────────────────────────┐
│          Application Pods                   │
│  (Emitting logs, metrics, traces)          │
└───────────────┬────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│        Container Insights Agent             │
│  (Collects container metrics & logs)       │
└───────────────┬────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│      Azure Log Analytics Workspace          │
│  ├── Container logs                         │
│  ├── Metrics                                │
│  ├── Performance data                       │
│  └── Audit logs                             │
└───────────────┬────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│        Monitoring & Alerting                │
│  ├── Azure Monitor                          │
│  ├── Application Insights (optional)        │
│  └── Grafana dashboards (optional)          │
└────────────────────────────────────────────┘
```

## High Availability Design

### Multi-Zone Deployment

- Nodes distributed across availability zones
- Pod anti-affinity rules for critical workloads
- Zone-redundant load balancers

### Failure Scenarios

| Scenario | Impact | Recovery |
|----------|--------|----------|
| Single node failure | Minimal - pods reschedule | Automatic (30-60s) |
| Availability zone failure | Partial - one zone down | Automatic (<5min) |
| Region outage | Full - requires DR | Manual failover |
| Control plane issue | Read-only cluster | Azure manages recovery |

## Cost Optimization

### Cost Breakdown

```
Monthly Cost Estimate (Production)
├── AKS Cluster
│   ├── Control Plane: Free (managed by Azure)
│   ├── System Node Pool: 3x D4s_v3 = ~$350/month
│   └── Workload Node Pool: 3-10x D4s_v3 = ~$350-$1,200/month
├── Networking
│   ├── VNet: Free
│   ├── NAT Gateway: ~$50/month
│   └── Load Balancers: ~$20/month
├── Storage
│   ├── Managed Disks: ~$30/month
│   └── Terraform State: ~$1/month
└── Monitoring
    └── Log Analytics: ~$100/month (based on ingestion)

Total: ~$900-$1,750/month
```

### Cost Optimization Strategies

1. **Right-sizing**: Use appropriate VM sizes per environment
2. **Auto-scaling**: Scale down during off-hours
3. **Reserved Instances**: 1-3 year commitments for production
4. **Spot Instances**: For non-critical workloads
5. **Resource Quotas**: Prevent resource waste

## Security Considerations

### Best Practices Implemented

- ✅ Network segmentation with NSGs
- ✅ Azure RBAC for access control
- ✅ Workload Identity (no service principals in pods)
- ✅ Key Vault integration for secrets
- ✅ Private endpoints for Azure services
- ✅ TLS encryption for ingress
- ✅ Pod Security Standards enforcement
- ✅ Azure Policy for governance
- ✅ Container image scanning (recommended)
- ✅ Network policies for pod-to-pod communication

## Disaster Recovery

### Backup Strategy

1. **AKS Configuration**: Stored in Git (Infrastructure as Code)
2. **Application State**: Use Velero for backup/restore
3. **Persistent Data**: Azure Backup for PVCs
4. **Terraform State**: Versioned in Azure Storage

### Recovery Time Objectives (RTO/RPO)

| Scenario | RTO | RPO |
|----------|-----|-----|
| Pod failure | 1 minute | 0 (stateless) |
| Node failure | 5 minutes | 0 (stateless) |
| Cluster rebuild | 30 minutes | Last commit |
| Region failure | 4 hours | Last backup |

## Future Enhancements

1. **Service Mesh**: Implement Istio or Linkerd
2. **Advanced Monitoring**: Prometheus + Grafana stack
3. **Policy Enforcement**: OPA/Gatekeeper
4. **External DNS**: Automatic DNS record management
5. **Application Gateway**: WAF capabilities
6. **Azure Front Door**: Global load balancing
7. **Chaos Engineering**: Azure Chaos Studio
8. **Cost Management**: Kubecost integration
