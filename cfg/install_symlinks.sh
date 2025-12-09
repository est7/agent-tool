#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# ~/scripts/agent-tool/cfg/install_symlinks.sh
# 初始化统一配置目录结构，并为：
#   - Claude Code
#   - Codex CLI
#   - Gemini CLI
# 建立指向统一配置目录的软链接
# ═══════════════════════════════════════════════════════════════════════════════

AGENT_HOME="${AGENT_HOME:-${HOME}/.agents}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 标志位
DRY_RUN=false
VERBOSE=false
FORCE=false
UPGRADE=false

# ─────────────────────────────────────────────────────────────────────────────
# 通用工具函数
# ─────────────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
用法: $(basename "$0") [选项]

选项:
  -n, --dry-run     只显示将要执行的操作，不实际修改任何文件
  -v, --verbose     显示详细输出
  -f, --force       强制覆盖已有的非软链接目标（危险，谨慎使用）
  -U, --upgrade     仅刷新软链接（新增 command/skill 后同步用）
  -u, --uninstall   移除由本脚本创建的软链接
  -h, --help        显示本帮助信息

环境变量:
  AGENT_HOME        统一配置仓库路径（默认: ~/.agents）
EOF
  exit 0
}

log_info()    { echo -e "${BLUE}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1" >&2; }
log_verbose() { $VERBOSE && echo "    … $1" || true; }

ensure_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    log_verbose "目录已存在: $dir"
  else
    if $DRY_RUN; then
      log_verbose "将创建目录: $dir"
    else
      mkdir -p "$dir"
      log_verbose "已创建目录: $dir"
    fi
  fi
}

# 安全创建软链接：只会覆盖软链接；真实文件/目录默认不动，除非 --force
safe_link() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    log_warn "源文件不存在，跳过: $src"
    return 1
  fi

  if $DRY_RUN; then
    log_verbose "将建立软链接: $dest -> $src"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    rm -f "$dest"
    log_verbose "已移除已有软链接: $dest"
  elif [[ -e "$dest" ]]; then
    if ! $FORCE; then
      log_warn "目标已存在且不是软链接，跳过（使用 --force 可覆盖）: $dest"
      return 0
    fi
    rm -rf "$dest"
    log_warn "已强制删除原有路径: $dest"
  fi

  ln -snf "$src" "$dest"
  log_verbose "已建立软链接: $dest -> $src"
}

# 将目录中的内容（非递归）逐个软链接过去
link_dir_contents() {
  local src_dir="$1"
  local dest_dir="$2"
  local pattern="${3:-*}"

  [[ -d "$src_dir" ]] || return 0

  shopt -s nullglob
  for item in "$src_dir"/$pattern; do
    local name
    name="$(basename "$item")"
    safe_link "$item" "$dest_dir/$name"
  done
  shopt -u nullglob
}

