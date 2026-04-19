# Claude Cookbooks Summary

> Last updated: 2026-01-08
> Source: https://platform.claude.com/cookbook

## Overview

Anthropic publishes **63+ cookbooks** covering practical implementations for Claude. This document summarizes all available cookbooks and highlights those most relevant to The Agency.

---

## Cookbooks Saved Locally

The following cookbooks have been downloaded and saved to `claude/docs/cookbooks/`:

### Tools (`tools/`)
| Cookbook | Relevance | Key Takeaway |
|----------|-----------|--------------|
| **programmatic-tool-calling.md** | Very High | 85% token reduction by letting Claude write code that calls tools |
| **automatic-context-compaction.md** | Very High | 58% token savings in long sessions via automatic summarization |
| **tool-search-with-embeddings.md** | Very High | Scale to 1000s of tools with semantic search |

### Workflows (`workflows/`)
| Cookbook | Relevance | Key Takeaway |
|----------|-----------|--------------|
| **basic-workflows.md** | Very High | Chaining, parallelization, routing patterns |
| **orchestrator-workers.md** | Very High | Dynamic task decomposition (validates Agency architecture) |
| **evaluator-optimizer.md** | High | Iterative improvement with feedback loops |

### Extended Thinking (`extended-thinking/`)
| Cookbook | Relevance | Key Takeaway |
|----------|-----------|--------------|
| **extended-thinking.md** | Medium | Transparent reasoning with budget tokens |
| **extended-thinking-with-tool-use.md** | Medium | Combining reasoning with tools |

### Optimization (`optimization/`)
| Cookbook | Relevance | Key Takeaway |
|----------|-----------|--------------|
| **prompt-caching.md** | High | >2x faster, 90% cost reduction for repeated context |
| **batch-processing.md** | Medium-High | 50% cost reduction for async bulk processing |

---

## All Available Cookbooks

### Agent Patterns & SDK

| Cookbook | Description | Priority |
|----------|-------------|----------|
| The One-Liner Research Agent | Build research agents with WebSearch | HIGH |
| The Chief of Staff Agent | Multi-agent systems with subagents | HIGH |
| The Observability Agent | Connect agents to external systems via MCP | HIGH |
| Basic Workflows | Chaining, parallelization, routing | SAVED |
| Orchestrator Workers | Dynamic task decomposition | SAVED |
| Evaluator Optimizer | Generation + evaluation loops | SAVED |
| Using Haiku as a sub-agent | Cost-effective sub-agent patterns | MEDIUM |

### Tools & Tool Use

| Cookbook | Description | Priority |
|----------|-------------|----------|
| Programmatic Tool Calling (PTC) | Tools in code execution | SAVED |
| Tool Search with Embeddings | Scale to 1000s of tools | SAVED |
| Automatic Context Compaction | Manage context limits | SAVED |
| Memory & Context Management | Persistent agent memory | HIGH |
| Parallel Tool Calls | Concurrent tool execution | MEDIUM |
| Tool Choice | Control tool selection | MEDIUM |
| Vision with Tools | Structured data from images | MEDIUM |
| Calculator Tool | Math operations | LOW |
| Customer Service Agent | Client-side tools | MEDIUM |
| Extracting Structured JSON | Tool use for data extraction | MEDIUM |
| Note-Saving with Pydantic | Type-safe tool interactions | LOW |

### Skills

| Cookbook | Description | Priority |
|----------|-------------|----------|
| Introduction to Claude Skills | Excel, PowerPoint, PDF | LOW |
| Claude Skills for Financial Applications | Financial dashboards | LOW |
| Building Custom Skills for Claude | Custom skill development | LOW |

### Extended Thinking

| Cookbook | Description | Priority |
|----------|-------------|----------|
| Extended Thinking | Transparent step-by-step reasoning | SAVED |
| Extended Thinking with Tool Use | Reasoning + tools | SAVED |

### RAG & Retrieval

| Cookbook | Description | Priority |
|----------|-------------|----------|
| Retrieval Augmented Generation | Build RAG systems | MEDIUM |
| Text to SQL | Natural language to SQL | MEDIUM |
| Contextual Retrieval | Improve RAG accuracy | MEDIUM |
| Summarization | Document summarization | MEDIUM |
| Classification | Build classification systems | LOW |
| Web Page Content Summarization | Fetch and summarize | LOW |
| "Uploading" PDFs via API | PDF processing | LOW |

### Multimodal

