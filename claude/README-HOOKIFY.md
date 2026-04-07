# Hookify Rules — Reference

Hookify rules are TheAgency's behavioral enforcement layer. They run in `PreToolUse` hooks and either **block** (hard stop) or **warn** (advisory) when an agent is about to do something that violates the conventions.

This document is the comprehensive reference. It is readable by humans and agents. The methodology in `CLAUDE-THEAGENCY.md` and the orientation in `README-THEAGENCY.md` reference rules by name — this document explains what each one does.

## How Hookify Works

Hookify rules live in `claude/hookify/hookify.{name}.md`. Active rules are symlinked into `.claude/hookify.{name}.local.md` for Claude Code to discover. Each rule:

- **Triggers** on a specific Claude Code event (usually `PreToolUse` with a `Bash` matcher)
- **Matches** a pattern in the tool input
- **Decides** whether to block, warn, or pass through
- **Educates** the agent about the right way to do it

The enforcement triangle: every rule blocks the raw alternative and points to the skill or tool that should be used instead.

## Rule Categories

| Category | Purpose |
|----------|---------|
| **Block** | Hard enforcement — agent cannot proceed |
| **Warn** | Advisory — agent is told the right way but not blocked |
| **Authority** | Restricts certain operations to specific agents (captain, principal) |
| **Manual** | Reminders about manual processes that have no tool yet |

## Critical Rules (Read First)

These fire constantly and shape day-to-day agent behavior. Every adopter must understand them.

| Rule | Type | What It Does | Use Instead |
|------|------|-------------|-------------|
| `block-git-commit` | Block | Blocks raw `git commit` | `/git-commit` skill or `./claude/tools/git-commit` |
| `block-cd-to-main` | Block | Blocks `cd /Users/...` and absolute paths to tools | `./claude/tools/{name}` (relative paths from worktree) |
| `block-raw-handoff` | Block | Blocks raw `claude/tools/handoff` invocations | `/handoff` skill |
| `block-no-verify` | Block | Blocks `git commit --no-verify` and similar bypasses | Fix the underlying issue |
| `block-force-push-main` | Block | Blocks `git push --force` to main | Don't force-push main, ever |
| `require-qgr` | Block | Blocks commits without a matching QGR receipt | Run `/iteration-complete` or `/phase-complete` |
| `require-plan-update` | Warn | Warns when committing without updating the plan file | Update `usr/{principal}/{project}/{project}-plan-*.md` |
| `directive-authority` | Block | Only captain can create `--type directive` dispatches | Use a different dispatch type |
| `review-authority` | Block | Only captain can create `--type review` dispatches | Use a different dispatch type |

## All Rules

### Block Rules (Hard Enforcement)

| Rule | What It Blocks | Use Instead |
|------|---------------|-------------|
| `block-cd-to-main` | `cd /Users/.../the-agency &&` and absolute paths to `claude/tools/` | `./claude/tools/{name}` |
| `block-force-push-main` | `git push --force` to main/master | Don't force-push main |
| `block-git-commit` | Raw `git commit` | `/git-commit` skill |
| `block-no-verify` | `--no-verify`, `--no-gpg-sign`, etc. | Fix the underlying issue |
| `block-raw-git-merge-master` | Raw `git merge master` | `/sync-all` skill |
| `block-raw-handoff` | Raw `claude/tools/handoff` | `/handoff` skill |
| `block-system-install` | `brew install`, `apt install`, etc. | Ask principal first |
| `block-testuser-paths` | Writes to `usr/testuser/` | Use `usr/{actual-principal}/` |

### Warn Rules (Advisory)

| Rule | What It Warns | Use Instead |
|------|---------------|-------------|
| `warn-compound-bash` | `&&`, `\|`, `;`, subshells in Bash commands | Separate Bash tool calls |
| `warn-destructive-git` | `git reset --hard`, `git clean -fd`, etc. | Verify work is preserved first |
| `warn-enter-worktree` | `cd .claude/worktrees/{name}` from main | Launch a separate session |
| `warn-env-files` | Writing or staging `.env` files | Use the secret tool |
| `warn-external-git-actions` | Git operations against unrelated repos | Use the collaboration tool |
| `warn-external-paths` | Bash commands touching collaboration repos directly | Use `./claude/tools/collaboration` |
| `warn-multi-item-response` | Long responses with multiple unrelated items | Use 1B1 protocol via `/discuss` |
| `warn-npm` | Direct `npm` usage | Verify it's the right package manager |
| `warn-npx` | Direct `npx` usage | Verify it's the right invocation |
| `warn-on-push` | Any `git push` command | Verify push is authorized |
| `warn-raw-cat` | Raw `cat` commands | Use the `Read` tool |
| `warn-raw-doppler` | Direct `doppler` invocations | Use the secret tool |
| `warn-raw-find` | Raw `find` commands | Use the `Glob` tool |
| `warn-raw-grep` | Raw `grep` commands | Use the `Grep` tool |
| `warn-script-persistence` | Writing scripts to `tmp/` instead of `tools/` | Use `usr/{principal}/{project}/tools/` |
| `warn-secrets` | Patterns that look like secrets | Use the secret tool |
| `warn-whw-header` | File writes without provenance headers | Add What/How/Written header |

### Authority Rules

| Rule | What It Restricts | Allowed |
|------|-------------------|---------|
| `directive-authority` | `dispatch create --type directive` | Captain only |
| `review-authority` | `dispatch create --type review` | Captain only |
| `no-push-main` | `git push origin main` (or master) | Captain with explicit principal approval |

### Manual Process Reminders

| Rule | What It Reminds | When |
|------|----------------|------|
| `dispatch-manual` | Process dispatches manually after handling | After reading a dispatch |
| `flag-manual` | Process flags manually after triage | After triaging flags |
| `session-start-mail` | Check ISCP mail at session start | On every session start |
| `require-plan-update` | Update plan file before committing | On every commit |
| `require-qgr` | Generate QGR receipt before committing | On every commit |

## Adding a New Rule

1. Create `claude/hookify/hookify.{name}.md` with frontmatter:
   ```yaml
   ---
   trigger: PreToolUse
   matcher: Bash
   ---
   ```
2. Write the rule body — what to match, what to block/warn, what to do instead
3. End with the trademark: `*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*`
4. Symlink or copy to `.claude/hookify.{name}.local.md` for activation
5. Add an entry to this README in the appropriate section

## Adding a New Capability — Use the Triangle

Every new capability needs three parts:

1. **Tool** — `claude/tools/{name}` does the work
2. **Skill** — `.claude/skills/{name}/SKILL.md` tells the agent when and how
3. **Hookify rule** — `claude/hookify/hookify.block-raw-{name}.md` blocks the bypass

Build all three. The tool handles permissions, the skill handles discovery, the hookify rule handles compliance. See the Enforcement Triangle in `CLAUDE-THEAGENCY.md` for more.

## Disabling a Rule

Sandboxed: remove the symlink from `.claude/hookify.{name}.local.md`. The rule file stays in `claude/hookify/` but isn't active.

Removing entirely: delete from both `claude/hookify/` and `.claude/`. Don't do this without principal approval.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
