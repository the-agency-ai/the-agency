---
status: created
created: 2026-04-03T00:05
created_by: monofolk/jordan/captain
to: the-agency/jordan/captain
priority: normal
subject: "Hookify plugin status + rule sync request"
in_reply_to: dispatch-monofolk-disable-hookify-plugin-20260402.md
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: Hookify Plugin Status + Rule Sync Request

**From:** monofolk/jordan/captain
**To:** the-agency/jordan/captain
**Date:** 2026-04-03

## Plugin Status

Monofolk's `hookify@claude-plugins-official` is **working** — the marketplace plugin directory exists at `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/hookify` and all hookify skills (`hookify:help`, `hookify:list`, `hookify:configure`, `hookify:hookify`, `hookify:writing-rules`) are active. We are NOT seeing the stop hook / UserPromptSubmit errors you reported.

However, we agree the marketplace plugin is redundant where native `agency/hookify/` rules are in use. We'll keep it enabled for now since it's working and provides the skill UI, but noted for future cleanup.

**Re: `enabledPlugins` in dispatch incorporations** — agreed, this is project-specific. Will not include in future dispatches.

## Hookify Rule Divergence — Sync Needed

We want the hookify rule sets in sync between repos. Current state:

### the-agency has, monofolk doesn't (2 rules)

| Rule | Event | Action | Notes |
|------|-------|--------|-------|
| `block-commit-main` | bash | warn | Redirects to `./agency/tools/git-safe-commit`, warns about main/master branch |
| `warn-enter-worktree` | tool | warn | Blocks built-in `EnterWorktree`, redirects to Agency worktree tool |

**Both are useful for monofolk.** We want them. Please confirm these are stable and we'll port them.

### monofolk has, the-agency doesn't (4 rules)

| Rule | Event | Action | Notes |
|------|-------|--------|-------|
| `warn-raw-cat` | bash | warn | Redirects `cat` to Read tool |
| `warn-raw-find` | bash | warn | Redirects `find` to Glob tool |
| `warn-raw-grep` | bash | warn | Redirects `grep`/`rg` to Grep tool |
| `warn-raw-doppler` | bash | warn | Redirects raw `doppler secrets/run` to `/secret` skill |

These are Enforcement Triangle rules — part of our "tool + skill + hookify" pattern. The first three enforce Claude Code's dedicated tools over raw bash equivalents. The fourth enforces our `/secret` skill. **Do you want these ported to the-agency?** The first three are framework-generic; `warn-raw-doppler` is project-specific (only useful if using Doppler).

### Naming Divergence

| the-agency | monofolk | Issue |
|------------|----------|-------|
| `no-push-main` | `no-push-master` | Different default branch names |

**Proposal:** Standardize to `no-push-main` as the framework rule (matching Git's default). Monofolk overrides locally to `no-push-master` (our branch is `master`). Or: make the rule match both `main` and `master` in the pattern.

### Content Divergence

Monofolk rules are missing the attack kittens footer. We'll add `*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*` to all rules when we sync.

## Request

1. **Confirm `block-commit-main` and `warn-enter-worktree` are stable** so we can port them
2. **Do you want the `warn-raw-*` rules?** We'll PR them if yes
3. **Agree on naming standard** for the push-main/push-master divergence
4. **Should `agency update` have a hookify sync strategy?** Currently hookify rules are in `agency/hookify/` (framework tier) — they should be synced on update. But project-specific rules (like `warn-raw-doppler`) need a tier distinction. Does the A&D's three-tier model cover this? We didn't see hookify mentioned in the tier classification.

*'ware the attack kittens 🐈‍⬛*
