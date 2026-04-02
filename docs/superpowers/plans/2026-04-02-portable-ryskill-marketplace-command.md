# Portable ryskill Marketplace Command Execution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/ry:git-commit` work after marketplace installation on another machine by removing the hardcoded local plugin root path and replacing it with portable runtime plugin-root resolution.

**Architecture:** Keep `ryskill` as the canonical source repo and `ryskill-marketplace` as the installable distribution mirror. Introduce a small runtime helper that resolves the plugin root from the installed command layout, then have `commands/ry-git-commit.md` call that helper before invoking the existing `runtime/` and `modules/` scripts. Preserve the current modular command pipeline and only change root discovery plus validation messaging.

**Tech Stack:** Bash, Claude Code plugin command markdown, existing shell runtime helpers, git, marketplace-installed Claude plugin layout

---

## File Structure

### `ryskill` repository
- Modify: `/Users/ray/Documents/projects/ryskill/commands/ry-git-commit.md`
  - Replace the hardcoded local verification contract with portable plugin-root resolution logic
  - Keep the existing helper invocation order unchanged after root resolution
- Create: `/Users/ray/Documents/projects/ryskill/runtime/plugin-root.sh`
  - Resolve the plugin root directory portably from the current command/runtime layout
  - Emit machine-readable `plugin_root=...` output and meaningful failure diagnostics
- Modify: `/Users/ray/Documents/projects/ryskill/README.md`
  - Note that marketplace-installed command execution is intended to be portable
  - Keep source-vs-marketplace repo responsibilities clear

### `ryskill-marketplace` repository
- Modify: `/Users/ray/Documents/projects/ryskill-marketplace/commands/ry-git-commit.md`
  - Mirror the command change from the source repo
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/runtime/plugin-root.sh`
  - Mirror the runtime helper from the source repo
- Modify: `/Users/ray/Documents/projects/ryskill-marketplace/README.md`
  - Describe the portable marketplace execution goal/status accurately

---

### Task 1: Add portable plugin-root runtime helper

**Files:**
- Create: `/Users/ray/Documents/projects/ryskill/runtime/plugin-root.sh`

- [ ] **Step 1: Implement portable root resolution directly**

Create `/Users/ray/Documents/projects/ryskill/runtime/plugin-root.sh` with:
```bash
#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_root="$(cd "$script_dir/.." && pwd)"

if [[ ! -f "$plugin_root/plugin.json" ]]; then
  echo "error=plugin_manifest_not_found" >&2
  echo "plugin_root_candidate=$plugin_root" >&2
  exit 1
fi

if [[ ! -d "$plugin_root/runtime" ]]; then
  echo "error=runtime_directory_not_found" >&2
  echo "plugin_root_candidate=$plugin_root" >&2
  exit 1
fi

if [[ ! -d "$plugin_root/modules" ]]; then
  echo "error=modules_directory_not_found" >&2
  echo "plugin_root_candidate=$plugin_root" >&2
  exit 1
fi

if [[ ! -d "$plugin_root/commands" ]]; then
  echo "error=commands_directory_not_found" >&2
  echo "plugin_root_candidate=$plugin_root" >&2
  exit 1
fi

printf 'plugin_root=%s\n' "$plugin_root"
```

- [ ] **Step 2: Run the helper to verify it resolves the source repo root**

Run:
```bash
bash "/Users/ray/Documents/projects/ryskill/runtime/plugin-root.sh"
```

Expected: stdout contains:
```text
plugin_root=/Users/ray/Documents/projects/ryskill
```

- [ ] **Step 3: Commit the helper**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill" add "runtime/plugin-root.sh" && git -C "/Users/ray/Documents/projects/ryskill" commit -m "feat: add portable plugin root resolver"
```

Expected: commit succeeds.

---

### Task 2: Update the command definition to use the helper

**Files:**
- Modify: `/Users/ray/Documents/projects/ryskill/commands/ry-git-commit.md:5-23`

- [ ] **Step 3: Replace the hardcoded root block with the final helper invocation**

