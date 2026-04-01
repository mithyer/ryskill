#!/usr/bin/env bats

setup() {
  temp_dir="$(mktemp -d)"
  plan_file="$temp_dir/plan.txt"
  script_path="/Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit/modules/git/ry-git-commit/execute-plan.sh"
  cat <<'EOF' > "$plan_file"
[staged]|1|fix(parser): keep tokens explicit|runtime/selection-parser.sh
EOF
}

teardown() {
  rm -rf "$temp_dir"
}

parse_kv_output() {
  local input="$1"
  local line

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ "$line" == *=* ]] || return 1
    printf '%s\n' "$line"
  done <<< "$input"
}

extract_kv_value() {
  local key="$1"
  local input="$2"
  local line

  while IFS= read -r line; do
    [[ "$line" == "$key="* ]] || continue
    printf '%s\n' "${line#*=}"
    return 0
  done <<< "$input"

  return 1
}

assert_structured_error() {
  local expected_error="$1"
  local expected_phase="$2"
  local expected_lines="$3"
  local parsed

  parsed="$(parse_kv_output "$output")"

  [ "$parsed" = "$expected_lines" ]
  [[ "$parsed" == *$'error='"$expected_error"* ]]
  [[ "$parsed" == *$'failed_phase='"$expected_phase"* ]]
}

@test "fails when execution plan is empty" {
  : > "$plan_file"

  run bash "$script_path" . "$plan_file"

  [ "$status" -eq 1 ]
  assert_structured_error \
    "empty_execution_plan" \
    "validate" \
    $'error=empty_execution_plan\nfailed_phase=validate'
}

@test "fails when same bucket contains duplicate file across candidates" {
  cat <<'EOF' > "$plan_file"
[staged]|1|fix(parser): keep tokens explicit|runtime/selection-parser.sh
[staged]|2|fix(parser): keep parser explicit|runtime/selection-parser.sh
EOF

  run bash "$script_path" . "$plan_file"

  [ "$status" -eq 1 ]
  assert_structured_error \
    "duplicate_file_in_bucket" \
    "validate" \
    $'error=duplicate_file_in_bucket\nfailed_phase=validate\nbucket=[staged]\nfile=runtime/selection-parser.sh\nfirst_candidate=1\nsecond_candidate=2'
}

@test "fails when same bucket contains overlapping file inside multi-file candidate list" {
  cat <<'EOF' > "$plan_file"
[staged]|1|fix(parser): keep tokens explicit|runtime/selection-parser.sh, runtime/execute-plan.sh
[staged]|2|fix(parser): keep parser explicit|runtime/selection-parser.sh, runtime/other.sh
EOF

  run bash "$script_path" . "$plan_file"

  [ "$status" -eq 1 ]
  assert_structured_error \
    "duplicate_file_in_bucket" \
    "validate" \
    $'error=duplicate_file_in_bucket\nfailed_phase=validate\nbucket=[staged]\nfile=runtime/selection-parser.sh\nfirst_candidate=1\nsecond_candidate=2'
}

@test "fails closed on malformed plan row with structured validation error" {
  cat <<'EOF' > "$plan_file"
[staged]|1|fix(parser): keep tokens explicit|runtime/selection-parser.sh
[staged]|2|missing files column
EOF

  run bash "$script_path" . "$plan_file"

  [ "$status" -eq 1 ]
  assert_structured_error \
    "invalid_plan_row" \
    "validate" \
    $'error=invalid_plan_row\nfailed_phase=validate\nline_number=2\nline=[staged]|2|missing files column'
}

@test "fails closed when files column exists but is empty" {
  cat <<'EOF' > "$plan_file"
[staged]|1|fix(parser): keep tokens explicit|
EOF

  run bash "$script_path" . "$plan_file"

  [ "$status" -eq 1 ]
  assert_structured_error \
    "invalid_plan_row" \
    "validate" \
    $'error=invalid_plan_row\nfailed_phase=validate\nline_number=1\nline=[staged]|1|fix(parser): keep tokens explicit|'
}

@test "fails closed when files column is only whitespace" {
  printf '%s\n' '[staged]|1|fix(parser): keep tokens explicit|   ' > "$plan_file"

  run bash "$script_path" . "$plan_file"

  [ "$status" -eq 1 ]
  assert_structured_error \
    "invalid_plan_row" \
    "validate" \
    $'error=invalid_plan_row\nfailed_phase=validate\nline_number=1\nline=[staged]|1|fix(parser): keep tokens explicit|   '
}

@test "executes a simple staged plan and emits structured success output" {
  temp_repo_dir="$temp_dir/repo"
  mkdir -p "$temp_repo_dir"
  git init "$temp_repo_dir" >/dev/null
  git -C "$temp_repo_dir" config user.name "Test User"
  git -C "$temp_repo_dir" config user.email "test@example.com"
  printf '%s\n' 'base' > "$temp_repo_dir/file.txt"
  git -C "$temp_repo_dir" add file.txt
  git -C "$temp_repo_dir" commit -m "init" >/dev/null
  printf '%s\n' 'base' 'staged change' > "$temp_repo_dir/file.txt"
  git -C "$temp_repo_dir" add file.txt
  printf '%s\n' '[staged]|1|feat: commit staged change|file.txt' > "$plan_file"

  run bash "$script_path" "$temp_repo_dir" "$plan_file"

  [ "$status" -eq 0 ]
  [ "$(extract_kv_value "result" "$output")" = "ok" ]
  [ "$(extract_kv_value "committed_candidates" "$output")" = "1" ]
  [ "$(extract_kv_value "restored_unselected_changes" "$output")" = "no" ]
  [ -d "$(extract_kv_value "rescue_dir" "$output")" ]
}
