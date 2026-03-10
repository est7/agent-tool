---
name: docs-system
description: Organizes and persists project documentation into the appropriate docs/ categories using existing conversation and repository context. Use when the user asks to record work, sync docs, update design/research/implementation/reference/user/context docs, maintain postmortems, archive superseded material, or refresh documentation indexes.
---

# Docs System

Use this skill to persist existing context into the right long-lived documents.

## Core Rule

Document using the context that already exists in the conversation and repository.

- Do **not** narrate hidden reasoning steps.
- Do **not** invent implementation details that are not already supported by context.
- Do **not** create a CHANGELOG unless the repository already has one or the user explicitly asks for it.

## Directory Taxonomy

Primary document tree:

- `docs/design/`
- `docs/research/`
- `docs/implementation/`
- `docs/reference/`
- `docs/user/`
- `docs/context/`
- `docs/postmortem/`
- `docs/archive/`

`docs/context/` is for durable project context documents. It is **not** the same thing as Claude memory (`AGENTS.md`, `CLAUDE.md`, rules).

See:

- [references/taxonomy.md](references/taxonomy.md)
- [references/indexing.md](references/indexing.md)
- [references/postmortem.md](references/postmortem.md)
- [README.md](README.md)
- [references/docs-readme-template.md](references/docs-readme-template.md)
- [references/design-template.md](references/design-template.md)
- [references/research-template.md](references/research-template.md)
- [references/implementation-template.md](references/implementation-template.md)
- [references/reference-template.md](references/reference-template.md)
- [references/user-template.md](references/user-template.md)
- [references/context-template.md](references/context-template.md)
- [references/postmortem-template.md](references/postmortem-template.md)
- [references/postmortem-readme-template.md](references/postmortem-readme-template.md)
- [references/archive-template.md](references/archive-template.md)

## When to Write or Update Docs

Create or update docs when any of these is true:

- The user explicitly asks to record, sync, persist, archive, or organize documentation.
- A task produces reusable design, research, implementation, or operational knowledge.
- A failure, regression, or fix should become a `postmortem`.
- A document index (`docs/README.md` or `docs/postmortem/README.md`) would become stale after the change.

## Placement Rules

Before writing, inspect the nearest existing documentation location.

1. If the work belongs to a subproject or module that already has local docs, update those docs first.
2. If the information is cross-cutting or project-wide, write it under the root `docs/` tree.
3. If a document is superseded but worth keeping, move it to `docs/archive/` and leave an index entry.

## Template Rule

Each `docs/` category has its own template file. Use the matching template as the starting structure, then trim or extend it to fit the actual context.

## Postmortem Rules

Use `docs/postmortem/` for failure-analysis documents with strong warning value.

- **Onboarding**: summarize important historical fix patterns into durable reports.
- **Pre-release**: compare the current release or change scope against existing postmortems.
- **Post-fix / post-release**: create or update reports from fresh failures and fixes.

Each postmortem should make future regressions harder, not just preserve history.
