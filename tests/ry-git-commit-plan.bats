#!/usr/bin/env bats

@test "builds ordered execution plan from selected indexes" {
  run bash modules/git/ry-git-commit/build-execution-plan.sh '1 3' <<'EOF'
[staged]|1|fix(commit): 修复候选编号解析错误|src/commit/parser.ts
[staged]|2|refactor(git): 提取上下文解析逻辑|runtime/project-context.sh
[unstaged]|3|docs(readme): update install example|README.md
EOF
  [ "$status" -eq 0 ]
  [[ "$output" == *"[staged]|1|fix(commit): 修复候选编号解析错误"* ]]
  [[ "$output" == *"[unstaged]|3|docs(readme): update install example"* ]]
  [[ "$output" != *"|2|"* ]]
}

@test "single candidate contract can bypass selection by selecting its only index" {
  run bash modules/git/ry-git-commit/build-execution-plan.sh '12' <<'EOF'
[staged]|12|fix(parser): keep tokens explicit|runtime/selection-parser.sh
EOF
  [ "$status" -eq 0 ]
  [ "$output" = "[staged]|12|fix(parser): keep tokens explicit|runtime/selection-parser.sh" ]
}
