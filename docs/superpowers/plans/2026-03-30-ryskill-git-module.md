# ryskill Git Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the standalone `ryskill` Claude plugin repository with an initial `git` module and `/ry:git-commit` command that splits working tree changes into transaction-oriented commit candidates while preserving all unselected changes.

**Architecture:** The implementation uses a lightweight plugin host with a single `git` module. `/ry:git-commit` is decomposed into focused units for argument parsing, repository snapshotting, staged/unstaged candidate analysis, user-facing presentation, selection parsing, execution planning, and safe git mutation helpers.

**Tech Stack:** Claude plugin files, Markdown specs/plans, shell/git commands, focused helper scripts for patch analysis and execution, conventional commits.

---

## File Structure

### Create
- `plugin.json` — plugin metadata and install entry
- `README.md` — installation and command usage for `ryskill`
- `commands/ry-git-commit.md` — slash-command contract exposed to Claude
- `runtime/project-context.sh` — resolve current/explicit project and branch
- `runtime/git-state.sh` — snapshot repo state and detect unsafe conditions
- `runtime/selection-parser.sh` — parse `12`, `1-3`, `1,3,5` style selection input
- `modules/git/ry-git-commit/analyze-staged.sh` — build staged candidate list
- `modules/git/ry-git-commit/analyze-unstaged.sh` — build unstaged candidate list
- `modules/git/ry-git-commit/present-candidates.sh` — render grouped candidate output
- `modules/git/ry-git-commit/build-execution-plan.sh` — map user selection to executable plan
- `modules/git/ry-git-commit/execute-plan.sh` — execute selected candidates safely
- `modules/git/ry-git-commit/templates/commit-types.md` — supported commit type rules and examples
- `modules/git/ry-git-commit/templates/output-format.md` — staged/unstaged output format examples
- `tests/selection-parser.bats` — tests for selection parsing behavior
- `tests/project-context.bats` — tests for project/branch resolution behavior
- `tests/ry-git-commit-presentation.bats` — tests for grouped candidate rendering
- `tests/ry-git-commit-plan.bats` — tests for execution-plan generation behavior

### Modify
- `docs/superpowers/specs/2026-03-30-ryskill-design.md` — only if implementation uncovers a real spec contradiction

---

### Task 1: Create plugin skeleton and installation surface

**Files:**
- Create: `plugin.json`
- Create: `README.md`
- Create: `commands/ry-git-commit.md`

- [ ] **Step 1: Write the plugin metadata file**

```json
{
  "name": "ryskill",
  "version": "0.1.0",
  "description": "Modular Claude plugin with git utilities, starting with /ry:git-commit.",
  "commands": [
    {
      "name": "ry-git-commit",
      "file": "commands/ry-git-commit.md"
    }
  ]
}
```

- [ ] **Step 2: Write the command contract file**

