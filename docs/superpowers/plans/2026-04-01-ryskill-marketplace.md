# ryskill Marketplace Repo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a separate `ryskill-marketplace` repository that publishes the installable Claude Code marketplace distribution for `ryskill` while preserving `ryskill` as the development source repository.

**Architecture:** Keep `ryskill` as the source-of-truth repo and create `ryskill-marketplace` as a release-layout repo containing Claude marketplace metadata plus the minimal installable plugin files. The first milestone validates marketplace registration and installation only; command portability follow-up for the bundled `/ry:git-commit` implementation remains explicitly separate.

**Tech Stack:** Git, Claude Code plugin metadata (`plugin.json`, `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`), Markdown docs, shell file copy workflow

---

## File Structure

### `ryskill` repository
- Modify: `README.md`
  - Clarify that this is the source/development repo
  - Point users to `ryskill-marketplace` for installation

### `ryskill-marketplace` repository
- Create: `.claude-plugin/plugin.json`
  - Marketplace-visible plugin metadata
- Create: `.claude-plugin/marketplace.json`
  - Marketplace index for `ryskill`
- Create: `README.md`
  - End-user install instructions
- Create: `plugin.json`
  - Installable plugin manifest copied from source repo
- Create: `commands/ry-git-commit.md`
  - Initial marketplace command file, mirroring the `ry:git-commit` command implementation
- Create: `modules/git/...`
  - Required helper scripts copied from source repo
- Create: `runtime/git-state.sh`
- Create: `runtime/project-context.sh`
- Create: `runtime/selection-parser.sh`

---

### Task 1: Create marketplace repository skeleton

**Files:**
- Create: `../ryskill-marketplace/.claude-plugin/`
- Create: `../ryskill-marketplace/commands/`
- Create: `../ryskill-marketplace/modules/`
- Create: `../ryskill-marketplace/runtime/`

- [ ] **Step 1: Verify sibling directory target**

Run:
```bash
ls -la "/Users/ray/Documents/projects"
```

Expected: output includes `ryskill` and does not yet require `ryskill-marketplace` to exist.

- [ ] **Step 2: Create the repository directory structure**

Run:
```bash
mkdir -p "/Users/ray/Documents/projects/ryskill-marketplace/.claude-plugin" "/Users/ray/Documents/projects/ryskill-marketplace/commands" "/Users/ray/Documents/projects/ryskill-marketplace/modules" "/Users/ray/Documents/projects/ryskill-marketplace/runtime"
```

Expected: directories are created without error.

- [ ] **Step 3: Initialize git repository**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill-marketplace" init
```

Expected: Git reports an initialized repository in `ryskill-marketplace/.git`.

- [ ] **Step 4: Verify created structure**

Run:
```bash
ls -la "/Users/ray/Documents/projects/ryskill-marketplace" && ls -la "/Users/ray/Documents/projects/ryskill-marketplace/.claude-plugin"
```

Expected: root contains `.claude-plugin`, `commands`, `modules`, `runtime`, and `.git`.

- [ ] **Step 5: Continue to Task 2 before the first commit**

Expected: no commit is attempted yet because Git does not track empty directories; the first deterministic commit happens after metadata files are created in Task 2.

---

### Task 2: Add Claude marketplace metadata

**Files:**
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/.claude-plugin/plugin.json`
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/.claude-plugin/marketplace.json`

- [ ] **Step 1: Write marketplace plugin metadata**

Create `/Users/ray/Documents/projects/ryskill-marketplace/.claude-plugin/plugin.json` with:
```json
{
  "name": "ryskill",
  "description": "Modular Claude plugin with git utilities, starting with /ry:git-commit.",
  "version": "0.2.0",
  "author": {
    "name": "Ray"
  },
  "homepage": "https://github.com/mithyer/ryskill-marketplace",
  "repository": "https://github.com/mithyer/ryskill-marketplace",
  "license": "MIT",
  "keywords": [
    "claude-code",
    "plugin",
    "git",
    "workflow"
  ]
}
```

- [ ] **Step 2: Write marketplace index metadata**

Create `/Users/ray/Documents/projects/ryskill-marketplace/.claude-plugin/marketplace.json` with:
```json
{
  "name": "ryskill-marketplace",
  "description": "Marketplace for the ryskill Claude Code plugin",
  "owner": {
    "name": "Ray"
  },
  "plugins": [
    {
      "name": "ryskill",
      "description": "Modular Claude plugin with git utilities, starting with /ry:git-commit.",
      "version": "0.2.0",
      "source": "./",
      "author": {
        "name": "Ray"
      }
    }
  ]
}
```

- [ ] **Step 3: Validate metadata files**

Run:
```bash
python3 -m json.tool "/Users/ray/Documents/projects/ryskill-marketplace/.claude-plugin/plugin.json" >/dev/null && python3 -m json.tool "/Users/ray/Documents/projects/ryskill-marketplace/.claude-plugin/marketplace.json" >/dev/null
```

Expected: no output, exit status 0.

- [ ] **Step 4: Review file contents**

Run:
```bash
ls -la "/Users/ray/Documents/projects/ryskill-marketplace/.claude-plugin"
```

Expected: both `plugin.json` and `marketplace.json` are present.

- [ ] **Step 5: Commit metadata**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill-marketplace" add ".claude-plugin/plugin.json" ".claude-plugin/marketplace.json" && git -C "/Users/ray/Documents/projects/ryskill-marketplace" commit -m "feat: add marketplace metadata"
```

