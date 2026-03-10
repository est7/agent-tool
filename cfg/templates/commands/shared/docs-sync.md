---
argument-hint: [what changed or what to sync]
description: Persist the current context into the appropriate docs/ files and refresh documentation indexes
---

Persist the current task context into the appropriate `docs/` locations.

Use existing repository and conversation context only. Do not narrate hidden reasoning steps, and do not invent unsupported details.

1. Inspect the current `docs/` structure and the nearest relevant module or subproject docs before writing.
2. Decide which of `docs/design/`, `docs/research/`, `docs/implementation/`, `docs/reference/`, `docs/user/`, `docs/context/`, or `docs/archive/` need updates.
3. Create or update only the necessary files.
4. Refresh `docs/README.md` and any affected local indexes or `README.md` files.
5. If a long-lived document entry point changed, update `AGENTS.md` references when needed.
6. If the repository already has a changelog or release-notes file and the current change warrants it, update it. Do not create one from scratch unless explicitly requested.
7. Do not update `docs/postmortem/` unless the user explicitly asks for postmortem work; use `/postmortem-check` for that path.

Task focus: $ARGUMENTS