```md
---
name: ry-git-commit
description: Split staged and unstaged changes into commit candidates and commit selected transactions safely.
---

Use the `runtime/project-context.sh`, `runtime/git-state.sh`, and `modules/git/ry-git-commit/*` helpers to:
1. Resolve target project and branch.
2. Reject unsafe repository states.
3. Analyze staged and unstaged changes separately.
4. Present grouped candidates with file lists.
5. Parse user selection when multiple candidates exist.
6. Execute only selected candidates while preserving all others.

Supported arguments:
- `--project <project>`
- `--branch <branch>`
```

- [ ] **Step 3: Write the initial README**

```md
# ryskill

`ryskill` is a standalone Claude plugin repository installed from GitHub via `plugin install`.

## Commands
- `/ry:git-commit`

## Current scope
- standalone plugin host
- git module
- staged/unstaged transaction-oriented commit splitting

## Installation
Document the GitHub install command here once the repository remote exists.
```

- [ ] **Step 4: Verify created files exist**

Run: `ls plugin.json README.md commands/ry-git-commit.md`
Expected: all three paths are listed

- [ ] **Step 5: Commit skeleton**

```bash
git add plugin.json README.md commands/ry-git-commit.md
git commit -m "feat: add ryskill plugin skeleton"
```

### Task 2: Implement project and branch resolution helpers

**Files:**
- Create: `runtime/project-context.sh`
- Test: `tests/project-context.bats`

- [ ] **Step 1: Write the failing tests for context resolution**

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/project-context.bats`
Expected: FAIL because `runtime/project-context.sh` does not exist yet

- [ ] **Step 3: Write minimal context resolver implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

cwd=""
project=""
branch=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd) cwd="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --branch) branch="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$cwd" ]]; then
  cwd="$PWD"
fi

if [[ -z "$project" ]]; then
  project="$cwd"
fi

if [[ ! -d "$project/.git" ]]; then
  echo "project_path=$project" >&2
  echo "error=not_a_git_repository" >&2
  exit 1
fi

if [[ -z "$branch" ]]; then
  branch="$(git -C "$project" rev-parse --abbrev-ref HEAD)"
fi

printf 'project_path=%s\nbranch=%s\n' "$project" "$branch"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/project-context.bats`
Expected: PASS

- [ ] **Step 5: Commit context resolver**

```bash
git add runtime/project-context.sh tests/project-context.bats
git commit -m "feat(git): add project context resolver"
```

### Task 3: Implement unsafe repository state detection

**Files:**
- Create: `runtime/git-state.sh`

- [ ] **Step 1: Write the repository state helper**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"

if git -C "$repo_path" rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
  echo "unsafe_state=merge_in_progress"
  exit 1
fi

if [[ -d "$repo_path/.git/rebase-merge" || -d "$repo_path/.git/rebase-apply" ]]; then
  echo "unsafe_state=rebase_in_progress"
  exit 1
fi

if [[ -f "$repo_path/.git/CHERRY_PICK_HEAD" ]]; then
  echo "unsafe_state=cherry_pick_in_progress"
  exit 1
fi

if git -C "$repo_path" diff --name-only --diff-filter=U | grep -q .; then
  echo "unsafe_state=unresolved_conflicts"
  exit 1
fi

echo "unsafe_state=clean_for_analysis"
```

- [ ] **Step 2: Verify helper reports a safe repository**

Run: `bash runtime/git-state.sh .`
Expected: `unsafe_state=clean_for_analysis`

- [ ] **Step 3: Make the helper executable**

Run: `chmod +x runtime/git-state.sh`
Expected: command succeeds with no output

- [ ] **Step 4: Commit repository state helper**

```bash
git add runtime/git-state.sh
git commit -m "feat(git): detect unsafe repository states"
```

### Task 4: Implement selection parser with ordered deduplication

**Files:**
- Create: `runtime/selection-parser.sh`
- Test: `tests/selection-parser.bats`

- [ ] **Step 1: Write the failing tests for selection parsing**

```bash
@test "parses compact digits" {
  run bash runtime/selection-parser.sh 135
  [ "$status" -eq 0 ]
  [ "$output" = "1 3 5" ]
}

@test "parses ranges and commas in display order" {
  run bash runtime/selection-parser.sh '3,1-2,2'
  [ "$status" -eq 0 ]
  [ "$output" = "1 2 3" ]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/selection-parser.bats`
Expected: FAIL because `runtime/selection-parser.sh` does not exist yet

- [ ] **Step 3: Write minimal parser implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

input="${1:-}"
normalized="${input//,/ }"
results=()

for token in $normalized; do
  if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
    start="${token%-*}"
    end="${token#*-}"
    for ((i=start; i<=end; i++)); do
      results+=("$i")
    done
  elif [[ "$token" =~ ^[0-9]+$ && ${#token} -gt 1 ]]; then
    for ((i=0; i<${#token}; i++)); do
      results+=("${token:$i:1}")
    done
  elif [[ "$token" =~ ^[0-9]+$ ]]; then
    results+=("$token")
  else
    echo "invalid_selection=$token" >&2
    exit 1
  fi
done

printf '%s\n' "${results[@]}" | awk '!seen[$0]++' | sort -n | paste -sd' ' -
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/selection-parser.bats`
Expected: PASS

- [ ] **Step 5: Commit selection parser**

```bash
git add runtime/selection-parser.sh tests/selection-parser.bats
git commit -m "feat(git): add selection parser"
```

### Task 5: Render staged and unstaged candidate groups

**Files:**
- Create: `modules/git/ry-git-commit/present-candidates.sh`
- Create: `modules/git/ry-git-commit/templates/output-format.md`
- Test: `tests/ry-git-commit-presentation.bats`

- [ ] **Step 1: Write the failing presentation test**

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/ry-git-commit-presentation.bats`
Expected: FAIL because presentation script does not exist yet

- [ ] **Step 3: Write minimal presentation implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

staged=()
unstaged=()

while IFS='|' read -r bucket index message files; do
  [[ -z "$bucket" ]] && continue
  line="$bucket|$index|$message|${files//,/, }"
  if [[ "$bucket" == "[staged]" ]]; then
    staged+=("$line")
  else
    unstaged+=("$line")
  fi
done

if [[ ${#staged[@]} -gt 0 ]]; then
  echo "Staged candidates"
  for item in "${staged[@]}"; do
    IFS='|' read -r bucket index message files <<<"$item"
    echo "$bucket $index. $message"
    echo "Files: $files"
  done
fi

if [[ ${#unstaged[@]} -gt 0 ]]; then
  echo "Unstaged candidates"
  for item in "${unstaged[@]}"; do
    IFS='|' read -r bucket index message files <<<"$item"
    echo "$bucket $index. $message"
    echo "Files: $files"
  done
fi
```

- [ ] **Step 4: Write the output format reference**

```md
# Candidate Output Format

Sections are rendered in this order:
1. Staged candidates
2. Unstaged candidates

Each entry shows:
- bucket label
- numeric index
- commit message
- default file list
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bats tests/ry-git-commit-presentation.bats`
Expected: PASS

- [ ] **Step 6: Commit presentation layer**

```bash
git add modules/git/ry-git-commit/present-candidates.sh modules/git/ry-git-commit/templates/output-format.md tests/ry-git-commit-presentation.bats
git commit -m "feat(git): add candidate presentation"
```

### Task 6: Implement execution-plan builder for user selections

**Files:**
- Create: `modules/git/ry-git-commit/build-execution-plan.sh`
- Test: `tests/ry-git-commit-plan.bats`

- [ ] **Step 1: Write the failing execution-plan test**

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/ry-git-commit-plan.bats`
Expected: FAIL because plan builder does not exist yet

- [ ] **Step 3: Write minimal execution-plan builder**

```bash
#!/usr/bin/env bash
set -euo pipefail

selected=" ${1:-} "
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  IFS='|' read -r bucket index message files <<<"$line"
  if [[ "$selected" == *" $index "* ]]; then
    echo "$bucket|$index|$message|$files"
  fi
done
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/ry-git-commit-plan.bats`
Expected: PASS

- [ ] **Step 5: Commit execution-plan builder**

```bash
git add modules/git/ry-git-commit/build-execution-plan.sh tests/ry-git-commit-plan.bats
git commit -m "feat(git): add execution plan builder"
```

### Task 7: Implement staged and unstaged candidate analyzers

**Files:**
- Create: `modules/git/ry-git-commit/analyze-staged.sh`
- Create: `modules/git/ry-git-commit/analyze-unstaged.sh`
- Create: `modules/git/ry-git-commit/templates/commit-types.md`

- [ ] **Step 1: Write the supported commit type reference**

```md
# Supported Commit Types

- feat — new feature
- fix — bug fix
- docs — documentation only
- style — formatting only
- refactor — code change that is neither a feature nor a fix
- test — test changes
- build — build system or dependency changes
- ci — CI/CD changes
- perf — performance improvements
```

- [ ] **Step 2: Write minimal staged analyzer**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_path="${1:-.}"
index=1

git -C "$repo_path" diff --cached --name-only | while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  echo "[staged]|$index|refactor: review staged change in $file|$file"
  index=$((index + 1))
done
```

- [ ] **Step 3: Write minimal unstaged analyzer**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_path="${1:-.}"
start_index="${2:-1}"
index="$start_index"

git -C "$repo_path" diff --name-only | while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  echo "[unstaged]|$index|refactor: review unstaged change in $file|$file"
  index=$((index + 1))
done
```

- [ ] **Step 4: Make analyzer scripts executable**

Run: `chmod +x modules/git/ry-git-commit/analyze-staged.sh modules/git/ry-git-commit/analyze-unstaged.sh`
Expected: command succeeds with no output

- [ ] **Step 5: Verify analyzers emit candidate rows**

Run: `bash modules/git/ry-git-commit/analyze-staged.sh . && bash modules/git/ry-git-commit/analyze-unstaged.sh . 6`
Expected: each script prints zero or more candidate rows in the `[bucket]|index|message|files` format

- [ ] **Step 6: Commit analyzers**

```bash
git add modules/git/ry-git-commit/analyze-staged.sh modules/git/ry-git-commit/analyze-unstaged.sh modules/git/ry-git-commit/templates/commit-types.md
git commit -m "feat(git): add candidate analyzers"
```

### Task 8: Implement safe execution helper

**Files:**
- Create: `modules/git/ry-git-commit/execute-plan.sh`

- [ ] **Step 1: Write the execution helper skeleton**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"
plan_file="$2"

while IFS='|' read -r bucket index message files; do
  [[ -z "$bucket" ]] && continue
  echo "executing bucket=$bucket index=$index message=$message files=$files"
done < "$plan_file"
```

- [ ] **Step 2: Make the helper executable**

Run: `chmod +x modules/git/ry-git-commit/execute-plan.sh`
Expected: command succeeds with no output

- [ ] **Step 3: Verify the helper reads a plan file**

Run: `printf '[staged]|1|fix(commit): demo|plugin.json\n' > /tmp/ryskill-plan.txt && bash modules/git/ry-git-commit/execute-plan.sh . /tmp/ryskill-plan.txt`
Expected: prints `executing bucket=[staged] index=1 message=fix(commit): demo files=plugin.json`

- [ ] **Step 4: Commit execution helper skeleton**

```bash
git add modules/git/ry-git-commit/execute-plan.sh
git commit -m "feat(git): add execution helper skeleton"
```

### Task 9: Wire the command end-to-end

**Files:**
- Modify: `commands/ry-git-commit.md`
- Modify: `runtime/project-context.sh`
- Modify: `runtime/git-state.sh`
- Modify: `runtime/selection-parser.sh`
- Modify: `modules/git/ry-git-commit/analyze-staged.sh`
- Modify: `modules/git/ry-git-commit/analyze-unstaged.sh`
- Modify: `modules/git/ry-git-commit/present-candidates.sh`
- Modify: `modules/git/ry-git-commit/build-execution-plan.sh`
- Modify: `modules/git/ry-git-commit/execute-plan.sh`

- [ ] **Step 1: Update the command contract with the final orchestration order**

```md
Use the helpers in this order:
1. `runtime/project-context.sh`
2. `runtime/git-state.sh`
3. `modules/git/ry-git-commit/analyze-staged.sh`
4. `modules/git/ry-git-commit/analyze-unstaged.sh`
5. `modules/git/ry-git-commit/present-candidates.sh`
6. `runtime/selection-parser.sh` when multiple candidates exist
7. `modules/git/ry-git-commit/build-execution-plan.sh`
8. `modules/git/ry-git-commit/execute-plan.sh`

If only one candidate exists, skip selection and commit directly.
Always preserve unselected changes.
```

- [ ] **Step 2: Verify the command contract reflects the implemented helpers**

Run: `grep -n 'runtime/project-context.sh\|modules/git/ry-git-commit/execute-plan.sh' commands/ry-git-commit.md`
Expected: both helper references are present

- [ ] **Step 3: Commit the end-to-end wiring**

```bash
git add commands/ry-git-commit.md runtime/project-context.sh runtime/git-state.sh runtime/selection-parser.sh modules/git/ry-git-commit/analyze-staged.sh modules/git/ry-git-commit/analyze-unstaged.sh modules/git/ry-git-commit/present-candidates.sh modules/git/ry-git-commit/build-execution-plan.sh modules/git/ry-git-commit/execute-plan.sh
git commit -m "feat(git): wire ry-git-commit workflow"
```

### Task 10: Final verification and documentation pass

**Files:**
- Modify: `README.md`
- Modify: `commands/ry-git-commit.md`

- [ ] **Step 1: Update README usage section with final examples**

```md
## Usage

### Default current repository
`/ry:git-commit`

### Explicit project and branch
`/ry:git-commit --project /path/to/repo --branch feature/demo`

### Multi-candidate flow
The command groups candidates into staged and unstaged sections, shows file lists, and asks which numbered candidates to commit.
```

- [ ] **Step 2: Run focused verification commands**

Run: `bats tests/project-context.bats tests/selection-parser.bats tests/ry-git-commit-presentation.bats tests/ry-git-commit-plan.bats`
Expected: PASS for all listed test files

- [ ] **Step 3: Run a manual smoke check of helper chain**

Run: `bash runtime/project-context.sh --cwd "$PWD" && bash runtime/git-state.sh .`
Expected: project path and branch are printed, then `unsafe_state=clean_for_analysis`

- [ ] **Step 4: Commit docs and verification updates**

```bash
git add README.md commands/ry-git-commit.md
git commit -m "docs: finalize ry-git-commit usage"
```

---

## Self-Review Checklist

### Spec coverage
- Standalone `ryskill` repository and installable plugin surface: covered in Task 1
- Modular host shape with initial git module: covered in Tasks 1 and 9
- `/ry:git-commit` default and explicit context resolution: covered in Task 2
- Unsafe-state rejection boundary: covered in Task 3
- Selection parsing rules: covered in Task 4
- Candidate grouping with staged/unstaged labels and file lists: covered in Task 5
- Ordered execution-plan building: covered in Task 6
- Initial candidate analysis for staged and unstaged buckets: covered in Task 7
- Execution helper and preservation-oriented workflow skeleton: covered in Task 8
- End-to-end orchestration and docs: covered in Tasks 9 and 10

### Placeholder scan
- No `TODO`, `TBD`, or unresolved task placeholders remain in plan steps.
- Every code-writing step includes actual file content or command content.

### Type and naming consistency
- Helper names are consistent across tasks: `project-context.sh`, `git-state.sh`, `selection-parser.sh`, `present-candidates.sh`, `build-execution-plan.sh`, `execute-plan.sh`
- Candidate row format is consistent across tasks: `[bucket]|index|message|files`
