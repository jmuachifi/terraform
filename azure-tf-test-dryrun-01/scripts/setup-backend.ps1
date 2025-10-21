# Azure AKS Terraform Setup Script (PowerShell)
# This script helps initialize the Terraform backend and prepare the environment

param(
    [string]$ResourceGroup = "tfstate-rg",
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Azure AKS Infrastructure Setup" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Function to print colored output
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# Check if Azure CLI is installed
try {
    $null = az version
    Write-Success "Azure CLI found"
} catch {
    Write-Error-Custom "Azure CLI is not installed. Please install it first."
    exit 1
}

# Check if logged in to Azure
try {
    $null = az account show 2>$null
} catch {
    Write-Warning-Custom "Not logged in to Azure. Logging in..."
    az login
}

# Get current subscription
$subscriptionId = az account show --query id -o tsv
$subscriptionName = az account show --query name -o tsv

Write-Host ""
Write-Host "Current Azure Subscription:"
Write-Host "  Name: $subscriptionName"
Write-Host "  ID: $subscriptionId"
Write-Host ""

$continue = Read-Host "Is this the correct subscription? (y/n)"
if ($continue -ne 'y' -and $continue -ne 'Y') {
    Write-Warning-Custom "Please set the correct subscription with: az account set --subscription <subscription-id>"
    exit 1
}

Write-Host ""
Write-Host "Will create the following resources for Terraform state:"
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  Location: $Location"
Write-Host "  Storage Accounts: tfstatedevaks, tfstatestgaks, tfstateprodaks"
Write-Host ""

$continue = Read-Host "Continue? (y/n)"
if ($continue -ne 'y' -and $continue -ne 'Y') {
    exit 0
}

# Create resource group
Write-Host ""
Write-Host "Creating resource group..."
try {
    $null = az group create --name $ResourceGroup --location $Location 2>&1
    Write-Success "Resource group created: $ResourceGroup"
} catch {
    Write-Warning-Custom "Resource group might already exist or creation failed"
}

# Create storage accounts for each environment
$envs = @("dev", "stg", "prod")

foreach ($env in $envs) {
    $storageAccountName = "tfstate$($env)aks"
    
    Write-Host ""
    Write-Host "Creating storage account: $storageAccountName"
    
    $exists = az storage account show --name $storageAccountName --resource-group $ResourceGroup 2>$null
    
    if ($exists) {
        Write-Warning-Custom "Storage account $storageAccountName already exists"
    } else {
        try {
            $null = az storage account create `
                --name $storageAccountName `
                --resource-group $ResourceGroup `
                --location $Location `
                --sku Standard_LRS `
                --encryption-services blob `
                --https-only true `
                --min-tls-version TLS1_2 `
                --allow-blob-public-access false 2>&1
            Write-Success "Storage account created: $storageAccountName"
        } catch {
            Write-Error-Custom "Failed to create storage account: $storageAccountName"
            continue
        }
    }
    
    # Get storage account key
    $accountKey = az storage account keys list `
        --resource-group $ResourceGroup `
        --account-name $storageAccountName `
        --query '[0].value' -o tsv
    
    # Create container
    Write-Host "Creating container: tfstate"
    try {
        $null = az storage container create `
            --name tfstate `
            --account-name $storageAccountName `
            --account-key $accountKey 2>&1
        Write-Success "Container created: tfstate"
    } catch {
        Write-Warning-Custom "Container might already exist or creation failed"
    }
}

# Grant current user permissions
Write-Host ""
Write-Host "Granting Storage Blob Data Contributor role..."
$userObjectId = az ad signed-in-user show --query id -o tsv

foreach ($env in $envs) {
    $storageAccountName = "tfstate$($env)aks"
    $scope = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
    
    try {
        $null = az role assignment create `
            --role "Storage Blob Data Contributor" `
            --assignee $userObjectId `
            --scope $scope 2>&1
        Write-Success "Role assigned for $storageAccountName"
    } catch {
        Write-Warning-Custom "Role assignment might already exist for $storageAccountName"
    }
}

# Create service principal for Terraform (optional)
Write-Host ""
$createSP = Read-Host "Create service principal for Terraform? (y/n)"
if ($createSP -eq 'y' -or $createSP -eq 'Y') {
    $spName = "terraform-sp"
    Write-Host ""
    Write-Host "Creating service principal: $spName"
    
    $spOutput = az ad sp create-for-rbac `
        --name $spName `
        --role="Contributor" `
        --scopes="/subscriptions/$subscriptionId"
    
    Write-Host ""
    Write-Success "Service Principal created!"
    Write-Host ""
    Write-Host "Save these credentials for Azure DevOps:" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host $spOutput
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

# Check for Terraform
Write-Host ""
try {
    $terraformVersion = terraform version 2>$null
    Write-Success "Terraform found: $($terraformVersion[0])"
} catch {
    Write-Warning-Custom "Terraform not found. Install with: winget install Hashicorp.Terraform"
}

# Check for kubectl
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Success "kubectl found"
} catch {
    Write-Warning-Custom "kubectl not found. Install with: az aks install-cli"
}

# Summary
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Copy terraform.tfvars.example to terraform.tfvars in each environment"
Write-Host "2. Update terraform.tfvars with your values"
Write-Host "3. Run 'cd environments/dev; terraform init'"
Write-Host "4. Run 'terraform plan' to preview changes"
Write-Host "5. Run 'terraform apply' to create infrastructure"
Write-Host ""
Write-Host "For detailed instructions, see docs/SETUP.md"
Write-Host ""
Write-Success "Backend storage is ready for Terraform state!"
Write-Host ""