# 删除某目录下指向 AGENT_HOME 的软链接
remove_links_pointing_to_ai() {
  local dir="$1"

  [[ -d "$dir" ]] || return 0

  find "$dir" -maxdepth 1 -type l 2>/dev/null | while read -r link; do
    local target
    target="$(readlink "$link" || true)"
    if [[ "$target" == "${AGENT_HOME}"* ]]; then
      if $DRY_RUN; then
        log_verbose "将删除软链接: $link -> $target"
      else
        rm -f "$link"
        log_verbose "已删除软链接: $link -> $target"
      fi
    fi
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# 初始化统一配置目录结构（幂等，不覆盖已有文件）
# ─────────────────────────────────────────────────────────────────────────────

init_ai_home_structure() {
  log_info "检查并初始化 AGENT_HOME 目录结构: $AGENT_HOME"

  ensure_dir "$AGENT_HOME"

  # 顶层 AGENTS.md
  if [[ ! -f "${AGENT_HOME}/AGENTS.md" ]]; then
    local agents_md_template="${SCRIPT_DIR}/templates/AGENTS.md"
    if [[ -f "${agents_md_template}" ]]; then
      if $DRY_RUN; then
        log_verbose "将从模板复制 AGENTS.md: ${agents_md_template} -> ${AGENT_HOME}/AGENTS.md"
      else
        cp "${agents_md_template}" "${AGENT_HOME}/AGENTS.md"
        log_verbose "已从模板复制 AGENTS.md"
      fi
    else
      if $DRY_RUN; then
        log_verbose "未找到 AGENTS.md 模板，将使用内联默认内容创建"
      else
        cat > "${AGENT_HOME}/AGENTS.md" <<'EOF'
# AGENTS.md

## 我是谁（Who I am）
- 在这里描述你的背景（例如：Android/Kotlin 高级、iOS/Swift 入门、Web/Golang/Rust 爱好者等）

## 全局编码原则（Global coding principles）
- 示例：
  - 正确性 > 可维护性 > 性能 > 简洁
  - Kotlin：使用协程 + Flow，避免过时框架 —— 在这里写清楚
  - Swift：首选 Swift Concurrency，避免遗留 Rx 等
- 写清楚你希望 AI 遵守的「底线规则」

## 工作流默认约定（Workflow defaults）
- 示例：
  - 修改代码前先给方案，再给最小 diff
  - 所有改动都要附带测试思路 / 验证步骤
  - 不要在未经确认的情况下执行破坏性 shell 命令

## 工具与环境（Tools）
- 示例：
  - 主力 IDE：Android Studio / IntelliJ / VS Code
  - 构建工具：Android 使用 Gradle，Web 使用 pnpm，等等
- 这里主要是帮助各个 Agent 理解你真实的开发环境
EOF
        log_verbose "已创建 AGENTS.md 模板（内联默认内容）"
      fi
    fi
  else
    log_verbose "AGENTS.md 已存在，保持不变"
  fi

  # 顶层 README.md：说明目录结构 + 三件套脚本 + 推荐工作流
  if [[ ! -f "${AGENT_HOME}/README.md" ]]; then
    local readme_template="${SCRIPT_DIR}/templates/README.md"
    if [[ -f "${readme_template}" ]]; then
      if $DRY_RUN; then
        log_verbose "将从模板复制 README.md: ${readme_template} -> ${AGENT_HOME}/README.md"
      else
        cp "${readme_template}" "${AGENT_HOME}/README.md"
        log_verbose "已从模板复制 README.md"
      fi
    else
      if $DRY_RUN; then
        log_verbose "未找到 README.md 模板，将使用内联默认内容创建"
      else
        cat > "${AGENT_HOME}/README.md" <<'EOF'
# 统一配置目录 ($AGENT_HOME)

这是个人的「AI 配置单一真相（Single Source of Truth）」仓库，用来统一管理：

- 全局说明书：AGENTS.md
- 各种 Slash 命令 / Prompt 模板：commands/
- 各种 Skill 定义：skills/
- MCP 配置 Snippet：mcp/

目前主要面向三套工具：

- Claude Code
- Codex CLI / Codex in IDE
- Gemini CLI / Code Assist

---

## 目录结构约定

```text
$AGENT_HOME
├── AGENTS.md                 # 全局 persona + 编码规则（被多工具读取）
├── README.md                 # 本说明文件
├── skills/
│   ├── shared/               # Claude + Codex 等共享的 Skill
│   │   └── sayhello/         # 示例 Skill：用于验证管线
│   │       ├── SKILL.md
│   │       └── scripts/run.sh
│   ├── claude-only/          # 仅 Claude 使用的 Skill
│   └── codex-only/           # 仅 Codex 使用的 Skill
├── commands/
│   ├── shared/               # 通用 Slash 命令
│   │   └── review.md         # 示例：/review 统一 Code Review 模板
│   ├── claude-only/          # 仅 Claude 使用的命令
│   ├── codex-only/           # 仅 Codex 使用的命令
│   └── gemini-only/          # 仅 Gemini 使用的命令/说明
├── output-styles/
│   ├── shared/               # 通用输出风格（Claude/Codex 等可共享）
│   └── claude-only/          # 仅 Claude 使用的输出风格
├── mcp/
│   ├── claude.json.snippet   # Claude 用的 .mcp.json 片段（不含密钥）
│   ├── gemini.json.snippet   # Gemini 用的 settings.json 片段（不含密钥）
│   └── codex.toml.snippet    # Codex 用的 config.toml 片段（只放 [mcp_servers.*]）
└── .mcp.json                 # 把 $AGENT_HOME 本身当成一个“项目”时的 MCP 配置骨架
````

---

## 三件套脚本说明（脚本位于 ~/scripts/agent-tool/cfg 和 doctor）

### 1. 全局初始化：install_symlinks.sh

位置：`~/scripts/agent-tool/cfg/install_symlinks.sh`（或通过 `agent-tool cfg init` 调用）

作用：

* 初始化 `$AGENT_HOME` 基本目录结构和示例文件（仅在不存在时创建）
* 为三套工具建立「指向 $AGENT_HOME 的软链接」：

  * `~/.claude/CLAUDE.md -> $AGENT_HOME/AGENTS.md`
  * `~/.claude/commands/* -> $AGENT_HOME/commands/{shared,claude-only}`
  * `~/.claude/skills/*   -> $AGENT_HOME/skills/{shared,claude-only}`
  * `~/.claude/output-styles/* -> $AGENT_HOME/output-styles/{shared,claude-only}`
  * `~/.codex/prompts/*   -> $AGENT_HOME/commands/{shared,codex-only}`
  * `~/.codex/skills/*    -> $AGENT_HOME/skills/{shared,codex-only}`
  * `~/.codex/AGENTS.md   -> $AGENT_HOME/AGENTS.md`
  * `~/.gemini/AGENTS.md  -> $AGENT_HOME/AGENTS.md`
* 如果已安装过，可以用 `--uninstall` 把这些软链接干净移除

示例：

```bash
# 只看看会做什么（推荐新机器先这样跑一遍）
~/scripts/agent-tool/cfg/install_symlinks.sh -n -v

# 实际执行全局初始化（新机器第一次）
~/scripts/agent-tool/cfg/install_symlinks.sh -v

# 如果某些路径已被手工文件占用，且你确认要用统一配置目录接管：
~/scripts/agent-tool/cfg/install_symlinks.sh -v --force

# 想撤销（只移除由本脚本创建的软链接，不删真实目录/文件）
~/scripts/agent-tool/cfg/install_symlinks.sh -u -v
```

### 2. 项目级 MCP：project_mcp_setup.sh

位置：`~/scripts/agent-tool/cfg/project_mcp_setup.sh`（或通过 `agent-tool cfg mcp` 调用）

在「项目根目录」中运行，用 `$AGENT_HOME/mcp` 下的 snippet 生成项目级配置：

* Claude: `./.mcp.json`
* Gemini: `./.gemini/settings.json`
* Codex: `./.codex/config.toml`（配合项目内 `CODEX_HOME=./.codex` 使用）

示例：

```bash
cd /path/to/your/project
~/scripts/agent-tool/cfg/project_mcp_setup.sh -v
```

### 3. 自检：cfg_doctor.sh

位置：`~/scripts/agent-tool/doctor/cfg_doctor.sh`（或通过 `agent-tool cfg selftest` / `agent-tool doctor <platform>` 调用）

作用：

* 检查 `$AGENT_HOME` 是否存在关键文件/目录
* 校验 `mcp/*.json.snippet` 的 JSON 语法（依赖 jq）
* 检查几个关键软链接是否存在、是否为 symlink

示例：

```bash
~/scripts/agent-tool/doctor/cfg_doctor.sh -v
```

---

## 新机器上的推荐工作流

1. 克隆配置仓库：

   ```bash
   git clone git@github.com:yourname/dot-agents.git ~/.agents
   ```

2. 全局初始化：

   ```bash
   ~/scripts/agent-tool/cfg/install_symlinks.sh -n -v
   ~/scripts/agent-tool/cfg/install_symlinks.sh -v
   ```

3. 针对常用项目，在项目根目录生成项目级 MCP 配置：

   ```bash
   cd ~/workspace/your-project
   ~/scripts/agent-tool/cfg/project_mcp_setup.sh -v
   ```

4. 最后跑一次自检确认整体环境健康：

   ```bash
   ~/scripts/agent-tool/doctor/cfg_doctor.sh -v
   ```

EOF
        log_verbose "已创建 README.md（内联默认内容）"
      fi
    fi
  else
    log_verbose "README.md 已存在，保持不变"
  fi

# 核心目录结构

ensure_dir "${AGENT_HOME}/skills/shared"
ensure_dir "${AGENT_HOME}/skills/claude-only"
ensure_dir "${AGENT_HOME}/skills/codex-only"

ensure_dir "${AGENT_HOME}/output-styles/shared"
ensure_dir "${AGENT_HOME}/output-styles/claude-only"

ensure_dir "${AGENT_HOME}/commands/shared"
ensure_dir "${AGENT_HOME}/commands/claude-only"
ensure_dir "${AGENT_HOME}/commands/codex-only"
ensure_dir "${AGENT_HOME}/commands/gemini-only"

ensure_dir "${AGENT_HOME}/hooks/claude"

ensure_dir "${AGENT_HOME}/agents/claude"

ensure_dir "${AGENT_HOME}/mcp"

  # 示例命令：/review（优先从模板目录复制）

  if [[ ! -f "${AGENT_HOME}/commands/shared/review.md" ]]; then
    local review_template="${SCRIPT_DIR}/templates/commands/shared/review.md"
    if [[ -f "${review_template}" ]]; then
      if $DRY_RUN; then
        log_verbose "将从模板复制示例命令: ${review_template} -> ${AGENT_HOME}/commands/shared/review.md"
      else
        cp "${review_template}" "${AGENT_HOME}/commands/shared/review.md"
        log_verbose "已从模板复制示例命令: review.md"
      fi
    else
      if $DRY_RUN; then
        log_verbose "未找到 review 模板，将使用内联默认内容创建示例命令: commands/shared/review.md"
      else
        cat > "${AGENT_HOME}/commands/shared/review.md" <<'EOF'

# review

你现在扮演一名「严格但理性的高级工程师」。

任务：

* 针对当前变更做 Code Review。
* 优先关注：

  * 架构边界是否被破坏（模块间耦合是否合理）
  * 可测试性（是否容易写单测/集成测试）
  * 性能风险（明显的 N+1、主线程重活等）
* 给出「最小可审阅 diff」建议，而不是大面积重写。
* 最后用一句话总结风险等级：low / medium / high，并给出理由。
EOF
        log_verbose "已创建示例命令: review.md"
      fi
    fi
  fi

  # 示例命令：/enhance（优先从模板目录复制）

  if [[ ! -f "${AGENT_HOME}/commands/shared/enhance.md" ]]; then
    local enhance_template="${SCRIPT_DIR}/templates/commands/shared/enhance.md"
    if [[ -f "${enhance_template}" ]]; then
      if $DRY_RUN; then
        log_verbose "将从模板复制示例命令: ${enhance_template} -> ${AGENT_HOME}/commands/shared/enhance.md"
      else
        cp "${enhance_template}" "${AGENT_HOME}/commands/shared/enhance.md"
        log_verbose "已从模板复制示例命令: enhance.md"
      fi
    else
      if $DRY_RUN; then
        log_verbose "未找到 enhance 模板，将使用内联默认内容创建示例命令: commands/shared/enhance.md"
      else
        cat > "${AGENT_HOME}/commands/shared/enhance.md" <<'EOF'
# enhance

---

description: "使用 prompt-enhancer MCP 优化指令并经用户确认后再执行。"

---

你现在扮演一名「Prompt 优化助手 + 执行代理」。

目标：在真正开始执行用户任务之前，先用 MCP 的 `prompt-enhancer` 工具优化用户的原始指令，并让用户确认增强后的版本（寸止），再据此展开后续工作。

工作流要求：

1. 把用户通过 `/enhance ...` 提供的文本视为原始指令 `origin_prompt`。
2. 调用名为 `prompt-enhancer` 的 MCP 工具，对 `origin_prompt` 做一次优化。向该工具发送的内容应仅包含原始指令文本本身。
3. 从工具返回结果中，解析出 `<augment-enhanced-prompt>...</augment-enhanced-prompt>` 标签内的增强后指令，把它记为 `enhanced_prompt`。
4. 先「寸止」给出结果：用中文简要说明 `enhanced_prompt` 相比原始指令有哪些关键优化（例如更清晰的目标、范围、约束或安全提醒），并完整展示 `enhanced_prompt`，此时不要开始执行任务。
5. 明确询问用户是否接受这个增强版本：例如提示用户回复 `OK` / `Y` 或给出修改意见。
6. 只有在用户确认后，才把 `enhanced_prompt` 视为真正的任务指令，继续后续的推理、工具调用和实现工作；后续所有操作都应基于 `enhanced_prompt`，而不是 `origin_prompt`。
7. 如果用户对增强结果不满意或提出新要求，根据用户的补充重新调用 `prompt-enhancer` 调整指令，再次进入确认流程。

当你看到用户以 `/enhance ...` 的形式发起请求时，请严格按照上述工作流执行，而不是直接处理原始指令。
EOF
        log_verbose "已创建示例命令: enhance.md"
      fi
    fi
  fi

  # 示例 Skill：sayhello（从模板目录复制，用于验证 Skill 管线）

  local skill_dir="${AGENT_HOME}/skills/shared/sayhello"
  local template_skill_dir="${SCRIPT_DIR}/templates/skills/sayhello"

  if [[ -d "${template_skill_dir}" ]]; then
    ensure_dir "${skill_dir}"
    if $DRY_RUN; then
      log_verbose "将从模板复制示例 Skill: ${template_skill_dir} -> ${skill_dir}"
    else
      cp -R "${template_skill_dir}/." "${skill_dir}/"
      log_verbose "已从模板复制示例 Skill: sayhello"
    fi
  else
    log_verbose "未找到 sayhello 模板目录: ${template_skill_dir}，跳过示例 Skill 初始化"
  fi

# MCP snippet 占位文件（不含密钥）

if [[ ! -f "${AGENT_HOME}/mcp/claude.json.snippet" ]]; then
if $DRY_RUN; then
log_verbose "将创建 mcp/claude.json.snippet"
else
cat > "${AGENT_HOME}/mcp/claude.json.snippet" <<'EOF'
{
  "mcpServers": {
    "claudecode-mcp-async": {
      "args": [
        "claudecode-mcp-async"
      ],
      "command": "uvx",
      "env": {}
    },
    "codex-mcp-async": {
      "args": [
        "codex-mcp-async"
      ],
      "command": "uvx",
      "env": {}
    },
    "exa-mcp": {
      "args": [
        "-y",
        "mcp-remote",
        "https://mcp.exa.ai/mcp"
      ],
      "command": "npx"
    },
    "gemini-cli-mcp-async": {
      "args": [
        "gemini-cli-mcp-async"
      ],
      "command": "uvx",
      "env": {}
    },
    "memory": {
      "args": [
        "-y",
        "@modelcontextprotocol/server-memory"
      ],
      "command": "npx",
      "type": "stdio"
    },
    "sequential-thinking": {
      "args": [
        "-y",
        "@modelcontextprotocol/server-sequential-thinking"
      ],
      "command": "npx",
      "type": "stdio"
    }
  }
}
EOF
log_verbose "已创建 mcp/claude.json.snippet"
fi
fi

if [[ ! -f "${AGENT_HOME}/mcp/codex.toml.snippet" ]]; then
if $DRY_RUN; then
log_verbose "将创建 mcp/codex.toml.snippet"
else
cat > "${AGENT_HOME}/mcp/codex.toml.snippet" <<'EOF'

# 示例 Codex MCP 片段（请合并到项目级 .codex/config.toml 中）

# [mcp_servers.example]

# command = "echo"

# args = ["示例 MCP server，请替换为真实配置"]

EOF
log_verbose "已创建 mcp/codex.toml.snippet"
fi
fi

if [[ ! -f "${AGENT_HOME}/mcp/gemini.json.snippet" ]]; then
if $DRY_RUN; then
log_verbose "将创建 mcp/gemini.json.snippet"
else
cat > "${AGENT_HOME}/mcp/gemini.json.snippet" <<'EOF'
{
  "mcpServers": {
    "claudecode-mcp-async": {
      "args": [
        "claudecode-mcp-async"
      ],
      "command": "uvx",
      "env": {}
    },
    "codex-mcp-async": {
      "args": [
        "codex-mcp-async"
      ],
      "command": "uvx",
      "env": {}
    },
    "exa-mcp": {
      "args": [
        "-y",
        "mcp-remote",
        "https://mcp.exa.ai/mcp"
      ],
      "command": "npx"
    },
    "gemini-cli-mcp-async": {
      "args": [
        "gemini-cli-mcp-async"
      ],
      "command": "uvx",
      "env": {}
    },
    "memory": {
      "args": [
        "-y",
        "@modelcontextprotocol/server-memory"
      ],
      "command": "npx",
      "type": "stdio"
    },
    "sequential-thinking": {
      "args": [
        "-y",
        "@modelcontextprotocol/server-sequential-thinking"
      ],
      "command": "npx",
      "type": "stdio"
    }
  },
  "contextFileName": ["AGENTS.md"]
}
EOF
log_verbose "已创建 mcp/gemini.json.snippet"
fi
fi

# 把 $AGENT_HOME 本身当成一个“项目”时的 .mcp.json 骨架

if [[ ! -f "${AGENT_HOME}/.mcp.json" ]]; then
if $DRY_RUN; then
log_verbose "将创建 ${AGENT_HOME}/.mcp.json 骨架"
else
cat > "${AGENT_HOME}/.mcp.json" <<'EOF'
{
"mcpServers": { }
}
EOF
log_verbose "已创建 ${AGENT_HOME}/.mcp.json 骨架"
fi
fi
}

# ─────────────────────────────────────────────────────────────────────────────

# 为 Claude / Codex / Gemini 建立软链接

# ─────────────────────────────────────────────────────────────────────────────

setup_claude() {
log_info "配置 Claude Code..."
local claude_home="${HOME}/.claude"

if ! $DRY_RUN; then
mkdir -p "$claude_home"
fi

# 全局说明书

safe_link "${AGENT_HOME}/AGENTS.md" "$claude_home/CLAUDE.md"

# Commands: shared + claude-only

if ! $DRY_RUN; then
mkdir -p "$claude_home/commands"
fi
link_dir_contents "${AGENT_HOME}/commands/shared" "$claude_home/commands" "*.md"
link_dir_contents "${AGENT_HOME}/commands/claude-only" "$claude_home/commands" "*.md"

# Skills: shared + claude-only

if ! $DRY_RUN; then
mkdir -p "$claude_home/skills"
fi
link_dir_contents "${AGENT_HOME}/skills/shared" "$claude_home/skills"
link_dir_contents "${AGENT_HOME}/skills/claude-only" "$claude_home/skills"

# Output styles: shared + claude-only

if ! $DRY_RUN; then
mkdir -p "$claude_home/output-styles"
fi
link_dir_contents "${AGENT_HOME}/output-styles/shared" "$claude_home/output-styles"
link_dir_contents "${AGENT_HOME}/output-styles/claude-only" "$claude_home/output-styles"

# Hooks: Claude-only
if ! $DRY_RUN; then
  mkdir -p "$claude_home/hooks"
fi
link_dir_contents "${AGENT_HOME}/hooks/claude" "$claude_home/hooks"

# Sub agents: Claude-only
if ! $DRY_RUN; then
  mkdir -p "$claude_home/agents"
fi
link_dir_contents "${AGENT_HOME}/agents/claude" "$claude_home/agents"

if [[ -f "${AGENT_HOME}/mcp/claude.json.snippet" ]]; then
log_verbose "提示: Claude MCP snippet 位于 ${AGENT_HOME}/mcp/claude.json.snippet，可配合 project_mcp_setup.sh 在项目层使用。"
fi

log_success "Claude Code 已配置完成"
}

setup_codex() {
log_info "配置 Codex CLI..."
local codex_home="${CODEX_HOME:-${HOME}/.codex}"

if ! $DRY_RUN; then
mkdir -p "$codex_home"
fi

# Prompts (slash commands): shared + codex-only

if ! $DRY_RUN; then
mkdir -p "$codex_home/prompts"
fi
link_dir_contents "${AGENT_HOME}/commands/shared" "$codex_home/prompts" "*.md"
link_dir_contents "${AGENT_HOME}/commands/codex-only" "$codex_home/prompts" "*.md"

# Skills: shared + codex-only

if ! $DRY_RUN; then
mkdir -p "$codex_home/skills"
fi
link_dir_contents "${AGENT_HOME}/skills/shared" "$codex_home/skills"
link_dir_contents "${AGENT_HOME}/skills/codex-only" "$codex_home/skills"

# 全局说明书，方便在 Codex 里打开查看

safe_link "${AGENT_HOME}/AGENTS.md" "$codex_home/AGENTS.md"

if [[ -f "${AGENT_HOME}/mcp/codex.toml.snippet" ]]; then
log_verbose "提示: Codex MCP snippet 位于 ${AGENT_HOME}/mcp/codex.toml.snippet，可配合 project_mcp_setup.sh 在项目层使用。"
fi

log_success "Codex CLI 已配置完成"
}

setup_gemini() {
log_info "配置 Gemini CLI..."
local gemini_home="${HOME}/.gemini"
local settings="$gemini_home/settings.json"

if ! $DRY_RUN; then
mkdir -p "$gemini_home"
fi

# settings.json: 确保 contextFileName 包含 AGENTS.md

if $DRY_RUN; then
log_verbose "将检查/更新 $settings 中的 contextFileName"
else
if [[ ! -f "$settings" ]]; then
cat > "$settings" <<'EOF'
{
"contextFileName": ["AGENTS.md", "GEMINI.md"]
}
EOF
log_verbose "已创建: $settings"
else
if command -v jq &>/dev/null; then
local tmp="${settings}.tmp.$$"
jq '
.contextFileName = (
(.contextFileName // []) + ["AGENTS.md", "GEMINI.md"] | unique
)
' "$settings" > "$tmp" && mv "$tmp" "$settings"
log_verbose "已更新 $settings 中的 contextFileName"
else
if ! grep -q '"contextFileName"' "$settings" 2>/dev/null; then
log_warn "未找到 jq。请手动在 $settings 中添加 contextFileName 字段（包含 AGENTS.md）。"
else
log_warn "未找到 jq。settings.json 已存在，请确认其中的 contextFileName 已包含 AGENTS.md。"
fi
fi
fi
fi

# 软链接 AGENTS.md 到 ~/.gemini，用于手工查看或其他工具使用

safe_link "${AGENT_HOME}/AGENTS.md" "$gemini_home/AGENTS.md"

if [[ -f "${AGENT_HOME}/mcp/gemini.json.snippet" ]]; then
log_verbose "提示: Gemini MCP snippet 位于 ${AGENT_HOME}/mcp/gemini.json.snippet，可配合 project_mcp_setup.sh 在项目层使用。"
fi

log_success "Gemini CLI 已配置完成"
}

# ─────────────────────────────────────────────────────────────────────────────

# 卸载：只移除由本脚本创建的软链接，保留真实目录/文件

# ─────────────────────────────────────────────────────────────────────────────

uninstall() {
log_info "开始移除由本脚本创建的软链接..."

# 顶层软链接

local top_links=(
"${HOME}/.claude/CLAUDE.md"
"${HOME}/.codex/AGENTS.md"
"${HOME}/.gemini/AGENTS.md"
)

for link in "${top_links[@]}"; do
if [[ -L "$link" ]]; then
if $DRY_RUN; then
log_verbose "将删除: $link"
else
rm -f "$link"
log_verbose "已删除: $link"
fi
fi
done

# 目录内部指向 AGENT_HOME 的软链接

remove_links_pointing_to_ai "${HOME}/.claude/commands"
remove_links_pointing_to_ai "${HOME}/.claude/output-styles"
remove_links_pointing_to_ai "${HOME}/.claude/skills"
remove_links_pointing_to_ai "${HOME}/.codex/prompts"
remove_links_pointing_to_ai "${HOME}/.codex/skills"

log_success "卸载完成（只移除了指向 AGENT_HOME 的软链接，未删除任何真实目录/文件）。"
}

# ─────────────────────────────────────────────────────────────────────────────

# Main

# ─────────────────────────────────────────────────────────────────────────────

main() {

# 解析参数

while [[ $# -gt 0 ]]; do
case "$1" in
-n|--dry-run)   DRY_RUN=true; VERBOSE=true ;;
-v|--verbose)   VERBOSE=true ;;
-f|--force)     FORCE=true ;;
-U|--upgrade)   UPGRADE=true ;;
-u|--uninstall) uninstall; exit 0 ;;
-h|--help)      usage ;;
*) log_error "未知选项: $1"; usage ;;
esac
shift
done

$UPGRADE && VERBOSE=true
$DRY_RUN && log_warn "Dry-run 模式：不会进行任何实际修改。"
$FORCE && log_warn "Force 模式开启：可能覆盖已有非软链接路径，请确认你知道自己在做什么。"
$UPGRADE && log_info "升级模式：仅刷新软链接，适合新增 command/skill 后同步。"

# 初始化统一配置目录结构（只在不存在时创建，不覆盖已有文件）

init_ai_home_structure

# 非 dry-run 场景下，确保 AGENTS.md 存在

if ! $DRY_RUN && [[ ! -f "${AGENT_HOME}/AGENTS.md" ]]; then
log_error "初始化后仍未找到 AGENTS.md，请手动检查 $AGENT_HOME"
exit 1
fi

echo ""
setup_claude
echo ""
setup_codex
echo ""
setup_gemini
echo ""

log_success "全部完成：Claude / Codex / Gemini 已指向你的统一配置目录。"
$VERBOSE && echo -e "\n${BLUE}提示:${NC} 新机器上推荐顺序：先运行本脚本，再在项目中运行 project_mcp_setup.sh，最后跑一遍 self_test.sh。"
}

main "$@"
