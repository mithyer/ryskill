#!/usr/bin/env bats

setup() {
  temp_dir="$(mktemp -d)"
  plan_file="$temp_dir/plan.txt"
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

  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

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

  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

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

  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

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

  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

  [ "$status" -eq 1 ]
  assert_structured_error \
    "invalid_plan_row" \
    "validate" \
    $'error=invalid_plan_row\nfailed_phase=validate\nline_number=2\nline=[staged]|2|missing files column'
}

@test "fails explicitly after validation while execution remains disabled" {
  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

  [ "$status" -eq 1 ]
  assert_structured_error \
    "execution_not_yet_enabled" \
    "snapshot" \
    $'error=execution_not_yet_enabled\nfailed_phase=snapshot\nrepo_path=.'
}
