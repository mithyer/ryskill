#!/usr/bin/env bats

setup() {
  temp_dir="$(mktemp -d)"
  repo_path="$temp_dir/repo"
  git init "$repo_path" >/dev/null
  default_branch="$(git -C "$repo_path" branch --show-current)"
  git -C "$repo_path" config user.name test
  git -C "$repo_path" config user.email test@example.com
  printf 'base\n' > "$repo_path/file.txt"
  git -C "$repo_path" add file.txt
  git -C "$repo_path" commit -m 'base' >/dev/null
}

teardown() {
  rm -rf "$temp_dir"
}

@test "detects rebase state in a git worktree via absolute git dir" {
  git -C "$repo_path" worktree add "$temp_dir/wt" -b feature/test >/dev/null
  worktree_path="$temp_dir/wt"
  git_dir="$(git -C "$worktree_path" rev-parse --absolute-git-dir)"
  mkdir -p "$git_dir/rebase-merge"

  run bash runtime/git-state.sh "$worktree_path"

  [ "$status" -eq 1 ]
  [ "$output" = "unsafe_state=rebase_in_progress" ]
}

@test "detects cherry-pick state in a git worktree via absolute git dir" {
  git -C "$repo_path" worktree add "$temp_dir/wt" -b feature/test >/dev/null
  worktree_path="$temp_dir/wt"
  git_dir="$(git -C "$worktree_path" rev-parse --absolute-git-dir)"
  : > "$git_dir/CHERRY_PICK_HEAD"

  run bash runtime/git-state.sh "$worktree_path"

  [ "$status" -eq 1 ]
  [ "$output" = "unsafe_state=cherry_pick_in_progress" ]
}

@test "detects merge state before unresolved conflict cleanup finishes" {
  git -C "$repo_path" branch side
  printf 'main-change\n' > "$repo_path/file.txt"
  git -C "$repo_path" add file.txt
  git -C "$repo_path" commit -m 'change on main' >/dev/null
  git -C "$repo_path" switch side >/dev/null
  printf 'side-change\n' > "$repo_path/file.txt"
  git -C "$repo_path" add file.txt
  git -C "$repo_path" commit -m 'change on side' >/dev/null
  git -C "$repo_path" switch "$default_branch" >/dev/null
  git -C "$repo_path" merge side >/dev/null 2>&1 || true

  run bash runtime/git-state.sh "$repo_path"

  [ "$status" -eq 1 ]
  [ "$output" = "unsafe_state=merge_in_progress" ]
}

@test "detects unresolved conflicts from porcelain status in a worktree" {
  git -C "$repo_path" branch side
  printf 'main-change\n' > "$repo_path/file.txt"
  git -C "$repo_path" add file.txt
  git -C "$repo_path" commit -m 'change on main' >/dev/null
  git -C "$repo_path" worktree add "$temp_dir/wt" -b feature/test side >/dev/null
  worktree_path="$temp_dir/wt"
  printf 'side-change\n' > "$worktree_path/file.txt"
  git -C "$worktree_path" add file.txt
  git -C "$worktree_path" commit -m 'change on side' >/dev/null
  git -C "$worktree_path" merge "$default_branch" >/dev/null 2>&1 || true
  git_dir="$(git -C "$worktree_path" rev-parse --absolute-git-dir)"
  rm -f "$git_dir/MERGE_HEAD"

  run bash runtime/git-state.sh "$worktree_path"

  [ "$status" -eq 1 ]
  [ "$output" = "unsafe_state=unresolved_conflicts" ]
}
