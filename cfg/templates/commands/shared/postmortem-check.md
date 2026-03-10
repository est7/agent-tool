---
argument-hint: [release scope or fix context]
description: Check current work against existing postmortems and update docs/postmortem when needed
---

Review the current release or fix context against `docs/postmortem/` and persist any required updates.

Use existing repository and conversation context only. Do not narrate hidden reasoning steps, and do not invent unsupported details.

1. Read `docs/postmortem/README.md` and the most relevant existing reports.
2. Determine whether the current release scope or fix context matches prior failure patterns.
3. Before release, surface concrete regressions, missing checks, or fixes that must be addressed.
4. After a fix or release, create or update the relevant `docs/postmortem/YYYYMMDD-topic.md` report.
5. Refresh `docs/postmortem/README.md` and cross-link related `docs/design/`, `docs/research/`, or `docs/implementation/` files when useful.
6. Keep the output concrete and durable: trigger, impact, root cause, guardrails, verification, and follow-up.

Scope: $ARGUMENTS
