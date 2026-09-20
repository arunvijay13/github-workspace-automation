#!/bin/bash
set -Eeuo pipefail
REPOSITORY_CONFIG="${PROJECT_ROOT}/config/repositories.json"
validate_repository_config(){
  [[ -f "$REPOSITORY_CONFIG" ]] || { log_error "Repository configuration not found: $REPOSITORY_CONFIG"; return 1; }
  jq empty "$REPOSITORY_CONFIG" >/dev/null 2>&1 || { log_error "Invalid JSON: $REPOSITORY_CONFIG"; return 1; }
}
get_repository_count(){ jq '.repositories | length' "$REPOSITORY_CONFIG"; }
get_repository_name(){ jq -r ".repositories[$1].name" "$REPOSITORY_CONFIG"; }
get_repository_owner(){ jq -r ".repositories[$1].owner" "$REPOSITORY_CONFIG"; }
get_repository_description(){ jq -r ".repositories[$1].description" "$REPOSITORY_CONFIG"; }
get_full_repository_name(){ printf '%s/%s' "$(get_repository_owner "$1")" "$(get_repository_name "$1")"; }
