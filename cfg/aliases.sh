#!/usr/bin/env bash
# shellcheck shell=bash

CFG_DIR="${CFG_DIR:-$HOME/scripts/agent-tool/cfg}"
DOCTOR_DIR="${DOCTOR_DIR:-$HOME/scripts/agent-tool/doctor}"
ALIASES_DIR="${ALIASES_DIR:-${CFG_DIR}/aliases.d}"

# 手动 source 本文件以加载常用别名（默认不自动加载，以免污染环境）：
#   source "$CFG_DIR/aliases.sh"
#
# 你也可以在 shell 配置（~/.zshrc 等）里按需引用：
#   if [[ -f "$CFG_DIR/aliases.sh" ]]; then
#     source "$CFG_DIR/aliases.sh"
#   fi
#
# 别名本身按职责拆分在 aliases.d/*.sh 中，便于未来扩展。

if [[ -d "${ALIASES_DIR}" ]]; then
  for _file in "${ALIASES_DIR}"/*.sh; do
    [[ -f "${_file}" ]] || continue
    # shellcheck source=/dev/null
    source "${_file}"
  done
fi
