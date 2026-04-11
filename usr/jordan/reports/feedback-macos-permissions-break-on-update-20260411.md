---
report_type: feedback
target: Anthropic Claude Code
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-11
status: draft
category: bug
severity: moderate
subject: macOS accessibility/automation permissions break on every Claude Code update (binary path versioning)
source: usr/jordan/captain/anthropic-issues-to-file-20260406.md (item 3)
---

## [Bug Report]: macOS permissions break on every Claude Code update — binary path includes version

**From:** Jordan Dea-Mattson
**GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
**Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
**Related:** Computer Use MCP, macOS Privacy & Security integration

## Problem

macOS stores accessibility and automation permissions keyed on the exact filesystem path of the granting binary. Claude Code's installed binary path **includes the version number**. When Claude Code auto-updates (which happens often — sometimes multiple times per week), the binary path changes, which invalidates all previously granted permissions from macOS's perspective.

The result: every update silently breaks Computer Use MCP and any other feature that requires macOS accessibility or automation permissions. The user discovers this only when the feature fails, usually mid-task, often with a cryptic permission-denied error.

## Steps to Reproduce

1. On macOS, grant Claude Code accessibility or automation permissions:
   - Open System Settings → Privacy & Security → Accessibility
   - Add or enable Claude Code
   - Verify it works (e.g., Computer Use MCP takes a screenshot successfully)
2. Wait for Claude Code to auto-update (or manually update to a new version, e.g., `2.1.63` → `2.1.64`)
3. Attempt to use a feature that requires the granted permission
4. Observe: permission failure. The old entry in System Settings is now a "ghost" pointing at a path that no longer exists, and the new binary has no permission.

## Diagnostic Evidence

On my Mac, I have accumulated **ghost entries** in Privacy & Security > Accessibility for multiple past Claude Code versions, each pointing at a stale path. Every update adds another ghost. I have to:

1. Go to System Settings > Privacy & Security > Accessibility
2. Remove the ghost entry for the old version
3. Click "+" and navigate to the new Claude Code binary
4. Re-toggle the permission

This happens every single update. Multiple times per week. My ghost list is currently around a dozen entries.

## Root Cause

macOS permissions are stored with the inode and path of the binary at the moment permission was granted. Updating the binary to a new path means macOS treats it as a **different application** that has never been granted permission. Claude Code appears to install each version to a version-specific path rather than using a stable symlink, wrapper script, or update-in-place pattern.

## Requested Behavior

**Option 1 (preferred): Stable binary path**

Claude Code should install to a version-independent path (e.g., `/usr/local/bin/claude` or `/Applications/Claude Code.app`) with the versioned binaries hidden behind it as implementation detail. Updates swap the target of the stable path; the path itself never changes. macOS permissions granted to the stable path survive all future updates.

**Option 2: In-place binary update**

Update the binary in place without changing its path. macOS re-reads the new inode and preserves permissions for the same path. This is how many native macOS apps handle updates (the `Contents/MacOS/{app}` path stays the same across updates).

**Option 3: Documented migration on update**

If Options 1 and 2 are infeasible for some reason, at minimum detect the update-breaks-permissions condition and show a clear one-time banner: *"Claude Code was updated. If you use Computer Use MCP or other accessibility-dependent features, you will need to re-grant macOS permissions in System Settings > Privacy & Security."*

## Why This Matters

- **Computer Use MCP is a flagship Claude Code feature.** Breaking it silently on every update undermines trust in the tool.
- **Users who update frequently suffer most.** Power users who adopt new features fastest are the most penalized. This is the opposite of what a good update ergonomics model produces.
- **The ghost-entry accumulation is user-hostile.** Users see a list of "Claude Code" entries in Privacy & Security growing over time with no clear way to clean them up.
- **Not fixable in user space.** Framework developers cannot work around this. Only Anthropic can fix the install layout.

## Related context

- Filed by: Jordan Dea-Mattson, daily Claude Code user on macOS
- Environment: macOS (specific version varies; observed across multiple macOS versions)
- Feature affected: primarily Computer Use MCP, but any feature requiring macOS accessibility or automation

---

*Draft — awaiting principal review before send.*
