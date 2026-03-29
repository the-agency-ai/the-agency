# Mock and Mark — PVR Discussion Transcript

**Date:** 2026-03-29
**Participants:** jordan (principal), mock-and-mark agent

---

## Item 1 — Product Name

**Agent:** There's a split in the seed material. "Mark and Mock" is used consistently in the design doc v1.1 and the original chatlog. Mark first reflects the Phase 1 priority. But "Mock and Mark" is used in the agent definition, workstream name, and all Agency scaffolding. Which is the canonical product name? And should the agent/workstream be renamed to match, or does the current naming stick?

**Jordan:** Which do you think is the better name?

**Agent:** I think "Mock and Mark" is the better name. "Mock" is the more distinctive, creative-first verb — it leads with what makes the app unique (sketch → lo-fi wireframe cleanup). "Mark" (annotation) is useful but more conventional. "Mock and Mark" has a better rhythm too — the short punchy word first, then the softer one. It also mirrors the creative flow: you mock up something new, then you mark up what exists. Even though Mark ships first in Phase 1, the name should reflect the product vision, not the release order. So my read: "Mock and Mark" is canonical, the seed doc's "Mark and Mock" was just the original working name, and the Agency scaffolding already has it right. Does that match your thinking, or do you see it differently?

**Jordan:** And we should be consistent in agent and worktree naming.

**Agent:** So you're saying: the name is "Mock and Mark" everywhere — agent, workstream, worktree, docs — and the worktree name should reflect the full scope of work (PVR + A&D + beyond), not just this first discussion. Is that right?

**Jordan:** Yes, I am.

**Decision:** "Mock and Mark" canonical everywhere.

---

## Item 2 — Claude Code Target

**Agent:** The seed doc says "Claude Desktop & Claude Code" throughout, but the original chatlog explicitly removed the Anthropic API from the app. The question is: what's the actual delivery target? Claude Code (CLI), Claude Desktop (chat app), or both? The packet format is target-agnostic — a ZIP with PNG + JSON + markdown works for anything. Should we frame this as "Claude-agnostic structured export" rather than targeting a specific Claude product?

**Jordan:** It is targeted for claude for coding. Particularly Claude Code. So, if we give up anything to be agnostic, that is an issue.

**Agent:** So you're saying: the primary target is Claude Code specifically — this is a tool for developers communicating visual intent to a coding agent. If supporting Claude Desktop or being "agnostic" means compromising anything for the Claude Code use case, that's the wrong trade-off. Is that right?

**Jordan:** Yep. Of course we have Claude Code on the desktop.

**Agent:** Right — Claude Code runs on the desktop (Mac terminal), so "Claude Desktop" as a separate target is moot. The user is already in Claude Code on their Mac when they receive the packet.

**Jordan:** No, it runs in the Claude App which has Claude Chat, Cowork, and Code.

**Agent:** So you're saying: Claude Code isn't just the CLI terminal tool — it lives inside the Claude App alongside Chat and Cowork modes. The target is the Claude App's Code mode specifically, but the packet lands in the same app ecosystem. Is that right?

**Jordan:** Yes.

**Decision:** Primary target is Claude Code within the Claude App. No compromises for other targets.

---

## Item 3 — Distribution Strategy

**Agent:** The seed doc lists this as an open question: App Store, TestFlight, or internal/enterprise only for v1? This matters because App Store requires accessibility compliance, review process, privacy nutrition labels, potentially longer iteration cycles. TestFlight gives up to 10,000 external testers, no App Store review requirements, 90-day expiry. Internal is just build and run via Xcode, fastest iteration, zero gatekeeping. For a v1 that's primarily a personal/team tool for Claude Code developers, what's your thinking?

**Jordan:** We will progress through internal only -> testflight -> app store.

**Agent:** So you're saying: a graduated rollout — start internal (Xcode direct), move to TestFlight when it's ready for broader testing, then App Store when it's polished. No need to design for App Store constraints from day one. Is that right?

**Jordan:** Yes, as we develop it.

**Decision:** Internal → TestFlight → App Store. Graduated rollout.

---

## Item 4 — AI and Network Policy

**Agent:** The seed doc already removed the Anthropic API from the app. All sketch cleanup uses on-device Vision framework. No network calls for core functionality. The question: is offline-first a hard requirement — meaning the app must be fully functional with no network connection? Or is it just a consequence of the "no AI in the app" decision, and we'd allow network for things like iCloud sync, updates, etc.? My read: core features (mark, mock, sketch cleanup, export) must work offline. Network is fine for sync/delivery features (iCloud, companion app handoff).

**Jordan:** It is the "no ai in the app decision"

**Agent:** So you're saying: offline-first isn't a standalone requirement — it's a natural consequence of "no AI in the app." Network is fine where it makes sense (iCloud sync, companion handoff). The principle is no AI dependency, not no network. Is that right?

**Jordan:** Yes - "core features (mark, mock, sketch cleanup, export) must work offline" Yes - Network is fine for sync/delivery features (iCloud, companion app handoff)

**Agent:** No AI in the app is the principle. Core features work offline as a consequence. Network is permitted for sync and delivery (iCloud, companion handoff). Agreed? Item 5?

