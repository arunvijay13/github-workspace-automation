#!/bin/bash
set -Eeuo pipefail

github_check_auth() {
    local github_host="${1:-github.com}"

    if ! gh auth status --hostname "$github_host" >/dev/null 2>&1; then
        log_error "GitHub authentication failed."
        echo
        echo "Please authenticate using:"
        echo "    gh auth login"
        echo
        return 1
    fi

    log_success "GitHub authentication verified."
}

github_repository_exists() {
    local repository="$1"

    gh repo view "$repository" \
        --json name \
        --jq '.name' \
        >/dev/null 2>&1
}

github_clone_repository() {
    local repository="$1"
    local destination="$2"

    log_info "Cloning repository: $repository"

    if gh repo clone "$repository" "$destination"; then
        log_success "Repository cloned."
        return 0
    fi

    log_error "Failed to clone repository: $repository"
    return 1
}