---
name: mcp-services
description: Detailed usage guides for MCP services (Sequential Thinking, Context7, Async MCP, GitHub, Google Developer Knowledge, Codebase Retrieval) and multi-tool collaboration patterns. Use when you need guidance on how to use a specific MCP service or combine multiple MCP services for complex tasks.
---

# MCP 服务使用规范（全量）

本文件是 MCP 的**全量**使用规范与手册，目标是把 MCP 相关规则集中在一个地方，避免分散与丢失信息。

> 提示：`cfg/templates/rules/mcp.md` 只保留最小入口与约束；所有细节以本文件为准。

---

## 1. 全局原则

- **离线优先**：能用本地工具完成的，不调用外部 MCP
- **单轮单工具**：每轮对话最多调用 1–2 个 MCP 服务（超过时必须说明收益与原因）
- **最小必要**：限制查询范围，避免过度数据捕获
- **可追溯**：引用外部信息时标注来源

---

## 2. 工具决策流程

任务开始时，按以下流程判断是否使用 MCP 以及使用哪个：

```
Task received
  │
  ├─ Identify task type (code understanding / docs / repo search / complex planning / cross-agent collaboration)
  │
  ├─ Can native tools complete it efficiently?
  │    ├─ Yes → use native tools, skip MCP
  │    └─ No  → select the most suitable MCP service
  │
  └─ Execute and monitor
       ├─ Success → done
       └─ Failure → trigger switch (see below)
```

### 2.1 切换触发条件

| 触发类型 | 条件 | 动作 |
|---------|------|------|
| **错误触发** | MCP 工具连续失败 ≥ 2 次 | 切换到备选方案或原生能力 |
| **效率触发** | MCP 调用耗时远超预期 | 评估是否改用本地工具 |
| **能力触发** | 任务超出当前工具能力范围 | 切换到更合适的 MCP 或组合使用 |
| **发现触发** | 执行中发现更优工具 | 立即切换 |

### 2.2 缺失工具处理

当识别出任务需要但未配置的 MCP 时：
1. 告知用户缺失的工具及其价值
2. 提供安装配置命令
3. 用当前可用的方案先完成任务（降级执行）

---

## 3. 服务选择与触发时机

| 服务 | 触发时机 | 用途 |
|------|---------|------|
| **sequential-thinking** | 分解复杂问题、规划步骤、评估方案 | 生成可执行计划与里程碑 |
| **context7** | 查询库/框架文档、API 用法、最新版本信息 | 获取最新技术文档上下文 |
| **claudecode-mcp-async** | 在 Codex/Gemini 中调用 Claude Code | 跨 Agent 异步协作 |
| **codex-mcp-async** | 在 Claude/Gemini 中调用 Codex | 跨 Agent 异步协作 |
| **gemini-cli-mcp-async** | 在 Claude/Codex 中调用 Gemini | 跨 Agent 异步协作 |
| **github** | 搜索开源实现、查找类似库、查看仓库代码、管理 Issue/PR | GitHub 全平台检索与项目管理 |
| **google-developer-knowledge** | 查询 Google 系产品文档（Android、Firebase、Cloud、Maps 等） | Google 官方开发者文档检索 |
| **jetbrains** | 需要在 JetBrains IDE 中执行操作（导航、重构、运行配置等） | JetBrains IDE 集成（SSE） |
| **auggie-mcp** (codebase-retrieval) | 理解本地代码架构、追踪调用链、编辑前获取上下文 | AI 语义代码检索（详见第 5 章） |

---

## 4. 服务使用指南

### 4.1 Sequential Thinking

结构化思维链工具，将复杂问题拆解为可执行的线性步骤。

**适用场景**：
- 多步骤任务的分解与排序（如：重构方案设计、迁移计划）
- 多方案权衡评估（需要列出 pros/cons 再做决策时）
- 风险识别与应对策略制定
- 调试时的根因分析（从现象倒推可能原因）

**不适用场景**：
- 单步骤简单任务（直接执行即可）
- 已有明确方案、无需权衡的场景
- 纯信息查询（改用 context7 或 codebase-retrieval）

**使用约束**：
- 步骤上限 6–10 步，每步一句话描述
- 输出可执行计划，不暴露中间推理过程
- 步骤间保持线性依赖，避免并行分支

### 4.2 Context7

基于 `@upstash/context7-mcp` 的技术文档检索工具，获取库/框架的最新官方文档。

**适用场景**：
- 查询第三方库的 API 用法和参数签名
- 确认框架最新版本的 breaking changes 或新特性
- 获取官方推荐的最佳实践和配置方式
- 对比不同版本间的 API 差异

