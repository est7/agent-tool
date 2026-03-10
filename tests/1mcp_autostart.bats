#!/usr/bin/env bats

@test "cfg/install_symlinks.sh: configured autostart should invoke 1mcp enable when binary exists" {
  local fake_root="${BATS_TEST_TMPDIR}/install-symlinks"
  local fake_home="${fake_root}/home"
  local fake_agent_home="${fake_home}/.agents"
  local fake_script_dir="${fake_root}/cfg"
  local trace_file="${fake_root}/trace.log"
  local script_path="${BATS_TEST_DIRNAME}/../cfg/install_symlinks.sh"

  mkdir -p "${fake_agent_home}/mcp/bin" "${fake_script_dir}/1mcp"
  touch "${fake_agent_home}/mcp/bin/1mcp"
  chmod +x "${fake_agent_home}/mcp/bin/1mcp"

  cat > "${fake_script_dir}/1mcp/index.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >> "${trace_file}"
EOF
  chmod +x "${fake_script_dir}/1mcp/index.sh"

  run bash -lc "
    set -euo pipefail
    export HOME='${fake_home}'
    export AGENT_HOME='${fake_agent_home}'
    export AGENT_TOOL_ENABLE_1MCP_AUTOSTART=true
    source '${script_path}'
    SCRIPT_DIR='${fake_script_dir}'

    maybe_enable_1mcp_autostart
  "

  [ "${status}" -eq 0 ]
  [ -f "${trace_file}" ]
  run cat "${trace_file}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"enable"* ]]
}

@test "cfg/install_symlinks.sh: configured autostart should warn instead of failing when 1mcp is not installed" {
  local fake_root="${BATS_TEST_TMPDIR}/install-symlinks-missing"
  local fake_home="${fake_root}/home"
  local fake_agent_home="${fake_home}/.agents"
  local script_path="${BATS_TEST_DIRNAME}/../cfg/install_symlinks.sh"

  mkdir -p "${fake_agent_home}/mcp"

  run bash -lc "
    set -euo pipefail
    export HOME='${fake_home}'
    export AGENT_HOME='${fake_agent_home}'
    export AGENT_TOOL_ENABLE_1MCP_AUTOSTART=true
    source '${script_path}'

    maybe_enable_1mcp_autostart
  "

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"未安装 1mcp"* ]]
}

@test "cfg/1mcp/index.sh: autostart config should trigger enable after install" {
  local script_path="${BATS_TEST_DIRNAME}/../cfg/1mcp/index.sh"

  run bash -lc "
    set -euo pipefail
    export AGENT_TOOL_ENABLE_1MCP_AUTOSTART=true
    source '${script_path}'

    cmd_enable() {
      echo enabled
    }

    maybe_enable_autostart_after_install
  "

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"enabled"* ]]
}

@test "cfg/install_symlinks.sh: upgrade mode should not invoke 1mcp enable" {
  local fake_root="${BATS_TEST_TMPDIR}/install-symlinks-upgrade"
  local fake_home="${fake_root}/home"
  local fake_agent_home="${fake_home}/.agents"
  local fake_script_dir="${fake_root}/cfg"
  local trace_file="${fake_root}/trace.log"
  local script_path="${BATS_TEST_DIRNAME}/../cfg/install_symlinks.sh"

  mkdir -p "${fake_agent_home}/mcp/bin" "${fake_script_dir}/1mcp"
  touch "${fake_agent_home}/mcp/bin/1mcp"
  chmod +x "${fake_agent_home}/mcp/bin/1mcp"

  cat > "${fake_script_dir}/1mcp/index.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >> "${trace_file}"
EOF
  chmod +x "${fake_script_dir}/1mcp/index.sh"

  run bash -lc "
    set -euo pipefail
    export HOME='${fake_home}'
    export AGENT_HOME='${fake_agent_home}'
    export AGENT_TOOL_ENABLE_1MCP_AUTOSTART=true
    source '${script_path}'
    SCRIPT_DIR='${fake_script_dir}'
    UPGRADE=true

    maybe_enable_1mcp_autostart
  "

  [ "${status}" -eq 0 ]
  [ ! -f "${trace_file}" ]
}

@test "agent-tool cfg 1mcp install: should forward autostart config loaded from config file" {
  local fake_root="${BATS_TEST_TMPDIR}/agent-tool-forward"
  local fake_cfg_dir="${fake_root}/cfg"
  local fake_config="${fake_root}/agent-tool.conf"
  local trace_file="${fake_root}/trace.log"
  local script_path="${BATS_TEST_DIRNAME}/../agent-tool.sh"

  mkdir -p "${fake_cfg_dir}/1mcp" "${fake_root}/ws" "${fake_root}/build" "${fake_root}/doctor" "${fake_root}/dev" "${fake_root}/test"

  cat > "${fake_cfg_dir}/index.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
agent_error() { echo "$1: ${2:-}" >&2; }
EOF

  cat > "${fake_root}/ws/index.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
EOF

  cat > "${fake_root}/build/index.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
EOF

  cat > "${fake_root}/doctor/index.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
EOF

  cat > "${fake_root}/dev/index.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
EOF

  cat > "${fake_root}/test/index.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
EOF

  cat > "${fake_cfg_dir}/1mcp/index.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf 'autostart=%s args=%s\n' "\${AGENT_TOOL_ENABLE_1MCP_AUTOSTART:-}" "\$*" > "${trace_file}"
EOF
  chmod +x "${fake_cfg_dir}/1mcp/index.sh"

  cat > "${fake_config}" <<'EOF'
AGENT_TOOL_ENABLE_1MCP_AUTOSTART=true
EOF

  run bash -lc "
    set -euo pipefail
    export AGENT_TOOL_CONFIG='${fake_config}'
    export CFG_DIR='${fake_cfg_dir}'
    export WS_DIR='${fake_root}/ws'
    export BUILD_DIR='${fake_root}/build'
    export DOCTOR_DIR='${fake_root}/doctor'
    export DEV_DIR='${fake_root}/dev'
    export TEST_DIR='${fake_root}/test'
    '${script_path}' cfg 1mcp install
  "

  [ "${status}" -eq 0 ]
  run cat "${trace_file}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"autostart=true"* ]]
  [[ "${output}" == *"args=install"* ]]
}
