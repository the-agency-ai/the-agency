# Gap Analysis: The Agency Getting Started Experience

**Date:** 2026-01-06
**Author:** housekeeping + jordan

This document identifies gaps in The Agency setup experience that need to be filled.

---

## Critical Gaps

### 1. PATH Configuration

**Problem:** After Claude Code installation, `claude` command may not be found.

**Current State:** User must manually add to shell profile.

**Decision:** Handle in install script with proper permissions. The install script should:
- Detect current shell (zsh for now)
- Update PATH automatically
- Verify the command works

**Solution:**
- [ ] Install script auto-updates PATH
- [ ] Clear error message with fix if something goes wrong
- [ ] `./tools/check-path` diagnostic tool (fallback)

---

### 2. Terminal Tab Naming

**Problem:** Tab naming relies on terminal-specific escape sequences.

**Current State:** Works in iTerm2, may not work in other terminals.

**Decision:** Require iTerm2 for macOS. Either:
- Tell them to install iTerm2 as prerequisite
- Install it for them via Homebrew

**Solution:**
- [ ] Document iTerm2 as requirement for macOS
- [ ] Add `brew install --cask iterm2` to install script
- [ ] Graceful message for other terminals

---

### 3. First-Run Experience: The Captain Interview

**Problem:** User clones starter but doesn't know what to do next.

**Current State:** Must read documentation.

**Decision:** First-run should be **The Captain Interview** - an interactive onboarding conversation where TheCaptain:
- Welcomes the user
- Asks about their project/goals
- Creates principal identity
- Sets up first agent
- Explains key tools
- Opens Markdown Browser to show what they've got

**Solution:**
- [ ] Create TheCaptain Interview skill
- [ ] Triggered by `./tools/init-agency` or first `claude` run
- [ ] Interactive, conversational setup
- [ ] Uses open-webpage to show resources

**Proposal:** Part of PROP-0004 (Hello World) - The Captain Interview

---

### 4. Tool Discovery via TheCaptain

**Problem:** Users don't know what tools are available.

**Current State:** Must explore `./tools/` directory.

**Existing:**
- [x] `./tools/list-tools` - EXISTS
- [x] `./tools/find-tool` - EXISTS

**Decision:** This is also The Captain Interview. TheCaptain should know all tools and guide users to them.

**Solution:**
- [ ] `./tools/how "task"` - TheCaptain suggests tools
- [ ] PROP-0014 Knowledge Indexer powers TheCaptain's knowledge
- [ ] Tab completion for tool names (nice to have)

---

### 5. Shell Profile Detection

**Problem:** Different shells (bash, zsh, fish) have different config files.

**Current State:** Manual, user must know their shell.

**Decision:** Start with **zsh only**. Provide good architecture and example so community can contribute support for other shells.

**Solution:**
- [ ] Support zsh in v1.0
- [ ] Document how to add other shells
- [ ] Accept community PRs for bash, fish, etc.

---

## Medium Priority Gaps

### 6. Credential/API Key Setup

**Problem:** Various services need API keys (Anthropic, GitHub, etc.)

**Current State:** Manual `.env` creation.

**Decision:** The Captain Interview + open-webpage. TheCaptain:
- Asks what services they'll use
- Opens the relevant credential pages in browser
- Guides them through pasting keys
- Validates keys are set

**Solution:**
- [ ] TheCaptain Interview handles credentials
- [ ] Uses `./tools/open-webpage` to open key pages
- [ ] Validates keys work before proceeding

---

### 7. Git Configuration

**Problem:** User may not have git configured for commits.

**Current State:** May fail on first commit.

**Solution:**
- [ ] Check for git user.name and user.email in Captain Interview
- [ ] Prompt to configure if missing
- [ ] Simple: `git config --global user.name "Your Name"`

---

### 8. GitHub CLI (`gh`) Installation

**Problem:** Full GitHub integration requires `gh` CLI.

**Current State:** Not checked, may silently fail.

**Solution:**
- [ ] Check for `gh` during Captain Interview
- [ ] Offer to install via `brew install gh`
- [ ] Document as recommended (not required)

---

### 9. Node.js Version Check

**Problem:** Claude Code requires Node.js 18+.

**Current State:** Fails with cryptic error if wrong version.

**Solution:**
- [ ] Check node version in install script
- [ ] Clear error message with upgrade instructions
- [ ] Recommend nvm for version management

---

## Nice to Have

### 10. IDE Integration

**Problem:** User may want VS Code extension but doesn't know about it.

**Solution:**
- [ ] Mention VS Code extension in Captain Interview
- [ ] `./tools/open-webpage` to extension marketplace
- [ ] Part of getting started guide

---

### 11. Permissions Pre-configuration

**Problem:** Claude asks for permission on every action initially.

**Current State:** User must configure `.claude/settings.json` manually.

**Solution:**
- [ ] Default permissions template for The Agency tools
- [ ] Part of init-agency setup
- [ ] Safe defaults that don't expose secrets

---

### 12. Onboarding Tour

**Problem:** User doesn't know the key features.

**Decision:** This IS The Captain Interview.

---

## Summary: The Captain Interview

Most gaps are solved by **The Captain Interview** - an interactive first-run experience where TheCaptain:

1. Welcomes user, explains The Agency
2. Checks prerequisites (Node.js, git, gh)
3. Installs missing tools (iTerm2, gh)
4. Creates principal identity
5. Sets up credentials (opens pages, validates)
6. Configures git if needed
7. Creates first agent
8. Opens Markdown Browser to show the result
9. Explains key tools and how to get help

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
| PROP-0004 (Hello World) | The Captain Interview, Markdown Browser |
| PROP-0013 (Open Webpage) | Opening credential pages, docs, previews |
| PROP-0014 (Knowledge Indexer) | Tool discovery via TheCaptain |

---

## Priority Order

1. **The Captain Interview** - Solves most gaps in one interactive experience
2. **Install script** - PATH, Node.js check, iTerm2
3. **Knowledge Indexer** - Powers TheCaptain's tool knowledge
4. **Open Webpage** - Enables credential setup flow

---

## Action Items

- [ ] Update PROP-0004 to define The Captain Interview
- [ ] Create install script that handles PATH, prerequisites
- [ ] Implement `./tools/init-agency` that triggers Captain Interview
- [ ] Build Knowledge Indexer (PROP-0014) to power TheCaptain
