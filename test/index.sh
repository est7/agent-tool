#!/usr/bin/env bash
set -euo pipefail

# test/index.sh
#
# test 模块入口，提供 agent-tool 自身的测试/验证子命令。
#
# 区分于仓库级自动化测试（建议放在 tests/ 目录），这里更偏向于
# 「agent-tool 提供的 test 子命令」的实现位置。

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
    "${root}/cfg/aliases.d/core.sh"
    "${root}/cfg/install_symlinks.sh"
    "${root}/cfg/project_mcp_setup.sh"
    "${root}/cfg/index.sh"
    "${root}/dev/index.sh"
    "${root}/test/index.sh"
  )

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
