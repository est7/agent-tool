# Frontmatter Fields Reference

All SKILL.md files must start with YAML frontmatter. This reference documents all available fields.

---

## When to Use Optional Fields (Decision Guide)

**大多数 Skills 只需要 `name` + `description`**。可选字段用于特定场景：

| 字段 | 何时考虑使用 | 优先级 |
|:-----|:------------|:-------|
| `context: fork` | 主上下文只需结果，不需中间过程（避免上下文污染） | **高 - 最重要的优化** |
| `agent` | fork 模式下需要专精化 agent 执行特定类型任务 | 中 - 建立 subagent-skillset 架构 |
| `hooks` | 记录中间变更、执行验证、结果回传主上下文 | 中 - 配合 fork 实现完整工作流 |
| `allowed-tools` | 需要限制工具访问（安全敏感/只读操作） | 中 - 安全相关时必用 |
| `model` | 任务需要特定模型能力（如 Opus 的深度推理） | 低 - 极少需要 |
| `user-invocable` | 只想自动触发，不想出现在 `/` 菜单 | 低 - helper Skills |

### 核心概念：上下文分叉 (context: fork)

**问题**：以前 Skills 是 inline（内联）运行的，执行过程中的中间步骤会**污染主上下文**。

**解决方案**：`context: fork` 让 Skill 在**独立的子 Agent 上下文**中运行：
- 主上下文只获取**最终结果**，保持整洁
- 子上下文处理所有中间过程
- 特别适合产生大量中间输出的任务（如 dev browser skill、代码分析、文件处理）

### Subagent-Skillset 架构模式

`agent` 字段 + `hooks` 可以建立**专精化分工**：

```
主上下文
    │
    ├─ Skill A (context: fork, agent: Explore)
    │   └─ 专门做代码探索，hooks 记录发现
    │
    ├─ Skill B (context: fork, agent: Plan)
    │   └─ 专门做架构规划，hooks 记录决策
    │
    └─ Skill C (context: fork, agent: custom-reviewer)
        └─ 专门做代码审查，hooks 记录问题
```

**hooks 的关键作用**：
- `PostToolUse`: 记录中间变更过程
- `Stop`: Skill 结束时，引导主上下文读取变更结果

### 决策流程

```
开始创建 Skill
    │
    ├─ 只需要 name + description 吗？
    │   └─ 是 → 完成（简单 Skills）
    │
    ├─ 主上下文需要看到中间过程吗？
    │   └─ 否，只需要结果 → 添加 context: fork
    │       │
    │       ├─ 需要专精化执行？
    │       │   ├─ 代码探索 → agent: Explore
    │       │   ├─ 架构规划 → agent: Plan
    │       │   ├─ 自定义专精 → agent: your-custom-agent
    │       │   └─ 通用任务 → 不设置（默认 general-purpose）
    │       │
    │       └─ 需要将变更记录回传主上下文？
    │           └─ 是 → 添加 hooks (PostToolUse/Stop)
    │
    ├─ 需要限制 Claude 的工具访问？
    │   └─ 是 → 添加 allowed-tools
    │
    └─ 不想让用户手动调用此 Skill？
        └─ 是 → 添加 user-invocable: false
```

### 常见组合模式

**模式 1: 结果导向型 Skill（最常用）**

主上下文只需要结果，不关心中间过程：

```yaml
name: analyzing-codebase
description: Analyzes codebase structure and generates report...
context: fork
agent: Explore
```

**模式 2: 带变更记录的 fork Skill**

执行后将变更信息回传主上下文：

```yaml
name: refactoring-code
description: Performs code refactoring with change tracking...
context: fork
agent: Plan
hooks:
  Stop:
    - type: command
      command: "./scripts/summarize-changes.sh"
```

**模式 3: 只读分析 Skill**

```yaml
name: security-scanning
description: Scans code for security vulnerabilities...
allowed-tools: Read, Grep, Glob
context: fork
```

**模式 4: 安全敏感操作**

