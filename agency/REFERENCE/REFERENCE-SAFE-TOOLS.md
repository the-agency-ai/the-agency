# Safe Tools — Full Reference

Tool path root: `./agency/tools/`

---

## `git-safe`

Safe git operations for all agents. Hookify blocks raw `git add -A`, `git add .`, and `git rebase`; this tool provides the approved read and limited-write path.

**Usage:** `./agency/tools/git-safe <subcommand> [args...]`

### Subcommands

#### Read-only (pass-through)

| Subcommand | Equivalent | Notes |
|---|---|---|
| `status [args]` | `git status` | All args passed through |
| `log [args]` | `git log` | All args passed through |
| `diff [args]` | `git diff` | All args passed through |
| `branch` | `git branch --show-current` | Returns current branch name only |
| `show [args]` | `git show` | All args passed through |
| `blame [args]` | `git blame` | All args passed through |

#### Guarded write

**`add <file> [file...]`**

Stages explicit file paths. Blocked patterns (exit 1):
- `-A` / `--all` flags
- `.` / `./` / `..` / `../` bare paths
- `*` / `**` glob wildcards (when passed quoted)
- Any path that resolves to a directory

On success: stages files, prints `Staged: <files>`.

**`rm <file> [file...]`**

Removes explicit file paths from working tree and index. Same guards as `add`:
- blocks `-r` / `-R` / `-rf` / `--recursive` / `-f` / `--force`
- blocks `.` / `./` / `..` / `../`, `*` / `**`, and any path that resolves to a directory

On success: runs `git rm`, prints `Removed: <files>`.

**`merge-from-master`**

Merges main/master into the current feature branch.

Checks (each exits 1 on failure):
1. Auto-detects `main` (tried first) or `master`
2. Refuses if already on the main branch
3. Refuses if working tree is dirty (`git diff` or `git diff --cached` non-empty)
4. Optional `--remote` merges `origin/main` instead of local `main` (fetch first).

On success: runs `git merge <main_branch> --no-edit`, prints merge summary.

**`resolve-conflict <file> --ours|--theirs`** (D41-R7)

Resolves a conflicted file mid-merge by taking one side and staging it.

- Requires MERGE_HEAD (exits 1 otherwise — no merge in progress)
- Requires the file to have an unmerged index entry (exits 1 otherwise)
- Exactly one file per invocation; `--ours` or `--theirs` mandatory
- Runs `git checkout --ours|--theirs -- <file>` then `git add -- <file>`

On success: prints `Resolved: <file> (took <side>)`.

**When to use which tool mid-merge:**

| Situation | Tool |
|---|---|
| Keep our side of a conflicted file | `git-safe resolve-conflict <file> --ours` |
| Keep the incoming side | `git-safe resolve-conflict <file> --theirs` |
| File should be deleted (delete-as-resolution) | `git-safe rm <file>` |
| Abandon the merge entirely | `git-safe merge-abort` |
| Manual edit already made, stage the result | `git-safe add <file>` |
| Conclude the merge after all files resolved | `git-safe-commit` (auto-detects MERGE_HEAD) |

**`merge-abort`** (D41-R7)

Aborts an in-progress merge by wrapping `git merge --abort`. Exits 1 if MERGE_HEAD is absent.

### Options

| Flag | Effect |
|---|---|
| `--help` / `-h` | Print usage |
| `--version` | Print `git-safe 1.0.0` |

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Blocked pattern, missing args, or merge failure |

---

## `git-captain`

Captain-only privileged git operations. Wraps merge-to-master, branch management, push, fetch, and tagging with safety checks.

**Usage:** `./agency/tools/git-captain <subcommand> [args...]`

### Subcommands

**`merge-to-master <branch>`**

Merges a feature branch into main/master using `--no-ff`.

Checks (each exits 1 on failure):
1. Must currently be on main/master
2. Source branch must exist (`refs/heads/<branch>`)

On success: `git merge <branch> --no-ff --no-edit`.

**`checkout-branch <name>`**

Creates and switches to a new branch.

Checks (each exits 1 on failure):
1. Name must match `[a-zA-Z0-9][a-zA-Z0-9._/-]*` (ASCII letters + digits, leading letter or digit, subsequent chars may also include `.`, `_`, `/`, `-`)
2. Name must not contain `..`, end with `/`, `.`, `-`, or `.lock` (per `git check-ref-format`)
3. Branch must not already exist (use `switch-branch` for existing branches)

**`switch-branch <name>`**

Switches to an existing branch (including main).

