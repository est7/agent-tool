#!/usr/bin/env bash
set -euo pipefail

# agent-tool.sh
#
# 用于创建 / 清理 / 查看 Agent 专用仓库, 以及针对 Android/iOS/Web 的构建辅助。
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# 模块路径：支持新结构（cfg/ws/build/doctor/dev/test/...）
CFG_DIR="${CFG_DIR:-${SCRIPT_DIR}/cfg}"
WS_DIR="${WS_DIR:-${SCRIPT_DIR}/ws}"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build}"
DOCTOR_DIR="${DOCTOR_DIR:-${SCRIPT_DIR}/doctor}"
DEV_DIR="${DEV_DIR:-${SCRIPT_DIR}/dev}"
TEST_DIR="${TEST_DIR:-${SCRIPT_DIR}/test}"

# 全局配置文件（可通过 AGENT_TOOL_CONFIG 覆盖）
AGENT_TOOL_CONFIG="${AGENT_TOOL_CONFIG:-${HOME}/.agent-tool/config}"
if [[ -f "${AGENT_TOOL_CONFIG}" ]]; then
  # shellcheck source=/dev/null
  source "${AGENT_TOOL_CONFIG}"
fi

usage() {
  cat <<EOF
用法:
  $0 help [group]                                       # 显示整体或某个分组的帮助
  $0 cfg <subcommand> [args]                           # 统一配置/软链/MCP 工具
  $0 ws  <subcommand> [...]                            # workspace 相关命令的分组入口
  $0 dev <subcommand> [...]                            # 预留: 开发期流程/规范/模板
  $0 test <platform> <kind> [-- <args...>]             # 项目级测试入口 (单元测试/覆盖率)
  $0 build <platform> [--run] [-- <args...>]           # 在当前仓库中执行内置平台构建逻辑
  $0 run   <platform> [-- <args...>]                   # 便捷运行: 等价于 build <platform> --run
  $0 doctor <target>                                   # 检查平台构建环境 / CLI 自检

说明:
  - 默认 create 时, 使用当前主仓所在分支作为基线
  - 如果指定 --base-branch <branch>, 则显式使用该分支作为基线 (例如 dev/main/release/*)
  - build/run 命令根据平台在当前仓库中执行预置的构建/运行流程, 可通过 .agent-build.yml 提供默认参数

参数:
  <type>   任务类型: feat | bugfix | refactor | chore | exp
  <scope>  任务范围: kebab-case, 例如 user-profile-header
  <platform> 平台: android | ios | web
  --run      对于支持的平台, 表示构建完成后尝试安装/运行

cfg 子命令:
  cfg init              # 初始化统一配置目录软链 (install_symlinks.sh -v)
  cfg init-force        # 初始化并强制覆盖非软链路径 (--force)
  cfg refresh           # 新增 commands/skills/hooks/agents 后刷新软链 (-U)
  cfg selftest [--v]    # 自检配置目录及软链状态
  cfg mcp [options]     # 在项目根生成 MCP 配置 (透传选项至 project_mcp_setup.sh)

ws 子命令（ws 前缀等价于旧的直接命令）:
  ws create [--base-branch <branch>] <type> <scope>
  ws cleanup [--force] <type> <scope> # 默认交互确认；--force 为非交互危险删除
  ws list
  ws status

dev 子命令:
  dev ...               # 预留: 开发期流程/规范/模板 (当前未实现)

test 子命令（项目级测试入口）:
  test <platform> <kind> [-- <args...>]

  platform: android | ios | web
  kind:     unit | coverage

build 子命令:
  build <platform> [--run] [-- <args...>]

  platform: android | ios | web

run 子命令:
  run <platform> [-- <args...>]

  说明: 等价于 **build <platform> --run [-- <args...>]**，用于直接以运行模式调用预置构建流程。

doctor 子命令:
  doctor <platform>   # 检查当前仓库针对平台的构建环境 (android | ios | web)
  doctor cli          # 对 agent-tool 自身做自检 (bash -n)

示例: 一个完整的 Android 开发流程

  # 1. 在新机器上初始化统一配置目录 (仅需执行一次)
  $0 cfg init

  # 2. 在主仓中为本次需求创建 Agent workspace
  $0 ws create feat user-profile-header

  # 3. 在主仓根目录配置 .agent-build.yml（可选，填 android_package / android_default_variant 等）

  # 4. 在主仓根目录进行构建
  $0 build android com.myapp Debug

  # 5. 运行项目级单元测试
  $0 test android unit

  # 6. 检查当前仓库的 Android 构建环境
  $0 doctor android

  # 7. 任务完成后清理对应的 Agent workspace
  $0 ws cleanup --force feat user-profile-header
EOF
}

is_help_flag() {
  local arg="${1:-}"
  [[ "${arg}" == "-h" || "${arg}" == "--help" ]]
}

help_command() {
  local group="${1:-}"
  case "${group}" in
  "" | -h | --help)
    usage
    ;;
  cfg)
    cat <<EOF
cfg 子命令:
  cfg init              # 初始化统一配置目录软链 (install_symlinks.sh -v)
  cfg init-force        # 初始化并强制覆盖非软链路径 (--force)
  cfg refresh           # 新增 commands/skills/hooks/agents 后刷新软链 (-U)
  cfg selftest [--v]    # 自检配置目录及软链状态
  cfg mcp [options]     # 在项目根生成 MCP 配置 (透传选项至 project_mcp_setup.sh)
  cfg 1mcp <command>    # 管理 1mcp 统一 MCP 网关 (install|start|stop|status|...)
EOF
    ;;
  ws)
    cat <<EOF
workspace 子命令 (仅通过 ws 分组使用):
  ws create [--base-branch <branch>] <type> <scope>
  ws cleanup [--force] <type> <scope> # 默认交互确认；--force 为非交互危险删除
  ws list
  ws status
EOF
    ;;
  build)
    cat <<EOF
build 子命令:
  build <platform> [--run] [-- <args...>]

platform:
  android   Android 工程, 使用 gradlew assemble/install + adb
  ios       iOS 工程, 使用 tuist build/run
  web       Web 工程, 使用 pnpm/yarn/npm build/dev

示例:
  $0 build android com.myapp Debug
  $0 build android --run com.myapp Debug
  $0 build ios MyAppScheme
  $0 build ios --run MyAppScheme "iPhone 16 Pro"
  $0 build web
  $0 build web --run
EOF
    ;;
  run)
    cat <<EOF
run 子命令:
  run <platform> [-- <args...>]

说明:
  等价于: build <platform> --run [-- <args...>]

platform:
  android   Android 工程, 相当于: build android --run
  ios       iOS 工程, 相当于: build ios --run
  web       Web 工程, 相当于: build web --run

示例:
  $0 run android com.myapp Debug
  $0 run ios MyAppScheme "iPhone 16 Pro"
  $0 run web
EOF
    ;;
  doctor)
    cat <<EOF
doctor 子命令:
  doctor <platform>
  doctor cli        # 对 agent-tool 自身做自检 (bash -n)

platform:
  android   检查 Android 构建所需依赖
  ios       检查 iOS (Tuist) 构建所需依赖
  web       检查 Web 构建所需依赖
EOF
    ;;
  dev)
    cat <<EOF
dev 模块尚未实现，预留用于开发期流程/规范/模板。
EOF
    ;;
  test)
    cat <<EOF
test 子命令（项目级测试入口）:
  test <platform> <kind> [-- <args...>]

platform:
  android | ios | web

kind:
  unit      # 单元测试
  coverage  # 覆盖率（具体开关依赖各平台工程配置）

示例:
  $0 test android unit
  $0 test android coverage -- jacocoTestReport
  $0 test ios unit               # 使用 .agent-build.yml 中的 ios_scheme，或在命令行显式传入
  $0 test ios unit MyAppScheme
  $0 test web unit
  $0 test web coverage           # 等价于 pnpm/yarn/npm test -- --coverage（假设使用 Jest 等支持该参数的测试框架）
EOF
    ;;
  *)
    agent_error "E_HELP_GROUP_UNKNOWN" "未知 help 分组: ${group}"
    ;;
  esac
  exit 0
}

# 加载按职责拆分的模块
# - cfg: 公共工具函数（错误输出等）
# - ws: Agent workspace 管理 (create/cleanup/list/status)
# - build: 各平台构建/运行逻辑
# - doctor: 各平台环境自检逻辑 + CLI 自检
# - dev: 预留开发期流程/规范/模板
# - test: 项目级测试入口 + 测试命令封装
source "${CFG_DIR}/index.sh"
source "${WS_DIR}/index.sh"
source "${BUILD_DIR}/index.sh"
source "${DOCTOR_DIR}/index.sh"
source "${DEV_DIR}/index.sh"
source "${TEST_DIR}/index.sh"

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
CLEANUP_FORCE=0
BUILD_PLATFORM=""
BUILD_SHOULD_RUN=0
BUILD_ARGS=()
DOCTOR_PLATFORM=""
AGENT_ROOT=""
REPO_ROOT=""
REPO_NAME=""
PARENT_DIR=""
BASE_BRANCH_NAME=""
WS_GROUP=0

# help 分组：`agent-tool help <group>`
if [[ "${COMMAND}" == "help" ]]; then
  shift
  help_command "$@"
fi

# workspace 分组前缀：`agent-tool ws create ...` 等价于直接 `create ...`
if [[ "${COMMAND}" == "ws" ]]; then
  WS_GROUP=1
  shift
  # 没有后续参数时，默认展示 ws 分组帮助
  if [[ $# -lt 1 ]]; then
    help_command ws
  fi
  if is_help_flag "${1:-}"; then
    help_command ws
  fi
  COMMAND="$1"
fi

if [[ "${WS_GROUP}" -eq 0 ]]; then
  case "${COMMAND}" in
  create | cleanup | list | status)
    agent_error "E_DEPRECATED_TOPLEVEL" "顶层子命令 '${COMMAND}' 已废弃，请使用: $0 ws ${COMMAND} ..."
    echo
    echo "示例:"
    echo "  $0 ws create [--base-branch <branch>] <type> <scope>"
    echo "  $0 ws cleanup --force <type> <scope>"
    echo "  $0 ws list"
    echo "  $0 ws status"
    exit 1
    ;;
  esac
fi

########################################
# cfg 子命令：操作统一配置目录
########################################

run_cfg_script() {
  local script="$1"
  shift || true
  local path="${CFG_DIR}/${script}"
  if [[ ! -x "$path" ]]; then
    agent_error "E_CFG_SCRIPT_NOT_FOUND" "找不到配置脚本: $path"
    exit 1
  fi
  "$path" "$@"
}

cfg_command() {
  shift # 去掉 "cfg"
  local sub="${1:-}"

  # 无子命令或显式 -h/--help 时展示 cfg 帮助
  if [[ -z "${sub}" ]] || is_help_flag "${sub}"; then
    help_command cfg
  fi

  case "$sub" in
  init)
    run_cfg_script "install_symlinks.sh" -v
    ;;
  init-force)
    run_cfg_script "install_symlinks.sh" -v --force
    ;;
  refresh)
    run_cfg_script "install_symlinks.sh" -U
    ;;
  selftest)
    shift || true
    if [[ -x "${DOCTOR_DIR}/cfg_doctor.sh" ]]; then
      "${DOCTOR_DIR}/cfg_doctor.sh" "$@"
    else
      agent_error "E_DOCTOR_SCRIPT_NOT_FOUND" "找不到 cfg_doctor.sh，检查 DOCTOR_DIR 是否正确: ${DOCTOR_DIR}"
      exit 1
    fi
    ;;
  mcp)
    shift || true
    run_cfg_script "project_mcp_setup.sh" "$@"
    ;;
  1mcp)
    shift || true
    local onemcp_script="${CFG_DIR}/1mcp/index.sh"
    if [[ ! -x "$onemcp_script" ]]; then
      agent_error "E_CFG_SCRIPT_NOT_FOUND" "找不到 1mcp 脚本: $onemcp_script"
      exit 1
    fi
    "$onemcp_script" "$@"
    ;;
  *)
    agent_error "E_SUBCOMMAND_UNKNOWN" "未知 cfg 子命令: ${sub}"
    echo "可用: init | init-force | refresh | selftest | mcp | 1mcp"
    exit 1
    ;;
  esac
  exit 0
}

# cfg 子命令不依赖当前目录是 git 仓库
if [[ "${COMMAND}" == "cfg" ]]; then
  cfg_command "$@"
fi

# 计算仓库路径相关变量（仅 ws/build/run/doctor/test 需要）
if ! command -v git >/dev/null 2>&1; then
  agent_error "E_GIT_MISSING" "未找到 git 命令，请安装 git 并确保其在 PATH 中。"
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  agent_error "E_NOT_GIT_REPO" "当前目录不在一个 Git 仓库中，请在主仓内部执行此脚本。"
  exit 1
fi

REPO_NAME="$(basename "${REPO_ROOT}")" # 例如 my-app
PARENT_DIR="$(dirname "${REPO_ROOT}")" # 例如 ~/Projects
AGENT_ROOT_DEFAULT="${PARENT_DIR}/${REPO_NAME}-agents"
AGENT_ROOT="${AGENT_ROOT:-${AGENT_ROOT_DEFAULT}}"

########################################
# test 子命令：项目级测试入口
########################################

test_command() {
  shift # 去掉 "test"

  # 无参数或显式 -h/--help 时进入 test 帮助
  if [[ $# -lt 1 ]] || is_help_flag "$1"; then
    help_command test
  fi

  local platform="$1"
  shift

  case "${platform}" in
  android | ios | web)
    ;;
  *)
    agent_error "E_ARG_INVALID" "不支持的 test platform='${platform}'，请使用: android | ios | web"
    exit 1
    ;;
  esac

  if [[ $# -lt 1 ]]; then
    agent_error "E_ARG_MISSING" "test 需要显式指定测试类型 kind（unit | coverage）。"
    echo
    echo "用法: $0 test <platform> <kind> [-- <args...>]"
    echo "platform: android | ios | web"
    echo "kind: unit | coverage"
    exit 1
  fi

  local kind="$1"
  shift

  case "${kind}" in
  unit | coverage)
    ;;
  *)
    agent_error "E_TEST_KIND_INVALID" "不支持的测试类型 kind='${kind}'，请使用: unit | coverage"
    exit 1
    ;;
  esac

  if [[ $# -gt 0 && "$1" == "--" ]]; then
    shift
  fi

  # 剩余参数透传给具体平台的测试命令
  test_agent_project "${platform}" "${kind}" "$@"
  exit 0
}

if [[ "${COMMAND}" == "test" ]]; then
  test_command "$@"
fi

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
    agent_error "E_ARG_MISSING" "ws create 需要 <type> <scope>。"
    exit 1
  fi

  TYPE="$1"
  SCOPE="$2"

elif [[ "${COMMAND}" == "cleanup" ]]; then
  shift # 去掉 cleanup

  CLEANUP_FORCE=0
  if [[ "${1:-}" == "--force" ]]; then
    CLEANUP_FORCE=1
    shift
  fi

  if [[ $# -lt 2 ]]; then
    agent_error "E_ARG_MISSING" "ws cleanup 需要 <type> <scope>。"
    exit 1
  fi

  TYPE="$1"
  SCOPE="$2"

elif [[ "${COMMAND}" == "build" ]]; then
  shift # 去掉 build

  # 无平台参数或显式 -h/--help 时进入 build 帮助模式
  if [[ $# -eq 0 ]] || is_help_flag "$1"; then
    help_command build
  fi

  case "$1" in
  android | ios | web)
    BUILD_PLATFORM="$1"
    shift
    ;;
  *)
    agent_error "E_ARG_INVALID" "不支持的 platform='$1'，请使用: android | ios | web"
    exit 1
    ;;
  esac

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

  # 无平台参数或显式 -h/--help 时进入 run 帮助模式
  if [[ $# -eq 0 ]] || is_help_flag "$1"; then
    help_command run
  fi

  case "$1" in
  android | ios | web)
    BUILD_PLATFORM="$1"
    shift
    ;;
  *)
    agent_error "E_ARG_INVALID" "不支持的 platform='$1'，请使用: android | ios | web"
    exit 1
    ;;
  esac

  if [[ $# -gt 0 && "$1" == "--" ]]; then
    shift
  fi

  if [[ $# -gt 0 ]]; then
    BUILD_ARGS=("$@")
  fi
elif [[ "${COMMAND}" == "doctor" ]]; then
  shift # 去掉 doctor

  # 无参数或显式 -h/--help 时进入 doctor 帮助模式
  if [[ $# -lt 1 ]] || is_help_flag "$1"; then
    help_command doctor
  fi

  case "$1" in
  android | ios | web)
    DOCTOR_PLATFORM="$1"
    ;;
  cli)
    DOCTOR_PLATFORM="cli"
    ;;
  *)
    agent_error "E_ARG_INVALID" "不支持的 doctor 目标='$1'，请使用: android | ios | web | cli"
    exit 1
    ;;
  esac
fi

# 针对需要 type/scope 的命令, 做基本校验和公共变量计算
if [[ "${COMMAND}" == "create" || "${COMMAND}" == "cleanup" ]]; then
  case "${TYPE}" in
  feat | bugfix | refactor | chore | exp) ;;
  *)
    agent_error "E_ARG_INVALID" "不支持的 type='${TYPE}'，请使用: feat | bugfix | refactor | chore | exp"
    exit 1
    ;;
  esac

  BRANCH="agent/${TYPE}/${SCOPE}"
  AGENT_DIR_NAME="${REPO_NAME}-agent-${TYPE}-${SCOPE}"
  AGENT_DIR="${AGENT_ROOT}/${AGENT_DIR_NAME}"
fi

########################################
# 命令分派
########################################

case "${COMMAND}" in
create)
  create_agent_repo "${REPO_ROOT}" "${AGENT_ROOT}" "${TYPE}" "${SCOPE}" "${BRANCH}" "${AGENT_DIR_NAME}" "${AGENT_DIR}" "${BASE_BRANCH_NAME:-}"
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
  if [[ "${DOCTOR_PLATFORM}" == "cli" ]]; then
    agent_tool_test_self
  else
    doctor_agent_environment
  fi
  ;;
dev)
  echo "dev 模块尚未实现，预留用于开发期流程/规范/模板。"
  exit 1
  ;;
*)
  usage
  exit 1
  ;;
esac
