#!/usr/bin/env bash
set -euo pipefail

# cfg/1mcp/index.sh
#
# 1mcp 子命令模块 - 管理 1mcp 统一 MCP 网关
#
# 用法: agent-tool cfg 1mcp <command>
#
# 命令:
#   install   安装 1mcp binary
#   start     启动 1mcp server（后台）
#   stop      停止 1mcp server
#   restart   重启 1mcp server
#   status    查看运行状态
#   enable    设置开机自启
#   disable   取消开机自启
#   logs      查看日志

# ============================================================================
# 常量定义
# ============================================================================

AGENT_HOME="${AGENT_HOME:-$HOME/.agents}"
ONEMCP_BIN="${AGENT_HOME}/bin/1mcp"
ONEMCP_CONFIG="${AGENT_HOME}/mcp.json"
ONEMCP_PID_FILE="${AGENT_HOME}/1mcp.pid"
ONEMCP_LOG_DIR="${AGENT_HOME}/logs"
ONEMCP_LOG_FILE="${ONEMCP_LOG_DIR}/1mcp.log"
ONEMCP_PORT="${ONEMCP_PORT:-3050}"

# 1mcp release 下载 URL
ONEMCP_VERSION="latest"
ONEMCP_RELEASE_BASE="https://github.com/1mcp-app/agent/releases/latest/download"

# LaunchAgent / systemd 配置
LAUNCHAGENT_PLIST="$HOME/Library/LaunchAgents/com.agents.1mcp.plist"
SYSTEMD_SERVICE="$HOME/.config/systemd/user/1mcp.service"

# ============================================================================
# 帮助信息
# ============================================================================

show_1mcp_help() {
  cat <<'EOF'
1mcp - 统一 MCP 网关管理

用法:
  agent-tool cfg 1mcp <command>

命令:
  install       安装 1mcp binary 到 ~/.agents/bin/
  start         启动 1mcp server（后台运行）
  stop          停止 1mcp server
  restart       重启 1mcp server
  status        查看 1mcp 运行状态
  enable        设置开机自启（macOS: launchd, Linux: systemd）
  disable       取消开机自启
  logs          查看 1mcp 日志（最近 50 行）
  logs -f       实时跟踪日志
  init-project  在当前项目创建 MCP 配置
                  生成 .mcp.json（Claude Code 项目级配置）
                  生成 .1mcprc（1mcp proxy 配置）
                  --preset, -p <name>  使用预设（all/core/agent-cli）
                  --filter, -f <expr>  使用标签过滤表达式
                  --force              覆盖已存在的配置文件
                  --1mcprc-only        只生成 .1mcprc

示例:
  agent-tool cfg 1mcp install        # 首次安装
  agent-tool cfg 1mcp start          # 启动服务
  agent-tool cfg 1mcp status         # 检查状态
  agent-tool cfg 1mcp logs -f        # 查看实时日志
  agent-tool cfg 1mcp init-project   # 在项目创建 .1mcprc（默认 preset: all）
  agent-tool cfg 1mcp init-project -p core  # 使用 core preset

配置文件:
  ~/.agents/mcp.json              # MCP servers 唯一可信源
  ~/.config/1mcp/mcp.json         # 软链接 → ~/.agents/mcp.json
  <project>/.mcp.json             # Claude Code 项目级配置（指向 1mcp）
  <project>/.1mcprc               # 1mcp proxy 配置（preset 过滤）
  ~/.agents/1mcp.pid              # PID 文件
  ~/.agents/logs/1mcp.log         # 日志文件

预设说明:
  all        全部 6 个 MCP servers（默认）
  core       核心 servers（sequential-thinking, exa-mcp, memory）
  agent-cli  跨 CLI 协作（claudecode/codex/gemini-cli-mcp-async）

端口:
  默认 3050，可通过 ONEMCP_PORT 环境变量修改

更多信息:
  https://docs.1mcp.app/
EOF
}

# ============================================================================
# 工具函数
# ============================================================================

log_info() {
  echo "[1mcp] $*"
}

log_error() {
  echo "[1mcp] 错误: $*" >&2
}

log_warn() {
  echo "[1mcp] 警告: $*" >&2
}

