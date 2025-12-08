#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# ~/scripts/agent-tool/doctor/cfg_doctor.sh
#
# 用途：
#   - 快速自检统一配置目录（AI_HOME）和关键软链接是否正常
#   - 检查：
#       * $AI_HOME 是否存在
#       * AGENTS.md 是否存在（没有也能用，但强烈建议有）
#       * commands/、skills/、hooks/、agents/、mcp/、bootstrap/ 等关键目录
#       * mcp/*.json.snippet 的 JSON 语法（依赖 jq）
#       * 关键软链接：
#           - ~/.claude/CLAUDE.md / ~/.codex/AGENTS.md / ~/.gemini/AGENTS.md
#           - ~/.claude/commands/*    -> $AI_HOME/commands/{shared,claude-only}
#           - ~/.claude/skills/*      -> $AI_HOME/skills/{shared,claude-only}
#           - ~/.claude/hooks/*       -> $AI_HOME/hooks/claude
#           - ~/.claude/agents/*      -> $AI_HOME/agents/claude
#           - ~/.codex/prompts/*      -> $AI_HOME/commands/{shared,codex-only}
#           - ~/.codex/skills/*       -> $AI_HOME/skills/{shared,codex-only}
# ═══════════════════════════════════════════════════════════════════════════════

AI_HOME="${AI_HOME:-${HOME}/.agents}"
VERBOSE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1" >&2; }
log_verbose() { $VERBOSE && echo "    … $1" || true; }

usage() {
  cat <<EOF
用法: $(basename "$0") [选项]

选项:
  -v, --verbose   显示详细输出
  -h, --help      显示本帮助信息

环境变量:
  AI_HOME         统一配置仓库路径 (默认: ~/.agents)

说明:
  本脚本只做【健康检查】，不会修改任何文件。
  有 Warning 并不一定是致命问题，请结合自己的配置判断。
EOF
  exit 0
}

check_file() {
  local path="$1"
  local label="$2"
  if [[ -f "$path" ]]; then
    log_success "$label 存在: $path"
  else
    log_warn    "$label 缺失: $path"
  fi
}

check_dir() {
  local path="$1"
  local label="$2"
  if [[ -d "$path" ]]; then
    log_success "$label 存在: $path"
  else
    log_warn    "$label 缺失: $path"
  fi
}

check_json_valid() {
  local path="$1"
  local label="$2"

  if [[ ! -f "$path" ]]; then
    log_warn "$label JSON 未找到，跳过语法检查: $path"
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log_warn "未安装 jq，无法校验 JSON 语法: $path"
    return 0
  fi

  if jq empty "$path" >/dev/null 2>&1; then
    log_success "$label JSON 语法正常: $path"
  else
    log_error "$label JSON 语法错误，请修复: $path"
  fi
}

check_symlink() {
  local path="$1"
  local label="$2"
  local expected_prefix="$3"  # 可以为空：只检查是否 symlink，不检查指向

  if [[ -L "$path" ]]; then
    local target
    target="$(readlink "$path" || true)"
    if [[ -n "$expected_prefix" && "$target" != "$expected_prefix"* ]]; then
      log_warn "$label 是软链接，但指向看起来不在预期目录下: $path -> $target"
    else
      log_success "$label 为软链接: $path -> $target"
    fi
  elif [[ -e "$path" ]]; then
    log_warn "$label 存在但不是软链接（可能是你手动创建的实体文件/目录）: $path"
  else
    log_warn "$label 缺失（软链接不存在）: $path"
  fi
}

check_dir_links() {
  local dir="$1"
  local label="$2"
  local expected_prefix="$3"

  if [[ ! -d "$dir" ]]; then
    log_warn "$label 缺失目录: $dir"
    return
  fi

  local total=0
  local matched=0
  while IFS= read -r link; do
    total=$((total + 1))
    local target
    target="$(readlink "$link" || true)"
    if [[ -n "$expected_prefix" && "$target" == "$expected_prefix"* ]]; then
      matched=$((matched + 1))
    fi
  done < <(find "$dir" -maxdepth 1 -type l 2>/dev/null)

  if (( total == 0 )); then
    log_warn "$label 目录存在但未发现软链接: $dir"
  else
    if [[ -n "$expected_prefix" && $matched -lt $total ]]; then
      log_warn "$label 中有软链接未指向预期前缀（$matched/$total 匹配）: $dir"
    else
      log_success "$label 软链接正常（$total 项）: $dir"
    fi
  fi
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose) VERBOSE=true ;;
      -h|--help)    usage ;;
      *)
        log_error "未知选项: $1"
        usage
        ;;
    esac
    shift
  done

  if [[ ! -d "$AI_HOME" ]]; then
    log_error "AI_HOME 目录不存在: $AI_HOME"
    exit 1
  fi

  log_info "AI_HOME: $AI_HOME"
  echo ""

  # 核心文件 / 目录
  if [[ -f "${AI_HOME}/AGENTS.md" ]]; then
    log_success "AGENTS.md 存在: ${AI_HOME}/AGENTS.md"
  else
    log_warn "AGENTS.md 缺失: ${AI_HOME}/AGENTS.md"
    log_warn "→ 建议在 ${AI_HOME} 下创建 AGENTS.md 作为全局说明书。"
  fi

  check_dir "${AI_HOME}/commands"  "commands 目录"
  check_dir "${AI_HOME}/skills"    "skills 目录"
  check_dir "${AI_HOME}/hooks"     "hooks 目录"
  check_dir "${AI_HOME}/agents"    "agents 目录"
  check_dir "${AI_HOME}/mcp"       "mcp 目录"
  check_dir "${AI_HOME}/bootstrap" "bootstrap 目录"

  echo ""

  # MCP JSON snippet 语法校验
  check_json_valid "${AI_HOME}/mcp/claude.json.snippet" "Claude MCP snippet"
  check_json_valid "${AI_HOME}/mcp/gemini.json.snippet" "Gemini MCP snippet"

  echo ""

  # 关键 symlink 检查
  check_symlink "${HOME}/.claude/CLAUDE.md" "Claude 全局说明文件" "${AI_HOME}"
  check_symlink "${HOME}/.codex/AGENTS.md"  "Codex 全局说明文件"  "${AI_HOME}"
  check_symlink "${HOME}/.gemini/AGENTS.md" "Gemini 全局说明文件" "${AI_HOME}"

  check_dir_links "${HOME}/.claude/commands" "Claude commands 软链接" "${AI_HOME}/commands"
  check_dir_links "${HOME}/.claude/skills"   "Claude skills 软链接"   "${AI_HOME}/skills"
  check_dir_links "${HOME}/.claude/hooks"    "Claude hooks 软链接"    "${AI_HOME}/hooks"
  check_dir_links "${HOME}/.claude/agents"   "Claude agents 软链接"   "${AI_HOME}/agents"

  check_dir_links "${HOME}/.codex/prompts"   "Codex prompts 软链接"   "${AI_HOME}/commands"
  check_dir_links "${HOME}/.codex/skills"    "Codex skills 软链接"    "${AI_HOME}/skills"

  echo ""

  log_info "自检完成：如有 [!] 或 [✗]，请根据实际情况决定是否需要处理。"
}

main "$@"
