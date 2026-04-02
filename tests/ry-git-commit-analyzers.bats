#!/usr/bin/env bats

load 'test-support/git-fixtures.sh'

setup() {
  temp_dir="$(mktemp -d)"
  setup_temp_repo "$temp_dir/repo"
  repo_dir="$SETUP_TEMP_REPO_DIR"
  staged_script="$BATS_TEST_DIRNAME/../modules/git/ry-git-commit/analyze-staged.sh"
  unstaged_script="$BATS_TEST_DIRNAME/../modules/git/ry-git-commit/analyze-unstaged.sh"
}

teardown() {
  rm -rf "$temp_dir"
}

@test "analyze-staged generates conservative conventional commit message from nested path" {
  mkdir -p "$repo_dir/Main/DeviceDetails/BikeTrainer"
  printf '%s\n' 'change' > "$repo_dir/Main/DeviceDetails/BikeTrainer/BikeTrainerViewController.swift"
  git -C "$repo_dir" add Main/DeviceDetails/BikeTrainer/BikeTrainerViewController.swift

  run bash "$staged_script" "$repo_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"[staged]|1|fix(bike-trainer): update BikeTrainerViewController|Main/DeviceDetails/BikeTrainer/BikeTrainerViewController.swift"* ]]
}

@test "analyze-staged falls back to no scope for root file" {
  printf '%s\n' 'root change' >> "$repo_dir/README.md"
  git -C "$repo_dir" add README.md

  run bash "$staged_script" "$repo_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"fix: update README|README.md"* ]]
}

@test "analyze-unstaged generates conservative conventional commit message and preserves start index" {
  mkdir -p "$repo_dir/Main/DeviceDetails/BikeTrainer"
  printf '%s\n' 'change' > "$repo_dir/Main/DeviceDetails/BikeTrainer/BikeTrainerViewController.swift"

  run bash "$unstaged_script" "$repo_dir" 7

  [ "$status" -eq 0 ]
  [[ "$output" == *"[unstaged]|7|fix(bike-trainer): update BikeTrainerViewController|Main/DeviceDetails/BikeTrainer/BikeTrainerViewController.swift"* ]]
}
