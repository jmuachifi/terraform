#!/bin/bash

# Azure AKS Terraform Setup Script
# This script helps initialize the Terraform backend and prepare the environment

set -e

echo "=================================================="
echo "  Azure AKS Infrastructure Setup"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

print_success "Azure CLI found"

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    print_warning "Not logged in to Azure. Logging in..."
    az login
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo ""
echo "Current Azure Subscription:"
echo "  Name: $SUBSCRIPTION_NAME"
echo "  ID: $SUBSCRIPTION_ID"
echo ""

read -p "Is this the correct subscription? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Please set the correct subscription with: az account set --subscription <subscription-id>"
    exit 1
fi

# Ask for configuration
echo ""
echo "Configuration:"
read -p "Resource Group Name for Terraform State [tfstate-rg]: " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-tfstate-rg}

read -p "Location [eastus]: " LOCATION
LOCATION=${LOCATION:-eastus}

echo ""
echo "Will create the following resources for Terraform state:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Storage Accounts: tfstatedevaks, tfstatestgaks, tfstateprodaks"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Create resource group
echo ""
echo "Creating resource group..."
if az group create --name "$RESOURCE_GROUP" --location "$LOCATION" &> /dev/null; then
    print_success "Resource group created: $RESOURCE_GROUP"
else
    print_warning "Resource group might already exist or creation failed"
fi

# Create storage accounts for each environment
declare -a envs=("dev" "stg" "prod")

for env in "${envs[@]}"
do
    STORAGE_ACCOUNT_NAME="tfstate${env}aks"
    
    echo ""
    echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
    
    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_warning "Storage account $STORAGE_ACCOUNT_NAME already exists"
    else
        if az storage account create \
            --name "$STORAGE_ACCOUNT_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --encryption-services blob \
            --https-only true \
            --min-tls-version TLS1_2 \
            --allow-blob-public-access false &> /dev/null; then
            print_success "Storage account created: $STORAGE_ACCOUNT_NAME"
        else
            print_error "Failed to create storage account: $STORAGE_ACCOUNT_NAME"
            continue
        fi
    fi
    
    # Get storage account key
    ACCOUNT_KEY=$(az storage account keys list \
        --resource-group "$RESOURCE_GROUP" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --query '[0].value' -o tsv)
    
    # Create container
    echo "Creating container: tfstate"
    if az storage container create \
        --name tfstate \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$ACCOUNT_KEY" &> /dev/null; then
        print_success "Container created: tfstate"
    else
        print_warning "Container might already exist or creation failed"
    fi
done

# Grant current user permissions
echo ""
echo "Granting Storage Blob Data Contributor role..."
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

for env in "${envs[@]}"
do
    STORAGE_ACCOUNT_NAME="tfstate${env}aks"
    SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
    
    if az role assignment create \
        --role "Storage Blob Data Contributor" \
        --assignee "$USER_OBJECT_ID" \
        --scope "$SCOPE" &> /dev/null; then
        print_success "Role assigned for $STORAGE_ACCOUNT_NAME"
    else
        print_warning "Role assignment might already exist for $STORAGE_ACCOUNT_NAME"
    fi
done

# Create service principal for Terraform (optional)
echo ""
read -p "Create service principal for Terraform? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SP_NAME="terraform-sp"
    echo ""
    echo "Creating service principal: $SP_NAME"
    
    SP_OUTPUT=$(az ad sp create-for-rbac \
        --name "$SP_NAME" \
        --role="Contributor" \
        --scopes="/subscriptions/$SUBSCRIPTION_ID")
    
    echo ""
    print_success "Service Principal created!"
    echo ""
    echo "Save these credentials for Azure DevOps:"
    echo "============================================"
    echo "$SP_OUTPUT"
    echo "============================================"
    echo ""
fi

# Check for Terraform
echo ""
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version | head -n 1)
    print_success "Terraform found: $TERRAFORM_VERSION"
else
    print_warning "Terraform not found. Install with: winget install Hashicorp.Terraform"
fi

# Check for kubectl
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
    print_success "kubectl found: $KUBECTL_VERSION"
else
    print_warning "kubectl not found. Install with: az aks install-cli"
fi

# Summary
echo ""
echo "=================================================="
echo "  Setup Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Copy terraform.tfvars.example to terraform.tfvars in each environment"
echo "2. Update terraform.tfvars with your values"
echo "3. Run 'cd environments/dev && terraform init'"
echo "4. Run 'terraform plan' to preview changes"
echo "5. Run 'terraform apply' to create infrastructure"
echo ""
echo "For detailed instructions, see docs/SETUP.md"
echo ""
print_success "Backend storage is ready for Terraform state!"
echo ""