Expected: commit succeeds.

---

### Task 3: Copy installable plugin files from source repo

**Files:**
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/plugin.json`
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/commands/ry-git-commit.md`
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/modules/git/...`
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/runtime/git-state.sh`
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/runtime/project-context.sh`
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/runtime/selection-parser.sh`

- [ ] **Step 1: Copy the root plugin manifest**

Run:
```bash
cp "/Users/ray/Documents/projects/ryskill/plugin.json" "/Users/ray/Documents/projects/ryskill-marketplace/plugin.json"
```

Expected: destination file exists.

- [ ] **Step 2: Copy the command definition**

Run:
```bash
cp "/Users/ray/Documents/projects/ryskill/commands/ry-git-commit.md" "/Users/ray/Documents/projects/ryskill-marketplace/commands/ry-git-commit.md"
```

Expected: destination file exists.

- [ ] **Step 3: Copy module helpers**

Run:
```bash
cp -R "/Users/ray/Documents/projects/ryskill/modules/git" "/Users/ray/Documents/projects/ryskill-marketplace/modules/"
```

Expected: `modules/git` exists in marketplace repo.

- [ ] **Step 4: Copy runtime helpers**

Run:
```bash
cp "/Users/ray/Documents/projects/ryskill/runtime/git-state.sh" "/Users/ray/Documents/projects/ryskill-marketplace/runtime/" && cp "/Users/ray/Documents/projects/ryskill/runtime/project-context.sh" "/Users/ray/Documents/projects/ryskill-marketplace/runtime/" && cp "/Users/ray/Documents/projects/ryskill/runtime/selection-parser.sh" "/Users/ray/Documents/projects/ryskill-marketplace/runtime/"
```

Expected: all three runtime files exist in destination.

- [ ] **Step 5: Verify copied layout**

Run:
```bash
ls -la "/Users/ray/Documents/projects/ryskill-marketplace" && ls -la "/Users/ray/Documents/projects/ryskill-marketplace/commands" && ls -la "/Users/ray/Documents/projects/ryskill-marketplace/modules" && ls -la "/Users/ray/Documents/projects/ryskill-marketplace/runtime"
```

Expected: `plugin.json`, command file, module directory, and runtime scripts are present.

- [ ] **Step 6: Commit copied plugin files**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill-marketplace" add "plugin.json" "commands/ry-git-commit.md" "modules" "runtime" && git -C "/Users/ray/Documents/projects/ryskill-marketplace" commit -m "feat: add installable ryskill plugin files"
```

Expected: commit succeeds.

---

### Task 4: Add first-release install documentation

**Files:**
- Create: `/Users/ray/Documents/projects/ryskill-marketplace/README.md`
- Modify: `/Users/ray/Documents/projects/ryskill/README.md:23-25`

- [ ] **Step 1: Write marketplace README**

Create `/Users/ray/Documents/projects/ryskill-marketplace/README.md` with:
```md
# ryskill Marketplace

Marketplace repository for installing `ryskill` in Claude Code.

## Installation

### Claude Code (via Plugin Marketplace)

Register the marketplace first:

```bash
/plugin marketplace add mithyer/ryskill-marketplace
```

Then install the plugin:

```bash
/plugin install ryskill@ryskill-marketplace
```

## Included commands

- `/ry:git-commit`

## Status

This is the marketplace distribution repository for `ryskill`.

The initial marketplace release is focused on validating installation through Claude Code's Plugin Marketplace flow. The command layout mirrors the canonical source repository command, while keeping runtime portability work explicitly tracked separately.

## Source repository

Development happens in the main `ryskill` source repository.
```

- [ ] **Step 2: Update source-repo README installation section**

Replace the existing `README.md` installation section in `/Users/ray/Documents/projects/ryskill/README.md` with:
```md
## Installation

