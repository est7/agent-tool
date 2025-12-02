#!/usr/bin/env bash
set -euo pipefail

########################################
# Web 构建 / 运行 / 环境检查
#
# 依赖主脚本中的:
# - REPO_ROOT
# - BUILD_ARGS / BUILD_SHOULD_RUN
########################################

build_web_project() {
  echo "[agent-build][web] 开始执行 Web 构建流程"

  cd "${REPO_ROOT}"

  if [[ ! -f "package.json" ]]; then
    echo "错误: 未找到 package.json, 请在 Web 工程根目录执行。"
    exit 1
  fi

  local pm=""
  if command -v pnpm >/dev/null 2>&1; then
    pm="pnpm"
  elif command -v yarn >/dev/null 2>&1; then
    pm="yarn"
  elif command -v npm >/dev/null 2>&1; then
    pm="npm"
  else
    echo "错误: 未找到 pnpm/yarn/npm, 请至少安装一种 Node.js 包管理器并配置 PATH。"
    exit 1
  fi

  echo "[agent-build][web] 使用包管理器: ${pm}"

  local extra_args=()
  if [[ ${#BUILD_ARGS[@]} -gt 0 ]]; then
    extra_args=("${BUILD_ARGS[@]}")
  fi

  if [[ "${BUILD_SHOULD_RUN}" -eq 1 ]]; then
    echo "[agent-build][web] 以开发/运行模式启动, 透传参数: ${extra_args[*]:-}"
    case "${pm}" in
      pnpm) pnpm dev "${extra_args[@]}" ;;
      yarn) yarn dev "${extra_args[@]}" ;;
      npm)  npm run dev -- "${extra_args[@]}" ;;
    esac
  else
    echo "[agent-build][web] 构建 Web 工程, 透传参数: ${extra_args[*]:-}"
    case "${pm}" in
      pnpm) pnpm build "${extra_args[@]}" ;;
      yarn) yarn build "${extra_args[@]}" ;;
      npm)  npm run build -- "${extra_args[@]}" ;;
    esac
  fi

  echo "[agent-build][web] 完成。"
}

doctor_web_environment() {
  echo "  - 检查 Web 工程标志 (package.json)"
  if [[ -f "${REPO_ROOT}/package.json" ]]; then
    echo "    ✔ 已找到 package.json。"
  else
    echo "    ✖ 未找到 package.json。"
    echo "      请确认当前仓库为 Web 工程根目录。"
  fi

  echo "  - 检查包管理器 (pnpm/yarn/npm)"
  if command -v pnpm >/dev/null 2>&1; then
    echo "    ✔ 检测到 pnpm。"
  elif command -v yarn >/dev/null 2>&1; then
    echo "    ✔ 检测到 yarn。"
  elif command -v npm >/dev/null 2>&1; then
    echo "    ✔ 检测到 npm。"
  else
    echo "    ✖ 未找到 pnpm/yarn/npm。"
    echo "      请至少安装一种 Node.js 包管理器并配置 PATH。"
  fi
}