```yaml
name: database-migration
description: Executes database migrations...
allowed-tools: Read, Bash(python:*)
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-sql.sh $TOOL_INPUT"
```

**模式 5: 内部 helper Skill**

```yaml
name: format-checker
description: Checks code formatting (used by other Skills)...
user-invocable: false
```

### 热重载特性

Skills 支持**热重载**：新增或修改的 Skills 立即生效，无需重启会话。

**应用场景**：长时间运行的任务中，可以让 Claude 将重复性操作抽象为新 Skill，然后立即在后续任务中使用。

---

## Required Fields

### name

**Required.** The Skill name.

**Validation rules:**
- Maximum 64 characters
- Only lowercase letters, numbers, and hyphens
- Cannot contain XML tags
- Cannot contain reserved words: "anthropic", "claude"
- Should match the directory name

```yaml
name: processing-pdfs
```

### description

**Required.** What the Skill does and when to use it.

**Validation rules:**
- Must be non-empty
- Maximum 1024 characters
- Cannot contain XML tags
- **Always write in third person**

**Good examples:**
```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.

description: Analyze Excel spreadsheets, create pivot tables, generate charts. Use when analyzing Excel files, spreadsheets, tabular data, or .xlsx files.
```

**Bad examples:**
```yaml
# Too vague
description: Helps with documents

# Wrong person (uses "I" or "you")
description: I can help you process PDF files

# Missing trigger context
description: Processes data
```

---

## Optional Fields

### allowed-tools

Limits which tools Claude can use when this Skill is active. Tools listed here can be used without asking permission.

**Formats:**

Comma-separated string:
```yaml
allowed-tools: Read, Grep, Glob
```

YAML list:
```yaml
allowed-tools:
  - Read
  - Grep
  - Glob
```

**Use cases:**
- Read-only Skills that shouldn't modify files
- Skills with limited scope (data analysis only, no file writing)
- Security-sensitive workflows

**Note:** If omitted, the Skill doesn't restrict tools. Claude uses its standard permission model.

### model

Specifies which model to use when this Skill is active.

```yaml
model: claude-sonnet-4-20250514
```

If not specified, defaults to the conversation's model.

### context

Set to `fork` to run the Skill in an isolated sub-agent context with its own conversation history.

```yaml
context: fork
```

**Use cases:**
- Complex multi-step operations that shouldn't clutter the main conversation
- Tasks requiring different tool access
- Operations needing isolation from main context

### agent

Specifies which agent type to use when `context: fork` is set.

```yaml
context: fork
agent: Explore
```

**Valid values:**
- `Explore` - Fast agent for exploring codebases
- `Plan` - Software architect agent for designing implementation plans
- `general-purpose` - General-purpose agent (default if not specified)
- Custom agent name from `.claude/agents/`

**Note:** Only applicable when combined with `context: fork`.

### hooks

Define hooks scoped to this Skill's lifecycle. Supports `PreToolUse`, `PostToolUse`, and `Stop` events.

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh $TOOL_INPUT"
          once: true
```

**Hook event types:**
- `PreToolUse` - Runs before a tool is used
- `PostToolUse` - Runs after a tool is used
- `Stop` - Runs when the Skill stops

**Hook options:**
- `matcher` - Tool name to match (e.g., "Bash", "Edit")
- `type` - Hook type (e.g., "command")
- `command` - Command to run
- `once` - If true, only run once per session

### user-invocable

Set to `false` to hide the Skill from the slash command menu. Skills are visible in the menu by default.

```yaml
user-invocable: false
```

**Use cases:**
- Skills that should only be triggered automatically, not manually
- Helper Skills used by other Skills

---

## Complete Example

```yaml
---
name: secure-code-analysis
description: Analyzes code for security vulnerabilities and generates reports. Use when reviewing code for security issues, auditing dependencies, or preparing security documentation.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(python:*)
model: claude-sonnet-4-20250514
context: fork
agent: Explore
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh $TOOL_INPUT"
user-invocable: true
---

# Secure Code Analysis

## Instructions
...
```
