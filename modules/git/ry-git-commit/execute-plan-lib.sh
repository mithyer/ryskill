#!/usr/bin/env bash
set -euo pipefail

ry_git_commit_emit_error() {
  local error_code="$1"
  local failed_phase="$2"

  echo "error=${error_code}" >&2
  echo "failed_phase=${failed_phase}" >&2
}

ry_git_commit_plan_is_empty() {
  local plan_file="$1"
  [[ ! -s "$plan_file" ]]
}

ry_git_commit_validate_no_duplicate_files_in_bucket() {
  local plan_file="$1"

  python3 - "$plan_file" <<'PY'
import sys
from collections import defaultdict

plan_file = sys.argv[1]
seen = defaultdict(dict)

with open(plan_file, "r", encoding="utf-8") as handle:
    for raw_line in handle:
        line = raw_line.strip()
        if not line:
            continue

        parts = line.split("|", 3)
        if len(parts) != 4:
            continue

        bucket, candidate, _message, files_column = parts
        file_paths = [path.strip() for path in files_column.split(",") if path.strip()]
        for file_path in file_paths:
            existing = seen[bucket].get(file_path)
            if existing is not None and existing != candidate:
                print(f"bucket={bucket}")
                print(f"file={file_path}")
                print(f"first_candidate={existing}")
                print(f"second_candidate={candidate}")
                sys.exit(1)

            seen[bucket][file_path] = candidate
PY
}
