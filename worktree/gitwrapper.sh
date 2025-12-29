#!/usr/bin/env bash
set -euo pipefail

########################################
# gitwrapper - Git Submodule Worktree Manager
#
# 四个核心命令:
#   checkout <branch>      - 切换分支 + 更新子模块
#   worktree <branch>      - 创建隔离 worktree
#   commit-push [message]  - 先子后父提交推送
#   pull                   - 拉取 + 更新子模块
#
# 设计原则:
#   - 无权限子模块不阻塞，但必须可观测
#   - worktree 子模块工作目录完全隔离
#   - 先子后父，保证指针可达性
########################################

# === 全局配置 ===
VERBOSE="${VERBOSE:-0}"
DRY_RUN="${DRY_RUN:-0}"
WORKTREE_BASE="${WORKTREE_BASE:-}"  # 默认 ../repo__<branch>

# === 颜色输出 ===
if [[ -t 1 ]]; then
  readonly C_RED='\033[0;31m'
  readonly C_GREEN='\033[0;32m'
  readonly C_YELLOW='\033[0;33m'
  readonly C_BLUE='\033[0;34m'
  readonly C_CYAN='\033[0;36m'
  readonly C_RESET='\033[0m'
else
  readonly C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_CYAN='' C_RESET=''
fi

# === 报告收集器 ===
REPORT_OK=()
REPORT_SKIP=()
REPORT_FAIL_AUTH=()
REPORT_FAIL_NOTFOUND=()
REPORT_FAIL_OTHER=()

# === 日志函数 ===
log_info()  { echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }
log_debug() { [[ "${VERBOSE}" -eq 1 ]] && echo -e "${C_BLUE}[DEBUG]${C_RESET} $*" || true; }

# === 工具函数 ===

# 获取仓库根目录
get_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || {
    log_error "当前目录不在 Git 仓库中"
    exit 1
  }
}

# 检查是否在 worktree 中
is_in_worktree() {
  local git_common_dir git_dir
  git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)"
  git_dir="$(git rev-parse --git-dir 2>/dev/null)"
  [[ "${git_common_dir}" != "${git_dir}" ]]
}

# 获取所有子模块路径
get_submodule_paths() {
  git config -f .gitmodules --get-regexp 'submodule\..*\.path' 2>/dev/null | awk '{print $2}' || true
}

# 检查子模块是否已初始化
is_submodule_initialized() {
  local path="$1"
  [[ -d "${path}" ]] && { [[ -d "${path}/.git" ]] || [[ -f "${path}/.git" ]]; }
}

# 检测子模块访问失败原因
# 返回: auth|notfound|other
detect_failure_reason() {
  local output="$1"
  if echo "${output}" | grep -qiE "(permission denied|access denied|authentication failed|could not read username|fatal: Authentication)"; then
    echo "auth"
  elif echo "${output}" | grep -qiE "(repository.*not found|remote.*not found|does not exist)"; then
    echo "notfound"
  else
    echo "other"
  fi
}

