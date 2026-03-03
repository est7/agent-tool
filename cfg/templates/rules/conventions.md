# Conventions — Language, Git & Tooling

---

## Summary · Language Rules

* **Explanation, discussion, analysis**: Simplified Chinese.
* **All code, comments, identifiers, commit messages, content in code blocks**: English only — no Chinese characters.
* **Markdown documents**: prose in Chinese, code blocks in English.
* Comments: only when behavior/intent is non-obvious; explain "why" not "what".

---

## Summary · Git & CLI

* **Commit format**: `type: message` (type: `feat|fix|refactor|chore|docs|test`)
* **Branch naming**: `feat/xxx` / `fix/xxx` / `chore/xxx`
* Prefer `gh` CLI for GitHub interactions.
* Do not proactively suggest history-rewriting commands unless user explicitly asks.
* For destructive operations: state risk, provide safer alternative, confirm with user.

---

## Summary · Build Tools

| Platform | Tool |
|----------|------|
| Android | Gradle (Kotlin DSL) |
| iOS | Xcode / SPM |
| Web | pnpm / npm |
| Python | uv / pip |

Use the project's existing formatter configuration.

---

## Summary · Rule Changes

* Modifying core rules requires: stated motivation, maintainer review, backward-compatibility assessment.
* Record significant rule changes in `docs/memo/`.

---

## 5 · Language & Coding Style

* **Explanation, discussion, analysis, summaries**: use **Simplified Chinese**.
* **All code, comments, identifiers (variables, functions, types), commit messages, and content inside Markdown code blocks**: use **English** only — no Chinese characters.
* **Markdown documents**: prose in Chinese, code blocks entirely in English.
* Naming & format:
  * Kotlin: Kotlin style guide
  * Rust: `snake_case`, module/crate naming per community convention
  * Go: exported identifiers use PascalCase, per Go style
  * Other languages: follow their community's mainstream style
* For larger code snippets, assume they've been auto-formatted (e.g., `cargo fmt`, `gofmt`, `black`, etc.).
* Comments: add only when behavior/intent is non-obvious; prefer explaining "why" over restating "what".

---

## 6 · CLI & Git / GitHub Conventions

* For clearly destructive operations (delete files/dirs, rebuild database, `git reset --hard`, `git push --force`, etc.):
  * State the risk before the command.
  * Provide a safer alternative when possible (backup first, `ls`/`git status` first, interactive command, etc.).
  * Usually confirm with the user before issuing the command.
* Git / GitHub:
  * Do not proactively suggest history-rewriting commands (`git rebase`, `git reset --hard`, `git push --force`) unless the user explicitly asks.
  * Prefer `gh` CLI for GitHub interactions.
* **Commit format**: `type: message` where type is `feat|fix|refactor|chore|docs|test`.
* **Branch naming**: `feat/xxx` / `fix/xxx` / `chore/xxx`.

> The confirmation rule above applies only to destructive or hard-to-revert operations. Pure code edits, syntax fixes, formatting, and small structural changes do not need extra confirmation.

---

## 12 · Tools & Environment

### 12.1 Build Tools

| Platform | Tool |
|----------|------|
| Android | Gradle (Kotlin DSL) |
| iOS | Xcode / SPM |
| Web | pnpm / npm |
| Python | uv / pip |

### 12.2 Formatting

* Use the project's existing formatter configuration. Assume code has been auto-formatted before delivery.
