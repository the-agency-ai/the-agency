# What Problem: BATS tests for ISCP tools leaked into the live environment —
# 62 flags into the production DB and test user.email/user.name into the
# live .git/config. Even with HOME override and ISCP_DB_PATH, there are
# always new leak vectors (env vars, git worktree shared config, etc.)
#
# How & Why: Docker provides complete filesystem isolation. The container
# has its own HOME, its own git config, its own /tmp. Nothing can leak to
# the host. We mount the repo read-only and copy test-relevant files into
# the container's workspace. Uses alpine + bash + sqlite + git + jq — the
# exact dependencies the ISCP tools need, nothing more.
#
# Written: 2026-04-06 — Docker test isolation (dispatches #16, #17)

FROM alpine:3.21

# Install dependencies: bash, git, sqlite, jq, bats
RUN apk add --no-cache \
    bash \
    git \
    sqlite \
    jq \
    coreutils \
    && git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && /tmp/bats-core/install.sh /usr/local \
    && rm -rf /tmp/bats-core

# Create test user
RUN adduser -D -s /bin/bash testrunner
USER testrunner
WORKDIR /home/testrunner

# Git config for the test user (container-local, can never leak)
RUN git config --global user.email "docker-test@example.com" \
    && git config --global user.name "Docker Test Runner"

# Entry point: run BATS tests
ENTRYPOINT ["bats"]