**Jordan:** It is really: No AI via a cloud API. We can use local AI provided by the apple platforms

**Agent:** Good distinction. So you're saying: the principle is no cloud AI API calls — but on-device AI provided by Apple frameworks (Vision, CoreML, etc.) is fair game. That's what makes the sketch cleanup possible in the first place. Is that right?

**Jordan:** Correct.

**Decision:** No cloud AI APIs. On-device Apple AI (Vision, CoreML, etc.) encouraged. Network for sync/delivery.

---

## Item 5 — Phase Roadmap

**Agent:** There's a mismatch between the two seed docs. Design doc v1.1 has 6 phases over 18 months. Analysis doc has 3 phases. Two questions: which phasing is right? Should flow diagrams move earlier?

**Jordan:** First off, those timelines are absolutely crazy ;) It isn't going to take that long. I think it is iPad App broken into phases: Mark, Mock, iCloud, Figma Import(?). What is Flow diagrams?

**Agent:** Flow diagrams was Phase 4 in the seed doc — the idea of multi-canvas projects where you connect screens together with arrows to show navigation flows. Like "Login Screen → Home Screen → Settings Screen" as a linked graph, with a flow overview map and the full flow graph exported in components.json. Essentially: going from single-screen mockups to multi-screen user journeys.

**Jordan:** Yeah, that is before Figma. We need to see how it plays with Figma later. And Mac Os is later, once iPad is working. We need the iCloud sync to shift things between Mac OS and iOS (because Mac OS is where they are running Claude Code).

**Agent:** So the phasing is: Mark, Mock, iCloud sync, Flow diagrams, Figma import, macOS app. And iCloud sync is critical infrastructure, not a nice-to-have — because the whole point is getting packets from iPad to Mac where Claude Code lives. Is that right?

**Jordan:** And from Mac to iPad and back again.

**Agent:** Right — iCloud sync is bidirectional. iPad to Mac for delivery to Claude Code, Mac to iPad for pulling in screenshots or continuing work. It's a continuous workflow across devices, not a one-way export pipe.

**Jordan:** Yep. It is.

**Decision:** Mark → Mock → iCloud (bidirectional) → Flow diagrams → Figma (TBD) → macOS. No fixed timelines.

---

## Item 6 — Collaboration

**Agent:** The seed doc confirms single-user for v1 and asks when multi-user annotation sessions arrive. My read: this is a solo developer tool. Multi-user collaboration feels like a different product entirely. Is collaboration even in scope, or should we explicitly cut it?

**Jordan:** Agreed. Item 6 next.

**Agent:** Multi-user collaboration is out of scope. This is a solo developer tool. Agreed on Item 6? Ready for Item 7?

**Jordan:** Multi-User collaboration is not in scope at this point.

**Agent:** So you're saying: don't rule it out forever, but it's not in scope for the current product vision. We're not designing for it or planning for it — if it ever becomes relevant, it's a future conversation. Is that right?

**Jordan:** Maybe someday. But I don't see the value.

**Decision:** Out of scope. No current value seen.

---

## Item 7 — Accessibility and Localization

**Agent:** The seed doc asks whether VoiceOver and Switch Control are required for v1 or deferred. Since we're starting internal-only and graduating to App Store later, we don't need App Store accessibility compliance on day one. But good accessibility habits are easier to build in from the start than to retrofit. SwiftUI gives you a lot for free. My take: don't make it a blocker for internal/TestFlight phases, but build with accessibility in mind. Full VoiceOver/Switch Control audit before App Store submission. Your thinking?

**Jordan:** Yes, good habits and take what we get out of the box. Just like we will for localization

**Agent:** So you're saying: leverage what SwiftUI gives for free on both accessibility and localization. Don't do extra work for either right now, but don't fight the frameworks either. Full compliance comes later when we target App Store. Is that right?

**Jordan:** Do the right stuff, and see if that is enough. I see a lot of apps that don't have any accesibility in the App Store.

**Agent:** Accessibility and localization — do the right stuff with SwiftUI defaults. Don't over-invest, don't ignore. Assess when App Store time comes. Agreed? Item 8?

**Jordan:** To be clear: we are not going to do special work or come up with a way to make doing work with an Apple Pencil accesisble. But we are not going to do anything that is an anti-pattern.

**Agent:** So you're saying: Apple Pencil is inherently a visual/motor tool — we're not going to invent accessibility solutions for that interaction model. But everywhere else (navigation, labels, export, project browser), we follow platform conventions and don't create barriers. Is that right?

**Jordan:** Correct.

**Decision:** Platform conventions, no anti-patterns. No special Pencil a11y. Same for localization.

---

## Item 8 — Export Packet Schema

**Agent:** The seed doc defines a ZIP with 6 files. For Phase 1 (Mark only), some don't apply yet: `components.json` is Mock only, `design-system.json` is listed as v2+. So Phase 1 packet would be: `manifest.json` + `canvas.png` + `annotations.json` + `prompt.md` — four files. The broader question: is this file set right for the long term, or does anything need to change?

*(Awaiting response...)*

---

## Item 9 — Vision Framework Realism
*(Pending)*

## Item 10 — Scope Guard for Phase 1
*(Pending)*
