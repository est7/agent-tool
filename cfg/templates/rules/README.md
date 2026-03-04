# Rules (`cfg/templates/rules`)

Reusable rule documents used by this repository's template system.

Files:

- `core.md`: index entrypoint for core rules (split by domain).
- `core/reasoning.md`: core reasoning framework + quality evaluation.
- `core/workflow.md`: task complexity routing + Plan/Code workflow + answering conventions.
- `core/self-check.md`: self-check and self-fix protocol.
- `testing/tdd.md`: testing and TDD requirements.
- `memo/task-memo.md`: task memo / 落盘规范.
- `conventions.md`: language + git + tools & environment.
- `jetbrains-mcp.md`: guidance for using the `jetbrains` MCP server (JetBrains IDE integration).
- `comments.md`: project-wide commenting policy and guidance.

Note:

- `core.md` is an index entrypoint; truly core rules live under `core/`. Non-core domains live under folders like `testing/`, `memo/` or at the top level (e.g. `conventions.md`).
- When you have heavy playbooks or tool handbooks that are not required every session, prefer putting them into Skills under `cfg/templates/skills/` for on-demand loading.
