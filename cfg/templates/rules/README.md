# Rules (`cfg/templates/rules`)

Reusable rule documents used by this repository's template system.

Files:

- `core.md`: index entrypoint for core rules (split by domain).
- `core/reasoning.md`: core reasoning framework + quality evaluation.
- `core/workflow.md`: task complexity routing + Plan/Code workflow + answering conventions.
- `core/self-check.md`: self-check and self-fix protocol.
- `testing/tdd.md`: testing and TDD requirements.
- `docs/docs-system.md`: documentation persistence / docs system.
- `conventions.md`: language + git + tools & environment (also includes short commenting guidance).

Note:

- `core.md` is an index entrypoint; truly core rules live under `core/`. Non-core domains live under folders like `testing/`, `docs/` or at the top level (e.g. `conventions.md`).
- When you have heavy playbooks or tool handbooks that are not required every session, prefer putting them into Skills under `cfg/templates/skills/` for on-demand loading (e.g. JetBrains guidance lives in `jetbrains-skill`).
