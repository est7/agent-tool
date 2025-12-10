#!/usr/bin/env bash
set -euo pipefail

# test/index.sh
#
# test 模块入口，提供：
# - 项目级测试入口: test_agent_project（由 `agent-tool test ...` 调用）
# - CLI 自检: agent_tool_test_self（由 `agent-tool doctor cli` 调用）
#
# 区分于仓库级自动化测试（建议放在 tests/ 目录），这里更偏向于
# 「agent-tool 为当前项目提供的统一 test 子命令」的实现位置。

test_agent_project() {
  local platform="$1"
  local kind="$2"
  shift 2 || true

  case "${platform}" in
  android)
    test_android_project "${kind}" "$@"
    ;;
  ios)
    test_ios_project "${kind}" "$@"
    ;;
  web)
    test_web_project "${kind}" "$@"
    ;;
  *)
    agent_error "E_TEST_PLATFORM_INVALID" "不支持的测试平台: ${platform}"
    exit 1
    ;;
  esac
}

test_android_project() {
  local kind="$1"
  shift || true
  local extra_args=("$@")

  echo "[agent-test][android] 开始执行 Android 测试 (${kind})"

  cd "${REPO_ROOT}"

  if [[ ! -f "./gradlew" ]]; then
    agent_error "E_ANDROID_GRADLEW_MISSING" "当前仓库根目录下未找到 ./gradlew, 请在 Android 工程根目录执行。"
    exit 1
  fi

  case "${kind}" in
  unit)
    if [[ ${#extra_args[@]} -gt 0 ]]; then
      echo "[agent-test][android] 执行自定义单元测试任务: ./gradlew ${extra_args[*]}"
      ./gradlew "${extra_args[@]}"
    else
      echo "[agent-test][android] 执行默认单元测试: ./gradlew test"
      ./gradlew test
    fi
    ;;
  coverage)
    if [[ ${#extra_args[@]} -gt 0 ]]; then
      echo "[agent-test][android] 执行覆盖率任务: ./gradlew ${extra_args[*]}"
      ./gradlew "${extra_args[@]}"
    else
      echo "[agent-test][android] 执行默认覆盖率任务: ./gradlew jacocoTestReport"
      ./gradlew jacocoTestReport
    fi
    ;;
  *)
    agent_error "E_TEST_KIND_INVALID" "不支持的 Android 测试类型 kind='${kind}'，请使用: unit | coverage"
    exit 1
    ;;
  esac

  echo "[agent-test][android] 完成。"
}

test_ios_project() {
  local kind="$1"
  shift || true
  local extra_args=("$@")

  echo "[agent-test][ios] 开始执行 iOS 测试 (${kind})"

  cd "${REPO_ROOT}"

  if ! command -v tuist >/dev/null 2>&1; then
    agent_error "E_IOS_TUIST_MISSING" "未找到 tuist 命令, 请先安装 tuist 并配置 PATH。"
    exit 1
  fi

  if ! command -v xcodebuild >/dev/null 2>&1; then
    agent_error "E_IOS_XCODEBUILD_MISSING" "未找到 xcodebuild, 请安装 Xcode 并在 Xcode 中安装命令行工具。"
    exit 1
  fi

  if [[ ! -f "Project.swift" && ! -d "Tuist" ]]; then
    echo "[agent-test][ios] 提示: 未检测到 Project.swift 或 Tuist 目录, 请确认当前目录为 Tuist 工程根目录。"
  fi

  local scheme=""

  # 如果第一个额外参数不是以 - 开头, 视为覆盖默认 scheme
  if [[ ${#extra_args[@]} -gt 0 && "${extra_args[0]}" != -* ]]; then
    scheme="${extra_args[0]}"
    extra_args=("${extra_args[@]:1}")
  else
    local config_file="${REPO_ROOT}/.agent-build.yml"
    if [[ -f "${config_file}" ]]; then
      scheme="$(awk -F': *' '$1=="ios_scheme"{print $2; exit}' "${config_file}" 2>/dev/null || true)"
    fi
  fi

  if [[ -z "${scheme}" ]]; then
    agent_error "E_TEST_CONFIG" "未提供 iOS scheme, 且 .agent-build.yml 中未配置 ios_scheme。"
    echo
    echo "请在命令行显式传入 scheme, 例如:"
    echo "  $0 test ios unit MyAppScheme"
    echo "或在 .agent-build.yml 中添加:"
    echo "  ios_scheme: MyAppScheme"
    exit 1
  fi

  case "${kind}" in
  unit)
    echo "[agent-test][ios] 执行单元测试: tuist test ${scheme} ${extra_args[*]:-}"
    tuist test "${scheme}" "${extra_args[@]}"
    ;;
  coverage)
    echo "[agent-test][ios] 执行覆盖率测试（覆盖率开关由工程配置控制）: tuist test ${scheme} ${extra_args[*]:-}"
    tuist test "${scheme}" "${extra_args[@]}"
    ;;
  *)
    agent_error "E_TEST_KIND_INVALID" "不支持的 iOS 测试类型 kind='${kind}'，请使用: unit | coverage"
    exit 1
    ;;
  esac

  echo "[agent-test][ios] 完成。"
}

test_web_project() {
  local kind="$1"
  shift || true
  local extra_args=("$@")

  echo "[agent-test][web] 开始执行 Web 测试 (${kind})"

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

  case "${kind}" in
  unit)
    echo "[agent-test][web] 执行单元测试: ${pm} test ${extra_args[*]:-}"
    case "${pm}" in
      pnpm) pnpm test "${extra_args[@]}" ;;
      yarn) yarn test "${extra_args[@]}" ;;
      npm)  npm test -- "${extra_args[@]}" ;;
    esac
    ;;
  coverage)
    if [[ ${#extra_args[@]} -eq 0 ]]; then
      # 约定默认通过 --coverage 打开覆盖率（适用于 Jest 等框架）
      extra_args=(--coverage)
    fi
    echo "[agent-test][web] 执行覆盖率测试: ${pm} test ${extra_args[*]:-}"
    case "${pm}" in
      pnpm) pnpm test "${extra_args[@]}" ;;
      yarn) yarn test "${extra_args[@]}" ;;
      npm)  npm test -- "${extra_args[@]}" ;;
    esac
    ;;
  *)
    agent_error "E_TEST_KIND_INVALID" "不支持的 Web 测试类型 kind='${kind}'，请使用: unit | coverage"
    exit 1
    ;;
  esac

  echo "[agent-test][web] 完成。"
}

