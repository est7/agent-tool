# 统一配置目录 ($AGENT_HOME)

这是个人的「Agent 配置单一真相（Single Source of Truth）」目录，用来集中管理：

- 全局说明书：`AGENTS.md`（persona + 编码规则）
- 通用命令模板：`commands/`（Slash 命令 / prompts）
- 可复用 Skills：`skills/`
- MCP 统一配置：`mcp.json`（1mcp 网关配置）

当前主要服务于三类客户端：

- Claude Code
- Codex CLI / Codex in IDE
- Gemini CLI / Code Assist

---

## 目录结构约定

```text
$AGENT_HOME
├── AGENTS.md                 # 用户级 AGENTS 说明（本目录的"总纲"）
├── README.md                 # 本说明文件（可按个人习惯修改）
├── mcp/                      # MCP 相关目录
│   ├── mcp.json              # 1mcp 统一配置（所有 MCP servers 定义在此）
│   ├── bin/                  # 1mcp 二进制（由 install 创建）
│   └── logs/                 # 1mcp 日志（由 start 创建）
├── skills/
│   ├── shared/               # Claude / Codex 共享 Skill
│   │   └── sayhello/         # 示例 Skill：验证管线用
│   ├── claude-only/          # 仅 Claude 使用
│   └── codex-only/           # 仅 Codex 使用
├── commands/
│   ├── shared/               # 通用 Slash 命令
│   │   └── plan.md           # 示例：/plan 任务规划命令
│   ├── claude-only/          # 仅 Claude 使用
│   ├── codex-only/           # 仅 Codex 使用
│   └── gemini-only/          # 仅 Gemini 使用
├── output-styles/
│   ├── shared/               # 通用输出风格（Claude / Codex 等共享）
│   └── claude-only/          # 仅 Claude 使用的输出风格
├── hooks/
│   └── claude/               # Claude Code hooks
└── agents/
    └── claude/               # Claude Code 自定义 subagents
```

你可以把 `$AGENT_HOME` 自己放在一个 Git 仓库（例如 `~/.agents`），长期维护个人的命令与 Skills。

---

## 快速开始

### 1. 全局初始化

```bash
# 在 agent-tool 仓库中
./agent-tool.sh cfg init        # 初始化目录结构 + 建立软链接
./agent-tool.sh cfg selftest -v # 自检配置是否正确
```

作用：

- 初始化 `$AGENT_HOME` 的目录结构与示例文件（仅在不存在时创建，不覆盖已有内容）
- 为三类客户端建立指向 `$AGENT_HOME` 的软链接
- 在各客户端配置 1mcp HTTP 端点

### 2. 安装并启动 1mcp

```bash
./agent-tool.sh cfg 1mcp install   # 下载安装 1mcp 二进制
./agent-tool.sh cfg 1mcp start     # 启动 1mcp 服务（后台运行）
./agent-tool.sh cfg 1mcp status    # 查看运行状态
```

### 3. 设置开机自启（可选）

```bash
./agent-tool.sh cfg 1mcp enable    # macOS: launchd, Linux: systemd
```

---

## 1mcp 统一 MCP 网关

### 什么是 1mcp？

1mcp 是一个统一的 MCP 网关服务，它：

- 在本地启动一个 HTTP 服务（默认端口 3050）
- 读取 `~/.agents/mcp/mcp.json` 中定义的所有 MCP servers
- 提供统一的 HTTP 端点供各 Agent CLI 连接

### 为什么用 1mcp？

**之前的方式（MCP snippet）**：
- 每个项目需要单独配置 `.mcp.json`、`.gemini/settings.json`、`.codex/config.toml`
- 相同的 MCP servers 需要在多处重复配置
- 新增 MCP server 需要更新所有项目

**现在的方式（1mcp 网关）**：
- 所有 MCP servers 集中定义在 `~/.agents/mcp/mcp.json`
- 各 Agent CLI 只需连接 `http://127.0.0.1:3050/mcp` 一个端点
- 新增 MCP server 只需修改 `mcp.json` 并重启 1mcp

### mcp.json 配置示例

```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "tags": ["core", "all"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "tags": ["core", "all", "search"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "tags": ["core", "all"]
    },
    "claudecode-mcp-async": {
      "command": "uvx",
      "args": ["claudecode-mcp-async"],
      "tags": ["agent-cli", "all"]
    },
    "codex-mcp-async": {
      "command": "uvx",
      "args": ["codex-mcp-async"],
      "tags": ["agent-cli", "all"]
    },
    "gemini-cli-mcp-async": {
      "command": "uvx",
      "args": ["gemini-cli-mcp-async"],
      "tags": ["agent-cli", "all"]
    }
  }
}
```

