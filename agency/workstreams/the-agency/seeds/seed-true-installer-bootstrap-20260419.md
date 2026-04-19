---
type: seed
workstream: the-agency
slug: true-installer-bootstrap
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-19
topic: "True installer — bare-repo to fully-installed + bootstrap paradox"
status: captured (for later Valueflow /define → /design → /plan pass)
next_action: "Tonight: file GH agency issue with this seed; then /discuss → /define → /design → /plan → /release"
---

# Seed — True installer + bootstrap paradox

Captured from principal's D45-R3 session directive: *"Save everything from the discussion of installer to now for later as a seed and let's solve the immediate term issues."*

## Principal's framing (verbatim)

> And then I want an agency issue to build a true installer. We can capture it as a seed, but I want to do this tonight.
>
> We have an interesting situation here:
> **We use the-agency to build the agency**
> **We are bootstrapping.**
>
> Which means that we both need to have our source code in the-agency repo as well as have it "installed" so it can be used by us.
> So, when we update a skill or create a new skill, we need to edit it in the source tree and then we need to install it for execution by claude.
>
> This a bare repo install of the agency should have:
> - `.claude/`
>   - with whatever is installed in there by claude and then by us.
>   - Layout what you think it should have.
>   - in the case of andrew-demo, I think it is not fully installed, because there is only an "agents" nothing else.
> - `agency/`
>   - What is currently `claude/`
> - `CLAUDE.MD`
> - `LICENSE.MD`
> - `usr/`
>
> Am I missing anything?
>
> If I clone the-agency, I would expect to have:
> - `.agency`
> - `.agency-setup-complete`
> - `.claude`
> - `.git`
> - …
> - `agency/`
> - `apps/`
> - `CHANGELOG.md`
> - `CLAUDE.MD`
> - `CODE-OF-CONDUCT.MD`
> - `CONTRIBUTING.MD`
> - `history/`
> - `LICENSE.MD`
> - `README.MD`
> - `tests/`
> - `src/`
> - `usr/`
>
> **src/ should have the source code for all of our commands, agents, subagents, skills, etc.**
>
> A git clone (even shallow) is different from what you get when you do an `agency init`.

## Core insight — the bootstrap paradox

The-agency is built USING the-agency. This creates a "live source ↔ installed copy" duality that no ordinary framework has to manage:

- **For adopters:** `agency init` installs framework content INTO their project. Their `claude/` (future `agency/`) is a frozen snapshot at install time; they use `agency update` to pull changes.
- **For the-agency itself (us):** our `claude/` tree is BOTH the source-of-truth and the live-in-use copy. We edit a skill → it IS the skill. We don't separately "install" it.

This works today only because we don't HAVE a separate installed copy — our source IS the installed copy. But it produces several structural gaps:

