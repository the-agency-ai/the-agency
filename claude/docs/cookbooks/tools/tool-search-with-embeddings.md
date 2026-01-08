# Tool Search with Embeddings

> Source: https://platform.claude.com/cookbook/tool-use-tool-search-with-embeddings

## Overview

This cookbook demonstrates how to scale Claude applications from dozens to thousands of tools using semantic embeddings for dynamic tool discovery. Instead of providing all tool definitions upfront (which consumes context), Claude gets a single `tool_search` tool that returns relevant capabilities on demand, cutting context usage by 90%+.

## Prerequisites

**Required Knowledge:**
- Python fundamentals (functions, dictionaries, data structures)
- Basic understanding of Claude tool use

**Required Tools:**
- Python 3.11 or higher
- Anthropic API key

## Setup

```python
# Install dependencies
%pip install --only-binary :all: -q anthropic sentence-transformers numpy python-dotenv

import json
import random
from datetime import datetime, timedelta
from typing import Any

import anthropic
import numpy as np
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

load_dotenv()

MODEL = "claude-sonnet-4-5-20250929"

claude_client = anthropic.Anthropic()

# Load embedding model (384 dimensional embeddings)
print("Loading SentenceTransformer model...")
embedding_model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

print("Clients initialized successfully")
```

## Define Tool Library

Create a library of tools across multiple domains:

```python
TOOL_LIBRARY = [
    # Weather Tools
    {
        "name": "get_weather",
        "description": "Get the current weather in a given location",
        "input_schema": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA",
                },
                "unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"],
                    "description": "The unit of temperature",
                },
            },
            "required": ["location"],
        },
    },
    {
        "name": "get_forecast",
        "description": "Get the weather forecast for multiple days ahead",
        "input_schema": {
            "type": "object",
            "properties": {
                "location": {"type": "string", "description": "The city and state"},
                "days": {"type": "number", "description": "Number of days to forecast (1-10)"},
            },
            "required": ["location", "days"],
        },
    },
    # Finance Tools
    {
        "name": "get_stock_price",
        "description": "Get the current stock price and market data for a given ticker symbol",
        "input_schema": {
            "type": "object",
            "properties": {
                "ticker": {"type": "string", "description": "Stock ticker symbol (e.g., AAPL, GOOGL)"},
                "include_history": {"type": "boolean", "description": "Include historical data"},
            },
            "required": ["ticker"],
        },
    },
    {
        "name": "convert_currency",
        "description": "Convert an amount from one currency to another using current exchange rates",
        "input_schema": {
            "type": "object",
            "properties": {
                "amount": {"type": "number", "description": "Amount to convert"},
                "from_currency": {"type": "string", "description": "Source currency code (e.g., USD)"},
                "to_currency": {"type": "string", "description": "Target currency code (e.g., EUR)"},
            },
            "required": ["amount", "from_currency", "to_currency"],
        },
    },
    # ... more tools
]
```

## Create Tool Embeddings

```python
def tool_to_text(tool: dict[str, Any]) -> str:
    """Convert a tool definition into a text representation for embedding."""
    text_parts = [
        f"Tool: {tool['name']}",
        f"Description: {tool['description']}",
    ]

    if "input_schema" in tool and "properties" in tool["input_schema"]:
        params = tool["input_schema"]["properties"]
        param_descriptions = []
        for param_name, param_info in params.items():
            param_desc = param_info.get("description", "")
            param_type = param_info.get("type", "")
            param_descriptions.append(f"{param_name} ({param_type}): {param_desc}")

        if param_descriptions:
            text_parts.append("Parameters: " + ", ".join(param_descriptions))

    return "\n".join(text_parts)

# Create embeddings for all tools
tool_texts = [tool_to_text(tool) for tool in TOOL_LIBRARY]
tool_embeddings = embedding_model.encode(tool_texts, convert_to_numpy=True)

print(f"Created embeddings with shape: {tool_embeddings.shape}")
```

## Implement Tool Search

