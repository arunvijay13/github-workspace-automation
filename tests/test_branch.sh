#!/bin/bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/git.sh"
git_validate_branch_name "feature/CPPS-1234-test"
! git_validate_branch_name "feature//bad"
! git_validate_branch_name "feature..bad"
echo "test_branch.sh: PASS"
