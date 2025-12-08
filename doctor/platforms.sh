#!/usr/bin/env bash
set -euo pipefail

########################################
# 平台环境 doctor 入口
#
# 依赖主脚本中的:
# - REPO_ROOT
# - DOCTOR_PLATFORM / DOCTOR_DIR
########################################

doctor_android_environment() {
  echo "  - 检查 Android 工程标志 (./gradlew)"
  if [[ -f "${REPO_ROOT}/gradlew" ]]; then
    echo "    ✔ 已找到 ./gradlew。"
  else
    echo "    ✖ 当前仓库根目录下未找到 ./gradlew。"
    echo "      建议在 Android 工程根目录执行 doctor, 或确认 gradlew 所在位置。"
  fi

  echo "  - 检查 adb"
  if command -v adb >/dev/null 2>&1; then
    echo "    ✔ adb 已安装并在 PATH 中。"
  else
    echo "    ✖ 未找到 adb 命令。"
    echo "      建议安装 Android Platform Tools 并将其添加到 PATH。"
  fi
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

doctor_agent_environment() {
  if [[ -z "${DOCTOR_PLATFORM}" ]]; then
    agent_error "E_INTERNAL" "DOCTOR_PLATFORM 为空, 请检查参数解析逻辑。"
    exit 1
  fi

  echo "==> Doctor 平台: ${DOCTOR_PLATFORM}"
  echo "==> 主仓根目录: ${REPO_ROOT}"

  case "${DOCTOR_PLATFORM}" in
  android)
    doctor_android_environment
    ;;
  ios)
    doctor_ios_environment
    ;;
  web)
    doctor_web_environment
    ;;
  *)
    agent_error "E_INTERNAL" "不支持的 DOCTOR_PLATFORM='${DOCTOR_PLATFORM}'。"
    exit 1
    ;;
  esac

  echo
  echo "==> 配置目录自检 (doctor/cfg_doctor.sh)"
  if [[ -x "${DOCTOR_DIR}/cfg_doctor.sh" ]]; then
    "${DOCTOR_DIR}/cfg_doctor.sh" || {
      echo "  !! cfg_doctor.sh 运行失败，请检查上方输出。"
      exit 1
    }
  else
    echo "  !! 未找到 cfg_doctor.sh，检查 DOCTOR_DIR 是否正确: ${DOCTOR_DIR}"
  fi

  echo
  echo "Doctor 检查完成。如有 ✖ 项, 请根据建议修复后再执行 build/run。"
}
