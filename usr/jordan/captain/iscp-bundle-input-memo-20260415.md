---
type: memo
date: 2026-04-15
author: the-agency/jordan/captain
to: jordan (principal)
re: ISCP Dispatch Service — PVR + A&D + Plan bundle
status: ready for sign-off discussion
---

# Captain memo — ISCP Dispatch Service bundle

You asked for my input on the autonomous overnight bundle from the ISCP agent
(PVR, A&D, Plan). My recommendation: **APPROVE and authorize Iter 1**, with
two clarifications and one small Plan addendum.

## What was produced

| Artifact | Path | Size |
|----------|------|------|
| PVR | `agency/workstreams/iscp/dispatch-service-pvr-20260414.md` | 9 sections complete |
| A&D | `agency/workstreams/iscp/dispatch-service-ad-20260415.md` | 604 lines, 10 sections, 10 trade-offs, 10 failure modes |
| Plan | `agency/workstreams/iscp/dispatch-service-plan-20260415.md` | 8 iterations, 8 weeks, 7 milestones, 10-risk register |

The agent ran the full PVR → A&D → Plan chain autonomously per directive,
paused at the sign-off gate (Plan §8) per protocol. Did not start
implementation. This is exactly the discipline we asked for.

## What's good

1. **Local-first for ≤3-segment addresses.** Preserves all existing ISCP
   semantics. Hub only sees 4-segment (cross-org) traffic. This is the right
   architectural call — minimizes hub criticality.

2. **Append-only envelope, idempotency on (from, idempotency_key).** Solves
   delivery semantics cleanly. UUIDv7 for `idempotency_key` gives time-ordered
   dedup keys, which is good for partitioning.

3. **Storage split — Postgres for metadata, object store for body.** Right
   shape: small envelopes in indexed PG (filterable by `to_org`, `from_org`,
   `created_at`, status), large markdown payloads in cheap object storage
   (Fly Volumes or Tigris). Avoids bloating PG.

4. **ETag-based polling for receive.** Standard, efficient, lets us cache hits
   return 304 immediately. Pairs well with `since_id` pagination.

5. **GitHub OAuth for admin web UI, JWT for client.** Sane separation. Admin
   surface is rare-use, OAuth is appropriate. Client surface is per-call,
   JWT is appropriate.

6. **8 iterations / 8 weeks with critical path 1→2→3→6→7→8 and 4+5
   parallelizable.** Realistic. The parallel slot creates room for one
   contractor or for the iscp agent to multitask if work allows.

7. **Sunset of `collaborate` by Week 12.** Clean migration story. Existing
   collaboration repos remain readable through the hub for a defined window.

8. **<$50/mo target.** Realistic at low volume — Fly Managed PG starts ~$15,
   compute ~$5-10, Tigris/object store usage-billed for our envelope sizes.
   Headroom for growth before we'd need to revisit.

## What needs clarification before Iter 1

### 1. Multi-tenancy model — what is an "org"?

The A&D treats `org` as company-level (Anthropic as one org, with multiple
principals and repos under it). The PVR is more ambiguous. This affects:

- Token scope hierarchy (`scope_principal`, `scope_agent` make sense if
  org=company; less clear if org=principal)
- Billing surface
- The address-ladder (`org/repo/principal/agent` — does `jordan@anthropic`
  resolve as `org=anthropic, principal=jordan` or `org=jordan-anthropic`?)
- Sign-up flow on the admin UI

**Ask:** Confirm org=company semantics. If yes, Iter 1 is unblocked.
If no, A&D needs ~half a section rewritten before Iter 1.

### 2. JWT key rotation operational story

A&D §2.1 includes `jwt_key_id` on tokens (good — supports key rotation),
but the Plan doesn't allocate explicit time for the rotation runbook. Iter 6
(security & ops) should include:

- Key rotation cadence (suggest: 90 days standard, 24h emergency)
- Rotation procedure (publish new `kid` to JWKS, deprecate old, grace
  window for clients to refresh)
- Token revocation propagation latency target (suggest: 60s P99)

**Ask:** Approve adding a single sub-iteration line to Plan Iter 6 covering
this. Doesn't add weeks; just makes the work explicit.

## What to defer (not blocking)

- **Postgres choice.** A&D commits to Fly Managed PG. Plausible alternatives
  (FoundationDB-tier in Tigris, raw SQLite over Litestream replication) have
  different cost/durability profiles at scale. Defer to Iter 5 (perf/scale
  validation). Don't re-litigate now — Fly Managed PG is the right Iter-1
  default.

- **Geographic distribution.** A&D is single-region. Cross-region replication
  for latency/availability is post-GA. Acceptable for v1.

- **Webhook/push delivery.** Plan is poll-only. Push delivery (webhooks,
  Server-Sent Events) is post-GA. Acceptable; agents already poll on
  session-start + 60s.

## Recommendation

**APPROVE the bundle. AUTHORIZE Iter 1.**

Conditions:
1. Confirm org=company semantics (1B1 with iscp before Iter 1 starts).
2. Add JWT-rotation sub-iteration to Plan Iter 6 (iscp updates Plan, no QG
   needed for that one-line addendum).
3. Land the bundle on main as part of D41-R5 documentation release (no PR
   blocker — it's docs).

After sign-off, dispatch iscp to:
- Start Iter 1 (Postgres schema + auth scaffold)
- Confirm the org-semantics decision in their handoff
- Update Plan Iter 6 with the rotation sub-item

## Open items NOT in this bundle worth flagging

- **Cross-org permissions matrix.** Who can dispatch to whom across orgs?
  PVR mentions broadcast but the A&D scopes it via token permissions. A
  matrix doc would help — not blocking Iter 1, but should be in PVR before
  Iter 4 (broadcast feature).

- **GDPR / data residency.** A&D is single-region (Fly's primary). For EU
  customers, may need EU-region option. Defer to Iter 8 (GA prep).

- **Pricing surface for paid tiers.** Plan sets target <$50/mo for our use,
  but if this becomes a hosted product, pricing tiers need design. Out of
  scope for v1; flag for product-strategy 1B1 separately.

## Captain assessment of Plan quality

This is a *competent* Plan. Iterations are sized appropriately (each 1 week,
matching mdpal-cli pacing). Dependencies are explicit. Risk register is
realistic (10 risks, mitigations specific). Test levels are spelled out
(unit, integration, contract, load, security, chaos, smoke, e2e). Sign-off
gate before implementation is correct discipline.

I don't think a re-review is warranted before Iter 1 starts — sign off and
go.

— captain, the-agency
