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
  $0 test <subcommand> [...]                           # 预留: agent-tool 自身测试命令
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

cfg 子命令:
  cfg init              # 初始化统一配置目录软链 (install_symlinks.sh -v)
  cfg init-force        # 初始化并强制覆盖非软链路径 (--force)
  cfg refresh           # 新增 commands/skills/hooks/agents 后刷新软链 (-U)
  cfg selftest [--v]    # 自检配置目录及软链状态
  cfg mcp [options]     # 在项目根生成 MCP 配置 (透传选项至 project_mcp_setup.sh)

workspace 子命令（ws 前缀等价于旧的直接命令）:
  ws create [--base-branch <branch>] <type> <scope>
  ws cleanup --force <type> <scope>   # 危险: 删除 agent workspace 目录
  ws list
  ws status

示例:
  $0 ws create feat user-profile-header
  $0 ws create --base-branch dev feat user-profile-header
  $0 ws cleanup --force feat user-profile-header
  $0 ws list
  $0 ws status
  $0 build android com.myapp Debug
  $0 build android --run com.myapp Debug
  $0 build ios MyAppScheme
  $0 build web --run
  $0 run android com.myapp Debug
  $0 run web
  $0 doctor android
EOF
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
EOF
    ;;
  ws)
    cat <<EOF
workspace 子命令 (仅通过 ws 分组使用):
  ws create [--base-branch <branch>] <type> <scope>
  ws cleanup --force <type> <scope>   # 危险: 删除 agent workspace 目录
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
EOF
    ;;
  doctor)
    cat <<EOF
doctor 子命令:
  doctor <platform>

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
test 子命令:
  test self   # 对 agent-tool 自身做最小语法检查 (bash -n)
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
# - doctor: 各平台环境自检逻辑
# - dev: 预留开发期流程/规范/模板
# - test: 预留 agent-tool 自身测试/验证逻辑
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
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
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

  if [[ "${sub}" == "-h" || "${sub}" == "--help" ]]; then
    help_command cfg
  fi

  if [[ -z "${sub}" ]]; then
    agent_error "E_ARG_MISSING" "cfg 需要显式指定子命令。"
    echo
    echo "用法: $0 cfg <subcommand> [args]"
    echo "可用子命令: init | init-force | refresh | selftest | mcp"
    exit 1
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
  *)
    agent_error "E_SUBCOMMAND_UNKNOWN" "未知 cfg 子命令: ${sub}"
    echo "可用: init | init-force | refresh | selftest | mcp"
    exit 1
    ;;
  esac
  exit 0
}

# cfg / test 子命令不依赖当前目录是 git 仓库
if [[ "${COMMAND}" == "cfg" ]]; then
  cfg_command "$@"
fi

test_command() {
  shift # 去掉 "test"
  local sub="${1:-self}"

  if [[ "${sub}" == "-h" || "${sub}" == "--help" ]]; then
    help_command test
  fi

  case "${sub}" in
  self)
    agent_tool_test_self
    ;;
  *)
    agent_error "E_SUBCOMMAND_UNKNOWN" "未知 test 子命令: ${sub}"
    exit 1
    ;;
  esac
  exit 0
}

if [[ "${COMMAND}" == "test" ]]; then
  test_command "$@"
fi

# 计算仓库路径相关变量（仅 ws/build/run/doctor 需要）
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

  if [[ "${1:-}" != "--force" ]]; then
    agent_error "E_FORCE_REQUIRED" "ws cleanup 为危险操作，请使用: $0 ws cleanup --force <type> <scope>"
    exit 1
  fi

  shift # 去掉 --force

  if [[ $# -lt 2 ]]; then
    agent_error "E_ARG_MISSING" "ws cleanup 需要 <type> <scope>。"
    exit 1
  fi

  TYPE="$1"
  SCOPE="$2"

elif [[ "${COMMAND}" == "build" ]]; then
  shift # 去掉 build

  if [[ $# -eq 0 ]]; then
    agent_error "E_ARG_MISSING" "build 需要显式指定平台。"
    echo
    echo "用法: $0 build <platform> [--run] [-- <args...>]"
    echo "platform: android | ios | web"
    exit 1
  fi

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

  if [[ $# -eq 0 ]]; then
    agent_error "E_ARG_MISSING" "run 需要显式指定平台。"
    echo
    echo "用法: $0 run <platform> [-- <args...>]"
    echo "platform: android | ios | web"
    exit 1
  fi

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

  if [[ $# -lt 1 ]]; then
    agent_error "E_ARG_MISSING" "doctor 命令需要指定平台。"
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
    agent_error "E_ARG_INVALID" "不支持的 platform='$1'，请使用: android | ios | web"
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
dev)
  echo "dev 模块尚未实现，预留用于开发期流程/规范/模板。"
  exit 1
  ;;
*)
  usage
  exit 1
  ;;
esac
