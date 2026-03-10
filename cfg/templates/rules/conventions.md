# Conventions — Language, Git & Tooling

---

## Summary · Language Rules

* **Explanation, discussion, analysis**: Simplified Chinese.
* **All code, comments, identifiers, commit messages, content in code blocks**: English only — no Chinese characters.
* **Markdown documents**: prose in Chinese, code blocks in English.
* Naming & format: follow each language's mainstream style guide.
* Comments: only when intent/constraints are non-obvious; explain **why** not **what**; avoid change-tracking comments; prefer docstrings for public APIs.

---

## Summary · Git & CLI

* **Commit format**: follow Conventional Commits.
* **Branch naming**: `feat/xxx` / `fix/xxx` / `chore/xxx`
* Prefer `gh` CLI for GitHub interactions.
* Do not proactively suggest history-rewriting commands unless user explicitly asks.
* For destructive operations: state risk, provide safer alternative, confirm with user.
* Confirmation is only for destructive/hard-to-revert ops; pure code edits/formatting/small refactors do not need extra confirmation.

---

## Summary · Build Tools

| Platform | Tool |
|----------|------|
| Android | Gradle (Kotlin DSL) |
| iOS | Xcode / SPM |
| Web | pnpm / npm |
| Python | uv / pip |

Use the project's existing formatter configuration; run the formatter/linter before delivery when available.

---

## Summary · Rule Changes

* Modifying core rules requires: stated motivation, maintainer review, backward-compatibility assessment.
* Record significant rule, design, and process changes in the appropriate `docs/` category; use `docs/postmortem/` for failure-analysis documents.
