#!/usr/bin/env bash
# Bash-only entrypoint. Invoke with bash or execute directly; do not run with sh.
set -euo pipefail

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf '%s\n' 'error=unsupported_shell' >&2
  printf '%s\n' 'failed_phase=bootstrap' >&2
  exit 1
fi

repo_path="$1"
plan_file="$2"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=modules/git/ry-git-commit/execute-plan-lib.sh
source "$script_dir/execute-plan-lib.sh"

if ry_git_commit_plan_is_empty "$plan_file"; then
  ry_git_commit_emit_error "empty_execution_plan" "validate"
  exit 1
fi

if ! validation_output="$(ry_git_commit_validate_no_duplicate_files_in_bucket "$plan_file")"; then
  if [[ -n "$validation_output" ]]; then
    printf '%s\n' "$validation_output" >&2
  else
    ry_git_commit_emit_error "unknown_validation_error" "validate"
  fi
  exit 1
fi

ry_git_commit_emit_error "execution_not_yet_enabled" "snapshot"
ry_git_commit_emit_kv "repo_path" "$repo_path"
exit 1
