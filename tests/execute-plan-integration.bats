#!/usr/bin/env bats

load 'test-support/git-fixtures.sh'

setup() {
  temp_dir="$(mktemp -d)"
  setup_temp_repo "$temp_dir/repo"
  repo_dir="$SETUP_TEMP_REPO_DIR"
  plan_file="$temp_dir/plan.txt"
  script_path="${BATS_TEST_DIRNAME}/../modules/git/ry-git-commit/execute-plan.sh"
}

teardown() {
  rm -rf "$temp_dir"
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

run_execute_plan() {
  local repo_path="$1"
  local plan_path="$2"

  run bash -c '"$1" "$2" "$3" 2>&1' _ "$script_path" "$repo_path" "$plan_path"
}

@test "fails closed when a staged candidate references any file missing from the staged snapshot" {
  printf '%s\n' 'selected staged line' >> "$repo_dir/selected-staged.txt"
  git -C "$repo_dir" add selected-staged.txt

  cat <<'EOF' > "$plan_file"
[staged]|1|feat: staged selection must fully exist|selected-staged.txt,leftover-staged.txt
EOF

  run_execute_plan "$repo_dir" "$plan_file"

  [ "$status" -eq 1 ]
  [ "$(extract_kv_value "error" "$output")" = "selected_files_not_present_in_bucket" ]
  [ "$(extract_kv_value "failed_phase" "$output")" = "snapshot" ]
  [ "$(extract_kv_value "bucket" "$output")" = "[staged]" ]
  [ "$(extract_kv_value "file" "$output")" = "leftover-staged.txt" ]
}

@test "commits only the selected staged candidate files" {
  printf '%s\n' 'selected staged line' >> "$repo_dir/selected-staged.txt"
  printf '%s\n' 'leftover staged line' >> "$repo_dir/leftover-staged.txt"
  git -C "$repo_dir" add selected-staged.txt leftover-staged.txt

  cat <<'EOF' > "$plan_file"
[staged]|1|feat: commit only selected staged file|selected-staged.txt
EOF

  run_execute_plan "$repo_dir" "$plan_file"

  [ "$status" -eq 0 ]
  [ "$(git -C "$repo_dir" log -1 --pretty=%s)" = "feat: commit only selected staged file" ]
  [[ "$(git -C "$repo_dir" show --name-only --format= HEAD)" == *"selected-staged.txt"* ]]
  [[ "$(git -C "$repo_dir" show --name-only --format= HEAD)" != *"leftover-staged.txt"* ]]
  [ -n "$(git -C "$repo_dir" diff --cached -- leftover-staged.txt)" ]
  [ -z "$(git -C "$repo_dir" diff --cached -- selected-staged.txt)" ]
}

@test "commits only the selected unstaged candidate files" {
  printf '%s\n' 'selected unstaged line' >> "$repo_dir/selected-unstaged.txt"
  printf '%s\n' 'leftover unstaged line' >> "$repo_dir/leftover-unstaged.txt"

  cat <<'EOF' > "$plan_file"
[unstaged]|2|feat: commit only selected unstaged file|selected-unstaged.txt
EOF

  run_execute_plan "$repo_dir" "$plan_file"

  [ "$status" -eq 0 ]
  [ "$(git -C "$repo_dir" log -1 --pretty=%s)" = "feat: commit only selected unstaged file" ]
  [[ "$(git -C "$repo_dir" show --name-only --format= HEAD)" == *"selected-unstaged.txt"* ]]
  [[ "$(git -C "$repo_dir" show --name-only --format= HEAD)" != *"leftover-unstaged.txt"* ]]
  [ -n "$(git -C "$repo_dir" diff -- leftover-unstaged.txt)" ]
  [ -z "$(git -C "$repo_dir" diff -- selected-unstaged.txt)" ]
}

@test "commits selected candidate message verbatim" {
  printf '%s\n' 'selected staged line' >> "$repo_dir/selected-staged.txt"
  git -C "$repo_dir" add selected-staged.txt

  cat <<'EOF' > "$plan_file"
[staged]|1|fix(bike-trainer): update BikeTrainerViewController|selected-staged.txt
EOF

  run_execute_plan "$repo_dir" "$plan_file"

  [ "$status" -eq 0 ]
  [ "$(git -C "$repo_dir" log -1 --pretty=%s)" = "fix(bike-trainer): update BikeTrainerViewController" ]
}

@test "preserves unselected unstaged changes when a later candidate commit fails" {
  printf '%s\n' 'selected staged line' >> "$repo_dir/selected-staged.txt"
  printf '%s\n' 'leftover unstaged line' >> "$repo_dir/leftover-unstaged.txt"
  git -C "$repo_dir" add selected-staged.txt

  cat <<'EOF' > "$repo_dir/.git/hooks/commit-msg"
#!/usr/bin/env bash
if grep -q 'reject second candidate' "$1"; then
  printf '%s\n' 'hook rejected second candidate' >&2
  exit 1
fi
EOF
  chmod +x "$repo_dir/.git/hooks/commit-msg"

  cat <<'EOF' > "$plan_file"
[staged]|1|feat: commit selected staged file|selected-staged.txt
[unstaged]|2|feat: reject second candidate|selected-unstaged.txt
EOF

  printf '%s\n' 'selected unstaged line' >> "$repo_dir/selected-unstaged.txt"

  run_execute_plan "$repo_dir" "$plan_file"

  [ "$status" -eq 1 ]
  [ "$(extract_kv_value "error" "$output")" = "git_commit_failed" ]
  [ "$(extract_kv_value "restoration_mode" "$output")" = "full_snapshot" ]
  [ "$(extract_kv_value "restored_unselected_changes" "$output")" = "no" ]
  [ -n "$(git -C "$repo_dir" diff --cached -- selected-unstaged.txt)" ]
  [[ "$output" == *"git_commit_output_file="* ]]
}

@test "surfaces commit failure output file for diagnosis" {
  printf '%s\n' 'selected staged line' >> "$repo_dir/selected-staged.txt"
  git -C "$repo_dir" add selected-staged.txt

  cat <<'EOF' > "$repo_dir/.git/hooks/commit-msg"
#!/usr/bin/env bash
printf '%s\n' 'hook rejected candidate for diagnostics' >&2
exit 1
EOF
  chmod +x "$repo_dir/.git/hooks/commit-msg"

  cat <<'EOF' > "$plan_file"
[staged]|1|feat: hook should reject this commit|selected-staged.txt
EOF

  run_execute_plan "$repo_dir" "$plan_file"

  [ "$status" -eq 1 ]
  [ "$(extract_kv_value "error" "$output")" = "git_commit_failed" ]
  commit_output_file="$(extract_kv_value "git_commit_output_file" "$output")"
  [ -f "$commit_output_file" ]
  [[ "$(<"$commit_output_file")" == *"hook rejected candidate for diagnostics"* ]]
}
