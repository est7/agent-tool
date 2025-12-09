# 统一配置目录 ($AGENT_HOME)

这是个人的「Agent 配置单一真相（Single Source of Truth）」目录，用来集中管理：

- 全局说明书：`AGENTS.md`（persona + 编码规则）
- 通用命令模板：`commands/`（Slash 命令 / prompts）
- 可复用 Skills：`skills/`
- MCP 配置片段：`mcp/`

当前主要服务于三类客户端：

- Claude Code
- Codex CLI / Codex in IDE
- Gemini CLI / Code Assist

---

## 目录结构约定

```text
$AGENT_HOME
├── AGENTS.md                 # 用户级 AGENTS 说明（本目录的“总纲”）
├── README.md                 # 本说明文件（可按个人习惯修改）
├── skills/
│   ├── shared/               # Claude / Codex 共享 Skill
│   │   └── sayhello/         # 示例 Skill：验证管线用
│   ├── claude-only/          # 仅 Claude 使用
│   └── codex-only/           # 仅 Codex 使用
├── commands/
│   ├── shared/               # 通用 Slash 命令
│   │   └── review.md         # 示例：/review 统一 Code Review 模板
│   ├── claude-only/          # 仅 Claude 使用
│   ├── codex-only/           # 仅 Codex 使用
│   └── gemini-only/          # 仅 Gemini 使用
├── output-styles/
│   ├── shared/               # 通用输出风格（Claude / Codex 等共享）
│   └── claude-only/          # 仅 Claude 使用的输出风格
├── mcp/
│   ├── claude.json.snippet   # 填入到项目 .mcp.json 的片段（不含密钥）
│   ├── gemini.json.snippet   # 填入到项目 .gemini/settings.json 的片段
│   └── codex.toml.snippet    # 填入到项目 .codex/config.toml 的 [mcp_servers.*]
└── .mcp.json                 # 把 $AGENT_HOME 当成“项目”时的 MCP 配置骨架
````

你可以把 `$AGENT_HOME` 自己放在一个 Git 仓库（例如 `~/.agents`），长期维护个人的命令与 Skills。  

---

## 全局初始化（映射到各个客户端）

推荐通过 `agent-tool.sh` 调用，而不是直接跑脚本：

```bash
# 在 agent-tool 仓库中
./agent-tool.sh cfg init        # 等价于 cfg/install_symlinks.sh -v
./agent-tool.sh cfg selftest -v # 调用 doctor/cfg_doctor.sh 自检
```

作用：

- 初始化 `$AGENT_HOME` 的目录结构与示例文件（仅在不存在时创建，不覆盖已有内容）。
- 为三类客户端建立指向 `$AGENT_HOME` 的软链接：
  - Claude：`~/.claude/CLAUDE.md`、`~/.claude/commands/*`、`~/.claude/skills/*` 等
  - Codex：`~/.codex/prompts/*`、`~/.codex/skills/*`、`~/.codex/AGENTS.md`
  - Gemini：`~/.gemini/AGENTS.md`

如需卸载，可使用：

```bash
./cfg/install_symlinks.sh -u -v  # 只删除软链，不删除 $AGENT_HOME 本身
```

---

## 输出风格（output-styles）

`output-styles/` 用于存放 Claude / Codex 等客户端可以直接选择的「输出风格」 Markdown 文件。

- 实际生效路径是 `$AGENT_HOME/output-styles/`。
- Claude Desktop / Claude Web 会从 `~/.claude/output-styles/` 读取，本仓库通过软链把它指向 `$AGENT_HOME/output-styles/`。
- 推荐目录划分：
  - `output-styles/shared/`：通用输出风格，Claude / Codex 等都可以复用。
  - `output-styles/claude-only/`：仅 Claude 使用的输出风格。

当前仓库已经在 `cfg/install_symlinks.sh` 中内置了一步「示例输出风格同步」：

- 运行 `agent-tool cfg init` 或直接执行 `cfg/install_symlinks.sh` 时，
- 会把 `cfg/templates/output-styles/` 下的 `*.md` 文件（例如 `linus-engineer.md`、`tech-mentor.md`）
- 复制到 `$AGENT_HOME/output-styles/shared/` 中（若目标文件已存在则不会覆盖）。

之后，这些样式会通过软链出现在：

- `~/.claude/output-styles/`（Claude Desktop / Claude Web 可直接选择）

如果你有新的输出风格，只需：

1. 把 `.md` 文件放到 `$AGENT_HOME/output-styles/shared/` 或 `output-styles/claude-only/`。
2. 或者先放到 `cfg/templates/output-styles/`，再跑一次 `agent-tool cfg init` 或 `cfg/install_symlinks.sh` 让脚本帮你从模板复制一份到 `$AGENT_HOME`。

---

## 在项目中生成 MCP 配置

进入具体项目根目录后，可以用统一入口生成 MCP 配置：

```bash
cd /path/to/your-project

# 通过 agent-tool 封装脚本
./agent-tool.sh cfg mcp -v --claude --gemini --codex
```

等价于运行 `cfg/project_mcp_setup.sh`，它会从 `$AGENT_HOME/mcp` 读取 snippet，在项目内生成：

- `.mcp.json`             （Claude）
- `.gemini/settings.json` （Gemini）
- `.codex/config.toml`    （Codex，需配合 `CODEX_HOME=./.codex`）

所有敏感信息（API Key 等）建议通过环境变量引用，不要直接写在 snippet 或项目配置里。***
