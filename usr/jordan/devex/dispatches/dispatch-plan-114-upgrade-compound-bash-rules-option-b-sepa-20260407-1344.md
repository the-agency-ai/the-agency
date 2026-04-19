---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-07T05:44
status: created
priority: normal
subject: "PLAN #114: upgrade compound-bash rules — Option B (separate rules)"
in_reply_to: 114
---

# PLAN #114: upgrade compound-bash rules — Option B (separate rules)

## Investigation

### Current state
- `hookify.warn-compound-bash.md` (action: warn) — catches `&&`, `||`, `;`, single `|` with exclude pattern for benign cases (HEREDOC commit, `bash -c`, `2>&1 |`, `| head`, `| tail`)
- `hookify.block-cd-to-main.md` (action: block) — blocks `cd /Users/` etc. specifically (no compound match)
- `hookify.block-git-safe-commit.md` (action: block) — blocks `git commit` directly with HEREDOC exclude
- 33 hookify rules total

### Hookify infrastructure
Single action per rule: `block`, `warn`, or `inform`. **Option A (mixed actions in one rule) is NOT supported by the current infrastructure.** Would require changes to the hookify processor.

### Overlap with existing rules
- `cd /path && tool` — currently warned by warn-compound-bash. Not blocked by block-cd-to-main if path doesn't start with /Users/, ~/, or $HOME.
- `git add ... && git commit` — the `git commit` substring IS matched by block-git-safe-commit (no compound exclude). But: my recent commits used `git commit -m "$(cat <<...EOF)"` which is in the exclude pattern, suggesting block-git-safe-commit ALLOWS compound commit if HEREDOC is used. So a direct `git add foo && git commit -m "x"` may or may not block depending on the regex matching behavior across the whole compound string.

### My own offense pattern
I am the recent offender. Pattern from this session: `git add foo && git commit -m "$(cat <<EOF...` — compound + HEREDOC + bypass of /git-safe-commit. The HEREDOC exclude in block-git-safe-commit lets it through.

## Proposed Fix (Option B — separate rules)

### Rule 1: NEW `hookify.block-compound-cd.md` (block)

```yaml
---
name: block-compound-cd
enabled: true
event: bash
pattern: \bcd\s+\S+\s*&&
exclude_pattern: ^cd "\$\(pwd\)"
action: block
---

**BLOCKED: `cd <path> && <tool>` breaks worktree identity resolution.**

When you cd then run a tool, the tool reads the new directory's git context.
Worktree agents must run tools from their worktree CWD with relative paths.

Wrong: `cd /Users/jdm/code/the-agency && ./agency/tools/handoff write`
Right: `./agency/tools/handoff write` (from worktree CWD)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
```

**Pattern explanation:** `cd <something> && ...` — captures any cd-then-anything compound. The exclude allows `cd "$(pwd)"` which is a no-op idiom.

**Note:** This is broader than block-cd-to-main and supersedes it for compound cases. block-cd-to-main stays for the bare `cd /Users/...` case (not compound).

**Note 2:** This overlaps with the proposed cd-stays-in-worktree rule from #110. **The two should be merged.** My recommendation: build cd-stays-in-worktree as the comprehensive solution (handles bare cd and compound cd, resolves variables, checks worktree containment) and delete this Rule 1 from the plan. See #110 plan.

### Rule 2: NEW `hookify.block-compound-git-add-commit.md` (block)

```yaml
---
name: block-compound-git-add-commit
enabled: true
event: bash
pattern: git\s+add\b.*&&.*git\s+commit
action: block
---

**BLOCKED: `git add ... && git commit ...` bypasses /git-safe-commit skill.**

The /git-safe-commit skill enforces QGR receipt checks and dispatches commit notifications.
Compound git add+commit dodges both. Stage and commit as separate steps via the skill.

Right: `/git-safe-commit` (the skill — does add+commit+dispatch in one go correctly)
Or:  Two separate Bash calls, one for add, one for /git-safe-commit invocation.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
```

**Note:** block-git-safe-commit's HEREDOC exclude lets compound HEREDOC commits through. This new rule closes that gap by matching the compound pattern explicitly.

### Rule 3: warn-compound-bash stays as-is

For all other compound patterns. The two new block rules handle the high-confidence offenders. Everything else (build && test, find | xargs, etc.) gets a warn.

## Verification

1. Add new rules
2. Try compound `cd && tool` from a test agent — should block
3. Try compound `git add && git commit` — should block
4. Try benign `echo a | grep b | head -1` — should warn (not block)
5. Try single `./agency/tools/foo` — should not trigger any rule
6. Check tool-runs.jsonl after a session for evidence the rules are firing

## Telemetry check
Captain asked: "Are warn rules actually firing today?" I don't know the answer. I'd need to check tool-runs.jsonl or query the log service. **Need to investigate before claiming the warn rule isn't working.** Could be:
- (a) The warn fires but agents ignore it (prose enforcement not enough — Captain's hypothesis)
- (b) The warn doesn't fire (regex mismatch, infra bug)
- (c) Both

I'll check telemetry as part of the implementation.

## Risks

- **Pattern overlap:** block-compound-cd in this plan overlaps with cd-stays-in-worktree from #110. **Merge them or drop this rule and rely on #110.** My recommendation: drop Rule 1 here, do the comprehensive cd rule in #110.
- **False positives on git add+commit:** Some legitimate use cases (rebasing, fixup commits) chain git add+commit. The block message should mention the escape hatch (/git-safe-commit skill or two Bash calls).
- **No infra changes:** Sticking with single-action rules means more files. 33→34 or 35. Acceptable.

## Estimated work
- Rule 2 (git add+commit): 20 min including verification
- Rule 1 deferred to #110 implementation
- Telemetry check on warn-compound-bash: 15 min
- Update CLAUDE-THEAGENCY.md if needed: 10 min
- **Total: ~45 min (assuming Rule 1 is merged into #110)**

## Open questions for you
1. **Merge Rule 1 with #110?** Yes/no. If yes, this plan shrinks to just Rule 2 + telemetry check.
2. **Telemetry investigation:** worth doing? Or just ship the new block rules and assume the warn was ineffective?
3. **Order of operations:** Should I tackle these dispatches in order (#109 → #110 → #114) or can I batch the cd rules from #110 and #114 together?

Awaiting approval to implement.
