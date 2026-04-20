---
type: seed
workstream: agency
date: 2026-04-10
subject: "This Happened!" + "Breadcrumb" — value-added services from The Agency
---

# This Happened! + Breadcrumb

Two complementary value-added services from The Agency, designed to be human-friendly AND agent-friendly.

## Breadcrumb — Distributed Trace Chain

**What:** A correlation ID service using UUID7 identifiers that chain across service boundaries.

**How it works:**
- Every call gets a UUID7 identifier (time-ordered — sequence is embedded in the ID itself)
- When a call crosses a service boundary, the receiving service adds its own UUID7 while preserving the parent
- Chain: `UXCall_UUID7 → APICall1_UUID7 → ServiceCall2_UUID7 → ...`
- All IDs go into logs at every level
- UUID7's time-ordering means you can reconstruct sequence without a centralized clock

**The pattern:**
```
User action → UI event (UUID7-A)
  → API call (UUID7-A → UUID7-B)
    → Database query (UUID7-A → UUID7-B → UUID7-C)
    → External service (UUID7-A → UUID7-B → UUID7-D)
```

**Not new** — this is distributed tracing (OpenTelemetry trace/span IDs). What's different:
- UUID7 instead of random trace IDs — time-ordered, sortable, no clock sync needed
- Designed for both human and agent consumption
- Integrated with "This Happened!" for end-to-end traceability from user report to root cause
- Greenfield-friendly (monofolk bakes it in from day one)
- Retrofit-friendly (add at API gateway layer for existing systems)

**Name:** Breadcrumb — follow the trail from where you are back to where it started. Hansel and Gretel, but for distributed systems.

## This Happened! — User Issue Reporting with Automatic State Capture

**What:** A user-facing issue reporting mechanism that automatically captures runtime state at the moment the user reports a problem.

**The name:** "This Happened!" — as in: no, it DID happen. Don't deny it. Here's what happened and where.

**How it works:**
- User hits a problem → taps "This Happened!" (or equivalent trigger)
- System automatically captures:
  - Current screen / UI state
  - Recent user actions (last N interactions)
  - In-flight API calls and their Breadcrumb trace IDs
  - Device state (memory, network, OS version, app version)
  - Relevant logs from the last N seconds
  - Active feature flags / configuration
- User can optionally add a note ("I was trying to...")
- Everything gets bundled into a structured report
- The Breadcrumb trail connects the report to the exact call chains that were executing

**Why it matters:**
- User doesn't have to describe what happened — the system already knows
- Support doesn't have to ask "can you reproduce it?" — they have the trace
- Agents can parse the structured data and diagnose automatically
- The Breadcrumb chain means you go from "it's broken" → exact service → exact failure

**Together:**
- **This Happened!** captures the WHAT — runtime state, user context, the moment of impact
- **Breadcrumb** traces the WHERE — the call chain across every service boundary
- This Happened! automatically attaches the active Breadcrumb trails to every report
- Support/agents follow the breadcrumbs from the user's "it happened" moment to root cause

## Design Principles

- **Human-friendly:** Whimsical names, clear UI, no jargon. A user taps "This Happened!" — they don't "file a JIRA ticket with reproduction steps."
- **Agent-friendly:** Structured data, correlation IDs, machine-parseable reports. An agent reads the This Happened! report + Breadcrumb chain and diagnoses without asking for more context.
- **Built for greenfield, retrofit for brownfield:** Monofolk bakes both in from day one. Existing systems can add Breadcrumb at the API gateway and This Happened! at the UI layer.
- **Whimsical branding** — we have the kittens, we have the voice. These are Agency services, not enterprise middleware.

## Status

- **Breadcrumb:** Pattern defined. Implementing in monofolk from the ground up.
- **This Happened!:** Concept captured. Needs PVR + A&D.
- **Both:** Value-added services from The Agency — ship as part of the framework or as standalone packages.
