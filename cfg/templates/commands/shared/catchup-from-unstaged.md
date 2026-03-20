---
description: 收集未提交更改（含 submodule）作为结构化上下文
argument-hint: <optional: question or focus area>
allowed-tools: Read, Glob, Grep, Bash(git:*)
---

Collect all uncommitted changes (working tree + staged) across the main repo and submodules, and present structured context.

## Phase 1 — Check Main Repo

```bash
git branch --show-current
git status --short
git diff --stat
git diff --cached --stat
git stash list 2>/dev/null
```

## Phase 2 — Check Submodules

```bash
git submodule status 2>/dev/null
```

For each initialized submodule (no `-` prefix), run the same status and diff commands.

## Phase 3 — Read Changed Files

Use Read to load the full content of every uncommitted changed file. Skip binary files, lock files, and generated files.

If the total exceeds 30 files, read only the top 30 by priority:
1. Staged files (about to be committed)
2. Modified tracked files
3. Untracked files

## Phase 4 — Output Summary

```
# Catchup (unstaged) — {current branch}

**Working directory**: `<cwd>`
**Repos**: N (main + M submodules)
**Changed files**: X

## Main Repo [{branch}]

| Status | File | +/- |
|--------|------|-----|
| M      | path/to/file | +10 -5 |
| A      | path/to/file | +50 |
| ??     | path/to/file | (new) |

## Submodule: <name> [{branch}]

| Status | File | +/- |
|--------|------|-----|
| M      | path/to/file | +3 -1 |

## Skipped Submodules (if any)

| Submodule | Reason |
|-----------|--------|
| path/to/sub | not initialized |

## Summary

- **Scope**: which areas of the codebase were touched
- **Theme**: the overall purpose of these changes
- **Concerns**: anything that looks risky, incomplete, or inconsistent
```

Status codes: M=modified, A=added, D=deleted, R=renamed, ??=untracked

## Phase 5 — Respond to User

- If the user provided `$ARGUMENTS`, use the collected context to answer their question or focus on their area of concern.
- If no arguments, present the summary and offer to dive deeper into any area.
