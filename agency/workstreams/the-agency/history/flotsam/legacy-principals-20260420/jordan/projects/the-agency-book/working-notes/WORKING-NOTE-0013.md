# WORKING-NOTE-0013: Activity Indicator State Machine Fix

**Date:** 2026-01-04 09:30 SGT
**Topic:** iTerm Tab Color Activity Indicator - Principal Action Model

## Problem Statement

The tab color activity indicator (Blue/Red/Green) had UX issues:

1. **Red stayed on after permission grant** - The indicator stayed Red during command execution, even after the principal granted permission
2. **Error state stickiness** - Red on error didn't clear promptly
3. **Mental model mismatch** - Red was "permission wait" but should be "principal action requested"

## Key Insight

Red doesn't mean "waiting for permission" - it means **"ball is in principal's court"**:

- Permission request (grant OR deny)
- Question requiring answer
- Plan mode awaiting approval
- Error requiring decision

**The moment the principal acts, the indicator should flip to Green** regardless of what happens next.

## Solution

Added two hook changes:

### 1. UserPromptSubmit Hook (NEW)

Fires when principal submits ANY input (grant, deny, answer, new request):

```json
"UserPromptSubmit": [
  {
    "matcher": "*",
    "hooks": [
      {
        "type": "command",
        "command": "./tools/tab-status working 2>/dev/null || true"
      }
    ]
  }
]
```

### 2. PostToolUse Status Update (ADDED)

Sets Green after tool completes (agent still processing):

```json
{
  "type": "command",
  "command": "./tools/tab-status working 2>/dev/null || true"
}
```

## State Machine

```
┌─────────────────┐
│   SessionStart  │──────────────────────┐
└─────────────────┘                      │
         │                               ▼
         │                        ┌──────────────┐
         │                        │  🔵 Blue     │
         │                        │  (available) │
         │                        └──────────────┘
         │                               │
         │                    UserPromptSubmit
         │                               │
         ▼                               ▼
┌─────────────────┐               ┌──────────────┐
│   PreToolUse    │──────────────▶│  🟢 Green    │
└─────────────────┘               │  (working)   │
         │                        └──────────────┘
         │                               │
    Permission                     PostToolUse
    Required?                            │
         │                               ▼
         ▼                        ┌──────────────┐
┌─────────────────┐               │  🟢 Green    │
│ PermissionReq   │──────────────▶│  (working)   │
└─────────────────┘               └──────────────┘
         │                               │
         ▼                            Stop
┌─────────────────┐                      │
│  🔴 Red         │                      ▼
│  (attention)    │               ┌──────────────┐
└─────────────────┘               │  🔵 Blue     │
         │                        │  (available) │
  Principal Acts                  └──────────────┘
         │
         ▼
┌─────────────────┐
│ UserPromptSubmit│
└─────────────────┘
         │
         ▼
┌─────────────────┐
│  🟢 Green       │
│  (working)      │
└─────────────────┘
```

## Files Modified

- `.claude/settings.local.json` - Added UserPromptSubmit hook, updated PostToolUse

## For The Agency Starter

This pattern should be documented as the standard activity indicator configuration. Users extending the starter should understand:

1. **Blue** = Ready for input (idle)
2. **Red** = Principal action required
3. **Green** = Agent working

The key is that **Red clears on principal action, not on command completion**.

## Related

- `./tools/tab-status` - The indicator control script
- INSTR-0041 - iTerm Performance (completed)
- WORKING-NOTE-0005 - Original statusline setup