### Tags 与 Preset

MCP servers 通过 tags 分类，支持在项目级别使用 preset 过滤：

| Preset | Tags | 包含的 Servers |
|--------|------|---------------|
| `all` | 全部 | 6 个（默认） |
| `core` | core | sequential-thinking, context7, memory |
| `agent-cli` | agent-cli | claudecode/codex/gemini-cli-mcp-async |

### 常用命令

```bash
./agent-tool.sh cfg 1mcp install        # 安装 1mcp
./agent-tool.sh cfg 1mcp start          # 启动服务
./agent-tool.sh cfg 1mcp stop           # 停止服务
./agent-tool.sh cfg 1mcp restart        # 重启服务（修改 mcp.json 后）
./agent-tool.sh cfg 1mcp status         # 查看状态
./agent-tool.sh cfg 1mcp logs           # 查看日志（最近 50 行）
./agent-tool.sh cfg 1mcp logs -f        # 实时跟踪日志
./agent-tool.sh cfg 1mcp enable         # 设置开机自启
./agent-tool.sh cfg 1mcp disable        # 取消开机自启
./agent-tool.sh cfg 1mcp init-project   # 在项目创建 .1mcprc（默认 preset: all）
./agent-tool.sh cfg 1mcp init-project -p core  # 使用 core preset
```

### 项目级配置 (.mcp.json 和 .1mcprc)

在项目根目录创建配置文件，用于项目级 MCP 设置：

```bash
# 生成两个文件：.mcp.json + .1mcprc
./agent-tool.sh cfg 1mcp init-project              # 默认 all
./agent-tool.sh cfg 1mcp init-project -p core      # 只用 core servers
./agent-tool.sh cfg 1mcp init-project -p agent-cli # 只用跨 CLI 协作 servers

# 使用自定义过滤
./agent-tool.sh cfg 1mcp init-project -f "core OR agent-cli"

# 只生成 .1mcprc（不生成 .mcp.json）
./agent-tool.sh cfg 1mcp init-project --1mcprc-only
```

生成的 `.mcp.json`（Claude Code 项目级配置）：

```json
{
  "mcpServers": {
    "1mcp": {
      "type": "http",
      "url": "http://127.0.0.1:3050/mcp"
    }
  }
}
```

生成的 `.1mcprc`（1mcp proxy 配置）：

```json
{
  "preset": "all"
}
```

### 配置文件位置

| 文件 | 说明 |
|------|------|
| `~/.agents/mcp/mcp.json` | MCP servers 唯一可信源 |
| `~/.config/1mcp/mcp.json` | 软链接 → `~/.agents/mcp/mcp.json` |
| `<project>/.mcp.json` | Claude Code 项目级配置（指向 1mcp） |
| `<project>/.1mcprc` | 1mcp proxy 配置（preset 过滤） |

---

## 输出风格（output-styles）

`output-styles/` 用于存放 Claude / Codex 等客户端可以直接选择的「输出风格」 Markdown 文件。

- 实际生效路径是 `$AGENT_HOME/output-styles/`
- Claude Desktop / Claude Web 会从 `~/.claude/output-styles/` 读取，本仓库通过软链把它指向 `$AGENT_HOME/output-styles/`
- 推荐目录划分：
  - `output-styles/shared/`：通用输出风格，Claude / Codex 等都可以复用
  - `output-styles/claude-only/`：仅 Claude 使用的输出风格

---

## 刷新配置（新增 command/skill 后）

```bash
./agent-tool.sh cfg refresh   # 刷新软链接
```

等价于 `cfg/install_symlinks.sh -U`，仅同步新增的 commands 和 skills，不会覆盖已有配置。

---

## 卸载

```bash
./agent-tool.sh cfg 1mcp disable  # 取消开机自启
./agent-tool.sh cfg 1mcp stop     # 停止服务
./cfg/install_symlinks.sh -u -v   # 只删除软链，不删除 $AGENT_HOME 本身
```

---

## 更多信息

- 1mcp 官方文档：https://docs.1mcp.app/
- agent-tool 仓库：运行 `./agent-tool.sh --help` 查看所有命令
