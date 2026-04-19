# Automatic Context Compaction

> Source: https://platform.claude.com/cookbook/tool-use-automatic-context-compaction

## Overview

This cookbook demonstrates how to manage context limits in long-running agentic workflows by automatically compressing conversation history using Claude's `compaction_control` parameter.

**Key Problem**: Tool-heavy workflows and long conversations quickly consume the token context window (200k limit), causing performance degradation and context rot.

**Solution**: Automatic context compaction monitors token usage and injects summaries when thresholds are exceeded, allowing tasks to continue beyond typical limits.

## What is Context Compaction?

When token usage exceeds a threshold, the system:

1. Monitors token usage per turn
2. Injects a summary prompt as a user turn when threshold is exceeded
3. Claude generates a summary wrapped in `<summary></summary>` tags
4. Clears conversation history and resumes with only the summary
5. Continues the task with compressed context

## Prerequisites

- Python 3.11+
- Anthropic SDK >= 0.74.1
- Anthropic API key in `.env` file

## Setup

```python
from dotenv import load_dotenv
import anthropic

load_dotenv()

MODEL = "claude-sonnet-4-5"
client = anthropic.Anthropic()
```

## Customer Service Use Case

The example implements an AI customer service agent processing support tickets with these steps per ticket:

1. Fetch ticket (`get_next_ticket()`)
2. Classify issue (`classify_ticket()`)
3. Search knowledge base (`search_knowledge_base()`)
4. Set priority (`set_priority()`)
5. Route to team (`route_to_team()`)
6. Draft response (`draft_response()`)
7. Mark complete (`mark_complete()`)

### Tools Definition

```python
from anthropic import beta_tool

@beta_tool
def get_next_ticket() -> dict:
    """Retrieve the next unprocessed support ticket from the queue."""
    ...

tools = [
    get_next_ticket,
    classify_ticket,
    search_knowledge_base,
    set_priority,
    route_to_team,
    draft_response,
    mark_complete,
]
```

## Baseline Results (Without Compaction)

Processing 5 tickets with 7 steps each (35 tool calls total):

```
Total turns:   37
Input tokens:  204,416
Output tokens: 4,422
Total tokens:  208,838
```

**Problem**: Linear token growth—each turn sends entire conversation history including all previous tool results.

## Enabling Automatic Context Compaction

```python
from anthropic.types.beta import BetaMessageParam

messages: list[BetaMessageParam] = [
    {
        "role": "user",
        "content": """You are an AI customer service agent processing support tickets...
[prompt details]
"""
    }
]

runner = client.beta.messages.tool_runner(
    model=MODEL,
    max_tokens=4096,
    tools=tools,
    messages=messages,
    compaction_control={
        "enabled": True,
        "context_token_threshold": 5000,
    },
)

for message in runner:
    # Process message
    pass
```

## Results With Compaction

Processing the same 5 tickets:

```
Total turns:   26
Compactions:   2
Input tokens:  82,171
Output tokens: 4,275
Total tokens:  86,446

Token Savings: 122,392 tokens (58.6% reduction)
```

### Compaction Events

When threshold (5,000 tokens) is exceeded, Claude generates a summary:

```markdown
## Support Ticket Processing Progress Summary

### Tickets Completed (2 of 5)

**TICKET-1 (Chris Davis) - COMPLETED**
- Issue: Account locked, unlock email link not working
- Category: account
- Priority: high
- Team: account-services
- Status: resolved

**TICKET-2 (Chris Williams) - COMPLETED**
- Issue: Unrecognized $49.99 charge
- Category: billing
- Priority: high
- Team: billing-team
- Status: resolved

### Current Status
**TICKET-3 (John Jones) - IN PROGRESS**
- Category: product
- Steps remaining: 3-7

### Next Steps
1. Complete TICKET-3
2. Fetch and process TICKET-4
3. Fetch and process TICKET-5
```

## Compaction Configuration Options

### Adjusting the Threshold

```python
compaction_control={
    "enabled": True,
    "context_token_threshold": 5000,  # Tokens before compaction triggers
}
```

**Guidelines**:
- **Low (5k-20k)**: Frequent compaction for sequential entity processing
- **Medium (50k-100k)**: Multi-phase workflows with larger checkpoints
- **High (100k-150k)**: Tasks requiring substantial historical context
- **Default (100k)**: Good balance for general long-running tasks

