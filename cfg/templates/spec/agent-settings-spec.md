# Agent Settings Spec

The `settings.json` file configures Claude Code behavior including permissions, hooks, environment variables, and more.

Official documentation: https://code.claude.com/docs/en/settings

## File Locations (Priority High → Low)

| Priority | Location | Scope |
|----------|----------|-------|
| 1 | Enterprise managed policy | System-wide |
| 2 | Command line arguments | Session |
| 3 | `.claude/settings.local.json` | Local project (not committed) |
| 4 | `.claude/settings.json` | Project (shared via git) |
| 5 | `~/.claude/settings.json` | User (all projects) |

Settings are **merged**, with higher priority overriding lower.

## Basic Structure

```json
{
  "permissions": {
    "allow": [],
    "deny": [],
    "ask": []
  },
  "env": {},
  "hooks": {},
  "model": "",
  "statusLine": {}
}
```

## All Supported Fields

| Field | Type | Description |
|-------|------|-------------|
| `permissions` | object | Tool access control (allow/deny/ask) |
| `env` | object | Environment variables |
| `hooks` | object | Pre/post tool execution hooks |
| `disableAllHooks` | boolean | Disable all hooks |
| `model` | string | Override default model |
| `statusLine` | object | Custom status line |
| `outputStyle` | string | Output formatting style |
| `apiKeyHelper` | string | Script to generate auth |
| `cleanupPeriodDays` | number | Days before deleting inactive sessions |
| `includeCoAuthoredBy` | boolean | Include co-authored-by in commits |
| `sandbox` | object | Sandbox configuration |

## Permissions Configuration

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run:*)",
      "Bash(git status:*)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl:*)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ],
    "ask": [
      "Bash(git push:*)",
      "Edit(./config/**)"
    ],
    "additionalDirectories": [
      "../docs/",
      "../../shared/"
    ],
    "defaultMode": "acceptEdits"
  }
}
```

### Permission Rule Syntax

| Tool | Pattern | Example |
|------|---------|---------|
| Bash | `Bash(command:*)` | `Bash(npm run:*)` matches `npm run test` |
| Read | `Read(path)` | `Read(./.env*)` blocks env files |
| Edit | `Edit(path)` | `Edit(./config/**)` |
| Write | `Write(path)` | `Write(./src/**)` |
| WebFetch | `WebFetch` | Allow/deny web requests |

**Note**: Bash uses prefix matching, not regex.

### Permission Modes

| Mode | Description |
|------|-------------|
| `default` | Ask for confirmation |
| `acceptEdits` | Auto-accept file edits |
| `bypassPermissions` | Skip all permission checks |
| `plan` | Plan mode |

## Environment Variables

```json
{
  "env": {
    "ANTHROPIC_MODEL": "claude-sonnet-4-5-20250929",
    "BASH_DEFAULT_TIMEOUT_MS": "60000",
    "BASH_MAX_OUTPUT_LENGTH": "100000",
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "8000",
    "MAX_THINKING_TOKENS": "10000",
    "DISABLE_TELEMETRY": "1"
  }
}
```

### Key Environment Variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_MODEL` | Model selection |
| `BASH_DEFAULT_TIMEOUT_MS` | Bash command timeout |
| `BASH_MAX_OUTPUT_LENGTH` | Max bash output chars |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Max response tokens |
| `MAX_THINKING_TOKENS` | Extended thinking budget |
| `DISABLE_TELEMETRY` | Disable telemetry |
| `DISABLE_AUTOUPDATER` | Disable auto-update |

## Sandbox Configuration

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["docker", "git"],
    "allowUnsandboxedCommands": true,
    "network": {
      "allowUnixSockets": [
        "~/.ssh/agent-socket",
        "/var/run/docker.sock"
      ],
      "allowLocalBinding": true
    }
  }
}
```

## Status Line Configuration

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## MCP Server Control

```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["memory", "github"],
  "disabledMcpjsonServers": ["filesystem"]
}
```

## Complete Example

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Bash(curl:*)",
      "Bash(rm -rf:*)"
    ],
    "ask": [
      "Bash(git push:*)",
      "Bash(git commit:*)"
    ],
    "additionalDirectories": ["../shared-libs/"]
  },
  "env": {
    "BASH_DEFAULT_TIMEOUT_MS": "60000",
    "DISABLE_TELEMETRY": "1"
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write $FILE"
          }
        ]
      }
    ]
  },
  "model": "claude-sonnet-4-5-20250929",
  "sandbox": {
    "enabled": true,
    "excludedCommands": ["docker"]
  }
}
```

## Best Practices

1. **Protect sensitive files**: Always deny access to `.env`, secrets, credentials
2. **Use prefix matching**: `Bash(npm:*)` not regex patterns
3. **Project vs User**: Put team settings in `.claude/settings.json`, personal in `~/.claude/settings.json`
4. **Local overrides**: Use `.claude/settings.local.json` for machine-specific settings (add to `.gitignore`)

## Version History

- Based on Claude Code documentation as of 2025-12
