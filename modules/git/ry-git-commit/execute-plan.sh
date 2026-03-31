#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"
plan_file="$2"

if [[ "${RY_GIT_COMMIT_ALLOW_EXECUTE:-0}" == "1" ]]; then
  echo "error=execute_plan_not_implemented" >&2
  echo "mode=execute_requested_but_unimplemented" >&2
  echo "hint=real execution semantics are not implemented yet; refusing to preview as success" >&2
  exit 1
fi

echo "error=execute_plan_not_implemented" >&2
echo "mode=dry_run_only" >&2
echo "hint=set RY_GIT_COMMIT_ALLOW_EXECUTE=1 only after implementing real execution semantics" >&2
exit 1
