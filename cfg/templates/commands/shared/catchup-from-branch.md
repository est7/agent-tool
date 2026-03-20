---
description: 收集当前分支相对 base branch 的所有已提交变更并读取文件全文
argument-hint: <optional: question or focus area>
allowed-tools: Read, Glob, Grep, Bash(git:*)
---

Collect all committed changes in the current branch compared to the base branch, read each changed file, and present structured context.

## Phase 1 — Detect Base Branch

```bash
git branch --show-current
```

Detect the base branch automatically:
1. If `main` exists → use `main`
2. Else if `master` exists → use `master`
3. Else if `develop` exists → use `develop`
4. Else → use the default remote HEAD (`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`)

## Phase 2 — Collect Committed Changes

```bash
git log --oneline <base>..HEAD
git diff --stat <base>..HEAD
git diff --name-status <base>..HEAD
```

## Phase 3 — Read Changed Files

Use Read to load the full content of every changed file. Skip binary files, lock files, and generated files (e.g. `*.lock`, `*.min.js`, `*.map`).

If the total exceeds 30 files, read only the top 30 by priority:
1. Files changed in the most recent commits
2. Source code over config/docs

## Phase 4 — Output Summary

```
# Catchup (branch) — {current branch}

**Base**: `<base-branch>` | **Commits ahead**: N

## Commit Log

<one-line-per-commit>

## Changed Files

| Status | File | +/- |
|--------|------|-----|
| M      | path/to/file | +10 -5 |

## Summary

- **Scope**: which areas of the codebase were touched
- **Theme**: the overall purpose of these changes
- **Concerns**: anything that looks risky, incomplete, or inconsistent
```

## Phase 5 — Respond to User

- If the user provided `$ARGUMENTS`, use the collected context to answer their question or focus on their area of concern.
- If no arguments, present the summary and offer to dive deeper into any area.
