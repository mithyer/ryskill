---
name: ry-git-commit
description: Use when the user wants to analyze staged/unstaged changes and create selected commits safely.
metadata:
  short-description: Structured git commit workflow
---

# RY Git Commit

## Overview

This skill provides a safe commit workflow based on the scripts in this repository:
- `modules/git/ry-git-commit/analyze-staged.sh`
- `modules/git/ry-git-commit/analyze-unstaged.sh`
- `modules/git/ry-git-commit/present-candidates.sh`
- `modules/git/ry-git-commit/build-execution-plan.sh`
- `modules/git/ry-git-commit/execute-plan.sh`

## Prerequisites

- Run this skill from the `ryskill` source repository.
- `bash`, `git`, and `python3` are available.
- The target project is a valid git repository.

## Required Workflow

### Step 1: Resolve project context

Run:

```bash
bash runtime/project-context.sh --cwd "$PWD"
```

If the user passed `--project` or `--branch`, pass those through exactly.

### Step 2: Inspect git state

Run:

```bash
bash runtime/git-state.sh "$project_path"
```

If both staged and unstaged changes are empty, stop and report that there is nothing to commit.

### Step 3: Build candidates

Run analyzers and merge output in index order:

```bash
staged_rows="$(bash modules/git/ry-git-commit/analyze-staged.sh "$project_path")"
next_index="$(printf '%s\n' "$staged_rows" | awk -F'|' 'NF>=2{last=$2} END{if(last=="") print 1; else print last+1}')"
unstaged_rows="$(bash modules/git/ry-git-commit/analyze-unstaged.sh "$project_path" "$next_index")"
candidate_rows="$(printf '%s\n%s\n' "$staged_rows" "$unstaged_rows" | sed '/^$/d')"
```

### Step 4: Present summary and candidates

Always present staged and unstaged summaries before asking for a selection:

```bash
printf '%s\n' "$candidate_rows" | bash modules/git/ry-git-commit/present-candidates.sh
```

Prompt exactly:

`Select commit numbers, or 0 to over`

### Step 5: Parse selection and execute

- Parse user input with `bash runtime/selection-parser.sh`.
- Build the plan using `bash modules/git/ry-git-commit/build-execution-plan.sh`.
- Execute selected rows in order with `bash modules/git/ry-git-commit/execute-plan.sh`.
- Use selected candidate messages verbatim as commit messages.

### Step 6: Report outcome

- Report created commit subjects in order.
- Report any preserved unselected changes.
- If any step fails, include the command and stderr details in the response.
