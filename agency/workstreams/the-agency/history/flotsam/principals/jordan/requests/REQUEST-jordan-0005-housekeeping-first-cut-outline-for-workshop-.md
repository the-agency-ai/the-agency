# REQUEST-jordan-0005-housekeeping-first-cut-outline-for-workshop-

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** In Review

**Priority:** Normal

**Created:** 2026-01-09 12:35 SST

**Updated:** 2026-01-09 14:45 SST

## Summary

First Cut Outline for Workshop

Plese provide feedback

## Details

Okay, need your help in quickly building a PPT.



But first, let's nail the outline and the content, slide by slide, before we generate the PPT.



This is for a workshop where we will be introducing TheAgency to folks and getting them to try it hands-on.



I want to lead with why the agency? The problem we are trying to solve.



I want to take a quick jump into the basics/principals of AI Fluency and the 4Ds



We will then dig into Description as key and maybe other areas.



Then want a slide where we have a checklist to get started:





iTerm install



a directory for your projects, mine is called "code", some folks do "projects" created at the root of your home directory.



cd to ~/code or ~/projects



Run TheAgency installer (willl give them something on the command line)



Discuss the concept of starter kits.



Then I go a tour and explain things to them.



Then we launch them on their projects.



Project will:



- Start as Next.js web app

  - Use localStorage (no backend needed)

  - Convert to Tauri desktop app

  - Deploy to Vercel for sharing



We will give them one of a choice:

Personal Bookmark Manager



REQUEST to trigger:

  REQUEST Summary: "Build a bookmark manager app where I can save URLs with titles, tags, and notes. Include search and tag filtering. Store in localStorage."



What it does: A local-first bookmark manager with tags, search, and collections.

Features to build:





Add bookmarks with title, URL, description



Tag bookmarks for organization



Search across all bookmarks



Create collections/folders



Import from browser bookmarks (stretch goal)

Why it's good for the workshop:





Simple CRUD operations



Introduces local storage concepts



Can be enhanced with AI-powered tagging



Visual UI work with lists and cards



Easy to make it their own

Tauri Desktop Enhancement:





System tray quick-add



Keyboard shortcut to add current browser URL



Native file export



2. Daily Mood Tracker

REQUEST to Trigger: REQUEST Summary: "Build a mood tracker app where I can log my mood (1-5) each day with optional notes. Show a calendar view and simple trend

  chart. Store in localStorage."



What it does: Track daily moods with notes, see patterns over time.

Features to build:





Log mood (emoji scale or 1-5)



Add notes for the day



View calendar of moods



Simple charts showing mood over time



Streak tracking ("7 days logged!")

Why it's good for the workshop:





Date/time handling



Data visualization intro



Personal and relatable



Mobile-friendly design practice



Can add AI insights as stretch goal

Tauri Desktop Enhancement:





Daily reminder notification



Menu bar mood logger



Privacy-focused local storage



3. Recipe Book / Meal Planner

REQUEST to trigger: REQUEST Summary: "Build a recipe book app where I can add recipes with name, ingredients list, and step-by-step instructions. Include search

  by name or ingredient. Store in localStorage."



What it does: Save recipes, plan weekly meals, generate shopping lists.

Features to build:





Add recipes with ingredients and steps



Categorize by meal type



Weekly meal calendar



Auto-generate shopping list from planned meals



Scale recipe servings

Why it's good for the workshop:





Real-world useful app



Moderate complexity



Nice UI opportunities (recipe cards, calendar)



Data relationships (recipes → ingredients → shopping list)



Can add AI recipe suggestions

Tauri Desktop Enhancement:





Quick recipe capture from clipboard



Print-friendly recipe view



Offline-first for kitchen use




## Acceptance Criteria

- [ ] We have an outline for the workshop presentation

## Notes

<!-- Any additional context, constraints, or preferences -->

---

## Activity Log

### 2026-01-09 12:35 SST - Created
- Request created by principal:jordan

### 2026-01-09 14:45 SST - Feedback & Slide Content Proposal

## Feedback on Original Outline

### What's Working Well

1. **Logical flow** - Why → Concepts → Setup → Hands-on is a solid structure
2. **Multiple project choices** - Letting attendees pick their project increases engagement
3. **Clear progression path** - Next.js → localStorage → Tauri → Vercel is achievable
4. **REQUEST triggers** - Giving them exact text to use removes friction

### Questions & Areas to Address

| Issue | Question/Concern | Suggestion |
|-------|------------------|------------|
| **4Ds undefined** | What are the 4Ds? Not spelled out | Need dedicated slide explaining each D |
| **"Description as key"** | Unclear phrase | Reframe as "Why Description Matters" |
| **No time budget** | How long is workshop? | Define: 1hr / 2hr / half-day changes scope |
| **Platform assumption** | iTerm = macOS only | Address Windows/Linux users |
| **Tour undefined** | What's in the "tour"? | List specific things to show |
| **Scope mismatch** | REQUEST vs feature list | Make explicit: REQUEST = start, features = stretch |
| **Tauri timing** | When does conversion happen? | Position after web app works |
| **No safety net** | What if attendees get stuck? | Add "flag me down after 5 min" rule |
| **No success criteria** | What should they have at end? | Define clear takeaways |

