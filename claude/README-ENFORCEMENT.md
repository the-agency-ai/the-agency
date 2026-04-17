# Enforcement — How TheAgency Enforces Its Rules

TheAgency's quality and convention story is **mechanical, not aspirational**. Rules exist as code — hooks, hookify rules, quality gates, the permission system. Agents and humans both forget prose. Mechanical enforcement doesn't.

This document is the comprehensive reference for the enforcement model. It is readable by humans and agents. Other docs (`CLAUDE-THEAGENCY.md`, `README-THEAGENCY.md`) reference this one for the full picture.

## The Enforcement Model

Enforcement in TheAgency operates at **five layers**, from soft to hard:

| Layer | Mechanism | What | Examples |
|-------|-----------|------|----------|
| 1. Documentation | Markdown in `claude/REFERENCE-*.md`, `CLAUDE-THEAGENCY.md` | Human and agent readable conventions | Methodology, address format |
| 2. Skills | `.claude/skills/{name}/SKILL.md` | Discoverable invocations of conventions | `/handoff`, `/iteration-complete` |
| 3. Tools | `claude/tools/{name}` | Mechanical capabilities with logging and telemetry | `dispatch`, `git-safe-commit`, `stage-hash` |
| 4. Hookify rules | `claude/hookify/hookify.{name}.md` | PreToolUse hooks that block or warn on patterns | `block-git-safe-commit`, `warn-compound-bash` |
| 5. Lifecycle hooks | `.claude/settings.json` hooks | Claude Code lifecycle events that fire scripts | `iscp-check`, `quality-check`, `ref-injector` |

Each layer addresses the bypass discovered in the previous layer. Quality gates run on top of all of them.

## The Enforcement Triangle

The Triangle is the **per-capability structural pattern**. Every Agency capability has three parts that work together:

| Layer | What | Why |
|-------|------|-----|
| **Tool** (`claude/tools/{name}`) | Does the work. Pre-approved in `settings.json`. | Permissions. No prompts for approved operations. |
| **Skill** (`.claude/skills/{name}/SKILL.md`) | Tells the agent when and how to use the tool. | Discovery. Agents find it via `/` autocomplete. |
| **Hookify rule** (`claude/hookify/`) | Blocks the raw alternative. Points to the skill. | Compliance. Can't bypass. |

When building a new capability: build the tool, wrap it in a skill, block the raw alternative with a hookify rule. All three. Not one, not two. The tool handles permissions, the skill handles discovery, the hookify rule handles compliance.

**Triangle examples:**

| Capability | Tool | Skill | Hookify Rule |
|------------|------|-------|--------------|
| Safe git commits | `git-safe` / `git-captain` | `/git-safe`, `/git-captain`, `/git-safe-commit` | `block-git-safe-commit` (blocks raw `git commit`) |
| Safe file copy | `cp-safe` | *(called directly)* | `block-raw-cp` (blocks raw `cp`) |
| PR creation | `pr-create` | `/release` | `block-raw-pr-create` (blocks raw `gh pr create`) |

## The Enforcement Ladder

The Ladder is the **per-capability adoption progression**. Different capabilities are at different ladder steps. New capabilities start at step 1 and progress as they mature:

1. **Document** — write it in `CLAUDE-THEAGENCY.md` or a referenced doc. Human-readable, no tooling required.
2. **Skill** — wrap the documented process in an invocable skill. Discovery via `/` autocomplete.
3. **Tool** — build the mechanical capability. Pre-approved in `settings.json`.
4. **Hookify warn** — warn when the tool is bypassed. Points to the skill.
5. **Hookify block** — hard enforcement. Can't bypass.

**Triangle vs Ladder:** The Triangle is the *structure* (tool + skill + hookify). The Ladder is the *progression* (how a capability moves from documented to fully enforced). A capability at step 5 has all three Triangle parts; a capability at step 1 has only docs.

