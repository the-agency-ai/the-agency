# Transcript: Workstream & Agent Setup for MarkdownPal, MockAndMark, GTM

**Date:** 2026-03-29
**Participants:** jordan (principal), captain (agent)
**Context:** Agency 2.0 operational setup — creating workstreams and agents for three projects

---

## Background

Agency 2.0 landed on main via two PRs from the monofolk CoS session. Captain was briefed via:
- `guide-captain-agency2-transition-20260329.md`
- `guide-cos-session-briefing-20260329.md`
- `devex-tools-unification-review-20260329.md`
- `guide-secret-skill-design-20260329.md`

This session also fixed the Ghostty terminal config (switched to GitHub Light Default + JetBrains Mono 14) and ran `tools/ghostty-setup`.

## Discussion

### Workstream/Agent Setup

**jordan:** We are going to create two projects/workstreams into which I will launch agents to have the MarkdownPal and MockAndMark definition and design discussions. Why don't you tell me what you will do to make that happen? Because you are the captain here.

**captain:** Proposed plan:
1. Create workstreams via `./tools/workstream-create` for `markdown-pal` and `mock-and-mark`
2. Create agents via `./tools/agent-create` for each
3. Verify seed files are ready for `/discuss`
4. Write handoff/launch instructions

Asked about agent naming (one per project vs shared) and whether new or existing workstreams.

**jordan:** Workstream name : agent name mapping. New workstreams. Do we have any other workstreams?

**captain:** Found two existing: `housekeeping` (captain's workstream) and `gtm` (bare directory with empty KNOWLEDGE.md and two empty epic dirs).

**jordan:** Housekeeping becomes just master, managed by captain. We will need to create a formal gtm workstream as outlined above.

**captain:** Updated plan to three workstreams:
- `markdown-pal` : `markdown-pal`
- `mock-and-mark` : `mock-and-mark`
- `gtm` : `gtm`

Asked what the gtm agent's role is, what name and template.

**jordan:** Capture a transcript from here (using the transcript approach): 7-Step Tools Unification Plan. As we move this forward. Workstream name: agent name.

### Decisions Made

1. **Naming convention:** workstream name = agent name (1:1 mapping)
2. **Three workstreams created:** markdown-pal, mock-and-mark, gtm
3. **Three agents created:** markdown-pal, mock-and-mark, gtm (all generic template)
4. **housekeeping** workstream is the master workstream, managed by captain
5. **gtm** formalized from bare directory into proper workstream + agent

### Seed File Status

**markdown-pal** (`usr/jordan/markdown-pal/`):
- `markdown-pal-seed-20260329.md` — CoS session seed
- `markdown-pal-analysis-20260329.md` — CoS session analysis
- `markdown-pal-chatlog-20250310.md` — original chatlog
- `markdown-pal-cli-spec-20250310.md` — original CLI spec
- `markdown-pal-prompt-20250310.md` — original prompt

**mock-and-mark** (`usr/jordan/mock-and-mark/`):
- `mock-and-mark-seed-20260329.md` — CoS session seed
- `mock-and-mark-analysis-20260329.md` — CoS session analysis
- `mock-and-mark-chatlog-20250310.md` — original chatlog

### 7-Step Tools Unification Plan (Reference)

From `guide-cos-session-briefing-20260329.md`:

1. **Review** — audit all three tool sets (done — devex review file)
2. **Extract + formalize** — codify the framework spec from the-agency's best tools
3. **Gap analysis** — identify what the-agency is missing
4. **Update existing** — bring all tools to the formalized framework
5. **Fill gaps** — build new tools to the framework
6. **Port next-gen** — monofolk Jordan-era tools get ported
7. **Leave legacy alone** — legacy monofolk tools stay as-is

Step 1 is complete. Step 2 is next: extract + formalize the framework spec.

### Next Steps

1. **MarkdownPal PVR/A&D** — launch `./tools/myclaude markdown-pal markdown-pal`, run `/discuss` with seeds
2. **MockAndMark PVR/A&D** — launch `./tools/myclaude mock-and-mark mock-and-mark`, run `/discuss` with seeds
3. **GTM** — define scope and goals for the gtm agent
4. **Tools unification step 2** — extract + formalize the framework spec

### 1B1 Review of Setup Quality

Captain proposed a 1B1 review of 4 issues found during verification.

**Issue 1: Agent definitions are boilerplate** — All three agent.md files had placeholder text. Captain read the seed files and filled in proper purpose, responsibilities, and seed file references.

**jordan:** Confirmed captain should fill these in. Clarified agent role: run definition and design discussions, get PVR and A&D drafted, iterate through review cycles to finalize, then use plan mode to plan the project. GTM scope: definition and design for the GTM Strategy and Plan for Agency, launching with 2.0.

**Issue 2: Model says Opus 4.5** — Fixed as part of issue 1 edits. Updated to Opus 4.6.

**Issue 3: gtm workstream KNOWLEDGE.md is bare** — Jordan confirmed captain should fill it in. Done.

**Issue 4: Workstream KNOWLEDGE.md files for markdown-pal and mock-and-mark are boilerplate** — Jordan confirmed. Captain filled in both with project scope, key concepts, seed file references.

### Issues Document

**jordan:** Create an issues document following naming conventions, shared with the other captain (monofolk CoS).

**captain:** Proposed `issues-agency2-setup-20260329.md` at `usr/jordan/captain/`.

**jordan:** Approved.

**captain:** Created issues document with 6 issues found during setup:
- ISS-001: Ghostty bare hex colors (High, resolved)
- ISS-002: workstream-create --help bug (Medium, tool needs fix)
- ISS-003: Agent template defaults to Opus 4.5 (Low, template needs update)
- ISS-004: Bare boilerplate KNOWLEDGE.md (Low, tool could accept description)
- ISS-005: No seed file cross-references in agent.md (Low, tool could accept --seeds)
- ISS-006: Briefing files not in initial PRs (Medium, process issue)

Each issue includes action items for monofolk.

### All Changes Made This Session

**Files created:**
- `claude/workstreams/markdown-pal/` — workstream directory
- `claude/workstreams/mock-and-mark/` — workstream directory
- `claude/agents/markdown-pal/` — agent directory
- `claude/agents/mock-and-mark/` — agent directory
- `claude/agents/gtm/` — agent directory
- `usr/jordan/captain/transcript-workstream-setup-20260329.md` — this transcript
- `usr/jordan/captain/issues-agency2-setup-20260329.md` — issues document

**Files modified:**
- `claude/agents/markdown-pal/agent.md` — filled in purpose, responsibilities, seed files
- `claude/agents/mock-and-mark/agent.md` — filled in purpose, responsibilities, seed files
- `claude/agents/gtm/agent.md` — filled in purpose, responsibilities
- `claude/workstreams/markdown-pal/KNOWLEDGE.md` — filled in project scope
- `claude/workstreams/mock-and-mark/KNOWLEDGE.md` — filled in project scope
- `claude/workstreams/gtm/KNOWLEDGE.md` — filled in GTM scope

**Files removed:**
- `claude/workstreams/--help/` — errant directory from workstream-create bug

### Commands Created

```bash
# Launch agents
./tools/myclaude markdown-pal markdown-pal
./tools/myclaude mock-and-mark mock-and-mark
./tools/myclaude gtm gtm
```
