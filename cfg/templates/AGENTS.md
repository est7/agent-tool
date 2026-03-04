# AGENTS.md

## Agent Behavior

- Perform chain-of-thought and reasoning in English; communicate with the user strictly in Chinese.
- When the user's description is ambiguous, incomplete, or contradictory, ask targeted clarifying questions before starting work. Do not assume or guess missing context.
- After being corrected on a mistake, add a new guardrail to the project's `CLAUDE.md` only when the mistake is reproducible, likely to recur, and repository/workflow-specific. Keep the guardrail concise and actionable.
- Complete the requested task first. If you make any changes beyond the stated scope (opportunistic fixes, refactors, design improvements), explicitly list them afterward with a rationale, so the user can decide whether to keep or revert them.

## Project Hygiene

- Root directory and each meaningful module directory must contain a `README.md` explaining usage; update only when the public interface or usage changes. Treat “module” as a semantic unit (a folder that exposes a public interface or a standalone workflow), not a fixed list of directory names.
- Maintain a clean project structure by strictly avoiding clutter in the root directory and promptly deleting any unnecessary or temporary files.
- Eliminate obsolete and historical code only when it is clearly unused and within the current task scope; for cross-module or large cleanup, list the cleanup set and ask for confirmation first.
- Ensure all code is formatted using the repository's existing linters/formatters (e.g., Prettier, Ruff, ESLint) before delivery (and before committing, if committing).

## Implementation Standards

- Implement complete, fully functional features in production code; placeholders and fake logic are not allowed. In tests, mocks are permitted but prefer integration tests against real boundaries or controllable fakes (e.g., local containers, test services) over behavior stubs.
- Enforce strong typing (e.g., TypeScript interfaces, Python type hints) across the codebase to ensure type safety and improve maintainability.
- Handle errors explicitly at I/O boundaries (network, filesystem, process execution); never silently ignore failures.
- Never hardcode sensitive information (secrets, API keys); always use environment variables and .env files. If new required variables are introduced, provide `.env.example`.
- Prefer the standard library over adding new dependencies for simple tasks. Every new dependency must be explicitly justified by evaluating its maintenance status, license, and security exposure.
- In production code, use a structured logging framework; never use print/console.log. Include relevant context (request ID, user ID, operation name) in log entries. For scripts/CLI tools, prefer project logging helpers if available and avoid unstructured debug output.

## Development Principles

- Adhere to the KISS, DRY, and YAGNI core principles to keep code simple, avoid repetition, and prevent over-engineering.
- Adhere to SOLID principles to ensure single responsibility, extensibility, and proper dependency management through clear abstractions.
- Prioritize high cohesion and low coupling through separation of concerns while favoring composition over inheritance.
- Prioritize code readability and correctness, avoiding premature optimization unless strictly necessary.
- Follow established industry best practices first. For complex/architectural decisions where no clear consensus exists, evaluate 2–3 distinct approaches, compare trade-offs explicitly, and proceed with the strongest one.

## Code Comments

- Ensure minimal visibility (smallest possible). Any intentionally `public` function, property, class, or module is considered external-facing service/API surface and must have documentation comments (docstring / KDoc / JSDoc) covering inputs, outputs, errors, and edge cases.
- Internal implementation does not require forced comments; only add intent comments where the logic is non-obvious.

## Bug Fixes

- Before fixing a bug, write a failing test that reproduces it; fix until the test passes. If a reliable automated test is not feasible (e.g., external environment/client device), provide exact reproduction steps and a minimal verification checklist instead.
- If automated tests are insufficient or human verification is needed, provide exact reproduction steps (environment, inputs, expected vs. actual behavior) and how to capture evidence (logs/screenshots).
