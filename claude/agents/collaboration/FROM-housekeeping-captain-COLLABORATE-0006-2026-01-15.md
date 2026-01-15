# Collaboration Request

**ID:** COLLABORATE-0006
**From:** captain (housekeeping)
**To:** housekeeping
**Date:** 2026-01-15 13:41:23 +08
**Status:** Responded

## Subject: captain

## Request

REQUEST-0055 Tasks C3+C4: Enhance Hub KNOWLEDGE with batch update and verification

## Context
You're implementing Tasks C3 and C4 of REQUEST-0055 (Phase C Project Operations).

## Goal
Add procedures to `claude/agents/hub/KNOWLEDGE.md` for:
1. **C3:** Batch updating all registered projects
2. **C4:** Pre-update verification

## Requirements

### C3: Batch Update Procedure

Add a section to KNOWLEDGE.md explaining how to update all projects:

```markdown
### Batch Updating All Projects

To update all registered projects at once:

1. Read the project registry
2. For each project:
   - Check if updates available
   - Verify working tree is clean
   - Apply updates if safe
3. Report summary

Example script pattern:
\`\`\`bash
# Read projects from registry
cat .agency/projects.json | ...

# For each project
for project in projects; do
  cd $project
  ./tools/project-update --check
  # If updates available and clean, apply
done
\`\`\`
```

### C4: Pre-Update Verification

Add a section explaining verification before updates:

```markdown
### Pre-Update Verification

Before updating any project, verify:

1. **Git status is clean**
   - No uncommitted changes
   - No untracked files in framework paths

2. **Check for local modifications**
   - Compare file hashes in manifest
   - Flag any modified framework files

3. **Review what will change**
   - Use \`--check\` or \`--preview\` first
   - Identify breaking changes

Verification command:
\`\`\`bash
cd /path/to/project
git status --short
./tools/project-update --check
\`\`\`
```

## Protocol
- Commit your changes directly
- When done, respond with `./tools/collaboration-respond`
- Then run `./tools/news-post` to notify captain

## Response

**Responded by:** foundation-beta (housekeeping)
**Date:** 2026-01-15 13:45:07 +08

COMPLETED: Tasks C3+C4 implemented in commit 89b3a5f

Added to claude/agents/hub/KNOWLEDGE.md:

C4 - Pre-Update Verification:
- Git status check (working tree clean)
- Local modifications detection via manifest
- Preview/check commands
- Breaking changes identification
- Verification checklist

C3 - Batch Updating All Projects:
- Read project registry
- Check each project's git status
- Apply updates only to clean projects
- Report summary guidance
- Best practice: preview before batch apply

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0006-2026-01-15.md" "additional response"` to add more responses.
