#!/usr/bin/env bats

@test "command contract invokes runtime helpers through bash with resolved project path" {
  run grep -F 'bash "$plugin_root/runtime/project-context.sh" --cwd "$PWD" [--project <project>] [--branch <branch>]' "$BATS_TEST_DIRNAME/../commands/ry-git-commit.md"
  [ "$status" -eq 0 ]

  run grep -F 'bash "$plugin_root/runtime/git-state.sh" "$project_path"' "$BATS_TEST_DIRNAME/../commands/ry-git-commit.md"
  [ "$status" -eq 0 ]
}

@test "command contract reports staged and unstaged changes before commit flow" {
  run grep -F 'First, directly tell the user which changes are currently staged and which are currently unstaged.' "$BATS_TEST_DIRNAME/../commands/ry-git-commit.md"
  [ "$status" -eq 0 ]
}

@test "command contract requires exact uniform selection prompt" {
  run grep -F 'Select commit numbers, or 0 to over' "$BATS_TEST_DIRNAME/../commands/ry-git-commit.md"
  [ "$status" -eq 0 ]
}

@test "command contract no longer documents single-candidate auto-commit behavior" {
  run grep -F 'If only one candidate exists, skip selection and commit that candidate directly.' "$BATS_TEST_DIRNAME/../commands/ry-git-commit.md"
  [ "$status" -ne 0 ]
}

@test "build execution plan passes candidate rows through unchanged" {
  script_path="$BATS_TEST_DIRNAME/../modules/git/ry-git-commit/build-execution-plan.sh"
  candidate_row='[staged]|1|refactor: review staged change in selected-staged.txt|selected-staged.txt'

  run bash -c 'printf "%s\n" "$1" | bash "$2"' _ "$candidate_row" "$script_path"

  [ "$status" -eq 0 ]
  [ "$output" = "$candidate_row" ]
}
