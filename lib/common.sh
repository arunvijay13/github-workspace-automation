#!/bin/bash
set -Eeuo pipefail
log_info(){ printf '[INFO] %s\n' "$1"; }
log_success(){ printf '[OK]   %s\n' "$1"; }
log_warn(){ printf '[WARN] %s\n' "$1" >&2; }
log_error(){ printf '[ERROR] %s\n' "$1" >&2; }
die(){ log_error "$1"; exit "${2:-1}"; }
command_exists(){ command -v "$1" >/dev/null 2>&1; }
require_command(){
  local c="$1" msg="${2:-}"
  if ! command_exists "$c"; then
    log_error "Required command not found: $c"
    [[ -n "$msg" ]] && log_error "$msg"
    exit 1
  fi
}
