# Conventions — Language, Git & Tooling

---

## 1 · Language Rules

* **Explanation, discussion, analysis**: Simplified Chinese.
* **All code, comments, identifiers, commit messages, content in code blocks**: English only — no Chinese characters.
* **Markdown documents**: prose in Chinese, code blocks in English.
* Comments: only when behavior/intent is non-obvious; explain "why" not "what".

---

## 2 · Git & CLI

* **Commit format**: `type: message` (type: `feat|fix|refactor|chore|docs|test`)
* **Branch naming**: `feat/xxx` / `fix/xxx` / `chore/xxx`
* Prefer `gh` CLI for GitHub interactions.
* Do not proactively suggest history-rewriting commands unless user explicitly asks.
* For destructive operations: state risk, provide safer alternative, confirm with user.

---

## 3 · Build Tools

| Platform | Tool |
|----------|------|
| Android | Gradle (Kotlin DSL) |
| iOS | Xcode / SPM |
| Web | pnpm / npm |
| Python | uv / pip |

Use the project's existing formatter configuration.

---

## 4 · Rule Changes

* Modifying core rules requires: stated motivation, maintainer review, backward-compatibility assessment.
* Record significant rule changes in `docs/memo/`.
