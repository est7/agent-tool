#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# ~/scripts/agent-tool/cfg/project_mcp_setup.sh
#
# 用途：
#   在「项目根目录」下运行，用统一配置目录（AGENT_HOME）下的 mcp snippet 生成项目级 MCP 配置：
#
#     Claude Code : .mcp.json
#     Gemini CLI  : .gemini/settings.json
#     Codex CLI   : .codex/config.toml  （配合项目内 CODEX_HOME=./.codex 使用）
#
# 设计原则：
#   - 不修改系统级配置 ( ~/.claude.json / ~/.gemini/settings.json / ~/.codex/config.toml )
#   - MCP 行为主要由项目内文件控制，可进 Git 管理
# ═══════════════════════════════════════════════════════════════════════════════

AGENT_HOME="${AGENT_HOME:-${HOME}/.agents}"
PROJECT_ROOT="${PWD}"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 标志位
DRY_RUN=false
VERBOSE=false
DO_CLAUDE=false
DO_GEMINI=false
DO_CODEX=false

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
  它会基于 $AGENT_HOME/mcp 下的 snippet 生成项目级的 MCP 配置文件：

    Claude : .mcp.json
    Gemini : .gemini/settings.json
    Codex  : .codex/config.toml

选项:
  --claude        只配置 Claude (.mcp.json)
  --gemini        只配置 Gemini (.gemini/settings.json)
  --codex         只配置 Codex (.codex/config.toml)
  -n, --dry-run   只显示将要执行的操作，不实际写入
  -v, --verbose   显示详细输出
  -h, --help      显示本帮助信息

环境变量:
  AGENT_HOME      统一配置仓库路径 (默认: ~/.agents)

提示:
  • Codex: 需要在项目中把 CODEX_HOME 指向 ./.codex
    建议用 direnv/mise 等工具设置，而不是全局写死环境变量。
EOF
  exit 0
}

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

# ─────────────────────────────────────────────────────────────────────────────
# Claude: .mcp.json ← $AGENT_HOME/mcp/claude.json.snippet
# ─────────────────────────────────────────────────────────────────────────────

setup_claude_project_mcp() {
  local snippet="${AGENT_HOME}/mcp/claude.json.snippet"
  local target="${PROJECT_ROOT}/.mcp.json"

  log_info "配置 Claude 项目级 MCP (.mcp.json)…"

  if [[ ! -f "$snippet" ]]; then
    log_warn "未找到 snippet 文件: $snippet，跳过 Claude"
    return 0
  fi

  if [[ -f "$target" ]]; then
    log_warn "项目中已存在 .mcp.json，保持不变: $target"
    log_warn "→ 如果你想统一使用 $AGENT_HOME 的定义，可以手动用 jq merge 或直接覆盖。"
    return 0
  fi

  if $DRY_RUN; then
    log_verbose "将复制 $snippet -> $target"
  else
    cp "$snippet" "$target"
    log_verbose "已复制 $snippet -> $target"
  fi

  log_success "Claude 项目 MCP 已配置: $target"
}

# ─────────────────────────────────────────────────────────────────────────────
# Gemini: .gemini/settings.json ← $AGENT_HOME/mcp/gemini.json.snippet
# ─────────────────────────────────────────────────────────────────────────────

setup_gemini_project_mcp() {
  local snippet="${AGENT_HOME}/mcp/gemini.json.snippet"
  local dir="${PROJECT_ROOT}/.gemini"
  local target="${dir}/settings.json"

  log_info "配置 Gemini 项目级 MCP (.gemini/settings.json)…"

  if [[ ! -f "$snippet" ]]; then
    log_warn "未找到 snippet 文件: $snippet，跳过 Gemini"
    return 0
  fi

  ensure_dir "$dir"

  if [[ -f "$target" ]]; then
    log_warn "$target 已存在，保持不变。"
    log_warn "→ 建议手动把 $snippet 中的 mcpServers 合并进现有 settings.json，避免覆盖其他设置。"
    return 0
  fi

  if $DRY_RUN; then
    log_verbose "将复制 $snippet -> $target"
  else
    cp "$snippet" "$target"
    log_verbose "已复制 $snippet -> $target"
  fi

  log_success "Gemini 项目 MCP 已配置: $target"
  log_warn   "注意：请在 snippet 中通过环境变量引用密钥，不要直接写入明文 token。"
}

# ─────────────────────────────────────────────────────────────────────────────
# Codex: .codex/config.toml ← $AGENT_HOME/mcp/codex.toml.snippet
# ─────────────────────────────────────────────────────────────────────────────

setup_codex_project_mcp() {
  local snippet="${AGENT_HOME}/mcp/codex.toml.snippet"
  local dir="${PROJECT_ROOT}/.codex"
  local target="${dir}/config.toml"
  local marker="# BEGIN AGENT_HOME MCP snippet"

  log_info "配置 Codex 项目级 MCP (.codex/config.toml)…"

  if [[ ! -f "$snippet" ]]; then
    log_warn "未找到 snippet 文件: $snippet，跳过 Codex"
    return 0
  fi

  ensure_dir "$dir"

  if $DRY_RUN; then
    if [[ -f "$target" ]]; then
      if grep -Fq "$marker" "$target"; then
        log_verbose "config.toml 中已经存在 AGENT_HOME MCP snippet 标记: $target"
      else
        log_verbose "将把 $snippet 追加到 $target（带标记）"
      fi
    else
      log_verbose "将创建 $target，并填入 $snippet 的内容（带标记）"
    fi
    return 0
  fi

  if [[ ! -f "$target" ]]; then
    {
      echo "$marker"
      cat "$snippet"
      echo "# END AGENT_HOME MCP snippet"
    } > "$target"
    log_verbose "已创建 $target 并写入 MCP snippet"
  else
    if grep -Fq "$marker" "$target"; then
      log_verbose "$target 中已存在 AGENT_HOME MCP snippet 标记，跳过追加"
    else
      {
        echo ""
        echo "$marker"
        cat "$snippet"
        echo "# END AGENT_HOME MCP snippet"
      } >> "$target"
      log_verbose "已将 MCP snippet 从 $snippet 追加到 $target"
    fi
  fi

  log_success "Codex 项目 MCP 已配置: $target"
  log_warn   "要让 Codex 使用项目配置，请在本项目中设置: CODEX_HOME=./.codex"
  log_warn   "推荐用 direnv/mise 管理，而不是在全局 shell 里硬改环境变量。"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
  # 解析参数
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --claude) DO_CLAUDE=true ;;
      --gemini) DO_GEMINI=true ;;
      --codex)  DO_CODEX=true ;;
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

  # 如果未指定具体工具，默认全开
  if ! $DO_CLAUDE && ! $DO_GEMINI && ! $DO_CODEX; then
    DO_CLAUDE=true
    DO_GEMINI=true
    DO_CODEX=true
  fi

  if [[ ! -d "$AGENT_HOME" ]]; then
    log_error "AGENT_HOME 不存在: $AGENT_HOME"
    log_error "请先将你的配置仓库放到该路径，或设置 AGENT_HOME 环境变量。"
    exit 1
  fi

  log_info "AGENT_HOME:   $AGENT_HOME"
  log_info "PROJECT_ROOT: $PROJECT_ROOT"
  $DRY_RUN && log_warn "Dry-run 模式 - 不会进行任何实际写入。"

  echo ""

  $DO_CLAUDE && setup_claude_project_mcp && echo ""
  $DO_GEMINI && setup_gemini_project_mcp && echo ""
  $DO_CODEX  && setup_codex_project_mcp  && echo ""

  log_success "项目级 MCP 配置完成。"
}

main "$@"
