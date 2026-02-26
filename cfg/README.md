# cfg/

Shared configuration utilities used by `agent-tool.sh`.

Contents:

- `install_symlinks.sh`: creates/refreshes symlinks from client tools (Claude/Codex/Gemini) to `$AGENT_HOME` (default: `~/.agents`).
- `aliases.sh` / `aliases.d/`: shared shell aliases and helpers.
- `1mcp/`: scripts to install/start/stop the `1mcp` gateway that serves a single MCP HTTP endpoint.
- `templates/`: template files copied/symlinked into `$AGENT_HOME` (commands, skills, MCP config, rules, etc.).

