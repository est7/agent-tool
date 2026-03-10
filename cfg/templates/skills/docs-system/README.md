# docs-system

这个 skill 用来把**当前已经存在的上下文**落盘到合适的文档位置，而不是额外展开一套新的思维链。

## 目录说明

`references/` 下的文件分成三类：

- 规则说明
  - `taxonomy.md`：定义 `docs/` 下各目录分别放什么
  - `indexing.md`：定义 `docs/README.md` 和 `docs/postmortem/README.md` 的索引规则
  - `postmortem.md`：定义 postmortem 的使用场景和建议结构
- 目录模板
  - `docs-readme-template.md`
  - `design-template.md`
  - `research-template.md`
  - `implementation-template.md`
  - `reference-template.md`
  - `user-template.md`
  - `context-template.md`
  - `postmortem-template.md`
  - `postmortem-readme-template.md`
  - `archive-template.md`

## `docs/` 目录装什么

| 目录 | 内容 |
|------|------|
| `docs/design/` | 设计方案、架构决策、权衡、ADR 类内容 |
| `docs/research/` | 调研、对比、探索性分析 |
| `docs/implementation/` | 实施方案、迁移步骤、上线/执行记录 |
| `docs/reference/` | 稳定参考资料，如接口、命令、约束、数据结构 |
| `docs/user/` | 用户或操作手册 |
| `docs/context/` | 长期项目背景与上下文，不等同于 Claude memory |
| `docs/postmortem/` | 故障、回归、fix 沉淀出的尸检报告 |
| `docs/archive/` | 已废弃但仍需保留检索价值的历史文档 |

## 模板对应关系

| 目标文件/目录 | 模板 |
|--------------|------|
| `docs/README.md` | `references/docs-readme-template.md` |
| `docs/design/*.md` | `references/design-template.md` |
| `docs/research/*.md` | `references/research-template.md` |
| `docs/implementation/*.md` | `references/implementation-template.md` |
| `docs/reference/*.md` | `references/reference-template.md` |
| `docs/user/*.md` | `references/user-template.md` |
| `docs/context/*.md` | `references/context-template.md` |
| `docs/postmortem/*.md` | `references/postmortem-template.md` |
| `docs/postmortem/README.md` | `references/postmortem-readme-template.md` |
| `docs/archive/*.md` | `references/archive-template.md` |

## 使用原则

- 优先更新离代码最近、已经存在的文档位置
- 根级 `docs/README.md` 负责总索引
- `docs/postmortem/README.md` 负责 postmortem 的独立 TOC
- 模板是起点，不要求机械照抄；但结构要保持稳定，便于 agentic RAG
