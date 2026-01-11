# REQUEST-jordan-0035-housekeeping-agencybench-and-docbench-cli-integration

**Status:** Open
**Priority:** High
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-11

## Summary

AgencyBench and DocBench CLI integration

## Details

Improve AgencyBench and DocBench CLI integration for seamless document workflow.

## Requirements

### 1. Launch AgencyBench from CLI
- Easy command to launch AgencyBench application
- Works inside or outside Claude Code
- Example: `./tools/agency-bench` or `./tools/open-agency-bench`

### 2. Open Document in DocBench (Tool for Claude)
- Tool that Claude can use: "please open X for me in doc-bench"
- Takes a file path, opens in DocBench
- Example: `./tools/docbench open /path/to/file.md`

### 3. Open Document in DocBench (CLI)
- Command-line way to open a doc in DocBench
- Simple: command + path
- Example: `./tools/docbench /path/to/file.md`

### 4. Open Arbitrary Document with Full Path
- Support opening any document by full path
- Not limited to project files
- Example: `./tools/docbench open ~/Documents/notes.md`

### 5. Save As Functionality
- Ability to "Save As" an open document in DocBench
- Save to a different location/name
- UI or command support

## Deliverables
- [ ] `./tools/agency-bench` - launch AgencyBench app
- [ ] `./tools/docbench` - CLI for DocBench operations
- [ ] `./tools/docbench open <path>` - open document
- [ ] `./tools/docbench save-as <path>` - save as
- [ ] Integration with Claude Code (tool use)

## Acceptance Criteria

<!-- How will we know when this is complete? -->
- [ ] Criteria 1
- [ ] Criteria 2

## Notes

<!-- Any additional context, constraints, or preferences -->

---

## Activity Log

### 2026-01-11 - Created
- Request created by agent:housekeeping (on behalf of jordan)
