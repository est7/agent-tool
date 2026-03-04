---
name: implementation-gates
description: Pre-implementation quality gates for non-trivial features. Use when implementing moderate or complex features to ensure proper boundaries, minimal structure, and no unnecessary abstraction. Includes exception protocol for skipping gates.
---

# Implementation Gates

Pre-implementation quality checks. Apply based on task complexity:

| Gate | trivial | moderate | complex |
|------|---------|----------|---------|
| Simplicity Gate | apply | apply | apply |
| Anti-Abstraction Gate | apply | apply | apply |
| Library Gate | skip | if applicable | apply |
| CLI Gate | skip | if applicable | apply |
| Test-First Gate | skip | recommended | mandatory |
| Integration-First Gate | skip | recommended | mandatory |

---

## Simplicity Gate (Article VII)

- [ ] No unnecessary new top-level modules/packages introduced (if new, must have justification)
- [ ] No future-proofing: every abstraction layer has a clear, current need
- [ ] No speculative generalization

## Anti-Abstraction Gate (Article VIII)

- [ ] Framework/standard library capabilities used directly (no unnecessary wrappers)
- [ ] No wrappers introduced solely for "unified interface" or "elegance" without measurable benefit
- [ ] Single model representation: same concept not duplicated across layers without clear boundary justification

**Clarification on SOLID compatibility**: SOLID principles (especially Dependency Inversion) are compatible with Anti-Abstraction. An interface for dependency boundary = good. A wrapper that just delegates with no added value = bad.

## Library Gate (Article I)

**Applies to**: domain logic, data transformation, rule engines, parsers, code generators, batch processors.
**Does NOT apply to**: pure UI, one-time glue code, thin integration wrappers.

When applicable:

- [ ] Reusable boundary identified (input / output / error model / minimal dependencies)
- [ ] Application layer only orchestrates; core rules live in the library

## CLI Gate (Article II)

When applicable (i.e., Library Gate also applies):

- [ ] CLI accepts text input (stdin / args / files)
- [ ] CLI outputs text to stdout, supports JSON
- [ ] Errors go to stderr with non-zero exit codes

---

## Exception Protocol

When a gate does not apply to the current task, you must state:

1. **Which gate** is being skipped
2. **Why** it doesn't apply (environment / time / dependency / scope)
3. **Alternative** verification or observability measure
4. **Risk** and impact (short-term / long-term)
5. **Recovery plan** — under what conditions to restore compliance

---

## Usage

* **complex tasks**: Output the gate checklist in Plan mode for user review.
* **moderate tasks**: Run gates internally, note any exceptions in the plan.
* **trivial tasks**: Only Simplicity + Anti-Abstraction gates apply (run mentally).
