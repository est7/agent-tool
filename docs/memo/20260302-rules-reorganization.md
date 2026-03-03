# Rules Reorganization — Decision Record (Updated)

Date: 2026-03-03

This memo reflects the **current** state of rules/skills in this repo after multiple iterations.

Goals:

- Organize instructions by domain (rules support recursive discovery under `~/.claude/rules/`).
- Keep constraints **full fidelity** (no constraint removal); only move/rename and add index navigation.
- Avoid duplicated handbooks across multiple files (single source of truth per domain).
- Prefer cleanup over archiving for deprecated rule files.

---

## 1. Current Layout

### 1.1 Rules (`cfg/templates/rules/`)

- `core.md` — index entrypoint + user context
- `core/reasoning.md` — reasoning framework + quality evaluation
- `core/workflow.md` — task complexity routing + Plan/Code workflow + answer/style conventions
- `core/self-check.md` — self-check + self-fix protocol
- `conventions.md` — language + git + tools & environment (includes a short summary section)
- `testing/tdd.md` — testing & strict TDD gate
- `memo/task-memo.md` — task memo / 落盘规范
- `comments.md` — commenting policy
- `jetbrains-mcp.md` — JetBrains MCP guidance

### 1.2 Skills (`cfg/templates/skills/`)

- `mcp-services` — full MCP handbook (**canonical**)
- `plan-code-workflow`, `testing-tdd`, `task-memo`, `implementation-gates` — on-demand playbooks

---

## 2. Sync Behavior

`cfg/install_symlinks.sh` copies rules **recursively** from `cfg/templates/rules/` into `$AGENT_HOME/rules/` (excluding `README.md`), then symlinks the whole directory to `~/.claude/rules/`.

It also deletes a small allowlist of deprecated template-managed rule files to prevent stale leftovers under `$AGENT_HOME/rules/`.

---

## 3. Notes / Follow-ups

- Some commit type vocab differs across docs (`fix` vs `bugfix`, presence/absence of `exp`). Not blocking the rules split, but should be normalized later.
- Cross-language implementation standards in `AGENTS.md` are intentionally kept even though this repo is Bash-heavy.

---

## 4. Conclusion

Rules are now domain-organized and navigable; large tool handbooks (notably MCP) have a single canonical home, and deprecated rule files are cleaned up rather than archived.
