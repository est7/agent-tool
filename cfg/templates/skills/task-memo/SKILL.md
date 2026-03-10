---
name: task-memo
description: Task documentation conventions for structured recording. Use when a task has 7+ implementation steps, or when user asks to record/document/persist findings (e.g., "记录一下", "落地到文档", "整理成方案").
---

# Task Memo Conventions

## When to Create a Memo

Create a memo when **any** of:

* Task has **7 or more** implementation steps.
* User explicitly asks to **record / document / persist**.

## File Convention

* **Path**: `docs/memo/YYYYMMDD-task-name.md`
* **Example**: `20260210-auth-refactor.md`
* **Same-day duplicates**: append sequence number, e.g., `20260210-auth-refactor-2.md`
* **Auto-create directory**: ensure `docs/memo/` exists before first write.

## Principles

* **Real-time updates** — check off steps and append results as they complete.
* **Content over format** — completeness beats template perfection.
* **Must have conclusion** — every memo must include `## Conclusion & Deliverables` with clear results.
* **One topic per document** — separate tasks into separate files.

## Reference

Template: `references/memo-template.md`
