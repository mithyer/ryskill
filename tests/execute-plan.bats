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

@test "fails when execution plan is empty" {
  : > "$plan_file"

  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

  [ "$status" -eq 1 ]
  [[ "$output" == *"error=empty_execution_plan"* ]]
  [[ "$output" == *"failed_phase=validate"* ]]
}

@test "fails when same bucket contains duplicate file across candidates" {
  cat <<'EOF' > "$plan_file"
[staged]|1|fix(parser): keep tokens explicit|runtime/selection-parser.sh
[staged]|2|fix(parser): keep parser explicit|runtime/selection-parser.sh
EOF

  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

  [ "$status" -eq 1 ]
  [[ "$output" == *"error=duplicate_file_in_bucket"* ]]
  [[ "$output" == *"failed_phase=validate"* ]]
}

@test "fails when same bucket contains overlapping file inside multi-file candidate list" {
  cat <<'EOF' > "$plan_file"
[staged]|1|fix(parser): keep tokens explicit|runtime/selection-parser.sh, runtime/execute-plan.sh
[staged]|2|fix(parser): keep parser explicit|runtime/selection-parser.sh, runtime/other.sh
EOF

  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

  [ "$status" -eq 1 ]
  [[ "$output" == *"error=duplicate_file_in_bucket"* ]]
  [[ "$output" == *"failed_phase=validate"* ]]
}

@test "fails explicitly after validation while execution remains disabled" {
  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

  [ "$status" -eq 1 ]
  [[ "$output" == *"error=execution_not_yet_enabled"* ]]
  [[ "$output" == *"failed_phase=snapshot"* ]]
}
