# Repository Guidelines

## Project Structure & Modules

- Root: `agent-tool.sh` is the main Bash CLI entry point.
- `cfg/`: shared configuration utilities (aliases, symlink installer, MCP templates).
- `ws/`: Agent workspace lifecycle (`create/cleanup/list/status`).
- `build/`, `test/`, `doctor/`, `dev/`: platform build/test, environment checks, and future dev workflows.
- `agents-guidelines.md`: Git workflow and multi‑clone rules; follow it when working in Agent workspaces.
- For future automated tests of this repo, use a top‑level `tests/` directory (see `test/README.md`).

## Agent Templates & Specs

- Templates live in `cfg/templates/` (`commands/`, `hooks/`, `mcp/`, `skills/`).
- When creating or editing a template, read the matching spec in `cfg/templates/spec/agent-*-spec.md` (for example, `agent-skills-spec.md` for skills).
- Make sure `SKILL.md` / command / hook / MCP definitions follow the required frontmatter, layout, and naming rules defined in their spec.

## Build, Test & Development Commands

- General help: `./agent-tool.sh help` or `./agent-tool.sh help <group>`.
- Build/run current project: `./agent-tool.sh build <platform> [--run] [-- <args...>]`.
- Project tests (per target repo): `./agent-tool.sh test <platform> <kind> [-- <args...>]`.
- Environment and CLI checks: `./agent-tool.sh doctor <platform|cli>`.
- Local script hygiene for this repo: `bash -n agent-tool.sh` and optionally `shellcheck agent-tool.sh` and module scripts.

## Coding Style & Naming

- Language: Bash only (`#!/usr/bin/env bash`, `set -euo pipefail` at top of new scripts).
- Indentation: 2 spaces, no hard tabs; keep functions small and composable.
- Functions: `lower_snake_case` (for example, `create_agent_repo`); variables: UPPER_SNAKE for constants, lower_snake for locals.
- Errors: use `agent_error "E_DOMAIN_MEANING" "message"` and follow the `E_<域>_<含义>` pattern described in `README.md`.

## Testing Guidelines

- Prefer Bats or similar for new shell tests, placing them under `tests/` with descriptive filenames (for example, `tests/agent_tool_ws.bats`).
- For lightweight smoke tests, use `./agent-tool.sh doctor cli` plus targeted `bash -n`/`shellcheck` on changed scripts.
- When adding platform behaviour, document expected `agent-tool.sh test ...` usage and add at least one happy‑path test per code path.

## Commit & Pull Request Guidelines

- Commits follow a simple `type: message` format, where `type` is one of `feat|bugfix|refactor|chore|exp` (for example, `feat: add web build helper`).
- Keep commits focused and incremental; prefer smaller, reviewable changes over large mixed refactors.
- Pull requests should include: brief summary, motivation/context, key commands used for validation, and any screenshots or logs when behaviour changes.
- Link related issues or tasks where applicable, and mention any follow‑up work (TODOs) in the PR description.
