# AGENTS.md

## Agent Behavior

- Perform chain-of-thought and reasoning in English; communicate with the user strictly in Chinese.
- When the user's description is ambiguous, incomplete, or contradictory, ask targeted clarifying questions before starting work. Do not assume or guess missing context.
- After being corrected on a mistake, immediately add a new rule to the project's CLAUDE.md to prevent repeating it.
- Complete the requested task first. If you make any changes beyond the stated scope (opportunistic fixes, refactors, design improvements), explicitly list them afterward with a rationale, so the user can decide whether to keep or revert them.

## Project Hygiene

- Root directory and every module directory must contain an README.md explaining usage; update only when the public interface or usage changes.
- Maintain a clean project structure by strictly avoiding clutter in the root directory and promptly deleting any unnecessary or temporary files.
- Eliminate all obsolete and historical code to maintain a clean codebase, prioritizing code hygiene over backward compatibility.
- Ensure all code is formatted according to standard linters/formatters (e.g., Prettier, Ruff, ESLint) before committing.

## Implementation Standards

- Implement complete, fully functional features in production code; placeholders and fake logic are not allowed. In tests, mocks are permitted but prefer integration tests against real boundaries or controllable fakes (e.g., local containers, test services) over behavior stubs.
- Enforce strong typing (e.g., TypeScript interfaces, Python type hints) across the codebase to ensure type safety and improve maintainability.
- Handle errors explicitly at I/O boundaries (network, filesystem, process execution); never silently ignore failures.
- Never hardcode sensitive information (secrets, API keys); always use environment variables and .env files. Provide `.env.example` for required variables.
- Prefer the standard library over adding new dependencies for simple tasks. Every new dependency must be explicitly justified by evaluating its maintenance status, license, and security exposure.
- Use a structured logging framework in production code; never use print/console.log. Include relevant context (request ID, user ID, operation name) in log entries.

## Development Principles

- Adhere to the KISS, DRY, and YAGNI core principles to keep code simple, avoid repetition, and prevent over-engineering.
- Adhere to SOLID principles to ensure single responsibility, extensibility, and proper dependency management through clear abstractions.
- Prioritize high cohesion and low coupling through separation of concerns while favoring composition over inheritance.
- Prioritize code readability and correctness, avoiding premature optimization unless strictly necessary.
- Follow established industry best practices first. When no clear consensus exists, evaluate at least three distinct approaches, compare their trade-offs explicitly, and proceed with the strongest one.

## Code Comments

- Public-facing functions, classes, and modules must have documentation comments (docstring / KDoc / JSDoc) covering inputs, outputs, errors, and edge cases.
- Internal implementation does not require forced comments; only add intent comments where the logic is non-obvious.

## Bug Fixes

- Before fixing a bug, write a failing test that reproduces it; fix until the test passes.
- If human verification is needed, provide exact reproduction steps (environment, inputs, expected vs. actual behavior).
