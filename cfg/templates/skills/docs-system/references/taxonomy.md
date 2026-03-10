# Docs Taxonomy

Use the following directories consistently.

| Directory | Purpose | Naming |
|-----------|---------|--------|
| `docs/design/` | Architecture, proposals, trade-offs, ADR-like material | `YYYYMMDD-topic.md` for task-bound docs; stable names for canonical designs |
| `docs/research/` | Investigations, comparisons, exploratory findings | `YYYYMMDD-topic.md` |
| `docs/implementation/` | Implementation plans, rollout notes, migration steps, execution records | `YYYYMMDD-topic.md` |
| `docs/reference/` | Durable factual reference: APIs, contracts, commands, data shapes, invariants | Stable descriptive names preferred |
| `docs/user/` | End-user or operator facing docs | Stable descriptive names preferred |
| `docs/context/` | Durable project context that should be readable but not auto-loaded as Claude memory | Stable descriptive names preferred |
| `docs/postmortem/` | Failure-analysis reports and regression guardrails | `YYYYMMDD-topic.md` |
| `docs/archive/` | Superseded but still useful historical documents | Keep original names when possible |

## Selection Heuristics

- Put reusable decision rationale in `design/`.
- Put exploratory or comparative analysis in `research/`.
- Put execution-oriented steps and delivery notes in `implementation/`.
- Put stable lookup material in `reference/`.
- Put user-facing manuals in `user/`.
- Put durable project knowledge that should not live in `CLAUDE.md` or rules in `context/`.
- Put regressions, incidents, and fix-derived guardrails in `postmortem/`.
- Put retired documents in `archive/`.
