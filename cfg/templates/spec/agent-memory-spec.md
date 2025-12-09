# Agent Memory Spec

CLAUDE.md files provide persistent context that loads automatically when Claude Code starts, containing project-specific instructions, conventions, and workflows.

Official documentation: https://code.claude.com/docs/en/memory

## File Locations (Priority High → Low)

| Priority | Type | Location | Scope |
|----------|------|----------|-------|
| 1 | Enterprise | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) | Organization |
| 2 | Project | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team (via git) |
| 3 | User | `~/.claude/CLAUDE.md` | Personal (all projects) |
| 4 | Local | `./CLAUDE.local.md` | Personal (current project, gitignored) |

Higher priority files take precedence. Settings are merged.

## Discovery & Loading

Claude Code recursively searches for memory files:

```
cwd/CLAUDE.md           ← Loaded
cwd/CLAUDE.local.md     ← Loaded (gitignored)
parent/CLAUDE.md        ← Loaded
grandparent/CLAUDE.md   ← Loaded
...up to root

cwd/subdir/CLAUDE.md    ← Lazy-loaded when accessing subdir
```

## File Format

No required format. Plain Markdown recommended:

```markdown
# Project: My App

## Build Commands
- `npm run build` - Production build
- `npm run dev` - Development server
- `npm test` - Run tests

## Code Style
- Use TypeScript strict mode
- 2-space indentation
- Prefer async/await over callbacks

## Architecture
- React frontend in `src/`
- Express API in `api/`
- Shared types in `shared/`

## Important Notes
- Always run `npm run lint` before committing
- Database migrations in `db/migrations/`
```

## Import Syntax

Import other files using `@path`:

```markdown
# Project Overview
@README.md

# Git Workflow
@docs/git-instructions.md

# Personal Preferences
@~/.claude/my-coding-style.md
```

### Import Rules

| Rule | Description |
|------|-------------|
| Paths | Relative and absolute supported |
| Max depth | 5 recursive hops |
| Ignored | Inside code blocks and inline code |

## Commands

### `/init` - Create Memory File

```
> /init
```

Creates `./CLAUDE.md` with template structure.

### `/memory` - Edit Memory

```
> /memory
```

Opens memory file in system editor.

### `#` - Quick Add

Start input with `#` to add memory:

```
> # Always use descriptive variable names
```

Prompts to select which memory file to store.

## Best Practices

### Be Specific

```markdown
# Good
- Use 2-space indentation
- Prefer `const` over `let`
- Use early returns

# Bad
- Format code properly
- Write clean code
```

### Use Structure

```markdown
# Build

- `npm run build` - Production
- `npm run dev` - Development

# Testing

- `npm test` - All tests
- `npm test -- --watch` - Watch mode
```

### Keep Concise

Memory is part of system prompt. Too much detail:
- Wastes tokens
- Can confuse the LLM
- Slows down responses

### Common Content

- Build/test/lint commands
- Code style preferences
- Naming conventions
- Architecture overview
- Important file locations
- Team workflows
- Security policies

## Example CLAUDE.md

```markdown
# My Project

## Quick Commands
- `npm run dev` - Start dev server (port 3000)
- `npm test` - Run Jest tests
- `npm run lint` - ESLint + Prettier

## Code Style
- TypeScript strict mode
- React functional components with hooks
- Use `@/` alias for src imports

## Architecture
- `src/components/` - React components
- `src/hooks/` - Custom hooks
- `src/api/` - API client
- `src/types/` - TypeScript types

## Conventions
- Component files: PascalCase (`Button.tsx`)
- Utility files: camelCase (`formatDate.ts`)
- Test files: `*.test.ts` next to source

## Notes
- Run `npm run db:migrate` after pulling
- Environment vars in `.env.local` (not committed)
```

## Version History

- Based on Claude Code documentation as of 2025-12
