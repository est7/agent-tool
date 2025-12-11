# MCP Rules — MCP 工具使用规范

---

## 1. 全局原则

- **离线优先**: 能用本地工具完成的，不调用外部 MCP
- **单轮单工具**: 每轮对话最多调用 1-2 个 MCP 服务
- **最小必要**: 限制查询范围，避免过度数据捕获
- **可追溯**: 引用外部信息时标注来源

---

## 2. 服务选择与触发时机

| 服务 | 触发时机 | 用途 |
|------|---------|------|
| **sequential-thinking** | 分解复杂问题、规划步骤、评估方案 | 生成可执行计划与里程碑 |
| **context7** | 查询库/框架文档、API 用法、最新版本信息 | 获取最新技术文档上下文 |
| **memory** | 用户分享偏好、项目约定、重要信息 | 跨会话持久化知识图谱 |
| **claudecode-mcp-async** | 在 Codex/Gemini 中调用 Claude Code | 跨 Agent 异步协作 |
| **codex-mcp-async** | 在 Claude/Gemini 中调用 Codex | 跨 Agent 异步协作 |
| **gemini-cli-mcp-async** | 在 Claude/Codex 中调用 Gemini | 跨 Agent 异步协作 |

---

## 3. 服务使用指南

### Sequential Thinking

- 步骤上限 6-10 步，每步一句话
- 输出可执行计划，不暴露中间推理
- 用于：任务分解、方案评估、风险识别

### Context7

- 使用 `@upstash/context7-mcp` 包
- 获取库/框架的最新官方文档
- 自动解析库名，返回相关上下文

### Memory

- 核心概念：实体（节点）、关系（有向连接）、观察（原子事实）
- 常用工具：`create_entities`、`add_observations`、`search_nodes`
- 用于：记录用户偏好、项目约定、技术决策

### Async MCP (跨 Agent 协作)

- `claudecode-mcp-async` / `codex-mcp-async` / `gemini-cli-mcp-async`
- 允许不同 Agent CLI 之间互相调用
- 通过 uvx 运行，无需额外配置

---

## 4. 失败降级

- 首选服务失败时，尝试备用服务
- 全部失败时，提供保守的本地答案并标注不确定性
- 记录失败原因，便于后续优化
