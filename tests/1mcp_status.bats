#!/usr/bin/env bats

create_fake_onemcp_home() {
  local fake_home="${BATS_TEST_TMPDIR}/home"

  mkdir -p "${fake_home}/.agents/mcp/bin" "${fake_home}/.agents/mcp/logs"

  cat > "${fake_home}/.agents/mcp/bin/1mcp" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  echo "0.30.0"
  exit 0
fi
exit 0
EOF
  chmod +x "${fake_home}/.agents/mcp/bin/1mcp"

  cat > "${fake_home}/.agents/mcp/mcp.json" <<'EOF'
{
  "mcpServers": {
    "demo": {
      "disabled": false
    }
  }
}
EOF

  printf '%s\n' "${fake_home}"
}

@test "cfg 1mcp status: unhealthy health endpoint should not be shown as healthy" {
  local fake_home
  fake_home="$(create_fake_onemcp_home)"
  local script_path="${BATS_TEST_DIRNAME}/../cfg/1mcp/index.sh"

  run bash -lc "
    set -euo pipefail
    export HOME='${fake_home}'
    export AGENT_HOME='${fake_home}/.agents'
    source '${script_path}'

    is_running() { return 0; }
    get_pid() { echo 4242; }
    curl() {
      cat <<'JSON'
{\"status\":\"unhealthy\",\"servers\":{\"total\":1,\"healthy\":0,\"unhealthy\":1,\"details\":[{\"name\":\"github\",\"status\":\"unhealthy\",\"error\":\"spawn docker ENOENT\"}]}}
JSON
    }

    cmd_status
  "

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"健康: ✗ 异常 (unhealthy)"* ]]
  [[ "${output}" == *"详情: total=1, healthy=0, unhealthy=1"* ]]
  [[ "${output}" == *"github"* ]]
  [[ "${output}" == *"spawn docker ENOENT"* ]]
}

@test "cfg 1mcp start: unhealthy health endpoint should fail startup" {
  local fake_home
  fake_home="$(create_fake_onemcp_home)"
  local script_path="${BATS_TEST_DIRNAME}/../cfg/1mcp/index.sh"

  run bash -lc "
    set -euo pipefail
    export HOME='${fake_home}'
    export AGENT_HOME='${fake_home}/.agents'
    source '${script_path}'

    nohup() { \"\$@\"; }
    listener_pid_for_port() { return 0; }
    curl() {
      cat <<'JSON'
{\"status\":\"unhealthy\",\"servers\":{\"total\":1,\"healthy\":0,\"unhealthy\":1,\"details\":[{\"name\":\"github\",\"status\":\"unhealthy\",\"error\":\"spawn docker ENOENT\"}]}}
JSON
    }

    cmd_start
  "

  [ "${status}" -eq 1 ]
  [[ "${output}" == *"启动后健康检查异常"* ]]
  [[ "${output}" == *"github"* ]]
  [[ "${output}" == *"spawn docker ENOENT"* ]]
}

@test "cfg 1mcp status: degraded health endpoint should be shown as degraded" {
  local fake_home
  fake_home="$(create_fake_onemcp_home)"
  local script_path="${BATS_TEST_DIRNAME}/../cfg/1mcp/index.sh"

  run bash -lc "
    set -euo pipefail
    export HOME='${fake_home}'
    export AGENT_HOME='${fake_home}/.agents'
    source '${script_path}'

    is_running() { return 0; }
    get_pid() { echo 4242; }
    curl() {
      cat <<'JSON'
{\"status\":\"degraded\",\"servers\":{\"total\":8,\"healthy\":7,\"unhealthy\":1,\"details\":[]}}
JSON
    }

    cmd_status
  "

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"健康: ✗ 异常 (degraded)"* ]]
  [[ "${output}" == *"详情: total=8, healthy=7, unhealthy=1"* ]]
}

@test "cfg 1mcp start: degraded health endpoint should fail startup without waiting for timeout" {
  local fake_home
  fake_home="$(create_fake_onemcp_home)"
  local script_path="${BATS_TEST_DIRNAME}/../cfg/1mcp/index.sh"

  run bash -lc "
    set -euo pipefail
    export HOME='${fake_home}'
    export AGENT_HOME='${fake_home}/.agents'
    source '${script_path}'

    nohup() { \"\$@\"; }
    listener_pid_for_port() { return 0; }
    curl() {
      cat <<'JSON'
{\"status\":\"degraded\",\"servers\":{\"total\":8,\"healthy\":7,\"unhealthy\":1,\"details\":[]}}
JSON
    }

    cmd_start
  "

  [ "${status}" -eq 1 ]
  [[ "${output}" == *"启动后健康检查异常"* ]]
  [[ "${output}" == *"异常 (degraded)"* ]]
}

@test "cfg 1mcp start: occupied port should fail before launching a duplicate process" {
  local fake_home
  fake_home="$(create_fake_onemcp_home)"
  local script_path="${BATS_TEST_DIRNAME}/../cfg/1mcp/index.sh"

  run bash -lc "
    set -euo pipefail
    export HOME='${fake_home}'
    export AGENT_HOME='${fake_home}/.agents'
    source '${script_path}'

    listener_pid_for_port() { echo 9999; }

    cmd_start
  "

  [ "${status}" -eq 1 ]
  [[ "${output}" == *"端口 3050 已被其他进程占用 (PID: 9999)"* ]]
}
