#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"
plan_file="$2"

while IFS='|' read -r bucket index message files; do
  [[ -z "$bucket" ]] && continue
  echo "executing bucket=$bucket index=$index message=$message files=$files"
done < "$plan_file"
