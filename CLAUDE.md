# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`agent-tool` is a Bash CLI for managing Agent workspaces in Git repositories and providing unified build/test/run commands for Android, iOS, and Web platforms. It also manages configuration templates (slash commands, skills, hooks, MCP configs) that sync across Claude Code, Codex CLI, and Gemini CLI.

## Common Commands

```bash
# Syntax check (run after any script change)
bash -n agent-tool.sh

# Static analysis (optional)
shellcheck agent-tool.sh

# CLI self-test
./agent-tool.sh doctor cli

# Initialize unified config directory (first time setup)
./agent-tool.sh cfg init

# Refresh symlinks after adding new commands/skills/hooks
./agent-tool.sh cfg refresh

# Workspace commands
./agent-tool.sh ws create feat my-feature
./agent-tool.sh ws list
./agent-tool.sh ws status
./agent-tool.sh ws cleanup --force feat my-feature

# Build/run (requires being in a project with .agent-build.yml or explicit args)
./agent-tool.sh build android com.myapp Debug
./agent-tool.sh run web
./agent-tool.sh test android unit
```

## Architecture

**Entry Point**: `agent-tool.sh` - main CLI that parses commands and dispatches to modules.

**Module Structure** (each has `index.sh` as entry):
- `cfg/` - Config management: `install_symlinks.sh` (syncs templates to `~/.agents/`), `project_mcp_setup.sh` (generates project-level MCP configs)
- `ws/` - Workspace lifecycle: `workspace.sh` contains `create_agent_repo`, `cleanup_agent_repo`, `list_agents`, `status_agents`
- `build/` - Platform builds: `platforms.sh` with `build_android_project`, `build_ios_project`, `build_web_project`
- `test/` - Test runner entry point
- `doctor/` - Environment checks: `platforms.sh` for platform checks, `cfg_doctor.sh` for config validation

**Config Templates** (`cfg/templates/`):
- `commands/shared/` - Slash commands (`.md` files with YAML frontmatter)
- `skills/` - Reusable skills (directories with `SKILL.md`)
- `output-styles/` - Agent personas
- `spec/` - Specifications for templates

**Config Flow**: Templates in `cfg/templates/` → copied to `~/.agents/` → symlinked to `~/.claude/`, `~/.codex/`, `~/.gemini/`

## Coding Conventions

- Bash only: `#!/usr/bin/env bash` with `set -euo pipefail`
- Functions: `lower_snake_case`; Constants: `UPPER_SNAKE`; Locals: `lower_snake`
- Indentation: 2 spaces
- Errors: Use `agent_error "E_DOMAIN_MEANING" "message"` pattern (defined in `cfg/index.sh`)

## Template Specifications

**IMPORTANT**: When creating or editing any templates, you MUST read and follow the corresponding spec file in `cfg/templates/spec/`:

| Spec File | When to Read |
|-----------|--------------|
| `agent-command-spec.md` | Creating/editing slash commands in `commands/` |
| `agent-skills-spec.md` | Creating/editing skills in `skills/` |
| `agent-hook-spec.md` | Creating/editing hooks |
| `agent-mcp-spec.md` | Creating/editing MCP server configs |
| `agent-subagent-spec.md` | Creating/editing custom subagents |
| `agent-settings-spec.md` | Creating/editing settings.json |
| `agent-memory-spec.md` | Creating/editing CLAUDE.md memory files |

Each spec contains:
- Official file locations and naming conventions
- Required YAML frontmatter fields
- Supported configuration options
- Complete examples

## Template Editing Workflow

1. **Read the spec first**: `cfg/templates/spec/agent-*-spec.md`
2. Create/edit template following the spec format
3. Run `./agent-tool.sh cfg refresh` to sync to `~/.agents/`
