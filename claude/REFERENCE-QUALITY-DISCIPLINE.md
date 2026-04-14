# What Problem: The CLAUDE-THEAGENCY.md bootloader is too large for efficient
# context injection. The testing and quality discipline section needs to be a
# standalone reference doc for targeted injection by skills and hooks.
#
# How & Why: Extracted from CLAUDE-THEAGENCY.md "Testing & Quality Discipline"
# section (lines 539-587), including the Enforcement Triangle, Enforcement
# Ladder, and "When something fails" rules. These are the quality values and
# enforcement model that every agent must follow.
#
# Written: 2026-04-12 during devex session (CLAUDE.md bootloader refactoring)

## Testing & Quality Discipline

**We fix things. We don't work around them. There are no small bugs — just fix it.**

- **Fix what you find** — don't defer nits. Dead code, stale config, broken patterns — fix in the same pass.
- **No silent failures** — fail loudly or handle explicitly. If you suppress an error, comment why.
- **No unactionable noise** — every warning must trigger action or get fixed at the source.
- **Verify, don't assume** — read the docs, check the data, debug with evidence. Don't cargo-cult patterns.
- **Enforce conventions mechanically** — hooks and rules, not prose. Prose gets forgotten.

### The Enforcement Triangle

The Triangle is the **per-capability structural pattern**. Every Agency capability has three parts that work together:

| Layer | What | Why |
|-------|------|-----|
| **Tool** (bash, `claude/tools/`) | Does the work. Pre-approved in `settings.json`. | Permissions. No prompts for approved operations. |
| **Skill** (markdown, `.claude/skills/`) | Tells the agent when and how to use the tool. | Discovery. Agents find it via `/` autocomplete. |
| **Hookify rule** (`claude/hookify/`) | Blocks the raw alternative. Points to the skill. | Compliance. Can't bypass. |

When building a new capability: build the tool, wrap it in a skill, block the raw alternative with a hookify rule. All three. Not one, not two. The tool handles permissions, the skill handles discovery, the hookify rule handles compliance. *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*

**Full enforcement model:** See `claude/README-ENFORCEMENT.md` for the complete reference — Triangle, Ladder, lifecycle hooks, all 36 hookify rules, quality gate tiers, and the permission model. When a hookify rule blocks you, look it up in the README-ENFORCEMENT.md tables to understand what to do instead.

### The Enforcement Ladder

The Ladder is the **per-capability adoption progression**. Different capabilities are at different ladder steps. New capabilities start at step 1 and progress as they mature:

1. **Document** — write it in CLAUDE-THEAGENCY.md or a referenced doc. Human-readable, no tooling required.
2. **Skill** — wrap the documented process in an invocable skill. Discovery via `/` autocomplete.
3. **Tool** — build the mechanical capability. Pre-approved in settings.json.
4. **Hookify warn** — warn when the tool is bypassed. Points to the skill.
5. **Hookify block** — hard enforcement. Can't bypass.

**Triangle vs Ladder:** The Triangle is the *structure* (tool + skill + hookify). The Ladder is the *progression* (how a capability moves from documented to fully enforced). A capability at step 5 has all three Triangle parts; a capability at step 1 has only docs.

**The ladder is per-capability, not framework-wide.** Mature capabilities like `git-safe-commit` and `handoff` are at step 5 (block enforced). Newer methodology patterns like Valueflow, MAR, and the three-bucket triage are at step 1 — documented, but not yet skill-wrapped or enforced. Each capability progresses up the ladder as it matures.

- **No stale artifacts** — unused config, orphaned files, outdated docs — delete or update. Version control remembers.

### When Something Fails

**The blocker IS the work.** Do not skip, disable, or work around failing tests, hooks, or checks.

- **Never propose `--no-verify`, `eslint-disable`, `@ts-ignore`, or "fix later."** Find and fix the underlying issue.
- **Fix flakes.** Diagnose non-determinism (timing, state leakage) and eliminate it.
- **Fix infrastructure.** Don't code around missing tools or broken paths — configure them correctly.
- **Re-read after lint/format.** Linters rewrite files. Your in-memory copy is stale after lint-staged runs.
- **Always read before write.** Never Edit or Write a file you haven't Read in this conversation.
- **Consult before acting on failures.** Diagnose first, propose a fix second, act only with approval.
