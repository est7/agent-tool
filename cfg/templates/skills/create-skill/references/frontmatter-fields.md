# Frontmatter Fields Reference

This file documents the current Claude Code skill frontmatter model and the most useful authoring patterns to layer on top of it.

Official semantics come first. The guidance here then adds practical recommendations for writing better skills.

---

## Recommended Defaults

For most skills, start with:

```yaml
---
name: explain-code
description: Explains code with diagrams and analogies. Use when explaining how code works or teaching a codebase.
---
```

Recommended baseline:

- Include `description` whenever possible so Claude can auto-trigger the skill
- Include `name` explicitly for clarity, even though the directory name can be used when omitted
- Keep advanced frontmatter fields out until the workflow actually needs them

---

## Field Reference

| Field | Status | Notes |
|:------|:-------|:------|
| `name` | Optional | If omitted, Claude Code uses the directory name |
| `description` | Recommended | Primary signal for automatic invocation |
| `argument-hint` | Optional | Shown during autocomplete for direct invocation |
| `disable-model-invocation` | Optional | Prevents Claude from auto-invoking the skill |
| `user-invocable` | Optional | Controls visibility in the `/` menu |
| `allowed-tools` | Optional | Tools Claude can use without extra approval while the skill is active |
| `model` | Optional | Overrides the active model for the skill |
| `context` | Optional | `fork` runs the skill in a subagent context |
| `agent` | Optional | Subagent type to use with `context: fork` |
| `hooks` | Optional | Hooks scoped to the skill lifecycle |

---

## Core Rules

### `name`

`name` is optional, but if present it should be a clean identifier.

```yaml
name: processing-pdfs
```

Validation guidance:

- lowercase letters, numbers, and hyphens only
- maximum 64 characters
- do not use spaces or mixed case

Recommendation:

- prefer explicit names so the slash command is obvious in review and diffs
- gerund-style names are still a good convention when they read naturally

### `description`

`description` is recommended because it drives automatic triggering. This field is for Claude, not for humans — Claude scans it to decide whether this Skill can help accomplish the current request. List what the Skill can do and what scenarios it covers, so Claude can quickly match user intent to Skill capabilities.

```yaml
description: Extracts text and tables from PDF files. Use when the user is working with PDFs, forms, or document extraction.
```

Recommendation:

- list capabilities and applicable scenarios broadly
- write from the skill's point of view, not in first person
- bias slightly toward under-explained user intent rather than implementation details
- make descriptions slightly "pushy" — Claude tends to under-trigger
- keep within 1024 characters

### `argument-hint`

Shown in autocomplete to explain the expected arguments.

```yaml
argument-hint: "[filename] [format]"
```

Use when the skill is mainly a direct `/skill-name ...` workflow.

### `disable-model-invocation`

Blocks Claude from invoking the skill automatically.

```yaml
disable-model-invocation: true
```

Use for side-effectful workflows like deploy, release, or commit helpers.

Claude will not see this skill's description in context, so it cannot auto-trigger it.
Only manual invocation via `/skill-name` will activate the skill.
Use for side-effectful operations (deploy, send messages, write to database) where you do not want Claude to decide on its own that "the time is right" to execute.

### `user-invocable`

Controls whether the skill appears in the `/` menu.

```yaml
user-invocable: false
```

Use for background knowledge or helper skills that users should not run directly.

Claude can still see the description and will automatically load and use the skill in relevant conversations.
Typing `/skill-name` manually has no effect (or is ignored).
Use for background knowledge skills (e.g., "legacy system context") — reference material for Claude to read, not an action you would trigger directly.

### `allowed-tools`

Can be a comma-separated string or YAML list.

```yaml
allowed-tools: Read, Grep, Glob
```

```yaml
allowed-tools:
  - Read
  - Grep
  - Glob
```

Use when the skill needs a predictable tool boundary.

### `model`

Overrides the current model for this skill.

```yaml
model: claude-sonnet-4-6
```

Use sparingly. Most skills should inherit the session model.

### `context`

Set `context: fork` to run the skill in an isolated subagent context.

```yaml
context: fork
```

Use when:

- the skill produces heavy intermediate output
- the main context only needs the final result
- the skill behaves more like a delegated task than inline reference material

### `agent`

Selects the subagent environment when using `context: fork`.

```yaml
context: fork
agent: Explore
```

Typical values:

- `Explore`
- `Plan`
- `general-purpose`
- a custom agent name from `.claude/agents/`

### `hooks`

Hooks let the skill attach lifecycle actions.

```yaml
hooks:
  Stop:
    - type: command
      command: "./scripts/report.sh"
```

Use when the skill needs validation, logging, or post-run summaries around tool execution.

---

## Invocation Control Patterns

### Manual-only workflow

```yaml
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true
---
```

### Hidden background knowledge

```yaml
---
name: legacy-system-context
description: Explains the legacy billing system when relevant.
user-invocable: false
---
```

### Forked task executor

```yaml
---
name: deep-research
description: Research a topic thoroughly and summarize findings.
context: fork
agent: Explore
---
```

---

## Argument and Context Substitutions

Skills support runtime substitutions in the markdown body:

- `$ARGUMENTS`
- `$ARGUMENTS[N]`
- `$N`
- `${CLAUDE_SESSION_ID}`
- `${CLAUDE_SKILL_DIR}`
- `${CLAUDE_PLUGIN_ROOT}` — absolute path to the plugin's installation directory; use to reference scripts, binaries, and config files bundled with the plugin. **Changes on plugin update** — do not write persistent data here.
- `${CLAUDE_PLUGIN_DATA}` — persistent directory for plugin state that survives updates (e.g., `node_modules`, virtualenvs, caches, generated files). Created automatically on first reference.

Example:

```yaml
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix issue $ARGUMENTS following the project coding standards.
```

Use `${CLAUDE_SKILL_DIR}` whenever a bundled script or reference file must be resolved reliably from the current shell context.

Use `${CLAUDE_PLUGIN_ROOT}` for the same purpose when the skill is distributed as part of a plugin. Use `${CLAUDE_PLUGIN_DATA}` for any state that must persist across plugin version upgrades.

---

## Dynamic Context Injection

The `!`command`` syntax runs before the skill content is sent to Claude.

Example:

```yaml
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
```

Use this when live external context is required, not for ordinary static instructions.

---

## Practical Authoring Guidance

These are recommendations, not hard schema rules:

- Keep `SKILL.md` concise and move deep material into references
- Prefer distinctive descriptions over generic ones
- Use examples when the output shape matters
- Use scripts when the same deterministic work would otherwise be reinvented each run
- Treat `context: fork` as a task-execution tool, not as a default

---

## Legacy Compatibility

This repo's validator still accepts `license` and `metadata` for compatibility with existing/open-standard skill layouts already present in the ecosystem.

Do not introduce new project-specific frontmatter fields. If you need extra structure, put it in:

- the markdown body
- `references/`
- `metadata`
