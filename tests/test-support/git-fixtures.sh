setup_temp_repo() {
  local repo_dir="$1"

  rm -rf "$repo_dir"
  mkdir -p "$repo_dir"
  git init "$repo_dir" >/dev/null
  git -C "$repo_dir" config user.name "Test User"
  git -C "$repo_dir" config user.email "test@example.com"

  printf '%s\n' 'initial selected staged' > "$repo_dir/selected-staged.txt"
  printf '%s\n' 'initial leftover unstaged' > "$repo_dir/leftover-unstaged.txt"
  printf '%s\n' 'initial leftover staged' > "$repo_dir/leftover-staged.txt"
  printf '%s\n' 'initial selected unstaged' > "$repo_dir/selected-unstaged.txt"

  git -C "$repo_dir" add selected-staged.txt leftover-unstaged.txt leftover-staged.txt selected-unstaged.txt
  git -C "$repo_dir" commit -m "Initial commit" >/dev/null

  SETUP_TEMP_REPO_DIR="$repo_dir"
}
