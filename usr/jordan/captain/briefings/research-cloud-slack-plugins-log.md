# Research log — Cloud / Slack tag / plugins

**Purpose:** accumulating research trail for the two design directions in CLAUDE.md (Claude Cloud runtime + Slack tag; plugin packaging). Per principal direction (2026-09-28): *verify what the platform actually does before designing against it; research over time; do not assume.* Everything here is a **finding to verify**, dated and sourced — not doctrine. Re-check against live docs before relying on any single point (Cloud/Tag are beta and moving).

---

## Pass 1 — 2026-09-28 · external contracts (docs sweep, cited to code.claude.com / platform.claude.com / claude.com)

### Plugins (Claude Code)
- **Manifest:** `.claude-plugin/plugin.json`. Required: `name`, `author.name`. Optional: `version`, `description`, `dependencies`, `userConfig`, and component paths (`commands`, `skills`, `agents`, `hooks`, `mcp`).
- **Can bundle:** skills (`skills/<n>/SKILL.md`), commands (`commands/*.md`), agents (`agents/*.md`), hooks (`hooks/hooks.json`), MCP servers (`.mcp.json`), and **bash tools in a subdir** referenced via **`${CLAUDE_PLUGIN_ROOT}`** (e.g. `bash ${CLAUDE_PLUGIN_ROOT}/tools/x.sh`). Tools are NOT auto-added to PATH — full path required.
- **Hooks in plugins:** `hooks/hooks.json`, same schema as `.claude/settings.json` hooks; supports PreToolUse/PostToolUse/SessionStart/SessionEnd with matchers; runs shell commands. → our hookify wiring is plausibly portable.
- **Install:** installed to `~/.claude/plugins/<n>/` (user) or `.claude/plugins/<n>/` (project). `claude plugin marketplace add <owner/repo>` then `claude plugin install <n>@<marketplace>`.
- **Marketplace:** `.claude-plugin/marketplace.json` (`name`, `owner.name`, `plugins[]`); each entry has `source` (relative path / github / git-subdir / url / archive / npm / command). One marketplace can list many plugins (installed individually). `--plugin-dir ./folder` loads a folder of plugins (v2.1.265+).
- **Limits:** bundled repos capped ~100 MB. No documented per-plugin sandboxing (hooks run in session bash context). `claude plugin validate --strict` checks the manifest.

### Cloud sessions (claude.ai/code, `claude --cloud`, routines)
- Ephemeral sandbox; working dir `/tmp/workspace`; **repo cloned from remote at session start**; edits persist **only if committed + pushed** before idle. Sandbox released ~5 min after quiet; conversation history persists server-side.
- **Git available; worktrees NOT documented as supported** (single-branch checkout).
- **Project `.claude/settings.json` command hooks DO run** in cloud sessions (in the cloud VM).
- **No long-lived background processes / monitors** — timeouts + sandbox release. Recurring work → **routines** (scheduled sessions), each a fresh sandbox.
- Auth: GitHub via proxy (GitHub App or `/web-setup` gh token); API credentials Pro/Max only (not Team/Enterprise yet); SSH/signing keys not in sandbox; OAuth MCP servers may not work.
- Per-scope **cloud environment**: setup script (cached), env vars, network access level, credentials.

### Managed Agents (API — distinct from Cloud sessions)
- Stateful, long-running agent instances via API; **persistent filesystem + working dir across turns**, git available, sessions can run hours/days. Built-in Bash/file/web/MCP tools. JSON/SSE, no terminal UI. Beta (`managed-agents-2026-04-01`). → the one runtime that resembles our persistent-fleet model.

### Claude Tag (Claude in Slack)
- **Team/Enterprise only.** Ephemeral sandbox per task (like Cloud); repo cloned on-demand; runs as **agent/service identity**; PRs authored by the Claude GitHub App.
- **Skills/agents must be packaged as a PLUGIN to be discoverable** — bare `.claude/skills/` in a repo are NOT auto-available in Tag (unlike local). Alt: admin-configured "skills repository", or in-channel custom instructions.
- **Project settings.json hooks do NOT auto-run in Tag** — hook logic must live in plugin skills or instructions.
- Channel/workspace memory persists; threads are independent sandboxes; no persistent FS between runs.
- Setup: `/install-slack-app` → pairing code → org Owner pairs in admin settings.

### The load-bearing linkage
**Plugin packaging (Direction 2) is effectively the prerequisite for the Slack-tag path (Direction 1):** Tag only discovers skills/agents delivered as a plugin, and does not run project settings.json hooks. So "usable via @claude in Slack" ⇒ "packaged as a plugin whose hooks live in hooks/hooks.json." The two directions are one dependency chain, not parallel tracks.

### Open unknowns (carry forward — verify next passes)
- Per-plugin bash sandboxing / restrictions: undocumented.
- Whether Managed Agents can load Claude Code plugins: unclear.
- Exact hook behavior/limits inside Tag: only "not auto-available" is documented.
- Fate of our SQLite ISCP + worktree fleet + long-lived monitors under ephemeral sandboxes: needs the coupling audit (pass 2, pending) + hands-on verification.