**Where things stand today:** Mature capabilities like `git-safe-commit`, `handoff`, `dispatch`, and `flag` are at steps 4–5 (warn or block enforced). Newer methodology patterns like Valueflow, MAR, MARFI, three-bucket triage, and SPEC-PROVIDER are at step 1 — documented, but not yet skill-wrapped or enforced. Each capability progresses up the ladder as it matures.

## Lifecycle Hooks

Claude Code fires hooks at well-defined lifecycle events. TheAgency uses these to inject context, check messages, validate state, and run telemetry. Hooks live in `claude/hooks/` and are wired in `.claude/settings.json`.

**Shipped template** (`claude/config/settings-template.json`) — what new adopters get on `agency init`:

| Event | What's Wired |
|-------|--------------|
| `SessionStart` | `iscp-check` (mail check), `collaboration check` (cross-repo), `worktree-cwd-check` (verify agent is in expected worktree) |
| `UserPromptSubmit` | `iscp-check` (mail reminder) |
| `PreToolUse` (Skill) | `ref-injector.sh` (loads referenced docs) |
| `Stop` | `iscp-check` |

The shipped template is intentionally minimal. Projects extend it for their own concerns. The current the-agency repo's local `.claude/settings.json` adds: `session-start.sh`, `branch-freshness.sh`, `session-handoff.sh`, `ghostty-status.sh`, `quality-check.sh`, `stop-check.py`, `tool-telemetry.sh`, `plan-capture.sh`/`.py`, `session-backup`, `session-end.sh`. These are local additions, not shipped.

**Available hooks in `claude/hooks/`** (any project can wire these):

| Hook | Purpose |
|------|---------|
| `branch-freshness.sh` | Warn if current branch is stale relative to main |
| `ghostty-status.sh` | Update Ghostty terminal status line |
| `plan-capture.sh` | Capture plan content on `ExitPlanMode` |
| `quality-check.sh` | Validate session state on `Stop` (uncommitted changes, etc.) |
| `ref-injector.sh` | Inject `@`-referenced docs when a skill is invoked |
| `session-handoff.sh` | Inject the agent's handoff on `SessionStart` |
| `tool-telemetry.sh` | Log every tool invocation to `~/.claude/telemetry/{date}.jsonl` |

**Available tools used by hooks** (called from settings.json hook commands):

| Tool | Purpose |
|------|---------|
| `claude/tools/iscp-check` | "You got mail" notification — fires on SessionStart, UserPromptSubmit, Stop |
| `claude/tools/collaboration check` | Pull cross-repo dispatches and surface unread items |
| `claude/tools/worktree-cwd-check` | Verify the agent's CWD matches their worktree at session start (Layer 1 of cd-stays-in-worktree) |

**Git hook templates:**

| Hook | Purpose | Where |
|------|---------|-------|
| `commit-msg` | Validate commit message against the Day/Phase prefix convention when `commits.require_day_prefix` is enabled in `agency.yaml` | Installed by `agency init` (or `agency update`) into `.git/hooks/commit-msg` |

**Important:** `$CLAUDE_PROJECT_DIR` is **only set inside hook execution**, not in agent Bash tool calls. Agents must use `./claude/tools/` (relative paths) when invoking tools — never `$CLAUDE_PROJECT_DIR/claude/tools/...` from a Bash command.

## Hookify Rules

Hookify rules are `PreToolUse` hooks with pattern matching that block or warn when an agent is about to do something that violates conventions. They live in `claude/hookify/hookify.{name}.md` and are activated by symlinking into `.claude/hookify.{name}.local.md`.

### Critical Fix — Day 40: Blocks Were Theater Before

**Prior to the Day 40 hookify fix**, all "block" rules used `systemMessage` + `exit 0`. This meant the hook printed a warning but Claude Code treated `exit 0` as success and **ran the command anyway**. "BLOCKED" messages were theater.

**After the Day 40 fix**, block rules use `decision: block` + `exit 2`. Claude Code interprets `exit 2` as a hard block — the command is cancelled, not just warned about. If you adopted TheAgency before Day 40, run `agency update` to pick up the corrected hookify rules.

### Rule Categories