- Adopters and the-agency have different mental models of where their skills/hooks/commands live
- When we create a skill in `.claude/skills/`, we're editing the INSTALLED location, not the source — there's no source at all for these
- Agents/subagents live in `claude/agents/` but Claude Code expects `.claude/agents/` — we don't ship the bridge (see issue #324)
- `CLAUDE.md` at repo root should point at the framework — but we auto-generate a stub (#325)
- Framework-internal docs ship to adopters because there's no install manifest (#287)

## Proposed target structure — bare-clone of the-agency

```
the-agency/                              # repo root
├── .agency                              # marker: "this is an agency repo"
├── .agency-setup-complete               # marker: "setup has been run"
├── .claude/                             # Claude Code private area
│   ├── settings.json                    # hooks, permissions, statusline
│   ├── skills/                          # INSTALLED skills (auto-discoverable)
│   ├── commands/                        # INSTALLED commands
│   └── agents/                          # INSTALLED agent registrations
├── .git/                                # (standard)
├── agency/                              # FRAMEWORK (currently at claude/)
│   ├── tools/                           # framework tools (safe-tools family)
│   ├── hooks/                           # framework hook scripts
│   ├── hookify/                         # framework enforcement rule docs
│   ├── templates/                       # scaffolding templates
│   ├── config/                          # manifest.json, agency.yaml
│   ├── workstreams/                     # framework-level workstreams
│   └── REFERENCE-*.md                   # framework reference docs
├── apps/                                # application code (mdpal, etc.)
├── src/                                 # SOURCE for skills/agents/commands (NEW)
│   ├── skills/                          # canonical source of each v2 skill bundle
│   ├── commands/                        # canonical source of each command
│   ├── agents/                          # canonical source of agent classes
│   └── hooks/                           # canonical source of hook scripts
├── tests/                               # framework + app tests
├── usr/                                 # principal sandboxes
├── history/                             # archived framework artifacts
├── CLAUDE.md                            # top-level CLAUDE.md
├── LICENSE.md
├── CHANGELOG.md
├── CODE-OF-CONDUCT.md
├── CONTRIBUTING.md
└── README.md
```

### Key architectural addition: `src/` as the source-of-truth

New convention: **edit in `src/`, install to `.claude/` or `agency/`.** The install step copies (or symlinks) source → installed. Same mechanism used by `agency init` for adopters is now used by the-agency itself for our own bootstrap.

For skills specifically (per v2 methodology from PR #309):

- **Source:** `src/skills/<name>/SKILL.md` + `reference.md` + `examples.md` + `scripts/` + `assets/`
- **Installed:** `.claude/skills/<name>/` (Claude Code's discovery path)
- **Install step:** copy or symlink `src/skills/<name>/` → `.claude/skills/<name>/`

For the-agency itself, this means every skill edit becomes a two-step flow: edit in `src/`, run `agency install` (or watch mode) to reflect in `.claude/`.

### What `agency init` vs `git clone` should produce

**`git clone the-agency-ai/the-agency`** (developer of the framework):
- Everything in the layout above
- Framework is live, source is visible, agents can develop framework skills directly

**`agency init` on an adopter's project** (user of the framework):
- A **SUBSET** — adopter-facing manifest only:
  - `.claude/` with installed skills + commands + agents from the framework
  - `agency/` with framework tools (read-only-ish, updated via `agency update`)
  - `CLAUDE.md` template rewritten with project context
  - `usr/<principal>/` scaffolded
  - NO `src/` — adopters don't need the source (they extend via their own `usr/<p>/<a>/tools/` sandbox or propose back upstream)
  - NO framework-internal docs, history, tests, apps
- Install manifest declares which files/dirs are adopter-facing vs framework-internal

## Why this matters — issues this seed addresses

This seed is the structural answer to:

- **#287** — The "real installer" gap. The manifest becomes the source-of-truth for what adopters get.
- **#324** — `.claude/agents/` missing after init. The install step populates `.claude/agents/` from `src/agents/` (or from the framework's agent class definitions).
- **#325** — `CLAUDE.md` placeholder stub. The install step rewrites from a template.
- **#326** — Principal/user addressing split. With `src/` as canonical source, the principal resolver can be consistent across install + framework.
- **#270** — The Great Rename (`claude/` → `agency/`). This seed is the direction #270 points at.
- **#282** — `agency init --project <name>` auto-creates unused workstream. The install step changes to respect explicit workstream creation rather than guessing.
- **the bootstrap paradox itself** — no issue number yet; this seed is the first articulation.

## Questions principal asked

> Am I missing anything?

Captain's suggested additions / considerations:

1. **Lock file** — `agency.lock.json` or similar. Records exact framework version at install, which skill versions installed, which hooks installed. Enables reproducible `agency update` + rollback.
2. **Hook-gen step** — hookify rule docs in `src/hookify/` → generated scripts in `.claude/hooks/` (or wherever settings.json references). Source is the `.md` rule; generated is the `.sh` enforcement.
3. **Separate `config/`** — agency.yaml, manifest.json live in `agency/config/` (framework-owned) but adopter overrides live in `usr/<principal>/config/` (principal-owned). Needs clear precedence rules.
4. **Principal-scope vs project-scope** — `src/` has framework source; `usr/<principal>/<agent>/tools/` has personal scripts. Does the source-installed distinction also apply to per-principal content? Probably not — principal content is already sandbox + direct-edit.
5. **Claude Code's `.claude/agents/` model** — Anthropic expects `.claude/agents/<name>.md` (flat or `{principal}/{agent}.md` per D42-R3). Install step must bridge from our `src/agents/<class>/agent.md` to Claude Code's discovery path.
6. **Install idempotency** — re-running `agency install` should be safe. Diff-based update, don't clobber user edits in `.claude/commands/` if they customized them. Requires three-way merge or manifest-driven ownership split.
7. **Version-pinning for developer vs adopter** — developers of the-agency run HEAD; adopters pin to released versions. The install step needs version awareness.

> Questions? Comments?

Captain observations:

- **The `src/` convention means we'll have a big one-time migration** — every existing `.claude/skill/*` and `claude/tools/*` gets moved to `src/` + installed copy generated. This is significant work.
- **`.claude/` becomes generated output** — should it be `.gitignore`d in the framework repo? If yes, contributors need `agency install` to run before Claude Code discovers anything. If no, source + generated both committed (drift risk).
- **The `src/` + `.claude/` duality is analogous to source + `node_modules/`** — in many frameworks `node_modules/` is generated + gitignored. Should our `.claude/` behave the same? That would invert the current model.
- **Fleet implications** — every worktree currently has `.claude/` copy because `worktree-sync` syncs it. If `.claude/` becomes generated-from-src, worktree-sync runs the install step instead of copying.
- **Testing implications** — skill changes would have source-side tests + install-step validation. Current test runner runs against installed location; after the migration, tests should exercise source.

## Principal's design direction (added 2026-04-19 T18:40)

> **RE: Installer** — *"I suggest we have a yaml file that describes where to find items and where to put them and use that to drive creation of directories and rsync operations or some such."*

**Manifest-driven install** — the yaml becomes the single source-of-truth for:

- **Source locations** — where each installable thing lives in the framework tree (e.g., `src/skills/<name>/`, `src/agents/<class>/agent.md`, `src/hooks/<name>.sh`)
- **Destination locations** — where it lands in the target (e.g., `.claude/skills/<name>/`, `.claude/agents/<principal>/<agent>.md`, `claude/hooks/<name>.sh`)
- **Install operation** — copy vs symlink vs rsync vs template-expand
- **Scope** — `framework-dev` (the-agency clone), `adopter` (agency init target), `both`
- **Ownership** — framework-owned (never overwrite user edits) vs user-owned (preserve user customizations)
- **Version / pinning** — per-entry minimum framework version required

### Example manifest shape (captain strawman)

```yaml
# agency/install-manifest.yaml (or similar)
version: 1
entries:
  - id: skill.fleet-report
    kind: skill
    source: src/skills/fleet-report/
    destination: .claude/skills/fleet-report/
    op: rsync                     # rsync --delete-excluded (respect user-owned files per ownership rules)
    scope: [framework-dev, adopter]
    ownership: framework           # re-install clobbers (user customizes via usr/*/tools/ sandbox instead)
    min_framework_version: "45.2"

  - id: hook.block-raw-tools
    kind: hook
    source: src/hooks/block-raw-tools.sh
    destination: claude/hooks/block-raw-tools.sh
    op: copy
    scope: [framework-dev, adopter]
    ownership: framework

  - id: agent.captain
    kind: agent
    source: src/agents/captain/agent.md
    destination_template: ".claude/agents/{principal}/captain.md"
    op: template-expand
    scope: [framework-dev, adopter]
    ownership: principal-scoped
    template_vars: [principal, project, workstream]

  - id: settings.json
    kind: config
    source: src/config/settings.template.json
    destination: .claude/settings.json
    op: three-way-merge            # preserve user customizations on update
    scope: [adopter]
    ownership: user-owned
    merge_strategy: jq-patch       # or whatever we land on

  - id: claude-md
    kind: config
    source: src/templates/CLAUDE.md.template
    destination: CLAUDE.md
    op: template-expand            # only on init; never overwrite on update
    scope: [adopter]
    ownership: user-owned
    condition: on_init_only

  - id: workstream.{repo}
    kind: workstream
    source: src/templates/workstream/
    destination_template: "claude/workstreams/{repo}/"
    op: template-expand
    scope: [adopter]
    ownership: user-owned
    template_vars: [repo]
    condition: on_init_only
```

### Install operations

- **`copy`** — plain file copy. Framework-owned; clobbers on re-install.
- **`rsync`** — rsync with declared flags. Good for directory trees with excludes.
- **`symlink`** — for bootstrap scenario — the-agency developers want edits in `src/` to be LIVE in `.claude/` without a re-install step. `op: symlink` gives that.
- **`template-expand`** — source is a template with `{placeholders}`; installer fills from `template_vars` context. Used for CLAUDE.md, agent-per-principal registrations, workstream scaffold.
- **`three-way-merge`** — for config files like settings.json where adopters customize. Framework proposes new content, adopter's customizations survive. Merge tool (jq, yq, manual) depends on file type.

### Why this is the right design

- **Single source of truth** — one yaml describes the entire install surface. No more "wonder what agency init does" or "where should this live" — the manifest answers.
- **Testable** — CI can validate the manifest + dry-run the install. Adopter installs become reproducible.
- **Scope-aware** — same manifest drives `agency init` (adopter scope) and `agency install` / `agency sync` (framework-dev scope). One tool, one spec.
- **Ownership-aware** — clear rules for what the installer can and can't overwrite. No more clobbering user edits.
- **Upgrade path** — `agency update` reads the new manifest, diffs against installed state, applies delta. Per-entry `min_framework_version` gates which entries to touch.
- **Bootstrap-ready** — with `op: symlink` for framework-dev scope, the-agency developers get live edits without re-install loops.

### Captain additions to the manifest design

1. **Rsync flags declared per-entry** — some entries need `--delete-excluded`, some don't. Don't hardcode across the installer.
2. **Hash-based integrity check** — per-entry expected hash; re-install warns if installed state diverged (user customized a framework-owned file).
3. **Uninstall manifest entries** — when a skill is retired (e.g., `/agency-bug` this session), the manifest tombstones it so `agency update` can clean up.
4. **Preview mode** — `agency install --dry-run` reports exactly what would change before any operation.
5. **Per-adopter manifest overlay** — adopters can declare `usr/<principal>/install-overlay.yaml` that adds their own entries without modifying the framework manifest. Use case: adopter skills they built themselves.

## Principal's design direction — continuous self-install (added 2026-04-19 T18:45)

> **"And we use the installer to keep the-agency repo up to date with the latest versions (development) of the agency."**

**The installer runs against the-agency repo itself, continuously, during development.** This is the bootstrap paradox's operational answer:

- **Other frameworks:** source lives in one tree, installed copy lives in another. Clean separation.
- **The-agency:** source AND installed copy live in the SAME repo. We're both author and consumer.
- **The installer's job for the-agency repo (framework-dev scope):** edit in `src/` → installer syncs to `.claude/` → Claude Code picks up live changes → we dogfood our own changes in the same session.

### What this enables

1. **Zero-latency bootstrap** — edit a skill in `src/skills/<name>/`, run (or auto-watch) installer, skill is live for Claude Code in the same session. No "commit + reinstall + restart" loop.
2. **Guaranteed parity** — the same installer + manifest that ships to adopters is what keeps the-agency itself consistent. If the installer is wrong, we feel it first. Stops the "it works for us but not for adopters" class of bugs at the source.
3. **Continuous validation** — every framework-dev session IS an installer regression test. If the installer breaks, captain can't operate, and we fix it immediately.
4. **Single mental model** — "installer keeps installed state matching source" is true for both the-agency AND adopters. One abstraction, two audiences.

### Mechanics for framework-dev scope

- **Watch mode** — `agency install --watch` monitors `src/` + manifest, re-runs entries on change. Claude Code picks up within ~1s of a save.
- **Symlink op** — per the manifest, `op: symlink` entries bypass copy altogether — the `.claude/skills/<name>/` IS the `src/skills/<name>/` (live, always). Fastest, but requires Claude Code to tolerate symlinks in the discovery path.
- **Copy-on-change op** — `op: rsync` or `op: copy` re-runs only when source changes. Slightly slower but semantics are identical to adopter install. Good for parity testing.

### Adopter scope vs framework-dev scope — one manifest, two behaviors

The same yaml describes both. Difference is the **scope** declared per entry + any CLI flags:

- `agency install` on **adopter repo** → runs entries with scope `adopter` or `both`. Template-expand on init, three-way-merge on update. Never touches `src/` (doesn't exist in adopter repo).
- `agency install` on **the-agency repo** → runs entries with scope `framework-dev` or `both`. Symlink mode default for fast iteration. Manifest-driven.

### Captain addition

6. **Framework-dev CI should run adopter-scope install AS WELL** — `agency install --scope adopter --target /tmp/test-install` produces what an adopter would get. CI can diff that against expected output. Catches "we edited src/ but forgot to update the manifest" regressions before adopters hit them.

## Sequencing (captain recommendation)

1. **Tonight:** file agency issue capturing this seed + principal intent. Link to #287 as parent. Tag `discuss`. 
2. **Near-term:** `/discuss` session to resolve the 7 captain-identified questions above
3. **Then:** `/define` → PVR, `/design` → A&D, `/plan`, iterate, ship as a major release (framework-structure change, breaking for all adopters)
4. **Before release:** pilot migration on one skill (e.g., fleet-report since we just authored it v2) — prove source→install works end-to-end
5. **Release:** mass migration + adopter migration guide + tooling (`agency migrate-to-v2-structure`?)

## Related

- #270 Great Rename — structural precursor
- #287 real installer gap — this seed's direct parent
- #308/309/310 v2 skill methodology — informs `src/skills/` structure
- #324, #325, #326 — symptoms this seed's fix closes
- #330 session management — follows this in the queue (per principal's sequencing directive)

## Transcript context

This seed captures the principal's free-form articulation of the structural target. Preserved verbatim at the top for fidelity. Captain's analysis + questions below are captain-generated material for the /discuss session.

*Principal intent: file this as an agency issue tonight. Full Valueflow pass to follow.*
