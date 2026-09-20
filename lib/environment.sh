#!/bin/bash
set -Eeuo pipefail
ENVIRONMENT_CONFIG="${PROJECT_ROOT}/config/environments.json"
validate_environment_config(){
  [[ -f "$ENVIRONMENT_CONFIG" ]] || { log_error "Environment configuration not found: $ENVIRONMENT_CONFIG"; return 1; }
  jq empty "$ENVIRONMENT_CONFIG" >/dev/null 2>&1 || { log_error "Invalid JSON: $ENVIRONMENT_CONFIG"; return 1; }
}
display_environments(){
  cat <<'EOF'

=========================================
       Select Target Environment
=========================================

1) DEV
2) TEST
3) QA
4) DEV-POC
5) DEV-HOTFIX
6) CUSTOM
7) Exit

EOF
}
select_environment(){
  while true; do
    display_environments
    read -r -p "Enter your choice [1-7]: " s
    case "$s" in
      1) ENVIRONMENT="DEV"; break;;
      2) ENVIRONMENT="TEST"; break;;
      3) ENVIRONMENT="QA"; break;;
      4) ENVIRONMENT="DEV-POC"; break;;
      5) ENVIRONMENT="DEV-HOTFIX"; break;;
      6) ENVIRONMENT="CUSTOM"; break;;
      7) log_info "Operation cancelled."; exit 0;;
      *) log_error "Invalid selection. Please choose 1-7.";;
    esac
  done
  export ENVIRONMENT
  log_success "Environment selected: $ENVIRONMENT"
}
get_user_source_branch(){
  local branch
  echo
  echo "Source branch is required for environment: $ENVIRONMENT"
  read -r -p "Enter source branch: " branch
  [[ -n "$branch" ]] || { log_error "Source branch cannot be empty."; return 1; }
  git_validate_branch_name "$branch" || { log_error "Invalid Git branch name: $branch"; return 1; }
  printf '%s' "$branch"
}
