# fleet-report — skill-unique protocol

This skill is primarily orchestration — it aggregates outputs of six sibling tools and composes a report. Most behavior is specified in the `required_reading:` framework reference docs (ISCP protocol, worktree discipline, handoff spec, PR lifecycle).

This reference doc captures the protocol specific to fleet-report's aggregation — what the skill considers "stale," how it derives NEXT ACTIONS, and the exact shape of the JSON output.

## Staleness thresholds

| Artifact | Threshold | Source of truth |
|---|---|---|
| Handoff | `date:` frontmatter > 48 hours old | `usr/*/*/<agent>-handoff.md` YAML |
| PR | `updatedAt` > 72 hours ago, state OPEN | `gh pr list --json updatedAt` |
| Dispatch | `created_at` > 24 hours ago, status unread | ISCP SQLite DB |
| Flag | no time threshold — all unread flags surface | ISCP SQLite DB |
| Worktree divergence | > 14 days behind main | `agency-health` warning threshold |

Thresholds are intentionally generous. Fleet-report surfaces everything; the principal filters by relevance.

## NEXT ACTIONS inference rules

The captain inference at the bottom of the report is **strictly derived from observed data**. The rules:

1. **Critical health finding** → top of NEXT ACTIONS with the exact severity message
2. **Stale PR** → "PR #NNN stale for Nd — needs attention or close"
3. **Stale handoff** → "<agent> handoff N days old — consider status check"
4. **Large unread dispatch backlog (>5 per agent)** → "<agent> has N unread — triage or reassign"
5. **Diverging worktree (>50 commits behind main)** → "<agent> worktree N behind main — sync or close"
6. **Cross-repo unread > 0** → "monofolk: N unread collab dispatches — review"
7. **No findings** → "NEXT ACTIONS: none — fleet is quiet"

Do NOT invent actions the data doesn't support. If the fleet is quiet, say so.

## JSON output schema

```json
{
  "timestamp": "ISO-8601 UTC",
  "report_version": "1",
  "health": {
    "overall": { "warnings": N, "critical": N, "exit_code": N },
    "workstreams": [...],
    "agents": [...],
    "worktrees": [...]
  },
  "prs": {
    "open": [
      {
        "number": N,
        "title": "…",
        "author": "…",
        "is_draft": true|false,
        "created_at": "…",
        "updated_at": "…",
        "age_hours": N,
        "stale": true|false
      }
    ],
    "recent_merged": [
      {
        "number": N,
        "title": "…",
        "merged_at": "…",
        "age_hours": N
      }
    ]
  },
  "dispatches": {
    "total_unread": N,
    "by_agent": {
      "<agent-address>": {
        "unread": N,
        "oldest_hours": N
      }
    }
  },
  "flags": {
    "total_unread": N,
    "by_agent": {
      "<agent-address>": {
        "unread": N,
        "newest_text": "…"
      }
    }
  },
  "handoffs": {
    "stale": [
      { "agent": "…", "path": "…", "last_write": "…", "age_hours": N }
    ],
    "fresh": [
      { "agent": "…", "last_write": "…", "age_hours": N }
    ]
  },
  "worktrees": {
    "<name>": {
      "branch": "…",
      "last_commit": { "hash": "…", "subject": "…" },
      "behind_main": N,
      "dirty_files": N
    }
  },
  "cross_repo": {
    "<repo>": {
      "unread": N,
      "oldest_hours": N
    }
  },
  "next_actions": [
    "Action text 1",
    "Action text 2"
  ]
}
```

**Schema versioning:** `report_version` starts at `"1"`. Bumps when the schema changes in backwards-incompatible ways. Additive changes (new optional fields) do not bump.

## Composition order

The human-readable report preserves a fixed section order so the principal's eye goes to the same place every time. Do NOT reorder sections based on severity. Severity is reflected in the NEXT ACTIONS list.

Fixed section order:
1. HEALTH
2. PRs IN FLIGHT
3. RECENT MERGES
4. UNREAD DISPATCHES
5. UNREAD FLAGS
6. STALE HANDOFFS
7. RECENT COMMITS (per worktree)
8. CROSS-REPO
9. NEXT ACTIONS

Sections with no data appear as `<section>: (none)` — still present, so the principal confirms the section ran and had nothing to report (absence vs error).

## Related protocols (in required_reading)

- **ISCP protocol** (`REFERENCE-ISCP-PROTOCOL.md`) — defines dispatch + flag semantics
- **Worktree discipline** (`REFERENCE-WORKTREE-DISCIPLINE.md`) — defines what "healthy worktree" means
- **Handoff spec** (`REFERENCE-HANDOFF-SPEC.md`) — defines handoff frontmatter + staleness
- **Code-review lifecycle** (`REFERENCE-CODE-REVIEW-LIFECYCLE.md`) — defines PR states
