# Naming Conventions

**Quick Reference:** `{scope}{number}-{workstream}-{type}[-v#].md`

## Directory Structure

```
claude/
├── agents/{agentname}/           # Agent identity & state
├── workstreams/{workstream}/     # Work artifacts & shared knowledge
│   ├── KNOWLEDGE.md              # Shared domain knowledge
│   ├── epic001/                  # Past epic work
│   │   └── sprint001/
│   └── epic002/                  # Current epic
│       ├── epic002-{ws}-plan.md  # Workstream's epic plan
│       └── sprint001/
│           ├── sprint001-{ws}-plan.md
│           ├── sprint001-{ws}-completion.md
│           ├── sprint001-iteration001-{ws}-plan.md
│           └── sprint001-iteration001-{ws}-completion.md
├── principals/{principal}/       # Principal directives
│   ├── preferences.yaml          # Editor, timezone, etc.
│   ├── requests/                 # REQUEST-principal-####-*.md files
│   └── artifacts/                # ART-####-*.md files
└── docs/                         # Guides and reference
```

## File Naming Pattern

**Format:** `{scope}{number}-{workstream}-{type}[-v#].md`

| Document Type        | File Name                                           |
| -------------------- | --------------------------------------------------- |
| Epic plan            | `epic002-{workstream}-plan.md`                      |
| Sprint plan          | `sprint001-{workstream}-plan.md`                    |
| Sprint completion    | `sprint001-{workstream}-completion.md`              |
| Iteration plan       | `sprint001-iteration001-{workstream}-plan.md`       |
| Iteration completion | `sprint001-iteration001-{workstream}-completion.md` |

## Request Naming

**Format:** `REQUEST-{principal}-{seq}-{agent}-{slug}.md`

Example: `REQUEST-jordan-0001-web-implement-dark-mode.md`

## Artifact Naming

**Format:** `ART-{seq}-{principal}-{workstream}-{agent}-{date}-{slug}.md`

Example: `ART-0001-jordan-web-web-2026-01-01-implementation-report.md`

## Collaboration Naming

**Format:** `FROM-{source-workstream}-{source-agent}-COLLABORATE-{seq}-{date}.md`

Example: `FROM-housekeeping-housekeeping-COLLABORATE-0001-2026-01-01.md`

## Agent & Workstream Names

| Entity     | Format              | Example          |
| ---------- | ------------------- | ---------------- |
| Agent      | lowercase-hyphen    | `agent-manager`  |
| Workstream | lowercase           | `agents`         |
| Principal  | lowercase           | `jordan`         |

## Versioning

- **v1 assumed** if no version suffix (e.g., `sprint001-web-plan.md` = v1)
- **Explicit versions** use whole numerals: `-v2.md`, `-v3.md`
- Example: `sprint001-web-plan-v2.md`

## Sprint Insertion

If a new sprint is inserted, renumber all subsequent sprints:

- Insert `sprint002` between `sprint001` and existing `sprint002`
- Existing `sprint002` → `sprint003`, `sprint003` → `sprint004`, etc.

---

*Part of The Agency framework*
