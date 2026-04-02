#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_root="$(cd "$script_dir/.." && pwd)"

if [[ ! -f "$plugin_root/plugin.json" ]]; then
  echo "error=plugin_manifest_not_found" >&2
  echo "plugin_root_candidate=$plugin_root" >&2
  exit 1
fi

if [[ ! -d "$plugin_root/runtime" ]]; then
  echo "error=runtime_directory_not_found" >&2
  echo "plugin_root_candidate=$plugin_root" >&2
  exit 1
fi

if [[ ! -d "$plugin_root/modules" ]]; then
  echo "error=modules_directory_not_found" >&2
  echo "plugin_root_candidate=$plugin_root" >&2
  exit 1
fi

if [[ ! -d "$plugin_root/commands" ]]; then
  echo "error=commands_directory_not_found" >&2
  echo "plugin_root_candidate=$plugin_root" >&2
  exit 1
fi

printf 'plugin_root=%s\n' "$plugin_root"