```python
def search_tools(query: str, top_k: int = 5) -> list[dict[str, Any]]:
    """Search for tools using semantic similarity."""
    # Embed the query
    query_embedding = embedding_model.encode(query, convert_to_numpy=True)

    # Calculate cosine similarity using dot product
    similarities = np.dot(tool_embeddings, query_embedding)

    # Get top k indices
    top_indices = np.argsort(similarities)[-top_k:][::-1]

    # Return the corresponding tools with their scores
    results = []
    for idx in top_indices:
        results.append({
            "tool": TOOL_LIBRARY[idx],
            "similarity_score": float(similarities[idx])
        })

    return results
```

## Define the tool_search Meta-Tool

```python
TOOL_SEARCH_DEFINITION = {
    "name": "tool_search",
    "description": "Search for available tools that can help with a task. Returns tool definitions for matching tools.",
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Natural language description of what kind of tool you need",
            },
            "top_k": {
                "type": "number",
                "description": "Number of tools to return (default: 5)",
            },
        },
        "required": ["query"],
    },
}

def handle_tool_search(query: str, top_k: int = 5) -> list[dict[str, Any]]:
    """Handle a tool_search invocation and return tool references."""
    results = search_tools(query, top_k=top_k)

    # Create tool_reference objects
    tool_references = [
        {"type": "tool_reference", "tool_name": result["tool"]["name"]}
        for result in results
    ]

    return tool_references
```

## Conversation Loop

```python
def run_tool_search_conversation(user_message: str, max_turns: int = 5) -> None:
    """Run a conversation with Claude using the tool search pattern."""
    messages = [{"role": "user", "content": user_message}]

    for turn in range(max_turns):
        response = claude_client.messages.create(
            model=MODEL,
            max_tokens=1024,
            tools=TOOL_LIBRARY + [TOOL_SEARCH_DEFINITION],
            messages=messages,
            extra_headers={"anthropic-beta": "advanced-tool-use-2025-11-20"},
        )

        messages.append({"role": "assistant", "content": response.content})

        if response.stop_reason == "end_turn":
            for block in response.content:
                if block.type == "text":
                    print(f"ASSISTANT: {block.text}")
            break

        if response.stop_reason == "tool_use":
            tool_results = []

            for block in response.content:
                if block.type == "tool_use":
                    tool_name = block.name
                    tool_input = block.input
                    tool_use_id = block.id

                    if tool_name == "tool_search":
                        tool_references = handle_tool_search(
                            tool_input["query"],
                            tool_input.get("top_k", 5)
                        )
                        tool_results.append({
                            "type": "tool_result",
                            "tool_use_id": tool_use_id,
                            "content": tool_references,
                        })
                    else:
                        # Execute the discovered tool
                        mock_result = mock_tool_execution(tool_name, tool_input)
                        tool_results.append({
                            "type": "tool_result",
                            "tool_use_id": tool_use_id,
                            "content": mock_result,
                        })

            if tool_results:
                messages.append({"role": "user", "content": tool_results})
```

## Key Benefits

1. **Context Efficiency**: Reduces context from 19+ tool definitions to just one `tool_search` definition (90%+ reduction)
2. **Scalability**: Seamlessly scales from dozens to thousands of tools
3. **Latency Reduction**: Fewer tokens processed per request
4. **Cost Optimization**: Significantly reduced token usage

## Production Considerations

1. **Persist embeddings**: Cache to disk to avoid recomputation
2. **Improve search quality**: Use larger embedding models (e.g., `all-mpnet-base-v2`)
3. **Hybrid search**: Combine semantic and keyword matching (BM25)
4. **Add metadata**: Include usage statistics, costs, or reliability scores
5. **Implement caching**: Cache frequently used tool definitions
6. **Scale testing**: Test with hundreds or thousands of tools

---

## Relevance to The Agency

**Very High relevance** - This pattern is directly applicable:
- The Agency has 40+ tools that could benefit from semantic search
- Agents could dynamically discover tools based on task needs
- Reduces context overhead when agents don't need all tools
- Could enable specialized tool libraries per workstream
