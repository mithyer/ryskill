# Historical Plan Doc Consistency Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Normalize historical `docs/superpowers/plans/*.md` files so command naming and marketplace ownership guidance match the current repository contract without rewriting historical implementation details that are still accurate.

**Architecture:** Treat this as a targeted documentation cleanup. Update only instructionally misleading references such as obsolete slash-command names and stale marketplace owner/install examples, while preserving accurate historical file paths like `commands/ry-git-commit.md` and task structure that still reflect how the repo is organized.

**Tech Stack:** Markdown, git, grep-based verification, existing repo docs (`README.md`, `plugin.json`)

---

## File Structure

### Existing reference files
- Read: `/Users/ray/Documents/projects/ryskill/README.md`
  - Canonical current installation wording and marketplace owner
- Read: `/Users/ray/Documents/projects/ryskill/plugin.json`
  - Canonical current slash-command name and mapped command file path

### Historical plan files to review/update
- Modify: `/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-03-30-ryskill-git-module.md`
  - Update only misleading descriptive references to the old slash-command name where readers would interpret them as current command usage
  - Preserve true file-path/module-path references like `commands/ry-git-commit.md` and `modules/git/ry-git-commit/...`
- Modify: `/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-01-ryskill-install-usage-verification.md`
  - Update outdated slash-command usage examples and command-recognition checks
  - Preserve valid historical worktree file paths and script paths
- Modify: `/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-01-ryskill-marketplace.md`
  - Already partially cleaned; finish/verify marketplace owner and command wording consistency
- Modify: `/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-02-portable-ryskill-marketplace-command.md`
  - Already partially cleaned; finish/verify command wording consistency while preserving file paths

---

### Task 1: Establish the current terminology contract

**Files:**
- Read: `/Users/ray/Documents/projects/ryskill/README.md`
- Read: `/Users/ray/Documents/projects/ryskill/plugin.json`

- [ ] **Step 1: Read the current README installation and usage wording**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
p = Path('/Users/ray/Documents/projects/ryskill/README.md')
print(p.read_text())
PY
```

Expected: output shows current marketplace owner `mithyer/ryskill-marketplace` and current slash-command usage `/ry:git-commit`.

- [ ] **Step 2: Read the current plugin manifest**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
p = Path('/Users/ray/Documents/projects/ryskill/plugin.json')
print(p.read_text())
PY
```

Expected: output shows command name `ry:git-commit` mapped to file `commands/ry-git-commit.md`.

- [ ] **Step 3: Record the normalization rule before editing plans**

Use this rule for every later edit:
```text
Normalize user-facing command references to /ry:git-commit.
Preserve real repository file/module paths that still use ry-git-commit in filenames.
Normalize marketplace ownership/install examples to mithyer/ryskill-marketplace where the text is instructional.
```

Expected: the cleanup scope is explicit before touching historical plan docs.

---

### Task 2: Clean up the oldest historical plan doc safely

**Files:**
- Modify: `/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-03-30-ryskill-git-module.md`

- [ ] **Step 1: Inspect all old-command references in the oldest plan**

Run:
```bash
grep -n '/ry-git-commit\|ry-git-commit' '/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-03-30-ryskill-git-module.md'
```

Expected: output distinguishes user-facing slash-command references from file/module path references.

- [ ] **Step 2: Replace only user-facing slash-command references**

Apply this exact replacement everywhere it appears as a slash command in prose or examples:
```text
/ry-git-commit
```
becomes:
```text
/ry:git-commit
```

Do **not** change any of these path forms if they appear:
```text
commands/ry-git-commit.md
modules/git/ry-git-commit/
tests/ry-git-commit-*.bats
```

Expected: command usage text is current, while file paths remain historically accurate.

- [ ] **Step 3: Verify no misleading old slash-command usages remain**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
p = Path('/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-03-30-ryskill-git-module.md')
for line in p.read_text().splitlines():
    if '/ry-git-commit' in line:
        print(line)
PY
```

Expected: either no output, or only intentionally preserved cases that are part of historical quoted commands you explicitly chose to retain for accuracy. If any remaining line is a user-facing current usage instruction, edit it.

- [ ] **Step 4: Commit the oldest-plan cleanup**

Run:
```bash
git -C '/Users/ray/Documents/projects/ryskill' add 'docs/superpowers/plans/2026-03-30-ryskill-git-module.md' && git -C '/Users/ray/Documents/projects/ryskill' commit -m 'docs: normalize historical git module plan terminology'
```

Expected: commit succeeds.

---

### Task 3: Clean up the install verification historical plan

**Files:**
- Modify: `/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-01-ryskill-install-usage-verification.md`

- [ ] **Step 1: Inspect user-facing old command references in the install-verification plan**

Run:
```bash
grep -n '/ry-git-commit' '/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-01-ryskill-install-usage-verification.md'
```

Expected: output shows the lines that still present the old slash-command name to readers.

- [ ] **Step 2: Replace user-facing slash-command references with the current command name**

Apply this exact replacement for prose and user-entered command examples:
```text
/ry-git-commit
```
becomes:
```text
/ry:git-commit
```

Preserve path references like:
```text
.worktrees/ry-git-commit/...
commands/ry-git-commit.md
modules/git/ry-git-commit/...
```

Expected: the plan still points at the same files, but user-facing command guidance matches the current plugin contract.

- [ ] **Step 3: Verify the remaining occurrences are path/history references only**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
p = Path('/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-01-ryskill-install-usage-verification.md')
for i, line in enumerate(p.read_text().splitlines(), start=1):
    if '/ry-git-commit' in line:
        print(f'{i}: {line}')
PY
```

