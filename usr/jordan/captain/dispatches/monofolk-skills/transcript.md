---
allowed-tools: Read, Write, Edit, Glob, Bash(date *), Bash(git branch *)
description: Record structured discussion transcripts — start, capture decisions, stop
---

# /transcript

Real-time conversation capture tool. Records dialogue and decisions as they happen.

## Subcommands

| Subcommand                      | Description                               |
| ------------------------------- | ----------------------------------------- |
| `start "topic"`                 | Begin transcript capture                  |
| `capture "title" "description"` | Append a structured decision entry        |
| `append "text"`                 | Append freeform text to active transcript |
| `stop`                          | Finalize the transcript                   |
| `list`                          | List recent transcripts across projects   |
| `status`                        | Report if active, mode, file path         |

## Instructions

### Parse subcommand

Split `$ARGUMENTS` into the first word (subcommand) and the rest (args).

If `$ARGUMENTS` is empty, show the subcommand table above and ask which to run.

If the subcommand is not recognized, show the subcommand table and ask which to run.

---

### `start`

**Arguments:**

- First quoted string or unquoted words = topic (required)
- `--mode dialogue|review|design` — capture mode (default: `dialogue`)
- `--file path/to/file.md` — override output file path
- `--project name` — override project detection

**Steps:**

1. **Parse arguments.** Extract topic, mode, file, and project from the remaining args after "start". If no topic is provided, ask for one.

2. **Detect project** (if `--project` not specified):
   - Run `git branch --show-current`
   - If branch contains a `/`, take only the last segment (e.g., `proto/catalog` → `catalog`, `folio/main` → `main`, `pr/folio` → `folio`)
   - If branch is `master` → project is `captain`
   - Otherwise → use the branch name as-is

3. **Generate filename and date** (if `--file` not specified):
   - Get timestamp: `date "+%Y%m%d-%H%M"`
   - Get display date from the same moment: derive `YYYY-MM-DD` from the timestamp (first 4 chars + dash + next 2 + dash + next 2)
   - Slugify topic: lowercase, replace spaces and special characters with hyphens, collapse multiple hyphens, truncate to 50 characters
   - Result: `{timestamp}-{slug}.md`
   - Full path: `usr/jordan/{project}/transcripts/{filename}`

4. **Create directory:**
   - `mkdir -p usr/jordan/{project}/transcripts/`

5. **Write file** using the Write tool:

```markdown
# Discussion: {topic}

**Date:** {YYYY-MM-DD}
**Participants:** Jordan, {agent name — e.g. Captain, or the current agent's name}
**Mode:** {dialogue|review|design}
**Project:** {project}

---
```

6. **Confirm to user:**

   > Transcript started: `{file path}`
   > Mode: {mode}

7. **If mode is `dialogue`**, activate ongoing dialogue capture (see Dialogue Mode below).

---

### `capture`

Manually append a decision entry. Works in any mode.

**Arguments:**

- First quoted string = title (required)
- Second quoted string or remaining text = description (required)

**Steps:**

0. **Locate transcript file.** Use the file path from context. If no path is in context, run the Recovery procedure below to find the active transcript. If no active transcript is found, report "No active transcript. Run `/transcript start` first." and exit.

1. Get current time: `date "+%H:%M"`
2. Append to the transcript file using the Edit tool (find the last line of content and add after it):

```markdown
### {HH:MM} — Decision: {title}

{description}
```

3. Confirm inline: `Captured: {title}`

Note: In dialogue mode, the `capture` subcommand writes the decision entry directly. The subsequent confirmation message ("Captured: ...") is a status report and should NOT be double-appended by the dialogue mode rules.

---

### `append`

Append freeform text to the active transcript. For capturing discussion notes, observations, or context that aren't structured decisions.

**Arguments:**

- Quoted string or remaining text = the text to append (required)

**Steps:**

0. **Locate transcript file.** Use the file path from context. If no path is in context, run the Recovery procedure below to find the active transcript. If no active transcript is found, report "No active transcript. Run `/transcript start` first." and exit.

1. Get current time: `date "+%H:%M"`
2. Append to the transcript file using the Edit tool (find the last line of content and add after it):

```markdown
### {HH:MM} — Note

{text}
```

3. Confirm inline: `Appended note to transcript.`

Note: In dialogue mode, this confirmation is a status report and should NOT be double-appended by the dialogue mode rules.

---

### `stop`

Finalize the transcript and stop capturing.

**Steps:**