| Cookbook | Description | Priority |
|----------|-------------|----------|
| Crop Tool for Image Analysis | Zoom into image regions | MEDIUM |
| Best Practices for Vision | Image processing tips | LOW |
| Getting Started with Vision | Pass images to Claude | LOW |
| Transcribing Documents | Extract text from images | MEDIUM |
| Working with Charts & Graphs | Visual content analysis | MEDIUM |

### Responses & Output

| Cookbook | Description | Priority |
|----------|-------------|----------|
| Batch Processing | 50% cost reduction | SAVED |
| Prompt Caching | >2x faster, 90% cost reduction | SAVED |
| Speculative Prompt Caching | Warm cache proactively | MEDIUM |
| Sampling Past Max Tokens | Generate longer responses | LOW |
| JSON Mode | Reliable JSON output | MEDIUM |
| Citations | Source attribution | LOW |
| Metaprompt | Generate starting prompts | LOW |
| Moderation Filter | Content moderation | LOW |
| Frontend Aesthetics | Prompting for design | LOW |

### Fine-Tuning & Evals

| Cookbook | Description | Priority |
|----------|-------------|----------|
| Fine-tuning on Bedrock | Customize Claude 3 Haiku | LOW |
| Building Evals | Evaluation systems | MEDIUM |
| Synthetic Test Data | Generate test cases | LOW |
| Tool Evaluation | Parallel agent testing | MEDIUM |

### Integrations

| Cookbook | Description | Priority |
|----------|-------------|----------|
| ElevenLabs Voice Assistant | Low-latency voice | LOW |
| Deepgram Audio Transcription | Audio processing | LOW |
| Wolfram Alpha | Computational queries | LOW |
| LangChain v1 RAG Agents | LangChain integration | LOW |
| LlamaIndex (multiple) | Various RAG patterns | LOW |
| MongoDB RAG | Vector database | LOW |
| Pinecone RAG | Vector database | LOW |

### Observability

| Cookbook | Description | Priority |
|----------|-------------|----------|
| Usage & Cost Admin API | Programmatic usage data | MEDIUM |

---

## Agency-Relevant Patterns

### Already Implemented in The Agency

| Cookbook Pattern | Agency Implementation |
|-----------------|----------------------|
| Orchestrator-Workers | Principal → Agent architecture |
| Basic Workflows (Routing) | `./tools/dispatch-collaborations` |
| Evaluator-Optimizer | `./tools/code-review` + pre-commit |
| Multi-turn Context | SESSION-BACKUP mechanism |

### Should Implement

| Cookbook Pattern | Proposed Implementation |
|-----------------|------------------------|
| **Automatic Context Compaction** | Integrate into long sessions |
| **Tool Search with Embeddings** | Dynamic tool discovery for agents |
| **Programmatic Tool Calling** | Batch tool operations in agents |
| **Prompt Caching** | Cache agent.md + KNOWLEDGE.md |
| **Batch Processing** | Background analysis jobs |

### Enhancement Opportunities

1. **Context Compaction** (`./tools/compact-context`)
   - Automatic summarization when context exceeds threshold
   - Preserve agent identity and workstream context
   - Integrate with SESSION-BACKUP

2. **Tool Discovery** (`./tools/tool-find`)
   - Semantic search across 40+ Agency tools
   - Dynamic tool loading based on task needs
   - Reduce context overhead

3. **Batch Analysis** (`./tools/batch-analyze`)
   - Submit bulk analysis jobs (50% cost savings)
   - End-of-day code review batches
   - Cross-agent summary generation

4. **Cache Management** (`./tools/cache-context`)
   - Cache large context (agent.md, KNOWLEDGE.md)
   - Reduce token costs for long sessions
   - Share cached context across agents

---

## Next Steps

### Immediate (for Jan 23 workshop)
- [ ] Review Tool Search with Embeddings for dynamic tool discovery
- [ ] Test Automatic Context Compaction for long sessions

### Near-term
- [ ] Fetch remaining HIGH priority cookbooks (Research Agent, Chief of Staff)
- [ ] Prototype context compaction in myclaude
- [ ] Evaluate prompt caching benefits

### Long-term
- [ ] Implement tool discovery with embeddings
- [ ] Build batch processing infrastructure
- [ ] Create comprehensive eval suite

---

## Resources

- **Official Cookbook**: https://platform.claude.com/cookbook
- **GitHub Repository**: https://github.com/anthropics/anthropic-cookbook
- **Claude Agent SDK**: https://github.com/anthropics/claude-agent-sdk

---

*Summary generated 2026-01-08*
