#!/usr/bin/env bash
set -euo pipefail

########################################
# Agent workspace 管理 (create/cleanup/list/status)
#
# 依赖于主脚本中计算好的:
# - REPO_ROOT / REPO_NAME / AGENT_ROOT
# - TYPE / SCOPE / BRANCH / AGENT_DIR_NAME / AGENT_DIR
########################################

create_agent_repo() {
  echo "==> 主仓根目录: ${REPO_ROOT}"
  echo "==> Agent 根目录: ${AGENT_ROOT}"
  echo "==> Agent 仓库目录: ${AGENT_DIR}"
  echo "==> Agent 分支: ${BRANCH}"
  echo

  mkdir -p "${AGENT_ROOT}"

  if [[ -d "${AGENT_DIR}" ]]; then
    echo "警告: Agent 仓库目录已存在: ${AGENT_DIR}"
    echo "如果需要重建，请先执行 cleanup 再 create。"
    exit 1
  fi

  echo "==> 使用主仓作为源 + reference 仓库进行 clone (不自动拉 submodules) ..."
  git clone \
    --reference "${REPO_ROOT}" \
    "${REPO_ROOT}" \
    "${AGENT_DIR}"

  cd "${AGENT_DIR}"

  ########################################
  # 1) 在 Agent 仓库中生成并执行 agent_clone.sh (初始化 submodules)
  ########################################
  if [[ ! -f agent_clone.sh ]]; then
    cat >agent_clone.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "==> 初始化 submodules (agent_clone.sh) ..."

git submodule init || true

if git config -f .gitmodules --get-regexp path >/dev/null 2>&1; then
  git config -f .gitmodules --get-regexp path | awk '{print $2}' | \
  while IFS= read -r m; do
    echo "  -> 初始化 submodule: ${m}"
    git -c submodule.alternateErrorStrategy=info \
        submodule update --init --recursive "${m}" 2>/dev/null || echo "  !! 跳过: ${m}"
  done
else
  echo "  (没有配置任何 submodule，跳过初始化)"
fi

echo "==> submodules 初始化完成。"
EOF
    chmod +x agent_clone.sh
  fi

  echo "==> 运行 agent_clone.sh 初始化 submodule ..."
  ./agent_clone.sh
  echo

  ########################################
  # 2) 创建 Agent 父仓分支 (基线分支选择)
  ########################################
  local BASE_BRANCH
  local BASE_REF=""

  if [[ -n "${BASE_BRANCH_NAME:-}" ]]; then
    BASE_BRANCH="${BASE_BRANCH_NAME}"
    echo "==> 使用显式指定基线分支: ${BASE_BRANCH}"
  else
    local CURRENT_BRANCH
    CURRENT_BRANCH="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")"
    BASE_BRANCH="${CURRENT_BRANCH}"
    echo "==> 使用当前主仓分支作为基线: ${BASE_BRANCH}"
  fi

  if [[ "${BASE_BRANCH}" == "HEAD" ]]; then
    echo "  !! 基线为 detached HEAD, 使用 HEAD 作为基线引用"
    BASE_REF="HEAD"
  else
    if git show-ref --verify --quiet "refs/remotes/origin/${BASE_BRANCH}"; then
      BASE_REF="origin/${BASE_BRANCH}"
    elif git show-ref --verify --quiet "refs/heads/${BASE_BRANCH}"; then
      BASE_REF="${BASE_BRANCH}"
    else
      echo "  !! 未找到远端或本地分支 ${BASE_BRANCH}, 回退为当前 HEAD"
      BASE_REF="HEAD"
    fi
  fi

  echo "==> 基线引用: ${BASE_REF}"
  git switch -c "${BRANCH}" "${BASE_REF}" 2>/dev/null || git switch "${BRANCH}"

  ########################################
  # 3) 为所有已初始化且可访问的 submodule 创建/切换同名分支
  #    基线分支名与父仓一致: BASE_BRANCH
  ########################################
  echo "==> 为 submodules 创建/切换分支: ${BRANCH} (基线分支=${BASE_BRANCH})"

  if git config -f .gitmodules --get-regexp path >/dev/null 2>&1; then
    git config -f .gitmodules --get-regexp path | awk '{print $2}' |
      while IFS= read -r m; do
        echo "  -> 处理 submodule: ${m}"
        if [[ ! -d "${m}" ]]; then
          echo "     !! 工作目录不存在（可能无权限或未初始化），跳过"
          continue
        fi

        if [[ ! -d "${m}/.git" && ! -f "${m}/.git" ]]; then
          echo "     !! 非 git 工作目录，跳过"
          continue
        fi

        (
          cd "${m}"

          BASE_REF_SUB=""

          if [[ "${BASE_BRANCH}" != "HEAD" ]]; then
            if git show-ref --verify --quiet "refs/remotes/origin/${BASE_BRANCH}"; then
              BASE_REF_SUB="origin/${BASE_BRANCH}"
            elif git show-ref --verify --quiet "refs/heads/${BASE_BRANCH}"; then
              BASE_REF_SUB="${BASE_BRANCH}"
            fi
          fi

          if [[ -z "${BASE_REF_SUB}" ]]; then
            echo "     !! 子仓未找到基线分支 ${BASE_BRANCH}，保持当前分支/commit 不变"
            exit 0
          fi

          if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
            echo "     -> 已存在本地分支 ${BRANCH}，切换过去"
            git switch "${BRANCH}"
          else
            echo "     -> 基于 ${BASE_REF_SUB} 创建分支 ${BRANCH}"
            git switch -c "${BRANCH}" "${BASE_REF_SUB}" 2>/dev/null || git switch "${BRANCH}" || {
              echo "     !! 创建/切换分支失败，保持当前状态"
            }
          fi
        )
      done
  else
    echo "  (没有配置任何 submodule，跳过分支创建)"
  fi

  ########################################
  # 4) 生成 metadata + README
  ########################################
  CREATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  cat >.agent-meta.yml <<EOF
