# MCP Templates (`cfg/templates/mcp`)

This directory provides MCP configuration templates installed into `$AGENT_HOME/mcp/`.

Files:

- `mcp.json`: `1mcp` server registry (the single source of truth for MCP servers when using the `1mcp` gateway).

Environment variables referenced by `mcp.json`:

- `CONTEXT7_API_KEY`: API key for `context7`.
- `GITHUB_PAT`: GitHub personal access token for the `github` MCP server.
- `GOOGLE_DEVELOPER_KNOWLEDGE_API_KEY`: API key for `google-developer-knowledge`.

After updating the MCP config under `$AGENT_HOME/mcp/mcp.json`, restart the gateway:

```bash
./agent-tool.sh cfg 1mcp restart
```
