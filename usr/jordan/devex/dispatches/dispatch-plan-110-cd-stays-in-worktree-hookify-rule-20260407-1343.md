---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-07T05:43
status: created
priority: normal
subject: "PLAN #110: cd-stays-in-worktree hookify rule"
in_reply_to: 110
---

# PLAN #110: cd-stays-in-worktree hookify rule

## Investigation

### Existing rule
`agency/hookify/hookify.block-cd-to-main.md` blocks the specific case: `cd /Users/...` or `cd ~/` or `cd $HOME` followed by `&&`. Doesn't catch:
- `cd /tmp/foo`
- `cd ../sibling-worktree`
- `cd $HOME/code/somewhere` without `&&`
- `cd ..` from worktree root

### Worktree detection
Inside a worktree, `git rev-parse --show-toplevel` returns the worktree path (`.claude/worktrees/devex`), not the main repo. This is the canonical "my worktree root" value. The hookify rule can compute this once.

## Proposed Design

### Layer 1: SessionStart hook check (small, fast)

Add to `agency/tools/iscp-check` (already runs at SessionStart) OR new tool `agency/tools/worktree-cwd-check`:

```bash
# Verify CWD is inside the current worktree's root
WORKTREE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -n "$WORKTREE_ROOT" && "$PWD" != "$WORKTREE_ROOT"* ]]; then
    cat <<EOF >&2
WARNING: launched in $PWD but worktree is $WORKTREE_ROOT.
You should cd to the worktree before running tools, or your agent will write to the wrong place.
EOF
fi
```

**Why a tool, not inline in iscp-check:** keeps responsibilities separate, easier to test, easier to add to other hooks later.

### Layer 2: PreToolUse hookify rule (the main protection)

New file: `agency/hookify/hookify.cd-stays-in-worktree.md`

```markdown
---
trigger: PreToolUse
matcher: Bash
---

# Block: cd outside worktree

If the Bash command starts with `cd ` (or contains `&& cd `), parse the cd target and BLOCK if it would take you outside the current worktree.

The current worktree root is `git rev-parse --show-toplevel`. Any cd target that resolves to a path NOT starting with that root is blocked.

**Rules for resolution:**
- `cd <abs-path>` → use as-is
- `cd ~/<path>` → expand to $HOME/<path>
- `cd $VAR/<path>` → expand variable, then resolve
- `cd <rel-path>` → resolve relative to current shell pwd
- `cd ..` → parent of current pwd
- `cd` (no args) → $HOME → BLOCK
- `cd -` → previous dir → ALLOW (we don't track it; risk acceptable)
- `cd "$(pwd)"` → no-op → ALLOW
- `cd "$BATS_TEST_TMPDIR/..."` → BATS context, but this only fires inside test runs which use `bats` not raw `cd` calls

**Block message:**
> Blocked: 'cd /tmp/foo' would take you outside your worktree ($WORKTREE_ROOT).
> Worktree agents must stay in their worktree. Use absolute paths to read files outside, or use Read tool which doesn't change CWD.
> *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
```

### Layer 1 + Layer 2 interaction

- Layer 1 catches the case where the agent was LAUNCHED in the wrong directory (not their fault)
- Layer 2 catches the case where the agent runs `cd` mid-session (their action)
- Layer 1 is informational only (warn), Layer 2 is blocking
- Existing block-cd-to-main stays as a more specific rule (kicks in first if matched)

## Edge cases

| Pattern | Decision | Reason |
|---------|----------|--------|
| `cd` (bare) | BLOCK | Goes to $HOME |
| `cd -` | ALLOW | Can't track previous dir; rare |
| `cd .` | ALLOW | No-op |
| `cd ./subdir` | Check resolution | Should be inside worktree |
| `cd ../sibling` | Check resolution | Likely outside; usually BLOCK |
| `cd /tmp/foo` | BLOCK | Outside worktree |
| `cd "$(pwd)"` | ALLOW | No-op |
| `cd ~` | BLOCK | $HOME outside worktree |
| `cd /Users/jdm/code/the-agency` | BLOCK | Main repo (also caught by existing rule) |
| `cd /Users/jdm/code/the-agency/.claude/worktrees/devex/subdir` | ALLOW (if I am devex) | Inside my worktree |

## Risks

- **False positives:** Some legitimate workflows might cd to /tmp for scratch work. Mitigation: document the escape hatch (`SKIP_HOOKIFY=1` or whatever pattern we use, if any). Otherwise tell agents to use Read with absolute paths.
- **Hookify rule complexity:** Resolving `$VAR` expansions in a regex-style hookify rule is hard. May need to be permissive (allow if can't resolve confidently).
- **Performance:** Hookify rules fire on every Bash call. Should be fast — `git rev-parse` is sub-millisecond.

## Estimated work
- Layer 1 tool: 30 min (with tests)
- Layer 2 hookify rule: 45 min (markdown + edge case verification)
- Documentation update in CLAUDE-THEAGENCY.md: 10 min
- Add to enforcement.yaml registry: 5 min
- **Total: ~1.5 hours**

## Open questions for you
1. **Tool placement for Layer 1:** standalone `worktree-cwd-check` OR add to `iscp-check` OR add to a new general `session-checks` umbrella?
2. **Block vs warn for `cd ..`?** This is a common navigation pattern but takes you out of worktree if you're at the worktree root. Block is correct but pedantic.
3. **Escape hatch?** Some rare cases (running tools that need /tmp, debugging) might want a way to override. Or do we say "no escape, use absolute paths"?
4. **Pair with #109?** Should I do these in sequence (#109 first, then #110) or parallel? Both touch test infra, low conflict risk.

Awaiting approval to implement.