### Using Different Model for Summarization

```python
compaction_control={
    "enabled": True,
    "model": "claude-haiku-4-5",  # Use faster/cheaper model
    "context_token_threshold": 5000,
}
```

### Custom Summary Prompt

```python
compaction_control={
    "enabled": True,
    "summary_prompt": """You are processing customer support tickets.

Create a focused summary that preserves:

1. **COMPLETED TICKETS**: For each fully processed ticket:
   - Ticket ID and customer name
   - Issue category and priority
   - Team routed to
   - Brief outcome

2. **PROGRESS STATUS**:
   - How many tickets completed
   - Approximately how many remain

3. **NEXT STEPS**: Continue processing next ticket

Format with clear sections and wrap in <summary></summary> tags."""
}
```

## Manual Compaction for Chat Loops

For simple conversational applications without tool use:

```python
COMPACTION_THRESHOLD = 3000
SUMMARY_PROMPT = """You have been working on the task above but have not completed it.
Write a continuation summary that will allow you to resume work efficiently. Your summary
should include:

1. **Task Overview**
   - Core request and success criteria
   - Clarifications or constraints

2. **Current State**
   - What has been completed
   - Files created/modified/analyzed
   - Key outputs produced

3. **Important Discoveries**
   - Technical constraints uncovered
   - Decisions made and rationale
   - Errors and resolutions
   - What approaches didn't work

4. **Next Steps**
   - Specific actions needed
   - Blockers or open questions
   - Priority order

5. **Context to Preserve**
   - User preferences
   - Domain-specific details
   - Promises made to user

Wrap in <summary></summary> tags."""

messages = []

# Chat loop
user_input = "Your question here"
messages.append({"role": "user", "content": user_input})

response = client.messages.create(
    model=MODEL,
    max_tokens=2048,
    messages=messages,
)

messages.append({"role": "assistant", "content": response.content})

# Check for compaction
usage = response.usage
total_tokens = (
    usage.input_tokens +
    (usage.cache_creation_input_tokens or 0) +
    (usage.cache_read_input_tokens or 0) +
    usage.output_tokens
)

if total_tokens > COMPACTION_THRESHOLD:
    # Request summary
    summary_response = client.messages.create(
        model=MODEL,
        max_tokens=4096,
        messages=messages + [{"role": "user", "content": SUMMARY_PROMPT}],
    )

    summary_text = "".join(
        block.text for block in summary_response.content if block.type == "text"
    )

    # Replace history with summary
    messages = [{"role": "user", "content": summary_text}]
```

## Limitations

### Server-Side Sampling Loops
- Compaction doesn't work optimally with server-side web search tools
- Cache tokens accumulate prematurely
- Wait for future improvements

### Information Loss
- Details inevitably compressed in summaries
- Full KB articles and response text discarded
- **Mitigation**: Custom summary prompts, higher thresholds, modular task design

### When NOT to Use
- Short tasks (< 50k-100k tokens)
- Tasks requiring full audit trails
- Server-side sampling workflows
- Highly iterative refinement where each step depends on exact previous details

## When TO Use Compaction

- **Sequential Processing**: Multiple independent items processed one after another
- **Multi-Phase Workflows**: Natural checkpoints between phases
- **Iterative Data Processing**: Processing large datasets in chunks
- **Extended Analysis**: Analysis across many entities
- **Batch Operations**: Processing hundreds of independent items

## Key Takeaways

1. **Automatic compaction** monitors token usage and injects summaries when thresholds are exceeded
2. **58.6% token savings** demonstrated in ticket processing example (208k → 86k tokens)
3. **Natural workflow alignment**: Mimics how real support agents work—document, close, move on
4. **Quality preserved**: Critical information retained while discarding raw details
5. **Configurable**: Threshold, model, and prompts all customizable for your use case

---

## Relevance to The Agency

**Very High relevance** - This directly addresses our long-running agent sessions:
- Our agents often work on multi-step tasks that exceed context limits
- SESSION-BACKUP mechanism could integrate with automatic compaction
- Custom summary prompts could be tailored to preserve agent identity and workstream context
- Could dramatically reduce token costs for extended work sessions
