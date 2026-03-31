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

If only one candidate exists, skip selection and commit directly.
Always preserve unselected changes.
Current implementation note: `execute-plan.sh` is still a dry-run/preview skeleton and must fail explicitly instead of pretending to perform a real commit.

Supported arguments:
- `--project <project>`
- `--branch <branch>`
