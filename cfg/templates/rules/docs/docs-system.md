# Docs System (Documentation Persistence)

---

## 11 · Docs System

When durable project knowledge should be written down, persist it into the appropriate `docs/` category rather than leaving it only in conversation.

### Primary Directories

- `docs/design/`
- `docs/research/`
- `docs/implementation/`
- `docs/reference/`
- `docs/user/`
- `docs/context/`
- `docs/postmortem/`
- `docs/archive/`

### Core Rules

- Use existing conversation and repository context; do not narrate hidden reasoning steps.
- Choose the closest existing docs location first for subprojects and modules.
- Update `docs/README.md` when the active docs set or important entry points change.
- Update `docs/postmortem/README.md` when `docs/postmortem/` changes.
- `docs/context/` is for durable project context docs and is distinct from `AGENTS.md`, `CLAUDE.md`, and rules-based memory.
- If the repository already has a changelog or release-notes file, update it when relevant; do not invent one by default.

### Postmortem Use

Use `docs/postmortem/` for:

- onboarding summaries from important historical fix patterns
- pre-release checks against known failure patterns
- post-fix or post-release synthesis of new regression guardrails

Reference docs:

- [`cfg/templates/skills/docs-system/references/taxonomy.md`](../../skills/docs-system/references/taxonomy.md)
- [`cfg/templates/skills/docs-system/references/indexing.md`](../../skills/docs-system/references/indexing.md)
- [`cfg/templates/skills/docs-system/references/postmortem.md`](../../skills/docs-system/references/postmortem.md)
