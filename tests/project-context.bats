#!/usr/bin/env bats

@test "defaults to current repository when no project or branch is provided" {
  run bash runtime/project-context.sh --cwd "$PWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"project_path=$PWD"* ]]
}

@test "returns explicit branch when branch is provided" {
  run bash runtime/project-context.sh --cwd "$PWD" --branch feature/demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"branch=feature/demo"* ]]
}

@test "returns usage and argument error when option value is missing" {
  run bash runtime/project-context.sh --cwd "$PWD" --branch
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: runtime/project-context.sh [--cwd PATH] [--project PATH] [--branch NAME]"* ]]
  [[ "$output" == *"error=missing_argument_value flag=--branch"* ]]
}
