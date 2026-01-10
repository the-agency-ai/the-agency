# REQUEST-jordan-0010-housekeeping-simple-bug-reporting-and-tracking

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Open

**Priority:** Normal

**Created:** 2026-01-09 21:13 SST

**Updated:** 2026-01-09 21:13 SST

## Summary

Simple bug reporting and tracking

We need a simple - backed by a database, not by files - bug reporting and tracking system.

No need for priorites.

Because we are going to kill every bug as it comes in.

Simple Layout:
- Project
- Workstream
- Reporter (Agent, Principal, System)
- Assignee (Agent, Principal)
- Summary
- Description
- Details 
  - Could be attachments including a screen shot, a file, or a directory.
- XRef
  - Is this tied to a Request? Then reference it there.

Command Line tool for reporting
- Allow Agents and Systems to report issues.

{PROJECTID}-{WORKSTREAM}-##### numbering.

BugBench
A simple UX for:
- Reporting
- Viewing

## Details

### Database Schema

```sql
CREATE TABLE bugs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bug_id TEXT UNIQUE NOT NULL,        -- e.g., "BENCH-00001"
  workstream TEXT NOT NULL,           -- e.g., "bench", "housekeeping"
  summary TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'Open',         -- Open, In Progress, Fixed, Won't Fix
  reporter_type TEXT NOT NULL,        -- 'agent', 'principal', 'system'
  reporter_name TEXT NOT NULL,        -- e.g., "housekeeping", "jordan", "build-system"
  assignee_type TEXT,                 -- 'agent', 'principal', or NULL
  assignee_name TEXT,                 -- e.g., "housekeeping", "jordan", or NULL
  xref_type TEXT,                     -- 'request', 'bug', or NULL
  xref_id TEXT,                       -- e.g., "REQUEST-jordan-0010", "BENCH-00001"
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE bug_attachments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bug_id TEXT NOT NULL,
  filename TEXT NOT NULL,             -- Original filename
  filepath TEXT NOT NULL,             -- Path in claude/assets/bugs/{bug-id}/
  mime_type TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (bug_id) REFERENCES bugs(bug_id)
);

-- Sequence table for generating bug IDs
CREATE TABLE bug_sequences (
  workstream TEXT PRIMARY KEY,
  next_id INTEGER DEFAULT 1
);
```

### API Design (CLI-first)

The CLI tool models the API that could later become a proper REST/IPC API:

```bash
# Create a bug
./tools/report-bug --workstream bench --summary "..." [--description "..."] [--reporter "..."] [--assignee "..."] [--xref "..."]

# List bugs
./tools/list-bugs [--workstream bench] [--status open] [--assignee housekeeping]

# Update bug status
./tools/update-bug BENCH-00001 --status "Fixed"

# Assign bug
./tools/update-bug BENCH-00001 --assignee housekeeping

# Add attachment
./tools/attach-to-bug BENCH-00001 /path/to/screenshot.png

# View bug details
./tools/show-bug BENCH-00001
```

### BugBench UI Layout

```
+------------------+----------------------------------------+
| Filters          | Bug List                               |
|                  |----------------------------------------|
| Status: [All ▾]  | ID      Summary           Status       |
| Workstream: [▾]  |---------|-----------------|-------------|
| Assignee: [▾]    | BENCH-1 | Build fails...  | Open        |
|                  | BENCH-2 | UI glitch in... | In Progress |
| [+ New Bug]      | HK-42   | Doc gen error   | Fixed       |
+------------------+----------------------------------------+
                   | Bug Detail / Edit Form                 |
                   |----------------------------------------|
                   | ID: BENCH-00001                        |
                   | Status: [Open ▾]                       |
                   | Summary: [__________________]          |
                   | Description: [________________]        |
                   | Assignee: [____________ ▾]             |
                   | XRef: [________________]               |
                   | Attachments: [+ Add]                   |
                   |   - screenshot.png                     |
                   | [Save Changes]                         |
                   +----------------------------------------+
```

## Acceptance Criteria

- [x] Build number implemented (v0.1.0-20260109-009)
- [x] SQLite database at `claude/data/bugs.db` (shared between CLI and UI)
- [x] `./tools/report-bug` CLI tool working
- [x] BugBench app in AgencyBench sidebar
- [x] Can create bugs from UI
- [x] Can list/filter bugs
- [x] Can update bug status
- [x] Assignee notifications (on create and reassign)
- [ ] Can add attachments (future enhancement)

## Notes

