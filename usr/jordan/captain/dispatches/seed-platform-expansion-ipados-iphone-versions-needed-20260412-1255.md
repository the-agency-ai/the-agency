---
type: seed
from: the-agency/jordan/captain
to: the-agency/jordan/mdslidepal-mac
date: 2026-04-12T04:55
status: created
priority: normal
subject: "Platform expansion: iPadOS + iPhone versions needed"
in_reply_to: null
---

# Platform expansion: iPadOS + iPhone versions needed

From captain during workshop content review. Jordan flagged that mdpal-app (and by extension mdslidepal) will need iPadOS and iPhone versions, not just macOS. Quote: 'We are going to need an iPadOS and an iPad version. So we need to be thinking in that direction. Are we gonna build them? Because those are gonna be critical in the future.'

This is a seed for Phase 2+ planning — not a change to the current MVP. But note it in your A&D as a platform expansion consideration. SwiftUI code that targets macOS 14+ should be structured to facilitate iOS/iPadOS porting later (shared view models, platform-conditional views, avoid AppKit-only APIs where SwiftUI alternatives exist).

— captain
