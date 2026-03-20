---
name: deep-plan
description: "Deep structured analysis and planning with script-enforced quality gates. Use when the user explicitly asks for deep planning, thorough analysis before a complex decision, or invokes /deep-plan. Also use when a task involves cross-service architecture, migration strategy, or multi-stakeholder tradeoffs that need rigorous reasoning before implementation. Not needed for routine Plan/Code workflow — that is handled by plan-code-workflow."
user-invocable: true
argument-hint: <task description>
allowed-tools: Bash(python *validate_plan.py*), AskUserQuestion
---

# Deep Plan

Structured deep analysis with **script-enforced output gates**. Unlike prompt-only self-checks, this skill validates thinking quality programmatically — the validator script parses your output and rejects incomplete analysis.

## When to use this vs plan-code-workflow

- **plan-code-workflow**: organizing what to build and how — Plan mode → Code mode
- **deep-plan**: rigorous reasoning *before* deciding what to build — when the decision itself is the hard part

Use deep-plan first, then hand off to plan-code-workflow for execution.

---

## Phase 1 — Complexity Assessment

Classify the task:

| Level | Criteria | Min Steps |
|-------|----------|-----------|
| simple | Single file/function, no cross-module impact | 3 |
| medium | Multi-file/module, design choices needed | 5 |
| complex | Cross-service, architecture tradeoffs, migration | 8 |

Output the complexity level and your initial step count estimate. This determines the validator's minimum step threshold.

---

## Phase 2 — Sequential Thinking

Output numbered thinking steps. Each step MUST use this exact format:

```
### Step N/M [tag]
- **Focus**: What this step analyzes (one concern per step)
- **Findings**: Observations, evidence, conclusions
- **Confidence**: high | medium | low
- **Next**: What the next step addresses (or "→ Gate" on final step)
```

### Tags

| Tag | When to use |
|-----|-------------|
| `analysis` | Examining a specific aspect |
| `decomposition` | Breaking problem into sub-problems |
| `evaluation` | Assessing an approach or alternative |
| `comparison` | Comparing options side-by-side |
| `revision` | Revising a previous step — use `[revision of Step X]` |
| `branch` | Exploring an alternative path — use `[branch: id]` |
| `synthesis` | Combining findings into a conclusion |

### Rules

1. **One concern per step.** Do not combine multiple analyses.
2. **Adjust M freely.** Add steps as understanding deepens; reduce if a path is clearly simpler.
3. **Revise explicitly.** When new evidence contradicts an earlier step, tag as `revision` and cite which step.
4. **Address low confidence.** Any step with `Confidence: low` must be followed up by a later step that resolves the uncertainty.
5. **Terminate with "→ Gate".** The final step's Next field must say "→ Gate" to signal readiness for validation.

### Required coverage

Your steps must collectively cover all of these (order is flexible):

1. **Problem definition** — core problem, constraints, success criteria
2. **Decomposition** — sub-problems (MECE: mutually exclusive, collectively exhaustive)
3. **Evaluation** — at least 1 alternative approach assessed (or explicit justification why only 1 viable path exists)
4. **Tradeoff comparison** — tabular comparison on ≥3 dimensions (when alternatives exist)
5. **Execution steps** — 4–10 ordered, concrete, verifiable actions
6. **Risks** — issues and concrete mitigations

---

## Phase 3 — Validation Gate (Script-Enforced)

After completing all thinking steps, synthesize into a plan document and run the validator.

### Step 3a — Write the plan to a temp file

Write to `/tmp/deep-plan-output.md` containing both your thinking steps AND the plan:

```markdown
complexity: <level>

(All your ### Step N/M [tag] blocks from Phase 2)

## Plan: {task title}

### Problem Definition
- **Core problem**: ...
- **Constraints**: ...
- **Success criteria**: ...

### Analysis Summary
Key findings referencing step numbers.

### Execution Plan
1. Step — description → verification method
2. Step — description → verification method
...

### Risks
- Risk → mitigation

### Open Questions
- [ ] Assumptions needing confirmation
```

### Step 3b — Run the validator

```bash
python <skill-path>/scripts/validate_plan.py /tmp/deep-plan-output.md
```

The script checks 8 gates:

| Gate | What it checks |
|------|---------------|
| `step_format` | Every step has Focus, Findings, Confidence, Next |
| `step_tags` | All tags are from the valid set |
| `coverage` | All required topics addressed |
| `termination` | Final step ends with "→ Gate" |
| `low_confidence_addressed` | Low-confidence steps resolved later |
| `plan_sections` | Plan has all required sections |
| `execution_verification` | Every execution step has a verification method |
| `minimum_steps` | Step count meets complexity threshold |

### Step 3c — Handle results

- **All gates pass** → proceed to Phase 4
- **Any gate fails** → read the failure details, add thinking steps to fill the gaps, rewrite the plan, rerun the validator. Repeat until all gates pass. Do NOT proceed with failing gates.

---

## Phase 4 — Review Gate (Human)

Present the validated plan to the user. Then pause with AskUserQuestion:

- "Approve — proceed to execute"
- "Adjust — specify what to change"
- "Abort — discard this plan"

Do NOT proceed without explicit approval.

---

## Phase 5 — Persist and Execute

Only after approval:

1. Write plan to `plan/YYYY-MM-DD_HH-mm-ss-<slug>.md` with frontmatter:

```yaml
---
mode: plan
task: <task title>
complexity: <simple|medium|complex>
created_at: <ISO8601>
validated: true
---
```

2. Execute the plan step by step.

---

## Session Continuity

- "adjust", "modify", "refine" → update plan, re-validate, re-enter Phase 4
- "new", "different task" → restart from Phase 1
- Uncertain → ask the user