Checks (each exits 1 on failure):
1. Branch must already exist
2. Working tree must be clean

**`push [args]`**

Pushes to remote origin.

Checks (each exits 1 on failure):
1. Bare `--force` / `-f` without `--force-with-lease` is blocked
2. Explicit refspec naming main/master is blocked
3. If currently on main/master with no explicit refspec, push is blocked

Safe force push: `--force-with-lease` is allowed.

**`fetch`**

Runs `git fetch origin`. No restrictions.

**`tag <name> [-m <msg>]`**

Creates an annotated tag. Message defaults to `"Tag <name>"` if `-m` is omitted.

Checks (exits 1 on failure):
1. Tag must not already exist

**`branch-delete <name>`**

Safe-deletes a branch using `-d` (not `-D`).

Checks (each exits 1 on failure):
1. Cannot delete main/master
2. Cannot delete the currently checked-out branch
3. Unmerged branches are rejected by git's `-d` flag (unmerged work is protected)

### Options

| Flag | Effect |
|---|---|
| `--help` / `-h` | Print usage |
| `--version` | Print `git-captain 1.0.0` |

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Blocked, missing args, validation failure, or git failure |

---

## `git-safe-commit`

QG-aware commit wrapper. Enforces work item tracking, builds structured commit messages, adds per-agent attribution, and dispatches a commit notification to captain.

**Usage:** `./agency/tools/git-safe-commit "<message>" --work-item <ID> --stage <stage>`

**Escape hatch:** `./agency/tools/git-safe-commit "<message>" --no-work-item`

### Options

| Flag | Short | Required | Description |
|---|---|---|---|
| `"<message>"` | — | Yes | Short summary (positional) |
| `--work-item <ID>` | `-w` | Yes* | Work item ID: `REQUEST-jordan-0065`, `SPRINT-web-2026w03`, etc. |
| `--stage <stage>` | `-s` | When work-item given | One of: `impl`, `review`, `tests` |
| `--no-work-item` | — | Alternative to `--work-item` | Explicit escape hatch |
| `--allow-large` | — | No | Bypass commit-precheck large-file block for this commit (sets `ALLOW_LARGE_COMMIT=1`) |
| `--body <text>` | `-b` | No | Detailed commit body |
| `--principal <name>` | `-p` | No | Override principal (default: from work item or env) |
| `--staged` | — | No | Only commit staged changes (default: stage all with `git add -A`) |
| `--dry-run` | — | No | Preview message without committing |
| `--amend` | — | No | Amend the previous commit |
| `--no-verify` | — | No | Skip pre-commit hooks |
| `--verbose` | — | No | Show detailed log output |

### Work item pattern

Must match: `^(REQUEST|BUG|TASK|PHASE|ITERATION|SPRINT)-[a-zA-Z0-9-]+$`

Examples: `REQUEST-jordan-0065`, `BUG-web-0012`, `SPRINT-devex-2026w14`

### Commit message formats

With work item:
```
{WORK-ITEM} - {WORKSTREAM}/{AGENT} for {PRINCIPAL}: {MESSAGE}

{body}

Stage: {stage}
Generated-With: Claude Code
Co-Authored-By: {agent} <{gh-username}+{agent}.{repo}.{org}@users.noreply.github.com>
Co-Authored-By: Claude <noreply@anthropic.com>
```

Without work item (`--no-work-item`):
```
{WORKSTREAM}/{AGENT}: {MESSAGE}

{body}

Generated-With: Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

When `commits.require_day_prefix` is `true` in `agency.yaml`, the message is used as-is (no workstream/agent prefix injected).

### Workstream/agent resolution order

1. `AGENCY_WORKSTREAM` / `AGENCY_AGENT` environment variables
2. `~/.claude/current-session` file
3. Git branch name pattern `{workstream}/{agent}-description`
4. Fallback: `housekeeping/captain`

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Success (or nothing to commit) |
| 1 | Missing message, missing work item, invalid work item format, missing stage, invalid stage, or commit failure |
| 2 | Commit prefix validation failure (when `require_day_prefix` is enabled) |

### Merge-commit auto-route (D41-R7)

When invoked with a merge in progress (`.git/MERGE_HEAD` present) and no `--amend` / `--dry-run`, `git-safe-commit` short-circuits to `git commit --no-edit` to conclude the merge using git's default merge message. The normal work-item / message flow is skipped — you do not need `--no-work-item` mid-merge.

If conflicts remain unresolved (unmerged index entries), the commit is blocked with a pointer to `git-safe resolve-conflict` / `git-safe rm` / `git-safe merge-abort`.

This replaces the earlier `git-captain merge-continue` workaround for agents finishing a merge through the git-safe family.

### Large-file gate (via `commit-precheck`)

The pre-commit hook runs `commit-precheck`, which stats every staged file and enforces size thresholds:

| Threshold | Default | Env override | Action |
|---|---|---|---|
| Warn | 1 MB (1048576 B) | `LARGE_FILE_WARN_BYTES` | Prints warning, commit proceeds |
| Block | 10 MB (10485760 B) | `LARGE_FILE_BLOCK_BYTES` | Exits 2, commit aborted |

**Bypass:** `git-safe-commit --allow-large` (one-shot) or export `ALLOW_LARGE_COMMIT=1`.

**Permanent exemptions:** add one glob per line to `agency/config/large-file-exceptions.txt`. Matching is against full path or basename, `#` comments and blank lines ignored. Prefer narrow globs; use Git LFS for recurring large binaries.

