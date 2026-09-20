#!/bin/bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/repository.sh"
validate_repository_config
[[ "$(get_repository_count)" -eq 4 ]]
[[ "$(get_repository_name 0)" == "gciosdd_pps_web" ]]
[[ "$(get_full_repository_name 0)" == "caterpillar-inc/gciosdd_pps_web" ]]
echo "test_repository.sh: PASS"