agent_tool_test_self() {
  echo "==> 运行 agent-tool 自检 (bash -n)"

  local root="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)}"
  local files=(
    "${root}/agent-tool.sh"
    "${root}/ws/workspace.sh"
    "${root}/ws/index.sh"
    "${root}/build/platforms.sh"
    "${root}/build/index.sh"
    "${root}/doctor/platforms.sh"
    "${root}/doctor/index.sh"
    "${root}/cfg/aliases.sh"
    "${root}/cfg/install_symlinks.sh"
    "${root}/cfg/1mcp/index.sh"
    "${root}/cfg/index.sh"
    "${root}/dev/index.sh"
    "${root}/test/index.sh"
  )

  local alias_script
  shopt -s nullglob
  for alias_script in "${root}/cfg/aliases.d/"*.sh; do
    files+=("${alias_script}")
  done
  shopt -u nullglob

  local ok=0

  for f in "${files[@]}"; do
    if [[ ! -f "${f}" ]]; then
      echo "E_TEST_FILE_MISSING: 预期存在的脚本缺失: ${f}"
      ok=1
      continue
    fi

    if bash -n "${f}" 2>/tmp/agent_tool_test_err.$$; then
      echo "OK: ${f}"
    else
      echo "E_TEST_BASH_N: ${f}"
      sed 's/^/  /' /tmp/agent_tool_test_err.$$ || true
      ok=1
    fi
  done

  rm -f /tmp/agent_tool_test_err.$$ 2>/dev/null || true

  if [[ "${ok}" -ne 0 ]]; then
    agent_error "E_TEST_FAILED" "agent-tool 自检失败，请检查上方输出。"
  else
    echo "✅ agent-tool 自检通过。"
  fi

  return "${ok}"
}
