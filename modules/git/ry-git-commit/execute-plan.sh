#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"
plan_file="$2"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=modules/git/ry-git-commit/execute-plan-lib.sh
source "$script_dir/execute-plan-lib.sh"

if ry_git_commit_plan_is_empty "$plan_file"; then
  ry_git_commit_emit_error "empty_execution_plan" "validate"
  exit 1
fi

if ! duplicate_details="$(ry_git_commit_validate_no_duplicate_files_in_bucket "$plan_file")"; then
  ry_git_commit_emit_error "duplicate_file_in_bucket" "validate"
  if [[ -n "$duplicate_details" ]]; then
    printf '%s\n' "$duplicate_details" >&2
  fi
  exit 1
fi

ry_git_commit_emit_error "execution_not_yet_enabled" "snapshot"
echo "repo_path=$repo_path" >&2
exit 1
