#!/usr/bin/env bats

@test "renders staged and unstaged groups with file lists" {
  run bash modules/git/ry-git-commit/present-candidates.sh <<'EOF'
[staged]|1|fix(commit): 修复候选编号解析错误|src/commit/parser.ts,src/commit/selector.ts
[unstaged]|2|docs(readme): update install example|README.md
EOF
  [ "$status" -eq 0 ]
  [[ "$output" == *"Staged candidates"* ]]
  [[ "$output" == *"[staged] 1. fix(commit): 修复候选编号解析错误"* ]]
  [[ "$output" == *"Files: src/commit/parser.ts, src/commit/selector.ts"* ]]
  [[ "$output" == *"Unstaged candidates"* ]]
}