---

## Proposed Slide Deck Structure

### Slide 1: Title
**TheAgency Workshop**
*Build AI-Powered Apps with Claude Code*

- Your name / date
- WiFi info if needed
- "By the end of today, you'll have built and deployed your own app"

---

### Slide 2: Why TheAgency?

**The Problem We're Solving**

Content:
- Building software with AI is powerful but chaotic
- Context gets lost between sessions
- No structure for multi-step projects
- Hard to maintain quality and consistency

**The Solution:**
- TheAgency = Convention over configuration
- Agents with memory and identity
- Structured collaboration
- Quality gates built in

Visual: Before/After comparison
- Before: Scattered chat sessions, lost context, inconsistent results
- After: Organized workstreams, persistent knowledge, reliable output

---

### Slide 3: AI Fluency - The 4Ds

**How to Work Effectively with AI**

| D | What It Means | Example |
|---|---------------|---------|
| **Describe** | Be specific about what you want | "Build a bookmark manager with tags and search" not "build me an app" |
| **Decompose** | Break big tasks into smaller ones | Feature → Components → Functions |
| **Direct** | Guide and course-correct | "Use localStorage, not a database" |
| **Delegate** | Let AI handle the implementation | Trust the agent, review the output |

Key insight: The better your description, the better the result.

---

### Slide 4: Deep Dive - Description

**Why Description is the Key Skill**

Content:
- AI can only build what you can describe
- Vague input → Vague output
- Specific input → Specific output

**The REQUEST Pattern:**
```
What: [What should it do?]
Why: [What problem does it solve?]
How: [Any constraints or preferences?]
Done: [How do we know it's complete?]
```

**Example - Bad vs Good:**

❌ "Build me a notes app"

✅ "Build a notes app where I can:
- Create notes with a title and body
- Tag notes for organization
- Search notes by title or content
- Store everything in localStorage (no backend)
- Use a clean, minimal UI"

---

### Slide 5: Getting Started Checklist

**Before We Begin**

Prerequisites:
- [ ] macOS with iTerm (or Terminal)
  - *Windows users: Use Windows Terminal + WSL*
  - *Linux users: Any terminal*
