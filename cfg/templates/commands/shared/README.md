# Shared Slash Commands

English summary: this directory contains slash command templates intended to be shared across projects.

---

## 中文说明

本目录包含跨项目共享的 slash commands。

## 命令列表

| 命令 | 用途 |
|------|------|
| `/deep-plan` | 深度分析规划，含 review gate |
| `/catchup-from-branch` | 收集当前分支相对 base branch 的已提交变更，读取文件全文 |
| `/catchup-from-unstaged` | 收集未提交更改（含 submodule）作为结构化上下文 |
| `/review-role-advisor` | 根据代码文件类型自动推荐审查角色（frontend/security/architect 等） |
| `/review-solid-patterns` | 评估设计模式使用、SOLID 原则评分、反模式检测及重构建议 |
| `/clarify-intent` | 交互式澄清模糊指令，确认意图后再执行 |
| `/clarify-spec` | 采访式补全需求规格文档 |
| `/docs-sync` | 把当前上下文落盘到合适的 `docs/` 分类并刷新索引 |
| `/postmortem-check` | 发布前后基于 `docs/postmortem/` 做检查与落盘 |
| `/cleanup-ai-slop` | 清理 AI 生成的冗余代码（多余注释、防御性检查等） |
| `/handoff` | 生成跨会话交接摘要给下一位 AI Agent |

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

### /catchup-from-branch

**使用方式**:
```
/catchup-from-branch                           # 收集分支已提交变更
/catchup-from-branch 这些变更的主要目的是什么？  # 带问题
/catchup-from-branch 重点看 auth 模块的改动      # 聚焦特定区域
```

**适用场景**:
- 新会话开头了解当前分支做了什么
- Code review 前回顾分支全部提交
- 自动检测 base branch（main/master/develop）

---

### /catchup-from-unstaged

**使用方式**:
```
/catchup-from-unstaged                           # 收集所有未提交更改
/catchup-from-unstaged 这些变更的主要目的是什么？  # 带问题
```

**适用场景**:
- 准备 commit 前回顾工作区状态
- 多模块/monorepo 项目收集 submodule 状态
- 了解当前正在进行的修改

---

### /review-role-advisor

**使用方式**:
```
/review-role-advisor                    # 分析当前目录
/review-role-advisor src/auth/          # 分析指定目录
/review-role-advisor api/handler.go     # 分析指定文件
```

**适用场景**:
- 不确定该用哪个审查角色
- 代码涉及多个技术领域
- 需要智能推荐审查策略（单角色 / 多角色 / 辩论模式）

---

### /review-solid-patterns

**使用方式**:
```
/review-solid-patterns                     # 分析当前目录
/review-solid-patterns src/services/       # 分析指定目录
/review-solid-patterns src/payment.ts      # 分析指定文件
```

**适用场景**:
- 评估代码架构质量
- 识别设计模式使用情况
- 检查 SOLID 原则遵循度（含评分）
- 发现反模式并获取重构建议

---

### /clarify-intent

**使用方式**:
```
/clarify-intent 帮我实现一个滑动列表
/clarify-intent 添加用户登录功能
```

**适用场景**:
- 用户需求描述模糊
- 需要澄清交互方式、数据来源、视觉风格等
- 避免返工，一次做对

---

### /clarify-spec

**使用方式**:
```
/clarify-spec docs/feature-spec.md
/clarify-spec requirements.md
```

**适用场景**:
- 规格文档不够详细
- 需要深度采访澄清需求
- 补充边界情况、性能要求等

---

### /cleanup-ai-slop

**使用方式**:
```
/cleanup-ai-slop
/cleanup-ai-slop src/utils/
```

**适用场景**:
- AI 生成代码后的清理
- 移除多余注释、防御性检查
- 统一代码风格

---

### /handoff

**使用方式**:
```
/handoff
/handoff 重点交接数据库迁移部分的进展
/handoff 强调已排除的方案和原因
```

**适用场景**:
- 当前上下文过长，需要开新会话继续工作
- 跨会话传递工作进展、决策和剩余任务
- 让下一位 AI Agent 快速接手而不丢失关键信息

---

## 创建新命令

参考 `cfg/templates/spec/agent-command-spec.md` 规范。

核心要点:
1. **开门见山** - 第一句用 `$ARGUMENTS` 告诉 Agent 要做什么
2. **指令式语言** - "分析..."、"生成..."，不是"这是什么"
3. **不写使用方式** - 用户调用时已经知道要用它
4. **不写适用场景** - 那是文档内容，放这个 README
