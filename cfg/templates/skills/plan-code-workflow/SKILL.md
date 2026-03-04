---
name: plan-code-workflow
description: Complete Plan/Code workflow for moderate and complex tasks. Use when task complexity is moderate or complex (cross-module design, multi-file changes, architectural decisions). Not needed for trivial tasks.
---

# Plan / Code Workflow

This skill defines the complete workflow for non-trivial tasks. Core rules (§2) determine when to activate:

- **trivial** tasks: answer directly, skip this workflow
- **moderate / complex** tasks: follow this workflow

---

## Common Rules

* **On first entering Plan mode**, briefly restate:
  * Current mode (Plan or Code)
  * Task objective
  * Key constraints (language, file scope, forbidden ops, test scope)
  * Known task state / assumptions
* After initial restatement, only repeat on **mode switch** or **significant constraint change**.
* Read and understand related code before proposing any design — never suggest modifications without reading code first.
* Do not introduce entirely new tasks beyond scope (e.g., bug fix request → don't propose subsystem rewrite).
* Fixing your own introduced errors is NOT scope expansion — handle directly.
* When user says "实现", "落地", "按方案执行", "开始写代码", "帮我写出来":
  * Treat as explicit request for **Code mode**. Switch immediately. Do not re-confirm.

---

## Plan Mode (Analysis / Alignment)

1. Analyze top-down; find root causes and critical paths, not just symptom patches.
2. List key decision points and trade-off factors.
3. Provide **1–3 viable approaches**, each with:
   * Summary
   * Impact scope (modules, components, interfaces)
   * Pros and cons
   * Potential risks
   * Recommended verification
4. Ask clarifying questions **only** when missing info would block progress or change main approach.
5. Avoid essentially identical plans — describe deltas only.

**Exit conditions:**

* User explicitly selects an approach, **OR**
* One approach is clearly superior — select it proactively with reasoning.

Once exit conditions are met → enter Code mode in the very next reply.

---

## Code Mode (Implementation)

**Before writing code:**

* Read related code and understand existing design.
* Find 2–3 similar implementations in codebase as reference.
* Confirm test framework and verification approach.
* For non-trivial tasks: first deliverable is the test, not the implementation (see `testing-tdd` skill).

**In Code mode:**

1. Primary content must be **concrete implementation**, not extended plan discussion.
2. Before code, briefly state:
   * Which files / functions will be modified
   * Purpose of each change
3. Prefer **minimal, reviewable changes** (local snippets/patches, not large unmarked files).
4. State how to verify: tests/commands to run, new test case drafts.
5. If a major problem is discovered → pause, switch back to Plan mode with explanation.

**Output must include:**

* What changed, in which files/functions/locations.
* How to verify (tests, commands, manual checks).
* Any known limitations or follow-up TODOs.

---

## Re-planning

If forced to re-plan:

* Explain why current approach can't continue
* What new prerequisite or decision is needed
* What changed vs the previous plan

Do not linger in Plan mode — enter Code mode as soon as exit conditions are met.
