# 1mcp - 统一 MCP 网关

1mcp 是一个 MCP (Model Context Protocol) 统一网关，允许多个 Agent CLI（Claude Code、Codex CLI、Gemini CLI）共享同一套 MCP servers 配置。

## 快速开始

```bash
# 安装 1mcp
agent-tool cfg 1mcp install

# 启动服务
agent-tool cfg 1mcp start

# 在项目中初始化 MCP 配置
cd your-project
agent-tool cfg 1mcp init-project
```

## 内置 MCP Servers

| Server | 类型 | 用途 | Tags |
|--------|------|------|------|
| `sequential-thinking` | command | 结构化思考、任务分解 | core, all |
| `context7` | command | 获取库/框架最新文档 | core, all, search |
| `devtools` | http | Chrome DevTools 协议调试 | web, all |
| `claudecode-mcp-async` | command | 异步调用 Claude Code | agent-cli, all |
| `codex-mcp-async` | command | 异步调用 Codex CLI | agent-cli, all |
| `gemini-cli-mcp-async` | command | 异步调用 Gemini CLI | agent-cli, all |

## Preset 预设

通过 `.1mcprc` 文件控制项目中启用哪些 MCP servers：

| Preset | 包含的 Servers |
|--------|----------------|
| `all` | 全部 6 个 servers（默认） |
| `core` | sequential-thinking, context7 |
| `agent-cli` | claudecode/codex/gemini-cli-mcp-async |
| `web` | devtools |

### 使用 Preset

```bash
# 使用默认 preset (all)
agent-tool cfg 1mcp init-project

# 使用指定 preset
agent-tool cfg 1mcp init-project -p core

# 使用标签过滤表达式
agent-tool cfg 1mcp init-project -f "core OR web"
```

### .1mcprc 配置示例

**使用 preset：**
```json
{
  "preset": "core"
}
```

**使用 filter 表达式：**
```json
{
  "filter": "core OR agent-cli"
}
```

## 命令参考

```bash
agent-tool cfg 1mcp install       # 安装 1mcp binary
agent-tool cfg 1mcp start         # 启动服务
agent-tool cfg 1mcp stop          # 停止服务
agent-tool cfg 1mcp restart       # 重启服务
agent-tool cfg 1mcp status        # 查看状态
agent-tool cfg 1mcp enable        # 开机自启
agent-tool cfg 1mcp disable       # 取消自启
agent-tool cfg 1mcp logs          # 查看日志
agent-tool cfg 1mcp logs -f       # 实时日志
agent-tool cfg 1mcp init-project  # 初始化项目配置
```

## 配置文件

| 文件 | 说明 |
|------|------|
| `~/.agents/mcp/mcp.json` | MCP servers 唯一可信源 |
| `~/.config/1mcp/mcp.json` | 软链接 → ~/.agents/mcp/mcp.json |
| `<project>/.mcp.json` | Claude Code 项目级配置（指向 1mcp） |
| `<project>/.1mcprc` | 1mcp proxy 配置（preset 过滤） |

## devtools 配置

`devtools` server 使用 Chrome DevTools Protocol，需要启动 Chrome 的远程调试端口：

```bash
# macOS
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222

# Linux
google-chrome --remote-debugging-port=9222
```

默认连接 `http://localhost:9222/mcp`。

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ONEMCP_PORT` | 3050 | 1mcp 服务端口 |
| `AGENT_HOME` | ~/.agents | Agent 配置根目录 |

## 更多信息

- [1mcp 官方文档](https://docs.1mcp.app/)
- [MCP 协议规范](https://modelcontextprotocol.io/)
