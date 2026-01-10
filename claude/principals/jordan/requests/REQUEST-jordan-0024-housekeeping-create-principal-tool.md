# REQUEST-jordan-0024: Create Principal Tool

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Open

**Priority:** High

**Created:** 2026-01-10 17:45 SST

## Summary

Create `./tools/create-principal` that users run before their first Claude Code session to set up their principal identity.

## Requirements

- [ ] Interactive prompts for principal name
- [ ] Set CLAUDE_PRINCIPAL env variable
- [ ] Create principal directory structure
- [ ] Add to shell profile (.zshrc, .bashrc)
- [ ] Validate principal name format
- [ ] Check for existing principal

## Usage

```bash
./tools/create-principal
# Prompts: "What is your principal name?"
# Sets: export CLAUDE_PRINCIPAL=jordan
# Creates: claude/principals/jordan/
```

## Activity Log

### 2026-01-10 17:45 SST - Created
- Stub created as part of omnibus breakdown
- Quick win - improves onboarding experience
