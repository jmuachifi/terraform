#!/usr/bin/env bash
# validate-workflows.sh — Lint & validate .github/workflows locally
# Works on Linux/macOS. Pretty output, Docker fallbacks, optional act dry-run.
# Usage:
#   scripts/validate-workflows.sh [--no-act] [--no-shellcheck] [--path <repo-root>]
#   scripts/validate-workflows.sh --file .github/workflows/build.yml
set -Eeuo pipefail

### -------------------- Pretty printing --------------------
if [[ -t 1 ]]; then
    RED="$(tput setaf 1)"; GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"; BOLD="$(tput bold)"; RESET="$(tput sgr0)"
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi
ok()   { echo -e "${GREEN}✔${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }
err()  { echo -e "${RED}✖${RESET} $*" >&2; }
info() { echo -e "${BLUE}ℹ${RESET}  $*"; }

### -------------------- Defaults & args --------------------
REPO_ROOT="${PWD}"
RUN_ACT="true"
USE_SHELLCHECK="true"
SPECIFIC_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-act) RUN_ACT="false"; shift ;;
        --no-shellcheck) USE_SHELLCHECK="false"; shift ;;
        --path) REPO_ROOT="$2"; shift 2 ;;
        --file) SPECIFIC_FILE="$2"; shift 2 ;;
        -h|--help)
      cat <<EOF
${BOLD}validate-workflows.sh${RESET}
Validate all GitHub workflow YAMLs.

Options:
  --file <path>        Validate a single workflow file
  --path <repo-root>   Repo root path (default: current dir)
  --no-act             Skip 'act' dry-run
  --no-shellcheck      Skip shellcheck for 'run:' steps
EOF
            exit 0
        ;;
        *) err "Unknown arg: $1"; exit 2 ;;
    esac
done

### -------------------- Find workflows --------------------
WORKFLOWS_DIR="${REPO_ROOT}/.github/workflows"
if [[ -n "${SPECIFIC_FILE}" ]]; then
    mapfile -t WF_FILES < <(printf "%s\n" "${SPECIFIC_FILE}")
else
    if [[ ! -d "${WORKFLOWS_DIR}" ]]; then
        warn "No .github/workflows directory at ${WORKFLOWS_DIR}"
        exit 0
    fi
    mapfile -t WF_FILES < <(find "${WORKFLOWS_DIR}" -type f \( -name "*.yml" -o -name "*.yaml" \) | sort)
fi
if [[ "${#WF_FILES[@]}" -eq 0 ]]; then
    warn "No workflow files found."
    exit 0
fi

### -------------------- Tool resolvers --------------------
have() { command -v "$1" >/dev/null 2>&1; }
run_in_docker() {
    local image="$1"; shift
    docker run --rm -v "${REPO_ROOT}:/repo" -w /repo "${image}" "$@"
}

NEED_DOCKER_FALLBACK=false
if ! have actionlint || ! have yamllint || { [[ "${USE_SHELLCHECK}" == "true" ]] && ! have shellcheck; }; then
    if have docker; then
        NEED_DOCKER_FALLBACK=true
        info "Some tools missing; will use Docker fallbacks where needed."
    else
        warn "Docker not available; attempting to proceed with locally installed tools only."
    fi
fi

### -------------------- yamllint setup --------------------
# Put the temp config *inside the repo* so Docker can read it.
YAMLLINT_CFG="$(mktemp -p "${REPO_ROOT}" .yamllint.tmp.XXXXXX.yaml)"
cat > "${YAMLLINT_CFG}" <<'YAML'
extends: default
rules:
  document-start: disable
  line-length: {max: 160}
  truthy: enable
  indentation: {spaces: 2, indent-sequences: true}
  trailing-spaces: enable
  comments: {min-spaces-from-content: 1}
YAML
cleanup() { rm -f "${YAMLLINT_CFG}"; }
trap cleanup EXIT

