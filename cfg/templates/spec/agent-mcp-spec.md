# Agent MCP Spec

MCP (Model Context Protocol) servers extend Claude Code with external tools and data sources.

Official documentation: https://code.claude.com/docs/en/mcp

## Configuration Scopes

| Scope | Location | Visibility |
|-------|----------|------------|
| Local | `~/.claude.json` | Private, current project |
| Project | `.mcp.json` (repo root) | Shared via git |
| User | `~/.claude.json` | Private, all projects |

## .mcp.json File Format

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio|http|sse",
      "command": "/path/to/executable",
      "args": ["arg1", "arg2"],
      "env": {
        "API_KEY": "value"
      }
    }
  }
}
```

## Server Types

### Stdio Server (Local Process)

```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "NODE_ENV": "production"
      }
    }
  }
}
```

### HTTP Server (Remote)

```json
{
  "mcpServers": {
    "my-api": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      }
    }
  }
}
```

### SSE Server (Deprecated)

```json
{
  "mcpServers": {
    "my-sse": {
      "type": "sse",
      "url": "https://api.example.com/sse"
    }
  }
}
```

## Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `stdio`, `http`, or `sse` |
| `command` | string | stdio | Path to executable |
| `args` | array | No | Command-line arguments |
| `env` | object | No | Environment variables |
| `url` | string | http/sse | Server endpoint URL |
| `headers` | object | No | HTTP headers (auth, etc.) |

## Environment Variable Expansion

```json
{
  "mcpServers": {
    "example": {
      "type": "http",
      "url": "${API_BASE_URL:-https://default.com}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      },
      "env": {
        "DEBUG": "${DEBUG:-false}"
      }
    }
  }
}
```

- `${VAR}` - Expand variable
- `${VAR:-default}` - Use default if unset

## CLI Commands

### Add Servers

```bash
# HTTP server
claude mcp add --transport http myserver https://api.example.com/mcp

# Stdio server
claude mcp add --transport stdio myserver -- npx -y @some/package

# With environment variables
claude mcp add --transport stdio myserver --env API_KEY=xxx -- npx server

# With scope
claude mcp add --transport http myserver --scope project https://api.example.com
claude mcp add --transport http myserver --scope user https://api.example.com

# From JSON
claude mcp add-json myserver '{"type":"http","url":"https://api.example.com/mcp"}'
```

### Manage Servers

```bash
# List all servers
claude mcp list

# Get server details
claude mcp get <server-name>

# Remove server
claude mcp remove <server-name>

# Check status (in Claude Code)
/mcp

# Import from Claude Desktop
claude mcp add-from-claude-desktop
```

## Common Server Examples

### Sequential Thinking

任务分解、方案评估、风险识别。

```json
{
  "mcpServers": {
    "sequential-thinking": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

### Exa

高质量代码上下文搜索、技术文档检索。使用 mcp-remote 连接。

```json
{
  "mcpServers": {
    "exa-mcp": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.exa.ai/mcp"]
    }
  }
}
```

### Memory

跨会话持久化知识图谱，记录用户偏好和项目约定。

```json
{
  "mcpServers": {
    "memory": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

### Async MCP (跨 Agent 协作)

允许不同 Agent CLI 之间互相调用。

```json
{
  "mcpServers": {
    "claudecode-mcp-async": {
      "command": "uvx",
      "args": ["claudecode-mcp-async"],
      "env": {}
    },
    "codex-mcp-async": {
      "command": "uvx",
      "args": ["codex-mcp-async"],
      "env": {}
    },
    "gemini-cli-mcp-async": {
      "command": "uvx",
      "args": ["gemini-cli-mcp-async"],
      "env": {}
    }
  }
}
```

### Puppeteer

```json
{
  "mcpServers": {
    "puppeteer": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-puppeteer"]
    }
  }
}
```

### Custom Python Server

```json
{
  "mcpServers": {
    "my-python-server": {
      "type": "stdio",
      "command": "uvx",
      "args": ["my-mcp-package"],
      "env": {
        "PYTHONUNBUFFERED": "1"
      }
    }
  }
}
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MCP_TIMEOUT` | Server startup timeout (ms) |
| `MAX_MCP_OUTPUT_TOKENS` | Max output tokens (default: 25000) |

```bash
MCP_TIMEOUT=10000 claude
```

## Debugging

```bash
# Launch with MCP debug mode
claude --mcp-debug
```

## Project vs User Configuration

**Project** (`.mcp.json`):
- Shared with team
- Requires approval on first use
- Good for: project-specific tools, shared services

**User** (`~/.claude.json`):
- Personal only
- No approval needed
- Good for: personal API keys, experimental servers

## Version History

- Based on Claude Code documentation as of 2025-12
