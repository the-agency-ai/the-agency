# PROP-0006: Distribution Structure (Unix FHS Pattern)

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Need to cleanly separate:
1. Framework files (from The Agency upstream)
2. Local customizations (project-specific)
3. Variable/runtime data

Currently everything is mixed, making updates risky and contributions unclear.

## Proposal

Apply Unix Filesystem Hierarchy Standard pattern to The Agency structure.

### Core Principle

```
UPSTREAM (read-only)     LOCAL (user-owned)      VARIABLE (runtime)
────────────────────     ──────────────────      ──────────────────
Distribution files       Customizations          Runtime state
Updated by Agency        Never touched by        Regenerated as
                         updates                 needed
```

### Applied Structure

```
the-agency-starter/
├── tools/                    # Framework tools (upstream)
├── tools/local/              # Local tools (never updated)
├── claude/
│   ├── docs/                 # Framework docs (upstream)
│   ├── docs/local/           # Local docs (never updated)
│   ├── knowledge/            # Framework knowledge (upstream)
│   │   ├── patterns.md       # Reusable patterns
│   │   ├── conventions.md    # Naming, structure
│   │   └── troubleshooting.md
│   ├── knowledge/local/      # Project knowledge (never updated)
│   │   ├── domain.md         # Project-specific domain
│   │   ├── architecture.md   # Project architecture
│   │   └── decisions.md      # ADRs, choices made
│   ├── agents/               # Template agents (upstream)
│   │   └── housekeeping/     # Framework agent
│   │       ├── KNOWLEDGE.md  # Agent baseline knowledge
│   │       └── KNOWLEDGE.local.md  # Project additions
│   ├── agents/local/         # Local agents (never updated)
│   │   └── my-agent/         # User's custom agent
│   ├── config.yaml           # Framework defaults (upstream)
│   ├── config.local.yaml     # Local overrides (never updated)
│   └── var/                  # Variable data (runtime)
│       ├── context-stack/    # Pushed contexts
│       ├── sessions/         # Session backups
│       └── cache/            # Temporary data
```

### Knowledge Layering

Knowledge follows the same precedence as tools:

```
Lookup order for agent knowledge:
1. claude/agents/{agent}/KNOWLEDGE.local.md   # Project-specific
2. claude/agents/{agent}/KNOWLEDGE.md         # Framework baseline

Lookup order for general knowledge:
1. claude/knowledge/local/{topic}.md          # Project-specific
2. claude/knowledge/{topic}.md                # Framework baseline
```

**Framework knowledge** (upstream):
- How to use The Agency
- Tool documentation
- Common patterns
- Troubleshooting guides

**Project knowledge** (local):
- Domain-specific concepts
- Project architecture
- Team conventions
- Integration details

### Upstream/Downstream Flow

```
the-agency (upstream)
        ↓
the-agency-starter (upstream)
        ↓ updates flow down
ordinaryfolk-nextgen (downstream)
        ↑ contributions flow up
```

### Update Safety

1. **Upstream updates** only touch non-local paths
2. **Local paths** are `.gitignore`d from upstream perspective
3. **Merge strategy:** Local always wins for conflicts
4. **Contribution path:** `local/` → propose to upstream → review → merge

### Lookup Precedence

For any resource X:
1. Look in `local/X` first
2. Fall back to `X` (framework version)

Example: Tool lookup
```bash
tools/local/my-tool  →  Found? Use it
tools/my-tool        →  Fall back to framework
```

## Key Points

- Based on proven Unix FHS pattern
- Safe updates that never clobber local
- Clear separation of concerns
- Clean contribution path

## Open Questions

- [ ] How to handle `CLAUDE.md`? (highly customized but framework provides template)
- [ ] Should `var/` be gitignored entirely?
- [ ] How to migrate existing projects to this structure?

## Dependencies

- Related proposals: PROP-0001 (Tool Ecosystem)
- Related research: Perplexity 2026-01-06-0826

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping
- Target: v0.2.0

---

## Discussion Log

### 2026-01-06 - Created
Based on Perplexity research on Unix FHS. Key insight: "Never overwrite the local tree. Your updater should only touch dist/ and never local/."
