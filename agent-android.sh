#!/usr/bin/env bash
set -euo pipefail

########################################
# Android 构建 / 运行 / 环境检查
#
# 依赖主脚本中的:
# - REPO_ROOT
# - BUILD_ARGS / BUILD_SHOULD_RUN
########################################

build_android_project() {
  echo "[agent-build][android] 开始执行 Android 构建流程"

  cd "${REPO_ROOT}"

  if [[ ! -f "./gradlew" ]]; then
    echo "错误: 当前仓库根目录下未找到 ./gradlew, 请在 Android 工程根目录执行。"
    exit 1
  fi

  local package_name variant

  if [[ ${#BUILD_ARGS[@]} -ge 1 ]]; then
    package_name="${BUILD_ARGS[0]}"
  else
    echo "错误: 未提供 Android 包名, 且 .agent-build.yml 也未补充。"
    echo
    echo "请在命令行显式传入包名, 例如:"
    echo "  $0 build android com.myapp Debug"
    echo "或在 .agent-build.yml 中添加:"
    echo "  android_package: com.myapp"
    exit 1
  fi

  if [[ ${#BUILD_ARGS[@]} -ge 2 ]]; then
    variant="${BUILD_ARGS[1]}"
  else
    variant="Debug"
  fi

  if [[ "${BUILD_SHOULD_RUN}" -eq 1 ]]; then
    if ! command -v adb >/dev/null 2>&1; then
      echo "错误: 未找到 adb 命令, 请安装 Android Platform Tools 并配置 PATH。"
      exit 1
    fi

    if ! adb devices | awk 'NR>1 && $2=="device"{found=1} END{exit found?0:1}'; then
      echo "错误: 未检测到已连接的设备或模拟器, 请先启动设备后再重试。"
      exit 1
    fi
  fi

  echo "[agent-build][android] 使用 variant: ${variant}"
  echo "[agent-build][android] 执行: ./gradlew assemble${variant}"
  ./gradlew "assemble${variant}"

  if [[ "${BUILD_SHOULD_RUN}" -eq 1 ]]; then
    echo "[agent-build][android] 执行: ./gradlew install${variant}"
    ./gradlew "install${variant}"

    echo "[agent-build][android] 通过 adb 启动应用: ${package_name}"
    adb shell monkey -p "${package_name}" -c android.intent.category.LAUNCHER 1
  fi

  echo "[agent-build][android] 完成。"
}

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

