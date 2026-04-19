---
description: Onboard a new principal to the current repo — scaffold sandbox, register agent, write CLAUDE-PRINCIPAL.md, mutate agency.yaml, bootstrap captain handoff. The discoverable end-to-end command for adding a person to an agency repo.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Principal Create

End-to-end onboarding for a new principal joining an agency-init'd repo.
Wraps `./agency/tools/principal-onboard` which orchestrates: directory
scaffold (via existing `principal-create` tool), template substitution
(CLAUDE-PRINCIPAL.md, bootstrap handoff), agent registration
(`.claude/agents/{name}-captain.md`), and `agency.yaml` mutation.

This is the discoverable workshop-day command. Without it, adding a new
principal requires hand-editing YAML, authoring captain.md from scratch,
writing a bootstrap handoff manually, and remembering all the file paths.

## When to use

- A new human principal joins an existing agency-init'd repo (peer principal).
- During `agency init` of a fresh repo, after the first principal is set up.
- Workshop demo: showing how the framework supports multi-principal.

## When NOT to use

- For a fresh project with NO principals yet — use `agency init` first, which
  bootstraps the first principal.
- For an agent (not a person) — agents are scaffolded via `workstream-create`
  or `agent-create`, not principal-create.

## Arguments

- `$ARGUMENTS`: positional principal name + flags. At minimum the name. Common shape:
  - `<name> --user <sysuser> --display-name "Display Name"`
  - Optional: `--email <addr>` (repeatable), `--github-user <handle>`,
    `--no-yaml`, `--no-agent-reg`, `--no-handoff`, `--force`, `--dry-run`,
    `--verbose`

If `$ARGUMENTS` is missing the required pieces, ask the principal for them
1B1 — name, system $USER, display name, email, GitHub username — before
invoking the tool.

## Steps

### Step 1: Pre-flight

1. Confirm we're in an agency-init'd repo: `agency/config/agency.yaml` exists.
2. If `$ARGUMENTS` is empty or missing required fields, gather via 1B1:
   - "What's the principal's slug?" (lowercase, alphanumeric/hyphens/underscores)
   - "What's their system $USER?" (the value of `echo $USER` on their machine)
   - "What's their display name?" (Unicode OK)
   - "Email address(es)?" (optional)
   - "GitHub username?" (optional)
3. Recommend `--dry-run` first to preview what will be written.

### Step 2: Dry-run preview (recommended)

Invoke:

```
./agency/tools/principal-onboard <name> --user <sysuser> --display-name "..." \
    --email ... --github-user ... --dry-run --verbose
```

Show the principal what will be written, where. Get explicit go-ahead.

### Step 3: Execute

Drop `--dry-run`. Re-run with the same args.

### Step 4: Verify

1. `cat usr/<name>/CLAUDE-PRINCIPAL.md | head -30` — confirm template substituted correctly.
2. `cat usr/<name>/captain/captain-handoff.md | head -20` — confirm bootstrap handoff readable.
3. `cat .claude/agents/<name>-captain.md` — confirm agent registration present.
4. `grep -A 4 "^  <sysuser>:" agency/config/agency.yaml` — confirm YAML entry.

### Step 5: Commit (coordination artifact)

The new principal's files are framework coordination (not application code).
Use coord-commit:

```
/coord-commit
```

(Stages CLAUDE-PRINCIPAL.md, captain-handoff.md, agent registration, agency.yaml change.)

### Step 6: Hand off to the new principal

Tell the new principal:

```
You're set up. To start working as <display_name>:

1. On your machine: export AGENCY_PRINCIPAL=<name>
2. Verify: ./agency/tools/principal  (should print <name>)
3. Launch your captain: claude --agent <name>-captain
4. In Claude, run: /session-resume
   (reads your bootstrap handoff at usr/<name>/captain/captain-handoff.md)
```

### Step 7: Cross-principal courtesy

If other principals exist on this repo, dispatch them a note that a new
peer has joined. Use `/dispatch` to send a brief intro to each existing
principal's captain:

> "<display_name> has joined the repo. Sandbox: usr/<name>/. They'll
>  introduce themselves once their captain bootstraps."

## What this skill does NOT do

- **Does not push changes to remote** — that's `/release` or `/sync` after PR review.
- **Does not configure shell on the new principal's machine** — they set
  `AGENCY_PRINCIPAL` themselves (or use `add-principal` interactively).
- **Does not migrate existing work** — if the principal had work in another
  sandbox, they move it manually.
- **Does not create workstreams or agents beyond captain** — use
  `/workstream-create` for that.

## Reference

- Tool: `agency/tools/principal-onboard`
- Templates: `agency/templates/principal-v2/`
- Schema: `agency/config/agency.yaml` (`principals:` block)
- Concept: `agency/REFERENCE-AGENT-ADDRESSING.md`
- Worknote: `claude/docs/worknotes/WORKNOTE-principal-tooling.md`

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
