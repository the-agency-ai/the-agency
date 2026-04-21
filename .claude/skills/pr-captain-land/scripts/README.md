# scripts/

## `pr-captain-land`

Bash script that implements the 9-step land protocol. Invoked by the skill's Flow.

### Entry point

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/skills/pr-captain-land/scripts/pr-captain-land" <agent-branch> [flags]
```

### Security hardening (MAR fixes applied `ccf054ad`)

Two security findings from the comprehensive MAR were fixed in-place on this script and must be preserved across any refactor:

1. **Python code injection in manifest version-bump** (F-SEC-1 / CRITICAL-3): the original implementation used Python f-string interpolation with shell-sourced values (`f"""... {NEW_VER} ..."""`), which allowed branch-name-adversarial version bumps to inject Python code. **Fixed** by passing values as environment variables and accessing them via `os.environ`:

   ```bash
   MANIFEST="$MANIFEST" NEW_VER="$NEW_VER" python3 -c '
     import json, os, sys
     path = os.environ["MANIFEST"]
     new_ver = os.environ["NEW_VER"]
     ...
   '
   ```

   Any future refactor MUST preserve the env-var pattern. Do NOT re-introduce f-string interpolation of shell values.

2. **Unvalidated `$AGENT_BRANCH` flowing into git/gh/dispatch** (F-SEC-2): the original implementation accepted branch names verbatim. **Fixed** by a regex gate at the top of the script:

   ```bash
   if ! [[ "$AGENT_BRANCH" =~ ^[a-zA-Z0-9][a-zA-Z0-9/_.-]*$ ]]; then
     echo "ERROR: Invalid branch name" >&2; exit 1
   fi
   # Also reject '..' and leading '-'
   ```

   Any future refactor MUST preserve the validation. Add, don't relax.

### What it does

Implements the 9 steps from the skill's Flow:

1. Preflight — checks main-checkout + branch=master + clean tree + remote-branch exists + branch-name-valid + receipt-found
2. Switch to agent branch via `git-captain switch-branch`
3. Verify receipt against current diff-hash
4. Bump `agency_version` (security-hardened per above), commit, push
5. Create PR via `pr-create`
6. Switch back to master
7. Watch CI (poll `gh pr view --json statusCheckRollup` every 20s, max 30 attempts)
8. Merge via `pr-merge --principal-approved` + `gh-release create v{new}`
9. Dispatch agent with `master-updated` + PR URL + release URL

### Exit codes

- `0` — land complete (merge succeeded; release + dispatch may have warned)
- `1` — precondition / state error (preflight, receipt mismatch, CI fail, CI timeout, merge fail)
- `2` — tool composition error (gh/git-captain/dispatch unavailable)

### Related

- `../SKILL.md` — the skill definition
- `../reference.md` — full step-by-step protocol + recovery flows
- `../examples.md` — happy-path + failure-mode examples
- `ccf054ad` — the commit that applied the two security fixes documented above
- the-agency#314 — upstream package MAR summary

## Why a script, not inline skill instructions

Nine sequential steps with conditional branching, CI polling loops, and multi-tool composition is beyond reliable inline execution. The script enforces the exact sequence and provides single-entry atomic invocation.
