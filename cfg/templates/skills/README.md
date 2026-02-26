# Skills Templates

English summary: this directory contains skill templates shared across Claude Code, Codex CLI, and Gemini CLI.

---

## 中文说明

本目录包含跨 Agent 共享的 Skill 模板。Skills 是 Claude 自动识别并激活的知识模块，无需手动调用。

## Skill 列表

| Skill | 用途 | 触发方式 |
|-------|------|----------|
| `analyzing-project-health` | 技术债务量化 + 多角色辩论，生成健康评分和改进路线图 | 自动 |
| `android-dev-core` | Android 核心开发规则（MVI、Base 类、网络请求等） | 自动 |
| `android-dev-extras` | Android 扩展模板（SmartRefreshLayout、TabLayout+VP2） | 自动 |
| `codex-review` | 调用 Codex CLI 进行代码审核 | `/codex-review` |
| `create-command` | 创建 slash command 指南 | 自动 |
| `create-mcp` | 创建 MCP Server 指南（Python/Node） | 自动 |
| `create-skill` | 创建 Skill 指南 | 自动 |
| `dual-ai-review` | 多 AI 交叉审查（Gemini + Codex） | 自动 |
| `github-release` | 从 CHANGELOG 发布 GitHub Release | `/github-release` |
| `jetbrains-skill` | JetBrains IDE MCP 集成（索引、重构、Inspection） | 自动 |
| `prompt-engineering` | Prompt 工程最佳实践 | 自动 |
| `say-hello` | Skills 管线可用性验证 | `/say-hello` |
| `version-bump` | 版本号升级并提交 git | `/version-bump` |

## 按用途分类

### 项目分析

| Skill | 说明 |
|-------|------|
| `analyzing-project-health` | 6 维度扫描（依赖/文档/测试/安全/架构/代码质量）+ 多角色辩论优先级 |

### Android 开发

| Skill | 说明 |
|-------|------|
| `android-dev-core` | MVI 架构、Base 类体系、Adapter、网络请求规范 |
| `android-dev-extras` | SmartRefreshLayout 刷新、TabLayout+ViewPager2 模板 |

### 代码审查

| Skill | 说明 |
|-------|------|
| `codex-review` | 调用 Codex 命令行审核，自动收集变更上下文 |
| `dual-ai-review` | Gemini + Codex 交叉验证，多视角分析 |

### 元技能（创建 Agent 组件）

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

### 测试

| Skill | 说明 |
|-------|------|
| `say-hello` | 最小可运行示例，验证 Skill 管线是否正常 |

## 创建新 Skill

参考 `cfg/templates/spec/agent-skills-spec.md` 规范，或使用初始化脚本：

```bash
python3 cfg/templates/skills/create-skill/scripts/init_skill.py <skill-name> --path cfg/templates/skills
```

创建后运行 `./agent-tool.sh cfg refresh` 同步到三端。
