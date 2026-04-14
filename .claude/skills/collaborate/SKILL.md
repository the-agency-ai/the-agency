---
description: Cross-repo dispatch lifecycle — check, read, resolve, reply, push. Captain-only.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Cross-Repo Collaboration

Manage cross-repo dispatches via git-based collaboration repos. Captain-only — cross-repo coordination is a captain responsibility.

## Arguments

- `$ARGUMENTS`: Subcommand and arguments. One of:
  - `check` — pull all collaboration repos and scan for unread dispatches
  - `list` — list configured collaboration repos
  - `read <repo> <filename>` — read a dispatch and mark as read
  - `resolve <repo> <filename>` — mark a dispatch resolved
  - `resolve <repo> --all-resolved` — mark all read dispatches resolved
  - `reply <repo> --to <file> --subject <text> --body <text>` — write a reply dispatch
  - `push <repo>` — commit and push status updates and replies

If empty, defaults to `check`.

## Instructions

### check (default)

Run `./claude/tools/collaboration check` — pulls latest from all configured repos and reports unread dispatches. Silent when empty. This runs automatically on SessionStart via hook.

### read

Read a specific dispatch and mark it as read:

```
./claude/tools/collaboration read <repo> <filename>
```

Summarize the content for the principal.

### resolve

Mark dispatches as resolved after processing:

```
./claude/tools/collaboration resolve <repo> <filename>
./claude/tools/collaboration resolve <repo> --all-resolved
```

`--all-resolved` marks all dispatches with `status: read` as resolved. Does NOT touch unread dispatches.

### reply

Write a reply dispatch to the outbound directory:

```
./claude/tools/collaboration reply <repo> --to <original-file> --subject "Re: subject" --body "response content"
```

This also marks the original dispatch as resolved. The reply is written to the outbound directory but NOT pushed — run `push` separately.

### push

Commit and push all pending changes (status updates + reply dispatches):

```
./claude/tools/collaboration push <repo>
./claude/tools/collaboration push <repo> --message "custom commit message"
```

## Workflow

1. **Check:** `collaboration check` → see what's waiting
2. **Read:** `collaboration read <repo> <file>` → read and mark as read
3. **Reply:** `collaboration reply <repo> --to <file> --subject "..." --body "..."` → write response
4. **Resolve:** `collaboration resolve <repo> <file>` → mark done (reply does this automatically)
5. **Push:** `collaboration push <repo>` → commit and deliver

## Configuration

Collaboration repos are configured in `claude/config/agency.yaml`:

```yaml
collaboration:
  repos:
    <partner-repo>:
      path: "~/code/collaboration-<partner-repo>"
      inbound: "dispatches/<partner-repo>-to-the-agency"
      outbound: "dispatches/the-agency-to-<partner-repo>"
```