| Category | Purpose |
|----------|---------|
| **Block** | Hard enforcement — agent cannot proceed |
| **Warn** | Advisory — agent is told the right way but not blocked |
| **Authority** | Restricts certain operations to specific agents (captain, principal) |
| **Manual** | Reminders about manual processes that have no tool yet |

### Critical Rules (Read First)

These fire constantly and shape day-to-day agent behavior. Every adopter must understand them.

| Rule | Type | What It Does | Use Instead |
|------|------|-------------|-------------|
| `block-git-safe-commit` | Block | Blocks raw `git commit` | `/git-safe-commit` skill or `./claude/tools/git-safe-commit` |
| `block-raw-push` | Block | Blocks ALL raw `git push` | Use `/sync` (the only authorized push command) |
| `block-raw-cp` | Block | Blocks raw `cp` commands | `./claude/tools/cp-safe` |
| `block-raw-pr-create` | Block | Blocks raw `gh pr create` | `/release` skill |
| `block-cd-to-main` | Block | Blocks `cd /Users/...` and absolute paths to tools | `./claude/tools/{name}` (relative paths from worktree) |
| `block-cd-outside-worktree` | Block | Blocks any `cd` that takes the agent outside their worktree | Stay in worktree, use absolute paths via Read/Write tools |
| `block-git-add-and-commit` | Block | Blocks the compound `git add ... && git commit` form | `/git-safe-commit` skill (separate Bash calls if you must) |
| `block-raw-handoff` | Block | Blocks raw `claude/tools/handoff` invocations | `/handoff` skill |
| `block-no-verify` | Block | Blocks `git commit --no-verify` and similar bypasses | Fix the underlying issue |
| `block-raw-git-config-user-in-tests` | Block | Blocks bare `git config user.*` in BATS tests | Use `test_isolation_setup` from `test_helper.bash` |
| `require-qgr` | Block *(planned)* | Will block commits without a matching QGR receipt — not yet wired | Run `/iteration-complete` or `/phase-complete` |
| `require-plan-update` | Warn | Warns when committing without updating the plan file | Update `claude/workstreams/{W}/plan-{W}-{slug}-*.md` |
| `directive-authority` | Block | Only captain can create `--type directive` dispatches | Use a different dispatch type |
| `review-authority` | Block | Only captain can create `--type review` dispatches | Use a different dispatch type |

### All Rules

#### Block Rules (Hard Enforcement)

| Rule | What It Blocks | Use Instead |
|------|---------------|-------------|
| `block-cd-to-main` | `cd /Users/.../the-agency &&` and absolute paths to `claude/tools/` | `./claude/tools/{name}` |
| `block-cd-outside-worktree` | Any `cd` that resolves to a path outside the agent's worktree | Stay in worktree; use absolute paths to Read/Write outside |
| `block-git-add-and-commit` | The compound `git add ... && git commit ...` pattern | `/git-safe-commit` skill (or separate Bash calls if you must) |
| `block-git-safe-commit` | Raw `git commit` | `/git-safe-commit` skill |
| `block-no-verify` | `--no-verify`, `--no-gpg-sign`, etc. | Fix the underlying issue |
| `block-raw-cp` | Raw `cp` commands | `./claude/tools/cp-safe` |
| `block-raw-git-config-user-in-tests` | Bare `git config user.name`/`user.email` in BATS test files | Use `test_isolation_setup` from `test_helper.bash` |
| `block-raw-git-merge-master` | Raw `git merge master` | `/sync-all` skill |
| `block-raw-handoff` | Raw `claude/tools/handoff` | `/handoff` skill |
| `block-raw-pr-create` | Raw `gh pr create` | `/release` skill |
| `block-raw-push` | ALL `git push` commands | `/sync` skill (the only authorized push command) |
| `block-system-install` | `brew install`, `apt install`, etc. | Ask principal first |
| `block-testuser-paths` | Writes to `usr/testuser/` | Use `usr/{actual-principal}/` |
| `block-raw-gh-pr-merge` | Raw `gh pr merge` | `./claude/tools/pr-merge` via `/pr-merge` skill |
| `block-raw-gh-release` | Raw `gh release create` | `/post-merge` skill (creates release after PR merge) |
| `block-raw-tools` | Raw invocation of tools that have skill wrappers | Use the corresponding `/` skill |

