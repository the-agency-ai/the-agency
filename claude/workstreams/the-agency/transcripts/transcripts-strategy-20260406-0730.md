---
type: transcript
date: 2026-04-06T07:30
source: granola
topic: transcripts and session capture strategy
---

## Summary

- Transcript = gold standard for capturing what was said (vs. summaries, which are derivatives)
- Two transcript types to capture:
  - Principal–agent dialogue (back-and-forth, brainstorming, problem-solving)
  - Monologue/dictation (like this session) — used to generate artifacts on a topic
- "Always-on" transcripts: continuous capture of agent ↔ user exchanges
  - Agent periodically drops in block summaries of its conclusions
- Session transcripts differ from dictation — both are valuable, serve different purposes
- Transcripts will get large; need an index to make them queryable
  - Index entries: summary + timestamp covering the relevant time period
  - Transcripts stored in git; index stored outside git (to avoid conflicts)
- New design: transcript injection into handoffs
  - Pull last X transcripts of work into each new session
  - Enables more frequent compaction without losing context
- Agent-written summaries exist now; Anthropic API could automate these later

## Transcript

Me: The gold standard for what was said and what was discussed for the context of a conversation or a situation is a transcript. It's why we have court reporters who copy down every word. Blair said this response was here, not a summary, but every word. You can then get a summary and that's in fact what they have young junior associates do sit around and summarize those down into things. But at the end of the day the gold standard is that transcript. And what we want to do through multiple mechanisms is capture that and bring that into the agency. The first is the transcript of discussions between a principal and an agent. Where we're going back and forth where we're brainstorming, where we're solving an issue. We want to get these. We want to capture these. The other place where we want to bring in a transcript is what I will call the diatribe or monologue transcript, which is what I'm doing here right now with Granola. I am actually going through and talking about some stuff and what I'm going to pass to the captain is a summary from Granola. Plus I'm also going to give the full transcript. And this will become an artifact about this topic of transcripts. So this is very meta. We have a transcription. We're using monologue transcription to capture or dictation to capture what we're going for. It's interesting. So what we want is always on transcripts. And what transcripts capture and how they differ from session files is they are the back and forth. The agent said this. I said this and every once in a while the agent will go and drop a summary in of a block. Its conclusions that it drop. Gathered. That is the session transcript versus the dictation or what I'm doing right here. What this implies is these are going to get big and we want to capture them. So what we want to do is we actually want to have an index so you can look them up. Because they're always on. It should be possible for us to have a transcript of the of the of the time frame. And in addition what we want to do is we want to be in a handoff. We want to pull in the last x transcripts. Of work. And then we also have it. So what we have is we have a transcription tool that generates transcription. Right now we have agent written summaries. We could later probably plug that into the anthropic API and have those summaries generated for us. I think that would be very easy to do. And so we have that. We have that session transcript, that back and forth. We should every so often we should save those. We should have a summary that captures what it is. Put that in an index with a timestamp that it covers this period. Of time. So that's what we get. So I then can be able to go and I can query this transcript. These are all tied to a specific. These should be in get. But the index should be outside of git. So that we're not dealing with issues there that otherwise would. And then the other thing is that we want to do transcript injection. We're going to design a better handoff. That allows us to do injection and maybe stop resuming sessions the way we have been. Or at least be able to go with very slimmed down session resumes. You know we can do that. This also should let us compact more frequently because we're not going to lose any context. Okay, so this is about there.
