# Repository Guidelines

## Project Structure & Module Organization
- This repository is a small Bash-based tool; the main entrypoint is `agent-tool.sh` in the repo root.
- The script is designed to be run from inside any Git repo and creates per-task agent workspaces under `<parent>/<repo-name>-agents/` (for example `~/Projects/my-app-agents/`).
- If you add more utilities, keep them in this directory and prefer small, single-purpose scripts.

## Build, Test, and Development Commands
- `./agent-tool.sh create [--base-branch <branch>] <type> <scope>` – create an agent workspace and branch `agent/<type>/<scope>` based on the chosen baseline.
- `./agent-tool.sh cleanup <type> <scope>` – delete the corresponding agent workspace directory only.
- `./agent-tool.sh list` – list all detected agent workspaces with metadata from `.agent-meta.yml`.
- `./agent-tool.sh status` – show a short `git status` for each agent workspace.
- `bash -n agent-tool.sh` – syntax check the script; run before committing.
- `shellcheck agent-tool.sh` – static analysis (if installed); fix warnings where practical.

## Coding Style & Naming Conventions
- Target Bash (`#!/usr/bin/env bash`) with `set -euo pipefail` at the top of every script.
- Use two-space indentation, long, descriptive English names for functions (e.g., `create_agent_repo`) and UPPER_SNAKE_CASE for variables.
- Keep user-facing messages in Chinese for consistency with the existing script; prefer clear, actionable error text.
- Avoid unnecessary external dependencies; rely on `git` and standard Unix tools only.

## Testing Guidelines
- For changes that affect behavior, exercise the script against a real Git repo and verify `create`, `cleanup`, `list`, and `status` flows.
- If you introduce automated tests, place them under a `tests/` directory as `test_*.sh` and ensure they can be run with a single command (e.g., `./tests/run.sh`).
- Always run `bash -n` and, where available, `shellcheck` before opening a PR.

## Commit & Pull Request Guidelines
- Use Conventional Commit prefixes where possible: `feat:`, `fix:`, `refactor:`, `chore:`, `test:`.
- Keep `type` and `scope` arguments consistent with the script’s contract: `type` in `{feat, bugfix, refactor, chore, exp}`, `scope` in kebab-case (e.g., `user-profile-header`).
- PRs should state motivation, key behavior changes, how you tested (commands used), and any risks or migration notes.

## Agent-Specific Notes
- Preserve the core workflow: default to the current branch as baseline unless `--base-branch` is explicitly provided, and avoid baking project-specific paths into the tool.
