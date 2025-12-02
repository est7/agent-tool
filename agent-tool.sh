#!/usr/bin/env bash
set -euo pipefail

# agent-tool.sh
#
# 用于创建 / 清理 / 查看 Agent 专用仓库, 以及针对 Android/iOS/Web 的构建辅助。
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

usage() {
  cat <<EOF
用法:
  $0 create  [--base-branch <branch>] <type> <scope>   # 创建 Agent 仓库并初始化
  $0 cleanup <type> <scope>                            # 删除对应的 Agent 仓库目录
  $0 list                                              # 列出所有已存在的 Agent 仓库
  $0 status                                            # 显示所有 Agent 仓库的 git 状态简要信息
  $0 build <platform> [--run] [-- <args...>]           # 在当前仓库中执行内置平台构建逻辑
  $0 run   <platform> [-- <args...>]                   # 便捷运行: 等价于 build <platform> --run
  $0 doctor <platform>                                 # 检查当前仓库针对平台的构建环境

说明:
  - 默认 create 时, 使用当前主仓所在分支作为基线
  - 如果指定 --base-branch <branch>, 则显式使用该分支作为基线 (例如 dev/main/release/*)
  - build/run 命令根据平台在当前仓库中执行预置的构建/运行流程, 可通过 .agent-build.yml 提供默认参数

参数:
  <type>   任务类型: feat | bugfix | refactor | chore | exp
  <scope>  任务范围: kebab-case, 例如 user-profile-header
  <platform> 平台: android | ios | web
  --run      对于支持的平台, 表示构建完成后尝试安装/运行

示例:
  $0 create feat user-profile-header
  $0 create --base-branch dev feat user-profile-header
  $0 cleanup feat user-profile-header
  $0 list
  $0 status
  $0 build android com.myapp Debug
  $0 build android --run com.myapp Debug
  $0 build ios MyAppScheme
  $0 build web --run
  $0 run android com.myapp Debug
  $0 run web
  $0 doctor android
EOF
}

# 加载按职责拆分的模块 (workspace + 平台构建)
source "${SCRIPT_DIR}/agent-workspace.sh"
source "${SCRIPT_DIR}/agent-android.sh"
source "${SCRIPT_DIR}/agent-ios.sh"
source "${SCRIPT_DIR}/agent-web.sh"

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

COMMAND="$1"

TYPE=""
SCOPE=""
BRANCH=""
AGENT_DIR_NAME=""
AGENT_DIR=""
BUILD_PLATFORM=""
BUILD_SHOULD_RUN=0
BUILD_ARGS=()
DOCTOR_PLATFORM=""
AGENT_ROOT=""
REPO_ROOT=""
REPO_NAME=""
PARENT_DIR=""
BASE_BRANCH_NAME=""

# 计算仓库路径相关变量（所有命令都需要）
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "错误: 当前目录不在一个 Git 仓库中，请在主仓内部执行此脚本。"
  exit 1
fi

REPO_NAME="$(basename "${REPO_ROOT}")" # 例如 my-app
PARENT_DIR="$(dirname "${REPO_ROOT}")" # 例如 ~/Projects
AGENT_ROOT="${PARENT_DIR}/${REPO_NAME}-agents"

########################################
# 参数解析: create / cleanup
########################################

if [[ "${COMMAND}" == "create" ]]; then
  shift # 去掉 create

  # 可选参数: --base-branch <branch>
  if [[ $# -ge 2 && "$1" == "--base-branch" ]]; then
    BASE_BRANCH_NAME="$2"
    shift 2
  fi

  if [[ $# -lt 2 ]]; then
    usage
    exit 1
  fi

  TYPE="$1"
  SCOPE="$2"

elif [[ "${COMMAND}" == "cleanup" ]]; then
  shift # 去掉 cleanup
  if [[ $# -lt 2 ]]; then
    usage
    exit 1
  fi

  TYPE="$1"
  SCOPE="$2"

elif [[ "${COMMAND}" == "build" ]]; then
  shift # 去掉 build

  if [[ $# -eq 0 ]]; then
    # 尝试自动检测平台
    platforms=()
    if [[ -f "${REPO_ROOT}/gradlew" ]]; then
      platforms+=("android")
    fi
    if [[ -f "${REPO_ROOT}/Project.swift" || -d "${REPO_ROOT}/Tuist" ]]; then
      platforms+=("ios")
    fi
    if [[ -f "${REPO_ROOT}/package.json" ]]; then
      platforms+=("web")
    fi

    if [[ ${#platforms[@]} -eq 1 ]]; then
      BUILD_PLATFORM="${platforms[0]}"
      echo "提示: 未显式指定平台, 自动检测为: ${BUILD_PLATFORM}"
    elif [[ ${#platforms[@]} -eq 0 ]]; then
      echo "错误: 未检测到已知平台结构。"
      echo
      echo "请显式指定平台, 用法:"
      echo "  $0 build <platform> [--run] [-- <args...>]"
      echo "platform: android | ios | web"
      exit 1
    else
      echo "错误: 检测到多个可能的平台: ${platforms[*]}"
      echo
      echo "请显式指定平台, 用法:"
      echo "  $0 build <platform> [--run] [-- <args...>]"
      exit 1
    fi
  else
    case "$1" in
    android | ios | web)
      BUILD_PLATFORM="$1"
      shift
      ;;
    -h | --help)
      echo "用法: $0 build <platform> [--run] [-- <args...>]"
      echo
      echo "platform:"
      echo "  android   Android 工程, 使用 gradlew assemble/install + adb"
      echo "  ios       iOS 工程, 使用 tuist build/run"
      echo "  web       Web 工程, 使用 pnpm/yarn/npm build/dev"
      echo
      echo "示例:"
      echo "  $0 build android com.myapp Debug"
      echo "  $0 build android --run com.myapp Debug"
      echo "  $0 build ios MyAppScheme"
      echo "  $0 build ios --run MyAppScheme \"iPhone 16 Pro\""
      echo "  $0 build web"
      echo "  $0 build web --run"
      exit 0
      ;;
    *)
      echo "错误: 不支持的 platform='$1'，请使用: android | ios | web"
      exit 1
      ;;
    esac
  fi

  if [[ $# -gt 0 && "$1" == "--run" ]]; then
    BUILD_SHOULD_RUN=1
    shift
  fi

  if [[ $# -gt 0 && "$1" == "--" ]]; then
    shift
  fi

  if [[ $# -gt 0 ]]; then
    BUILD_ARGS=("$@")
  fi
elif [[ "${COMMAND}" == "run" ]]; then
  shift # 去掉 run

  BUILD_SHOULD_RUN=1

  if [[ $# -eq 0 ]]; then
    # 尝试自动检测平台
    platforms=()
    if [[ -f "${REPO_ROOT}/gradlew" ]]; then
      platforms+=("android")
    fi
    if [[ -f "${REPO_ROOT}/Project.swift" || -d "${REPO_ROOT}/Tuist" ]]; then
      platforms+=("ios")
    fi
    if [[ -f "${REPO_ROOT}/package.json" ]]; then
      platforms+=("web")
    fi

    if [[ ${#platforms[@]} -eq 1 ]]; then
      BUILD_PLATFORM="${platforms[0]}"
      echo "提示: 未显式指定平台, 自动检测为: ${BUILD_PLATFORM}"
    elif [[ ${#platforms[@]} -eq 0 ]]; then
      echo "错误: 未检测到已知平台结构。"
      echo
      echo "请显式指定平台, 用法:"
      echo "  $0 run <platform> [-- <args...>]"
      echo "platform: android | ios | web"
      exit 1
    else
      echo "错误: 检测到多个可能的平台: ${platforms[*]}"
      echo
      echo "请显式指定平台, 用法:"
      echo "  $0 run <platform> [-- <args...>]"
      exit 1
    fi
  else
    case "$1" in
    android | ios | web)
      BUILD_PLATFORM="$1"
      shift
      ;;
    -h | --help)
      echo "用法: $0 run <platform> [-- <args...>]"
      echo
      echo "platform:"
      echo "  android   Android 工程, 相当于: build android --run"
      echo "  ios       iOS 工程, 相当于: build ios --run"
      echo "  web       Web 工程, 相当于: build web --run"
      echo
      echo "示例:"
      echo "  $0 run android com.myapp Debug"
      echo "  $0 run ios MyAppScheme \"iPhone 16 Pro\""
      echo "  $0 run web"
      exit 0
      ;;
    *)
      echo "错误: 不支持的 platform='$1'，请使用: android | ios | web"
      exit 1
      ;;
    esac
  fi

  if [[ $# -gt 0 && "$1" == "--" ]]; then
    shift
  fi

  if [[ $# -gt 0 ]]; then
    BUILD_ARGS=("$@")
  fi
elif [[ "${COMMAND}" == "doctor" ]]; then
  shift # 去掉 doctor

  if [[ $# -lt 1 ]]; then
    echo "错误: doctor 命令需要指定平台。"
    echo
    echo "用法: $0 doctor <platform>"
    echo "platform: android | ios | web"
    exit 1
  fi

  case "$1" in
  android | ios | web)
    DOCTOR_PLATFORM="$1"
    ;;
  -h | --help)
    echo "用法: $0 doctor <platform>"
    echo
    echo "platform:"
    echo "  android   检查 Android 构建所需依赖"
    echo "  ios       检查 iOS (Tuist) 构建所需依赖"
    echo "  web       检查 Web 构建所需依赖"
    echo
    echo "示例:"
    echo "  $0 doctor android"
    echo "  $0 doctor ios"
    echo "  $0 doctor web"
    exit 0
    ;;
  *)
    echo "错误: 不支持的 platform='$1'，请使用: android | ios | web"
    exit 1
    ;;
  esac
fi

# 针对需要 type/scope 的命令, 做基本校验和公共变量计算
if [[ "${COMMAND}" == "create" || "${COMMAND}" == "cleanup" ]]; then
  case "${TYPE}" in
  feat | bugfix | refactor | chore | exp) ;;
  *)
    echo "错误: 不支持的 type='${TYPE}'，请使用: feat | bugfix | refactor | chore | exp"
    exit 1
    ;;
  esac

  BRANCH="agent/${TYPE}/${SCOPE}"
  AGENT_DIR_NAME="${REPO_NAME}-agent-${TYPE}-${SCOPE}"
  AGENT_DIR="${AGENT_ROOT}/${AGENT_DIR_NAME}"
fi

########################################
# build + doctor
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
      echo "错误: 未提供 Android 包名, 且 .agent-build.yml 中未配置 android_package。"
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
      echo "错误: 未提供 iOS scheme, 且 .agent-build.yml 中未配置 ios_scheme。"
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
    echo "内部错误: BUILD_PLATFORM 为空, 请检查参数解析逻辑。"
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
    echo "错误: 不支持的构建平台: ${BUILD_PLATFORM}"
    exit 1
    ;;
  esac
}

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

doctor_agent_environment() {
  if [[ -z "${DOCTOR_PLATFORM}" ]]; then
    echo "内部错误: DOCTOR_PLATFORM 为空, 请检查参数解析逻辑。"
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
    echo "内部错误: 不支持的 DOCTOR_PLATFORM='${DOCTOR_PLATFORM}'。"
    exit 1
    ;;
  esac

  echo
  echo "Doctor 检查完成。如有 ✖ 项, 请根据建议修复后再执行 build/run。"
}

########################################
# status
########################################

status_agents() {
  echo "==> Agent 根目录: ${AGENT_ROOT}"
  if [[ ! -d "${AGENT_ROOT}" ]]; then
    echo "当前没有任何 Agent 仓库。"
    return 0
  fi

  shopt -s nullglob
  for dir in "${AGENT_ROOT}"/*; do
    [[ -d "$dir" ]] || continue
    local meta="${dir}/.agent-meta.yml"
    local name branch base_branch
    name="$(basename "${dir}")"

    if [[ -f "${meta}" ]]; then
      branch="$(awk -F': ' '/^branch:/{print $2; exit}' "${meta}" || true)"
      base_branch="$(awk -F': ' '/^base_branch:/{print $2; exit}' "${meta}" || true)"
    else
      branch=""
      base_branch=""
    fi

    echo
    echo "==> ${name} ${branch:+(${branch})} ${base_branch:+[base:${base_branch}]}"
    if [[ ! -d "${dir}/.git" && ! -f "${dir}/.git" ]]; then
      echo "  !! 非 git 仓库，跳过"
      continue
    fi

    local out
    out="$(git -C "${dir}" status --short || echo "  !! git status 失败")"
    if [[ -z "${out}" ]]; then
      echo "  工作区干净"
    else
      echo "${out}" | sed 's/^/  /'
    fi
  done
  shopt -u nullglob
}

########################################
# 命令分派
########################################

case "${COMMAND}" in
create)
  create_agent_repo
  ;;
cleanup)
  cleanup_agent_repo
  ;;
list)
  list_agents
  ;;
status)
  status_agents
  ;;
build)
  build_agent_project
  ;;
run)
  build_agent_project
  ;;
doctor)
  doctor_agent_environment
  ;;
*)
  usage
  exit 1
  ;;
esac
