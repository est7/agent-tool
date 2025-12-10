#!/usr/bin/env bash
# shellcheck shell=bash

# 针对 agent-tool 的配置/自检/MCP 快捷别名。
# 依赖上层 loader 提供:
# - CFG_DIR
# - DOCTOR_DIR

alias agent-cfg-refresh="${CFG_DIR}/install_symlinks.sh -U"
alias agent-cfg-selftest="${DOCTOR_DIR}/cfg_doctor.sh"

alias agent-cfg-init="${CFG_DIR}/install_symlinks.sh -v"
alias agent-cfg-init-force="${CFG_DIR}/install_symlinks.sh -v --force"

alias agent-cfg-mcp="${CFG_DIR}/1mcp/index.sh init-project"