Replace lines 5-23 with this final command snippet:
```md
Resolve the plugin root at runtime before invoking helpers:

```bash
plugin_root_line="$(bash "$(dirname "$CLAUDE_COMMAND_FILE")/../runtime/plugin-root.sh" 2>/dev/null || true)"
plugin_root="${plugin_root_line#plugin_root=}"
if [[ -z "$plugin_root" || "$plugin_root" == "$plugin_root_line" ]]; then
  printf 'ry-git-commit: unable to resolve plugin root from CLAUDE_COMMAND_FILE\n' >&2
  exit 1
fi
```
```

- [ ] **Step 4: Verify the command file now references `runtime/plugin-root.sh` and no hardcoded user path**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
p = Path("/Users/ray/Documents/projects/ryskill/commands/ry-git-commit.md")
text = p.read_text()
assert "/Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit" not in text
assert "runtime/plugin-root.sh" in text
assert 'CLAUDE_COMMAND_FILE' in text
print("portable command block present")
PY
```

Expected: prints `portable command block present`.

- [ ] **Step 5: Commit the command change**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill" add "commands/ry-git-commit.md" && git -C "/Users/ray/Documents/projects/ryskill" commit -m "refactor: resolve plugin root at runtime"
```

Expected: commit succeeds.

---

### Task 3: Mirror the portability changes into the marketplace distribution

**Files:**
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/runtime/plugin-root.sh`
- Modify: `/Users/ray/Documents/projects/ryskill-marketplace/commands/ry-git-commit.md`

- [ ] **Step 1: Copy the new runtime helper into the marketplace repo**

Run:
```bash
cp "/Users/ray/Documents/projects/ryskill/runtime/plugin-root.sh" "/Users/ray/Documents/projects/ryskill-marketplace/runtime/plugin-root.sh"
```

Expected: destination file exists.

- [ ] **Step 2: Copy the updated command definition into the marketplace repo**

Run:
```bash
cp "/Users/ray/Documents/projects/ryskill/commands/ry-git-commit.md" "/Users/ray/Documents/projects/ryskill-marketplace/commands/ry-git-commit.md"
```

Expected: destination file exists.

- [ ] **Step 3: Verify the marketplace mirror matches the source repo for the changed files**

Run:
```bash
diff -u "/Users/ray/Documents/projects/ryskill/runtime/plugin-root.sh" "/Users/ray/Documents/projects/ryskill-marketplace/runtime/plugin-root.sh" && diff -u "/Users/ray/Documents/projects/ryskill/commands/ry-git-commit.md" "/Users/ray/Documents/projects/ryskill-marketplace/commands/ry-git-commit.md"
```

Expected: no output, exit status 0.

- [ ] **Step 4: Commit the mirrored marketplace files**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill-marketplace" add "runtime/plugin-root.sh" "commands/ry-git-commit.md" && git -C "/Users/ray/Documents/projects/ryskill-marketplace" commit -m "fix: mirror portable plugin root resolution"
```

Expected: commit succeeds.

---

### Task 4: Update docs to describe portable execution intent

**Files:**
- Modify: `/Users/ray/Documents/projects/ryskill/README.md`
- Modify: `/Users/ray/Documents/projects/ryskill-marketplace/README.md`

- [ ] **Step 1: Update the source repo README status language**

Replace the installation section tail in `/Users/ray/Documents/projects/ryskill/README.md` with:
```md
### Claude Code marketplace discovery

For marketplace-based installation, use the marketplace index repository:

```bash
claude plugins marketplace add mithyer/ryskill-marketplace
claude plugins install ryskill@ryskill-marketplace
```

The intent is that the installed plugin command layout works portably after installation rather than depending on a local development worktree path.
```

- [ ] **Step 2: Update the marketplace README status language**

Append this paragraph to `/Users/ray/Documents/projects/ryskill-marketplace/README.md`:
```md
The marketplace distribution is intended to run from the installed plugin layout directly, without depending on a machine-specific development path.
```