Rationale: GitHub soft-caps at 50 MB (warn) / 100 MB (reject). By then the commit is already local and requires history rewrite to remove. Catching at commit time avoids that.

---

## `git-push`

Thin push wrapper. Blocks pushes to main/master. The only approved push path when hookify blocks raw `git push`.

**Usage:** `./agency/tools/git-push [--force-with-lease] [branch]`

### Arguments

| Argument | Default | Description |
|---|---|---|
| `branch` | Current branch (`git rev-parse --abbrev-ref HEAD`) | Branch to push |
| `--force-with-lease` | Off | Enable safe force push for PR branch updates |

### Guards

- Exits 1 if `branch` is `main` or `master`
- Always uses `git push -u origin <branch>` (sets upstream)
- With `--force-with-lease`: uses `git push --force-with-lease origin <branch>`

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Push succeeded |
| 1 | Blocked (main/master target) or git failure |

---

## `cp-safe`

Worktree-boundary-aware file copy. Blocks cross-worktree copies that would bypass git change tracking.

**Usage:** `./agency/tools/cp-safe [-r] <source> <dest>`

### Arguments

| Argument | Description |
|---|---|
| `source` | Source file or directory |
| `dest` | Destination path |
| `-r` / `-R` / `--recursive` / `-a` | Recursive copy (passed through to `cp`) |

Multi-source copy (`cp file1 file2 dir/`) is not supported. Run `cp-safe` once per file.

### Worktree detection

Walks up the directory tree from each path looking for a `.git` marker. For non-existent destination paths, walks up to the nearest existing parent directory.

### Guards (each exits 1 on failure)

1. Source must be inside a git repository
2. Destination must be inside a git repository
3. Source and destination must be in the same worktree root

Blocked example: copying from `/repo/.git/worktrees/devex/file` to `/repo/file` — different worktree roots.

For cross-worktree sync, use `/worktree-sync`.

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Copy succeeded |
| 1 | Wrong number of args, source/dest outside git repo, or cross-worktree attempt |

---

## `pr-create`

QG-gated PR creation. Wraps `gh pr create` with three mandatory checks. Hookify blocks raw `gh pr create`.

**Usage:** `./agency/tools/pr-create --title "title" --body "body" [gh pr create flags...]`

All flags after validation are passed through to `gh pr create`.

### Pre-flight checks

**Step 1 — Branch check**

Exits 1 if currently on `main` or `master`. Must be on a feature branch.

**Step 2 — Receipt check**

Finds the newest receipt file via three-tier search: `agency/workstreams/*/qgr/*.md` and `*/rgr/*.md` (checked first) → `agency/receipts/*.md` (legacy) → `usr/**/qgr-*.md` (old-old). Runs `./agency/tools/receipt-verify --file <receipt>`. Exits 1 if no receipt exists or receipt verification fails.

A receipt is produced by the Quality Gate (`/quality-gate`, `/pr-prep`, or `/release`). See `agency/README-RECEIPT-INFRASTRUCTURE.md` for receipt format details.

**Step 3 — Version bump check**

Checks that `agency/config/manifest.json` differs from `origin/main` (committed, staged, or unstaged). Exits 1 if the manifest has not changed.

The manifest must have an updated `agency_version` and `updated_at` timestamp. The `/release` skill handles this automatically.

### Exit codes

| Code | Meaning |
|---|---|
| 0 | All checks passed, PR created |
| 1 | Branch check failed, receipt missing/invalid, version not bumped, or `gh pr create` failure |
