# android-refactor

---

name: android-refactor
description: "为 Android 多模块项目提供一致的重构建议。"
tags:
  - android
  - kotlin

entrypoint:
  shell: "./scripts/run.sh"
supports:
  - claude
  - codex

---

# 目标

- 强化 Android 多模块项目中的模块边界一致性。
- 按照你的全局架构规则（见 AGENTS.md）提出重构建议。

# 使用方式

- 在 Claude Code 中：
  - 例如提示："请使用 android-refactor 这个 skill，帮我检查模块划分和依赖。"
- 在 Codex 中：
  - 触发 android-refactor skill，让它给出重构思路和迁移步骤。

