---
description: 深度分析规划，含 review gate，使用 sequential-thinking
argument-hint: <task description>
---

Produce a reviewable, executable plan for **$ARGUMENTS** using the workflow below.

## Phase 1 — Complexity Assessment

Classify the task before planning:

| Level | Criteria | totalThoughts |
|-------|----------|---------------|
| simple | Single file/function, no cross-module impact | 4 |
| medium | Multi-file/module, design choices needed | 7 |
| complex | Cross-service, architecture tradeoffs, migration | 10 |

## Phase 2 — Structured Analysis via Sequential Thinking

Call `mcp__sequential-thinking__sequentialthinking` to decompose the task:

- Start: thoughtNumber=1, nextThoughtNeeded=true
- Dynamically adjust totalThoughts as understanding deepens
- End: set nextThoughtNeeded=false when the plan is sufficiently detailed

During analysis, cover:

1. **Problem definition** — core problem in one sentence, constraints, success criteria
2. **Decomposition** — break into sub-problems (MECE: mutually exclusive, collectively exhaustive)
3. **Multi-perspective evaluation** (when alternatives exist):
   - Technical: feasibility, risk, scalability
   - Business: value, delivery speed, opportunity cost
   - Operational: deployment complexity, monitoring, failure recovery
4. **Tradeoff comparison** — tabular comparison of options on key dimensions
5. **Execution steps** — ordered, concrete, verifiable steps (4-10)
6. **Risks** — potential issues and mitigation strategies

## Phase 3 — Present Plan for Review

Output the plan in this format:

```
## Plan: {task title}

### Problem Definition
- **Core problem**: ...
- **Constraints**: ...
- **Success criteria**: ...

### Analysis Summary
(Key findings from sequential thinking)

### Execution Plan
1. Step 1 — description
2. Step 2 — description
... (4-10 steps)

### Risks
- Risk 1 → mitigation
- Risk 2 → mitigation

### Open Questions
- [ ] Assumptions that need confirmation
```

## Phase 4 — Review Gate (Critical)

After presenting the plan, you MUST pause and ask the user for review using AskUserQuestion:

- Option 1: "Approve — proceed to execute"
- Option 2: "Adjust — specify what to change"
- Option 3: "Abort — discard this plan"

Do NOT proceed to Phase 5 without explicit user approval.

## Phase 5 — Persist and Execute

Only after approval:

1. Write plan file to `plan/YYYY-MM-DD_HH-mm-ss-<slug>.md` with frontmatter:

```yaml
---
mode: plan
task: <task title>
complexity: <simple|medium|complex>
created_at: <ISO8601>
---
```

2. Begin executing the plan step by step.

## Session Continuity

- User says "adjust", "modify", "refine" → update existing plan, re-enter Phase 4
- User says "new", "different task" → start fresh from Phase 1
- When uncertain → ask the user