### -------------------- Validators --------------------
pass_count=0
fail_count=0
yamllint_run() {
    info "YAML lint…"
    if have yamllint; then
        yamllint -c "${YAMLLINT_CFG}" -- "${WF_FILES[@]}" \
        && ok "yamllint passed" || { err "yamllint failed"; return 1; }
    elif [[ "${NEED_DOCKER_FALLBACK}" == "true" ]]; then
        # Mount repo at /repo in the container and pass relative paths.
        local rel_cfg rel_files=()
        rel_cfg="$(realpath --relative-to="${REPO_ROOT}" "${YAMLLINT_CFG}")"
        for wf in "${WF_FILES[@]}"; do
            rel_files+=("/repo/$(realpath --relative-to="${REPO_ROOT}" "${wf}")")
        done
        run_in_docker "yamllint/yamllint:latest" \
            yamllint -c "/repo/${rel_cfg}" -- "${rel_files[@]}" \
        && ok "yamllint (docker) passed" || { err "yamllint (docker) failed"; return 1; }
    else
        warn "yamllint not found. Skipping YAML lint."
    fi
}

actionlint_run() {
    info "GitHub Actions lint (actionlint)…"
    local shellcheck_opt=()
    if [[ "${USE_SHELLCHECK}" == "true" ]]; then
        if have shellcheck; then
            shellcheck_opt+=( "-shellcheck=$(command -v shellcheck)" )
        elif [[ "${NEED_DOCKER_FALLBACK}" == "true" ]] && have docker; then
            # We'll run actionlint in Docker which already bundles shellcheck; no need to pass -shellcheck.
            :
        else
            warn "shellcheck not found. 'run:' script checks will be limited."
        fi
    fi
    
    if have actionlint; then
        actionlint -color -format '{{severity}}:{{file}}:{{line}}:{{col}}:{{message}} ({{code}})' "${shellcheck_opt[@]}" \
        && ok "actionlint passed" || { err "actionlint found issues"; return 1; }
    elif [[ "${NEED_DOCKER_FALLBACK}" == "true" ]]; then
        # ghcr.io/rhysd/actionlint bundles actionlint (+shellcheck internally)
        run_in_docker "ghcr.io/rhysd/actionlint:latest" actionlint -color -format '{{severity}}:{{file}}:{{line}}:{{col}}:{{message}} ({{code}})' \
        && ok "actionlint (docker) passed" || { err "actionlint (docker) found issues"; return 1; }
    else
        warn "actionlint not found. Skipping Actions-specific validation (not recommended)."
    fi
}

act_dry_run() {
    [[ "${RUN_ACT}" == "true" ]] || { info "Skipping act dry-run (--no-act)"; return 0; }
    if ! have act; then
        warn "'act' is not installed. Skipping dry-run. Install from https://github.com/nektos/act"
        return 0
    fi
    info "act dry-run (syntax & job graph)…"
    # Try to list workflow jobs/events (fast, low-noise). Using a default runner image mapping for ubuntu-latest if needed.
    if ! act --list >/dev/null 2>&1; then
        warn "act --list failed (possibly missing runner images or secrets). Attempting a no-op dry-run for 'push'…"
    fi
    # Dry-run won't execute actions, but will parse the workflow & graph.
    if act -n -P ubuntu-latest=catthehacker/ubuntu:act-latest >/dev/null 2>&1; then
        ok "act dry-run basic parse succeeded"
    else
        warn "act dry-run reported issues (could be missing secrets/services). Inspect 'act' output manually if needed."
    fi
}

### -------------------- Run checks --------------------
echo -e "${BOLD}Validating GitHub Workflows (${#WF_FILES[@]} file(s))${RESET}"
for f in "${WF_FILES[@]}"; do
    echo " • ${f}"
done
echo

if yamllint_run; then ((pass_count++)); else ((fail_count++)); fi
if actionlint_run; then ((pass_count++)); else ((fail_count++)); fi
if act_dry_run; then ((pass_count++)); else ((fail_count++)); fi

echo
if (( fail_count == 0 )); then
    ok "${BOLD}All checks passed.${RESET} (${pass_count} stages)"
    exit 0
else
    err "${BOLD}${fail_count} stage(s) failed.${RESET} See logs above."
    exit 1
fi
