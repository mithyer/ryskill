# ryskill

`ryskill` is the canonical Claude plugin source repository.

## Commands
- `/ry:git-commit`

## Current scope
- standalone plugin host
- git module
- staged/unstaged transaction-oriented commit splitting

## Usage

### Default current repository
`/ry:git-commit`

### Explicit project and branch
`/ry:git-commit --project /path/to/repo --branch feature/demo`

### Multi-candidate flow
The command groups candidates into staged and unstaged sections, shows file lists, and asks which numbered candidates to commit.

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
