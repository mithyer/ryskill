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
