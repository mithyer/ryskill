# ryskill Install and Usage Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `ryskill` load through a real Claude plugin path and verify that `/ry:git-commit` is recognized and can complete at least one real repository flow successfully.

**Architecture:** The work stays narrowly focused on the plugin surface and the existing `ry-git-commit` execution path. First align the outward-facing contract and README with the real implementation, then verify the command behavior with automated tests, then verify plugin loading and command recognition through Claude’s real local plugin workflow, and finally run one real end-to-end scenario in a temporary repository.

**Tech Stack:** Claude plugin files, Markdown docs, shell scripts, Git, Bats tests, Claude Code plugin commands, local temp repositories.

---

## File Structure

### Modify
- `.worktrees/ry-git-commit/README.md` — replace installation placeholder with a real local development and verification flow
- `.worktrees/ry-git-commit/commands/ry-git-commit.md` — remove stale dry-run note and describe the current real execution contract
- `.worktrees/ry-git-commit/plugin.json` — only if plugin metadata blocks real loading or command recognition
- `.worktrees/ry-git-commit/modules/git/ry-git-commit/execute-plan.sh` — only if real command verification exposes a runtime contract bug
- `.worktrees/ry-git-commit/modules/git/ry-git-commit/execute-plan-lib.sh` — only if real command verification exposes state-restoration bugs
- `.worktrees/ry-git-commit/tests/execute-plan.bats` — keep structured error/output tests aligned with command behavior
- `.worktrees/ry-git-commit/tests/execute-plan-integration.bats` — keep real staged/unstaged preservation tests green
- `docs/superpowers/specs/2026-04-01-ryskill-install-usage-design.md` — only if implementation reveals a real contradiction in the approved spec

### Create
- `docs/superpowers/plans/2026-04-01-ryskill-install-usage-verification.md` — this implementation plan
- `.worktrees/ry-git-commit/tests/plugin-install-smoke.bats` — optional, only if a tiny scripted smoke test is needed for repeatable local verification

---

### Task 1: Align the command contract with real execution

**Files:**
- Modify: `.worktrees/ry-git-commit/commands/ry-git-commit.md:1-22`

- [ ] **Step 1: Write the failing contract expectation as a review checklist**

```text
Expected contract after edit:
- describes staged and unstaged analysis order
- says single-candidate flows may commit directly
- says selected candidates are executed via build-execution-plan.sh + execute-plan.sh
- says unselected changes are preserved
- does not say execute-plan.sh is still dry-run only
```

- [ ] **Step 2: Confirm the current file still contains the stale dry-run note**

Run: `grep -n "dry-run/preview skeleton" .worktrees/ry-git-commit/commands/ry-git-commit.md`
Expected: one matching line showing the stale note

- [ ] **Step 3: Replace the command contract with the minimal accurate version**

```md
---
name: ry-git-commit
description: Split staged and unstaged changes into commit candidates and commit selected transactions safely.
---

Use the helpers in this order:
1. `runtime/project-context.sh`
2. `runtime/git-state.sh`
3. `modules/git/ry-git-commit/analyze-staged.sh`
4. `modules/git/ry-git-commit/analyze-unstaged.sh`
5. `modules/git/ry-git-commit/present-candidates.sh`
6. `runtime/selection-parser.sh` when multiple candidates exist
7. `modules/git/ry-git-commit/build-execution-plan.sh`
8. `modules/git/ry-git-commit/execute-plan.sh`

Behavior requirements:
- staged and unstaged candidates are analyzed separately
- if only one candidate exists, the command may commit it directly
- if multiple candidates exist, selection is parsed before execution
- selected candidates are executed in plan order
- unselected changes must be preserved

Supported arguments:
- `--project <project>`
- `--branch <branch>`
```

- [ ] **Step 4: Read the file back to verify the stale note is gone**

Run: `grep -n "dry-run/preview skeleton" .worktrees/ry-git-commit/commands/ry-git-commit.md`
Expected: no output and exit status 1

- [ ] **Step 5: Commit the contract correction**

```bash
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit add commands/ry-git-commit.md
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit commit -m "docs: align ry-git-commit command contract"
```

### Task 2: Replace the README installation placeholder with the real current verification flow

**Files:**
- Modify: `.worktrees/ry-git-commit/README.md:1-25`

- [ ] **Step 1: Write the README acceptance checklist**

```text
Expected README content after edit:
- local development loading path using `claude --plugin-dir`
- reload step using `/reload-plugins`
- recognition check using `/` or `/help`
- one minimal `/ry:git-commit` usage example
- no placeholder or implied public install path unless one actually exists
```

