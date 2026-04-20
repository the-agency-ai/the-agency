# REQUEST-jordan-0006-housekeeping-provide-reviw-feedback-on-workshop-slides

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** In Review

**Priority:** Normal

**Created:** 2026-01-09 13:06 SST

**Updated:** 2026-01-09 15:15 SST

## Summary

Provide reviw feedback on Workshop Slides at:

/Users/jdm/code/the-agency/claude/principals/jordan/requests/the-agency-workshop-slides-outline-v1.md

Use the convention we have for providing feedback.

[(housekeeping) Feedback Convention]
[(housekeeping) My feedback!]

## Details

<!-- Detailed description of what you're requesting -->

## Acceptance Criteria

- [x] Feedback provided on slide content
- [x] Inline comments added to slides document
- [ ] Jordan reviews and addresses feedback

## Notes

<!-- Any additional context, constraints, or preferences -->

---

## Activity Log

### 2026-01-09 13:06 SST - Created
- Request created by principal:jordan

### 2026-01-09 15:15 SST - Feedback Provided

## [(housekeeping) Overall Assessment]

**Strengths:**
- Excellent flow from Why → Concepts → Setup → Build
- 4Ds framework well-integrated
- Good timing estimates
- Project options are well-scoped
- "Ground Rules" slide is smart for workshop management

**Areas to Address:**

| Slide | Issue | Suggestion |
|-------|-------|------------|
| 3 | Jordan noted: Discernment needs separate slide | Agree - it's the safety net skill |
| 7 | Installer command placeholder | Need to fill in actual command |
| 10 | Command says `general housekeeping` | Should be `housekeeping housekeeping` |
| 8 | Starter Kits mentioned but install doesn't show selection | Clarify when/how starter kit is applied |
| 15 | Same command issue | Fix to `housekeeping housekeeping` |
| 17 | Tauri conversion may need prerequisites | Note: Rust must be installed |

---

## [(housekeeping) Detailed Feedback]

### Slide 3: 4Ds Table
- Jordan's inline note about Discernment is spot-on
- Consider: Lead with Description since that's the focus skill for today
- Diligence row feels abbreviated compared to others

### Slide 7: Installing The Agency
- **Critical:** Need the actual installer command
- Based on our setup, it should be:
```bash
curl -fsSL "https://[TOKEN]@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="[TOKEN]" bash -s -- my-first-app
```

### Slide 8: Starter Kits
- Good concept explanation
- **Question:** Does the installer auto-apply the Next.js starter kit, or do they need to do something?
- If manual, add the command

### Slide 10 & 15: Command Error
- `./tools/myclaude general housekeeping` → should be `./tools/myclaude housekeeping housekeeping`
- Format: `./tools/myclaude <workstream> <agent>`

### Slide 17: Tauri Prerequisites
- Tauri requires Rust to be installed
- This could be a blocker for some attendees
- Suggestion: Either pre-check this in Slide 6, or note it's "if you have Rust installed"

### Slide 19: What You Built Today
- Consider adding: "A foundation you can keep building on"
- The code is theirs to keep and extend

---

## [(housekeeping) Minor Suggestions]

1. **Slide 1:** Add TheAgency logo (constellation design now available)
2. **Slide 9:** The tree diagram is great - consider showing it during live install too
3. **Slide 16:** "Did you try asking housekeeping to debug it?" - great line, emphasize this
4. **Slide 21:** Consider ending with the tagline callback: "You built an app today."

---

## [(housekeeping) Open Questions]

1. Will attendees have Rust pre-installed for Tauri?
2. Should we have a "Plan B" pre-built demo app?
3. Is there a Slack/Discord for attendees to share their URLs?

---

**Inline feedback also added to the slides document.**
