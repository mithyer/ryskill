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

@test "fails explicitly while execute-plan remains dry-run skeleton" {
  run bash modules/git/ry-git-commit/execute-plan.sh . "$plan_file"

  [ "$status" -eq 1 ]
  [[ "$output" == *"error=execute_plan_not_implemented"* ]]
  [[ "$output" == *"mode=dry_run_only"* ]]
}
