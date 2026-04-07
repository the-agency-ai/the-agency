---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-07T05:58
status: created
priority: normal
subject: "PLAN #122: opt-in Day/Phase commit prefix enforcement"
in_reply_to: 122
---

# PLAN #122: opt-in Day/Phase commit prefix enforcement

## Investigation

### Existing config infrastructure
- `claude/tools/config get <dot.path>` reads agency.yaml — perfect for this use case
- agency.yaml already has nested config sections (principals, project, framework, collaboration, etc.)
- No `commits:` section exists yet — clean slot
- commit-precheck does NOT currently read agency.yaml (no provider pattern dependency yet)

### Existing patterns to match
- `preview.provider`, `deploy.provider`, `secrets.provider` — string values per Captain's example
- Boolean flags exist (`collaboration.auto_sync: true`)
- I'll match the boolean pattern for the feature flag

### commit-precheck integration
- commit-precheck currently classifies staged files (docs/tool/app) and runs scoped tests
- It does NOT see the commit message — the message arrives at `git commit` time AFTER the pre-commit hook fires
- **Critical gap:** Pre-commit hooks run BEFORE the message is finalized. The message isn't available to a pre-commit hook in the standard git flow.
- Workaround options:
  - (a) Use `commit-msg` hook instead of `pre-commit` — fires after message is composed, before commit lands
  - (b) Add the check inside `claude/tools/git-commit` (the wrapper) — has access to the `-m` arg before invoking git
  - (c) Both — defense in depth

## Proposed Fix

### Part A: agency.yaml schema addition

Add to the canonical agency.yaml template:

```yaml
# Commit message conventions
commits:
  require_day_prefix: false  # opt-in: enforce 'Day N:' or 'Phase X.Y:' prefix
```

Default: `false`. Projects opt in by setting to `true`.

### Part B: prefix validator (shared lib)

Create `claude/tools/lib/_commit-prefix` (sourced library, like `_log-helper`):

```bash
# What Problem: Multiple tools need to validate commit message prefixes against
# the Day/Phase convention. Centralize the regex and the helpful error message.
#
# How & Why: Library function reads agency.yaml via the config tool, returns
# 0 if message valid (or check disabled), 1 with error to stderr if invalid.

validate_commit_prefix() {
    local message="$1"
    local first_line="${message%%$'\n'*}"

    # Read flag from agency.yaml
    local enabled
    enabled=$(./claude/tools/config get commits.require_day_prefix 2>/dev/null || echo "false")
    [[ "$enabled" != "true" ]] && return 0  # opt-in: disabled = pass

    # Allowed prefixes
    local pattern='^(Day [0-9]+|Phase [0-9]+(\.[0-9]+|\.M[0-9]+)?|Merge |Revert )'
    if [[ "$first_line" =~ $pattern ]]; then
        return 0
    fi

    # Pedagogical error message
    cat >&2 <<EOF
✗ Commit message prefix not recognized.

  First line: "$first_line"

  Expected one of:
    Day N: <summary>           e.g., "Day 32: fix worktree identity bug"
    Phase X.Y: <summary>       e.g., "Phase 1.3: rewrite commit-precheck"
    Phase X.MN: <summary>      e.g., "Phase 2.M1: docker T3 milestone"
    Merge ...                  (any merge commit, allowed unconditionally)
    Revert ...                 (any revert commit, allowed unconditionally)

  Fix: rewrite the commit message to start with one of these prefixes.
  This check is enforced because commits.require_day_prefix=true in agency.yaml.

EOF
    return 1
}
```

### Part C: integrate into git-commit tool (Option B from analysis)

Add to `claude/tools/git-commit` after message is built and before `git commit` runs:

```bash
source "$SCRIPT_DIR/lib/_commit-prefix"
if ! validate_commit_prefix "$FULL_MESSAGE"; then
    log_end "$RUN_ID" "failure" 1 0 "Commit prefix validation failed"
    exit 2
fi
```

This is the primary enforcement path because /git-commit is the canonical commit tool.

### Part D: defense in depth — commit-msg hook (Option A)

Add a `commit-msg` hook to `.git/hooks/commit-msg` (and the template installed by agency-init):

```bash
#!/bin/bash
# Validates commit message prefix when commits.require_day_prefix=true
MESSAGE=$(cat "$1")
source ./claude/tools/lib/_commit-prefix
validate_commit_prefix "$MESSAGE" || exit 1
```

This catches raw `git commit` calls that bypass /git-commit. The block-git-commit hookify already strongly discourages raw git commit, but defense in depth.

### Part E: documentation

- Update `README-THEAGENCY.md` Day-PR section with the opt-in note
- Update `README-ENFORCEMENT.md` (if exists) under commit-precheck section
- Add note in CLAUDE-THEAGENCY.md commit message section

### Part F: tests

Add to `tests/tools/git-commit.bats` (or create new `tests/tools/commit-prefix.bats`):
- Disabled (default): any prefix passes
- Enabled + valid prefix: passes
- Enabled + invalid prefix: blocks with helpful message
- Enabled + Day prefix: passes
- Enabled + Phase X.Y: passes
- Enabled + Phase X.M1: passes
- Enabled + Merge commit: passes
- Enabled + Revert commit: passes
- Multi-line message: only first line checked

## Verification

1. Implement Parts A-F
2. Set `commits.require_day_prefix: true` in agency.yaml
3. Try a bad commit (`/git-commit "fix bug"`) — should block
4. Try a good commit (`/git-commit "Day 32: fix bug"`) — should pass
5. Set the flag back to false; bad commit now passes
6. Verify commit-msg hook catches raw `git commit` (defense in depth)
7. Run all relevant BATS tests

## Risks
- **Breaking existing commits:** If we set the flag globally for the-agency, my recent commits don't follow the pattern. Recommendation: ship the feature with flag=false in this repo, document the opt-in, then flip later when we're consistent.
- **commit-msg hook conflicts:** Some projects may have existing commit-msg hooks. The agency-init installer should respect existing files or chain them.
- **Config tool dependency:** `./claude/tools/config` needs to exist and work. It does.

## Estimated work
- Part A (yaml schema): 2 min
- Part B (lib): 20 min
- Part C (git-commit integration): 10 min
- Part D (commit-msg hook): 15 min including agency-init template
- Part E (docs): 10 min
- Part F (tests): 30 min
- **Total: ~1.5 hours**

## Open questions for you
1. **Enable the flag in the-agency itself?** Yes → I should also fix recent commits to match the convention before flipping (history rewrite, same question as #109). No → ship the feature off, you flip it when ready.
2. **Revert handling:** Allow `^Revert ` unconditionally (my recommendation) or require revert to preserve original prefix?
3. **Hook chaining:** If a project already has a `.git/hooks/commit-msg`, what should agency-init do? Skip / append / refuse?
4. **Order in implementation queue:** This is plan #5 dispatched. Where does it fit relative to #109/#110/#114/#118? My proposal: #109 → #118 → #110+#114 merged → #122. #122 last because it's opt-in and lowest risk.

Awaiting approval to implement.

## Note on dispatch flow
You mentioned this is my 6th dispatch (#109, #110, #111, #114, #118, #120, this one) — but I haven't received #120. My queue shows #109, #110, #111, #112, #114, #118, #122. Either #120 is en route or it's a numbering hiccup. I'll watch for it.