---

## Pass 2 — 2026-09-28 · local-first coupling audit of the-agency (Explore, cited to file paths)

**Theme:** the-agency's messaging, identity, and fleet model rest on a **persistent, shared, local filesystem + a human at a terminal**. That substrate is exactly what ephemeral Cloud/Tag sandboxes remove. Plugin *packaging* is mechanically plausible; the *runtime assumptions* are the hard part.

**The 10 hardest coupling points (verify before designing against):**
1. **ISCP DB at `$HOME/.agency/$repo/iscp.db`** (`agency/tools/lib/_iscp-db:415-444`) — persistent shared SQLite is the spine of flags/dispatches/notifications. No persistent `$HOME` in ephemeral cloud → async state evaporates. Only seam: `ISCP_DB_PATH` (tests only). *Hardest.*
2. **Identity-by-branch-and-CWD** (`agency/tools/agent-identity`) — main→captain, worktree-slug→agent. Headless single-branch run → ambiguous identity → misrouted dispatches/handoffs.
3. **Worktree fleet model** (`.claude/worktrees/`, `worktree-*`, `git-captain`, `captain-sync-all`) — presumes N co-located worktrees + captain reconciling master. No analog in a single-shot checkout. Biggest conceptual rethink.
4. **`$SCRIPT_DIR/../..` root-layout math + `settings.json` `$CLAUDE_PROJECT_DIR/agency/...` hook paths** — ~120 tools + every hook assume vendored two-levels-under-root layout. Plugin-relative (`${CLAUDE_PLUGIN_ROOT}`) paths break this everywhere at once.
5. **File-copy installer** (`agency/tools/lib/_agency-init`) — vendors the whole framework into each repo, re-copies on `update`. Opposite of a referenced plugin; the direction says plugin should "augment" this.
6. **Persistent monitors + PID registry** (`dispatch-monitor`, `issue-monitor while true`, `ghostty-state-watchdog`, `monitor-register`→`agency/config/monitor-pids.json`) — assume a session outliving a request, re-attach by local PID. Cloud is request-scoped/event-pushed.
7. **Interactive auth/consent gates** — vault passphrase + gh token via `secret-vault`; `pr-merge --principal-approved`; 1B1/discuss skills (`define`/`design`/`discuss`/`flag-triage`). All assume a human present to unlock/approve/converse; async Slack @claude would deadlock or needs redesign (pre-injected secrets / async approval).
8. **TTY/terminal integration** (`ghostty-status.sh` guards on `TERM_PROGRAM`/`/dev/tty`, 8 ghostty tools, `idle-mail-check.sh`, `statusLine`) — zero works headless; degrades to silent no-ops (safe), but the awareness UX has no cloud replacement.
9. **Cross-repo collaboration via co-resident checkouts** (`agency/tools/collaboration`, `agency.yaml collaboration.repos: ~/code/collaboration-monofolk`) — git push/pull between sibling repos on one disk.
10. **src ↔ root mirror ambiguity** — runtime executes root `agency/`+`.claude/`; shippable payload is `src/`; a port must pick an authoritative tree and reconcile the `../..` path math, or plugin builds and live dogfooding diverge.

**Hookify detail:** two layers — native hooks in `.claude/settings.json` (SessionStart/PreToolUse/PostToolUse/etc.) invoking `$CLAUDE_PROJECT_DIR/agency/hooks/*.sh` + `tools/*`, and 41 markdown rules in `agency/hookify/` interpreted by `agency/hooks/block-raw-tools.sh` (the official hookify plugin is *disabled*; enforcement is hand-rolled). Portable in principle to `hooks/hooks.json`, but all paths are checkout-relative today.

---

## Cross-pass synthesis (2026-09-28)
- **The two directions are one dependency chain:** Tag discovers only plugin-delivered skills/agents and won't run project `settings.json` hooks → **plugin packaging is the prerequisite for the Slack path.**
- **Two separable layers of work:**
  - **(A) Packaging** — bundle skills/commands/agents/hooks/tools as a plugin, move `settings.json` hooks → `hooks/hooks.json`, replace `$SCRIPT_DIR/../..` with `${CLAUDE_PLUGIN_ROOT}`, pick the authoritative tree (`src/`). *Mostly mechanical; verify plugin capabilities hands-on.*
  - **(B) Runtime portability** — the ephemeral-sandbox mismatch: ISCP DB substrate, identity model, fleet, monitors, interactive gates. *Conceptual redesign; the real depth.*
- **Layer A is largely a prerequisite for testing Layer B** and delivers standalone value (easier install) even if the fleet never runs in cloud.
- **Managed Agents (API)** is the only surveyed runtime with a persistent FS + long-running model resembling our fleet — worth a dedicated research pass before assuming Cloud/Tag ephemerality is the only cloud shape.
- **Open, to verify hands-on:** does a plugin's `hooks/hooks.json` fire the same way our `block-raw-tools.sh` enforcement does? Can `${CLAUDE_PLUGIN_ROOT}` tools resolve the repo-under-test? What actually survives a Cloud session boundary for a repo like ours?
