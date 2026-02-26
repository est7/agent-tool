# JetBrains MCP Rules — JetBrains IDE 集成决策规则

> 本规则定义"何时"使用 JetBrains MCP。
> 具体执行方法（工具选择、参数、工作流）见 jetbrains-skill。

---

## 1) 前提条件（必须全部满足）

使用 JetBrains MCP 前，确认以下条件全部成立：

- JetBrains IDE（IntelliJ IDEA / Android Studio / WebStorm 等）已打开当前项目
- JetBrains MCP 插件已启用并在运行
- 端点可访问（SSE 常见为 `http://localhost:64343/sse`）

若条件不满足：
- **不要反复尝试连接**（最多 1 次探测 + 1 次重试）
- 直接切换到非 IDE 方案（见 §5 降级策略）

> 客户端差异：有些客户端（如 IDE 插件会话）配置的 MCP 仅对"插件会话"生效，不影响独立 CLI。

---

## 2) 何时优先使用

以下场景优先选择 JetBrains MCP 而非 CLI 工具：

- **语义导航**：跳转到定义、查找用法、符号层级（比纯文本搜索更准）
- **结构化重构**：安全重命名、提取方法/变量、移动类/文件并修复引用
- **IDE Inspection**：获取静态检查结果与可自动修复项
- **运行配置**：通过 IDE Run Configuration 启动/调试（尤其是 Android / 多模块项目）
- **索引搜索**：文件名/内容搜索利用 IDE 索引，通常更快更准

---

## 3) 何时不使用（改走 CLI）

- 用户没有打开 JetBrains IDE，或明确使用其它编辑器
- 批量文本查找/替换、简单编辑：优先用 `rg` / 直接编辑
- 与 IDE 无关的任务：更新文档、修改脚本、整理配置

---

## 4) 安全要求

- 调用前必须说明将要执行的 IDE 操作
- **多文件影响的操作必须先获得用户确认**
- **只读操作可直接执行**（无需确认）
- 具体哪些操作需要/不需要确认 → 见 jetbrains-skill Constraints

---

## 5) 降级策略

当 JetBrains MCP 不可用（IDE 未开 / 插件未启用 / 端口不可达）：

- **代码理解**：优先 `codebase-retrieval`（语义检索）+ `rg`（精确字符串搜索）
- **重构**：改用小步安全改动（最小 diff），必要时补充测试/构建验证
- **运行**：使用仓库自带命令（Gradle、pnpm/npm、pytest 等），不要依赖 IDE Run Configuration
