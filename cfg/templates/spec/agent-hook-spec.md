# Agent Hooks Spec

Hooks are user-defined shell commands that execute at various points in Claude Code's lifecycle, providing control over behavior and automation.

Official documentation: https://code.claude.com/docs/en/hooks

## Configuration Locations

| Location | Scope |
|----------|-------|
| `~/.claude/settings.json` | User (all projects) |
| `.claude/settings.json` | Project (shared via git) |
| `.claude/settings.local.json` | Local project (not committed) |

## Hook Events

### Events with Matchers

| Event | Trigger | Common Matchers |
|-------|---------|-----------------|
| `PreToolUse` | Before tool execution | `Write`, `Edit`, `Bash`, `Task`, `*` |
| `PostToolUse` | After tool completes | `Write`, `Edit`, `Bash`, `*` |
| `PermissionRequest` | Permission dialog shown | Same as PreToolUse |
| `Notification` | Notification sent | `permission_prompt`, `idle_prompt` |

### Events without Matchers

| Event | Trigger |
|-------|---------|
| `UserPromptSubmit` | User submits a prompt |
| `Stop` | Main agent finishes |
| `SubagentStop` | Subagent (Task) finishes |
| `PreCompact` | Before compact operation |
| `SessionStart` | Session starts/resumes |
| `SessionEnd` | Session ends |

## Configuration Structure

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/script.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Tool completed'"
          }
        ]
      }
    ]
  }
}
```

## Matcher Syntax

| Pattern | Matches |
|---------|---------|
| `Write` | Exact match (case-sensitive) |
| `Edit\|Write` | Regex OR |
| `Notebook.*` | Regex pattern |
| `*` | All tools |
| `""` or omit | All tools |
| `mcp__server__tool` | MCP tool pattern |

## Hook Types

### Command Hook

```json
{
  "type": "command",
  "command": "/path/to/script.sh",
  "timeout": 60
}
```

### Prompt Hook

For `Stop`, `SubagentStop`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`:

```json
{
  "type": "prompt",
  "prompt": "Evaluate if all tasks are complete: $ARGUMENTS",
  "timeout": 30
}
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `$CLAUDE_PROJECT_DIR` | Absolute path to project root |
| `$CLAUDE_CODE_REMOTE` | `"true"` for web, empty for CLI |
| `$CLAUDE_ENV_FILE` | (SessionStart) File to persist env vars |

## Hook Input (stdin JSON)

Common fields for all hooks:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse"
}
```

### PreToolUse Additional Fields

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "file content"
  },
  "tool_use_id": "toolu_01ABC123"
}
```

### PostToolUse Additional Fields

```json
{
  "tool_name": "Write",
  "tool_input": { ... },
  "tool_response": {
    "filePath": "/path/to/file.txt",
    "success": true
  }
}
```

## Exit Codes

| Code | Meaning | Behavior |
|------|---------|----------|
| 0 | Success | Continue normally |
| 2 | Block | Prevent action, show stderr |
| Other | Error | Non-blocking, show in verbose mode |

## Hook Output (stdout JSON)

### PreToolUse Decision Control

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "explanation",
    "updatedInput": {
      "file_path": "/modified/path"
    }
  }
}
```

### PostToolUse Feedback

```json
{
  "decision": "block",
  "reason": "Explanation for Claude",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Additional info"
  }
}
```

### Stop/SubagentStop Control

```json
{
  "decision": "block",
  "reason": "Continue working on X"
}
```

## Complete Example: Format on Write

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/scripts/format.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**scripts/format.sh:**

```bash
#!/bin/bash
set -e

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.file // empty')

if [[ -z "$file_path" ]]; then
  exit 0
fi

case "$file_path" in
  *.js|*.ts|*.jsx|*.tsx)
    npx prettier --write "$file_path" 2>/dev/null || true
    ;;
  *.py)
    black "$file_path" 2>/dev/null || true
    ;;
esac

exit 0
```

## Version History

- Based on Claude Code documentation as of 2025-12