- [ ] **Step 2: Confirm the placeholder text still exists**

Run: `grep -n "Document the GitHub install command here once the repository remote exists" .worktrees/ry-git-commit/README.md`
Expected: one matching line showing the placeholder

- [ ] **Step 3: Replace the README with a real local install and verification guide**

```md
# ryskill

`ryskill` is a standalone Claude plugin repository for Claude Code.

## Commands
- `/ry:git-commit`

## Current scope
- standalone plugin host
- git module
- staged/unstaged transaction-oriented commit splitting

## Local development

Load the plugin directly from the local repository:

```bash
claude --plugin-dir /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit
```

After editing plugin files, reload active plugins inside Claude Code:

```text
/reload-plugins
```

To verify the command is recognized:
- type `/` and look for `/ry:git-commit`
- or run `/help`

## Usage

### Default current repository
`/ry:git-commit`

### Explicit project and branch
`/ry:git-commit --project /path/to/repo --branch feature/demo`

### Multi-candidate flow
The command groups candidates into staged and unstaged sections, shows file lists, and asks which numbered candidates to commit.
```

- [ ] **Step 4: Read the README back and confirm the placeholder is gone**

Run: `grep -n "Document the GitHub install command here once the repository remote exists" .worktrees/ry-git-commit/README.md`
Expected: no output and exit status 1

- [ ] **Step 5: Commit the README update**

```bash
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit add README.md
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit commit -m "docs: add local plugin verification flow"
```

### Task 3: Re-verify the execute-plan test suite before plugin-level checks

**Files:**
- Test: `.worktrees/ry-git-commit/tests/execute-plan.bats`
- Test: `.worktrees/ry-git-commit/tests/execute-plan-integration.bats`

- [ ] **Step 1: Review the real behavior covered by the current integration tests**

```text
Must stay true before plugin verification:
- selected staged candidate commits successfully
- leftover unstaged changes remain unstaged
- selected unstaged candidate commits successfully
- leftover staged changes remain staged in the index
- structured result output still includes result, committed_candidates, restored_unselected_changes, rescue_dir
```

- [ ] **Step 2: Run the focused execute-plan test files**

Run: `bats /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit/tests/execute-plan.bats /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit/tests/execute-plan-integration.bats`
Expected: all tests PASS

- [ ] **Step 3: If a failure appears, update the minimal affected test or implementation only**

```text
Allowed edit scope if red:
- output/phase mismatch -> tests/execute-plan.bats or execute-plan.sh
- staged/unstaged restoration bug -> execute-plan-lib.sh and the matching integration test
- do not broaden into analyzer/presentation refactors
```

- [ ] **Step 4: Re-run the same focused tests until they pass**

Run: `bats /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit/tests/execute-plan.bats /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit/tests/execute-plan-integration.bats`
Expected: all tests PASS

- [ ] **Step 5: Commit only if code or tests changed during re-verification**

```bash
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit add modules/git/ry-git-commit/execute-plan.sh modules/git/ry-git-commit/execute-plan-lib.sh tests/execute-plan.bats tests/execute-plan-integration.bats
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit commit -m "fix(git): keep execute plan verification green"
```

### Task 4: Verify the plugin loads in Claude Code from the local plugin directory

**Files:**
- Modify: `.worktrees/ry-git-commit/plugin.json` only if plugin loading fails because metadata is invalid
- Test: `.worktrees/ry-git-commit/README.md`
- Test: `.worktrees/ry-git-commit/commands/ry-git-commit.md`

- [ ] **Step 1: Start Claude Code with the local plugin directory**

Run: `claude --plugin-dir /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit`
Expected: Claude starts without plugin parse errors

- [ ] **Step 2: Reload plugins inside the Claude session after startup**

Run inside Claude: `/reload-plugins`
Expected: output reports the plugin and its command files were reloaded without errors

- [ ] **Step 3: Verify the command is recognized by the command palette**

```text
Inside Claude:
1. type `/`
2. confirm `/ry:git-commit` appears in the command list
3. if needed, run `/help` and confirm the command is listed there too
```

- [ ] **Step 4: If recognition fails, inspect the minimal plugin surface only**

```text
Check in this order:
1. `plugin.json` command name is `ry-git-commit`
2. `plugin.json` command file path is `commands/ry-git-commit.md`
3. command frontmatter name is `ry-git-commit`
4. run `/reload-plugins` again after fixes
```

- [ ] **Step 5: Commit only if metadata or command surface changed**

```bash
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit add plugin.json commands/ry-git-commit.md README.md
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit commit -m "fix(plugin): make ry-git-commit load cleanly"
```