**不适用场景**：
- 查询项目自身代码（改用 `codebase-retrieval`）
- 查询通用编程概念（Agent 自身知识已足够）
- 查询非公开的内部文档或私有 API

**使用约束**：
- 使用第三方库时，**优先查询 Context7** 获取最新文档，防止生成过时或不存在的 API
- 调用工作流：先 `resolve-library-id` 获取 Context7 ID（用户已提供 `/org/project` 格式时可跳过）→ 再 `get-library-docs` 获取文档
- 查询时指定具体的库名和版本号以提高准确性
- 优先用于 Agent 知识截止日期之后的新版本特性

**与 `google-developer-knowledge` 的选择标准**：

| 查询目标 | 选择 |
|---------|------|
| Google 系产品（Android SDK、Firebase、Cloud、Maps、TensorFlow 等） | `google-developer-knowledge` 优先 |
| 非 Google 的第三方库（OkHttp、React、Spring 等） | `context7` |
| 两者都涉及（如 Retrofit + Firebase Auth） | 分别查询各自擅长的部分 |

### 4.3 Async MCP（跨 Agent 协作）

允许不同 Agent CLI 之间互相异步调用，通过 uvx 运行，无需额外配置。

| 服务 | 调用方向 | 适合委派的任务 |
|------|---------|---------------|
| `claudecode-mcp-async` | Codex/Gemini → Claude Code | 深度代码理解、复杂重构方案设计、长上下文分析 |
| `codex-mcp-async` | Claude/Gemini → Codex | 代码生成、快速原型实现、批量代码修改 |
| `gemini-cli-mcp-async` | Claude/Codex → Gemini | 大上下文窗口任务、多模态分析（含图片/文档） |

**适用场景**：
- 任务超出当前 Agent 的能力边界（如上下文窗口不足）
- 需要不同 Agent 的差异化优势（如 Claude 擅长推理、Codex 擅长代码生成）
- 并行处理独立子任务以提高效率
- 需要二次验证（让另一个 Agent 审查方案）

**不适用场景**：
- 当前 Agent 可以独立完成的简单任务
- 需要实时交互的场景（异步调用有延迟）
- 涉及敏感信息且不宜跨 Agent 传递的任务

### 4.4 GitHub MCP（GitHub 全平台检索与项目管理）

