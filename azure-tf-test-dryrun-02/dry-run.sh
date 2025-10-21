set -euo pipefail

# Ensure Unix line endings (avoid CRLF issues on WSL/Windows)
if file "$0" | grep -q CRLF; then
  echo "[WARN] Windows line endings detected. Run: dos2unix $0"
  exit 1
fi

# Always run from repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Terraform Dry-Run (Local Only) ==="
echo "Shell: ${SHELL:-/bin/bash}"
echo "PWD  : $(pwd)"

have() { command -v "$1" >/dev/null 2>&1; }

if ! have terraform; then
  echo "[ERROR] Terraform not found in PATH" >&2
  exit 127
fi

# Optional: check Azure CLI authentication (validate token, not just presence)
AZ_AUTH_READY=0
if have az; then
  # Try to fetch an access token for ARM; if this fails, auth is not ready
  if ! az account get-access-token --resource https://management.azure.com/ >/dev/null 2>&1; then
    echo "[INFO] Azure CLI not logged in or token expired."
    echo "      Run one of the following before re-running:"
    echo "        - az login --scope https://graph.microsoft.com/.default"
    echo "        - or export ARM_CLIENT_ID/ARM_CLIENT_SECRET/ARM_TENANT_ID/ARM_SUBSCRIPTION_ID"
    AZ_AUTH_READY=1
  fi
else
  for v in ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_TENANT_ID ARM_SUBSCRIPTION_ID; do
    if [ -z "${!v:-}" ]; then
      AZ_AUTH_READY=1
      break
    fi
  done
fi

# ---------------------------------------------------------------------
# STEP 1: Formatting
# ---------------------------------------------------------------------
echo -e "\n[1/6] Formatting Terraform code..."
set +e
terraform fmt -recursive
FMT_EC=$?
set -e
[ $FMT_EC -ne 0 ] && echo "[WARN] terraform fmt reported issues."

# ---------------------------------------------------------------------
# STEP 2: Validate root (no backend)
# ---------------------------------------------------------------------
echo -e "\n[2/6] Validate root configuration..."
terraform init -backend=false -input=false >/dev/null
terraform validate

# ---------------------------------------------------------------------
# STEP 3: Validate modules
# ---------------------------------------------------------------------
echo -e "\n[3/6] Validate Terraform modules..."
if [ -d modules ]; then
  for d in modules/*; do
    [ -d "$d" ] || continue
    echo "- Validating module: $d"
    (cd "$d" && terraform init -backend=false -input=false >/dev/null && terraform validate)
  done
else
  echo "[INFO] No modules directory found; skipping module validation."
fi

# ---------------------------------------------------------------------
# STEP 4: Lint with tflint
# ---------------------------------------------------------------------
echo -e "\n[4/6] Lint Terraform configuration..."
if have tflint; then
  tflint --recursive || echo "[WARN] tflint found issues (see above)."
else
  echo "[SKIP] tflint not installed."
fi

# ---------------------------------------------------------------------
# STEP 5: Security scan with Checkov
# ---------------------------------------------------------------------
echo -e "\n[5/6] Run Checkov security scan..."
if have checkov; then
  # honor local config if present; otherwise default to terraform framework
  if [ -f .checkov.yml ] || [ -f .checkov.yaml ]; then
    checkov -d . || echo "[WARN] checkov found issues (see above)."
  else
    checkov -d . --framework terraform || echo "[WARN] checkov found issues (see above)."
  fi
else
  echo "[SKIP] checkov not installed."
fi

# ---------------------------------------------------------------------
# STEP 6: Create local Terraform plans
# ---------------------------------------------------------------------
echo -e "\n[6/6] Creating local plans..."
if [ $AZ_AUTH_READY -ne 0 ]; then
  echo "[SKIP] Azure credentials not available."
  echo "       Authenticate with 'az login' or set ARM_* vars, then re-run."
  echo "       Steps 1-5 completed successfully."
  echo "=== Dry-run complete (plans skipped) ==="
  exit 0
fi

for env in dev staging prod; do
  TFVARS="environments/${env}/terraform.tfvars"
  if [ ! -f "$TFVARS" ]; then
    echo "[SKIP] $env: missing $TFVARS"
    continue
  fi
  echo "- Planning for $env..."
  terraform init -backend=false -input=false >/dev/null
  terraform plan -var-file="$TFVARS" -lock=false -input=false -out="plan-${env}.tfplan"
  terraform show -no-color "plan-${env}.tfplan" > "plan-${env}.txt"
  echo "  -> plan-${env}.tfplan (binary)"
  echo "  -> plan-${env}.txt (human-readable)"
done

echo -e "\n=== Local Dry-run Validation Complete ==="
