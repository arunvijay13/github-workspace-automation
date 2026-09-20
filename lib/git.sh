#!/bin/bash
set -Eeuo pipefail
git_validate_branch_name(){ git check-ref-format --branch "$1" >/dev/null 2>&1; }
git_is_clean(){ [[ -z "$(git -C "$1" status --porcelain)" ]]; }
git_branch_exists_local(){
  git -C "$1" show-ref --verify --quiet "refs/heads/$2"
}
git_branch_exists_remote(){
  git -C "$1" show-ref --verify --quiet "refs/remotes/origin/$2"
}
git_source_branch_exists(){
  git -C "$1" ls-remote --exit-code --heads origin "$2" >/dev/null 2>&1
}
git_create_feature_branch(){
  local repo="$1" source="$2" feature="$3"
  git_is_clean "$repo" || { log_error "Working tree is not clean: $repo"; return 1; }
  git -C "$repo" switch --create "$feature" "origin/$source"
}
git_switch_feature_branch(){
  git_is_clean "$1" || { log_error "Working tree is not clean: $1"; return 1; }
  git -C "$1" switch "$2"
}
git_merge_source_into_feature(){
  local repo="$1" source="$2"
  git_is_clean "$repo" || { log_error "Working tree is not clean: $repo"; return 1; }
  git -C "$repo" merge --no-edit "origin/$source"
}
