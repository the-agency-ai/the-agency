---
type: handoff
agent: the-agency/jordan/captain
workstream: agency
date: 2026-04-15
trigger: session-compact
---

## Continue — Day 41 (mid-session compact, workshop-prep phase)

Extended Day 41 session. Captain has shipped 17 releases (v41.2 through v41.17), closed 8 GitHub issues, built enforcement infrastructure, and is now mid-workshop-prep for monofolk adoption workshop TODAY.

### Releases shipped today

| v | Title |
|---|---|
| 41.2 | D41-R2 post-merge tool gaps (sync-main, --remote) |
| 41.3 | D41-R3 collaboration cleanup (PR #87 + hardening) |
| 41.5 | D41-R5 monofolk QG hot patches |
| 41.10 | D41-R10 principal-onboard + agency update --from-github |
| 41.11 | devex bundle R4+R6+R7 (large-file + dirty-tree + merge-conflict family) |
| 41.12 | D41-R12 hotfix #99 (diff-hash excludes usr/**/dispatches/) |
| 41.13 | D41-R13 pr-merge triangle |
| 41.14 | mdpal-app v0.1 Phase 1A |
| 41.15 | D41-R15 bundle (settings + tests/ sync + captain agent doc) |
| 41.16 | D41-R16 agency update --prune |
| 41.17 | D41-R17 pr-create default-branch detection (#107) |

### GitHub issues closed: #94 #95 #96 #97 #99 #100 #102 #104 #107 #109

### Monofolk state
- Unblocked from #99 (diff-hash), #107 (pr-create main/master)
- All QG findings from captain D7-R1 review addressed
- secret-local clarified: their project-local, never upstreamed
- agency update --delete investigated; no --delete in current code

### Workshop TOP PRIORITY — TODAY

**Location:** `/Users/jdm/code/the-agency-group/usr/jordan/captain/workshops/monofolk-adoption-20260415/`
- `deck.md` — 35 slides, mdslidepal-web format
- `slack-pre-workshop.md` — <200 word pre-workshop Slack message
- `images/` — 8 SVGs (stack, enforcement-triangle, valueflow-pipeline, implementation-hierarchy, 5-hash-chain, 4 boundary diagrams)

**Live preview:** http://127.0.0.1:8765/index.html (mdslidepal-web server task `bjrsyv6f6`)

**Latest revision round applied** (2+ passes of principal review so far):
- Slide 6 → TheAgency feature bullet list with real counts (Commands=10, Skills=59, Tools=145)
- Slide 24 → implementation-hierarchy SVG (was ASCII)
- Slide 33 → stripped adoption path to single instruction block (no steps)
- Final slide: Agency Adoption Across OrdinaryFolk (status: monofolk—Jordan using/Peter adopting; backend/frontend/frontendv2/of-react-native—init soon)

**What's next (immediate post-compact):**
1. Principal continues reviewing deck
2. Apply any further revisions they call out
3. Workshop runs today
4. Post-workshop: principal-onboard for new monofolk principals who submit info (slug / $USER / display / email / GitHub)

### Bug queue
- 0 open framework bugs as of compact time
- #110 (git-captain --force) triaged, deferred to devex queue

### Devex queue (not yet shipped)
- R8 sandbox-sync 2 bug fixes (multi-principal blockers)
- R12 git-captain branch-name regex + branch-delete --force

### Key decisions today (must survive compact)

- **Release/PR titles**: `{github_login}-D{day}-R{release}` (e.g., `jordandm-D41-R17`)
- **Branch naming**: short — `jordan-captain-d41-r17` (no topic suffix)
- **Squash merges BANNED** — ships via `pr-merge` tool only, never `gh pr merge --squash`
- **Enforcement Triangle** pattern locked for pr-merge (skill + tool + hookify)
- **Hard attribution requirement** for any public filing (agency-issue next — D41-R18 pending)

### D41-R18 scope (not yet started)

Issue-filing enforcement triangle completion:
- Hard-inject `**Filed by:** {repo/principal/agent}` into body
- `--principal-approved` gate
- Hookify block raw `gh issue create`/`gh issue comment`
- Two skills: `/agency-issue` (framework) + `/workstream-issue` (adopter-local)
- agency.yaml schema (framework + local targets)
- Main/master hardcode audit across framework tools

Deferred until post-workshop.

### Active monitors
- Dispatch monitor (task b2m3i33by) — dispatches + cross-repo collab, ACTION REQUIRED label
- Issue monitor (task bvtq2rgry) — the-agency issues via claude/tools/issue-monitor
- Deck server (task bjrsyv6f6) — mdslidepal-web on :8765

### Open principal decisions (backlog)
- ISCP bundle sign-off (memo at `usr/jordan/captain/iscp-bundle-input-memo-20260415.md`)
- Monofolk Ring 2 transition dispatch (pending since D36)
- Claude Code Routines research (flag #123)

---

## D42-R2 scope (bundled — principal-confirmed)

- **#122** — decouple `agency_version` (framework) from `project.version` (adopter). `/release` bumps project.version; `agency update` bumps agency_version. Add project.version to manifest schema. Update release/SKILL.md + pr-create version-check.
- **#121** — codify workstream content split (shared `claude/workstreams/{W}/` vs principal `usr/{P}/{W}/`). Option B: docs + `workstream-create` scaffold update (pvr/ad/plans/seeds/research/reviews/transcripts/). Update REFERENCE-REPO-STRUCTURE.md + REFERENCE-CONTRIBUTION-MODEL.md.
- **`/secret` dedup** — `/sec` palette shows `secret` 3×. Both `.claude/commands/secret.md` and `.claude/skills/secret/SKILL.md` are registered. Skill is canonical (frontmatter + permission discipline). Delete the command file. Audit other command/skill name collisions while in there.
- **Hookify block raw `gh release create`** — rule written at `claude/hookify/hookify.block-raw-gh-release.md` (uncommitted on main, live anyway). Routes to `gh-release` tool / `/post-merge` / `/release`. Captain bypass during v42.1 was the trigger. Add tests, commit in D42-R2.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