基于 [github/github-mcp-server](https://github.com/github/github-mcp-server) 的官方 MCP 服务，通过 Docker 运行，需要 `GITHUB_PERSONAL_ACCESS_TOKEN`。

#### 核心工具分类

| 类别 | 关键工具 | 说明 |
|------|---------|------|
| **代码搜索** | `search_code` | 用 GitHub 搜索语法在全平台查找代码片段 |
| **仓库发现** | `search_repositories` | 按关键词、语言、stars 等条件发现开源库 |
| **代码阅读** | `get_file_contents`, `get_repository_tree` | 浏览仓库目录结构和文件内容 |
| **提交历史** | `list_commits`, `get_commit` | 查看提交记录和具体 diff |
| **Issue/PR** | `search_issues`, `search_pull_requests`, `create_pull_request` | 搜索和管理 Issue、PR |
| **安全扫描** | `list_code_scanning_alerts`, `list_dependabot_alerts` | 查看代码安全告警和依赖漏洞 |
| **Actions** | `actions_list`, `actions_get`, `get_job_logs` | 监控 CI/CD 工作流状态和日志 |

#### 适用场景

**场景 1：寻找类似功能的开源库**
- 用 `search_repositories` 按关键词 + 语言 + 最低 stars 筛选
- 用 `get_file_contents` 阅读候选库的 README 和核心代码
- 用 `list_commits` 判断项目活跃度

> 示例："搜索 Kotlin 语言、stars > 100 的图片加载库" → `search_repositories`

**场景 2：学习某功能的实现方式**
- 用 `search_code` 在高质量仓库中搜索特定 API/模式的用法
- 用 `get_repository_tree` 了解项目结构，再用 `get_file_contents` 读具体实现
- 用 `get_commit` 查看关键功能是如何逐步引入的

> 示例："在 OkHttp 仓库中搜索拦截器链的实现" → `search_code` + `get_file_contents`

**场景 3：项目日常管理**
- 用 `search_issues` / `search_pull_requests` 查找相关 Issue 和 PR
- 用 `create_pull_request` 直接创建 PR
- 用 `list_code_scanning_alerts` 检查安全告警

**场景 4：技术选型调研**
- 用 `search_repositories` 对比多个候选库（stars、最近提交、license）
- 用 `get_latest_release` 确认版本发布节奏
- 用 `list_dependabot_alerts` 评估依赖安全性

#### 不适用场景

- 搜索项目自身代码（改用 `codebase-retrieval`）
- 查询库的官方文档和 API 说明（改用 `context7`）
- 不需要 GitHub 数据的纯本地任务

### 4.5 JetBrains MCP（IDE 集成）

通过 SSE 协议连接本地运行的 JetBrains IDE（IntelliJ IDEA、Android Studio、WebStorm 等），端口固定为 64343。

决策规则与降级策略见 `jetbrains-mcp.md`；执行方法见 `jetbrains-skill`。

**适用场景**：
- 在 IDE 中执行代码导航（跳转到定义、查找用法、查看类层次）
- 触发 IDE 内置重构操作（重命名、提取方法/变量、移动类）
- 读取 IDE 感知的项目信息（运行配置、模块结构、依赖树）
- 利用 IDE 内置的代码分析和检查能力（Lint、Inspection）
- 在 IDE 中执行构建、运行或调试任务

**不适用场景**：
- IDE 未启动时（SSE 端点不可用，会连接失败）
- 纯文本编辑（Agent 自身的文件读写能力已足够）
- 查询第三方库文档（改用 `context7`）
- 语义级代码搜索（改用 `codebase-retrieval`）

**使用约束**：
- 需要 JetBrains IDE 已安装并启用 MCP 插件
- IDE 必须处于运行状态，端口 64343 可达
- 操作结果依赖 IDE 当前打开的项目上下文

### 4.6 Google Developer Knowledge（Google 官方文档检索）

Google 提供的远程 MCP 服务（HTTP 类型），通过 `GOOGLE_DEVELOPER_KNOWLEDGE_API_KEY` 鉴权，直接检索 Google 官方开发者文档。

#### 核心工具

| 工具 | 说明 |
|------|------|
| `search_documents` | 搜索 Google 开发者文档，返回文档片段（snippet）、名称和 URL |
| `get_document` | 根据 `parent` 字段获取单个文档的完整内容 |
| `batch_get_documents` | 批量获取最多 20 个文档的完整内容（优先于多次 `get_document`） |

#### 覆盖范围

Android (`developer.android.com`)、Firebase (`firebase.google.com`)、Google Cloud (`docs.cloud.google.com`)、Chrome (`developer.chrome.com`)、Google AI (`ai.google.dev`)、Google Maps / Ads / Search / YouTube (`developers.google.com`)、Google Home (`developers.home.google.com`)、TensorFlow (`www.tensorflow.org`)、Web (`web.dev`)、Apigee (`docs.apigee.com`)、Fuchsia (`fuchsia.dev`)

#### 适用场景

- 查询 Google 系 SDK 的 API 用法、参数签名、代码示例
- 获取 Android / Firebase / Cloud 等产品的最佳实践和配置指南
- 排查 Google API 相关错误（如 Maps API key 问题、Cloud IAM 配置）
- 对比 Google 产品的功能差异（如 Cloud Run vs Cloud Functions）

#### 不适用场景

- 查询非 Google 的第三方库文档（改用 `context7`）
- 搜索项目自身代码（改用 `codebase-retrieval`）
- 查询 GitHub、博客、YouTube 等非官方文档来源（不在覆盖范围内）
- 非英语文档查询（仅支持英文结果）

#### 使用约束

- **仅英文结果**：不支持中文等其他语言的文档
- **仅公开文档**：不含 GitHub、OSS 站点、博客或 YouTube 内容
- **网络依赖**：依赖 Google Cloud 在线服务，离线不可用
- **推荐工作流**：先 `search_documents` 获取片段 → 片段不够详细时用 `get_document` 或 `batch_get_documents` 获取全文

---

## 5. Auggie-MCP codebase-retrieval 使用规范

### 5.1 工具定位

`codebase-retrieval` 是基于语义嵌入的 AI 代码检索引擎，支持自然语言查询、跨语言检索，实时索引当前工作副本代码。

### 5.2 适用场景（优先使用）

- **理解业务流程 / 架构**：
  - "用户认证是在哪个模块里实现的？"
  - "登录功能有哪些测试用例？"
  - "数据库是如何连接到应用的？"
- **追踪调用链**：了解模块职责、业务流程关键入口
- **编辑前上下文获取**：修改代码前，先用它查询涉及的类、函数、属性等完整定义

### 5.3 不适用场景（改用 grep / IDE）

- 精确查找某个类 / 函数定义（如 `class Foo`）
- 查找某个函数的所有调用点（find all references）
- 查看某个文件的全文内容
- 精确字符串 / 常量匹配（UUID、配置值、错误信息）
- 代码注释标记搜索（TODO、FIXME、HACK）

### 5.4 编辑前深度查询协议

在编辑任何文件之前，**必须**先调用 `codebase-retrieval` 获取详细上下文：

| 规则 | 说明 |
|------|------|
| **全量查询** | 一次调用中询问所有涉及编辑的符号 |
| **一次完成** | 不要多次调用，除非获得新信息需要进一步澄清 |
| **疑问时包含** | 不确定某符号是否相关时，宁可包含 |
| **利用位置权重** | 重要符号放在查询末尾效果最好 |

**查询示例**：

- ✅ "我要修改 UserService.login()，请提供：UserService 类定义、login 方法实现、它调用的 AuthProvider 接口和 TokenManager 相关方法"
- ❌ 分多次分别查询每个符号

### 5.5 搜索工具快速选择表

| 场景 | 推荐工具 |
|------|---------|
| 理解业务流程 / 架构 | `codebase-retrieval` |
| 探索未知代码（不知关键词） | `codebase-retrieval` |
| 精确查找符号引用 | `grep` |
| 查找 TODO / FIXME | `grep` |
| 查找配置值 / 常量 | `grep` |
| 跨语言追踪调用链 | `codebase-retrieval` |
| 批量重命名前检查 | `grep` |
| IDE 内导航 / 重构 / 运行 | `jetbrains` |
| IDE 内置代码检查（Inspection） | `jetbrains` |
| 查询 Google 系产品文档（Android、Firebase、Cloud 等） | `google-developer-knowledge` |
| 查询非 Google 的第三方库文档 | `context7` |

---

## 6. 常见多工具协作模式

单个 MCP 解决单一问题，多个 MCP 串联解决复合任务。以下是常见的协作模式：

### 6.1 技术选型调研

```
github (search_repositories)  →  context7 / google-developer-knowledge  →  sequential-thinking
   discover candidates             query docs (by product)                    weigh pros/cons and decide
```

**典型流程**：
1. `github`: `search_repositories` 按语言 + stars 筛选候选库
2. `github`: `get_file_contents` 阅读候选库 README 和核心代码
3. 文档查询（按归属选择）：Google 系产品用 `google-developer-knowledge`，其他用 `context7`
4. `sequential-thinking`: 列出对比维度，逐步权衡，输出推荐方案

### 6.2 新代码库上手

```
codebase-retrieval  →  github (search_code)  →  context7 / google-developer-knowledge
  understand local arch     search similar impls        query dependency docs
```

**典型流程**：
1. `codebase-retrieval`: 了解项目整体架构、模块划分、核心入口
2. `codebase-retrieval`: 追踪关键业务流程的调用链
3. `github`: `search_code` 搜索同类项目中类似功能的实现方式作为参考
4. 文档查询：Google 系产品用 `google-developer-knowledge`，其他用 `context7`

### 6.3 复杂功能规划

```
codebase-retrieval  →  sequential-thinking  →  async-mcp (optional)
   survey existing code        plan steps           delegate subtasks
```

**典型流程**：
1. `codebase-retrieval`: 查询涉及修改的所有类、函数、依赖关系
2. `sequential-thinking`: 将需求拆解为 6–10 个可执行步骤
3. `async-mcp`（可选）: 将独立子任务委派给其他 Agent 并行处理

### 6.4 Bug 排查

```
codebase-retrieval  →  github (search_issues)  →  context7 / google-developer-knowledge
   locate problem code          search known issues            query correct API usage
```

**典型流程**：
1. `codebase-retrieval`: 根据错误现象定位相关代码和调用链
2. `github`: `search_issues` 在依赖库中搜索是否为已知问题
3. 文档查询：Google 系 API 问题用 `google-developer-knowledge`，其他用 `context7`

---

## 7. 失败降级

### 7.1 通用原则

- 首选服务失败时，尝试备用服务
- 全部失败时，提供保守的本地答案并标注不确定性
- 记录失败原因，便于后续优化

### 7.2 各服务降级策略

| 服务 | 降级方案 |
|------|---------|
| `context7` | 改用 `google-developer-knowledge`（Google 产品）或 Agent 自身知识 + `WebSearch` |
| `google-developer-knowledge` | 改用 `context7`（如覆盖范围有交集）或 Agent 自身知识 + `WebSearch` |
| `github` | 改用 `gh` CLI（`gh api`、`gh search`、`gh pr`）|
| `auggie-mcp` (codebase-retrieval) | 改用 `grep` + 文件读取 + IDE 索引搜索 |
| `jetbrains` | 见 `jetbrains-mcp.md` §5 降级策略 |
| `sequential-thinking` | Agent 内部推理（不使用外部工具） |
| `async-mcp`（跨 Agent） | 当前 Agent 独立完成任务 |
