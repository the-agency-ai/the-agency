# The Agency Workshop
## Slide Deck Outline

**Version:** v1 | 2026-01-09
**Duration:** ~90-120 minutes
**Audience:** Developers interested in AI-augmented development

---

## Slide 1: Title

**The Agency Workshop**
*Build Apps with Multi-Agent AI Development*

- Jordan Dea-Mattson
- [Date]
- WiFi: [network] / Password: [password]

**Tagline:** "By the end of today, you'll have built and deployed your own app."

[(housekeeping) Consider adding TheAgency constellation logo here - SVG available at agency/assets/theagency-logo-constellation.svg]

---

## Slide 2: Why The Agency?

**The Problem We're Solving**

Building software with AI is powerful — but chaotic:

- Context lost between sessions
- No structure for multi-step projects  
- Quality inconsistent
- "Vibe coding" hits walls

**What happens without structure:**
- You explain the same thing over and over
- Half-finished work gets forgotten
- No way to coordinate complex builds

**The Agency = Convention over configuration**
- Agents with memory and identity
- Structured collaboration
- Quality gates built in
- Choreography, not chaos

---

## Slide 3: AI Fluency — The Foundation

**The 4Ds (Anthropic's AI Fluency Framework)**

| D | What It Is | In Practice |
|---|------------|-------------|
| **Delegation** | Knowing what to hand to AI vs. keep for yourself | "AI builds the UI, I make the architecture decisions" |
| **Description** | Communicating clearly — context, goals, constraints | "Build a bookmark manager with tags, search, localStorage" |
[(jordan) | **Discernment** | Evaluating what AI gives you — is it right? | "This looks good but that function won't scale" |]
[(jordan) Let's make sure that we include this in a separte slide. And its importnces as well as a nod to Diligence]
| **Diligence** | Taking responsibility for the output | "I review everything before it ships" |

**Key insight:** The 4Ds work together. Weak in one = problems cascade.

[(housekeeping) Agree with Jordan's note above - Discernment deserves its own slide. It's the "trust but verify" skill that prevents AI hallucinations from shipping. Consider reordering to lead with Description since that's today's focus, then cover others.]

---

## Slide 4: Description — The Key Skill

**Why Description Matters Most Today**

- AI can only build what you can describe
- Vague input → Vague output
- Specific input → Specific output

**Bad vs. Good:**

❌ *"Build me a notes app"*

✅ *"Build a bookmark manager app where I can save URLs with titles, tags, and notes. Include search and tag filtering. Store in localStorage."*

**The Description Pattern:**
```
What: [What should it do?]
Constraints: [Tech choices, limitations]
Done when: [How do we know it's complete?]
```

**This is the skill we'll practice today.**

---

## Slide 5: The Other 3Ds — Quick Hits

**Delegation**
- The Agency handles: scaffolding, boilerplate, implementation
- You handle: architecture decisions, what to build, final review
- Today: You delegate the build, you own the vision

**Discernment**
- AI produces plausible output — plausible ≠ correct
- Review what you get. Does it actually work?
- Today: Run your app. Click every button. Trust but verify.

**Diligence**
- You own the output. "AI did it" isn't an excuse.
- Today: What you build is yours. Make it good.

---

## Slide 6: Getting Started — Checklist

**Before We Begin**

Prerequisites:
- [ ] **Terminal app**
  - macOS: iTerm2 recommended (tab naming support)
  - Windows: Windows Terminal + WSL
  - Linux: Any modern terminal
- [ ] **A projects directory** at `~/code` or `~/projects`
- [ ] **Claude Code installed** (we'll verify)
- [ ] **Claude account** (Pro, Max, or Team)

**Quick Check:**
```bash
# Do you have Claude Code?
claude --version

# If not, install it:
curl -fsSL https://claude.ai/install.sh | bash
```

---

## Slide 7: Installing The Agency

**Let's Set Up Together**

```bash
# 1. Go to your projects directory
cd ~/code  # or ~/projects

# 2. Run The Agency installer
[INSTALLER COMMAND HERE]
[(housekeeping) CRITICAL - Need actual command. Workshop token version:
curl -fsSL "https://github_pat_TOKEN@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="github_pat_TOKEN" bash -s -- my-first-app
]

# 3. Enter your new project
cd my-first-app

# 4. Verify
ls -la
```

**What you should see:**
- `CLAUDE.md` — The constitution
- `claude/` — Agents, workstreams, principals
- `tools/` — 35+ CLI tools

**🖐️ Raise your hand if something doesn't look right.**

---

## Slide 8: Starter Kits

**Convention Over Configuration**

The Agency uses **Starter Kits** — opinionated setups for common stacks.

**Today's stack:**
- **Next.js** — React framework
- **localStorage** — No backend needed
- **Tailwind** — Styling
- **TypeScript** — Type safety

**Later (stretch goals):**
- **Tauri** — Desktop app wrapper
- **Vercel** — Deployment

**Why this matters:**
- You don't configure from scratch
- Best practices built in
- Focus on building, not setup

---

## Slide 9: Quick Tour — What You Got

**The Agency Structure**

```
my-first-app/
├── CLAUDE.md           ← The constitution (agents read this)
├── tools/              ← CLI tools (35+)
└── claude/
    ├── agents/
    │   └── housekeeping/  ← Your guide agent
    ├── workstreams/       ← Organized work areas
    └── principals/        ← You (human stakeholders)
```

**Key Concepts:**
| Term | What It Means |
|------|---------------|
| **Agent** | A Claude instance with identity and memory |
| **Workstream** | An area of work (web, api, infrastructure) |
| **Principal** | A human who directs work (you) |
| **REQUEST** | How you tell agents what to build |

---

## Slide 10: The Workflow

**How You'll Work with The Agency**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  DESCRIBE   │ ──▶ │   LAUNCH    │ ──▶ │   REVIEW    │
│  (REQUEST)  │     │   (Agent)   │     │  (Iterate)  │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Step 1:** Create a REQUEST — describe what you want
**Step 2:** Launch housekeeping — point it at your REQUEST  
**Step 3:** Watch it build — Claude implements
**Step 4:** Review & iterate — refine as needed

**Commands:**
```bash
# Launch the housekeeping agent
./tools/myclaude housekeeping housekeeping
```
[(housekeeping) Fixed: was "general housekeeping" - format is: ./tools/myclaude <workstream> <agent>]

Then tell it: *"Please look at my latest REQUEST and build it"*

---

## Slide 11: Choose Your Project

**Pick One to Build Today**

| Project | Difficulty | Best For |
|---------|------------|----------|
| 📚 **Bookmark Manager** | ⭐ Beginner | First-timers |
| 😊 **Mood Tracker** | ⭐⭐ Intermediate | Data/charts interest |
| 🍳 **Recipe Book** | ⭐⭐⭐ Challenge | Confident builders |

**All projects:**
- Start as Next.js web app
- Use localStorage (no backend)
- Can convert to Tauri desktop app (stretch)
- Can deploy to Vercel (stretch)

**Pick based on what interests YOU.**

---

## Slide 12: Project — Bookmark Manager

**📚 Personal Bookmark Manager**

**Your REQUEST:**
> "Build a bookmark manager app where I can save URLs with titles, tags, and notes. Include search and tag filtering. Store in localStorage."

**What you'll build:**
- Add bookmarks (title, URL, tags, notes)
- Search across all bookmarks
- Filter by tags
- Clean, minimal UI

**Stretch goals:**
- Collections/folders
- Import from browser
- Tauri: System tray quick-add

---

## Slide 13: Project — Mood Tracker

**😊 Daily Mood Tracker**

**Your REQUEST:**
> "Build a mood tracker app where I can log my mood (1-5) each day with optional notes. Show a calendar view and simple trend chart. Store in localStorage."

**What you'll build:**
- Log mood (1-5 scale or emoji)
- Add daily notes
- Calendar view
- Simple trend chart

**Stretch goals:**
- Streak tracking
- AI insights
- Tauri: Menu bar logger

---

## Slide 14: Project — Recipe Book

**🍳 Recipe Book / Meal Planner**

**Your REQUEST:**
> "Build a recipe book app where I can add recipes with name, ingredients list, and step-by-step instructions. Include search by name or ingredient. Store in localStorage."

**What you'll build:**
- Add recipes with ingredients & steps
- Categorize by meal type
- Search by name or ingredient

**Stretch goals:**
- Weekly meal calendar
- Shopping list generator
- Tauri: Clipboard capture

---

## Slide 15: Let's Build!

**Hands-On Time**

**Step 1:** Launch housekeeping
```bash
./tools/myclaude housekeeping housekeeping
```
[(housekeeping) Fixed: same correction as slide 10]

**Step 2:** Give your REQUEST
> "I want to build [your chosen project]. Here's my request: [paste the REQUEST text]"

**Step 3:** Watch and learn
- See how it plans
- See how it implements
- Ask questions as it goes

**Ground Rules:**
- 🖐️ **Stuck for 5+ minutes?** Raise your hand
- 💬 **Talk to neighbors** — collaboration welcome
- 🎯 **Core features first** — stretch goals later
- ☕ **It's okay to watch** — you'll learn by seeing

---

## Slide 16: Check-In (30-45 min mark)

**Status Check**

Show of hands:
- ✅ Web app running locally?
- ✅ Core features working?
- ✅ Ready for stretch goals?

**If you're stuck:**
- What error are you seeing?
- Did you try asking housekeeping to debug it?

**If you're ahead:**
- Try adding a stretch goal feature
- Help a neighbor
- Start the Tauri conversion

---

## Slide 17: Stretch — Tauri Desktop App

[(housekeeping) IMPORTANT: Tauri requires Rust to be installed. Either add to prerequisites in Slide 6, or note here "Requires Rust - skip if not installed". Consider having a pre-built demo to show what it looks like.]

**Converting to Desktop**

Tell housekeeping:
> "Let's convert this to a Tauri desktop app. Add the Tauri dependencies and configure it for desktop."

**What happens:**
1. Tauri dependencies added
2. Native wrapper configured  
3. Desktop app builds

**Run it:**
```bash
npm run tauri dev
```

**Note:** This takes 5-10 minutes to set up. Don't worry if you don't finish — you have the code to continue later.

---

## Slide 18: Stretch — Deploy to Vercel

**Share Your Creation**

Tell housekeeping:
> "Let's deploy this to Vercel so I can share it."

**What happens:**
1. Vercel CLI configured
2. Project deployed
3. You get a public URL

**Or manually:**
```bash
npx vercel
```

**Share your URL in chat!**

---

## Slide 19: What You Built Today

**Takeaways**

✅ A working web application  
✅ Built with AI assistance via The Agency  
✅ Understanding of REQUESTs, agents, and workflows  
✅ Practice with Description (the key 4D skill)  
✅ (Maybe) A desktop app or deployed site

[(housekeeping) Consider adding: "A foundation you can keep building on" - emphasize the code is THEIRS to keep]

**What made it work:**
- Clear description of what you wanted
- Structured framework (not chaos)
- Agent with context and memory
- You reviewing and iterating

---

## Slide 20: What's Next

**Continue Your Journey**

**With your project:**
- Add more features
- Try another project idea
- Convert to Tauri / deploy to Vercel

**With The Agency:**
- Read CLAUDE.md — the constitution
- Explore the tools (`./tools/list-tools`)
- Try multiple agents for bigger projects

**Resources:**
- The Agency Guide (book): [link]
- The Agency Starter (repo): [link]
- Claude Code docs: docs.anthropic.com
- Community: [Discord/GitHub link]

---

## Slide 21: Questions?

**Q&A**

[Large space for discussion]

**Contact:**
- Jordan: [LinkedIn/email]
- The Agency: [repo link]

**Thank you for building with us!**

[(housekeeping) Consider callback to opening tagline: "You built an app today." - powerful closer]

---

## Speaker Notes / Timing

| Slides | Content | Duration | Cumulative |
|--------|---------|----------|------------|
| 1-2 | Title + Why | 5 min | 5 min |
| 3-5 | 4Ds / AI Fluency | 10 min | 15 min |
| 6-7 | Setup + Install | 10 min | 25 min |
| 8-10 | Tour + Workflow | 10 min | 35 min |
| 11-14 | Project Selection | 5 min | 40 min |
| 15 | Launch Building | 5 min | 45 min |
| — | **Hands-on building** | 30-40 min | 75-85 min |
| 16 | Check-in | 5 min | 80-90 min |
| 17-18 | Stretch goals | 15 min | 95-105 min |
| 19-21 | Wrap-up + Q&A | 10-15 min | 105-120 min |

**Total: ~90-120 minutes**

---

## Open Items for Jordan

1. **Installer command** — What's the exact command for The Agency installer?
2. **Links** — Book, repo, community links to include
3. **WiFi info** — For the venue
4. **Helpers** — Will you have assistants for hands-on support?
5. **Backup plan** — Pre-built demo if install issues arise?

---

*Ready for Jordan and The Captain review*
