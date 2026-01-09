---
name: skill-creator
description: Guide for creating effective skills. Use when users want to create a new skill, update an existing skill, or need help with SKILL.md files, frontmatter fields, skill structure, naming conventions, or skill development best practices for Claude Code.
license: Complete terms in LICENSE.txt
---

# Skill Creator

This skill provides guidance for creating effective skills.

## About Skills

Skills are modular, self-contained packages that extend Claude's capabilities by providing specialized knowledge, workflows, and tools. Think of them as "onboarding guides" for specific domains or tasks.

### How Skills Work

Skills are **model-invoked**: Claude decides which Skills to use based on your request.

1. **Discovery**: At startup, Claude loads only the name and description of each available Skill
2. **Activation**: When your request matches a Skill's description, Claude asks to use the Skill
3. **Execution**: Claude follows the Skill's instructions, loading referenced files or running bundled scripts as needed

### Where Skills Live

| Location   | Path                   | Applies to                        |
|:-----------|:-----------------------|:----------------------------------|
| Enterprise | See managed settings   | All users in your organization    |
| Personal   | `~/.claude/skills/`    | You, across all projects          |
| Project    | `.claude/skills/`      | Anyone working in this repository |
| Plugin     | Bundled with plugins   | Anyone with the plugin installed  |

If two Skills have the same name, the higher row wins.

### Skills vs Other Options

| Use this           | When you want to...                                           | When it runs                     |
|:-------------------|:--------------------------------------------------------------|:---------------------------------|
| **Skills**         | Give Claude specialized knowledge                             | Claude chooses when relevant     |
| **Slash commands** | Create reusable prompts (e.g., `/deploy staging`)             | You type `/command` to run it    |
| **CLAUDE.md**      | Set project-wide instructions                                 | Loaded into every conversation   |
| **Subagents**      | Delegate tasks to a separate context with its own tools       | Claude delegates or you invoke   |
| **Hooks**          | Run scripts on events (e.g., lint on file save)               | Fires on specific tool events    |
| **MCP servers**    | Connect Claude to external tools and data sources             | Claude calls MCP tools as needed |

**Skills vs. subagents**: Skills add knowledge to the current conversation. Subagents run in a separate context. Use Skills for guidance; use subagents when you need isolation.

**Skills vs. MCP**: Skills tell Claude *how* to use tools; MCP *provides* the tools.

## Core Principles

### Concise is Key

The context window is a public good. Skills share it with: system prompt, conversation history, other Skills' metadata, and the user request.

**Default assumption: Claude is already very smart.** Only add context Claude doesn't have. Challenge each piece: "Does Claude need this?" and "Does this justify its token cost?"

### Set Appropriate Degrees of Freedom

Match specificity to task fragility:

- **High freedom** (text instructions): Multiple approaches valid, context-dependent decisions
- **Medium freedom** (pseudocode/scripts with parameters): Preferred pattern exists, some variation acceptable
- **Low freedom** (specific scripts): Fragile operations, consistency critical

Think of Claude as exploring a path: narrow bridge with cliffs needs guardrails (low freedom), open field allows many routes (high freedom).

## Skill Structure

### Folder Layout

```
skill-name/
├── SKILL.md              # Required - overview and navigation
├── references/           # Docs loaded when needed
│   └── guide.md
├── scripts/              # Executable code
│   └── helper.py
└── assets/               # Files used in output (templates, images)
    └── template.docx
```

### SKILL.md File

Every SKILL.md consists of YAML frontmatter followed by Markdown body.

#### Frontmatter Fields

| Field            | Required | Description                                                                                         |
|:-----------------|:---------|:----------------------------------------------------------------------------------------------------|
| `name`           | Yes      | Skill name. Lowercase letters, numbers, hyphens only (max 64 chars)                                 |
| `description`    | Yes      | What the Skill does and when to use it (max 1024 chars). Claude uses this for Skill selection      |
| `allowed-tools`  | No       | Tools Claude can use without permission when active. See [frontmatter-fields.md](references/frontmatter-fields.md) |
| `model`          | No       | Model to use (e.g., `claude-sonnet-4-20250514`). Defaults to conversation's model                   |
| `context`        | No       | Set to `fork` to run in isolated sub-agent context                                                  |
| `agent`          | No       | Agent type when `context: fork` (e.g., `Explore`, `Plan`, `general-purpose`, or custom agent name)  |
| `hooks`          | No       | Hooks scoped to Skill's lifecycle (`PreToolUse`, `PostToolUse`, `Stop`)                             |
| `user-invocable` | No       | Set to `false` to hide from slash command menu                                                      |

For detailed field documentation: [references/frontmatter-fields.md](references/frontmatter-fields.md)

#### Name Validation Rules

- Maximum 64 characters
- Only lowercase letters, numbers, and hyphens
- Cannot contain XML tags
- Cannot contain reserved words: "anthropic", "claude"

#### Description Validation Rules

