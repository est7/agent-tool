# Testing & TDD

---

## 10 · Testing & TDD Requirements

### 10.1 Always Apply

* Every implementation must include a test plan or verification method.
* **Coverage**: happy path + boundary conditions + error recovery.
* **Test naming**: clearly describe the scenario, e.g., `test_login_with_invalid_password_returns_401`.
* For non-trivial logic changes (complex conditions, state machines, concurrency, error recovery): prefer adding or updating tests.
* When tests are missing, state the reason and a follow-up test plan in the delivery.

### 10.2 Observation & Honesty

* Report only what you can directly observe.
* If you can run tests in the current environment: run them and report actual results.
* If you cannot run tests: provide exact commands, expected failure points, and wait for user confirmation before proceeding.
* Never fabricate or assume test results.

### 10.3 TDD Gate (for non-trivial implementations)

Strict Red-Green-Refactor cycle:

1. **Red**: Write tests first that define expected behavior and boundary conditions.
2. **Review**: Tests must be reviewed by the user before proceeding.
3. **Confirm Red**: Verify tests fail with current implementation (run or provide commands for user to confirm).
4. **Green**: Write minimum implementation to make tests pass.
5. **Refactor**: Clean up without changing behavior.

**Complexity gating:**

* **trivial** tasks (one-line fix, simple config): TDD gate is optional. Provide a verification method instead.
* **moderate** tasks: TDD gate recommended. Write test → implement → verify.
* **complex** tasks: TDD gate mandatory. Full Red-Green-Refactor cycle.
* **Bug fixes** (all levels): Always write a failing test that reproduces the bug first, then fix.

### 10.4 Integration-First Strategy

Test priority order:

1. **Real environment first**: use real database, actual service instances when available.
2. **Contract tests**: define contracts (input/output/error semantics) and write contract tests before implementation.
3. **Mocks only when necessary**: if mock/stub is unavoidable, document:
   * Why real boundary is not available
   * What real-world coverage is missing
   * Compensating strategy (e.g., additional E2E test or smoke verification)

### 10.5 Deliverables

For each implementation, testing deliverables include:

* Tests (unit + integration/contract as appropriate)
* Runnable verification commands (or user-side reproduction steps + expected output)
* Exception notes if any gate was skipped (with risk and compensating strategy)

---
