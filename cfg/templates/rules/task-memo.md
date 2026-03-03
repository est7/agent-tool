# Core — Task Memo (落盘)

---

## 11 · Task Memo

When a task needs structured documentation, record it in `docs/memo/` rather than conversation only.

### File Convention

* **Path**: `docs/memo/YYYYMMDD-task-name.md`
* **Example**: `20260210-auth-refactor.md`
* **Same-day duplicates**: append sequence number, e.g., `20260210-auth-refactor-2.md`
* **Auto-create directory**: ensure `docs/memo/` exists before first write.

### Trigger Conditions

Create a memo when **any** of:

* Task has **7 or more** implementation steps.
* User explicitly asks to **record / document / persist** (e.g., "记录一下", "落地到文档", "整理成方案").

### Usage Principles

* **Real-time updates** — check off steps and append results as they complete.
* **Content over format** — completeness beats template perfection.
* **Must have conclusion** — every memo must include `## Conclusion & Deliverables` with clear deliverable results.
* **One topic per document** — separate tasks into separate files.

Reference template: [`cfg/templates/spec/memo-template.md`](../spec/memo-template.md).

---

