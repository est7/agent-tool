#!/usr/bin/env bash
set -euo pipefail

########################################
# 平台构建 / 运行 入口
#
# 依赖主脚本中的:
# - REPO_ROOT
# - BUILD_PLATFORM / BUILD_SHOULD_RUN / BUILD_ARGS
########################################

maybe_fill_build_args_from_config() {
  # 如果命令行已经提供了参数, 不再从配置中补全
  if [[ ${#BUILD_ARGS[@]} -gt 0 ]]; then
    return 0
  fi

  local config_file="${REPO_ROOT}/.agent-build.yml"
  if [[ ! -f "${config_file}" ]]; then
    return 0
  fi

  case "${BUILD_PLATFORM}" in
  android)
    local pkg variant
    pkg="$(awk -F': *' '$1=="android_package"{print $2; exit}' "${config_file}" 2>/dev/null || true)"
    variant="$(awk -F': *' '$1=="android_default_variant"{print $2; exit}' "${config_file}" 2>/dev/null || true)"

    if [[ -z "${pkg}" ]]; then
      agent_error "E_BUILD_CONFIG" "未提供 Android 包名, 且 .agent-build.yml 中未配置 android_package。"
      echo
      echo "请在命令行显式传入包名, 例如:"
      echo "  $0 build android com.myapp Debug"
      echo "或在 .agent-build.yml 中添加:"
      echo "  android_package: com.myapp"
      echo "  android_default_variant: Debug   # 可选"
      exit 1
    fi

    if [[ -n "${variant}" ]]; then
      BUILD_ARGS=("${pkg}" "${variant}")
      echo "提示: 从 .agent-build.yml 使用 Android 默认配置: 包名=${pkg}, variant=${variant}"
    else
      BUILD_ARGS=("${pkg}")
      echo "提示: 从 .agent-build.yml 使用 Android 默认配置: 包名=${pkg}"
    fi
    ;;
  ios)
    local scheme
    scheme="$(awk -F': *' '$1=="ios_scheme"{print $2; exit}' "${config_file}" 2>/dev/null || true)"

    if [[ -z "${scheme}" ]]; then
      agent_error "E_BUILD_CONFIG" "未提供 iOS scheme, 且 .agent-build.yml 中未配置 ios_scheme。"
      echo
      echo "请在命令行显式传入 scheme, 例如:"
      echo "  $0 build ios MyAppScheme"
      echo "或在 .agent-build.yml 中添加:"
      echo "  ios_scheme: MyAppScheme"
      exit 1
    fi

    BUILD_ARGS=("${scheme}")
    echo "提示: 从 .agent-build.yml 使用 iOS 默认 scheme: ${scheme}"
    ;;
  web)
    # Web 默认不要求额外参数
    ;;
  *)
    ;;
  esac
}

build_agent_project() {
  if [[ -z "${BUILD_PLATFORM}" ]]; then
    agent_error "E_INTERNAL" "BUILD_PLATFORM 为空, 请检查参数解析逻辑。"
    exit 1
  fi

  local mode
  if [[ "${BUILD_SHOULD_RUN}" -eq 1 ]]; then
    mode="构建并运行"
  else
    mode="仅构建"
  fi

  maybe_fill_build_args_from_config

  echo "==> 主仓根目录: ${REPO_ROOT}"
  echo "==> 构建平台: ${BUILD_PLATFORM}"
  echo "==> 构建模式: ${mode}"
  if [[ ${#BUILD_ARGS[@]} -gt 0 ]]; then
    echo "==> 透传参数: ${BUILD_ARGS[*]}"
  else
    echo "==> 透传参数: (无)"
  fi
  echo

  case "${BUILD_PLATFORM}" in
  android)
    build_android_project
    ;;
  ios)
    build_ios_project
    ;;
  web)
    build_web_project
    ;;
  *)
    agent_error "E_ARG_INVALID" "不支持的构建平台: ${BUILD_PLATFORM}"
    exit 1
    ;;
  esac
}

build_android_project() {
  echo "[agent-build][android] 开始执行 Android 构建流程"

  cd "${REPO_ROOT}"

  if [[ ! -f "./gradlew" ]]; then
    agent_error "E_ANDROID_GRADLEW_MISSING" "当前仓库根目录下未找到 ./gradlew, 请在 Android 工程根目录执行。"
    exit 1
  fi

  local package_name variant

  if [[ ${#BUILD_ARGS[@]} -ge 1 ]]; then
    package_name="${BUILD_ARGS[0]}"
  else
    agent_error "E_BUILD_CONFIG" "未提供 Android 包名, 且 .agent-build.yml 也未补充。"
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
      agent_error "E_ANDROID_ADB_MISSING" "未找到 adb 命令, 请安装 Android Platform Tools 并配置 PATH。"
      exit 1
    fi

    if ! adb devices | awk 'NR>1 && $2=="device"{found=1} END{exit found?0:1}'; then
      agent_error "E_ANDROID_DEVICE_MISSING" "未检测到已连接的设备或模拟器, 请先启动设备后再重试。"
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

build_ios_project() {
  echo "[agent-build][ios] 开始执行 iOS 构建流程"

  cd "${REPO_ROOT}"

  local scheme

  if [[ ${#BUILD_ARGS[@]} -ge 1 ]]; then
    scheme="${BUILD_ARGS[0]}"
  else
    agent_error "E_BUILD_CONFIG" "未提供 iOS scheme, 且 .agent-build.yml 也未补充。"
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
    agent_error "E_IOS_TUIST_MISSING" "未找到 tuist 命令, 请先安装 tuist 并配置 PATH。"
    exit 1
  fi

  if ! command -v xcodebuild >/dev/null 2>&1; then
    agent_error "E_IOS_XCODEBUILD_MISSING" "未找到 xcodebuild, 请安装 Xcode 并在 Xcode 中安装命令行工具。"
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

build_web_project() {
  echo "[agent-build][web] 开始执行 Web 构建流程"

  cd "${REPO_ROOT}"

  if [[ ! -f "package.json" ]]; then
    agent_error "E_WEB_PACKAGE_JSON_MISSING" "未找到 package.json, 请在 Web 工程根目录执行。"
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
    agent_error "E_WEB_PM_MISSING" "未找到 pnpm/yarn/npm, 请至少安装一种 Node.js 包管理器并配置 PATH。"
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
