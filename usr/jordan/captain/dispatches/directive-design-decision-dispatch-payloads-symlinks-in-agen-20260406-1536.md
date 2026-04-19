---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-06T07:36
status: created
priority: high
subject: "DESIGN DECISION: dispatch payloads — symlinks in ~/.agency/ pointing to git artifacts"
in_reply_to: null
---

# DESIGN DECISION: dispatch payloads — symlinks in ~/.agency/ pointing to git artifacts

## Decision

Principal decision: dispatch payload architecture uses **symlinks** in `~/.agency/{repo}/dispatches/` pointing to actual git artifacts on disk.

## The Problem We're Solving

Dispatch payloads in git have caused three classes of bugs this session:

1. **Branch transparency** — payloads on one branch invisible to agents on other branches. Captain sent dispatches #14, #16, #17 to ISCP; ISCP replied with payloads on the iscp branch; captain on main got "payload file not found."
2. **Template confusion** — `dispatch create` wrote templates that agents committed without editing. Fixed by requiring `--body` (escalation #53, commit 85d874d).
3. **Path derivation** — payload path derived from branch name; PR branches created garbage directories like `usr/jordan/valueflow-pvr-20260406/` (escalation #63, commit f05e3d0).

You built a 4-strategy resolution ladder (b1cd1b0) — local, main, sender branch, all-branch search. It works but it's complex and still requires git commands to find files across branches.

## The Discussion

Captain proposed moving payloads outside git entirely — alongside the DB at `~/.agency/{repo}/dispatches/`. Advantages: branch-transparent, no template confusion, no path bugs. Disadvantage: artifacts not in git (violates C3, no audit trail, no version history).

Principal's response: **the payload IS the artifact.** A dispatch about a PVR points to the PVR. The PVR is in git. The dispatch doesn't create a separate file — it points to something that already exists.

Captain explored alternatives:
- Copies outside git → drift between copy and original
- Reference files (branch + path metadata) → works but adds indirection
- Symlinks → **this is the answer**

## The Design

```
~/.agency/the-agency/dispatches/
  dispatch-001.md → /Users/jdm/code/the-agency/agency/workstreams/agency/valueflow-pvr-20260406.md
  dispatch-002.md → /Users/jdm/code/the-agency/.claude/worktrees/devex/usr/jordan/devex/some-artifact.md
```

**How it works:**
- Artifacts stay in git on their branch/worktree (C3 holds — source of truth, auditable, version-controlled)
- `~/.agency/{repo}/dispatches/` contains symlinks pointing to the filesystem path of the git artifact
- Symlinks resolve via OS path resolution — no git commands needed
- Works for main checkout (`/Users/jdm/code/the-agency/...`) AND worktrees (`/Users/jdm/code/the-agency/.claude/worktrees/devex/...`)
- Both are real directories on disk — OS follows the symlink transparently

**Dispatch tool changes:**
1. On `dispatch create`: write the payload to the correct git location (author's branch/worktree), then create a symlink in `~/.agency/{repo}/dispatches/` pointing to the filesystem path
2. On `dispatch read`: follow the symlink — `cat` or `readlink` resolves it. If dangling (worktree deleted), warn with actionable error
3. The DB `payload_path` column stores the symlink path (or the symlink name), not the git path

**What this replaces:**
- The 4-strategy resolution ladder (local → main → sender branch → all-branch search) becomes unnecessary
- The payload_path in the DB no longer needs to be a git-relative path
- `dispatch read` becomes a simple file read, not a multi-strategy search

**Edge cases:**
- Dangling symlink = worktree was deleted. Detectable: `readlink -e` returns error. Dispatch read warns: "payload unavailable — worktree may have been removed"
- Artifact moved/renamed in git = symlink breaks. Same detection. Author should update or the dispatch references the old location.

## Action

Design and implement this. This replaces your current payload resolution strategy. Update A&D Section 8 when you review `agency/workstreams/agency/valueflow-ad-20260406.md`.

## Acceptance Criteria

- [ ] `~/.agency/{repo}/dispatches/` directory created on first dispatch
- [ ] `dispatch create` writes symlink alongside payload file
- [ ] `dispatch read` follows symlink — works from any branch/worktree
- [ ] Dangling symlink detected and reported with actionable error
- [ ] Existing dispatches migrated (create symlinks for existing payloads)
- [ ] 4-strategy resolution ladder removed or kept as fallback for pre-migration dispatches
- [ ] All BATS tests updated and passing