- [ ] **Step 3: Verify both READMEs mention portable installed execution**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
for p in [
    Path("/Users/ray/Documents/projects/ryskill/README.md"),
    Path("/Users/ray/Documents/projects/ryskill-marketplace/README.md"),
]:
    text = p.read_text()
    assert "installed plugin" in text or "installed plugin layout" in text
    print(f"portable wording present: {p}")
PY
```

Expected: both files print `portable wording present: ...`.

- [ ] **Step 4: Commit the documentation updates**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill" add "README.md" && git -C "/Users/ray/Documents/projects/ryskill" commit -m "docs: describe portable installed execution"

git -C "/Users/ray/Documents/projects/ryskill-marketplace" add "README.md" && git -C "/Users/ray/Documents/projects/ryskill-marketplace" commit -m "docs: describe portable marketplace execution"
```

Expected: both commits succeed.

---

### Task 5: Validate marketplace-installed command root resolution

**Files:**
- Test: `/Users/ray/Documents/projects/ryskill-marketplace/runtime/plugin-root.sh`
- Test: installed `ryskill` plugin via Claude Code marketplace

- [ ] **Step 1: Push both repos after the portability commits**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill" push

git -C "/Users/ray/Documents/projects/ryskill-marketplace" push
```

Expected: both pushes succeed.

- [ ] **Step 2: Refresh the marketplace in Claude Code**

Run:
```bash
claude plugins marketplace update ryskill-marketplace || claude plugins marketplace add mithyer/ryskill-marketplace
```

Expected: the marketplace metadata refreshes successfully.

- [ ] **Step 3: Reinstall or update the plugin**

Run:
```bash
claude plugins update ryskill || claude plugins install ryskill@ryskill-marketplace
```

Expected: plugin update/install succeeds.

- [ ] **Step 4: Verify the installed plugin contains the new helper**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
base = Path.home() / ".claude" / "plugins"
matches = list(base.rglob("runtime/plugin-root.sh"))
for m in matches:
    if "ryskill" in str(m):
        print(m)
PY
```

Expected: prints at least one installed `runtime/plugin-root.sh` path for `ryskill`.

- [ ] **Step 5: Inspect the installed command file for the portable block**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
base = Path.home() / ".claude" / "plugins"
for p in base.rglob("commands/ry-git-commit.md"):
    if "ryskill" in str(p):
        text = p.read_text()
        print(p)
        print("runtime/plugin-root.sh" in text)
        print("/Users/ray/Documents/projects/ryskill/.worktrees/ry-git-commit" in text)
PY
```

Expected: for the installed command file, `True` is printed for `runtime/plugin-root.sh` and `False` for the hardcoded local path.

- [ ] **Step 6: Invoke the installed command in a disposable git repo**

Run:
```bash
tmpdir="$(mktemp -d)" && git -C "$tmpdir" init >/dev/null && cd "$tmpdir" && printf 'hello\n' > demo.txt && git add demo.txt && claude -p "/ry-git-commit" || true
```

Expected: the command progresses past plugin-root discovery. It may still stop later for unrelated interactive or workflow reasons, but it must not fail with a missing hardcoded plugin root path.

- [ ] **Step 7: Commit any final validation-driven adjustments if needed**

If no further code changes were needed, note that no commit is required. If a fix was needed, create a focused follow-up commit in the affected repo.

- [ ] **Step 8: Record completion status**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill" status --short && printf '%s\n' '---' && git -C "/Users/ray/Documents/projects/ryskill-marketplace" status --short
```

Expected: both repos are clean, or only contain intentional untracked planning artifacts outside the implementation scope.

---

## Self-review

- **Spec coverage:** This plan covers the portable execution goal end-to-end: introduce portable root resolution, update the command to use it, mirror the change into the marketplace distribution, update docs, and validate the installed plugin no longer depends on a hardcoded development path.
- **Placeholder scan:** No TBD/TODO placeholders remain; every task names exact files, code snippets, commands, and expected outcomes.
- **Type consistency:** The plan consistently uses `plugin_root.sh`, `plugin_root`, `runtime/plugin-root.sh`, and the `plugin_root=...` output contract across source repo, marketplace repo, docs, and validation steps.
