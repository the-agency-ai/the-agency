---
name: compound-bash-block
enabled: true
event: bash
pattern: (\s|^)(&&|\|\||;|\|)(\s|$)|\$\(|`[^`]*`|cd\s+[^;]+&&
action: block
---

**BLOCKED: Compound bash commands are not allowed.**

You wrote a bash command with `&&`, `||`, `;`, `|`, `$(…)`, backticks, or `cd X && …`. Every one of those is a compound construct that must be split into separate Bash tool calls — or replaced with a purpose-built Agency tool.

## Why this is a hard block

1. **Permission-prompt noise.** Claude Code parses compound commands and prompts for permission on every segment. `cd foo && bar && cd -` can fire three prompts. Every compound command is a multiplier on friction. Splitting into separate Bash calls triggers one prompt per call, and many tools are pre-approved already.

2. **State leakage.** `cd foo && bar && cd -` forgets `cd -` half the time. The parent shell parks in `foo` and every subsequent command runs in the wrong directory. Agent identity (which is resolved via CWD) then resolves wrong, handoffs write to the wrong agent's file, and dispatches go to the wrong inbox. This is not hypothetical — it has happened in captain sessions and produced real bugs.

3. **Observability loss.** Each Agency tool logs its runs via `log_start` / `log_end`. A compound command is opaque — the telemetry sees one `bash` call, not the three things that happened inside it. We lose the audit trail at the exact point we need it most (when something breaks).

4. **Bypass of the tool ecosystem.** Many compound patterns exist because the agent didn't know there's already a purpose-built tool. `grep foo | head` should be a single `Grep` tool call with `head_limit`. `cd repo && git status` should be `./agency/tools/run-in repo -- git status`. The block forces you to find the right primitive instead of papering over with shell plumbing.

5. **Hermeticity for tests and subprocess correctness.** `$(…)` and backticks run a subshell that inherits environment, which can leak env vars into BATS tests or other sensitive contexts. Splitting the work into explicit steps keeps every subprocess boundary visible.

## What to do instead

| You wanted to write… | Use instead |
|----------------------|-------------|
| `cd X && cmd`        | `./agency/tools/run-in X -- cmd` |
| `cd X && cmd && cd -`| `./agency/tools/run-in X -- cmd` (parent CWD never changes — no restore needed) |
| `cmd1 && cmd2`       | Two separate Bash tool calls (parallel if independent, sequential if dependent) |
| `cmd1 ; cmd2`        | Two separate Bash tool calls |
| `cmd \| head`        | Grep tool with `head_limit`, or separate `cmd` + Read |
| `cmd \| grep foo`    | Grep tool directly |
| `grep x \| xargs y`  | Separate steps, or a dedicated Agency tool |
| `$(cmd)` substitution| Run `cmd` first in one call, capture the value, pass to the next call |
| `` `cmd` `` backticks| Same as `$(…)` — split into steps |

## Related

- Tool: `agency/tools/run-in` (replacement for the `cd X && cmd` pattern)
- Skill: `/run-in`
- Reference: `agency/REFERENCE-PROVENANCE-HEADERS.md`
- Companion workstream: telemetry analysis of compound command patterns (flag #54) — mines the log of compound command attempts to identify which OTHER patterns deserve their own purpose-built tool

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
