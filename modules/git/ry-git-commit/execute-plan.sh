#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"
plan_file="$2"

if [[ "${RY_GIT_COMMIT_ALLOW_EXECUTE:-0}" != "1" ]]; then
  echo "error=execute_plan_not_implemented" >&2
  echo "mode=dry_run_only" >&2
  echo "hint=set RY_GIT_COMMIT_ALLOW_EXECUTE=1 after implementing real execution semantics" >&2
  exit 1
fi

while IFS='|' read -r bucket index message files; do
  [[ -z "$bucket" ]] && continue
  echo "preview_only bucket=$bucket index=$index message=$message files=$files"
done < "$plan_file"
