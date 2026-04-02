# ryskill Design Spec

Date: 2026-03-30
Topic: ryskill plugin with initial git module and /ry:git-commit command

## 1. Overview

`ryskill` is a standalone Claude plugin repository installed from GitHub via `plugin install`. It is not embedded inside any existing project repository. The plugin is designed as a lightweight host with module-based expansion. The first module is `git`, and the first command is `/ry:git-commit`.

The goal of `/ry:git-commit` is to analyze the current working tree, split changes into transaction-oriented commit candidates, and let the user commit selected candidates while preserving all unselected changes in the working tree.

## 2. Product Boundaries

### In scope for phase 1
- Standalone repository `ryskill`
- Installable Claude plugin structure
- Modular host shape for future expansion
- `git` module
- `/ry:git-commit` command
- Candidate generation for staged and unstaged changes
- User selection flow for multiple commit candidates
- Safe execution preserving unselected changes

### Out of scope for phase 1
- Push to remote
- Amend existing commits
- Squash / history rewriting
- Cross-repository batch commits
- Multi-branch commit orchestration
- Additional modules beyond `git`

## 3. Architecture

`ryskill` uses a lightweight host + module registration structure.

### Host responsibilities
- Plugin metadata and install entry
- Shared runtime utilities
- Common interaction framework
- Project / branch resolution
- Commit language inference from recent history
- Candidate numbering and selection parsing

### Module responsibilities
Each module owns its domain logic and plugs into the host through a stable registration surface.

### Command responsibilities
The `/ry:git-commit` command owns:
- parameter parsing
- change analysis
- candidate generation
- candidate presentation
- user selection handling
- execution planning
- commit execution

## 4. Repository Structure Principles

The repository should be organized in three layers:

1. Host layer
   - plugin metadata
   - install entry
   - shared runtime
2. Module layer
   - `git`
3. Command layer
   - `/ry:git-commit`
     - params
     - analyzer
     - planner
     - executor
     - templates

The implementation should preserve future extensibility without adding unnecessary abstraction in phase 1.

## 5. Command Interface

### Supported invocation forms
- `/ry:git-commit`
- `/ry:git-commit --project <project> --branch <branch>`

### Resolution rules
- If `--project` is omitted, use the current project.
- If `--branch` is omitted, use the current branch.
- If project or branch is explicitly provided, validate reachability before analysis.

## 6. Core Workflow

The command runs through the following stages:

1. Resolve target project and branch.
2. Capture working tree snapshot.
3. Split the snapshot into two hard-separated buckets:
   - staged
   - unstaged
4. Analyze each bucket independently.
5. Generate transaction-oriented commit candidates.
6. If exactly one candidate remains, commit directly.
7. If multiple candidates exist, present them and wait for user selection.
8. Execute selected candidates in stable order.
9. Leave all unselected changes in the working tree.

## 7. Hard Separation Rules

Staged and unstaged changes are structurally isolated.

### Rules
- A candidate commit may belong to **either** `staged` **or** `unstaged`, never both.
- Candidate lists must explicitly label the source bucket.
- Presentation order is fixed:
  1. staged candidates
  2. unstaged candidates
- Execution logic must preserve this separation.

This separation is a product requirement, not only a display detail.

## 8. Candidate Split Strategy

Phase 1 uses a balanced transaction split strategy.

### Strategy rules
- Prefer splitting by user-meaningful transaction, not mechanically by file.
- Merge strongly coupled edits into one candidate.
- Avoid over-splitting ambiguous edits.
- Allow multiple commits with the same conventional type.
- Allow different hunks from the same file to belong to different candidates when the transaction boundary is clear.

### Limits
- staged candidates: at most 5
- unstaged candidates: at most 5
- total candidates: at most 9

## 9. Commit Message Rules

Commit messages follow conventional commits:

`type(scope): message`

### Supported types
- feat
- fix
- docs
- style
- refactor
- test
- build
- ci
- perf

### Rules
- `type` is always English.
- `scope` is optional.
- If the transaction clearly belongs to one subdomain, scope should be used.
- If the transaction has no clear single subdomain, omit scope.
- Do not use vague scopes.
- The natural language of `message` defaults to the language inferred from the latest commit on the target branch unless the user explicitly specifies otherwise.

## 10. Candidate Presentation Rules

When multiple candidates exist, each item must display:
- bucket label: `[staged]` or `[unstaged]`
- numeric index
- commit message
- file list

### File list rules
- Show relative file paths or concise file names by default.
- If too many files are included, truncate the list.
- Details may be expandable later, but phase 1 only requires the default concise file list.

### Example shape
- `[staged] 1. fix(commit): 修复候选编号解析错误`
  - Files: `src/commit/parser.ts`, `src/commit/selector.ts`
- `[unstaged] 2. docs(readme): update install example`
  - Files: `README.md`

## 11. User Selection Rules

Supported selection input forms:
- `12`
- `135`
- `1-3`
- `1,3,5`
- `1 3 5`
- `1-3,5`

### Parsing rules
- Deduplicate repeated indexes.
- Normalize input into an ordered index list.
- Execute in original candidate order, not in raw user input order.

## 12. Execution Rules

### For staged candidates
- Commit only the selected staged content.
- Unselected staged content must remain staged.

### For unstaged candidates
- The command may temporarily stage selected hunks automatically.
- Commit selected unstaged content directly.
- Unselected unstaged content must remain unstaged.

### Global execution principle
The command removes only the user-selected transactions and leaves all other changes in place.

## 13. Safety Boundaries

Phase 1 should reject execution in these situations:
- unresolved merge conflicts
- repository in merge / rebase / cherry-pick intermediate state
- target project or branch unreachable
- patch boundaries cannot be identified safely
- change set too complex to split safely

### Failure reporting requirements
Errors should clearly state:
- which step failed
- whether staged or unstaged candidates were affected
- what working tree / index state may remain
- what the user should do next

## 14. Core Internal Objects

### ChangeBucket
Represents one source bucket:
- `staged`
- `unstaged`

### CommitCandidate
Represents one candidate commit, including:
- bucket
- index
- type
- optional scope
- message
- file list
- change slices

### ChangeSlice
Represents an actual change fragment, possibly:
- whole file
- selected hunks within a file

### ExecutionPlan
Represents the final execution plan after user selection, including:
- chosen candidates
- execution order
- index assembly strategy
- post-execution preservation behavior

## 15. Design Principles

- Keep phase 1 small and safe.
- Preserve a modular shape for future growth.
- Prefer understandable behavior over aggressive automation.
- Treat staged / unstaged isolation as a first-class invariant.
- Always preserve unselected changes.
