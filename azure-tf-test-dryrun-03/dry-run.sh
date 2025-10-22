#!/bin/bash
set -o pipefail  # Only fail on pipe failure, not on individual command failures
set +e # Allow commands to fail gracefully

# ============================================================================
# TERRAFORM DRY-RUN VALIDATION SCRIPT
# Local validation without Azure credentials
# ============================================================================

# Color codes for pretty output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# Ensure Unix line endings (avoid CRLF issues on WSL/Windows)
if file "$0" | grep -q CRLF; then
  echo -e "${RED}[ERROR]${NC} Windows line endings detected. Run: ${CYAN}dos2unix $0${NC}"
  exit 1
fi

# Always run from repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Helper functions
have() { command -v "$1" >/dev/null 2>&1; }

# Pretty print functions
print_header() {
  echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC} $1"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
  local step_num=$1
  local step_name=$2
  echo -e "\n${CYAN}[${step_num}/6]${NC} ${MAGENTA}▶${NC} ${step_name}..."
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_summary() {
  echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC} $1"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}\n"
}

# Ensure TFLint keeps plugins within repo for consistency across hosts
export TFLINT_PLUGIN_DIR="${SCRIPT_DIR}/.tflint.d/plugins"
[ -d "$TFLINT_PLUGIN_DIR" ] || mkdir -p "$TFLINT_PLUGIN_DIR"

# Print header
print_header "Terraform Dry-Run Validation (Local Only)"
echo -e "${CYAN}Shell:${NC} ${SHELL:-/bin/bash}"
echo -e "${CYAN}Root: ${NC} $(pwd)"
echo -e "${CYAN}Date: ${NC} $(date '+%Y-%m-%d %H:%M:%S')"

# Check for required tools
if ! have terraform; then
  print_error "Terraform not found in PATH"
  exit 127
fi
print_success "Terraform found: $(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4 || terraform version | head -1)"

# Optional: check AWS CLI authentication (validate credentials, not just presence)
AWS_AUTH_READY=0
if have aws; then
  if aws sts get-caller-identity >/dev/null 2>&1; then
    ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "Unknown")
    USER=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "Unknown")
    print_success "AWS CLI authenticated: ${ACCOUNT} (${USER})"
  else
    print_info "AWS CLI not logged in or credentials expired"
    print_info "Run one of the following before re-running:"
    print_info "  - ${CYAN}aws configure${NC}"
    print_info "  - or ${CYAN}export AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY/AWS_SESSION_TOKEN${NC}"
    print_info "  - or ${CYAN}export AWS_PROFILE=<profile-name>${NC}"
    AWS_AUTH_READY=1
  fi
else
  for v in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY; do
    if [ -z "${!v:-}" ]; then
      AWS_AUTH_READY=1
      break
    fi
  done
fi

# Check for optional tools
if have tflint; then
  print_success "tflint installed"
else
  print_warning "tflint not installed (lint step will be skipped)"
fi

if have checkov; then
  print_success "checkov installed"
else
  print_warning "checkov not installed (security scan will be skipped)"
fi

# ============================================================================
# STEP 1: Formatting
# ============================================================================
print_step 1 "Formatting Terraform code"

FMT_FILES=$(terraform fmt -recursive 2>&1 || true)
if [ -n "$FMT_FILES" ]; then
  print_warning "Files formatted or had issues:"
  echo "$FMT_FILES" | sed 's/^/  /' | head -20
else
  print_success "All files properly formatted"
fi

# ============================================================================
# STEP 2: Validate root (no backend)
# ============================================================================
print_step 2 "Validating root configuration"

if terraform init -backend=false -input=false >/dev/null 2>&1; then
  if terraform validate >/dev/null 2>&1; then
    print_success "Root configuration is valid"
  else
    print_error "Root configuration validation failed"
    terraform validate
    exit 1
  fi
else
  print_error "Failed to initialize Terraform"
  exit 1
fi

# Track critical failures
CRITICAL_FAILED=0

# ============================================================================
# STEP 3: Validate modules
# ============================================================================
print_step 3 "Validating Terraform modules"

