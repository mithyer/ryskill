#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"

if git -C "$repo_path" rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
  echo "unsafe_state=merge_in_progress"
  exit 1
fi

if [[ -d "$repo_path/.git/rebase-merge" || -d "$repo_path/.git/rebase-apply" ]]; then
  echo "unsafe_state=rebase_in_progress"
  exit 1
fi

if [[ -f "$repo_path/.git/CHERRY_PICK_HEAD" ]]; then
  echo "unsafe_state=cherry_pick_in_progress"
  exit 1
fi

if git -C "$repo_path" diff --name-only --diff-filter=U | grep -q .; then
  echo "unsafe_state=unresolved_conflicts"
  exit 1
fi

echo "unsafe_state=clean_for_analysis"
