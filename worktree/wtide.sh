#!/usr/bin/env bash
set -euo pipefail

# wtide.sh
#
# 面向 AI IDE 的 worktree 后置脚本：IDE 负责 git worktree add/remove，本脚本负责：
# - 子模块递归 init/update（失败不阻塞，但会报告）
# - 子模块分支标准化：优先切到父仓同名分支；不存在则回退到子模块配置/当前分支
# - worktree remove 失败（含 submodules）时提供一键安全删除

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

CFG_INDEX_SH="${SCRIPT_DIR}/../cfg/index.sh"
if [[ -f "${CFG_INDEX_SH}" ]]; then
  # shellcheck source=/dev/null
  source "${CFG_INDEX_SH}" 2>/dev/null || true
fi

if ! declare -F agent_error >/dev/null 2>&1; then
  agent_error() {
    local code="${1:-E_WTIDE_INTERNAL}"
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

resolve_exe() {
  local candidate=""
  for candidate in "$@"; do
    [[ -z "${candidate}" ]] && continue
    if [[ "${candidate}" == */* ]]; then
      [[ -x "${candidate}" ]] && { echo "${candidate}"; return 0; }
      continue
    fi
    if command -v "${candidate}" >/dev/null 2>&1; then
      command -v "${candidate}"
      return 0
    fi
  done
  return 1
}

# IDE/GUI 环境中 PATH 可能不完整：优先尝试常见安装位置，再回退到 command 查找。
GIT_EXE="$(resolve_exe "${WT_GIT_EXE:-}" "${GIT_EXE:-}" "/opt/homebrew/bin/git" "/usr/local/bin/git" "/usr/bin/git" "git" || true)"
GUM_EXE="$(resolve_exe "${WT_GUM_EXE:-}" "${GUM_EXE:-}" "/opt/homebrew/bin/gum" "/usr/local/bin/gum" "gum" || true)"

git_exec() {
  "${GIT_EXE}" "$@"
}

require_git() {
  [[ -n "${GIT_EXE}" ]] || die "E_WTIDE_CMD_MISSING" "未找到命令: git（可设置 WT_GIT_EXE=/abs/path/to/git）"
}

confirm_action() {
  local prompt="${1:-确认继续?}"
  if [[ -n "${GUM_EXE}" ]] && [[ -t 0 ]] && [[ -t 1 ]]; then
    "${GUM_EXE}" confirm "${prompt}"
    return $?
  fi

  echo -n "${prompt} [y/N] "
  local answer=""
  read -r answer
  case "${answer}" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

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
  git_exec -C "${repo_path}" rev-parse --show-toplevel 2>/dev/null || return 1
}

git_git_dir_abs() {
  local repo_path="${1:-.}"
  local root git_dir rel
  root="$(git_repo_root "${repo_path}")" || return 1
  git_dir="$(git_exec -C "${repo_path}" rev-parse --git-dir 2>/dev/null)" || return 1
  if [[ "${git_dir}" == /* ]]; then
    echo "${git_dir}"
    return 0
  fi
  rel="${root}/${git_dir}"
  echo "$(realpath_safe "${rel}")"
}

git_common_dir_abs() {
  local repo_path="${1:-.}"
  local root common rel
  root="$(git_repo_root "${repo_path}")" || return 1
  common="$(git_exec -C "${repo_path}" rev-parse --git-common-dir 2>/dev/null)" || return 1
  if [[ "${common}" == /* ]]; then
    echo "${common}"
    return 0
  fi
  rel="${root}/${common}"
  echo "$(realpath_safe "${rel}")"
}

is_main_worktree() {
  local repo_path="${1:-.}"
  local git_dir_abs common_dir_abs
  git_dir_abs="$(git_git_dir_abs "${repo_path}")" || return 1
  common_dir_abs="$(git_common_dir_abs "${repo_path}")" || return 1
  [[ -n "${git_dir_abs}" && -n "${common_dir_abs}" && "${git_dir_abs}" == "${common_dir_abs}" ]]
}

git_current_branch() {
  local repo_path="${1:-.}"
  git_exec -C "${repo_path}" rev-parse --abbrev-ref HEAD 2>/dev/null || return 1
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
  git_exec -C "${repo_path}" config -f .gitmodules --get-regexp 'submodule\..*\.path' 2>/dev/null | awk '{print $2}' || true
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
      branch="$(git_exec -C "${repo_path}" config -f .gitmodules --get "submodule.${name}.branch" 2>/dev/null || true)"
      echo "${branch}"
      return 0
    fi
  done < <(git_exec -C "${repo_path}" config -f .gitmodules --get-regexp 'submodule\..*\.path' 2>/dev/null || true)
  echo ""
}

git_ref_exists() {
  local repo_path="$1"
  local ref="$2"
  git_exec -C "${repo_path}" show-ref --verify --quiet "${ref}" 2>/dev/null
}

git_has_upstream() {
  local repo_path="$1"
  git_exec -C "${repo_path}" rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1
}

pick_branch_containing_head() {
  local repo_path="$1"
  local remote="$2"
  local raw line b branches

  raw="$(git_exec -C "${repo_path}" branch -r --contains HEAD 2>/dev/null || true)"
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

  echo "$(echo "${branches}" | head -n 1 | sed 's/^'"${remote//\//\\/}"'\///')"
}

standardize_one_submodule() {
  local wt_path="$1"
  local sm_path="$2"
  local parent_branch="$3"
  local remote="$4"
  local fetch="$5"
  local pull="$6"
  local branch_mode="${7:-${WT_SUBMODULE_BRANCH_MODE:-${WTIDE_SUBMODULE_BRANCH_MODE:-parent}}}"

  local sm_abs="${wt_path}/${sm_path}"
  if ! is_submodule_initialized "${wt_path}" "${sm_path}"; then
    log_debug "子模块未初始化，跳过: ${sm_path}"
    echo "SKIP:${sm_path} (未初始化)"
    return 0
  fi

  if [[ "${fetch}" == "1" ]]; then
    if ! git_exec -C "${sm_abs}" fetch --prune "${remote}" >/dev/null 2>&1; then
      log_warn "子模块 fetch 失败（继续执行）: ${sm_path}"
    fi
  fi

  local current_branch desired_branch configured_branch
  current_branch="$(git_exec -C "${sm_abs}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")"

  configured_branch="$(submodule_config_branch_from_gitmodules "${wt_path}" "${sm_path}")"

  case "${branch_mode}" in
    parent)
      # 强制跟随父仓分支：即使子模块里还没有同名分支，也会后续创建本地分支。
      desired_branch="${parent_branch}"
      ;;
    gitmodules)
      # 兼容旧行为：父仓同名分支存在时跟随父仓，否则优先用 .gitmodules.branch，再退回当前/包含 HEAD 的远端分支。
      if git_ref_exists "${sm_abs}" "refs/heads/${parent_branch}" || git_ref_exists "${sm_abs}" "refs/remotes/${remote}/${parent_branch}"; then
        desired_branch="${parent_branch}"
      else
        if [[ -n "${configured_branch}" ]] && (git_ref_exists "${sm_abs}" "refs/heads/${configured_branch}" || git_ref_exists "${sm_abs}" "refs/remotes/${remote}/${configured_branch}"); then
          desired_branch="${configured_branch}"
        elif [[ "${current_branch}" != "HEAD" ]]; then
          desired_branch="${current_branch}"
        else
          desired_branch="$(pick_branch_containing_head "${sm_abs}" "${remote}")"
          [[ -z "${desired_branch}" ]] && desired_branch="${parent_branch}"
        fi
      fi
      ;;
    *)
      echo "FAIL:${sm_path} (未知 branch_mode: ${branch_mode})"
      return 0
      ;;
  esac

  if [[ -z "${desired_branch}" ]]; then
    echo "SKIP:${sm_path} (无法确定目标分支)"
    return 0
  fi

  if [[ "${current_branch}" == "${desired_branch}" ]]; then
    :
  else
    if git_ref_exists "${sm_abs}" "refs/heads/${desired_branch}"; then
      git_exec -C "${sm_abs}" checkout "${desired_branch}" >/dev/null 2>&1 || {
        echo "FAIL:${sm_path} (checkout ${desired_branch} 失败)"
        return 0
      }
    elif git_ref_exists "${sm_abs}" "refs/remotes/${remote}/${desired_branch}"; then
      git_exec -C "${sm_abs}" checkout -B "${desired_branch}" "${remote}/${desired_branch}" >/dev/null 2>&1 || {
        echo "FAIL:${sm_path} (checkout ${remote}/${desired_branch} 失败)"
        return 0
      }
    else
      git_exec -C "${sm_abs}" checkout -b "${desired_branch}" >/dev/null 2>&1 || {
        echo "FAIL:${sm_path} (创建分支 ${desired_branch} 失败)"
        return 0
      }
    fi
  fi

  if git_ref_exists "${sm_abs}" "refs/remotes/${remote}/${desired_branch}"; then
    git_exec -C "${sm_abs}" branch --set-upstream-to "${remote}/${desired_branch}" "${desired_branch}" >/dev/null 2>&1 || true
  fi

  if [[ "${pull}" == "1" ]] && git_has_upstream "${sm_abs}"; then
    if ! git_exec -C "${sm_abs}" pull --ff-only >/dev/null 2>&1; then
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
  local allow_main="${WTIDE_ALLOW_MAIN:-0}"
  local branch_mode="${WT_SUBMODULE_BRANCH_MODE:-${WTIDE_SUBMODULE_BRANCH_MODE:-parent}}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --jobs)
        jobs="${2:-}"
        [[ -z "${jobs}" ]] && die "E_WTIDE_ARG_MISSING" "--jobs 需要参数"
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
        [[ -z "${remote}" ]] && die "E_WTIDE_ARG_MISSING" "--remote 需要参数"
        shift 2
        ;;
      --allow-main)
        allow_main="1"
        shift
        ;;
      --branch-mode)
        branch_mode="${2:-}"
        [[ -z "${branch_mode}" ]] && die "E_WTIDE_ARG_MISSING" "--branch-mode 需要参数"
        shift 2
        ;;
      -h|--help)
        cat <<'EOF'
用法:
  wtide.sh init [<worktree_path>] [--jobs N] [--no-fetch] [--no-pull] [--remote origin] [--allow-main] [--branch-mode parent|gitmodules]

说明:
  在现有 worktree 内初始化子模块，并将子模块切到合适分支（可提交）。
  默认只在「linked worktree」中执行；若目标路径是主工作区（git-dir == git-common-dir），将跳过执行。
  如需在主工作区也执行，可加 --allow-main 或设置 WTIDE_ALLOW_MAIN=1。
  分支模式（branch-mode，默认 parent；可用 WT_SUBMODULE_BRANCH_MODE/WTIDE_SUBMODULE_BRANCH_MODE 覆盖）：
  - parent：强制子模块 checkout/创建父仓同名分支（适合 feature 分支/改名场景）
  - gitmodules：兼容旧行为（父分支不存在时优先 .gitmodules.branch）
EOF
        return 0
        ;;
      -*)
        die "E_WTIDE_ARG_INVALID" "未知选项: $1"
        ;;
      *)
        wt_path="$1"
        shift
        ;;
    esac
  done

  wt_path="$(strip_trailing_slash "${wt_path}")"
  require_git

  if ! git_exec -C "${wt_path}" rev-parse --git-dir >/dev/null 2>&1; then
    die "E_WTIDE_NOT_GIT_REPO" "目录不是 Git 仓库: ${wt_path}"
  fi

  if [[ "${allow_main}" != "1" ]] && is_main_worktree "${wt_path}"; then
    log_warn "检测到主工作区（非 linked worktree），跳过 init: ${wt_path}"
    log_warn "如需强制执行：wtide.sh init ${wt_path} --allow-main"
    return 0
  fi

  local parent_branch
  parent_branch="$(git_current_branch "${wt_path}")" || die "E_WTIDE_GIT_FAILED" "无法获取父仓分支"
  [[ "${parent_branch}" == "HEAD" ]] && die "E_WTIDE_BRANCH_DETACHED" "父仓 detached HEAD，先 checkout 到分支再执行"

  log_info "父仓分支: ${parent_branch}"

  case "${branch_mode}" in
    parent|gitmodules) : ;;
    *) die "E_WTIDE_ARG_INVALID" "无效 --branch-mode: ${branch_mode}（可选: parent|gitmodules）" ;;
  esac

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
  git_exec -C "${wt_path}" submodule init >/dev/null 2>&1 || true

  while IFS= read -r sm_path; do
    [[ -z "${sm_path}" ]] && continue
    local output
    if output="$(git_exec -C "${wt_path}" -c submodule.alternateErrorStrategy=info submodule update --init --recursive --jobs "${jobs}" -- "${sm_path}" 2>&1)"; then
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
  sm_all="$(git_exec -C "${wt_path}" submodule foreach --recursive 'echo "$displaypath"' 2>/dev/null || true)"
  [[ -z "${sm_all}" ]] && sm_all="${submodules}"

  while IFS= read -r sm_path; do
    [[ -z "${sm_path}" ]] && continue
    local result
    result="$(standardize_one_submodule "${wt_path}" "${sm_path}" "${parent_branch}" "${remote}" "${fetch}" "${pull}" "${branch_mode}")"
    case "${result}" in
      OK:*) report_ok+=("${result#OK:}") ;;
      SKIP:*) report_skip+=("${result#SKIP:}") ;;
      FAIL:*) report_fail_other+=("${result#FAIL:}") ;;
      *) report_fail_other+=("${sm_path} (未知结果: ${result})") ;;
    esac
  done <<< "${sm_all}"

  echo
  echo "═══════════════════════════════════════════════════════════════"
  echo "                       wtide 执行报告"
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

  log_ok "完成：worktree 已可提交（父分支: ${parent_branch}）"
}

cmd_status() {
  require_git
  local wt_path="${1:-.}"

  if ! git_exec -C "${wt_path}" rev-parse --git-dir >/dev/null 2>&1; then
    die "E_WTIDE_NOT_GIT_REPO" "目录不是 Git 仓库: ${wt_path}"
  fi

  local repo_root parent_branch
  repo_root="$(git_repo_root "${wt_path}")"
  parent_branch="$(git_current_branch "${wt_path}")" || parent_branch="?"

  echo "═══════════════════════════════════════════════════════════════"
  echo "                        wtide 状态"
  echo "═══════════════════════════════════════════════════════════════"
  echo "父仓: ${repo_root}"
  echo "分支: ${parent_branch}"
  echo
  git_exec -C "${wt_path}" status --short | head -20 || true

  local submodules
  submodules="$(git_exec -C "${wt_path}" submodule foreach --recursive 'echo "$displaypath"' 2>/dev/null || true)"
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
      sm_branch="$(git_exec -C "${sm_abs}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")"
      sm_dirty="$(git_exec -C "${sm_abs}" status --short 2>/dev/null | head -n 1 || true)"
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
  done < <(git_exec -C "${repo_root}" worktree list --porcelain 2>/dev/null || true)

  echo ""
}

safe_rm_rf() {
  local target="$1"
  [[ -z "${target}" ]] && die "E_WTIDE_INTERNAL" "删除路径为空"
  [[ "${target}" == "/" ]] && die "E_WTIDE_INTERNAL" "拒绝删除 /"
  rm -rf "${target}"
}

cmd_remove() {
  require_git
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
  wtide.sh remove <worktree_path> [-y|--yes] [--force-submodules]

说明:
  - 先尝试原生: git worktree remove --force
  - 若遇到 "containing submodules cannot be moved or removed":
    1) 尝试在该 worktree 中执行: git submodule deinit -f --all
    2) 仍失败时，可用 --force-submodules 强制清理（rm -rf worktree + 删除 worktrees 元数据 + prune）
EOF
        return 0
        ;;
      -*)
        die "E_WTIDE_ARG_INVALID" "未知选项: $1"
        ;;
      *)
        wt_path="$1"
        shift
        ;;
    esac
  done

  [[ -z "${wt_path}" ]] && die "E_WTIDE_ARG_MISSING" "remove 需要 <worktree_path>"
  wt_path="$(strip_trailing_slash "${wt_path}")"

  local common_dir repo_root
  common_dir="$(git_common_dir_abs ".")" || die "E_WTIDE_NOT_GIT_REPO" "当前目录不在 Git 仓库中"
  repo_root="$(cd "${common_dir}/.." && pwd)" || die "E_WTIDE_GIT_FAILED" "无法解析主仓库路径"

  local repo_root_abs wt_abs
  repo_root_abs="$(realpath_safe "${repo_root}")"
  wt_abs="$(realpath_safe "${wt_path}")"
  if [[ -z "${wt_abs}" ]]; then
    wt_abs="$(realpath_safe "$(pwd)/${wt_path}")"
  fi
  if [[ -z "${wt_abs}" ]] && [[ -d "${wt_path}" ]]; then
    wt_abs="$(cd "${wt_path}" 2>/dev/null && pwd || true)"
  fi
  [[ -z "${wt_abs}" ]] && wt_abs="${wt_path}"
  if [[ -n "${wt_abs}" && -n "${repo_root_abs}" && "${wt_abs}" == "${repo_root_abs}" ]]; then
    die "E_WTIDE_ARG_INVALID" "拒绝删除主仓库 worktree（仓库根目录）: ${wt_path}"
  fi

  if [[ "${yes}" != "1" ]]; then
    if ! confirm_action "确认删除 worktree '${wt_path}' ?"; then
      log_info "已取消"
      return 0
    fi
  fi

  local current_abs=""
  current_abs="$(realpath_safe ".")"
  if [[ -z "${current_abs}" ]]; then
    current_abs="$(pwd -P 2>/dev/null || true)"
  fi

  if [[ -n "${current_abs}" && -n "${wt_abs}" ]] && { [[ "${current_abs}" == "${wt_abs}" ]] || [[ "${current_abs}" == "${wt_abs}/"* ]]; }; then
    log_warn "当前位于将被删除的 worktree 内：${current_abs}"
    log_warn "将切换到主仓库执行删除：${repo_root}"
    cd "${repo_root}" || true
  fi

  log_info "删除 worktree: ${wt_path}"
  local remove_out=""
  if remove_out="$(git_exec -C "${repo_root}" worktree remove --force "${wt_abs}" 2>&1)"; then
    log_ok "worktree 已删除: ${wt_path}"
    if [[ -n "${current_abs}" && -n "${wt_abs}" ]] && { [[ "${current_abs}" == "${wt_abs}" ]] || [[ "${current_abs}" == "${wt_abs}/"* ]]; }; then
      log_warn "提示：你的终端若仍停留在被删除目录，请手动执行：cd ${repo_root}"
    fi
    return 0
  fi

  if echo "${remove_out}" | grep -qi "containing submodules cannot be moved or removed"; then
    log_warn "检测到 worktree 含子模块，尝试 deinit 后重试..."
    git_exec -C "${wt_abs}" submodule deinit -f --all >/dev/null 2>&1 || true

    if git_exec -C "${repo_root}" worktree remove --force "${wt_abs}" >/dev/null 2>&1; then
      log_ok "worktree 已删除: ${wt_path}"
      return 0
    fi

    if [[ "${force_submodules}" != "1" ]]; then
      die "E_WTIDE_WORKTREE_REMOVE_SUBMODULES" "worktree 含子模块导致 remove 失败；可重试: wtide.sh remove --force-submodules -y ${wt_path}"
    fi

    log_warn "使用 --force-submodules 强制清理（rm -rf + 删除元数据 + prune）..."

    local gitdir common_dir2
    gitdir="$(worktree_find_gitdir "${repo_root}" "${wt_abs}")"
    common_dir2="$(git_common_dir_abs "${repo_root}")"

    if [[ -n "${gitdir}" ]]; then
      local gitdir_abs="${gitdir}"
      if [[ "${gitdir_abs}" != /* ]]; then
        gitdir_abs="${repo_root}/${gitdir_abs}"
      fi
      gitdir_abs="$(realpath_safe "${gitdir_abs}")"

      if [[ -n "${common_dir2}" && -n "${gitdir_abs}" && "${gitdir_abs}" == "${common_dir2}/worktrees/"* ]]; then
        safe_rm_rf "${gitdir_abs}"
      else
        log_warn "gitdir 路径不在 common_dir 下，拒绝删除: ${gitdir_abs}"
      fi
    else
      log_warn "未找到 worktree 元数据 gitdir（继续尝试 prune）"
    fi

    if [[ -d "${wt_abs}" || -f "${wt_abs}" ]]; then
      safe_rm_rf "${wt_abs}"
    fi

    git_exec -C "${repo_root}" worktree prune >/dev/null 2>&1 || true
    log_ok "强制清理完成: ${wt_path}"
    return 0
  fi

  die "E_WTIDE_WORKTREE_REMOVE_FAILED" "删除失败: ${remove_out}"
}

show_help() {
  cat <<'EOF'
wtide.sh - AI IDE worktree helper（CLI）

用法:
  wtide.sh <command> [args...]

命令:
  init [path]               初始化子模块并标准化分支（IDE 场景）
  status [path]             查看父仓/子模块状态
  remove <path>             删除 worktree（必要时用 --force-submodules）

环境变量:
  WT_GIT_EXE=/abs/path/to/git     git 绝对路径（IDE PATH 不完整时可用）
  WT_GUM_EXE=/abs/path/to/gum     gum 绝对路径（可选）
  WTIDE_ALLOW_MAIN=1             允许在主工作区执行 init（默认跳过）
  WT_SUBMODULE_BRANCH_MODE=parent|gitmodules   子模块分支模式（默认 parent）
  WTIDE_SUBMODULE_BRANCH_MODE=parent|gitmodules   同上（脚本专用覆盖）

示例:
  wtide.sh init .
  wtide.sh status .
  wtide.sh remove --force-submodules -y ../wt-li
EOF
}

main() {
  local cmd="${1:-}"
  shift || true
  case "${cmd}" in
    init) cmd_init "$@" ;;
    status|st) cmd_status "$@" ;;
    remove|rm) cmd_remove "$@" ;;
    -v|--verbose)
      VERBOSE=1
      main "$@"
      ;;
    ""|help|-h|--help) show_help ;;
    *) die "E_WTIDE_SUBCOMMAND_UNKNOWN" "未知子命令: ${cmd}" ;;
  esac
}

main "$@"
