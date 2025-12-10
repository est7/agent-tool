# Agent Rules Spec

Rules are modular Markdown instruction files that live under `.claude/rules/` and `~/.claude/rules/`. They extend CLAUDE.md memories by letting you organize topic-focused instructions and optionally scope them to specific paths in your project.

Official documentation: https://code.claude.com/docs/en/memory

## File Locations

| Scope   | Location                 | Description                                      |
|---------|--------------------------|--------------------------------------------------|
| Project | `./.claude/rules/*.md`   | Topic-specific project rules, shared via git     |
| User    | `~/.claude/rules/*.md`   | Personal rules that apply across all projects    |

Project rules have the same priority as `.claude/CLAUDE.md` for project memory. User-level rules are loaded before project rules, so project rules effectively override user rules when there is conflicting guidance.

Additional memory types (enterprise policy, `CLAUDE.md`, `CLAUDE.local.md`) are described in `agent-memory-spec.md`.

## Directory Layout

A typical project layout using rules:

```text
your-project/
├── .claude/
│   ├── CLAUDE.md           # Main project instructions
│   └── rules/
│       ├── code-style.md   # Code style guidelines
│       ├── testing.md      # Testing conventions
│       └── security.md     # Security requirements
```

All `.md` files under `.claude/rules/` (recursively) are discovered and loaded as project memory.

User-level rules live under:

```text
~/.claude/rules/
├── preferences.md    # Personal coding preferences
└── workflows.md      # Personal workflows and habits
```

## Rule File Format

Rule files are standard Markdown. They may optionally start with YAML frontmatter. Rules without frontmatter apply unconditionally whenever Claude is working in the project.

### Optional YAML Frontmatter

The primary supported field is `paths`, which controls when a rule is active:

- `paths`
  - Type: string
  - One or more glob patterns
  - When present, the rule only applies when Claude is working with files that match any of the patterns

Example of a path-scoped rule:

```markdown
---
paths: src/api/**/*.ts
---

# API Development Rules

- All API endpoints must include input validation
- Use the standard error response format
- Include OpenAPI documentation comments
```

Rules **without** a `paths` field are always loaded and apply to the whole project.

## Glob Patterns

The `paths` field supports standard glob patterns, evaluated relative to the project root:

| Pattern                | Matches                                     |
|------------------------|---------------------------------------------|
| `**/*.ts`              | All TypeScript files in any directory       |
| `src/**/*`             | All files under the `src/` directory        |
| `*.md`                 | Markdown files in the project root          |
| `src/components/*.tsx` | React components in `src/components/`       |

Brace expansion is supported for concise multi-pattern rules:

```markdown
---
paths: src/**/*.{ts,tsx}
---

# TypeScript/React Rules
```

The above is equivalent to matching both `src/**/*.ts` and `src/**/*.tsx`.

You can also combine multiple patterns with commas:

```markdown
---
paths: {src,lib}/**/*.ts, tests/**/*.test.ts
---

# Shared Library and Test Rules
```

## Subdirectories and Symlinks

Rules can be organized into subdirectories to keep related topics together:

```text
.claude/rules/
├── frontend/
│   ├── react.md
│   └── styles.md
├── backend/
│   ├── api.md
│   └── database.md
└── general.md
```

All `.md` files in subdirectories are discovered recursively.

The `.claude/rules/` directory also supports symlinks:

- Symlinked directories under `.claude/rules/` are traversed like normal folders
- Symlinked files are loaded as if they were regular rule files
- Circular symlinks are detected and handled gracefully

This makes it easy to share common rule sets across multiple projects (for example, a shared company security rules file).

## Relationship to CLAUDE.md

Rules are **additive** to CLAUDE.md:

- Use `CLAUDE.md` for high-level project overview, workflows, and general guidance
- Use `.claude/rules/*.md` to break out focused topics (e.g. `testing.md`, `api-design.md`, `security.md`)
- Both are loaded automatically as project memory when Claude Code starts

For a full description of memory types and lookup order, see `agent-memory-spec.md`.

## Best Practices

- **Keep rules focused**: Each file should cover a single topic (e.g. `testing.md`, `database.md`)
- **Use descriptive filenames**: Name files after the domain they control
- **Use `paths` sparingly**: Only scope rules when they truly apply to specific file types or directories
- **Organize with subdirectories**: Group related rules under folders like `frontend/`, `backend/`, `docs/`
- **Share common rules via symlinks**: Store organization-wide rules in a shared location and symlink them into `.claude/rules/`

## Version History

- Based on Claude Code documentation as of 2025-12

