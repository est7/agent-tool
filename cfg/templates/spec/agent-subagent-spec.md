# Agent Subagents Spec

Custom subagents are specialized AI assistants that can be invoked to handle specific types of tasks with their own context window and tool permissions.

Official documentation: https://code.claude.com/docs/en/sub-agents

## File Locations

| Scope | Location | Priority |
|-------|----------|----------|
| Project | `.claude/agents/` | Higher |
| User | `~/.claude/agents/` | Lower |

Project subagents take precedence when names conflict.

## File Format

Each subagent is a Markdown file (`.md`) with YAML frontmatter:

```markdown
---
name: my-subagent
description: When and why to use this subagent
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: default
skills: skill1, skill2
---

System prompt content goes here.

This defines the subagent's role, capabilities, and approach.
```

## YAML Frontmatter Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | Yes | string | Unique identifier (lowercase, hyphens) |
| `description` | Yes | string | When this subagent should be invoked |
| `tools` | No | string | Comma-separated tool list. Inherits all if omitted |
| `model` | No | string | `sonnet`, `opus`, `haiku`, or `inherit` |
| `permissionMode` | No | string | `default`, `acceptEdits`, `bypassPermissions`, `plan`, `ignore` |
| `skills` | No | string | Comma-separated skills to auto-load |

## Model Selection

| Value | Description |
|-------|-------------|
| `sonnet` | Claude Sonnet (default) |
| `opus` | Claude Opus |
| `haiku` | Claude Haiku (fast, low-cost) |
| `inherit` | Same model as main conversation |

## Available Tools

Common tools:
- `Read` - Read files
- `Edit` - Edit files
- `Write` - Create files
- `Glob` - Find files by pattern
- `Grep` - Search file contents
- `Bash` - Execute shell commands
- MCP tools: `mcp__server__tool`

## Built-In Subagents

### General-Purpose
- **Model**: Sonnet
- **Tools**: All
- **Use**: Complex multi-step tasks

### Explore
- **Model**: Haiku (fast)
- **Mode**: Read-only
- **Tools**: Glob, Grep, Read, Bash (read-only)
- **Use**: Fast codebase searching

### Plan
- **Model**: Sonnet
- **Tools**: Read, Glob, Grep, Bash
- **Use**: Research in plan mode

## Automatic Invocation

Claude automatically delegates based on:
- Task description matching subagent `description`
- Current context and tool requirements

**Tip**: Include "use PROACTIVELY" or "MUST BE USED" in description for eager invocation.

## Complete Example

```markdown
---
name: code-reviewer
description: Expert code reviewer. Use PROACTIVELY after any code changes to ensure quality and security.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer ensuring high standards.

## When invoked

1. Run `git diff` to see changes
2. Focus on modified files
3. Begin review immediately

## Review checklist

- Code clarity and readability
- Proper naming conventions
- No code duplication
- Error handling
- No exposed secrets
- Input validation
- Test coverage
- Performance considerations

## Output format

Organize feedback by priority:
- **Critical** (must fix)
- **Warning** (should fix)
- **Suggestion** (consider)

Include specific fix examples.
```

## CLI Definition

Define subagents via command line:

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

## Management

Use `/agents` command for interactive management:
- View available subagents
- Create/edit/delete subagents
- Configure tool access

Or manually create files in `.claude/agents/` or `~/.claude/agents/`.

## Version History

- Based on Claude Code documentation as of 2025-12
