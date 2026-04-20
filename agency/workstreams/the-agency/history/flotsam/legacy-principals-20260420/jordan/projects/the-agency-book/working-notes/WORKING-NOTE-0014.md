# WORKING-NOTE-0014: Command Telemetry → TheCaptain Learning Loop

**Date:** 2026-01-04 09:45 SGT
**Topic:** How command logging feeds TheCaptain's knowledge

## The Insight

> Agents solving similar problems differently → log it → TheCaptain learns canonical patterns → future agents get consistent guidance.

## The Problem Observed

Different agents solving the same problem with different approaches:

**Example: SQL Migration Trigger Fixes**

Agent A:

```bash
for f in supabase/migrations/2025*.sql supabase/migrations/2026*.sql; do
  sed -i '' 's/CREATE TRIGGER \([a-zA-Z0-9_]*\)/DROP TRIGGER IF EXISTS \1 ON /g' "$f"
done
```

Agent B might use:

- A different sed pattern
- A tool we already have
- Manual editing
- A different approach entirely

## Why This Matters

1. **Cost** - Long inline scripts are expensive (tokens)
2. **Consistency** - Agents should use canonical patterns
3. **Quality** - Some approaches are more robust than others
4. **Knowledge** - What one agent learns, all should benefit from

## The Solution Loop

```
┌──────────────────┐
│   Agent Work     │
│ (varied patterns)│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Command Logging │
│  (telemetry)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Analysis       │
│ (pattern mining) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  TheCaptain KB   │
│ (canonical ways) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Agent Query    │
│ "How do I fix    │
│  triggers?"      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Consistent      │
│  Guidance        │
└──────────────────┘
```

## Implementation Path

1. **Command Telemetry** (INSTR pending)
   - Log all Bash commands with context
   - Capture success/failure
   - Note patterns and variations

2. **Pattern Mining**
   - Identify common tasks (migration fixes, build issues, etc.)
   - Find best-performing patterns
   - Document anti-patterns

3. **TheCaptain Knowledge**
   - Feed canonical patterns into TheCaptain's context
   - "For trigger fixes, use ./tools/fix-triggers"
   - "For migration issues, see PLAYBOOK-migrations.md"

4. **Feedback Loop**
   - TheCaptain suggests tools that don't exist → create them
   - Common patterns → toolify them
   - Expensive inline scripts → replace with tools

## Related

- INSTR-0052: TheCaptain - Unified AI Guidance Service
- INSTR (pending): Command Analytics/Telemetry
