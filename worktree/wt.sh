#!/usr/bin/env bash
set -euo pipefail

# wt.sh
#
# 全托管 worktree + submodule 工作流（尽量贴近原生 git 的命令语义）：
# - worktree add/remove/list/status/init
# - commit-push：先子模块后父仓
# - merge：先子模块后父仓

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

CFG_INDEX_SH="${SCRIPT_DIR}/../cfg/index.sh"
if [[ -f "${CFG_INDEX_SH}" ]]; then
  # shellcheck source=/dev/null
  source "${CFG_INDEX_SH}" 2>/dev/null || true
fi

if ! declare -F agent_error >/dev/null 2>&1; then
  agent_error() {
    local code="${1:-E_WT_INTERNAL}"
    shift || true
    if [[ $# -gt 0 ]]; then
      echo "${code}: $*" >&2
    else
      echo "${code}" >&2
    fi
  }
fi

VERBOSE="${VERBOSE:-0}"
REMOTE_DEFAULT="${WT_REMOTE:-origin}"

if [[ -t 1 ]]; then
  readonly C_RED='\033[0;31m'
  readonly C_GREEN='\033[0;32m'
  readonly C_YELLOW='\033[0;33m'
  readonly C_CYAN='\033[0;36m'
  readonly C_RESET='\033[0m'
else
  readonly C_RED='' C_GREEN='' C_YELLOW='' C_CYAN='' C_RESET=''
fi

log_info() { echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
log_ok() { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
log_warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_debug() { [[ "${VERBOSE}" == "1" ]] && echo -e "${C_CYAN}[DEBUG]${C_RESET} $*" || true; }

die() {
  local code="$1"
  shift || true
  agent_error "${code}" "$*"
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || die "E_WT_CMD_MISSING" "未找到命令: ${cmd}"
}

strip_trailing_slash() {
  local p="${1:-}"
  while [[ "${p}" != "/" && "${p}" == */ ]]; do
    p="${p%/}"
  done
  echo "${p}"
}

realpath_safe() {
  local p="${1:-}"
  if command -v realpath >/dev/null 2>&1; then
    realpath "${p}" 2>/dev/null || true
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "${p}" 2>/dev/null || true
    return 0
  fi
  echo ""
}

git_repo_root() {
  local repo_path="${1:-.}"
  git -C "${repo_path}" rev-parse --show-toplevel 2>/dev/null || return 1
}

git_common_dir_abs() {
  local repo_path="${1:-.}"
  local root common rel
  root="$(git_repo_root "${repo_path}")" || return 1
  common="$(git -C "${repo_path}" rev-parse --git-common-dir 2>/dev/null)" || return 1
  if [[ "${common}" == /* ]]; then
    echo "${common}"
    return 0
  fi
  rel="${root}/${common}"
  echo "$(realpath_safe "${rel}")"
}

git_current_branch() {
  local repo_path="${1:-.}"
  git -C "${repo_path}" rev-parse --abbrev-ref HEAD 2>/dev/null || return 1
}

detect_jobs() {
  local jobs="${SUBMODULE_JOBS:-${WT_JOBS:-}}"
  if [[ -n "${jobs}" ]]; then
    echo "${jobs}"
    return 0
  fi

  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
  if [[ -z "${jobs}" ]]; then
    jobs="$(sysctl -n hw.ncpu 2>/dev/null || true)"
  fi
  [[ -z "${jobs}" ]] && jobs="8"
  echo "${jobs}"
}

get_submodule_paths_configured() {
  local repo_path="${1:-.}"
  git -C "${repo_path}" config -f .gitmodules --get-regexp 'submodule\..*\.path' 2>/dev/null | awk '{print $2}' || true
}

is_submodule_initialized() {
  local wt_path="$1"
  local sm_path="$2"
  local abs="${wt_path}/${sm_path}"
  [[ -d "${abs}/.git" ]] || [[ -f "${abs}/.git" ]]
}

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

submodule_config_branch_from_gitmodules() {
  local repo_path="$1"
  local sm_path="$2"
  local kv name branch
  while IFS= read -r kv; do
    [[ -z "${kv}" ]] && continue
    name="${kv%%.path *}"
    name="${name#submodule.}"
    if [[ "${kv##* }" == "${sm_path}" ]]; then
      branch="$(git -C "${repo_path}" config -f .gitmodules --get "submodule.${name}.branch" 2>/dev/null || true)"
      echo "${branch}"
      return 0
    fi
  done < <(git -C "${repo_path}" config -f .gitmodules --get-regexp 'submodule\..*\.path' 2>/dev/null || true)
  echo ""
}

git_ref_exists() {
  local repo_path="$1"
  local ref="$2"
  git -C "${repo_path}" show-ref --verify --quiet "${ref}" 2>/dev/null
}

git_has_upstream() {
  local repo_path="$1"
  git -C "${repo_path}" rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1
}

pick_branch_containing_head() {
  local repo_path="$1"
  local remote="$2"
  local raw line b branches

  raw="$(git -C "${repo_path}" branch -r --contains HEAD 2>/dev/null || true)"
  branches=""
  while IFS= read -r line; do
    line="${line#* }"
    b="$(echo "${line}" | sed 's/[[:space:]]//g')"
    [[ -z "${b}" ]] && continue
    [[ "${b}" == "${remote}/HEAD"* ]] && continue
    [[ "${b}" != "${remote}/"* ]] && continue
    branches+="${b}"$'\n'
  done <<< "${raw}"

  if [[ -z "${branches}" ]]; then
    echo ""
    return 0
  fi

  for b in "${remote}/dev" "${remote}/develop" "${remote}/development" "${remote}/main" "${remote}/master"; do
    if echo "${branches}" | grep -qx "${b}"; then
      echo "${b#${remote}/}"
      return 0
    fi
  done

  echo "$(echo "${branches}" | head -n 1 | sed 's/^'"${remote//\//\\/}"'\\///')"
}

standardize_one_submodule() {
  local wt_path="$1"
  local sm_path="$2"
  local parent_branch="$3"
  local remote="$4"
  local fetch="$5"
  local pull="$6"

  local sm_abs="${wt_path}/${sm_path}"
  if ! is_submodule_initialized "${wt_path}" "${sm_path}"; then
    log_debug "子模块未初始化，跳过: ${sm_path}"
    echo "SKIP:${sm_path} (未初始化)"
    return 0
  fi

  if [[ "${fetch}" == "1" ]]; then
    if ! git -C "${sm_abs}" fetch --prune "${remote}" >/dev/null 2>&1; then
      log_warn "子模块 fetch 失败（继续执行）: ${sm_path}"
    fi
  fi

  local current_branch desired_branch configured_branch
  current_branch="$(git -C "${sm_abs}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")"

  if git_ref_exists "${sm_abs}" "refs/heads/${parent_branch}" || git_ref_exists "${sm_abs}" "refs/remotes/${remote}/${parent_branch}"; then
    desired_branch="${parent_branch}"
  else
    configured_branch="$(submodule_config_branch_from_gitmodules "${wt_path}" "${sm_path}")"
    if [[ -n "${configured_branch}" ]] && (git_ref_exists "${sm_abs}" "refs/heads/${configured_branch}" || git_ref_exists "${sm_abs}" "refs/remotes/${remote}/${configured_branch}"); then
      desired_branch="${configured_branch}"
    elif [[ "${current_branch}" != "HEAD" ]]; then
      desired_branch="${current_branch}"
    else
      desired_branch="$(pick_branch_containing_head "${sm_abs}" "${remote}")"
      [[ -z "${desired_branch}" ]] && desired_branch="${parent_branch}"
    fi
  fi

  if [[ -z "${desired_branch}" ]]; then
    echo "SKIP:${sm_path} (无法确定目标分支)"
    return 0
  fi

  if [[ "${current_branch}" == "${desired_branch}" ]]; then
    : # 已在目标分支
  else
    if git_ref_exists "${sm_abs}" "refs/heads/${desired_branch}"; then
      git -C "${sm_abs}" checkout "${desired_branch}" >/dev/null 2>&1 || {
        echo "FAIL:${sm_path} (checkout ${desired_branch} 失败)"
        return 0
      }
    elif git_ref_exists "${sm_abs}" "refs/remotes/${remote}/${desired_branch}"; then
      git -C "${sm_abs}" checkout -B "${desired_branch}" "${remote}/${desired_branch}" >/dev/null 2>&1 || {
        echo "FAIL:${sm_path} (checkout ${remote}/${desired_branch} 失败)"
        return 0
      }
    else
      git -C "${sm_abs}" checkout -b "${desired_branch}" >/dev/null 2>&1 || {
        echo "FAIL:${sm_path} (创建分支 ${desired_branch} 失败)"
        return 0
      }
    fi
  fi

  if git_ref_exists "${sm_abs}" "refs/remotes/${remote}/${desired_branch}"; then
    git -C "${sm_abs}" branch --set-upstream-to "${remote}/${desired_branch}" "${desired_branch}" >/dev/null 2>&1 || true
  fi

  if [[ "${pull}" == "1" ]] && git_has_upstream "${sm_abs}"; then
    if ! git -C "${sm_abs}" pull --ff-only >/dev/null 2>&1; then
      log_warn "子模块 pull --ff-only 失败（继续执行）: ${sm_path}"
    fi
  fi

  echo "OK:${sm_path} → ${desired_branch}"
}

cmd_init() {
  local wt_path="."
  local jobs
  jobs="$(detect_jobs)"
  local fetch="1"
  local pull="1"
  local remote="${REMOTE_DEFAULT}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --jobs)
        jobs="${2:-}"
        [[ -z "${jobs}" ]] && die "E_WT_ARG_MISSING" "--jobs 需要参数"
        shift 2
        ;;
      --no-fetch)
        fetch="0"
        shift
        ;;
      --no-pull)
        pull="0"
        shift
        ;;
      --remote)
        remote="${2:-}"
        [[ -z "${remote}" ]] && die "E_WT_ARG_MISSING" "--remote 需要参数"
        shift 2
        ;;
      -h|--help)
        cat <<'EOF'
用法:
  wt.sh worktree init [<worktree_path>] [--jobs N] [--no-fetch] [--no-pull] [--remote origin]
EOF
        return 0
        ;;
      -*)
        die "E_WT_ARG_INVALID" "未知选项: $1"
        ;;
      *)
        wt_path="$1"
        shift
        ;;
    esac
  done

  wt_path="$(strip_trailing_slash "${wt_path}")"
  require_cmd git

  if ! git -C "${wt_path}" rev-parse --git-dir >/dev/null 2>&1; then
    die "E_WT_NOT_GIT_REPO" "目录不是 Git 仓库: ${wt_path}"
  fi

  local parent_branch
  parent_branch="$(git_current_branch "${wt_path}")" || die "E_WT_GIT_FAILED" "无法获取父仓分支"
  [[ "${parent_branch}" == "HEAD" ]] && die "E_WT_BRANCH_DETACHED" "父仓 detached HEAD，先 checkout 到分支再执行"

  log_info "父仓分支: ${parent_branch}"

  local submodules
  submodules="$(get_submodule_paths_configured "${wt_path}")"
  if [[ -z "${submodules}" ]]; then
    log_ok "没有配置子模块，无需处理"
    return 0
  fi

  local report_ok=()
  local report_skip=()
  local report_fail_auth=()
  local report_fail_notfound=()
  local report_fail_other=()

  log_info "初始化/更新子模块（失败不阻塞）..."
  git -C "${wt_path}" submodule init >/dev/null 2>&1 || true

  while IFS= read -r sm_path; do
    [[ -z "${sm_path}" ]] && continue
    local output
    if output="$(git -C "${wt_path}" -c submodule.alternateErrorStrategy=info submodule update --init --recursive --jobs "${jobs}" -- "${sm_path}" 2>&1)"; then
      report_ok+=("update: ${sm_path}")
    else
      case "$(detect_failure_reason "${output}")" in
        auth) report_fail_auth+=("update: ${sm_path}") ;;
        notfound) report_fail_notfound+=("update: ${sm_path}") ;;
        *) report_fail_other+=("update: ${sm_path} (${output})") ;;
      esac
    fi
  done <<< "${submodules}"

  log_info "标准化子模块分支（remote=${remote}, fetch=${fetch}, pull=${pull})..."
  local sm_all
  sm_all="$(git -C "${wt_path}" submodule foreach --recursive 'echo "$sm_path"' 2>/dev/null || true)"
  [[ -z "${sm_all}" ]] && sm_all="${submodules}"

  while IFS= read -r sm_path; do
    [[ -z "${sm_path}" ]] && continue
    local result
    result="$(standardize_one_submodule "${wt_path}" "${sm_path}" "${parent_branch}" "${remote}" "${fetch}" "${pull}")"
    case "${result}" in
      OK:*) report_ok+=("${result#OK:}") ;;
      SKIP:*) report_skip+=("${result#SKIP:}") ;;
      FAIL:*) report_fail_other+=("${result#FAIL:}") ;;
      *) report_fail_other+=("${sm_path} (未知结果: ${result})") ;;
    esac
  done <<< "${sm_all}"

  echo
  echo "═══════════════════════════════════════════════════════════════"
  echo "                         wt 执行报告"
  echo "═══════════════════════════════════════════════════════════════"
  if [[ ${#report_ok[@]} -gt 0 ]]; then
    echo -e "\n${C_GREEN}✓ 成功 (${#report_ok[@]})${C_RESET}"
    printf '  %s\n' "${report_ok[@]}"
  fi
  if [[ ${#report_skip[@]} -gt 0 ]]; then
    echo -e "\n${C_YELLOW}⊘ 跳过 (${#report_skip[@]})${C_RESET}"
    printf '  %s\n' "${report_skip[@]}"
  fi
  if [[ ${#report_fail_auth[@]} -gt 0 ]]; then
    echo -e "\n${C_RED}✗ 无权限 (${#report_fail_auth[@]})${C_RESET}"
    printf '  %s\n' "${report_fail_auth[@]}"
  fi
  if [[ ${#report_fail_notfound[@]} -gt 0 ]]; then
    echo -e "\n${C_RED}✗ 仓库不存在 (${#report_fail_notfound[@]})${C_RESET}"
    printf '  %s\n' "${report_fail_notfound[@]}"
  fi
  if [[ ${#report_fail_other[@]} -gt 0 ]]; then
    echo -e "\n${C_RED}✗ 其他错误 (${#report_fail_other[@]})${C_RESET}"
    printf '  %s\n' "${report_fail_other[@]}"
  fi
  echo "═══════════════════════════════════════════════════════════════"
}

cmd_list() {
  require_cmd git
  local repo_root
  repo_root="$(git_repo_root ".")" || die "E_WT_NOT_GIT_REPO" "当前目录不在 Git 仓库中"
  git -C "${repo_root}" worktree list
}

cmd_status() {
  require_cmd git
  local wt_path="${1:-.}"
  if ! git -C "${wt_path}" rev-parse --git-dir >/dev/null 2>&1; then
    die "E_WT_NOT_GIT_REPO" "目录不是 Git 仓库: ${wt_path}"
  fi

  local repo_root parent_branch
  repo_root="$(git_repo_root "${wt_path}")"
  parent_branch="$(git_current_branch "${wt_path}")" || parent_branch="?"

  echo "═══════════════════════════════════════════════════════════════"
  echo "                          wt 状态"
  echo "═══════════════════════════════════════════════════════════════"
  echo "父仓: ${repo_root}"
  echo "分支: ${parent_branch}"
  echo
  git -C "${wt_path}" status --short | head -20 || true

  local submodules
  submodules="$(git -C "${wt_path}" submodule foreach --recursive 'echo "$sm_path"' 2>/dev/null || true)"
  [[ -z "${submodules}" ]] && submodules="$(get_submodule_paths_configured "${wt_path}")"

  if [[ -n "${submodules}" ]]; then
    echo
    echo "子模块:"
    while IFS= read -r sm_path; do
      [[ -z "${sm_path}" ]] && continue
      if ! is_submodule_initialized "${wt_path}" "${sm_path}"; then
        echo "  ? ${sm_path} (未初始化)"
        continue
      fi
      local sm_abs sm_branch sm_dirty
      sm_abs="${wt_path}/${sm_path}"
      sm_branch="$(git -C "${sm_abs}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")"
      sm_dirty="$(git -C "${sm_abs}" status --short 2>/dev/null | head -n 1 || true)"
      if [[ -z "${sm_dirty}" ]]; then
        echo "  ✓ ${sm_path} (${sm_branch})"
      else
        echo "  * ${sm_path} (${sm_branch})"
      fi
    done <<< "${submodules}"
  fi
  echo
  echo "═══════════════════════════════════════════════════════════════"
}

cmd_add() {
  require_cmd git

  local new_branch=""
  local wt_path=""
  local start_point=""
  local init="1"
  local jobs
  jobs="$(detect_jobs)"
  local fetch="1"
  local pull="1"
  local remote="${REMOTE_DEFAULT}"
  local force="0"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -b|--branch)
        new_branch="${2:-}"
        [[ -z "${new_branch}" ]] && die "E_WT_ARG_MISSING" "-b/--branch 需要参数"
        shift 2
        ;;
      --no-init)
        init="0"
        shift
        ;;
      --jobs)
        jobs="${2:-}"
        [[ -z "${jobs}" ]] && die "E_WT_ARG_MISSING" "--jobs 需要参数"
        shift 2
        ;;
      --no-fetch)
        fetch="0"
        shift
        ;;
      --no-pull)
        pull="0"
        shift
        ;;
      --remote)
        remote="${2:-}"
        [[ -z "${remote}" ]] && die "E_WT_ARG_MISSING" "--remote 需要参数"
        shift 2
        ;;
      --force)
        force="1"
        shift
        ;;
      -h|--help)
        cat <<'EOF'
用法（尽量贴近原生 git）:
  wt.sh worktree add [-b <new-branch>] <path> [<start-point>] [--no-init] [--no-fetch] [--no-pull]
EOF
        return 0
        ;;
      -*)
        die "E_WT_ARG_INVALID" "未知选项: $1"
        ;;
      *)
        if [[ -z "${wt_path}" ]]; then
          wt_path="$1"
        elif [[ -z "${start_point}" ]]; then
          start_point="$1"
        else
          die "E_WT_ARG_INVALID" "多余参数: $1"
        fi
        shift
        ;;
    esac
  done

  [[ -z "${wt_path}" ]] && die "E_WT_ARG_MISSING" "worktree add 需要 <path>"

  local repo_root
  repo_root="$(git_repo_root ".")" || die "E_WT_NOT_GIT_REPO" "当前目录不在 Git 仓库中"

  log_info "创建 worktree: ${wt_path}"
  local cmd=(git -C "${repo_root}" worktree add)
  if [[ "${force}" == "1" ]]; then
    cmd+=(--force)
  fi
  if [[ -n "${new_branch}" ]]; then
    cmd+=(-b "${new_branch}")
  fi
  cmd+=("${wt_path}")
  if [[ -n "${start_point}" ]]; then
    cmd+=("${start_point}")
  fi
  "${cmd[@]}"
  log_ok "worktree 已创建: ${wt_path}"

  if [[ "${init}" == "1" ]]; then
    local args=(worktree init "${wt_path}" --jobs "${jobs}" --remote "${remote}")
    if [[ "${fetch}" == "0" ]]; then
      args+=(--no-fetch)
    fi
    if [[ "${pull}" == "0" ]]; then
      args+=(--no-pull)
    fi
    main "${args[@]}"
  fi
}

worktree_find_gitdir() {
  local repo_root="$1"
  local want_path="$2"

  local want_abs
  want_abs="$(realpath_safe "${want_path}")"
  want_path="$(strip_trailing_slash "${want_path}")"
  want_abs="$(strip_trailing_slash "${want_abs}")"

  local current_path="" line
  while IFS= read -r line; do
    if [[ "${line}" == worktree\ * ]]; then
      current_path="${line#worktree }"
      current_path="$(strip_trailing_slash "${current_path}")"
      continue
    fi
    if [[ "${line}" == gitdir\ * ]]; then
      local gitdir="${line#gitdir }"
      local cur_abs
      cur_abs="$(realpath_safe "${current_path}")"
      cur_abs="$(strip_trailing_slash "${cur_abs}")"

      if [[ -n "${want_abs}" && -n "${cur_abs}" && "${cur_abs}" == "${want_abs}" ]]; then
        echo "${gitdir}"
        return 0
      fi
      if [[ "${current_path}" == "${want_path}" ]]; then
        echo "${gitdir}"
        return 0
      fi
    fi
  done < <(git -C "${repo_root}" worktree list --porcelain 2>/dev/null || true)

  echo ""
}

safe_rm_rf() {
  local target="$1"
  [[ -z "${target}" ]] && die "E_WT_INTERNAL" "删除路径为空"
  [[ "${target}" == "/" ]] && die "E_WT_INTERNAL" "拒绝删除 /"
  rm -rf "${target}"
}

cmd_remove() {
  require_cmd git
  local wt_path=""
  local yes="0"
  local force_submodules="0"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y|--yes)
        yes="1"
        shift
        ;;
      --force-submodules)
        force_submodules="1"
        shift
        ;;
      -h|--help)
        cat <<'EOF'
用法:
  wt.sh worktree remove <worktree_path> [-y|--yes] [--force-submodules]
EOF
        return 0
        ;;
      -*)
        die "E_WT_ARG_INVALID" "未知选项: $1"
        ;;
      *)
        wt_path="$1"
        shift
        ;;
    esac
  done

  [[ -z "${wt_path}" ]] && die "E_WT_ARG_MISSING" "worktree remove 需要 <worktree_path>"
  wt_path="$(strip_trailing_slash "${wt_path}")"

  local repo_root
  repo_root="$(git_repo_root ".")" || die "E_WT_NOT_GIT_REPO" "当前目录不在 Git 仓库中"

  local repo_root_abs wt_abs
  repo_root_abs="$(realpath_safe "${repo_root}")"
  wt_abs="$(realpath_safe "${wt_path}")"
  if [[ -n "${wt_abs}" && -n "${repo_root_abs}" && "${wt_abs}" == "${repo_root_abs}" ]]; then
    die "E_WT_ARG_INVALID" "拒绝删除当前工作区（仓库根目录）: ${wt_path}"
  fi

  if [[ "${yes}" != "1" ]]; then
    echo -n "确认删除 worktree '${wt_path}' ? [y/N] "
    local answer=""
    read -r answer
    case "${answer}" in
      y|Y|yes|YES) ;;
      *) log_info "已取消"; return 0 ;;
    esac
  fi

  log_info "删除 worktree: ${wt_path}"
  local remove_out=""
  if remove_out="$(git -C "${repo_root}" worktree remove --force "${wt_path}" 2>&1)"; then
    log_ok "worktree 已删除: ${wt_path}"
    return 0
  fi

  if echo "${remove_out}" | grep -qi "containing submodules cannot be moved or removed"; then
    log_warn "检测到 worktree 含子模块，尝试 deinit 后重试..."
    git -C "${wt_path}" submodule deinit -f --all >/dev/null 2>&1 || true

    if git -C "${repo_root}" worktree remove --force "${wt_path}" >/dev/null 2>&1; then
      log_ok "worktree 已删除: ${wt_path}"
      return 0
    fi

    if [[ "${force_submodules}" != "1" ]]; then
      die "E_WT_WORKTREE_REMOVE_SUBMODULES" "worktree 含子模块导致 remove 失败；可重试: wt.sh worktree remove --force-submodules -y ${wt_path}"
    fi

    log_warn "使用 --force-submodules 强制清理（rm -rf + 删除元数据 + prune）..."

    local gitdir common_dir
    gitdir="$(worktree_find_gitdir "${repo_root}" "${wt_path}")"
    common_dir="$(git_common_dir_abs "${repo_root}")"

    if [[ -n "${gitdir}" ]]; then
      local gitdir_abs="${gitdir}"
      if [[ "${gitdir_abs}" != /* ]]; then
        gitdir_abs="${repo_root}/${gitdir_abs}"
      fi
      gitdir_abs="$(realpath_safe "${gitdir_abs}")"

      if [[ -n "${common_dir}" && -n "${gitdir_abs}" && "${gitdir_abs}" == "${common_dir}/worktrees/"* ]]; then
        safe_rm_rf "${gitdir_abs}"
      else
        log_warn "gitdir 路径不在 common_dir 下，拒绝删除: ${gitdir_abs}"
      fi
    else
      log_warn "未找到 worktree 元数据 gitdir（继续尝试 prune）"
    fi

    if [[ -d "${wt_path}" || -f "${wt_path}" ]]; then
      safe_rm_rf "${wt_path}"
    fi

    git -C "${repo_root}" worktree prune >/dev/null 2>&1 || true
    log_ok "强制清理完成: ${wt_path}"
    return 0
  fi

  die "E_WT_WORKTREE_REMOVE_FAILED" "删除失败: ${remove_out}"
}

cmd_commit_push() {
  require_cmd git
  local message=""
  local wt_path="."
  local remote="${REMOTE_DEFAULT}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path)
        wt_path="${2:-}"
        [[ -z "${wt_path}" ]] && die "E_WT_ARG_MISSING" "--path 需要参数"
        shift 2
        ;;
      --remote)
        remote="${2:-}"
        [[ -z "${remote}" ]] && die "E_WT_ARG_MISSING" "--remote 需要参数"
        shift 2
        ;;
      -h|--help)
        cat <<'EOF'
用法:
  wt.sh worktree commit-push [message] [--path <worktree_path>] [--remote origin]
EOF
        return 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        die "E_WT_ARG_INVALID" "未知选项: $1"
        ;;
      *)
        if [[ -z "${message}" ]]; then
          message="$1"
          shift
        else
          die "E_WT_ARG_INVALID" "多余参数: $1"
        fi
        ;;
    esac
  done

  if ! git -C "${wt_path}" rev-parse --git-dir >/dev/null 2>&1; then
    die "E_WT_NOT_GIT_REPO" "目录不是 Git 仓库: ${wt_path}"
  fi

  local parent_branch
  parent_branch="$(git_current_branch "${wt_path}")" || die "E_WT_GIT_FAILED" "无法获取父仓分支"
  [[ "${parent_branch}" == "HEAD" ]] && die "E_WT_BRANCH_DETACHED" "父仓 detached HEAD，无法 commit-push"

  local submodules
  submodules="$(git -C "${wt_path}" submodule foreach --recursive 'echo "$sm_path"' 2>/dev/null || true)"
  [[ -z "${submodules}" ]] && submodules="$(get_submodule_paths_configured "${wt_path}")"

  if [[ -n "${submodules}" ]]; then
    while IFS= read -r sm_path; do
      [[ -z "${sm_path}" ]] && continue
      if ! is_submodule_initialized "${wt_path}" "${sm_path}"; then
        continue
      fi

      local sm_abs sm_branch
      sm_abs="${wt_path}/${sm_path}"
      if [[ -z "$(git -C "${sm_abs}" status --porcelain 2>/dev/null || true)" ]]; then
        continue
      fi

      sm_branch="$(git_current_branch "${sm_abs}")" || sm_branch="HEAD"
      [[ "${sm_branch}" == "HEAD" ]] && die "E_WT_SUBMODULE_DETACHED" "子模块 detached HEAD，先执行: wt.sh worktree init ${wt_path}"

      log_info "子模块 commit-push: ${sm_path} (${sm_branch})"
      git -C "${sm_abs}" add -A
      git -C "${sm_abs}" diff --cached --quiet && continue

      git -C "${sm_abs}" commit -m "${message:-"chore: update ${sm_path}"}"
      git -C "${sm_abs}" push -u "${remote}" "${sm_branch}" || die "E_WT_SUBMODULE_PUSH_FAILED" "子模块 push 失败: ${sm_path}"
    done <<< "${submodules}"
  fi

  log_info "父仓 commit-push: ${parent_branch}"
  git -C "${wt_path}" add -A
  if git -C "${wt_path}" diff --cached --quiet; then
    log_ok "父仓无改动，跳过提交"
    return 0
  fi

  git -C "${wt_path}" commit -m "${message:-"chore: update submodules and parent"}"
  git -C "${wt_path}" push -u "${remote}" "${parent_branch}"
  log_ok "commit-push 完成"
}

cmd_merge() {
  require_cmd git
  local feature_branch=""
  local target_branch="development"
  local wt_path="."
  local remote="${REMOTE_DEFAULT}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path)
        wt_path="${2:-}"
        [[ -z "${wt_path}" ]] && die "E_WT_ARG_MISSING" "--path 需要参数"
        shift 2
        ;;
      --remote)
        remote="${2:-}"
        [[ -z "${remote}" ]] && die "E_WT_ARG_MISSING" "--remote 需要参数"
        shift 2
        ;;
      -h|--help)
        cat <<'EOF'
用法:
  wt.sh worktree merge <feature_branch> [target_branch] [--path <worktree_path>] [--remote origin]
EOF
        return 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        die "E_WT_ARG_INVALID" "未知选项: $1"
        ;;
      *)
        if [[ -z "${feature_branch}" ]]; then
          feature_branch="$1"
        elif [[ "${target_branch}" == "development" ]]; then
          target_branch="$1"
        else
          die "E_WT_ARG_INVALID" "多余参数: $1"
        fi
        shift
        ;;
    esac
  done

  [[ -z "${feature_branch}" ]] && die "E_WT_ARG_MISSING" "用法: wt.sh worktree merge <feature_branch> [target_branch]"

  log_info "合并分支: ${feature_branch} -> ${target_branch}"
  log_info "策略: 先子模块，后父仓库"

  git -C "${wt_path}" checkout "${target_branch}"
  git -C "${wt_path}" pull --ff-only >/dev/null 2>&1 || log_warn "父仓 pull --ff-only 失败（继续执行）"

  local repo_root
  repo_root="$(git_repo_root "${wt_path}")" || die "E_WT_NOT_GIT_REPO" "目录不是 Git 仓库: ${wt_path}"

  local submodules
  submodules="$(git -C "${wt_path}" submodule foreach --recursive 'echo "$sm_path"' 2>/dev/null || true)"
  [[ -z "${submodules}" ]] && submodules="$(get_submodule_paths_configured "${wt_path}")"

  local merged_file="${repo_root}/.wt-merged-submodules"
  rm -f "${merged_file}" 2>/dev/null || true

  if [[ -n "${submodules}" ]]; then
    while IFS= read -r sm_path; do
      [[ -z "${sm_path}" ]] && continue
      if ! is_submodule_initialized "${wt_path}" "${sm_path}"; then
        continue
      fi
      (
        local sm_abs="${wt_path}/${sm_path}"
        cd "${sm_abs}" || exit 0

        git fetch "${remote}" --quiet 2>/dev/null || true
        if git_ref_exists "." "refs/remotes/${remote}/${feature_branch}"; then
          log_info "子模块 ${sm_path}: 合并 ${feature_branch} -> ${target_branch}"

          if ! git_ref_exists "." "refs/heads/${target_branch}"; then
            if git_ref_exists "." "refs/remotes/${remote}/${target_branch}"; then
              git checkout -b "${target_branch}" "${remote}/${target_branch}"
            else
              log_warn "子模块 ${sm_path}: 目标分支 ${target_branch} 不存在，跳过"
              exit 0
            fi
          else
            git checkout "${target_branch}"
            git pull --ff-only 2>/dev/null || true
          fi

          if git merge "${remote}/${feature_branch}" -m "Merge ${feature_branch} into ${target_branch}"; then
            git push "${remote}" "${target_branch}" >/dev/null 2>&1 || true
            echo "${sm_path}" >> "${merged_file}"
            log_ok "子模块 ${sm_path}: 合并成功"
          else
            echo "${sm_path}:CONFLICT" >> "${merged_file}"
            die "E_WT_MERGE_CONFLICT" "子模块 ${sm_path} 合并冲突，请手动解决后重试"
          fi
        fi
      )
    done <<< "${submodules}"
  fi

  git -C "${wt_path}" submodule update --init --recursive >/dev/null 2>&1 || true
  if [[ -f "${merged_file}" ]]; then
    while IFS= read -r line; do
      local sm_path="${line%%:*}"
      [[ -z "${sm_path}" ]] && continue
      git -C "${wt_path}" add "${sm_path}" 2>/dev/null || true
    done < "${merged_file}"
    rm -f "${merged_file}" 2>/dev/null || true

    if ! git -C "${wt_path}" diff --cached --quiet; then
      git -C "${wt_path}" commit -m "chore: update submodule pointers after merging ${feature_branch}"
    fi
  fi

  if git_ref_exists "${wt_path}" "refs/remotes/${remote}/${feature_branch}"; then
    git -C "${wt_path}" merge "${remote}/${feature_branch}" -m "Merge ${feature_branch} into ${target_branch}"
  elif git_ref_exists "${wt_path}" "refs/heads/${feature_branch}"; then
    git -C "${wt_path}" merge "${feature_branch}" -m "Merge ${feature_branch} into ${target_branch}"
  else
    log_warn "父仓没有分支 ${feature_branch}，跳过父仓合并"
  fi

  git -C "${wt_path}" push "${remote}" "${target_branch}" >/dev/null 2>&1 || log_warn "父仓 push 失败（需要手动处理）"
  log_ok "合并完成: ${feature_branch} -> ${target_branch}"
}

show_help() {
  cat <<'EOF'
wt.sh - worktree + submodule workflow

用法:
  wt.sh worktree <command> [args...]

worktree 命令:
  init [path]
  add [-b <branch>] <path> [<start-point>]
  remove <path> [--force-submodules]
  list
  status [path]
  commit-push [message]
  merge <feature> [target]
EOF
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -h|--help|help)
        show_help
        return 0
        ;;
      *)
        break
        ;;
    esac
  done

  local group="${1:-}"
  shift || true

  case "${group}" in
    worktree|wt)
      local cmd="${1:-}"
      shift || true
      case "${cmd}" in
        init) cmd_init "$@" ;;
        add) cmd_add "$@" ;;
        remove|rm) cmd_remove "$@" ;;
        list|ls) cmd_list ;;
        status|st) cmd_status "$@" ;;
        commit-push|cp) cmd_commit_push "$@" ;;
        merge) cmd_merge "$@" ;;
        ""|help|-h|--help) show_help ;;
        *) die "E_WT_SUBCOMMAND_UNKNOWN" "未知 worktree 子命令: ${cmd}" ;;
      esac
      ;;
    ""|help|-h|--help)
      show_help
      ;;
    *)
      die "E_WT_GROUP_UNKNOWN" "未知命令组: ${group}"
      ;;
  esac
}

main "$@"