# 打印最终报告
print_report() {
  echo
  echo "═══════════════════════════════════════════════════════════════"
  echo "                         执行报告"
  echo "═══════════════════════════════════════════════════════════════"

  if [[ ${#REPORT_OK[@]} -gt 0 ]]; then
    echo -e "\n${C_GREEN}✓ 成功 (${#REPORT_OK[@]})${C_RESET}"
    printf '  %s\n' "${REPORT_OK[@]}"
  fi

  if [[ ${#REPORT_SKIP[@]} -gt 0 ]]; then
    echo -e "\n${C_YELLOW}⊘ 跳过 (${#REPORT_SKIP[@]})${C_RESET}"
    printf '  %s\n' "${REPORT_SKIP[@]}"
  fi

  if [[ ${#REPORT_FAIL_AUTH[@]} -gt 0 ]]; then
    echo -e "\n${C_RED}✗ 无权限 (${#REPORT_FAIL_AUTH[@]})${C_RESET}"
    printf '  %s\n' "${REPORT_FAIL_AUTH[@]}"
  fi

  if [[ ${#REPORT_FAIL_NOTFOUND[@]} -gt 0 ]]; then
    echo -e "\n${C_RED}✗ 仓库不存在 (${#REPORT_FAIL_NOTFOUND[@]})${C_RESET}"
    printf '  %s\n' "${REPORT_FAIL_NOTFOUND[@]}"
  fi

  if [[ ${#REPORT_FAIL_OTHER[@]} -gt 0 ]]; then
    echo -e "\n${C_RED}✗ 其他错误 (${#REPORT_FAIL_OTHER[@]})${C_RESET}"
    printf '  %s\n' "${REPORT_FAIL_OTHER[@]}"
  fi

  echo "═══════════════════════════════════════════════════════════════"

  local total_fail=$((${#REPORT_FAIL_AUTH[@]} + ${#REPORT_FAIL_NOTFOUND[@]} + ${#REPORT_FAIL_OTHER[@]}))
  if [[ ${total_fail} -gt 0 ]]; then
    echo -e "${C_YELLOW}提示: 有 ${total_fail} 个子模块不可用，但不影响其他功能${C_RESET}"
  fi
}

# 重置报告收集器
reset_report() {
  REPORT_OK=()
  REPORT_SKIP=()
  REPORT_FAIL_AUTH=()
  REPORT_FAIL_NOTFOUND=()
  REPORT_FAIL_OTHER=()
}

########################################
# 命令: checkout
# 切换到指定分支并更新子模块
########################################
cmd_checkout() {
  local branch="${1:-}"

  if [[ -z "${branch}" ]]; then
    log_error "用法: gitwrapper checkout <branch_name>"
    exit 1
  fi

  local repo_root
  repo_root="$(get_repo_root)"
  cd "${repo_root}"

  log_info "切换父仓库到分支: ${branch}"

  # 1. Fetch 最新 refs
  log_info "正在 fetch 远端..."
  git fetch --all --prune 2>&1 || log_warn "fetch 部分失败，继续执行"

  # 2. 切换分支
  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    log_info "切换到本地分支: ${branch}"
    git checkout "${branch}"
  elif git show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
    log_info "从远端创建并切换到分支: ${branch}"
    git checkout -b "${branch}" "origin/${branch}"
  else
    log_error "分支不存在: ${branch}"
    exit 1
  fi

  REPORT_OK+=("父仓库: ${branch}")

  # 3. 更新子模块
  log_info "正在更新子模块..."
  update_submodules_safe

  print_report
}

# 安全更新子模块（逐个处理，失败不阻塞）
update_submodules_safe() {
  local submodules
  submodules="$(get_submodule_paths)"

  if [[ -z "${submodules}" ]]; then
    log_info "没有配置子模块"
    return 0
  fi

  while IFS= read -r sm_path; do
    [[ -z "${sm_path}" ]] && continue

    log_debug "处理子模块: ${sm_path}"

    local output
    if output=$(git submodule update --init --recursive -- "${sm_path}" 2>&1); then
      REPORT_OK+=("子模块: ${sm_path}")
      log_ok "子模块更新成功: ${sm_path}"
    else
      local reason
      reason=$(detect_failure_reason "${output}")
      case "${reason}" in
        auth)
          REPORT_FAIL_AUTH+=("${sm_path}")
          log_warn "子模块无权限: ${sm_path}"
          ;;
        notfound)
          REPORT_FAIL_NOTFOUND+=("${sm_path}")
          log_warn "子模块仓库不存在: ${sm_path}"
          ;;
        *)
          REPORT_FAIL_OTHER+=("${sm_path}: ${output}")
          log_warn "子模块更新失败: ${sm_path}"
          ;;
      esac
    fi
  done <<< "${submodules}"
}

########################################
# 命令: worktree
# 创建隔离的 worktree，子模块也隔离
########################################
cmd_worktree() {
  local new_branch="${1:-}"
  local base_branch="${2:-}"

  if [[ -z "${new_branch}" ]]; then
    log_error "用法: gitwrapper worktree <new_branch> [base_branch]"
    exit 1
  fi

  local repo_root repo_name worktree_path
  repo_root="$(get_repo_root)"
  repo_name="$(basename "${repo_root}")"

  # 计算 worktree 路径
  if [[ -n "${WORKTREE_BASE}" ]]; then
    worktree_path="${WORKTREE_BASE}/${repo_name}__${new_branch}"
  else
    worktree_path="$(dirname "${repo_root}")/${repo_name}__${new_branch}"
  fi

  cd "${repo_root}"

  # 确定基线分支
  if [[ -z "${base_branch}" ]]; then
    base_branch="$(git rev-parse --abbrev-ref HEAD)"
    [[ "${base_branch}" == "HEAD" ]] && base_branch="$(git rev-parse HEAD)"
  fi

  log_info "创建 worktree"
  log_info "  新分支: ${new_branch}"
  log_info "  基线: ${base_branch}"
  log_info "  路径: ${worktree_path}"

  # 1. 检查目标路径
  if [[ -d "${worktree_path}" ]]; then
    log_error "目标路径已存在: ${worktree_path}"
    log_info "如需重建，请先执行: git worktree remove ${worktree_path}"
    exit 1
  fi

  # 2. 创建父仓库 worktree
  log_info "创建父仓库 worktree..."
  if git show-ref --verify --quiet "refs/heads/${new_branch}"; then
    # 分支已存在，直接 checkout
    git worktree add "${worktree_path}" "${new_branch}"
  else
    # 创建新分支
    git worktree add -b "${new_branch}" "${worktree_path}" "${base_branch}"
  fi

  REPORT_OK+=("父仓库 worktree: ${worktree_path}")

  # 3. 在新 worktree 中初始化子模块
  cd "${worktree_path}"

  log_info "在新 worktree 中初始化子模块..."
  init_submodules_in_worktree "${new_branch}" "${base_branch}"

  # 4. 创建 worktree 元数据
  create_worktree_metadata "${new_branch}" "${base_branch}" "${worktree_path}"

  print_report

  echo
  log_ok "Worktree 创建完成!"
  echo "  路径: ${worktree_path}"
  echo "  分支: ${new_branch}"
  echo
  echo "下一步:"
  echo "  cd ${worktree_path}"
}

# 在 worktree 中初始化子模块（带分支联动）
init_submodules_in_worktree() {
  local target_branch="$1"
  local base_branch="$2"

  local submodules
  submodules="$(get_submodule_paths)"

  if [[ -z "${submodules}" ]]; then
    log_info "没有配置子模块"
    return 0
  fi

  # Git 2.17+ 支持 worktree 中的子模块隔离
  # 每个 worktree 的子模块会有独立的工作目录

  while IFS= read -r sm_path; do
    [[ -z "${sm_path}" ]] && continue

    log_debug "处理子模块: ${sm_path}"

    local output
    if output=$(git submodule update --init --recursive -- "${sm_path}" 2>&1); then
      log_ok "子模块初始化成功: ${sm_path}"

      # 尝试分支联动
      if [[ -d "${sm_path}" ]] && { [[ -d "${sm_path}/.git" ]] || [[ -f "${sm_path}/.git" ]]; }; then
        checkout_submodule_branch "${sm_path}" "${target_branch}" "${base_branch}"
      fi

      REPORT_OK+=("子模块: ${sm_path}")
    else
      local reason
      reason=$(detect_failure_reason "${output}")
      case "${reason}" in
        auth)
          REPORT_FAIL_AUTH+=("${sm_path}")
          log_warn "子模块无权限，标记为只读: ${sm_path}"
          # 创建占位目录和说明文件
          mkdir -p "${sm_path}"
          echo "# 此子模块无访问权限" > "${sm_path}/.gitwrapper-unavailable"
          echo "原因: 认证失败" >> "${sm_path}/.gitwrapper-unavailable"
          ;;
        notfound)
          REPORT_FAIL_NOTFOUND+=("${sm_path}")
          log_warn "子模块仓库不存在: ${sm_path}"
          mkdir -p "${sm_path}"
          echo "# 此子模块仓库不存在" > "${sm_path}/.gitwrapper-unavailable"
          ;;
        *)
          REPORT_FAIL_OTHER+=("${sm_path}: ${output}")
          log_warn "子模块初始化失败: ${sm_path}"
          ;;
      esac
    fi
  done <<< "${submodules}"
}

# 为子模块切换/创建分支
checkout_submodule_branch() {
  local sm_path="$1"
  local target_branch="$2"
  local base_branch="$3"

  (
    cd "${sm_path}" || return 1

    # 检查远端是否有同名分支
    if git show-ref --verify --quiet "refs/remotes/origin/${target_branch}"; then
      log_debug "子模块 ${sm_path}: checkout 远端分支 ${target_branch}"
      git checkout -B "${target_branch}" "origin/${target_branch}" 2>/dev/null || true
    elif git show-ref --verify --quiet "refs/heads/${target_branch}"; then
      log_debug "子模块 ${sm_path}: checkout 本地分支 ${target_branch}"
      git checkout "${target_branch}" 2>/dev/null || true
    else
      # 创建新分支（基于当前 HEAD，即父仓库 pin 的 commit）
      log_debug "子模块 ${sm_path}: 创建新分支 ${target_branch}"
      git checkout -b "${target_branch}" 2>/dev/null || true
    fi
  )
}

# 创建 worktree 元数据
create_worktree_metadata() {
  local branch="$1"
  local base_branch="$2"
  local worktree_path="$3"
  local created_at
  created_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  cat > ".gitwrapper-meta.yml" << EOF
# gitwrapper worktree 元数据
# 由 gitwrapper worktree 命令自动生成

branch: ${branch}
base_branch: ${base_branch}
worktree_path: ${worktree_path}
created_at: ${created_at}
created_by: gitwrapper
EOF
}

########################################
# 命令: commit-push
# 先子后父的严格提交推送
########################################
cmd_commit_push() {
  local message="${1:-}"

  local repo_root
  repo_root="$(get_repo_root)"
  cd "${repo_root}"

  log_info "开始 commit-push 流程（先子后父）"

  # 1. 扫描有改动的子模块
  local changed_submodules=()
  local submodules
  submodules="$(get_submodule_paths)"

  if [[ -n "${submodules}" ]]; then
    while IFS= read -r sm_path; do
      [[ -z "${sm_path}" ]] && continue

      if ! is_submodule_initialized "${sm_path}"; then
        log_debug "子模块未初始化，跳过: ${sm_path}"
        continue
      fi

      # 检查子模块是否有改动
      if ! git -C "${sm_path}" diff --quiet 2>/dev/null || \
         ! git -C "${sm_path}" diff --cached --quiet 2>/dev/null || \
         [[ -n "$(git -C "${sm_path}" status --porcelain 2>/dev/null)" ]]; then
        changed_submodules+=("${sm_path}")
        log_info "检测到改动: ${sm_path}"
      fi
    done <<< "${submodules}"
  fi

  # 2. 检查父仓库 gitlink 改动
  local parent_has_gitlink_changes=false
  local gitlink_changes
  gitlink_changes="$(git diff --cached --name-only 2>/dev/null || true)"
  if [[ -n "${submodules}" ]]; then
    while IFS= read -r sm_path; do
      if echo "${gitlink_changes}" | grep -q "^${sm_path}$"; then
        parent_has_gitlink_changes=true
        log_info "父仓库有子模块指针改动: ${sm_path}"
      fi
    done <<< "${submodules}"
  fi

  # 3. 处理有改动的子模块
  if [[ ${#changed_submodules[@]} -gt 0 ]]; then
    log_info "开始处理 ${#changed_submodules[@]} 个有改动的子模块..."

    for sm_path in "${changed_submodules[@]}"; do
      process_submodule_commit_push "${sm_path}" "${message}"
    done
  fi

  # 4. 更新父仓库 gitlink 并提交推送
  process_parent_commit_push "${message}" "${changed_submodules[@]+"${changed_submodules[@]}"}"

  print_report
}

# 处理单个子模块的 commit-push
process_submodule_commit_push() {
  local sm_path="$1"
  local message="$2"

  log_info "处理子模块: ${sm_path}"

  (
    cd "${sm_path}" || {
      REPORT_FAIL_OTHER+=("${sm_path}: 无法进入目录")
      return 1
    }

    # 检查是否在可推送的分支上
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

    if [[ "${current_branch}" == "HEAD" ]]; then
      log_error "子模块 ${sm_path} 处于 detached HEAD 状态，无法推送"
      log_info "请先切换到分支: cd ${sm_path} && git checkout -b <branch_name>"
      REPORT_FAIL_OTHER+=("${sm_path}: detached HEAD")
      return 1
    fi

    # 暂存所有改动
    git add -A

    # 检查是否有东西要提交
    if git diff --cached --quiet; then
      log_info "子模块 ${sm_path} 没有需要提交的改动"
      REPORT_SKIP+=("${sm_path}: 无需提交")
      return 0
    fi

    # 提交
    local commit_msg="${message:-"chore: update from gitwrapper"}"
    git commit -m "${commit_msg}"
    log_ok "子模块已提交: ${sm_path}"

    # 推送
    log_info "推送子模块: ${sm_path} -> origin/${current_branch}"
    if git push origin "${current_branch}"; then
      log_ok "子模块推送成功: ${sm_path}"
      REPORT_OK+=("子模块: ${sm_path} (committed & pushed)")
    else
      log_error "子模块推送失败: ${sm_path}"
      REPORT_FAIL_OTHER+=("${sm_path}: push 失败")
      return 1
    fi
  )
}

# 处理父仓库的 commit-push
process_parent_commit_push() {
  local message="$1"
  shift
  local changed_submodules=("$@")

  log_info "处理父仓库..."

  # 暂存所有子模块指针变更
  if [[ ${#changed_submodules[@]} -gt 0 ]]; then
    for sm_path in "${changed_submodules[@]}"; do
      git add "${sm_path}" 2>/dev/null || true
    done
  fi

  # 暂存其他改动
  git add -A

  # 检查是否有东西要提交
  if git diff --cached --quiet; then
    log_info "父仓库没有需要提交的改动"
    REPORT_SKIP+=("父仓库: 无需提交")
    return 0
  fi

  # 验证子模块指针可达性
  log_info "验证子模块指针可达性..."
  verify_submodule_reachability

  # 提交
  local commit_msg="${message:-"chore: update submodules and parent"}"
  git commit -m "${commit_msg}"
  log_ok "父仓库已提交"

  # 推送
  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD)"

  log_info "推送父仓库: origin/${current_branch}"
  if git push origin "${current_branch}"; then
    log_ok "父仓库推送成功"
    REPORT_OK+=("父仓库: committed & pushed")
  else
    log_error "父仓库推送失败"
    REPORT_FAIL_OTHER+=("父仓库: push 失败")
    return 1
  fi
}

# 验证子模块指针在远端可达
verify_submodule_reachability() {
  local submodules
  submodules="$(get_submodule_paths)"

  [[ -z "${submodules}" ]] && return 0

  while IFS= read -r sm_path; do
    [[ -z "${sm_path}" ]] && continue

    if ! is_submodule_initialized "${sm_path}"; then
      continue
    fi

    # 获取父仓库期望的 commit
    local expected_commit
    expected_commit="$(git ls-tree HEAD "${sm_path}" 2>/dev/null | awk '{print $3}')"

    [[ -z "${expected_commit}" ]] && continue

    # 检查该 commit 是否在远端可达
    (
      cd "${sm_path}" || return 0

      # fetch 最新
      git fetch origin --quiet 2>/dev/null || return 0

      # 检查 commit 是否被任何远端分支包含
      if git branch -r --contains "${expected_commit}" 2>/dev/null | grep -q .; then
        log_debug "子模块 ${sm_path}: commit ${expected_commit:0:8} 在远端可达"
      else
        log_warn "子模块 ${sm_path}: commit ${expected_commit:0:8} 可能不在远端"
        # 这里只是警告，不阻塞（可能是本地新 commit 还没 push 的情况已在前面处理）
      fi
    )
  done <<< "${submodules}"
}

########################################
# 命令: pull
# 拉取父仓库并更新子模块
########################################
cmd_pull() {
  local repo_root
  repo_root="$(get_repo_root)"
  cd "${repo_root}"

  log_info "开始 pull 流程"

  # 1. 拉取父仓库
  log_info "拉取父仓库 (--ff-only)..."
  if git pull --ff-only; then
    log_ok "父仓库拉取成功"
    REPORT_OK+=("父仓库: pulled")
  else
    log_error "父仓库拉取失败（可能有分叉，需要手动处理）"
    log_info "建议: git pull --rebase 或 git merge"
    REPORT_FAIL_OTHER+=("父仓库: pull 失败")
    # 不退出，继续尝试更新子模块
  fi

  # 2. 更新子模块
  log_info "更新子模块..."
  update_submodules_safe

  print_report
}

########################################
# 命令: merge
# 合并 feature 分支（先子后父）
########################################
cmd_merge() {
  local feature_branch="${1:-}"
  local target_branch="${2:-development}"

  if [[ -z "${feature_branch}" ]]; then
    log_error "用法: gitwrapper merge <feature_branch> [target_branch]"
    log_info "示例: gitwrapper merge feature/login development"
    exit 1
  fi

  local repo_root
  repo_root="$(get_repo_root)"
  cd "${repo_root}"

  log_info "合并分支: ${feature_branch} -> ${target_branch}"
  log_info "策略: 先子模块，后父仓库"

  # 1. 确保在目标分支
  log_info "切换到目标分支: ${target_branch}"
  git checkout "${target_branch}"
  git pull --ff-only || log_warn "pull 失败，继续尝试合并"

  REPORT_OK+=("父仓库: checkout ${target_branch}")

  # 2. 找出 feature 分支中有改动的子模块
  local submodules
  submodules="$(get_submodule_paths)"

  if [[ -n "${submodules}" ]]; then
    log_info "检查子模块中的分支改动..."

    while IFS= read -r sm_path; do
      [[ -z "${sm_path}" ]] && continue

      if ! is_submodule_initialized "${sm_path}"; then
        log_debug "子模块未初始化，跳过: ${sm_path}"
        continue
      fi

      # 检查子模块是否有对应的 feature 分支
      (
        cd "${sm_path}" || exit 0

        # 先 fetch
        git fetch origin --quiet 2>/dev/null || true

        # 检查远端是否有这个分支
        if git show-ref --verify --quiet "refs/remotes/origin/${feature_branch}"; then
          log_info "子模块 ${sm_path}: 发现分支 ${feature_branch}，开始合并"

          # 确保子模块在目标分支
          if ! git show-ref --verify --quiet "refs/heads/${target_branch}"; then
            # 本地没有目标分支，从远端创建
            if git show-ref --verify --quiet "refs/remotes/origin/${target_branch}"; then
              git checkout -b "${target_branch}" "origin/${target_branch}"
            else
              log_warn "子模块 ${sm_path}: 目标分支 ${target_branch} 不存在，跳过"
              exit 0
            fi
          else
            git checkout "${target_branch}"
            git pull --ff-only 2>/dev/null || true
          fi

          # 合并 feature 分支
          if git merge "origin/${feature_branch}" -m "Merge ${feature_branch} into ${target_branch}"; then
            log_ok "子模块 ${sm_path}: 合并成功"
            git push origin "${target_branch}"
            echo "${sm_path}" >> "${repo_root}/.gitwrapper-merged-submodules"
          else
            log_error "子模块 ${sm_path}: 合并冲突，请手动解决"
            log_info "  cd ${sm_path}"
            log_info "  # 解决冲突后: git add . && git commit && git push"
            echo "${sm_path}:CONFLICT" >> "${repo_root}/.gitwrapper-merged-submodules"
          fi
        else
          log_debug "子模块 ${sm_path}: 没有分支 ${feature_branch}"
        fi
      )
    done <<< "${submodules}"
  fi

  # 3. 更新父仓库的子模块指针
  log_info "更新父仓库的子模块指针..."
  git submodule update --init --recursive 2>/dev/null || true

  # 暂存子模块变更
  if [[ -f ".gitwrapper-merged-submodules" ]]; then
    while IFS= read -r line; do
      local sm_path="${line%%:*}"
      git add "${sm_path}" 2>/dev/null || true
    done < ".gitwrapper-merged-submodules"
    rm -f ".gitwrapper-merged-submodules"

    if ! git diff --cached --quiet; then
      git commit -m "chore: update submodule pointers after merging ${feature_branch}"
      log_ok "子模块指针已更新"
    fi
  fi

  # 4. 合并父仓库的 feature 分支
  log_info "合并父仓库分支: ${feature_branch}"

  if git show-ref --verify --quiet "refs/remotes/origin/${feature_branch}"; then
    if git merge "origin/${feature_branch}" -m "Merge ${feature_branch} into ${target_branch}"; then
      log_ok "父仓库合并成功"
      REPORT_OK+=("父仓库: merged ${feature_branch}")
    else
      log_error "父仓库合并冲突，请手动解决"
      REPORT_FAIL_OTHER+=("父仓库: merge conflict")
      print_report
      exit 1
    fi
  elif git show-ref --verify --quiet "refs/heads/${feature_branch}"; then
    if git merge "${feature_branch}" -m "Merge ${feature_branch} into ${target_branch}"; then
      log_ok "父仓库合并成功"
      REPORT_OK+=("父仓库: merged ${feature_branch}")
    else
      log_error "父仓库合并冲突，请手动解决"
      REPORT_FAIL_OTHER+=("父仓库: merge conflict")
      print_report
      exit 1
    fi
  else
    log_warn "父仓库没有分支 ${feature_branch}，跳过父仓库合并"
    REPORT_SKIP+=("父仓库: 无分支 ${feature_branch}")
  fi

  # 5. 推送
  log_info "推送父仓库..."
  if git push origin "${target_branch}"; then
    log_ok "推送成功"
    REPORT_OK+=("父仓库: pushed ${target_branch}")
  else
    log_error "推送失败"
    REPORT_FAIL_OTHER+=("父仓库: push failed")
  fi

  print_report

  echo
  log_ok "合并完成: ${feature_branch} -> ${target_branch}"
}

########################################
# 命令: status
# 显示当前状态
########################################
cmd_status() {
  local repo_root
  repo_root="$(get_repo_root)"
  cd "${repo_root}"

  echo "═══════════════════════════════════════════════════════════════"
  echo "                      gitwrapper 状态"
  echo "═══════════════════════════════════════════════════════════════"

  # 父仓库状态
  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")"

  echo
  echo -e "${C_CYAN}父仓库${C_RESET}"
  echo "  路径: ${repo_root}"
  echo "  分支: ${current_branch}"

  local parent_status
  parent_status="$(git status --short 2>/dev/null)"
  if [[ -z "${parent_status}" ]]; then
    echo "  状态: 干净"
  else
    echo "  状态: 有改动"
    echo "${parent_status}" | head -10 | sed 's/^/    /'
    local total_changes
    total_changes="$(echo "${parent_status}" | wc -l | tr -d ' ')"
    [[ ${total_changes} -gt 10 ]] && echo "    ... 还有 $((total_changes - 10)) 个改动"
  fi

  # 检查是否在 worktree 中
  if is_in_worktree; then
    echo -e "  ${C_YELLOW}(这是一个 worktree)${C_RESET}"
    if [[ -f ".gitwrapper-meta.yml" ]]; then
      echo "  元数据:"
      sed 's/^/    /' .gitwrapper-meta.yml | head -5
    fi
  fi

  # 子模块状态
  local submodules
  submodules="$(get_submodule_paths)"

  if [[ -n "${submodules}" ]]; then
    echo
    echo -e "${C_CYAN}子模块${C_RESET}"

    while IFS= read -r sm_path; do
      [[ -z "${sm_path}" ]] && continue

      if [[ -f "${sm_path}/.gitwrapper-unavailable" ]]; then
        echo -e "  ${C_RED}✗${C_RESET} ${sm_path} (不可用)"
        continue
      fi

      if ! is_submodule_initialized "${sm_path}"; then
        echo -e "  ${C_YELLOW}?${C_RESET} ${sm_path} (未初始化)"
        continue
      fi

      local sm_branch sm_status
      sm_branch="$(git -C "${sm_path}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")"
      sm_status="$(git -C "${sm_path}" status --short 2>/dev/null | head -1)"

      if [[ -z "${sm_status}" ]]; then
        echo -e "  ${C_GREEN}✓${C_RESET} ${sm_path} (${sm_branch})"
      else
        echo -e "  ${C_YELLOW}*${C_RESET} ${sm_path} (${sm_branch}) - 有改动"
      fi
    done <<< "${submodules}"
  fi

  echo
  echo "═══════════════════════════════════════════════════════════════"
}

########################################
# 命令: list
# 列出所有 worktree
########################################
cmd_list() {
  local repo_root
  repo_root="$(get_repo_root)"
  cd "${repo_root}"

  echo "═══════════════════════════════════════════════════════════════"
  echo "                      Worktree 列表"
  echo "═══════════════════════════════════════════════════════════════"
  echo

  git worktree list

  echo
}

########################################
# 命令: remove
# 删除 worktree
########################################
cmd_remove() {
  local worktree_path="${1:-}"

  if [[ -z "${worktree_path}" ]]; then
    log_error "用法: gitwrapper remove <worktree_path>"
    exit 1
  fi

  local repo_root
  repo_root="$(get_repo_root)"
  cd "${repo_root}"

  log_info "删除 worktree: ${worktree_path}"

  # 检查是否存在
  if ! git worktree list | grep -q "${worktree_path}"; then
    log_error "Worktree 不存在: ${worktree_path}"
    exit 1
  fi

  # 确认
  echo -n "确认删除 worktree ${worktree_path}? [y/N] "
  read -r answer
  case "${answer}" in
    y|Y|yes|YES)
      git worktree remove --force "${worktree_path}"
      log_ok "Worktree 已删除: ${worktree_path}"
      ;;
    *)
      log_info "已取消"
      ;;
  esac
}

########################################
# 帮助信息
########################################
show_help() {
  cat << 'EOF'
gitwrapper - Git Submodule Worktree Manager

用法:
  gitwrapper <command> [options]

命令:
  checkout <branch>           切换到指定分支，更新子模块
  worktree <branch> [base]    创建隔离的 worktree（子模块也隔离）
  commit-push [message]       先子后父的提交推送
  pull                        拉取更新 + 更新子模块
  merge <feature> [target]    合并分支（先子后父，默认 target=development）
  status                      显示当前状态
  list                        列出所有 worktree
  remove <path>               删除 worktree

选项:
  -v, --verbose               详细输出
  -n, --dry-run               模拟执行，不实际操作
  -h, --help                  显示帮助

环境变量:
  WORKTREE_BASE               worktree 根目录（默认: 仓库同级目录）
  VERBOSE                     1 启用详细输出

示例:
  # 工作流 A: 单 worktree 开发
  gitwrapper checkout main
  # ... 开发 ...
  gitwrapper commit-push "feat: add feature"

  # 工作流 B: 并行 worktree 开发
  gitwrapper worktree feature/a main    # 创建 worktree A
  gitwrapper worktree feature/b main    # 创建 worktree B
  cd ../repo__feature__a && gitwrapper commit-push
  cd ../repo__feature__b && gitwrapper commit-push

  # 工作流 C: 合并回主线（先子后父）
  gitwrapper merge feature/a development
  gitwrapper merge feature/b development

  # 同步更新
  gitwrapper pull

EOF
}

########################################
# 主入口
########################################
main() {
  # 解析全局选项
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -n|--dry-run)
        DRY_RUN=1
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -*)
        log_error "未知选项: $1"
        show_help
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done

  local cmd="${1:-}"
  shift || true

  case "${cmd}" in
    checkout)
      cmd_checkout "$@"
      ;;
    worktree|wt)
      cmd_worktree "$@"
      ;;
    commit-push|cp)
      cmd_commit_push "$@"
      ;;
    pull)
      cmd_pull "$@"
      ;;
    merge)
      cmd_merge "$@"
      ;;
    status|st)
      cmd_status
      ;;
    list|ls)
      cmd_list
      ;;
    remove|rm)
      cmd_remove "$@"
      ;;
    ""|help)
      show_help
      ;;
    *)
      log_error "未知命令: ${cmd}"
      show_help
      exit 1
      ;;
  esac
}

# 如果直接执行脚本则运行 main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
