---
name: block-cd-outside-worktree
enabled: true
event: bash
pattern: (^|;|&&|\|\|)\s*cd(\s+(/|~|\.\.|-|\$HOME|\$\{HOME\})|\s*$|\s*&&|\s*\|\||\s*;)
exclude_pattern: cd "?\$\(pwd\)"?
action: block
---

**BLOCKED: `cd` outside your worktree.**

Worktree agents must stay in their worktree. When you `cd` outside, the next
git-aware tool reads the new directory's git context — `agent-identity` may
resolve to the wrong agent, and tools write to the wrong place.

This rule blocks the cd patterns that escape (or might escape) the worktree:

| Pattern | Blocked because |
|---------|-----------------|
| `cd` (no args) | Goes to `$HOME` — outside worktree |
| `cd /any/abs/path` | Absolute path — usually outside worktree |
| `cd ~/...` | Home expansion — outside worktree |
| `cd ..` | Parent of worktree root escapes |
| `cd -` | Previous directory — can't track |
| `cd $HOME/...` | Variable expansion to outside |
| `cd path && tool` | Compound — escapes via the cd half |

**Relative cd inside the worktree is allowed:**
- `cd subdir` — fine, stays inside
- `cd ./subdir` — fine
- `cd "$(pwd)"` — explicit no-op (excluded)

**The right ways to read or operate on files outside your worktree:**

- Use the **Read tool** with an absolute path — doesn't change CWD
- Use **`git -C /other/repo <command>`** for ops on other repos
- Use **absolute paths** in commands that need external files
- Use **subshell isolation** for legitimate cases: `(cd /target && tool)` —
  the cd is scoped to the subshell and the parent CWD is preserved

**Combined with #114 Rule 1:** the compound form `cd path && tool` is the
most common offender (it broke identity resolution multiple times). This
rule handles bare cd, compound cd, and the dangerous variants in one place.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
