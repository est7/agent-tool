# Agent Slash Commands Spec

Slash commands are Markdown files that define reusable prompts. When invoked, the file content becomes part of the conversation context.

Official documentation: https://code.claude.com/docs/en/slash-commands

## File Locations

| Scope | Location | Display in `/help` |
|-------|----------|-------------------|
| Project | `.claude/commands/` | `(project)` |
| User | `~/.claude/commands/` | `(user)` |

Project commands take precedence over user commands with the same name.

## File Format

Commands are Markdown files (`.md`). The filename (without extension) becomes the command name.

```
.claude/commands/
├── review.md        → /review
├── commit.md        → /commit
└── frontend/
    └── component.md → /component (project:frontend)
```

## YAML Frontmatter

Optional frontmatter at the start of the file:

```yaml
---
allowed-tools: Bash(git add:*), Bash(git status:*)
argument-hint: [message]
description: Brief description of the command
model: claude-3-5-haiku-20241022
disable-model-invocation: true
---
```

### Frontmatter Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `allowed-tools` | string | Inherits | Comma-separated list of pre-approved tools |
| `argument-hint` | string | None | Shows expected arguments in autocomplete |
| `description` | string | First line | Brief command description |
| `model` | string | Inherits | Specific model for this command |
| `disable-model-invocation` | boolean | `false` | Prevent SlashCommand tool from calling this |

## Parameter Placeholders

### All Arguments: `$ARGUMENTS`

```markdown
Create a git commit with message: $ARGUMENTS
```

Usage: `/commit fix login bug` → `$ARGUMENTS = "fix login bug"`

### Positional Arguments: `$1`, `$2`, `$3`...

```markdown
---
argument-hint: [pr-number] [priority] [assignee]
---

Review PR #$1 with priority $2 and assign to $3.
```

Usage: `/review-pr 456 high alice` → `$1="456"`, `$2="high"`, `$3="alice"`

## Bash Command Execution

Use `!` prefix to execute bash commands. Output is included in context.

**Requires** `allowed-tools` in frontmatter:

```markdown
---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*)
---

Current status: !`git status`
Recent commits: !`git log --oneline -5`
```

## File References

Use `@` prefix to include file contents:

```markdown
Review the implementation in @src/utils/helpers.js
```

## Directory Organization

Subdirectories create namespaces shown in description:

```
.claude/commands/
├── frontend/
│   └── build.md    → /build (project:frontend)
└── backend/
    └── build.md    → /build (project:backend)
```

## Complete Example

```markdown
---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git log:*)
argument-hint: [commit message]
description: Create a git commit with context
---

## Context

- Current status: !`git status --short`
- Staged diff: !`git diff --cached`
- Recent commits: !`git log --oneline -5`

## Task

Create a git commit with message: $ARGUMENTS

Follow conventional commit format. If no message provided, generate one based on the changes.
```

## Version History

- Based on Claude Code documentation as of 2025-12
