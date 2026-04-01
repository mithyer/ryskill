# ryskill

`ryskill` is a standalone Claude plugin repository installed from GitHub via `plugin install`.

## Commands
- `/ry-git-commit`

## Current scope
- standalone plugin host
- git module
- staged/unstaged transaction-oriented commit splitting

## Usage

### Default current repository
`/ry-git-commit`

### Explicit project and branch
`/ry-git-commit --project /path/to/repo --branch feature/demo`

### Multi-candidate flow
The command groups candidates into staged and unstaged sections, shows file lists, and asks which numbered candidates to commit.

## Installation
This repository is the development source for `ryskill`.

For Claude Code marketplace installation, use the marketplace repository:

```bash
/plugin marketplace add ray/ryskill-marketplace
/plugin install ryskill@ryskill-marketplace
```
