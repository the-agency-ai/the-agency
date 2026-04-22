---
title: 'Review: DevEx Service Composition A&D'
type: dispatch
status: created
date: 2026-04-01
source: monofolk (customer project)
target: the-agency (framework)
priority: normal
---

# Dispatch: DevEx Service Composition A&D Review

## Context

The MonoFolk project has produced a DevEx Service Composition Architecture & Design document that describes a unified service composition model for defining, provisioning, and deploying services across environments (local Docker, cloud preview, staging, production).

This document is submitted as a **customer use case** for what should become an Agency framework feature. The MonoFolk-specific details (app names, providers, topology) illustrate how the feature would be applied in practice.

## Document Location

`claude/docs/design/devex-service-composition-architecture.md`

## Review Request

Please review this document as a **framework feature proposal** with the following focus areas:

### 1. Framework vs. Project-Specific

What should be framework-level (reusable across any Agency project) vs. project-specific configuration?

Candidates for framework-level:
- Topology manifest format and resolution
- Provider tool interface (`setup`, `provision`, `deploy`, `teardown`, `status`)
- Provider bindings model (environment → provider mapping)
- `/preview` orchestration skill
- `/provider-setup` skill (successor to starter packs)
- Health check tooling

Candidates for project-specific:
- Concrete provider implementations (fly-provider, vercel-provider, etc.)
- Service type definitions
- Topology manifests
- Binding configurations

### 2. Fit with Existing Agency Patterns

How does this fit with existing Agency patterns?

- **Starter packs** — The document proposes replacing starter packs with `/provider-setup` skills. Is this the right evolution? What's preserved, what's lost?
- **Skills model** — The `/preview`, `/provision`, `/deploy` skills follow the existing skill pattern. Any concerns about the orchestration complexity?
- **Tools model** — Provider tools implement a common interface. Does this align with the existing tool conventions (logging, telemetry, structured output)?
- **Data layer** — YAML topology manifests and bindings are new artifact types. How do they fit alongside PVR, A&D, Plan artifacts?

### 3. General Design Feedback

- Is the three-layer lifecycle (Provider Setup → Provision → Deploy) the right abstraction?
- Is the topology + bindings + environment model sound?
- Are there Agency projects or patterns that would break this model?
- What's missing?

## Expected Output

A review with findings and recommendations, structured as:
1. Framework-level features to extract (with priority)
2. Design feedback and concerns
3. Relationship to existing Agency patterns
4. Suggested next steps
