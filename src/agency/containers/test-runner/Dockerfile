# the-agency isolated test-runner image
#
# A disposable Linux environment for running the framework's bats suite in a
# container, so a buggy test can only trash the container, never the host repo.
# Kept minimal + OCI-standard so it runs identically under Apple `container`
# (Apple Silicon) and Docker (Linux/CI/Intel) — the two backends behind
# agency/tools/lib/_container-runtime.
#
# Tools mirror what the bats suite actually invokes: bash, git, bats, jq,
# python3, and the coreutils/findutils/grep/sed/gawk userland.
FROM alpine:3.20
RUN apk add --no-cache \
        bash \
        git \
        bats \
        jq \
        python3 \
        coreutils \
        findutils \
        grep \
        sed \
        gawk \
    && rm -rf /var/cache/apk/*
# No ENTRYPOINT: the runner drives the container with an explicit `bash -c ...`
# so it can copy the repo to a writable workdir and invoke bats with arguments.
WORKDIR /work
