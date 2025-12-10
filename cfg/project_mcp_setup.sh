#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# ~/scripts/agent-tool/cfg/project_mcp_setup.sh
#
# 用途：
#   在「项目根目录」下运行，生成 1mcp 项目级配置文件 .1mcprc
#
#   .1mcprc 允许为不同项目配置不同的 MCP server 子集（通过 preset 或 tags 过滤）
#
# 设计原则：
#   - 使用 1mcp 作为统一 MCP 网关
#   - 项目级 .1mcprc 可进 Git 管理
#   - 全局 MCP servers 配置在 ~/.agents/mcp.json
# ═══════════════════════════════════════════════════════════════════════════════

AGENT_HOME="${AGENT_HOME:-${HOME}/.agents}"
PROJECT_ROOT="${PWD}"
ONEMCP_CONFIG="${AGENT_HOME}/mcp.json"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 标志位
DRY_RUN=false
VERBOSE=false
PRESET=""
TAGS=""

log_info()    { echo -e "${BLUE}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1" >&2; }
log_verbose() { $VERBOSE && echo "    … $1" || true; }

usage() {
  cat <<EOF
用法: $(basename "$0") [选项]

说明:
  在【项目根目录】中运行本脚本。
  生成 1mcp 项目级配置文件 .1mcprc，用于过滤全局 MCP servers。

生成的文件:
  .1mcprc         1mcp 项目配置（JSON 格式）

选项:
  --preset NAME   使用预设名称（如果已在 1mcp 中配置了 preset）
  --tags EXPR     标签过滤表达式（如 "core OR async"）
  -n, --dry-run   只显示将要执行的操作，不实际写入
  -v, --verbose   显示详细输出
  -h, --help      显示本帮助信息

示例:
  $(basename "$0")                      # 生成默认 .1mcprc（使用所有 MCP servers）
  $(basename "$0") --tags "core"        # 只使用带 core 标签的 servers
  $(basename "$0") --preset web-dev     # 使用名为 web-dev 的预设

环境变量:
  AGENT_HOME      统一配置仓库路径 (默认: ~/.agents)

提示:
  • 全局 MCP servers 配置在 $AGENT_HOME/mcp.json
  • 使用 'agent-tool cfg 1mcp status' 查看 1mcp 状态
  • 使用 'agent-tool cfg 1mcp start' 启动 1mcp server
EOF
  exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# 生成 .1mcprc 配置文件
# ─────────────────────────────────────────────────────────────────────────────

setup_1mcprc() {
  local target="${PROJECT_ROOT}/.1mcprc"

  log_info "配置 1mcp 项目级配置 (.1mcprc)…"

  # 检查全局配置是否存在
  if [[ ! -f "$ONEMCP_CONFIG" ]]; then
    log_warn "未找到全局 MCP 配置: $ONEMCP_CONFIG"
    log_warn "请先运行 'agent-tool cfg init' 初始化配置"
    return 1
  fi

  # 检查是否已存在
  if [[ -f "$target" ]]; then
    log_warn "项目中已存在 .1mcprc，保持不变: $target"
    log_warn "→ 如需更新，请手动编辑或删除后重新生成。"
    return 0
  fi

  # 构建配置内容
  local config_content

  if [[ -n "$PRESET" ]]; then
    # 使用 preset 模式
    config_content=$(cat <<EOF
{
  "preset": "${PRESET}"
}
EOF
)
  elif [[ -n "$TAGS" ]]; then
    # 使用 tags 过滤模式
    config_content=$(cat <<EOF
{
  "filter": "${TAGS}"
}
EOF
)
  else
    # 默认：使用所有 servers（空配置或注释说明）
    config_content=$(cat <<'EOF'
{
  "_comment": "1mcp 项目配置 - 由 agent-tool 生成",
  "_docs": "https://docs.1mcp.app/guide/quick-start"
}
EOF
)
  fi

  if $DRY_RUN; then
    log_verbose "将创建 $target，内容如下:"
    echo "$config_content"
  else
    echo "$config_content" > "$target"
    log_verbose "已创建 $target"
  fi

  log_success "1mcp 项目配置已生成: $target"

  # 提示信息
  echo ""
  log_info "配置说明:"
  echo "  • .1mcprc 用于过滤全局 MCP servers"
  echo "  • 全局配置: $ONEMCP_CONFIG"
  echo ""
  log_info "可用的过滤方式:"
  echo "  • preset: 使用预定义的服务器集合"
  echo "  • filter: 使用标签表达式（如 \"core AND NOT async\"）"
  echo ""
  log_info "确保 1mcp server 正在运行:"
  echo "  agent-tool cfg 1mcp start"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
  # 解析参数
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --preset)
        shift
        PRESET="${1:-}"
        if [[ -z "$PRESET" ]]; then
          log_error "--preset 需要指定预设名称"
          exit 1
        fi
        ;;
      --tags)
        shift
        TAGS="${1:-}"
        if [[ -z "$TAGS" ]]; then
          log_error "--tags 需要指定标签表达式"
          exit 1
        fi
        ;;
      -n|--dry-run) DRY_RUN=true; VERBOSE=true ;;
      -v|--verbose) VERBOSE=true ;;
      -h|--help)    usage ;;
      *)
        log_error "未知选项: $1"
        usage
        ;;
    esac
    shift
  done

  # 不能同时指定 preset 和 tags
  if [[ -n "$PRESET" ]] && [[ -n "$TAGS" ]]; then
    log_error "不能同时指定 --preset 和 --tags"
    exit 1
  fi

  if [[ ! -d "$AGENT_HOME" ]]; then
    log_error "AGENT_HOME 不存在: $AGENT_HOME"
    log_error "请先运行 'agent-tool cfg init' 初始化配置。"
    exit 1
  fi

  log_info "AGENT_HOME:   $AGENT_HOME"
  log_info "PROJECT_ROOT: $PROJECT_ROOT"
  $DRY_RUN && log_warn "Dry-run 模式 - 不会进行任何实际写入。"

  echo ""

  setup_1mcprc

  echo ""
  log_success "项目级 MCP 配置完成。"
}

main "$@"