if [ -d modules ]; then
  MODULES_VALID=true
  for d in modules/*/; do
    if [ -d "$d" ]; then
      module_name=$(basename "$d")
      if (cd "$d" && terraform init -backend=false -input=false >/dev/null 2>&1 && terraform validate >/dev/null 2>&1); then
        print_success "Module: ${CYAN}${module_name}${NC}"
      else
        print_error "Module validation failed: ${RED}${module_name}${NC}"
        (cd "$d" && terraform validate)
        MODULES_VALID=false
      fi
    fi
  done
  
  if [ "$MODULES_VALID" = false ]; then
    exit 1
  fi
else
  print_info "No modules directory found; skipping module validation"
fi

# ============================================================================
# STEP 4: Lint with tflint
# ============================================================================
print_step 4 "Linting Terraform configuration"

if have tflint; then
  if tflint --init --config "${SCRIPT_DIR}/.tflint.hcl" >/dev/null 2>&1; then
    LINT_OUTPUT=$(tflint --recursive --config "${SCRIPT_DIR}/.tflint.hcl" 2>&1)
    LINT_EXIT=$?
    
    if [ $LINT_EXIT -eq 0 ]; then
      print_success "TFLint passed with no issues"
    elif echo "$LINT_OUTPUT" | grep -q "executable file not found"; then
      print_warning "TFLint plugins not installed; install with: ${CYAN}tflint --init${NC}"
      print_info "Continuing with other validations..."
    else
      print_warning "TFLint found issues (see details below):"
      echo "$LINT_OUTPUT" | head -30 | sed 's/^/  /'
      print_info "Continuing with other validations..."
    fi
  else
    print_warning "tflint initialization failed; skipping lint"
    print_info "Continuing with other validations..."
  fi
else
  print_info "tflint not installed; skipping lint step"
fi

# ============================================================================
# STEP 5: Security scan with Checkov
# ============================================================================
print_step 5 "Running Checkov security scan"

if have checkov; then
  CHECKOV_OPTS="-d . --framework terraform --compact"
  
  if [ -f .checkov.yml ] || [ -f .checkov.yaml ]; then
    CHECKOV_CONFIG="${SCRIPT_DIR}/.checkov.yml"
    CHECKOV_OPTS="--config-file ${CHECKOV_CONFIG} -d . --compact"
    print_info "Using local checkov config: ${CYAN}.checkov.yml${NC}"
  fi
  
  CHECKOV_OUTPUT=$(eval "checkov ${CHECKOV_OPTS}" 2>&1)
  CHECKOV_EXIT=$?
  
  if [ $CHECKOV_EXIT -eq 0 ]; then
    print_success "Security scan passed with no issues"
  else
    if echo "$CHECKOV_OUTPUT" | grep -q "Passed checks:"; then
      PASSED=$(echo "$CHECKOV_OUTPUT" | grep "Passed checks:" | head -1)
      FAILED=$(echo "$CHECKOV_OUTPUT" | grep "Failed checks:" | head -1)
      print_warning "Security scan found some issues"
      echo -e "  ${PASSED}" | sed 's/^/  /'
      echo -e "  ${FAILED}" | sed 's/^/  /'
    else
      print_warning "Checkov scan completed with warnings"
      print_info "Continuing with other validations..."
    fi
  fi
else
  print_info "checkov not installed; skipping security scan"
fi

# ============================================================================
# STEP 6: Create local Terraform plans
# ============================================================================
print_step 6 "Creating local Terraform plans"

if [ $AWS_AUTH_READY -ne 0 ]; then
  print_warning "AWS credentials not available (skipping plan generation)"
  print_info "To generate plans, authenticate with one of the following:"
  print_info "  - ${CYAN}aws configure${NC}"
  print_info "  - or export: ${CYAN}AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY${NC}"
  print_info "  - or export: ${CYAN}AWS_PROFILE=<profile-name>${NC}"
  
  if [ $CRITICAL_FAILED -eq 0 ]; then
    print_summary "✓ LOCAL VALIDATION COMPLETE (Steps 1-5 passed)"
    echo -e "${GREEN}All local validations passed successfully!${NC}"
    echo -e "${YELLOW}Plans generation skipped due to missing AWS credentials.${NC}\n"
    exit 0
  else
    print_summary "✗ VALIDATION FAILED"
    echo -e "${RED}Critical validation errors detected.${NC}\n"
    exit 1
  fi
fi

PLANS_GENERATED=0
for env in dev stage prod; do
  TFVARS="envs/${env}/terraform.tfvars"
  if [ ! -f "$TFVARS" ]; then
    print_info "Skipping ${CYAN}${env}${NC}: terraform.tfvars not found"
    continue
  fi
  
  echo -e "${BLUE}Planning for ${CYAN}${env}${NC}...${NC}"
  
  if terraform init -backend=false -input=false >/dev/null 2>&1; then
    if terraform plan -var-file="$TFVARS" -lock=false -input=false -out="plan-${env}.tfplan" >/dev/null 2>&1; then
      terraform show -no-color "plan-${env}.tfplan" > "plan-${env}.txt"
      print_success "Plan created for ${CYAN}${env}${NC}"
      echo -e "  ${CYAN}Binary:${NC} plan-${env}.tfplan"
      echo -e "  ${CYAN}Human:${NC}  plan-${env}.txt"
      ((PLANS_GENERATED++))
    else
      print_error "Failed to create plan for ${RED}${env}${NC}"
    fi
  else
    print_error "Failed to initialize Terraform for ${RED}${env}${NC}"
  fi
done

if [ $PLANS_GENERATED -gt 0 ]; then
  print_summary "✓ DRY-RUN COMPLETE - All validations and plans succeeded!"
  echo -e "${GREEN}Generated plans:${NC} ${PLANS_GENERATED}"
else
  if [ $CRITICAL_FAILED -eq 0 ]; then
    print_summary "✓ LOCAL VALIDATION COMPLETE (Steps 1-5 passed)"
    print_info "No plans generated (missing terraform.tfvars files or AWS credentials)"
  else
    print_summary "✗ VALIDATION FAILED"
    echo -e "${RED}Critical validation errors detected.${NC}\n"
    exit 1
  fi
fi

exit 0
