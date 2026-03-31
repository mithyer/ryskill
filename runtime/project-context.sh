#!/usr/bin/env bash
set -euo pipefail

cwd=""
project=""
branch=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd) cwd="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --branch) branch="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$cwd" ]]; then
  cwd="$PWD"
fi

if [[ -z "$project" ]]; then
  project="$cwd"
fi

if ! git -C "$project" rev-parse --git-dir >/dev/null 2>&1; then
  echo "project_path=$project" >&2
  echo "error=not_a_git_repository" >&2
  exit 1
fi

if [[ -z "$branch" ]]; then
  branch="$(git -C "$project" rev-parse --abbrev-ref HEAD)"
fi

printf 'project_path=%s\nbranch=%s\n' "$project" "$branch"
