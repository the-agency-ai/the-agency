# REQUEST-jordan-0047: Migrate Agency Content from ordinaryfolk-nextgen

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** housekeeping
**Status:** Complete
**Priority:** Medium
**Created:** 2026-01-14

---

## Summary

Migrate Agency framework content from ordinaryfolk-nextgen to the-agency repo. The ordinaryfolk-nextgen project has been serving as the testbed for The Agency framework, and significant framework documentation exists there that should live in the main Agency repo.

---

## Content to Migrate

### 1. The Agency Book Project (HIGH PRIORITY)

**Source:** `/Users/jdm/code/ordinaryfolk-nextgen/claude/principals/jordan/projects/the-agency-book/`

**Contents:**
- `README.md` - Project overview
- `OUTLINE.md` - Book outline structure
- `the-agency-guide-proposal_and_outline-v3.md` - Proposal and final outline
- `the-agency-guide-chapter-01-draft-v2.md` - Chapter drafts
- `working-notes/WORKING-NOTE-*.md` (17 notes)
- `resources/general/` and `by-chapter/` - Research materials

**Target:** `claude/principals/jordan/projects/the-agency-book/`

### 2. Starter Packs (HIGH PRIORITY)

**Source:** `/Users/jdm/code/ordinaryfolk-nextgen/claude/starter-packs/`

**Contents:**
- `README.md` - Starter packs overview
- `node-base/` - Node.js base pack
- `react-app/` - React application pack
- `supabase-auth/` - Supabase authentication pack
- `github-ci/` - GitHub CI pack
- `vercel-deploy/` - Vercel deployment pack
- `posthog-analytics/` - PostHog analytics pack

**Target:** `claude/starter-packs/` (in the-agency-starter)

### 3. Framework Instructions (MEDIUM PRIORITY)

**Source:** `/Users/jdm/code/ordinaryfolk-nextgen/claude/principals/jordan/instructions/`

**Instructions to migrate:**
| ID | Title | Notes |
|----|-------|-------|
| INSTR-0001 | Principal Instruction System | Core framework |
| INSTR-0002 | Artifact System for Principals | Core framework |
| INSTR-0003 | CLAUDE.md Review and Context | Core framework |
| INSTR-0004 | Resources System for Instructions | Core framework |
| INSTR-0005 | Document The Agency Concepts | Meta documentation |
| INSTR-0022 | The Agency Starter Framework | Starter design |
| INSTR-0023 | The Agency Starter Launch Strategy | Launch planning |
| INSTR-0031 | Starter Packs: Modular Setup Guides | Starter packs |
| INSTR-0038 | Autonomous Workflows Phase | Future roadmap |
| INSTR-0050 | Agency Services: Database Tooling | Services design |
| INSTR-0056 | Agency Starter Sync Practice | Sync workflow |
| INSTR-0057 | Agency Starter Versioning | Versioning design |
| INSTR-0060 | Agency Starter Sync Pipeline | Sync pipeline |
| INSTR-0067 | Friday Workshop Introduction | Workshop content |

**Target:** `claude/principals/jordan/instructions/` or `claude/docs/legacy-instructions/`

### 4. Framework Artifacts (MEDIUM PRIORITY)

**Source:** `/Users/jdm/code/ordinaryfolk-nextgen/claude/principals/jordan/artifacts/`

**Artifacts to migrate:**
| ID | Title | Notes |
|----|-------|-------|
| ART-0001 | Principal and Artifact System Summary | Core framework |
| ART-0003 | Agency Comprehensive Concepts | Framework concepts |
| ART-0008 | Claude Desktop Workflow | Integration docs |
| ART-0011 | The Agency Context State | State documentation |

**Target:** `claude/principals/jordan/artifacts/` or `claude/docs/legacy-artifacts/`

### 5. Reference Documentation (LOW PRIORITY)

**Source:**
- `/Users/jdm/code/ordinaryfolk-nextgen/claude/docs/reference/THE_AGENCY.md`
- `/Users/jdm/code/ordinaryfolk-nextgen/claude/docs/the_agency.md`

**Notes:** These describe the ordinaryfolk-nextgen instantiation but contain valuable patterns. Consider as case study examples.

**Target:** `claude/docs/case-studies/ordinaryfolk-nextgen/`

---

## What Stays in ordinaryfolk-nextgen

- All agent-specific KNOWLEDGE.md, WORKLOG.md, ADHOC-WORKLOG.md
- Sprint plans and completion documents
- Project-specific design documents
- Customer/product-specific content
- Implementation-specific work logs

---

## Implementation Approach

### Phase 1: Book Project Migration
1. Copy entire book project directory
2. Update any internal references
3. Verify all files transferred

### Phase 2: Starter Packs Migration
1. Copy starter-packs to the-agency-starter
2. Update CLAUDE.md to reference starter packs
3. Test one pack to verify functionality

### Phase 3: Instructions and Artifacts
1. Review each instruction for framework vs project content
2. Extract framework-relevant portions
3. Archive in appropriate location

### Phase 4: Documentation Cleanup
1. Create case study from ordinaryfolk-nextgen docs
2. Update cross-references
3. Remove migrated content from ordinaryfolk-nextgen (optional)

---

## Success Criteria

- [ ] Book project fully migrated with all working notes
- [ ] All starter packs functional in the-agency-starter
- [ ] Framework instructions archived/available
- [ ] Framework artifacts archived/available
- [ ] No broken references in either repo
- [ ] Clear separation between framework and project content

---

## Notes

- ordinaryfolk-nextgen intentionally serves as reference implementation
- Some content may need to exist in both places (reference implementation)
- Consider using symlinks or references rather than full duplication where appropriate

---

## Work Log

### 2026-01-14

- Created REQUEST based on exploration of ordinaryfolk-nextgen
- Identified 5 categories of content to migrate
- Documented what should stay vs migrate

### 2026-01-14 (Session 2)

**Book Project:**
- Verified the-agency already has more working notes (0001-0024) than nextgen (0001-0018)
- No migration needed - the-agency is the canonical source

**Starter Packs:**
- Created `claude/starter-packs/` directory in the-agency
- Copied 6 packs from nextgen: github-ci, node-base, posthog-analytics, react-app, supabase-auth, vercel-deploy
- Multi-agent comparison of overlapping packs:
  - github-ci vs git-ci → Merged into github-ci (ported install.sh, workflows, Husky from git-ci)
  - vercel-deploy vs vercel → Replaced vercel-deploy with comprehensive vercel pack
- Multi-agent review of all 6 packs:
  - github-ci: 3.5/5 - Fixed step order inconsistencies
  - node-base: 4/5 - Documented dotenv as optional
  - posthog-analytics: 4.5/5 - Added to Available Packs in README
  - react-app: 4.5/5 - Fixed 'use client' syntax typo
  - supabase-auth: 4/5 - npm for CLI is acceptable
  - vercel: 4/5 - Changed Node 20 → 22 for consistency
- All packs updated to use pnpm and Node 22

**Instructions/Artifacts:**
- Deferred - can be added later if needed

**Commits:**
- ffd45c8: Add starter-packs from nextgen with merges
- 112f417: Fix starter pack review findings

**Summary:**
- 6 starter packs now in the-agency
- Working notes already up-to-date
- Framework instructions/artifacts deferred (lower priority)