- [ ] A code directory at `~/code` or `~/projects`
- [ ] Claude Code installed (we'll verify)

**Setup Steps:**
```bash
# 1. Open terminal

# 2. Go to your projects directory
cd ~/code  # or ~/projects

# 3. Run TheAgency installer
curl -fsSL "https://[INSTALLER_URL]" | bash -s -- my-first-app

# 4. Open in your editor
code my-first-app
```

---

### Slide 6: Installing TheAgency (Live Demo)

**Let's Do It Together**

*[This is a live demo slide - minimal content]*

What they'll see:
1. Installer downloads and runs
2. Project directory created
3. TheAgency structure scaffolded
4. Ready to launch housekeeping

**If something goes wrong:**
- Raise your hand
- Check: Are you in the right directory?
- Check: Do you have internet access?

---

### Slide 7: Quick Tour - What You Just Got

**TheAgency Structure**

```
my-first-app/
├── CLAUDE.md           ← The constitution (start here)
├── claude/
│   ├── agents/         ← Agent definitions
│   │   └── housekeeping/  ← Your guide
│   ├── workstreams/    ← Organized work areas
│   └── principals/     ← You! (human stakeholders)
└── tools/              ← CLI tools
```

**Key Concepts:**
- **Agents** = Specialized Claude instances with memory
- **Workstreams** = Areas of work (features, infrastructure)
- **Principals** = Humans who direct work
- **REQUESTs** = How you tell agents what to build

---

### Slide 8: How to Work with TheAgency

**The Workflow**

1. **Create a REQUEST** - Describe what you want
2. **Launch housekeeping** - Point it at your REQUEST
3. **Watch it work** - Claude builds your app
4. **Review & iterate** - Refine as needed

**Commands you'll use:**
```bash
# Create a request
./tools/request "Build a bookmark manager..."

# Launch housekeeping
./tools/myclaude housekeeping housekeeping

# Or use AgencyBench (GUI)
./tools/bench
```

---

### Slide 9: Choose Your Project

**Pick One to Build Today**

| Project | Difficulty | Best For |
|---------|------------|----------|
| **Bookmark Manager** | ⭐ Beginner | First-timers, visual learners |
| **Mood Tracker** | ⭐⭐ Intermediate | Data/charts interest |
| **Recipe Book** | ⭐⭐⭐ Challenge | Confident coders |

**All projects will:**
- Start as a Next.js web app
- Use localStorage (no backend needed)
- Convert to Tauri desktop app (stretch)
- Deploy to Vercel (stretch)

*Choose based on what interests YOU, not difficulty.*

---

### Slide 10: Project Details - Bookmark Manager

**REQUEST to use:**
> "Build a bookmark manager app where I can save URLs with titles, tags, and notes. Include search and tag filtering. Store in localStorage."

**What you'll build:**
- Add bookmarks (title, URL, description)
- Tag bookmarks for organization
- Search across all bookmarks
- Filter by tags

**Stretch goals:**
- Collections/folders
- Import from browser
- Tauri: System tray quick-add

---

### Slide 11: Project Details - Mood Tracker

**REQUEST to use:**
> "Build a mood tracker app where I can log my mood (1-5) each day with optional notes. Show a calendar view and simple trend chart. Store in localStorage."

**What you'll build:**
- Log mood (1-5 or emoji)
- Add daily notes
- Calendar view of moods
- Simple trend visualization

**Stretch goals:**
- Streak tracking
- AI insights
- Tauri: Menu bar logger

---

### Slide 12: Project Details - Recipe Book

**REQUEST to use:**
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

### Slide 13: Let's Build!

**Hands-On Time**

**Step 1:** Create your REQUEST
```bash
./tools/request "Your chosen REQUEST text here..."
```

**Step 2:** Launch housekeeping
```bash
./tools/myclaude housekeeping housekeeping
```

**Step 3:** Tell housekeeping about your request
> "Please look at my latest REQUEST and build it"

**Ground Rules:**
- 🖐️ Stuck for 5+ minutes? Raise your hand
- 💬 Talk to your neighbors - collaboration welcome
- 🎯 Focus on core features first, stretch goals later

---

### Slide 14: Check-In / Tauri Conversion

**[Use after ~30-45 min of building]**

**Status Check:**
- ✅ Web app running locally?
- ✅ Core features working?
- ✅ Ready for next step?

**Converting to Tauri Desktop App:**

Tell Claude:
> "Let's convert this to a Tauri desktop app. Add the Tauri starter pack and configure it for desktop."

What happens:
- Tauri dependencies added
- Native wrapper configured
- Desktop app builds

---

### Slide 15: Wrap-Up & What's Next

**What You Built Today**

- ✅ A working web application
- ✅ Built with AI assistance via TheAgency
- ✅ Understanding of REQUESTs and agents
- ✅ (Maybe) A desktop app or deployed site

**Take It Further:**
- Add more features to your app
- Try another project
- Explore other agents and workstreams
- Join the community: [link]

**Resources:**
- TheAgency docs: [link]
- Claude Code: [link]
- Today's slides: [link]

---

## Timing Suggestions

| Section | Duration | Cumulative |
|---------|----------|------------|
| Slides 1-4 (Why/Concepts) | 10 min | 10 min |
| Slides 5-6 (Setup) | 10 min | 20 min |
| Slides 7-8 (Tour) | 10 min | 30 min |
| Slides 9-12 (Projects) | 5 min | 35 min |
| Slide 13 (Building) | 30-45 min | 65-80 min |
| Slide 14 (Tauri) | 15 min | 80-95 min |
| Slide 15 (Wrap-up) | 5 min | 85-100 min |

**Recommended workshop length: 90-120 minutes**

---

## Open Questions for Jordan

1. **What are the actual 4Ds?** I made educated guesses - please confirm or correct
2. **Workshop duration?** Timing above assumes ~90 min
3. **Audience technical level?** Developers or mixed?
4. **Windows/Linux support?** Or macOS only?
5. **Will you have helpers?** For hands-on support
6. **Do you want the exact installer URL on slides?** Or provide separately

---

## Logo Design: "The Constellation"

**SVG File:** `claude/assets/theagency-logo-constellation.svg`

**Concept:**
The logo represents the collaborative nature of TheAgency through a constellation metaphor - nodes connected by lines forming a network.

**Elements:**
- **Central Node (Gold/Amber)**: The principal - larger, prominent, the human directing work
- **Surrounding Nodes (Teal/Blue)**: 4 agents - varying sizes suggesting different specializations
- **Connection Lines**: Thin blue lines connecting all nodes, showing collaboration pathways
- **Background**: Deep space blue gradient - subtle, professional

**Design Principles:**
- Asymmetric arrangement = organic collaboration, not rigid hierarchy
- Principal is slightly off-center and elevated = leadership without dominance
- Agent-to-agent connections (faint) = peer collaboration
- Glow effects = active, alive system

**Usage:**
- Full color on dark backgrounds
- Can simplify to just nodes + lines for small sizes (favicon)
- Monochrome version: white nodes/lines on dark, or dark on light

**Preview the SVG:**
```bash
open claude/assets/theagency-logo-constellation.svg
```

---

**Status:** Ready for slide generation - proceeding to Opus 4.5