#### Warn Rules (Advisory)

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
| `warn-script-persistence` | Writing scripts to `tmp/` instead of `tools/` | Use `usr/{P}/{A}/tools/` |
| `warn-secrets` | Patterns that look like secrets | Use the secret tool |
| `warn-whw-header` | File writes without provenance headers | Add What/How/Written header |

#### Authority Rules

| Rule | What It Restricts | Allowed |
|------|-------------------|---------|
| `directive-authority` | `dispatch create --type directive` | Captain only |
| `review-authority` | `dispatch create --type review` | Captain only |

#### Manual Process Reminders

| Rule | What It Reminds | When |
|------|----------------|------|
| `dispatch-manual` | Process dispatches manually after handling | After reading a dispatch |
| `flag-manual` | Process flags manually after triage | After triaging flags |
| `session-start-mail` | Check ISCP mail at session start | On every session start |
| `require-plan-update` | Update plan file before committing | On every commit |
| `require-qgr` | Generate QGR receipt before committing | On every commit |

## Quality Gates

Quality gates are tiered checkpoints that run at every commit boundary. Each tier has a different scope and time budget. See `claude/REFERENCE-QUALITY-GATE.md` for the full protocol.

| Tier | Boundary | Checks | Time budget | Skill |
|------|----------|--------|-------------|-------|
| **T1** | Iteration commit | Stage-hash + build + format + relevant fast tests | <60s | `/iteration-complete` |
| **T2** | Phase commit | T1 + full relevant unit tests | <120s | `/phase-complete` (pre-squash) |
| **T3** | Phase complete | Full test suite + MAR on phase artifacts | <5min | `/phase-complete` (deep QG) |
| **T4** | Pre-PR | Full diff QG vs origin/main | <5min | `/pr-prep` |

Each gate produces a **QGR (Quality Gate Report)** receipt at `claude/workstreams/{ws}/qgr/{org}-{principal}-{agent}-{ws}-{proj}-qgr-{boundary}-{YYYYMMDD-HHMM}-{hash_e_short}.md`. The receipt is signed via `receipt-sign` with a five-hash chain of trust. `pr-create` calls `receipt-verify` and blocks if no valid receipt matches the current diff.

## Permission Model

The framework ships with broad permissions:

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(**)",
      "Edit(**)",
      "Write(**)"
    ]
  }
}
```

**Why so broad?** The security model is layered:

1. **Project boundary** — agents can read/write within the project, nothing outside it. The project root is the security perimeter.
2. **Hookify rules** — behavioral enforcement happens at the rule layer, not the permission layer. Rules block raw `git commit`, prevent `cd` to the main repo, force the use of skills over raw tools, enforce QGR receipts, etc.
3. **Git** — version control is the audit trail. Anything an agent does is reviewable.

Narrow permission patterns (the old approach) created friction — every new command triggered a prompt, blocked legitimate work, and didn't actually improve security. Hookify rules enforce intent; permissions enforce scope.

## Adding a New Capability — Use the Triangle

Every new capability needs three parts:

1. **Tool** — `claude/tools/{name}` does the work
2. **Skill** — `.claude/skills/{name}/SKILL.md` tells the agent when and how
3. **Hookify rule** — `claude/hookify/hookify.raw-{name}-block.md` blocks the bypass (noun-verb naming: noun first, action last)

Build all three. The tool handles permissions, the skill handles discovery, the hookify rule handles compliance.

## Adding a New Hookify Rule

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

## Disabling a Rule

Sandboxed: remove the symlink from `.claude/hookify.{name}.local.md`. The rule file stays in `claude/hookify/` but isn't active.

Removing entirely: delete from both `claude/hookify/` and `.claude/`. Don't do this without principal approval.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