### Direct source repository

This repository contains the canonical plugin manifest and implementation.
The command resolves its plugin root from the installed command file at runtime via `runtime/plugin-root.sh`, so the same command definition works from the source repo, a worktree, or a marketplace install.

### Claude Code marketplace discovery

For marketplace-based installation, use the marketplace index repository:

```bash
/plugin marketplace add mithyer/ryskill-marketplace
/plugin install ryskill@ryskill-marketplace
```
```

- [ ] **Step 3: Verify README contents**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
for p in [
    Path("/Users/ray/Documents/projects/ryskill-marketplace/README.md"),
    Path("/Users/ray/Documents/projects/ryskill/README.md"),
]:
    print(f"--- {p}")
    print(p.read_text())
PY
```

Expected: both READMEs show the intended installation guidance.

- [ ] **Step 4: Commit documentation**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill-marketplace" add "README.md" && git -C "/Users/ray/Documents/projects/ryskill-marketplace" commit -m "docs: add marketplace installation guide"
```

Expected: marketplace README commit succeeds.

- [ ] **Step 5: Commit source-repo README update**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill" add "README.md" && git -C "/Users/ray/Documents/projects/ryskill" commit -m "docs: point installation to marketplace repo"
```

Expected: source repo README commit succeeds.

---

### Task 5: Mark first marketplace release as experimental

**Files:**
- Modify: `/Users/ray/Documents/projects/ryskill-marketplace/commands/ry-git-commit.md`

- [ ] **Step 1: Add experimental notice to command doc**

Insert immediately after the frontmatter in `/Users/ray/Documents/projects/ryskill-marketplace/commands/ry-git-commit.md`:
```md
> Experimental notice: this initial marketplace release validates installation packaging. The bundled file continues to expose the canonical `/ry:git-commit` command implementation while runtime portability follow-up remains tracked separately.
```

- [ ] **Step 2: Verify the notice is present**

Run:
```bash
python3 - <<'PY'
from pathlib import Path
p = Path("/Users/ray/Documents/projects/ryskill-marketplace/commands/ry-git-commit.md")
print(p.read_text())
PY
```

Expected: the notice appears directly below the frontmatter block.

- [ ] **Step 3: Commit the experimental notice**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill-marketplace" add "commands/ry-git-commit.md" && git -C "/Users/ray/Documents/projects/ryskill-marketplace" commit -m "docs: mark initial command release as experimental"
```

Expected: commit succeeds.

---

### Task 6: Publish and verify marketplace installation

**Files:**
- Modify: remote GitHub repositories for `ryskill-marketplace`
- Test: local Claude Code marketplace install flow

- [ ] **Step 1: Create the GitHub repository**

Create a remote repository named `ryskill-marketplace` under the GitHub account that will own the published marketplace index (currently expected to be `mithyer`, unless you intentionally change the ownership metadata earlier in this plan).

Expected: a new empty remote exists.

- [ ] **Step 2: Add the git remote**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill-marketplace" remote add origin git@github.com:mithyer/ryskill-marketplace.git
```

Expected: `origin` remote is configured.

- [ ] **Step 3: Push the marketplace repository**

Run:
```bash
git -C "/Users/ray/Documents/projects/ryskill-marketplace" push -u origin main
```

Expected: branch is pushed successfully.

- [ ] **Step 4: Add the marketplace in Claude Code**

Run in Claude Code:
```bash
/plugin marketplace add mithyer/ryskill-marketplace
```

Expected: Claude Code registers the marketplace without error.

- [ ] **Step 5: Install the plugin from the marketplace**

Run in Claude Code:
```bash
/plugin install ryskill@ryskill-marketplace
```

Expected: Claude Code installs `ryskill`.

- [ ] **Step 6: Verify plugin visibility**

Check that Claude Code recognizes `/ry:git-commit`.

Expected: command appears in the available plugin commands list.

- [ ] **Step 7: Record first-release execution status**

Document whether the installed command runs successfully or whether follow-up portability work remains after installation.

Expected: clear evidence for the next follow-up task.

---

## Self-review

- **Spec coverage:** This plan covers the agreed scope: separate `ryskill-marketplace` repo, preserved `ryskill` source repo, marketplace metadata, installation docs, and first-pass installation validation. It explicitly does not claim to solve runtime portability yet.
- **Placeholder scan:** No TBD/TODO placeholders remain; all files, commands, and commit intents are concrete.
- **Type consistency:** Metadata names are consistent across `plugin.json`, `.claude-plugin/plugin.json`, and `.claude-plugin/marketplace.json` as `ryskill` and `ryskill-marketplace`.