0. **Locate transcript file.** Use the file path from context. If no path is in context, run the Recovery procedure below to find the active transcript. If no active transcript is found, report "No active transcript." and exit.

1. Get current time: `date "+%H:%M"`
2. Append footer to the transcript file using the Edit tool:

```markdown
---

_Transcript ended at {HH:MM}_
```

3. Confirm: `Transcript saved: {file path}`
4. **Stop dialogue capture.** You are no longer appending exchanges to the transcript. Resume normal response behavior.

---

### `list`

List recent transcripts across all projects.

**Steps:**

1. Use Glob to find all `.md` files matching `usr/jordan/*/transcripts/*.md`.
2. Sort by filename (which embeds the date-time, so alphabetical = chronological). Take the most recent 15.
3. For each file, read just the header (first 10 lines) to extract:
   - **Date** — from the `**Date:**` line
   - **Topic** — from the `# Discussion:` or `# Transcript:` heading
   - **Project** — from the `**Project:**` line
   - **Status** — check if the file has a footer line starting with `_Transcript ended` (stopped) or not (active)
4. Present as a table:

```
| Date       | Topic              | Project  | Status  | Path                                          |
|------------|--------------------|----------|---------|-----------------------------------------------|
| 2026-03-29 | Agency Merge Plan  | captain  | Active  | usr/jordan/captain/transcripts/20260329-...md  |
| 2026-03-28 | Design Review      | folio    | Stopped | usr/jordan/folio/transcripts/20260328-...md    |
```

5. If no transcripts found, report: "No transcripts found."

---

### `status`

Report the current transcript state.

**Steps:**

Always cross-check against the actual file, even if you think you remember the state from context.

1. **Detect project** using the branch rules from `start` step 2.
2. Use Glob to find the most recent `.md` file in `usr/jordan/{project}/transcripts/`. If nothing found, try `usr/jordan/*/transcripts/`.
3. Read the file. Check if it has a footer line starting with `_Transcript ended`.
   - If footer exists → report: "No active transcript. Last transcript: {file path} (stopped)"
   - If no footer → report: "Active transcript: {file path}, mode: {mode from header}"

---

## Dialogue Mode — Ongoing Behavior

**This section defines persistent behavior that activates when a transcript starts in dialogue mode. It remains active until `/transcript stop` is invoked.**

Use the file path established by `/transcript start`. If context was compressed and the path is lost, use the Recovery procedure below to locate the active file before appending.

After EVERY substantive response you give to the user, you MUST also append the exchange to the transcript file using the Edit tool. Append after the last line of content in the file.

**For each exchange, append:**

```markdown
### {HH:MM} — Jordan

{The user's message — cleaned up for readability, preserving their intent and key phrases}

### {HH:MM} — {Agent Name}

{Your response — summarized to key points, not the full verbose response. Capture the essence: what you said, what you decided, what you recommended. 2-5 sentences typically.}
```

**Rules:**

- Get the current time with `date "+%H:%M"` for each entry.
- **Summarize your responses** to key points. Do NOT copy your full response verbatim — a 500-word response becomes 2-3 sentences capturing the decision or key information.
- **Preserve the user's words** more faithfully — their messages are usually concise already.
- **Do this silently.** Do not announce "I'm appending to the transcript" each time. Just do it as part of your turn.
- **Skip these turns** — do NOT append:
  - Tool-use-only turns (reading files, running commands with no discussion)
  - Status reports and confirmations
  - The `/transcript` commands themselves
  - Turns where you're only doing internal work (no user-facing discussion)
- **"Substantive" means:** a response involving discussion, decision, information exchange, design work, or question-and-answer. If the user said something and you said something meaningful back, capture it.

---

## Recovery After Context Compression

If you are unsure whether a transcript is active, or you need to locate the transcript file:

1. **Detect project** using the branch rules from `start` step 2.
2. Use Glob to find the most recent `.md` file in `usr/jordan/{project}/transcripts/`. If nothing found, try `usr/jordan/*/transcripts/`.
3. Read its header to determine:
   - **Mode** (dialogue, review, or design)
   - **File path** (you need this to append)
4. Check if the file has a footer line starting with `_Transcript ended`
   - If YES → transcript is stopped, do nothing
   - If NO → transcript is still active
5. If active and mode is `dialogue`, resume appending exchanges using the rules above.
6. If active and mode is `review` or `design`, wait for explicit `/transcript capture` or `/transcript append` invocations.
