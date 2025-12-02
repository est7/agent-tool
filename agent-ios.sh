#!/usr/bin/env bash
set -euo pipefail

########################################
# iOS(Tuist) 构建 / 运行 / 环境检查
#
# 依赖主脚本中的:
# - REPO_ROOT
# - BUILD_ARGS / BUILD_SHOULD_RUN
########################################

build_ios_project() {
  echo "[agent-build][ios] 开始执行 iOS 构建流程"

  cd "${REPO_ROOT}"

  local scheme

  if [[ ${#BUILD_ARGS[@]} -ge 1 ]]; then
    scheme="${BUILD_ARGS[0]}"
  else
    echo "错误: 未提供 iOS scheme, 且 .agent-build.yml 也未补充。"
    echo
    echo "请在命令行显式传入 scheme, 例如:"
    echo "  $0 build ios MyAppScheme"
    echo "或在 .agent-build.yml 中添加:"
    echo "  ios_scheme: MyAppScheme"
    exit 1
  fi

  local extra_args=()
  if [[ ${#BUILD_ARGS[@]} -gt 1 ]]; then
    extra_args=("${BUILD_ARGS[@]:1}")
  fi

  if ! command -v tuist >/dev/null 2>&1; then
    echo "错误: 未找到 tuist 命令, 请先安装 tuist 并配置 PATH。"
    exit 1
  fi

  if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "错误: 未找到 xcodebuild, 请安装 Xcode 并在 Xcode 中安装命令行工具。"
    exit 1
  fi

  if [[ ! -f "Project.swift" && ! -d "Tuist" ]]; then
    echo "[agent-build][ios] 提示: 未检测到 Project.swift 或 Tuist 目录, 请确认当前目录为 Tuist 工程根目录。"
  fi

  if [[ "${BUILD_SHOULD_RUN}" -eq 1 ]]; then
    echo "[agent-build][ios] 使用 tuist run, scheme=${scheme}, extra_args=${extra_args[*]:-}"
    tuist run "${scheme}" "${extra_args[@]}"
  else
    echo "[agent-build][ios] 使用 tuist build, scheme=${scheme}, extra_args=${extra_args[*]:-}"
    tuist build "${scheme}" "${extra_args[@]}"
  fi

  echo "[agent-build][ios] 完成。"
}

doctor_ios_environment() {
  echo "  - 检查 Tuist 工程标志 (Project.swift / Tuist/)"
  if [[ -f "${REPO_ROOT}/Project.swift" || -d "${REPO_ROOT}/Tuist" ]]; then
    echo "    ✔ 检测到 Tuist 工程结构。"
  else
    echo "    ✖ 未检测到 Project.swift 或 Tuist 目录。"
    echo "      请确认当前目录为 Tuist 工程根目录。"
  fi

  echo "  - 检查 tuist"
  if command -v tuist >/dev/null 2>&1; then
    echo "    ✔ tuist 已安装并在 PATH 中。"
  else
    echo "    ✖ 未找到 tuist 命令。"
    echo "      建议按照官方文档安装 tuist 并配置 PATH。"
  fi

  echo "  - 检查 xcodebuild"
  if command -v xcodebuild >/dev/null 2>&1; then
    echo "    ✔ xcodebuild 可用。"
  else
    echo "    ✖ 未找到 xcodebuild。"
    echo "      请安装 Xcode 并在 Xcode 中安装命令行工具。"
  fi
}

