#!/usr/bin/env bash
set -euo pipefail

selected=" ${1:-} "
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  IFS='|' read -r bucket index message files <<<"$line"
  if [[ "$selected" == *" $index "* ]]; then
    echo "$bucket|$index|$message|$files"
  fi
done
