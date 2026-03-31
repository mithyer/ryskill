#!/usr/bin/env bash
set -euo pipefail

ry_git_commit_emit_kv() {
  local key="$1"
  local value="$2"

  printf '%s=%s\n' "$key" "$value" >&2
}

ry_git_commit_emit_error() {
  local error_code="$1"
  local failed_phase="$2"

  ry_git_commit_emit_kv "error" "$error_code"
  ry_git_commit_emit_kv "failed_phase" "$failed_phase"
}

ry_git_commit_plan_is_empty() {
  local plan_file="$1"
  [[ ! -s "$plan_file" ]]
}

ry_git_commit_emit_invalid_plan_row() {
  local line_number="$1"
  local line="$2"

  printf 'error=invalid_plan_row\n'
  printf 'failed_phase=validate\n'
  printf 'line_number=%s\n' "$line_number"
  printf 'line=%s\n' "$line"
}

ry_git_commit_trim_whitespace() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

ry_git_commit_validate_no_duplicate_files_in_bucket() {
  local plan_file="$1"
  local seen_entries=""
  local raw_line
  local line
  local line_number=0
  local bucket
  local candidate
  local message
  local files_column
  local normalized_files
  local file_path
  local existing_candidate
  local seen_bucket
  local seen_file
  local seen_candidate
  local extra
  local -a file_paths=()

  while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line_number=$((line_number + 1))
    line="${raw_line%$'\r'}"
    [[ -n "${line//[[:space:]]/}" ]] || continue

    if [[ "$line" != *"|"*"|"*"|"* ]]; then
      ry_git_commit_emit_invalid_plan_row "$line_number" "$line"
      return 1
    fi

    IFS='|' read -r bucket candidate message files_column extra <<< "$line"
    if [[ -n "${extra-}" ]]; then
      ry_git_commit_emit_invalid_plan_row "$line_number" "$line"
      return 1
    fi

    normalized_files=""
    IFS=',' read -ra file_paths <<< "$files_column"
    for file_path in "${file_paths[@]}"; do
      file_path="$(ry_git_commit_trim_whitespace "$file_path")"
      [[ -n "$file_path" ]] || continue
      normalized_files+="$file_path"$'\n'
    done

    if [[ -z "$normalized_files" ]]; then
      ry_git_commit_emit_invalid_plan_row "$line_number" "$line"
      return 1
    fi

    while IFS= read -r file_path; do
      [[ -n "$file_path" ]] || continue
      existing_candidate=""

      while IFS=$'\t' read -r seen_bucket seen_file seen_candidate; do
        [[ -n "$seen_bucket" ]] || continue
        if [[ "$seen_bucket" == "$bucket" && "$seen_file" == "$file_path" ]]; then
          existing_candidate="$seen_candidate"
          break
        fi
      done <<< "$seen_entries"

      if [[ -n "$existing_candidate" && "$existing_candidate" != "$candidate" ]]; then
        printf 'error=duplicate_file_in_bucket\n'
        printf 'failed_phase=validate\n'
        printf 'bucket=%s\n' "$bucket"
        printf 'file=%s\n' "$file_path"
        printf 'first_candidate=%s\n' "$existing_candidate"
        printf 'second_candidate=%s\n' "$candidate"
        return 1
      fi

      if [[ -z "$existing_candidate" ]]; then
        seen_entries+="$bucket"$'\t'"$file_path"$'\t'"$candidate"$'\n'
      fi
    done <<< "$normalized_files"
  done < "$plan_file"
}