Expected: any remaining matches are intentional historical/path-context references, not current command instructions.

- [ ] **Step 4: Commit the install-verification cleanup**

Run:
```bash
git -C '/Users/ray/Documents/projects/ryskill' add 'docs/superpowers/plans/2026-04-01-ryskill-install-usage-verification.md' && git -C '/Users/ray/Documents/projects/ryskill' commit -m 'docs: normalize install verification plan terminology'
```

Expected: commit succeeds.

---

### Task 4: Finish and verify the two newer marketplace-related plans

**Files:**
- Modify: `/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-01-ryskill-marketplace.md`
- Modify: `/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-02-portable-ryskill-marketplace-command.md`

- [ ] **Step 1: Search both newer plans for stale command-owner wording**

Run:
```bash
grep -n 'ray/ryskill-marketplace\|/ry-git-commit' '/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-01-ryskill-marketplace.md' '/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-02-portable-ryskill-marketplace-command.md'
```

Expected: output shows only the remaining lines that still need judgment.

- [ ] **Step 2: Update only the misleading instructional wording**

Use these exact replacements where the text is instructional or descriptive:
```text
ray/ryskill-marketplace
```
becomes:
```text
mithyer/ryskill-marketplace
```

```text
/ry-git-commit
```
becomes:
```text
/ry:git-commit
```

Do **not** rename command file paths such as:
```text
commands/ry-git-commit.md
```

Expected: the plans remain historically specific about files, but current in user-facing instructions.

- [ ] **Step 3: Verify the remaining matches are intentional path references only**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
paths = [
    Path('/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-01-ryskill-marketplace.md'),
    Path('/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/2026-04-02-portable-ryskill-marketplace-command.md'),
]
for p in paths:
    print(f'--- {p.name} ---')
    for i, line in enumerate(p.read_text().splitlines(), start=1):
        if 'ray/ryskill-marketplace' in line or '/ry-git-commit' in line:
            print(f'{i}: {line}')
PY
```

Expected: no stale owner references remain, and any `/ry-git-commit` lines that remain are intentionally preserved historical/path-related content only.

- [ ] **Step 4: Commit the marketplace-plan cleanup**

Run:
```bash
git -C '/Users/ray/Documents/projects/ryskill' add 'docs/superpowers/plans/2026-04-01-ryskill-marketplace.md' 'docs/superpowers/plans/2026-04-02-portable-ryskill-marketplace-command.md' && git -C '/Users/ray/Documents/projects/ryskill' commit -m 'docs: normalize marketplace plan terminology'
```

Expected: commit succeeds.

---

### Task 5: Run a final repo-wide verification sweep for plan-doc consistency

**Files:**
- Test: `/Users/ray/Documents/projects/ryskill/docs/superpowers/plans/*.md`

- [ ] **Step 1: Search all plan docs for the old command string**

Run:
```bash
grep -R -n '/ry-git-commit' '/Users/ray/Documents/projects/ryskill/docs/superpowers/plans'
```

Expected: results, if any, are clearly intentional historical/path-context exceptions you can explain.

- [ ] **Step 2: Search all plan docs for the stale marketplace owner**

Run:
```bash
grep -R -n 'ray/ryskill-marketplace' '/Users/ray/Documents/projects/ryskill/docs/superpowers/plans'
```

Expected: no output.

- [ ] **Step 3: Check git status for only the expected plan-doc changes**

Run:
```bash
git -C '/Users/ray/Documents/projects/ryskill' status --short
```

Expected: only the intended historical plan docs are modified or already committed cleanly.

- [ ] **Step 4: Commit the final verification pass if any final edits were needed**

Run:
```bash
git -C '/Users/ray/Documents/projects/ryskill' status --short
```

Expected: either clean working tree, or a small final diff that you commit with a docs-focused message before finishing.

---

## Self-review

- **Spec coverage:** This plan covers the approved scope: targeted cleanup of misleading historical plan-doc terminology, preservation of accurate file/module paths, normalization of marketplace owner/install references, and final repo-wide verification.
- **Placeholder scan:** No TBD/TODO placeholders remain; every task includes exact files, commands, and verification steps.
- **Type consistency:** The plan consistently distinguishes the slash command `/ry:git-commit` from the still-valid file path `commands/ry-git-commit.md` and related module/test paths.
