# Azure Terraform Dry-Run Validation

A comprehensive Terraform validation and deployment testing framework for Azure infrastructure. This project provides local validation without requiring Azure credentials, plus optional plan generation with authentication.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Validation Steps](#validation-steps)
- [Configuration](#configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## 🎯 Overview

This project validates Terraform configurations for Azure infrastructure locally before deployment. The `dry-run.sh` script performs six validation steps:

1. **Code Formatting** - Ensures consistent Terraform style
2. **Root Configuration Validation** - Validates core Terraform syntax
3. **Module Validation** - Validates any custom modules (if present)
4. **Linting** - Checks for best practices using tflint
5. **Security Scanning** - Identifies security issues using Checkov
6. **Plan Generation** - Creates execution plans (requires Azure credentials)

**Key Benefits:**
- ✅ Validate without Azure credentials for steps 1-5
- ✅ Catch syntax errors early
- ✅ Enforce security best practices
- ✅ Generate execution plans for review before deployment
- ✅ Colorized output for easy reading

---

## 📦 Prerequisites

### Required Tools

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| **Terraform** | >= 1.0.0 | Infrastructure as Code | [Download](https://www.terraform.io/downloads) |
| **Bash** | 4.0+ | Script execution | Git Bash on Windows, pre-installed on Linux/Mac |

### Optional Tools (for enhanced validation)

| Tool | Purpose | Install |
|------|---------|---------|
| **tflint** | Terraform linting | `brew install tflint` or see [docs](https://github.com/terraform-linters/tflint) |
| **Checkov** | Security scanning | `pip install checkov` |
| **AWS CLI** | For credential management (if using AWS) | `brew install awscli` |

### Azure Requirements (for Step 6 - Plan Generation)

For generating Terraform plans, you'll need:
- **Azure Subscription ID**
- **Azure Tenant ID**
- **Service Principal Client ID**
- **Service Principal Client Secret**

---

## 📁 Project Structure

```
azure-tf-test-dryrun-03/
├── dry-run.sh                  # Main validation script
├── README.md                   # This file
├── main.tf                     # Provider configuration
├── variables.tf                # Input variables
├── output.tf                   # Output values
├── rg.tf                       # Resource Group definition
├── vnet.tf                     # Virtual Network definition
├── vnet-sub1.tf                # Subnet 1 definition
├── vnet-sub2.tf                # Subnet 2 definition
├── vnet-interface.tf           # Network Interface and Public IP
├── nsg.tf                      # Network Security Group definition
├── vm.tf                       # Virtual Machine definition
├── .tflint.hcl                 # TFLint configuration (optional)
├── .checkov.yml                # Checkov configuration (optional)
├── .terraform/                 # Terraform working directory (auto-generated)
├── .terraform.lock.hcl         # Provider lock file (auto-generated)
└── .tflint.d/                  # TFLint plugins directory (auto-generated)
```

### Key Files Description

| File | Purpose |
|------|---------|
| `dry-run.sh` | Main validation script - run this for complete validation |
| `main.tf` | Defines the Azure provider and required providers |
| `variables.tf` | Declares all input variables for the infrastructure |
| `output.tf` | Defines outputs that will be displayed after deployment |
| `rg.tf` | Creates the Azure Resource Group |
| `vnet.tf` | Creates the Virtual Network with DNS servers |
| `vnet-sub1.tf`, `vnet-sub2.tf` | Create two subnets within the VNet |
| `vnet-interface.tf` | Creates Network Interface and Public IP for VM connectivity |
| `nsg.tf` | Creates Network Security Group with SSH access rule |
| `vm.tf` | Creates the Azure Virtual Machine (Ubuntu 18.04-LTS) |

---

## 🚀 Quick Start

### 1. Check Prerequisites

```bash
# Verify Terraform is installed
terraform version

# Verify Bash is available
bash --version
```

### 2. Run Local Validation (No Credentials Required)

```bash
# Navigate to project directory
cd /path/to/azure-tf-test-dryrun-03

# Run the validation script
bash dry-run.sh
```

### 3. Review Validation Results

The script will output results for each step with color-coded status:
- ✅ `✓` - Success
- ⚠️ `⚠` - Warning (non-critical)
- ❌ `✗` - Error (requires action)

---

## 🔍 Validation Steps

### Step 1: Code Formatting

**Purpose:** Ensures all Terraform files follow consistent style guidelines.

**What it does:**
- Runs `terraform fmt -recursive`
- Reformats all `.tf` files to canonical style
- Reports files that were modified

**Example Output:**
```
[1/6] ▶ Formatting Terraform code...
✓ All files properly formatted
```

---

### Step 2: Root Configuration Validation

**Purpose:** Validates the main Terraform configuration syntax.

**What it does:**
- Initializes Terraform without a backend (`-backend=false`)
- Runs `terraform validate`
- Checks for syntax errors and resource references

**Example Output:**
```
[2/6] ▶ Validating root configuration...
✓ Root configuration is valid
```

**Common Errors:**
- `Error: Failed to initialize Terraform` - Check provider requirements in `main.tf`
- `Error: Reference to undeclared resource` - Ensure all referenced resources are declared

---

### Step 3: Module Validation

**Purpose:** Validates any custom Terraform modules in a `modules/` directory.

**What it does:**
- Checks if `modules/` directory exists
- Validates each module independently
- Reports any module-level errors

**Example Output:**
```
[3/6] ▶ Validating Terraform modules...
ℹ No modules directory found; skipping module validation
```

**To add modules:**
Create a `modules/` directory with subdirectories for each module:
```
modules/
├── vm/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── networking/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

---

### Step 4: Linting with tflint

**Purpose:** Checks for best practices, naming conventions, and common mistakes.

**What it does:**
- Initializes tflint with configured rules
- Runs recursive linting across all `.tf` files
- Reports issues by severity level

**Example Output:**
```
[4/6] ▶ Linting Terraform configuration...
✓ TFLint passed with no issues
```

**Install tflint:**

**macOS:**
```bash
brew install tflint
```

**Windows (Chocolatey):**
```bash
choco install tflint
```

**Linux (with wget):**
```bash
wget https://github.com/terraform-linters/tflint/releases/download/v0.50.0/tflint_linux_amd64.zip
unzip tflint_linux_amd64.zip
sudo mv tflint /usr/local/bin/
```

**Common tflint Rules:**
- Naming conventions (snake_case for resources)
- Unused variables and outputs
- Required attributes in resource definitions
- Provider version pinning

---

### Step 5: Security Scanning with Checkov

**Purpose:** Identifies security vulnerabilities and compliance violations.

**What it does:**
- Scans all Terraform files for security issues
- Checks against industry compliance frameworks (CIS, PCI-DSS, etc.)
- Reports passed and failed checks

**Example Output:**
```
[5/6] ▶ Running Checkov security scan...
⚠ Security scan found some issues
    Passed checks: 11, Failed checks: 6, Skipped checks: 0
```

**Install Checkov:**

**macOS/Linux:**
```bash
pip install checkov
```

**Windows (with Python 3.7+):**
```bash
pip install checkov
```

**Common Security Issues:**
- Hardcoded credentials or secrets
- Unrestricted network access (0.0.0.0/0 CIDR)
- Unencrypted storage or databases
- Missing authentication mechanisms
- Default or weak security configurations

**To suppress specific checks, update `.checkov.yml`:**
```yaml
quiet: true
compact: true
skip-check:
  - CKV_AZURE_1  # Example: Azure VM with public IP
  - CKV_AZURE_2  # Example: Network security groups allow unrestricted access
```

---

### Step 6: Terraform Plan Generation

**Purpose:** Creates an execution plan showing what resources will be created/modified.

**What it does:**
- Requires Azure credentials (subscription, tenant, service principal)
- Generates `.tfplan` binary files for each environment
- Creates human-readable `.txt` plan files
- Shows resource changes before actual deployment

**Example Output:**
```
[6/6] ▶ Creating local Terraform plans...
✓ Plan created for dev
  Binary: plan-dev.tfplan
  Human:  plan-dev.txt
```

**Prerequisites:**
1. Create `envs/dev/terraform.tfvars` file with Azure credentials
2. Authenticate with Azure

**Setting Up Azure Credentials:**

**Option 1: Environment Variables**
```bash
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
```

**Option 2: terraform.tfvars File**
```bash
mkdir -p envs/dev
cat > envs/dev/terraform.tfvars <<EOF
subscription_id = "<your-subscription-id>"
tenant_id       = "<your-tenant-id>"
client_id       = "<your-client-id>"
client_secret   = "<your-client-secret>"
resource_group_name = "dryrun-resource-group"
location        = "East US"
admin_username  = "azureuser"
admin_password  = "P@ssw0rd!"
EOF
```

**⚠️ Security Warning:** Never commit `terraform.tfvars` with credentials to version control. Add to `.gitignore`:
```bash
echo "envs/**/*.tfvars" >> .gitignore
echo "envs/**/*.tfvars.json" >> .gitignore
```

---

## ⚙️ Configuration

### Terraform Variables

Edit `variables.tf` to customize input variables. Default values are:

| Variable | Default | Description |
|----------|---------|-------------|
| `subscription_id` | (required) | Azure subscription ID |
| `tenant_id` | (required) | Azure AD tenant ID |
| `client_id` | (required) | Service Principal client ID |
| `client_secret` | (required) | Service Principal client secret |
| `resource_group_name` | `dryrun-resource-group` | Resource group name |
| `location` | `East US` | Azure region |
| `admin_username` | `azureuser` | VM admin username |
| `admin_password` | `P@ssw0rd!` | VM admin password |
| `zones` | `["1", "2"]` | Availability zones |
| `tags` | `{Environment: dev, Project: Azure-Terraform-DryRun}` | Resource tags |

### Terraform Outputs

The configuration will output:

```hcl
output "public_ip"           # VM public IP address
output "vm_id"               # Virtual Machine resource ID
output "resource_group_name" # Resource Group name
output "network_interface_id"# Network Interface resource ID
output "location"            # Azure region
output "admin_username"      # VM admin username
output "zones"               # Availability zones
output "tags"                # Applied resource tags
```

---

## 💡 Usage Examples

### Example 1: Run Complete Validation (Recommended)

```bash
bash dry-run.sh
```

This runs all 6 validation steps and provides a comprehensive report.

### Example 2: Format Code Only

```bash
terraform fmt -recursive
```

### Example 3: Validate Configuration

```bash
terraform init -backend=false -input=false
terraform validate
```

### Example 4: Run Linting Only

```bash
tflint --recursive --config .tflint.hcl
```

### Example 5: Run Security Scan Only

```bash
checkov -d . --framework terraform --compact
```

### Example 6: Generate Plan for Specific Environment

```bash
terraform init -backend=false -input=false
terraform plan -var-file=envs/dev/terraform.tfvars -out=plan-dev.tfplan
terraform show -no-color plan-dev.tfplan > plan-dev.txt
```

### Example 7: Review Generated Plan

```bash
# View human-readable plan
cat plan-dev.txt

# Or use the binary plan
terraform show plan-dev.tfplan
```

---

## 🐛 Troubleshooting

### Issue: `bash: ash: command not found`

**Cause:** Bash shell not found on Windows.

**Solution:** 
```bash
# Install Git Bash for Windows from https://git-scm.com/download/win
# Or use WSL (Windows Subsystem for Linux)

# Verify installation
bash --version
```

### Issue: `Error: Failed to initialize Terraform`

**Cause:** Provider plugin download failure or invalid provider configuration.

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init -backend=false -input=false

# Check provider requirements in main.tf
terraform version
```

### Issue: `Error: Reference to undeclared resource`

**Cause:** Output or resource references a non-existent resource.

**Solution:**
```bash
# List all declared resources
grep "^resource " *.tf

# Verify outputs match declared resources
cat output.tf
```

### Issue: `tflint initialization failed`

**Cause:** tflint plugins not installed or misconfigured.

**Solution:**
```bash
# Initialize tflint plugins
tflint --init

# Verify tflint configuration
cat .tflint.hcl

# Try manual lint without custom config
tflint --recursive
```

### Issue: `Checkov scan found security issues`

**Cause:** Configuration has security vulnerabilities (often by design for testing).

**Solution:**
```bash
# Review detailed report
checkov -d . --framework terraform

# Suppress specific checks in .checkov.yml
# See Step 5 documentation above
```

### Issue: `AWS credentials not available`

**Cause:** AWS CLI not authenticated (note: this is an Azure project, but script checks AWS).

**Solution:** This is informational. For Azure, use Azure credentials instead:
```bash
export ARM_SUBSCRIPTION_ID="<your-id>"
export ARM_TENANT_ID="<your-id>"
export ARM_CLIENT_ID="<your-id>"
export ARM_CLIENT_SECRET="<your-secret>"
```

### Issue: `terraform plan` fails with authentication error

**Cause:** Azure credentials not provided or invalid.

**Solution:**
```bash
# Create environment file with credentials
cat > envs/dev/terraform.tfvars <<EOF
subscription_id = "..."
tenant_id       = "..."
client_id       = "..."
client_secret   = "..."
EOF

# Or use environment variables
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."

# Then run plan
terraform plan -var-file=envs/dev/terraform.tfvars
```

---

## 📚 Resources

### Official Documentation

- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Terraform Docs**: https://www.terraform.io/docs/
- **Terraform Best Practices**: https://www.terraform.io/docs/cloud/recommended-practices

### Tools Documentation

- **tflint**: https://github.com/terraform-linters/tflint
- **Checkov**: https://www.checkov.io/
- **Azure CLI**: https://docs.microsoft.com/en-us/cli/azure/
- **Terraform Cloud**: https://app.terraform.io/

### Learning Resources

- **Terraform Learn**: https://learn.hashicorp.com/terraform
- **Azure Training**: https://docs.microsoft.com/en-us/learn/azure/
- **Infrastructure as Code**: https://www.terraform.io/docs/intro/

### Related Files

- `.tflint.hcl` - tflint rule configuration
- `.checkov.yml` - Checkov security rules configuration
- `.terraform.lock.hcl` - Provider version lock file (auto-generated)

---

## 📝 File Descriptions

### main.tf

Configures the Azure provider with required authentication:
- Specifies `azurerm` provider version 4.1.0
- Defines provider authentication (subscription, tenant, credentials)
- Sets feature flags

### variables.tf

Declares all input variables:
- Azure authentication credentials
- Resource naming conventions
- Location and size parameters
- SSH credentials
- Resource tags

### output.tf

Defines outputs after infrastructure creation:
- Public IP address for SSH access
- Virtual Machine ID
- Resource Group information
- Network configuration details

### rg.tf

Creates the Azure Resource Group:
- Container for all infrastructure resources
- Specifies region and tags

### vnet.tf

Creates the Virtual Network (VNet):
- Address space: 10.0.0.0/16
- DNS servers: 10.0.0.4, 10.0.0.5
- Applied tags for identification

### vnet-sub1.tf & vnet-sub2.tf

Create two subnets within the VNet:
- Subnet 1: 10.0.1.0/24
- Subnet 2: 10.0.2.0/24

### vnet-interface.tf

Creates network connectivity:
- **Network Interface (NIC)**: Connects VM to subnet
- **Public IP**: Enables external SSH access

### nsg.tf

Creates Network Security Group (NSG):
- Inbound rule: Allows SSH (port 22) from any source
- Applied to control VM access

### vm.tf

Creates the Azure Virtual Machine:
- Image: Ubuntu 18.04 LTS
- Size: Standard_DS1_v2
- OS disk: Standard HDD
- Admin credentials from variables
- Availability zones for redundancy

---

## 🔐 Security Best Practices

1. **Never commit credentials** to version control
2. **Use environment variables** for sensitive data
3. **Enable Azure Key Vault** for secret management
4. **Restrict NSG rules** to specific CIDR blocks instead of 0.0.0.0/0
5. **Use managed identities** instead of service principals when possible
6. **Enable resource encryption** for sensitive data
7. **Implement network policies** to restrict traffic
8. **Regular security audits** using Checkov or similar tools

---

## 📞 Support

For issues or questions:

1. Review the **Troubleshooting** section above
2. Check **Official Documentation** links
3. Run validation steps individually to isolate issues
4. Review **Terraform logs** for detailed error messages:
   ```bash
   TF_LOG=DEBUG terraform validate
   ```

---

## 📄 License

This project is provided as-is for infrastructure testing and validation purposes.

---

**Last Updated:** October 22, 2025
**Terraform Version:** 1.13.4+
**Azure Provider Version:** 4.1.0+
