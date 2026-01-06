# Gap Analysis: The Agency Getting Started Experience

**Date:** 2026-01-06
**Author:** housekeeping + jordan

This document identifies gaps in The Agency setup experience that need to be filled.

---

## Critical Gaps

### 1. PATH Configuration

**Problem:** After Claude Code installation, `claude` command may not be found.

**Current State:** User must manually add to shell profile.

**Solution Needed:**
- [ ] Post-install script that detects shell and offers to update PATH
- [ ] Clear error message with exact fix when command not found
- [ ] `./tools/check-path` diagnostic tool

**Proposal:** PROP-0015

---

### 2. Terminal Tab Naming

**Problem:** Tab naming relies on terminal-specific escape sequences.

**Current State:** Works in iTerm2, may not work in other terminals.

**Solution Needed:**
- [ ] Document supported terminals
- [ ] Graceful fallback for unsupported terminals
- [ ] Terminal detection in `./tools/myclaude`
- [ ] Alternative: status bar instead of tab name

**Proposal:** (part of PROP-0004 Hello World)

---

### 3. First-Run Experience

**Problem:** User clones starter but doesn't know what to do next.

**Current State:** Must read documentation.

**Solution Needed:**
- [ ] `./tools/init-agency` wizard that walks through setup
- [ ] Creates principal identity
- [ ] Initializes first agent
- [ ] Opens browser with Markdown Browser (PROP-0004)

**Proposal:** Part of PROP-0004 (Hello World)

---

### 4. Tool Discovery

**Problem:** Users don't know what tools are available.

**Current State:** Must explore `./tools/` directory.

**Solution Needed:**
- [x] `./tools/list-tools` - EXISTS
- [x] `./tools/find-tool` - EXISTS
- [ ] `./tools/how "task"` - TheCaptain integration
- [ ] Tab completion for tool names

**Proposal:** PROP-0014 (Knowledge Indexer for TheCaptain)

---

### 5. Shell Profile Detection

**Problem:** Different shells (bash, zsh, fish) have different config files.

**Current State:** Manual, user must know their shell.

**Solution Needed:**
- [ ] Detect current shell
- [ ] Auto-update correct profile file
- [ ] Support for: bash, zsh, fish

**Proposal:** PROP-0015

---

## Medium Priority Gaps

### 6. Credential/API Key Setup

**Problem:** Various services need API keys (Anthropic, GitHub, etc.)

**Current State:** Manual `.env` creation.

**Solution Needed:**
- [ ] `./tools/setup-credentials` wizard
- [ ] Secure storage recommendations
- [ ] Validation that keys are set

---

### 7. Git Configuration

**Problem:** User may not have git configured for commits.

**Current State:** May fail on first commit.

**Solution Needed:**
- [ ] Check for git user.name and user.email
- [ ] Prompt to configure if missing
- [ ] Part of init-agency flow

---

### 8. GitHub CLI (`gh`) Installation

**Problem:** Full GitHub integration requires `gh` CLI.

**Current State:** Not checked, may silently fail.

**Solution Needed:**
- [ ] Check for `gh` during init
- [ ] Offer to install via brew/apt
- [ ] Document as prerequisite

---

### 9. Node.js Version Check

**Problem:** Claude Code requires Node.js 18+.

**Current State:** Fails with cryptic error if wrong version.

**Solution Needed:**
- [ ] Check node version in init-agency
- [ ] Clear error message with upgrade instructions
- [ ] Consider nvm/fnm recommendations

---

## Nice to Have

### 10. IDE Integration

**Problem:** User may want VS Code extension but doesn't know about it.

**Current State:** Not mentioned.

**Solution Needed:**
- [ ] Document VS Code extension
- [ ] JetBrains plugin info
- [ ] Part of getting started guide

---

### 11. Permissions Pre-configuration

**Problem:** Claude asks for permission on every action initially.

**Current State:** User must configure `.claude/settings.json` manually.

**Solution Needed:**
- [ ] Default permissions template for The Agency tools
- [ ] Part of init-agency setup
- [ ] Safe defaults that don't expose secrets

---

### 12. Onboarding Tour

**Problem:** User doesn't know the key features.

**Current State:** Must read docs.

**Solution Needed:**
- [ ] Interactive tour via Claude conversation
- [ ] "What can you do?" response with examples
- [ ] Part of Hello World experience

---

## Gaps Filled by Existing Work

| Gap | Filled By |
|-----|-----------|
| Tool discovery | `./tools/list-tools`, `./tools/find-tool` |
| Session restore | `./tools/restore` |
| Quality checks | `./tools/pre-commit-check` |
| Deployment | `./tools/ship`, `./tools/sync` |
| Collaboration | `./tools/collaborate`, `./tools/post-news` |

---

## Related Proposals

| Proposal | Gaps Addressed |
|----------|----------------|
| PROP-0004 (Hello World) | First-run, terminal tabs, onboarding |
| PROP-0014 (Knowledge Indexer) | Tool discovery via TheCaptain |
| PROP-0015 (Shell Setup) | PATH, shell detection, profile updates |

---

## Priority Order

1. **PATH configuration** - Blocks everything else
2. **First-run wizard** - Critical for adoption
3. **Terminal detection** - Core experience
4. **Tool discovery** - Ongoing usability
5. **Credentials setup** - Required for real usage
6. **Git/GitHub setup** - Required for collaboration
7. **Node.js check** - Prevents cryptic errors
8. **IDE integration** - Nice to have
9. **Permissions** - Convenience
10. **Onboarding tour** - Polish

---

## Action Items

- [ ] Create PROP-0015 for shell/PATH setup
- [ ] Update PROP-0004 to include first-run wizard
- [ ] Add terminal detection to `./tools/myclaude`
- [ ] Create `./tools/init-agency` tool
- [ ] Document prerequisites in Getting Started
