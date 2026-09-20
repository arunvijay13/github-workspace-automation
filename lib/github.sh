#!/bin/bash
set -Eeuo pipefail
github_check_auth(){
  local host="${1:-github.com}"
  if ! gh auth status --hostname "$host" >/dev/null 2>&1; then
    log_error "GitHub authentication failed. Run: gh auth login"
    return 1
  fi
  log_success "GitHub authentication verified."
}
github_repository_exists(){
  local repo="$1"
  gh repo view "$repo" --json name --jq '.name' >/dev/null 2>&1
}
github_clone_repository(){
  local repo="$1" dest="$2"
  log_info "Cloning: $repo"
  if gh repo clone "$repo" "$dest"; then
    log_success "Cloned: $repo"
    return 0
  fi
  log_error "Failed to clone: $repo"
  return 1
}
