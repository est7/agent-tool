# cfg/

Shared configuration utilities used by `agent-tool.sh`.

Contents:

- `install_symlinks.sh`: creates/refreshes symlinks from client tools (Claude/Codex/Gemini) to `$AGENT_HOME` (default: `~/.agents`), and can optionally auto-enable `1mcp` autostart via `--enable-1mcp-autostart` or `AGENT_TOOL_ENABLE_1MCP_AUTOSTART=true`.
- `aliases.sh` / `aliases.d/`: shared shell aliases and helpers.
- `1mcp/`: scripts to install/start/stop the `1mcp` gateway that serves a single MCP HTTP endpoint; `install` also honors `AGENT_TOOL_ENABLE_1MCP_AUTOSTART=true`.
- `templates/`: template files copied/symlinked into `$AGENT_HOME` (commands, skills, MCP config, rules, etc.).
