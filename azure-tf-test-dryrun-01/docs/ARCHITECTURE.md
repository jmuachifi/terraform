# Architecture Documentation

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure DevOps                              │
│  ┌──────────────────┐           ┌──────────────────┐           │
│  │  Infrastructure  │           │   GitOps Sync    │           │
│  │    Pipeline      │           │    Pipeline      │           │
│  └────────┬─────────┘           └────────┬─────────┘           │
└───────────┼──────────────────────────────┼──────────────────────┘
            │                              │
            ▼                              ▼
┌─────────────────────────┐    ┌────────────────────────┐
│  Azure Infrastructure   │    │  Git Repository        │
│  ┌─────────────────┐   │    │  (GitOps Manifests)    │
│  │  Resource Group │   │    └────────┬───────────────┘
│  │  ┌───────────┐ │   │             │
│  │  │   VNet    │ │   │             │ Watches
│  │  └─────┬─────┘ │   │             │
│  │        │       │   │             ▼
│  │  ┌─────▼─────┐ │   │    ┌────────────────────┐
│  │  │    AKS    │ │◄──┼────┤     ArgoCD         │
│  │  │  Cluster  │ │   │    │  (Running in AKS)  │
│  │  └─────┬─────┘ │   │    └────────────────────┘
│  │        │       │   │
│  │  ┌─────▼─────┐ │   │
│  │  │    ACR    │ │   │
│  │  └───────────┘ │   │
│  │  ┌───────────┐ │   │
│  │  │ Key Vault │ │   │
│  │  └───────────┘ │   │
│  │  ┌───────────┐ │   │
│  │  │   Monitor │ │   │
│  │  └───────────┘ │   │
│  └─────────────────┘   │
└─────────────────────────┘
```

### AKS Cluster Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Load Balancer                       │
│                   (Public IP / Private)                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  NGINX Ingress Controller                    │
│                (Deployed in ingress-nginx NS)                │
└───────────────────────────┬─────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐   ┌──────────────┐
│   Service 1  │    │   Service 2  │   │   Service 3  │
│  (Namespace) │    │  (Namespace) │   │  (Namespace) │
└──────┬───────┘    └──────┬───────┘   └──────┬───────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐   ┌──────────────┐
│ Pod Pod Pod  │    │ Pod Pod Pod  │   │ Pod Pod Pod  │
└──────────────┘    └──────────────┘   └──────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    System Components                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ ArgoCD   │  │cert-mgr  │  │ External │  │ Cluster  │   │
│  │          │  │          │  │   DNS    │  │Autoscaler│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      Node Pools                              │
│  ┌─────────────────────┐      ┌─────────────────────┐      │
│  │   System Pool       │      │    User Pool        │      │
│  │  (3-5 nodes)        │      │   (3-10 nodes)      │      │
│  │  Standard_D4s_v5    │      │  Standard_D4s_v5    │      │
│  │  Critical addons    │      │  Application pods   │      │
│  └─────────────────────┘      └─────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Network Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Virtual Network (10.0.0.0/16)             │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │        AKS Subnet (10.0.1.0/24)                        │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │ │
│  │  │  Node 1  │  │  Node 2  │  │  Node 3  │            │ │
│  │  └──────────┘  └──────────┘  └──────────┘            │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │   Application Gateway Subnet (10.0.2.0/24)            │ │
│  │   (Reserved for future use)                           │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │   Private Endpoints Subnet (10.0.3.0/24)              │ │
│  │   ┌──────────────┐     ┌──────────────┐              │ │
│  │   │  Key Vault   │     │     ACR      │              │ │
│  │   │  Endpoint    │     │   Endpoint   │              │ │
│  │   └──────────────┘     └──────────────┘              │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  Service CIDR: 10.0.4.0/24 (Kubernetes Services)            │
│  DNS Service IP: 10.0.4.10                                   │
└──────────────────────────────────────────────────────────────┘
```

## Component Details

### Terraform Modules

#### 1. AKS Module
**Purpose**: Creates and configures Azure Kubernetes Service cluster

**Key Features**:
- Managed Identity for authentication
- Azure CNI networking for native Azure integration
- Separate system and user node pools
- Auto-scaling configuration
- Azure Monitor integration
- Azure Key Vault CSI driver
- Azure AD RBAC integration

**Resources Created**:
- User Assigned Identity for cluster
- AKS Cluster
- System Node Pool (auto-scaling)
- User Node Pool (auto-scaling)
- Role assignments for networking, ACR, Key Vault

#### 2. Networking Module
**Purpose**: Creates virtual network infrastructure

**Resources Created**:
- Virtual Network
- AKS Subnet with NSG
- Application Gateway Subnet with NSG
- Private Endpoints Subnet
- Network Security Groups

**Security Features**:
- Network isolation
- NSG rules for traffic control
- Private endpoint support

#### 3. ACR Module
**Purpose**: Creates Azure Container Registry

**Features**:
- Premium SKU with geo-replication (prod)
- Network rules and ACLs
- Diagnostic logging
- Integration with AKS via Managed Identity

#### 4. Key Vault Module
**Purpose**: Manages secrets and certificates

**Features**:
- RBAC-based access control
- Network ACLs
- Soft delete and purge protection
- Private endpoint support
- Comprehensive audit logging

#### 5. Monitoring Module
**Purpose**: Centralized monitoring and logging

**Components**:
- Log Analytics Workspace
- Application Insights
- Container Insights solution
- Key Vault Analytics solution

### GitOps Architecture

#### ArgoCD App of Apps Pattern