- Must be non-empty
- Maximum 1024 characters
- Cannot contain XML tags
- **Always write in third person** (good: "Processes Excel files"; avoid: "I can help you")

### Naming Conventions

Use **gerund form** (verb + -ing) for Skill names:

**Good:**
- `processing-pdfs`
- `analyzing-spreadsheets`
- `managing-databases`

**Avoid:**
- Vague names: `helper`, `utils`, `tools`
- Overly generic: `documents`, `data`, `files`
- Reserved words: `anthropic-helper`, `claude-tools`

### Writing Effective Descriptions

The description enables Skill discovery. Include both what the Skill does and when to use it:

```yaml
# Good - specific and includes triggers
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.

# Bad - too vague
description: Helps with documents
```

### What NOT to Include

Do NOT create extraneous files:
- README.md
- INSTALLATION_GUIDE.md
- CHANGELOG.md

The skill should only contain information needed for an AI agent to do the job.

## Progressive Disclosure

Skills use a three-level loading system:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words, keep under 500 lines)
3. **Bundled resources** - As needed by Claude

**Key patterns:**

- **High-level guide with references**: SKILL.md points to detailed files
- **Domain-specific organization**: Organize by domain to avoid loading irrelevant context
- **Conditional details**: Basic content in SKILL.md, advanced content linked

See [references/workflows.md](references/workflows.md) for workflow patterns and [references/output-patterns.md](references/output-patterns.md) for output templates.

**Important:**
- Keep references one level deep from SKILL.md
- For files >100 lines, include a table of contents at top

## Skills and Subagents

### Give a Subagent Access to Skills

Subagents don't inherit Skills automatically. List them in the subagent's `skills` field:

```yaml
# .claude/agents/code-reviewer.md
---
name: code-reviewer
description: Review code for quality and best practices
skills: pr-review, security-check
---
```

**Note**: Built-in agents (Explore, Plan, general-purpose) do not have access to your Skills.

### Run a Skill in a Subagent Context

Use `context: fork` and `agent` to run in isolated context:

```yaml
---
name: code-analysis
description: Analyze code quality and generate detailed reports
context: fork
agent: Explore
---
```

## Distributing Skills

- **Project Skills**: Commit `.claude/skills/` to version control
- **Plugins**: Create `skills/` directory in your plugin
- **Managed**: Deploy organization-wide through managed settings

## Skill Creation Process

1. Understand the skill with concrete examples
2. Plan reusable skill contents (scripts, references, assets)
3. Initialize the skill (run init_skill.py)
4. Edit the skill (implement resources and write SKILL.md)
5. Package the skill (run package_skill.py)
6. Iterate based on real usage

### Step 1: Understanding the Skill

To create an effective skill, understand concrete examples of how it will be used:

- "What functionality should this skill support?"
- "Can you give examples of how this skill would be used?"
- "What would a user say that should trigger this skill?"

### Step 2: Planning Reusable Contents

Analyze each example:

1. Consider how to execute from scratch
2. Identify helpful scripts, references, and assets

Example: For a `pdf-editor` skill handling "Help me rotate this PDF":
- A `scripts/rotate_pdf.py` would be helpful to store in the skill

### Step 3: Initializing the Skill

Run the `init_skill.py` script:

```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

The script creates: skill directory, SKILL.md template, example resource directories.

### Step 4: Editing the Skill

Remember the skill is for another Claude instance. Include non-obvious procedural knowledge and domain-specific details.

**Consult design patterns:**
- **Multi-step processes**: See [references/workflows.md](references/workflows.md)
- **Output formats**: See [references/output-patterns.md](references/output-patterns.md)
- **Frontmatter options**: See [references/frontmatter-fields.md](references/frontmatter-fields.md)

**Test scripts** by running them to ensure no bugs.

### Step 5: Packaging a Skill

```bash
scripts/package_skill.py <path/to/skill-folder>
```

The script validates and packages into a distributable .skill file.

See [references/checklist.md](references/checklist.md) for the pre-release checklist.

### Step 6: Iterate with Claude A/B Pattern

The most effective development involves two Claude instances:

1. **Claude A** (expert): Helps design and refine the Skill
2. **Claude B** (user): Tests the Skill on real tasks

**Workflow:**

1. Complete a task with Claude A using normal prompting. Notice what context you repeatedly provide
2. Ask Claude A to create a Skill capturing the pattern
3. Review for conciseness - remove unnecessary explanations
4. Test with Claude B on similar tasks
5. Observe Claude B's behavior - note struggles or inefficiencies
6. Return to Claude A for improvements based on observations
7. Repeat the observe-refine-test cycle

**Why this works:** Claude A understands agent needs, you provide domain expertise, Claude B reveals gaps through real usage.

## Troubleshooting

See [references/troubleshooting.md](references/troubleshooting.md) for common issues:

- Skill not triggering
- Skill doesn't load
- Skill has errors
- Multiple Skills conflict
- Plugin Skills not appearing