# 检测操作系统和架构
detect_platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "$os" in
    darwin) os="darwin" ;;
    linux)  os="linux" ;;
    *)
      log_error "不支持的操作系统: $os"
      return 1
      ;;
  esac

  case "$arch" in
    x86_64|amd64)   arch="x64" ;;
    arm64|aarch64)  arch="arm64" ;;
    *)
      log_error "不支持的架构: $arch"
      return 1
      ;;
  esac

  echo "${os}-${arch}"
}

# 检查 1mcp 是否已安装
is_installed() {
  [[ -x "$ONEMCP_BIN" ]]
}

# 检查 1mcp 是否正在运行
is_running() {
  if [[ -f "$ONEMCP_PID_FILE" ]]; then
    local pid
    pid=$(cat "$ONEMCP_PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

# 获取运行中的 PID
get_pid() {
  if [[ -f "$ONEMCP_PID_FILE" ]]; then
    cat "$ONEMCP_PID_FILE"
  fi
}

# 等待服务启动
wait_for_start() {
  local max_attempts=30
  local attempt=0
  while (( attempt < max_attempts )); do
    if curl -s "http://127.0.0.1:${ONEMCP_PORT}/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
    ((attempt++))
  done
  return 1
}

# ============================================================================
# 命令实现
# ============================================================================

cmd_install() {
  log_info "检测平台..."
  local platform
  platform=$(detect_platform) || return 1

  # macOS/Linux 使用 .tar.gz，Windows 使用 .zip
  local archive_ext="tar.gz"
  local archive_name="1mcp-${platform}.${archive_ext}"
  local download_url="${ONEMCP_RELEASE_BASE}/${archive_name}"
  local bin_dir="${AGENT_HOME}/bin"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  log_info "平台: ${platform}"
  log_info "下载 URL: ${download_url}"

  # 创建目录
  mkdir -p "$bin_dir"
  mkdir -p "$ONEMCP_LOG_DIR"

  # 下载压缩包
  log_info "下载 1mcp..."
  local archive_path="${tmp_dir}/${archive_name}"
  if command -v curl &>/dev/null; then
    curl -fSL -o "$archive_path" "$download_url"
  elif command -v wget &>/dev/null; then
    wget -q -O "$archive_path" "$download_url"
  else
    log_error "需要 curl 或 wget"
    rm -rf "$tmp_dir"
    return 1
  fi

  # 解压
  log_info "解压..."
  tar -xzf "$archive_path" -C "$tmp_dir"

  # 查找并移动二进制文件
  # 优先查找带平台后缀的文件（如 1mcp-darwin-arm64），然后查找 1mcp
  local extracted_bin="${tmp_dir}/1mcp-${platform}"
  if [[ ! -f "$extracted_bin" ]]; then
    extracted_bin="${tmp_dir}/1mcp"
  fi
  if [[ ! -f "$extracted_bin" ]]; then
    # 可能在子目录中，或者文件名不同
    extracted_bin=$(find "$tmp_dir" -name "1mcp*" -type f ! -name "*.tar.gz" | head -n 1)
  fi

  if [[ -z "$extracted_bin" || ! -f "$extracted_bin" ]]; then
    log_error "解压后未找到 1mcp 二进制文件"
    rm -rf "$tmp_dir"
    return 1
  fi

  mv "$extracted_bin" "$ONEMCP_BIN"
  chmod +x "$ONEMCP_BIN"

  # 清理临时目录
  rm -rf "$tmp_dir"

  # 验证安装
  if "$ONEMCP_BIN" --version &>/dev/null; then
    log_info "安装成功: $ONEMCP_BIN"
    "$ONEMCP_BIN" --version
  else
    log_error "安装验证失败"
    return 1
  fi

  # 生成默认配置（如果不存在）
  if [[ ! -f "$ONEMCP_CONFIG" ]]; then
    generate_default_config
  fi

  # 创建软链接：~/.config/1mcp/mcp.json → ~/.agents/mcp.json
  # 1mcp 官方默认读取 ~/.config/1mcp/mcp.json，我们将其指向唯一可信源
  local onemcp_official_dir="$HOME/.config/1mcp"
  local onemcp_official_config="${onemcp_official_dir}/mcp.json"

  mkdir -p "$onemcp_official_dir"

  if [[ -L "$onemcp_official_config" ]]; then
    rm -f "$onemcp_official_config"
  elif [[ -f "$onemcp_official_config" ]]; then
    mv "$onemcp_official_config" "${onemcp_official_config}.bak"
    log_warn "已备份: ${onemcp_official_config}.bak"
  fi

  ln -sf "$ONEMCP_CONFIG" "$onemcp_official_config"
  log_info "软链接: $onemcp_official_config → $ONEMCP_CONFIG"
}

cmd_start() {
  if ! is_installed; then
    log_error "1mcp 未安装，请先运行: agent-tool cfg 1mcp install"
    return 1
  fi

  if is_running; then
    log_warn "1mcp 已在运行 (PID: $(get_pid))"
    return 0
  fi

  if [[ ! -f "$ONEMCP_CONFIG" ]]; then
    log_error "配置文件不存在: $ONEMCP_CONFIG"
    log_info "请先运行 agent-tool cfg init 生成配置"
    return 1
  fi

  mkdir -p "$ONEMCP_LOG_DIR"

  log_info "启动 1mcp server (端口: ${ONEMCP_PORT})..."

  nohup "$ONEMCP_BIN" \
    --config "$ONEMCP_CONFIG" \
    --port "$ONEMCP_PORT" \
    >> "$ONEMCP_LOG_FILE" 2>&1 &

  local pid=$!
  echo "$pid" > "$ONEMCP_PID_FILE"

  # 等待启动
  if wait_for_start; then
    log_info "1mcp 已启动 (PID: $pid)"
    log_info "健康检查: http://127.0.0.1:${ONEMCP_PORT}/health"
  else
    log_error "启动超时，请检查日志: $ONEMCP_LOG_FILE"
    return 1
  fi
}

cmd_stop() {
  if ! is_running; then
    log_warn "1mcp 未在运行"
    [[ -f "$ONEMCP_PID_FILE" ]] && rm -f "$ONEMCP_PID_FILE"
    return 0
  fi

  local pid
  pid=$(get_pid)
  log_info "停止 1mcp (PID: $pid)..."

  kill "$pid" 2>/dev/null || true

  # 等待进程退出
  local attempt=0
  while (( attempt < 10 )); do
    if ! kill -0 "$pid" 2>/dev/null; then
      break
    fi
    sleep 0.5
    ((attempt++))
  done

  # 强制杀死
  if kill -0 "$pid" 2>/dev/null; then
    log_warn "进程未响应，强制终止..."
    kill -9 "$pid" 2>/dev/null || true
  fi

  rm -f "$ONEMCP_PID_FILE"
  log_info "1mcp 已停止"
}

cmd_restart() {
  cmd_stop
  sleep 1
  cmd_start
}

cmd_status() {
  echo "=== 1mcp 状态 ==="
  echo ""

  # 安装状态
  if is_installed; then
    echo "安装: ✓ 已安装"
    echo "路径: $ONEMCP_BIN"
    local version
    version=$("$ONEMCP_BIN" --version 2>/dev/null || echo "未知")
    echo "版本: $version"
  else
    echo "安装: ✗ 未安装"
    echo "运行 'agent-tool cfg 1mcp install' 安装"
    return 0
  fi

  echo ""

  # 运行状态
  if is_running; then
    local pid
    pid=$(get_pid)
    echo "运行: ✓ 运行中 (PID: $pid)"
    echo "端口: $ONEMCP_PORT"

    # 健康检查
    if curl -s "http://127.0.0.1:${ONEMCP_PORT}/health" >/dev/null 2>&1; then
      echo "健康: ✓ 正常"
    else
      echo "健康: ✗ 无响应"
    fi
  else
    echo "运行: ✗ 未运行"
    echo "运行 'agent-tool cfg 1mcp start' 启动"
  fi

  echo ""

  # 配置状态
  if [[ -f "$ONEMCP_CONFIG" ]]; then
    echo "配置: ✓ $ONEMCP_CONFIG"
    local server_count
    server_count=$(jq '.mcpServers | length' "$ONEMCP_CONFIG" 2>/dev/null || echo "?")
    echo "服务: $server_count 个 MCP server"
  else
    echo "配置: ✗ 配置文件不存在"
  fi

  echo ""

  # 自启动状态
  echo "自启动:"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if [[ -f "$LAUNCHAGENT_PLIST" ]]; then
      echo "  macOS (launchd): ✓ 已启用"
    else
      echo "  macOS (launchd): ✗ 未启用"
    fi
  else
    if [[ -f "$SYSTEMD_SERVICE" ]]; then
      if systemctl --user is-enabled 1mcp &>/dev/null; then
        echo "  Linux (systemd): ✓ 已启用"
      else
        echo "  Linux (systemd): ✗ 未启用"
      fi
    else
      echo "  Linux (systemd): ✗ 未配置"
    fi
  fi
}

cmd_enable() {
  if ! is_installed; then
    log_error "1mcp 未安装，请先运行: agent-tool cfg 1mcp install"
    return 1
  fi

  local os
  os="$(uname -s)"

  if [[ "$os" == "Darwin" ]]; then
    enable_launchd
  else
    enable_systemd
  fi
}

cmd_disable() {
  local os
  os="$(uname -s)"

  if [[ "$os" == "Darwin" ]]; then
    disable_launchd
  else
    disable_systemd
  fi
}

cmd_logs() {
  if [[ ! -f "$ONEMCP_LOG_FILE" ]]; then
    log_warn "日志文件不存在: $ONEMCP_LOG_FILE"
    return 0
  fi

  if [[ "${1:-}" == "-f" ]]; then
    tail -f "$ONEMCP_LOG_FILE"
  else
    tail -n 50 "$ONEMCP_LOG_FILE"
  fi
}

# ============================================================================
# 自启动配置
# ============================================================================

enable_launchd() {
  log_info "配置 macOS launchd 自启动..."

  mkdir -p "$(dirname "$LAUNCHAGENT_PLIST")"

  cat > "$LAUNCHAGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.agents.1mcp</string>
  <key>ProgramArguments</key>
  <array>
    <string>${ONEMCP_BIN}</string>
    <string>--config</string>
    <string>${ONEMCP_CONFIG}</string>
    <string>--port</string>
    <string>${ONEMCP_PORT}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${ONEMCP_LOG_FILE}</string>
  <key>StandardErrorPath</key>
  <string>${ONEMCP_LOG_FILE}</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin</string>
  </dict>
</dict>
</plist>
EOF

  launchctl load "$LAUNCHAGENT_PLIST" 2>/dev/null || true
  log_info "已启用 launchd 自启动"
  log_info "配置文件: $LAUNCHAGENT_PLIST"
}

disable_launchd() {
  if [[ -f "$LAUNCHAGENT_PLIST" ]]; then
    launchctl unload "$LAUNCHAGENT_PLIST" 2>/dev/null || true
    rm -f "$LAUNCHAGENT_PLIST"
    log_info "已禁用 launchd 自启动"
  else
    log_warn "launchd 自启动未配置"
  fi
}

enable_systemd() {
  log_info "配置 Linux systemd 自启动..."

  mkdir -p "$(dirname "$SYSTEMD_SERVICE")"

  cat > "$SYSTEMD_SERVICE" <<EOF
[Unit]
Description=1MCP - Unified MCP Server Proxy
After=network.target

[Service]
Type=simple
ExecStart=${ONEMCP_BIN} --config ${ONEMCP_CONFIG} --port ${ONEMCP_PORT}
Restart=always
RestartSec=5
StandardOutput=append:${ONEMCP_LOG_FILE}
StandardError=append:${ONEMCP_LOG_FILE}

[Install]
WantedBy=default.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable 1mcp

  log_info "已启用 systemd 自启动"
  log_info "配置文件: $SYSTEMD_SERVICE"
  log_info "使用 'systemctl --user start 1mcp' 启动"
}

disable_systemd() {
  if [[ -f "$SYSTEMD_SERVICE" ]]; then
    systemctl --user disable 1mcp 2>/dev/null || true
    systemctl --user stop 1mcp 2>/dev/null || true
    rm -f "$SYSTEMD_SERVICE"
    systemctl --user daemon-reload
    log_info "已禁用 systemd 自启动"
  else
    log_warn "systemd 自启动未配置"
  fi
}

# ============================================================================
# 配置生成
# ============================================================================

generate_default_config() {
  log_info "生成默认 MCP 配置: $ONEMCP_CONFIG"

  cat > "$ONEMCP_CONFIG" <<'EOF'
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "tags": ["core", "all"]
    },
    "exa-mcp": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.exa.ai/mcp"],
      "tags": ["core", "all"]
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
EOF

  log_info "配置已生成"
}

# 在当前项目创建 .mcp.json 配置文件（Claude Code 项目级 MCP 配置）
# 同时支持生成 .1mcprc（1mcp proxy 配置）
cmd_init_project() {
  local preset="all"  # 默认使用 all
  local filter=""
  local force=false
  local onemcp_only=false  # 只生成 .1mcprc

  # 解析参数
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --preset|-p)
        preset="$2"
        shift 2
        ;;
      --filter|-f)
        filter="$2"
        shift 2
        ;;
      --force)
        force=true
        shift
        ;;
      --1mcprc-only)
        onemcp_only=true
        shift
        ;;
      -h|--help)
        echo "用法: agent-tool cfg 1mcp init-project [选项]"
        echo ""
        echo "在当前项目创建 MCP 配置文件："
        echo "  - .mcp.json   Claude Code 项目级 MCP 配置（指向 1mcp HTTP 端点）"
        echo "  - .1mcprc     1mcp proxy 配置（用于 preset 过滤）"
        echo ""
        echo "选项:"
        echo "  --preset, -p <name>  使用预设（all/core/agent-cli），默认: all"
        echo "  --filter, -f <expr>  使用标签过滤表达式（如 \"core OR agent-cli\"）"
        echo "  --force              覆盖已存在的配置文件"
        echo "  --1mcprc-only        只生成 .1mcprc，不生成 .mcp.json"
        echo ""
        echo "预设说明:"
        echo "  all        全部 6 个 MCP servers"
        echo "  core       核心 servers（sequential-thinking, exa-mcp, memory）"
        echo "  agent-cli  跨 CLI 协作（claudecode/codex/gemini-cli-mcp-async）"
        return 0
        ;;
      *)
        log_error "未知参数: $1"
        return 1
        ;;
    esac
  done

  local mcpfile=".mcp.json"
  local rcfile=".1mcprc"

  # 生成 .mcp.json（Claude Code 项目级配置）
  if [[ "$onemcp_only" != true ]]; then
    if [[ -f "$mcpfile" ]] && [[ "$force" != true ]]; then
      log_warn "$mcpfile 已存在，使用 --force 覆盖"
    else
      cat > "$mcpfile" <<EOF
{
  "mcpServers": {
    "1mcp": {
      "type": "http",
      "url": "http://127.0.0.1:${ONEMCP_PORT}/mcp"
    }
  }
}
EOF
      log_info "已创建 $mcpfile (1mcp HTTP 端点)"
    fi
  fi

  # 生成 .1mcprc（1mcp proxy 配置）
  if [[ -f "$rcfile" ]] && [[ "$force" != true ]]; then
    log_warn "$rcfile 已存在，使用 --force 覆盖"
  else
    if [[ -n "$filter" ]]; then
      cat > "$rcfile" <<EOF
{
  "filter": "$filter"
}
EOF
      log_info "已创建 $rcfile (filter: $filter)"
    else
      cat > "$rcfile" <<EOF
{
  "preset": "$preset"
}
EOF
      log_info "已创建 $rcfile (preset: $preset)"
    fi
  fi

  log_info "可用 preset: all, core, agent-cli"
}

# ============================================================================
# 主入口
# ============================================================================

main() {
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    install)      cmd_install "$@" ;;
    start)        cmd_start "$@" ;;
    stop)         cmd_stop "$@" ;;
    restart)      cmd_restart "$@" ;;
    status)       cmd_status "$@" ;;
    enable)       cmd_enable "$@" ;;
    disable)      cmd_disable "$@" ;;
    logs)         cmd_logs "$@" ;;
    init-project) cmd_init_project "$@" ;;
    help|--help|-h)
      show_1mcp_help
      ;;
    *)
      log_error "未知命令: $cmd"
      echo ""
      show_1mcp_help
      return 1
      ;;
  esac
}

# 如果直接执行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