```
Root Application (app-of-apps)
│
├── Infrastructure ApplicationSet
│   ├── NGINX Ingress Controller (Helm)
│   ├── cert-manager (Helm)
│   ├── Cluster Autoscaler (Manifest)
│   └── External DNS (Helm)
│
└── Microservices ApplicationSet
    ├── Service 1 (per environment)
    ├── Service 2 (per environment)
    └── Service N (per environment)
```

#### Sync Strategy

- **Automated Sync**: Enabled for all applications
- **Self-Heal**: Automatic correction of drift
- **Prune**: Removes deleted resources
- **Retry Logic**: Exponential backoff on failures

### CI/CD Pipeline Architecture

#### Infrastructure Pipeline Flow

```
Commit to Git
      │
      ▼
┌─────────────┐
│  Validate   │ ◄── Terraform fmt, validate
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Plan       │ ◄── Terraform plan
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Approval   │ ◄── Manual gate (staging/prod)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Apply      │ ◄── Terraform apply
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Post-Deploy │ ◄── Install ArgoCD, verify
└─────────────┘
```

#### GitOps Sync Pipeline Flow

```
Commit to gitops/
      │
      ▼
┌─────────────┐
│  Validate   │ ◄── Kubeval, kubectl dry-run
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Branch Sync │ ◄── Push to environment branch
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  ArgoCD     │ ◄── Automatic sync
└─────────────┘
```

## Security Architecture

### Identity and Access Management

```
┌────────────────────────────────────────┐
│         Azure Active Directory         │
│                                        │
│  ┌──────────────┐  ┌──────────────┐  │
│  │  AKS Admins  │  │  Developers  │  │
│  │    Group     │  │    Group     │  │
│  └──────┬───────┘  └──────┬───────┘  │
└─────────┼──────────────────┼──────────┘
          │                  │
          │                  │
          ▼                  ▼
┌────────────────────────────────────────┐
│         AKS Cluster (RBAC)             │
│                                        │
│  ┌──────────────┐  ┌──────────────┐  │
│  │ Cluster Admin│  │  Namespace   │  │
│  │     Role     │  │    Reader    │  │
│  └──────────────┘  └──────────────┘  │
└────────────────────────────────────────┘
```

### Network Security Layers

1. **Perimeter**: Azure Firewall / NSG
2. **Network**: Azure CNI with Network Policies
3. **Application**: Ingress Controller with WAF
4. **Pod**: Security Contexts and Pod Security Standards

### Secret Management Flow

```
Application Pod
      │
      ├─► Key Vault CSI Driver
      │         │
      │         ▼
      │   Azure Key Vault
      │   (Secrets stored)
      │
      └─► Environment Variables
          (Non-sensitive config)
```

## Scalability Architecture

### Horizontal Scaling

- **Pod Level**: HPA based on CPU/Memory
- **Node Level**: Cluster Autoscaler
- **Application Level**: Load balancer distribution

### Vertical Scaling

- Resource requests and limits per pod
- Node pool VM size selection
- Storage class performance tiers

## Monitoring and Observability

### Metrics Collection Flow

```
Application Pods
      │
      ├─► Container Insights ──► Log Analytics
      │                              │
      ├─► Prometheus ───────────► Grafana
      │                              │
      └─► Application Insights ──────┤
                                     │
                                     ▼
                            Azure Monitor Alerts
```

### Log Aggregation

```
All Pods/Nodes
      │
      ▼
Container Insights
      │
      ▼
Log Analytics Workspace
      │
      ├─► KQL Queries
      ├─► Dashboards
      ├─► Alerts
      └─► Workbooks
```

## Disaster Recovery

### Backup Strategy

| Component | Backup Method | Retention | Recovery Time |
|-----------|---------------|-----------|---------------|
| Terraform State | Azure Storage with versioning | 30 days | < 5 min |
| Git Repository | Azure Repos replication | Indefinite | < 1 min |
| AKS Configuration | GitOps (IaC) | Indefinite | 15-30 min |
| Application Data | Azure Managed Disks | 7-30 days | Varies |
| Secrets | Key Vault with soft delete | 90 days | < 5 min |

### Recovery Procedure

1. **Infrastructure Loss**:
   - Restore Terraform state
   - Run `terraform apply`
   - ArgoCD auto-syncs applications

2. **Data Loss**:
   - Restore from managed disk snapshots
   - Replay from backup storage

3. **Region Failure**:
   - Deploy to secondary region
   - Update DNS
   - Restore from geo-replicated resources

## Performance Considerations

### Resource Optimization

- **CPU**: Burstable for dev, guaranteed for prod
- **Memory**: Appropriate limits to prevent OOM
- **Storage**: Premium SSD for databases, Standard for logs
- **Network**: Azure CNI for optimal performance

### Caching Strategy

- Application-level caching (Redis/Memcached)
- CDN for static assets
- HTTP caching at Ingress level

## Cost Optimization

### Environment-Specific Sizing

| Environment | Node Count | Node Size | Cost/Month (approx) |
|-------------|------------|-----------|---------------------|
| Dev | 2-3 | Standard_D2s_v5 | $200-300 |
| Staging | 3-5 | Standard_D4s_v5 | $600-1000 |
| Production | 3-10 | Standard_D4s_v5 | $1200-4000 |

### Cost-Saving Strategies

1. **Auto-scaling**: Scale down during off-hours
2. **Spot VMs**: For non-critical workloads
3. **Reserved Instances**: For predictable workloads
4. **Right-sizing**: Regular review of resource usage

---

**Last Updated**: 2025-10-21
**Version**: 1.0.0
