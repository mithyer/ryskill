#!/usr/bin/env bash
set -euo pipefail

input="${1:-}"
normalized="${input//,/ }"
results=()

for token in $normalized; do
  if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
    start="${token%-*}"
    end="${token#*-}"
    for ((i=start; i<=end; i++)); do
      results+=("$i")
    done
  elif [[ "$token" =~ ^[0-9]+$ && ${#token} -gt 1 ]]; then
    for ((i=0; i<${#token}; i++)); do
      results+=("${token:$i:1}")
    done
  elif [[ "$token" =~ ^[0-9]+$ ]]; then
    results+=("$token")
  else
    echo "invalid_selection=$token" >&2
    exit 1
  fi
done

printf '%s\n' "${results[@]}" | awk '!seen[$0]++' | sort -n | paste -sd' ' -
