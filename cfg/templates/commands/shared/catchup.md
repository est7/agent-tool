---
description: 收集多模块仓库中所有未提交更改作为上下文
argument-hint: <可选：针对这些变更的问题或关注点>
---

收集当前工作目录下主仓库及所有 git submodules 中的未提交更改，整理为结构化上下文。

## 执行步骤

### 1. 检查主仓库

```bash
git branch --show-current
git status --short
git diff --stat
git diff --cached --stat
```

### 2. 遍历 Submodules

```bash
git submodule status
```

对每个已初始化的 submodule（路径前无 `-` 标记）执行相同的状态收集命令。

### 3. 输出格式

```markdown
# 📋 Catchup 上下文摘要

**工作目录**: `<cwd>`
**仓库数量**: N 个（主仓库 + M 个 submodules）
**变更文件总数**: X 个

---

## 📦 <仓库名称> [<分支名>]

**路径**: `<仓库绝对路径>`

| 状态 | 文件路径 | +/- |
|------|----------|-----|
| M    | `<绝对路径>` | +10 -5 |
| A    | `<绝对路径>` | +50 |
| ??   | `<绝对路径>` | (new) |

---

## ⚠️ 跳过的 Submodules

| Submodule | 原因 |
|-----------|------|
| path/to/sub1 | 未初始化 |
```

状态码: M=修改, A=添加, D=删除, R=重命名, ??=未跟踪

### 4. 后续交互

- 如果用户提供了 `$ARGUMENTS`，使用 Read 工具读取相关文件后分析回答
- 如果没有参数，提示用户可针对变更提问
