#!/usr/bin/env bash
set -euo pipefail

# cfg/index.sh
#
# cfg 模块入口，提供统一配置/日志等共享工具函数。
#
# 约定:
# - 所有模块可以使用 agent_error 统一输出机器可解析的错误前缀。

agent_error() {
  local code="$1"; shift || true
  if [[ $# -gt 0 ]]; then
    echo "${code}: $*" >&2
  else
    echo "${code}" >&2
  fi
}

