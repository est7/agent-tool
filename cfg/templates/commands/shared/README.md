# Shared Slash Commands

本目录包含跨项目共享的 slash commands。

## 命令列表

| 命令 | 用途 |
|------|------|
| `/plan` | 使用 sequential-thinking 生成执行计划 |
| `/catchup` | 收集多模块仓库未提交更改 |
| `/simple-catchup` | 快速查看当前分支变更 |
| `/sequential-think` | 深度结构化思考，复杂决策分析 |
| `/role-debate` | 多角色辩论，权衡评估 |
| `/smart-review` | 智能推荐代码审查角色 |
| `/android-code-review` | Android/Kotlin 代码专业审查 |
| `/design-patterns` | 设计模式和 SOLID 原则分析 |
| `/tech-debt` | 技术债务量化评估 |
| `/enhance-prompt` | 交互式优化模糊指令 |
| `/enhance-spec` | 采访式需求规格细化 |
| `/remove-ai-junk-code` | 清理 AI 生成的代码垃圾 |
| `/lanhu` | 蓝湖设计稿提取（截图版） |
| `/lanhu01` | 蓝湖设计稿提取（跨平台规格） |
| `/lanhu02` | 蓝湖设计稿提取（优化版） |

---

## 使用方式与适用场景

### /plan

**使用方式**:
```
/plan 帮我设计 XXX 的实现方案
/plan 重构用户认证模块
```

**适用场景**:
- 需要结构化规划的复杂任务
- 想要把计划落地到 `plan/` 目录
- 需要 sequential-thinking MCP 辅助分解任务

---

### /catchup

**使用方式**:
```
/catchup                           # 收集所有未提交更改
/catchup 这些变更的主要目的是什么？  # 带问题
```

**适用场景**:
- 多模块/monorepo 项目
- 需要了解当前工作状态
- 准备 commit 前回顾变更

---

### /simple-catchup

**使用方式**:
```
/simple-catchup
```

**适用场景**:
- 快速了解当前分支相对 develop 的变更
- 单仓库项目

---

### /sequential-think

**使用方式**:
```
/sequential-think 微服务 vs 单体架构选择
/sequential-think 技术栈迁移方案评估
/sequential-think API 响应时间从 2s 降到 200ms
```

**适用场景**:
- 影响深远的架构决策
- 多方案权衡比较
- 复杂系统设计
- 技术债务偿还策略

**不适用**:
- 简单的 Bug 修复
- 明确的功能实现
- 日常代码审查

---

### /role-debate

**使用方式**:
```
/role-debate security,performance JWT Token 过期时间设置
/role-debate architect,frontend,mobile 状态管理方案选择
/role-debate backend,security 数据库加密策略
```

**可用角色**: security, performance, architect, frontend, backend, mobile, analyzer

**适用场景**:
- 技术选型（框架、数据库、云服务）
- 架构设计（微服务 vs 单体、同步 vs 异步）
- 权衡决策（安全 vs 性能、体验 vs 成本）
- 跨平台策略

---

### /smart-review

**使用方式**:
```
/smart-review                    # 分析当前目录
/smart-review src/auth/          # 分析指定目录
/smart-review api/handler.go     # 分析指定文件
```

**适用场景**:
- 不确定用哪个审查角色
- 代码涉及多个领域
- 需要智能推荐审查策略

---

### /android-code-review

**使用方式**:
```
/android-code-review                          # 审查当前目录
/android-code-review app/src/main/            # 审查指定目录
/android-code-review 关注协程使用              # 带关注点
```

**适用场景**:
- Android/Kotlin 项目代码审查
- 检查状态管理、协程、架构分层
- 识别 Android 反模式

---

### /design-patterns

**使用方式**:
```
/design-patterns                     # 分析当前目录
/design-patterns src/services/       # 分析指定目录
/design-patterns src/payment.ts      # 分析指定文件
```

**适用场景**:
- 评估代码架构质量
- 识别设计模式使用情况
- 检查 SOLID 原则遵循度
- 发现反模式并获取重构建议

---

### /tech-debt

**使用方式**:
```
/tech-debt                    # 分析当前项目
/tech-debt ./backend          # 分析指定目录
/tech-debt 关注安全问题        # 带关注领域
```

**适用场景**:
- 项目健康度评估
- 制定技术债务偿还计划
- 优先级排序（基于 ROI）
- Sprint 规划参考

---

### /enhance-prompt

**使用方式**:
```
/enhance-prompt 帮我实现一个滑动列表
/enhance-prompt 添加用户登录功能
```

**适用场景**:
- 用户需求描述模糊
- 需要澄清交互方式、数据来源、视觉风格等
- 避免返工，一次做对

---

### /enhance-spec

**使用方式**:
```
/enhance-spec docs/feature-spec.md
/enhance-spec requirements.md
```

**适用场景**:
- 规格文档不够详细
- 需要深度采访澄清需求
- 补充边界情况、性能要求等

---

### /remove-ai-junk-code

**使用方式**:
```
/remove-ai-junk-code
/remove-ai-junk-code src/utils/
```

**适用场景**:
- AI 生成代码后的清理
- 移除多余注释、防御性检查
- 统一代码风格

---

### /lanhu, /lanhu01, /lanhu02

**使用方式**:
```
/lanhu https://lanhu.com/xxx?ddsUrl=xxx
/lanhu01 https://lanhu.com/xxx?ddsUrl=xxx
/lanhu02 https://lanhu.com/xxx?ddsUrl=xxx
```

**区别**:
- `/lanhu`: 截图设计图 + 保存 JSX/CSS 代码
- `/lanhu01`: 生成跨平台 spec.md（JSX → HTML 转换）
- `/lanhu02`: 优化版，使用脚本自动解析

**适用场景**:
- 从蓝湖提取设计稿代码
- 生成 Android/iOS 开发规格
- 设计稿截图存档

---

## 创建新命令

参考 `cfg/templates/spec/agent-command-spec.md` 规范。

核心要点:
1. **开门见山** - 第一句用 `$ARGUMENTS` 告诉 Agent 要做什么
2. **指令式语言** - "分析..."、"生成..."，不是"这是什么"
3. **不写使用方式** - 用户调用时已经知道要用它
4. **不写适用场景** - 那是文档内容，放这个 README