- No priorities - "kill every bug as it comes in"
- Statuses: Open → In Progress → Fixed (or Won't Fix)
- Attachments copied to `claude/assets/bugs/{bug-id}/`

---

## Discussion & Planning

### 2026-01-09 - Questions & Decisions

**1. Database Architecture:**
- **Question:** Use existing AgencyBench SQLite DB or separate per app?
- **Decision (Jordan):** Each AgencyBench app should have its own SQLite DB

**Pros of separate DBs per app:**
- Isolation - bugs in one app's DB don't affect others
- Simpler schemas - each DB only has tables it needs
- Easier to backup/restore individual apps
- Can version/migrate independently
- Smaller file sizes, faster queries

**Cons:**
- Multiple DB connections to manage
- Harder to do cross-app queries (e.g., "show all bugs related to this request")
- More files to track

**Recommendation:** Separate DBs make sense. We can use a naming convention:
- `src-tauri/data/bugs.db` - BugBench
- `src-tauri/data/knowledge.db` - Knowledge Indexer
- etc.

**2. API Layer:**
- **Decision (Jordan):** Define an API on top of the databases
- CLI tool calls the API, which calls into the DB
- API design should be modeled in the CLI even before we build a proper API server

**3. Bug ID Format:**
- **Decision (Jordan):** `{WORKSTREAM}-#####` (no project prefix - tracker is scoped to a project)
- Examples: `BENCH-00001`, `HOUSEKEEPING-00042`

**4. Statuses:**
- **Decision (Jordan):** `Open`, `In Progress`, `Fixed`, `Won't Fix`
- Expectation: Short time in "In Progress", close to 100% fix rate

**5. Attachments:**
- **Decision (Jordan):** Option B - copy files and store path
- **Open Question:** Path structure for attachments?
  - Option A: `claude/attachments/bugs/` and `claude/attachments/requests/` (separate)
  - Option B: `claude/attachments/{type}/{id}/` (organized by item)
  - Option C: `claude/assets/` for all (images, attachments, etc.)

  Current image insertion uses `/claude/assets/images/`. Should we unify?
  - `claude/assets/images/` - general images
  - `claude/assets/bugs/{bug-id}/` - bug attachments
  - `claude/assets/requests/{request-id}/` - request attachments

**6. BugBench UI:**
- **Decision (Jordan):** Yes, new app in AgencyBench sidebar

**7. UI Features:**
- **Decision (Jordan):**
  - Can report a new bug
  - List view with filters
  - Click on bug to edit it

**8. CLI Tool:**
- **Decision (Jordan):** `./tools/report-bug --workstream bench --summary "..." --description "..."`
- Should model/mimic the API design

**9. Piping Support:**
- **Question:** Should CLI support `echo "details" | ./tools/report-bug`?
- **My thinking:** Could be useful for agents to pipe error output directly:
  ```bash
  npm run build 2>&1 | ./tools/report-bug --workstream bench --summary "Build failed"
  ```
  The piped content becomes the description. Thoughts?
- **Decision (Jordan):** TBD - implement basic version first, add piping later if useful

**Build Number:**
- **Decision (Jordan):** Implement now ✅
- Store in `src-tauri/BUILD`, increment on each build
- Display as `v0.1.0-20260109-001`
- Also updates `tauri.conf.json` for About box

---

## Open Issues

### Issue 1: Attachment Path Structure
**Status:** Needs Decision

Current proposal: `claude/assets/bugs/{bug-id}/`

**Questions:**
1. Should `{bug-id}` be the full ID like `BENCH-00001` or just the number?
   - Full ID: `claude/assets/bugs/BENCH-00001/screenshot.png` (clearer)
   - Number only: `claude/assets/bugs/00001/screenshot.png` (shorter but ambiguous across workstreams)

2. How to handle name collisions?
   - Add timestamp suffix: `screenshot-20260109-213015.png`
   - Or keep original name and let filesystem handle it?

**Recommendation:** Use full bug ID (`BENCH-00001`) and add timestamp suffix to filenames.

### Issue 2: Database Location
**Status:** Decided - `src-tauri/data/bugs.db`

**Questions:**
1. Should the `data/` directory be created automatically on first run?
2. Should there be a migration system for schema changes?

**Recommendation:** Yes to auto-create. Simple "schema version" table for future migrations.

### Issue 3: Reporter Auto-detection
**Status:** Needs Decision

**Questions:**
1. How should CLI auto-detect the reporter?
   - From `whoami` tool output?
   - From environment variable?
   - Always require explicit `--reporter`?

**Recommendation:** Try `./tools/whoami` first, fall back to requiring `--reporter`.

### Issue 4: Workstream Validation
**Status:** Needs Decision

**Questions:**
1. Should we validate workstream names against existing workstreams?
2. Or allow any string and auto-uppercase for the ID prefix?

**Recommendation:** Allow any string, auto-uppercase. Validation is optional enhancement.

---

## Activity Log

### 2026-01-09 - BugBench v1 Implemented (housekeeping)

**Changes Made:**

1. **CLI Tool** - Created `./tools/report-bug` that:
   - Creates bugs with auto-incrementing IDs (e.g., `BENCH-00001`)
   - Auto-detects reporter via `./tools/whoami`
   - Initializes database schema on first run

2. **Tauri Backend** - Added to `src-tauri/src/main.rs`:
   - `list_bugs` - List all bugs from database
   - `create_bug` - Create new bug with auto-ID generation
   - `update_bug_status` - Update bug status

3. **BugBench UI** - Created `src/app/bench/(apps)/bugbench/page.tsx`:
   - Sidebar filters (status, workstream, assignee)
   - Bug list with status badges
   - Detail panel for viewing/editing
   - New bug modal form
   - Stats display (total, open, in progress)

4. **Sidebar Integration** - Added BugBench to AppSidebar.tsx and Header.tsx

**Database Location:** `claude/data/bugs.db` (shared between CLI and UI)

**Files Created/Modified:**
- `./tools/report-bug` - CLI tool (new)
- `src-tauri/src/main.rs` - Added bug commands
- `src/app/bench/(apps)/bugbench/page.tsx` - BugBench UI (new)
- `src/components/bench/AppSidebar.tsx` - Added BugBench link
- `src/components/bench/Header.tsx` - Added BugBench title

**Build Status:** Build 009 - All features working

---

### 2026-01-10 - Assignee Notifications (housekeeping)

**Feature:** Notify assignees when bugs are assigned or reassigned to them.

**Design Decision (Jordan):**
- Notify assignees on assign and reassign
- Don't notify reporters when their bugs are closed (principals watch BugBench directly)

**Implementation:**

1. **CLI (`./tools/report-bug`)** - Sends message via `./tools/send-message` when `--assignee` is specified
   ```
   Created bug: HOUSEKEEPING-00002
     Summary: Test notification feature
     Assignee: housekeeping (agent)
     Notified: agent:housekeeping
   ```

2. **Tauri (`create_bug`)** - Calls `notify_bug_assignee()` helper after bug creation

3. **Tauri (`update_bug_assignee`)** - New command for reassignment with notification
   - Only notifies if assignee actually changed
   - Calls `notify_bug_reassignment()` helper

**Message Format:**
```
Subject: [HOUSEKEEPING-00002] New bug assigned to you

You have been assigned a new bug.

Bug ID: HOUSEKEEPING-00002
Summary: Test notification feature
Reporter: jordan (principal)
Workstream: HOUSEKEEPING

Description:
[if provided]

View in BugBench or run: ./tools/show-bug HOUSEKEEPING-00002
```

**Files Modified:**
- `./tools/report-bug` - Added notification after bug creation
- `src-tauri/src/main.rs` - Added `notify_bug_assignee()`, `notify_bug_reassignment()`, `update_bug_assignee` command

**Build Status:** Build 016 - Notifications working

---

### 2026-01-09 - Crash Fix: 16-bit PNG Icons (housekeeping)

**Problem:** App crashed on launch after adding BugBench with error:
```
invalid icon: The specified dimensions (32x32) don't match the number of pixels supplied by the `rgba` argument (2048). For those dimensions, the expected pixel count is 1024.
```

**Root Cause:** ImageMagick was generating 16-bit depth PNGs from the SVG logo. Tauri expects 8-bit RGBA PNGs. The 16-bit depth doubled the pixel data, causing the mismatch.

**Solution:** Added explicit PNG conversion options:
```bash
PNG_OPTS="-colorspace sRGB -alpha set -depth 8 -define png:bit-depth=8 -define png:color-type=6"
```

**Files Modified:**
- `scripts/generate-icons.sh` - Updated to force 8-bit RGBA PNGs
- `src-tauri/icons/*.png` - Regenerated with correct format

**Build Status:** Build 015 - App launches successfully with all features

---

### 2026-01-09 - Build Number Implemented (housekeeping)

**Changes Made:**

1. **BUILD counter file** - Created `src-tauri/BUILD` to store the incremental build number

2. **Increment script** - Created `scripts/increment-build.js` that:
   - Reads BUILD file and increments the counter
   - Generates `src/build-info.ts` with version info
   - Outputs format: `v{version}-{YYYYMMDD}-{NNN}`

3. **Build integration** - Added `prebuild` script to `package.json` that runs the increment script before each build

4. **Version display** - Updated `AppSidebar.tsx` to import and display `BUILD_INFO.fullVersion` (e.g., `v0.1.0-20260109-004`)

**Files Created/Modified:**
- `src-tauri/BUILD` - Build counter (new)
- `scripts/increment-build.js` - Increment script (new)
- `src/build-info.ts` - Generated build info (auto-generated)
- `package.json` - Added prebuild script
- `src/components/bench/AppSidebar.tsx` - Import and display build info

**Build Status:** Verified - Build successful, version displays as `v0.1.0-20260109-004`

### 2026-01-09 21:13 SST - Created
- Request created by principal:jordan
