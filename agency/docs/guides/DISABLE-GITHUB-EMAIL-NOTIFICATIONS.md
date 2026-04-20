<!-- What Problem: GitHub sends email on every CI failure, training everyone to
ignore notifications — the broken window that triggered the contribution model
rework. This guide documents how to disable the noise.

How & Why: Step-by-step for the principal to disable GitHub email notifications
and replace them with the ci-monitor tool (Monitor-based, agent-actionable).

Written: 2026-04-12 during devex Day 35 — contribution model rollout -->

# Disable GitHub Email Notifications

GitHub sends email on every CI failure. With the three-ring CI model, failures on main are rare and actionable — but email is the wrong channel. Replace with the `/monitor-ci` skill.

## Step 1: Disable CI failure emails

1. Go to **GitHub.com** > **Settings** > **Notifications**
2. Under **Actions**, uncheck:
   - "Send notifications for failed workflows only"
   - Or set to "Don't notify me" for the-agency repo
3. Under **Email notification preferences**, you can also filter by repo

Alternatively, per-repo:
1. Go to **github.com/the-agency-ai/the-agency**
2. Click **Watch** dropdown (top right)
3. Select **Custom** > uncheck **Workflows**

## Step 2: Use ci-monitor instead

In any captain session, start CI monitoring:

```
/monitor-ci
```

This runs `./claude/tools/ci-monitor` in the background via the Monitor tool. Silent when green. Structured output when failures exist. 60-second latency. Zero email noise.

## Step 3: Verify

After disabling:
1. Push a commit to a PR branch
2. Wait for CI to run
3. Verify no email arrives
4. Verify `/monitor-ci` reports the result

## Why this matters

Email notifications trained everyone to ignore CI — the broken window that persisted for weeks. The ci-monitor tool replaces passive email with active agent monitoring. Failures become dispatch-level events, not inbox noise.