type: ${TYPE}
scope: ${SCOPE}
branch: ${BRANCH}
base_branch: ${BASE_BRANCH}
created_at: ${CREATED_AT}
origin_repo: ${REPO_ROOT}
agent_dir_name: ${AGENT_DIR_NAME}
description: "TODO: 填写本任务的更详细描述"
EOF

  cat >README_AGENT.md <<EOF
# Agent Workspace

本目录是针对任务 **${TYPE}/${SCOPE}** 的独立 Agent 开发仓库。

- 主仓路径: \`${REPO_ROOT}\`
- Agent 仓库路径: \`${AGENT_DIR}\`
- 当前 Agent 分支: \`${BRANCH}\`
- 基线分支: \`${BASE_BRANCH}\`
- 创建时间(UTC): \`${CREATED_AT}\`

## 使用说明（人类 & Code Agent）

1. 在编辑器 / Codex / 其他 Agent 工具中，将项目根目录设置为本仓库根目录：
   \`${AGENT_DIR}\`

2. 所有改动请提交到当前分支：
   \`${BRANCH}\`

3. 本脚本已尝试为所有可访问的 submodule 以同名基线分支 \`${BASE_BRANCH}\` 创建/切换分支 \`${BRANCH}\`：
   - 若子仓存在 \`origin/${BASE_BRANCH}\` 或本地 \`${BASE_BRANCH}\`，则基于该分支创建；
   - 若子仓不存在该分支，则保持当前分支/commit 不变并打印提示。

4. 如需重新初始化 submodule，可在本仓库根目录执行：

   \`\`\`bash
   ./agent_clone.sh
   \`\`\`

5. 完成后，由人类在本仓库中整理 commit，并 push 到远端：

   \`\`\`bash
   git status
   git diff
   git commit ...
   git push origin ${BRANCH}
   \`\`\`

更多规则请参考主仓的 \`AGENTS.md\`。
EOF

  cat <<EOF

✅ Agent 仓库已创建并初始化完成。

  仓库目录: ${AGENT_DIR}
  分支:      ${BRANCH}
  基线分支:  ${BASE_BRANCH}

你可以在 Codex / IDE 中将项目根目录设为:
  ${AGENT_DIR}

如需重新初始化 submodule，可在 Agent 仓库根目录执行:
  ./agent_clone.sh

本仓库的元信息保存在:
  ${AGENT_DIR}/.agent-meta.yml

EOF
}

cleanup_agent_repo() {
  echo "==> 将删除 Agent 仓库目录: ${AGENT_DIR}"
  if [[ ! -d "${AGENT_DIR}" ]]; then
    echo "提示: 目录不存在，无需清理。"
    exit 0
  fi

  read -r -p "确认删除该目录及其所有内容? [y/N] " ans
  case "${ans}" in
  y | Y | yes | YES)
    rm -rf "${AGENT_DIR}"
    echo "🧹 已删除: ${AGENT_DIR}"
    ;;
  *)
    echo "取消删除。"
    ;;
  esac
}

list_agents() {
  echo "==> Agent 根目录: ${AGENT_ROOT}"
  if [[ ! -d "${AGENT_ROOT}" ]]; then
    echo "当前没有任何 Agent 仓库。"
    return 0
  fi

  printf "\n%-40s %-8s %-30s %-20s %-20s %-30s\n" "DIR" "TYPE" "SCOPE" "BASE_BRANCH" "CREATED_AT" "BRANCH"
  printf "%-40s %-8s %-30s %-20s %-20s %-30s\n" \
    "----------------------------------------" "--------" "------------------------------" "--------------------" "--------------------" "------------------------------"

  local any=0

  shopt -s nullglob
  for dir in "${AGENT_ROOT}"/*; do
    [[ -d "$dir" ]] || continue
    local meta="${dir}/.agent-meta.yml"
    [[ -f "${meta}" ]] || continue

    local name type scope branch base_branch created_at
    name="$(basename "${dir}")"
    type="$(awk -F': ' '/^type:/{print $2; exit}' "${meta}" || true)"
    scope="$(awk -F': ' '/^scope:/{print $2; exit}' "${meta}" || true)"
    branch="$(awk -F': ' '/^branch:/{print $2; exit}' "${meta}" || true)"
    base_branch="$(awk -F': ' '/^base_branch:/{print $2; exit}' "${meta}" || true)"
    created_at="$(awk -F': ' '/^created_at:/{print $2; exit}' "${meta}" || true)"

    printf "%-40s %-8s %-30s %-20s %-20s %-30s\n" "${name}" "${type}" "${scope}" "${base_branch}" "${created_at}" "${branch}"
    any=1
  done
  shopt -u nullglob

  if [[ "${any}" -eq 0 ]]; then
    echo "没有找到带 .agent-meta.yml 的 Agent 仓库。"
  fi
}

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

