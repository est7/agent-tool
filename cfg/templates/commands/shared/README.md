# Shared Slash Commands

English summary: this directory contains slash command templates intended to be shared across projects.

---

## 中文说明

本目录包含跨项目共享的 slash commands。

## 命令列表

| 命令 | 用途 |
|------|------|
| `/deep-plan` | 深度分析规划，含 review gate |
| `/catchup` | 收集多模块仓库未提交更改 |
| `/simple-catchup` | 快速查看当前分支变更 |
| `/smart-review` | 智能推荐代码审查角色 |
| `/android-code-review` | Android/Kotlin 代码专业审查 |
| `/design-patterns` | 设计模式和 SOLID 原则分析 |
| `/enhance-prompt` | 交互式优化模糊指令 |
| `/enhance-spec` | 采访式需求规格细化 |
| `/docs-sync` | 把当前上下文落盘到合适的 `docs/` 分类并刷新索引 |
| `/postmortem-check` | 发布前后基于 `docs/postmortem/` 做检查与落盘 |
| `/remove-ai-junk-code` | 清理 AI 生成的代码垃圾 |
| `/lanhu` | 蓝湖设计稿提取（截图版） |
| `/lanhu01` | 蓝湖设计稿提取（跨平台规格） |
| `/lanhu02` | 蓝湖设计稿提取（优化版） |

---

## 使用方式与适用场景

### /docs-sync

**使用方式**:
```
/docs-sync 更新这次重构涉及的设计文档和实现记录
/docs-sync 把当前讨论整理进 docs/reference 和 docs/context
```

**适用场景**:
- 需要把当前上下文落盘到 `docs/`
- 更新设计、研究、实现、参考、用户、上下文或归档文档
- 刷新 `docs/README.md` 或局部索引

---

### /postmortem-check

**使用方式**:
```
/postmortem-check 发布前检查这批改动是否触发已有 postmortem
/postmortem-check 把这次 fix 整理成新的 postmortem
```

**适用场景**:
- 发布前对照已有 `docs/postmortem/` 做风险检查
- 发布后或修复后沉淀新的尸检报告
- 刷新 `docs/postmortem/README.md` 的 TOC

---

### /deep-plan

**使用方式**:
```
/deep-plan 帮我设计 XXX 的实现方案
/deep-plan 重构用户认证模块
/deep-plan 微服务 vs 单体架构选择
```

**适用场景**:
- 需要结构化规划的复杂任务（功能开发、架构设计、迁移方案）
- 影响深远的技术决策（方案权衡、风险评估）
- 想要先 review 再执行（"寸止"模式）

**工作流**:
1. 复杂度评估 → sequential-thinking 分析
2. 生成执行计划 → 展示给用户 Review
3. 用户确认后 → 写入 `plan/` 目录 → 开始执行

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