### Task 5: Run one real `/ry:git-commit` repository scenario manually

**Files:**
- Test: `.worktrees/ry-git-commit/modules/git/ry-git-commit/execute-plan.sh`
- Test: `.worktrees/ry-git-commit/modules/git/ry-git-commit/execute-plan-lib.sh`
- Test: `.worktrees/ry-git-commit/commands/ry-git-commit.md`

- [ ] **Step 1: Create a temporary repository with one staged and one unstaged change**

Run: `tmpdir="$(mktemp -d)" && git init "$tmpdir" && git -C "$tmpdir" config user.name "Test User" && git -C "$tmpdir" config user.email "test@example.com" && printf 'base\n' > "$tmpdir/tracked.txt" && git -C "$tmpdir" add tracked.txt && git -C "$tmpdir" commit -m "Initial commit" && printf 'selected staged\n' > "$tmpdir/selected-staged.txt" && git -C "$tmpdir" add selected-staged.txt && printf 'leftover unstaged\n' > "$tmpdir/leftover-unstaged.txt" && printf '%s\n' "$tmpdir"`
Expected: command prints the temp repo path after creating the fixture repo

- [ ] **Step 2: Invoke `/ry:git-commit` against that repository inside Claude**

```text
/ry:git-commit --project <tmpdir>
```

Expected: Claude presents one or more candidate commits derived from the temporary repo changes

- [ ] **Step 3: Select a candidate and let the command execute**

```text
1
```

Expected: command reports success for the selected candidate and does not discard the unselected change

- [ ] **Step 4: Verify the repository state from the shell**

Run: `git -C <tmpdir> log -1 --pretty=%s && git -C <tmpdir> diff -- leftover-unstaged.txt && git -C <tmpdir> diff --cached`
Expected:
- first line is the new commit subject
- second command shows a diff for `leftover-unstaged.txt`
- cached diff is empty after the staged-candidate scenario

- [ ] **Step 5: If the real flow fails, patch the smallest broken layer and re-run the same scenario**

```text
Fix order:
1. command registration mismatch -> command metadata/docs
2. command orchestration mismatch -> command helper chain
3. execution/state mismatch -> execute-plan.sh or execute-plan-lib.sh
4. after each fix: `/reload-plugins`, rerun `/ry:git-commit --project <tmpdir>`, and repeat the same shell verification
```

### Task 6: Record final acceptance evidence and clean up optional smoke coverage

**Files:**
- Create: `.worktrees/ry-git-commit/tests/plugin-install-smoke.bats` only if the manual verification exposed repeatable shell-only setup worth preserving
- Modify: `.worktrees/ry-git-commit/README.md` only if the successful manual flow reveals missing usage detail

- [ ] **Step 1: Write down the final acceptance checklist in the work log or PR notes**

```text
Acceptance evidence must show:
- plugin loaded via `claude --plugin-dir /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit`
- `/reload-plugins` succeeded
- `/ry:git-commit` appeared in `/` or `/help`
- one real temp repo scenario created a commit successfully
- unselected changes remained in the correct location
```

- [ ] **Step 2: Only if the manual flow was awkward to repeat, add a tiny smoke test scaffold**

```bash
@test "fixture repo can be created for plugin verification" {
  temp_dir="$(mktemp -d)"
  git init "$temp_dir/repo" >/dev/null
  [ -d "$temp_dir/repo/.git" ]
}
```

- [ ] **Step 3: Run the full focused verification set**

Run: `bats /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit/tests/execute-plan.bats /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit/tests/execute-plan-integration.bats`
Expected: all tests PASS

- [ ] **Step 4: Verify the repo status only contains intentional changes**

Run: `git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit status --short`
Expected: only README, command contract, optional smoke test, and any minimal bugfix files are changed

- [ ] **Step 5: Commit the final acceptance work**

```bash
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit add README.md commands/ry-git-commit.md plugin.json tests/plugin-install-smoke.bats
git -C /Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit commit -m "test(plugin): verify local install and ry-git-commit flow"
```

## Self-Review

- Spec coverage check:
  - documentation and contract alignment -> Tasks 1-2
  - real installation / loading verification -> Task 4
  - real `/ry:git-commit` execution verification -> Task 5
  - focused regression protection for execute-plan behavior -> Tasks 3 and 6
- Placeholder scan:
  - no TODO/TBD placeholders remain
  - each runnable step includes exact commands or exact replacement content
- Consistency check:
  - internal file/path references consistently use `ry-git-commit`, while the user-facing slash command is consistently `/ry:git-commit`
  - local verification path is consistently `/Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit`
  - reload command is consistently `/reload-plugins`
