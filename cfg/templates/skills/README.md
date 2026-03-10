# Skills Templates

English summary: this directory contains skill templates shared across Claude Code, Codex CLI, and Gemini CLI.

---

## 中文说明

本目录包含跨 Agent 共享的 Skill 模板。Skills 是 Claude 自动识别并激活的知识模块，无需手动调用。

## Skill 列表

| Skill | 用途 | 触发方式 |
|-------|------|----------|
| `analyzing-project-health` | 技术债务量化 + 多角色辩论，生成健康评分和改进路线图 | 自动 |
| `codex-review` | 调用 Codex CLI 进行代码审核 | `/codex-review` |
| `create-command` | 创建 slash command 指南 | 自动 |
| `create-mcp` | 创建 MCP Server 指南（Python/Node） | 自动 |
| `create-skill` | 创建 Skill 指南 | 自动 |
| `developing-android-features` | Android 功能开发规范与架构模板 | 自动 |
| `dual-ai-review` | 多 AI 交叉审查（Gemini + Codex） | 自动 |
| `generating-android-ui` | 设计稿/前端代码 → Android XML 布局生成 | 自动 |
| `github-release` | 从 CHANGELOG 发布 GitHub Release | `/github-release` |
| `implementation-gates` | 非平凡任务的实现前门禁（简约/反抽象/测试优先/集成优先等） | 自动 |
| `jetbrains-skill` | JetBrains IDE MCP 集成（索引、重构、Inspection） | 自动 |
| `mcp-services` | MCP 服务的详细使用手册（按需加载） | 自动 |
| `plan-code-workflow` | 非平凡任务的 Plan/Code 工作流（按需加载） | 自动 |
| `prompt-engineering` | Prompt 工程最佳实践 | 自动 |
| `docs-system` | 文档体系落盘与索引维护（按需加载） | 自动 |
| `testing-tdd` | 测试与 TDD 工作流（按需加载） | 自动 |
| `version-bump` | 版本号升级并提交 git | `/version-bump` |

## 按用途分类

### 项目分析

| Skill | 说明 |
|-------|------|
| `analyzing-project-health` | 6 维度扫描（依赖/文档/测试/安全/架构/代码质量）+ 多角色辩论优先级 |

### Android 开发

| Skill | 说明 |
|-------|------|
| `developing-android-features` | MVI 架构、Base 类体系、列表/分页、网络请求等规范 |
| `generating-android-ui` | 从设计稿/截图/前端代码生成生产可用 XML 布局 |

### 代码审查

| Skill | 说明 |
|-------|------|
| `codex-review` | 调用 Codex 命令行审核，自动收集变更上下文 |
| `dual-ai-review` | Gemini + Codex 交叉验证，多视角分析 |

### 元技能（创建 Agent 组件 / Prompt）

| Skill | 说明 |
|-------|------|
| `create-command` | 创建 slash command 的结构、frontmatter、最佳实践 |
| `create-mcp` | 创建 MCP Server（FastMCP / MCP SDK） |
| `create-skill` | 创建 Skill 的结构、命名、渐进式加载 |
| `prompt-engineering` | Prompt 模板设计、Few-shot、CoT 等模式 |

### 工作流自动化

| Skill | 说明 |
|-------|------|
| `github-release` | CHANGELOG → Release Notes → Draft Release |
| `version-bump` | patch/minor/major 版本升级 + git commit + tag |

### 工具集成

| Skill | 说明 |
|-------|------|
| `jetbrains-skill` | IDE 索引搜索、代码检查、重构、运行配置 |

### 规则与流程（按需加载）

| Skill | 说明 |
|-------|------|
| `plan-code-workflow` | 非平凡任务的 Plan/Code 工作流（如何推进、何时切模式） |
| `testing-tdd` | 严格的 Red-Green-Refactor 与测试真实性原则 |
| `docs-system` | `docs/` 文档分类、索引、postmortem 与上下文落盘规范 |
| `implementation-gates` | Phase -1 门禁清单与例外流程 |
| `mcp-services` | MCP 每个服务的详细用法与组合模式 |

## 创建新 Skill

参考 `cfg/templates/spec/agent-skills-spec.md` 规范，或使用初始化脚本：

```bash
python3 cfg/templates/skills/create-skill/scripts/init_skill.py <skill-name> --path cfg/templates/skills
```

创建后运行 `./agent-tool.sh cfg refresh` 同步到三端。
