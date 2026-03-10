#!/usr/bin/env bats

setup() {
  export SKILL_ROOT="${BATS_TEST_DIRNAME}/../cfg/templates/skills/anthropics-skill-creator"
  export VALIDATOR="${SKILL_ROOT}/scripts/quick_validate.py"
  export PACKAGER="${SKILL_ROOT}/scripts/package_skill.py"
  export INIT_SKILL="${SKILL_ROOT}/scripts/init_skill.py"
}

make_skill_dir() {
  local name="$1"
  local dir="${BATS_TEST_TMPDIR}/${name}"
  mkdir -p "${dir}"
  printf '%s\n' "${dir}"
}

write_file() {
  local path="$1"
  shift
  cat > "${path}" <<EOF
$*
EOF
}

@test "skill validator: accepts official minimal skill with description only" {
  local skill_dir
  skill_dir="$(make_skill_dir minimal-skill)"

  write_file "${skill_dir}/SKILL.md" '---
description: Explains code with diagrams. Use when explaining how code works.
---

# Explain Code
'

  run python3 "${VALIDATOR}" "${skill_dir}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Skill is valid"* ]]
}

@test "skill validator: accepts advanced official fields" {
  local skill_dir
  skill_dir="$(make_skill_dir advanced-skill)"

  write_file "${skill_dir}/SKILL.md" '---
name: advanced-skill
description: Runs a deployment workflow when explicitly requested.
argument-hint: "[environment]"
disable-model-invocation: true
user-invocable: true
allowed-tools:
  - Read
  - Bash(git:*)
model: claude-sonnet-4-20250514
context: fork
agent: Explore
hooks:
  Stop:
    - type: command
      command: "./scripts/report.sh"
---

# Advanced Skill
'

  run python3 "${VALIDATOR}" "${skill_dir}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Skill is valid"* ]]
}

@test "skill validator: rejects compatibility as unsupported field" {
  local skill_dir
  skill_dir="$(make_skill_dir legacy-compatibility)"

  write_file "${skill_dir}/SKILL.md" '---
name: legacy-compatibility
description: Legacy field check.
compatibility: Claude Code only
---

# Legacy
'

  run python3 "${VALIDATOR}" "${skill_dir}"

  [ "${status}" -eq 1 ]
  [[ "${output}" == *"compatibility"* ]]
}

@test "skill validator: missing description is warning only" {
  local skill_dir
  skill_dir="$(make_skill_dir warning-only)"

  write_file "${skill_dir}/SKILL.md" '---
name: warning-only
---

# Warning Only
'

  run python3 "${VALIDATOR}" "${skill_dir}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"warning"* || "${output}" == *"Warning"* ]]
}

@test "skill packager: packages warning-only skill and excludes eval artifacts" {
  local skill_dir
  skill_dir="$(make_skill_dir packageable-skill)"
  mkdir -p "${skill_dir}/evals" "${skill_dir}/__pycache__"

  write_file "${skill_dir}/SKILL.md" '---
name: packageable-skill
---

# Packageable
'
  write_file "${skill_dir}/evals/evals.json" '{}'
  write_file "${skill_dir}/__pycache__/temp.pyc" 'bytecode'

  run bash -lc "
    set -euo pipefail
    cd '${SKILL_ROOT}'
    python3 '${PACKAGER}' '${skill_dir}' '${BATS_TEST_TMPDIR}/dist'
  "

  [ "${status}" -eq 0 ]
  [ -f "${BATS_TEST_TMPDIR}/dist/packageable-skill.skill" ]

  run python3 - <<PY
import zipfile
from pathlib import Path
archive = Path(${BATS_TEST_TMPDIR@Q}) / 'dist' / 'packageable-skill.skill'
with zipfile.ZipFile(archive) as zf:
    names = set(zf.namelist())
assert 'packageable-skill/SKILL.md' in names
assert 'packageable-skill/evals/evals.json' not in names
assert 'packageable-skill/__pycache__/temp.pyc' not in names
PY

  [ "${status}" -eq 0 ]
}

@test "init_skill: generates enhanced template without compatibility and passes validation" {
  local skills_dir="${BATS_TEST_TMPDIR}/generated"
  mkdir -p "${skills_dir}"

  run bash -lc "
    set -euo pipefail
    cd '${SKILL_ROOT}'
    python3 '${INIT_SKILL}' generated-skill --path '${skills_dir}'
    python3 '${VALIDATOR}' '${skills_dir}/generated-skill'
  "

  [ "${status}" -eq 0 ]
  run grep -n "compatibility" "${skills_dir}/generated-skill/SKILL.md"
  [ "${status}" -eq 1 ]
  run grep -n "disable-model-invocation" "${skills_dir}/generated-skill/SKILL.md"
  [ "${status}" -eq 0 ]
}
