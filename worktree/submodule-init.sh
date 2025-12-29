#!/usr/bin/env bash
set -euo pipefail

########################################
# submodule-init.sh
#
# 在 AI IDE 创建的 worktree 中运行，完成子模块初始化和分支联动。
#
# 使用场景：
#   IDE 创建 worktree → cd 到 worktree → 运行此脚本
#
# 功能：
#   1. 初始化/拉取子模块（容错，跳过无权限的）
#   2. 为每个子模块创建与父分支同名的分支
########################################

# === 颜色输出 ===
if [[ -t 1 ]]; then
  C_RED='\033[0;31m'
  C_GREEN='\033[0;32m'
  C_YELLOW='\033[0;33m'
  C_CYAN='\033[0;36m'
  C_RESET='\033[0m'
else
  C_RED='' C_GREEN='' C_YELLOW='' C_CYAN='' C_RESET=''
fi

# === 报告收集器 ===
REPORT_OK=()
REPORT_SKIP=()
REPORT_FAIL=()

# === 日志函数 ===
log_info()  { echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }

# === 打印报告 ===
print_report() {
  echo
  echo "═══════════════════════════════════════════════════════════════"
  echo "                      子模块初始化报告"
  echo "═══════════════════════════════════════════════════════════════"

  if [[ ${#REPORT_OK[@]} -gt 0 ]]; then
    echo -e "\n${C_GREEN}✓ 成功 (${#REPORT_OK[@]})${C_RESET}"
    printf '  %s\n' "${REPORT_OK[@]}"
  fi

  if [[ ${#REPORT_SKIP[@]} -gt 0 ]]; then
    echo -e "\n${C_YELLOW}⊘ 跳过 (${#REPORT_SKIP[@]})${C_RESET}"
    printf '  %s\n' "${REPORT_SKIP[@]}"
  fi

  if [[ ${#REPORT_FAIL[@]} -gt 0 ]]; then
    echo -e "\n${C_RED}✗ 失败 (${#REPORT_FAIL[@]})${C_RESET}"
    printf '  %s\n' "${REPORT_FAIL[@]}"
  fi

  echo "═══════════════════════════════════════════════════════════════"
}

# === 获取子模块列表 ===
get_submodule_paths() {
  git config -f .gitmodules --get-regexp 'submodule\..*\.path' 2>/dev/null | awk '{print $2}' || true
}

# === 计算并行 jobs 数 ===
# 优先级: SUBMODULE_JOBS 环境变量 > 自动探测 CPU 核数 > 8
detect_jobs() {
  local jobs="${SUBMODULE_JOBS:-}"
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

# === 检查是否为 git 目录 ===
is_git_dir() {
  local path="$1"
  [[ -d "${path}/.git" ]] || [[ -f "${path}/.git" ]]
}

# === 子模块状态前缀（git submodule status） ===
# 返回: '-', '+', 'U', ' ' 或空
get_submodule_status_prefix() {
  local sm_path="$1"
  local status_line
  status_line="$(git submodule status -- "${sm_path}" 2>/dev/null || true)"
  [[ -z "${status_line}" ]] && return 0
  echo "${status_line:0:1}"
}

# === 更新单个子模块（用于补救/诊断） ===
update_one_submodule() {
  local sm_path="$1"
  local jobs="$2"

  local update_output
  if update_output=$(git -c submodule.alternateErrorStrategy=info \
      submodule update --init --recursive --jobs "${jobs}" -- "${sm_path}" 2>&1); then
    return 0
  fi

  if echo "${update_output}" | grep -qiE "(permission denied|access denied|authentication failed|could not read username|fatal: Authentication)"; then
    REPORT_FAIL+=("${sm_path} (无权限)")
  else
    REPORT_FAIL+=("${sm_path} (拉取失败)")
  fi
  return 1
}

# === 主流程 ===
main() {
  # 检查是否在 git 仓库中
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "当前目录不在 Git 仓库中"
    exit 1
  fi

  # 1. 获取父仓库当前分支
  local parent_branch
  parent_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

  if [[ "${parent_branch}" == "HEAD" ]]; then
    log_error "父仓库处于 detached HEAD 状态，无法确定分支名"
    log_info "请先 checkout 到一个分支: git checkout <branch>"
    exit 1
  fi

  log_info "父仓库分支: ${parent_branch}"

  # 2. 获取子模块列表
  local submodules
  submodules="$(get_submodule_paths)"

  if [[ -z "${submodules}" ]]; then
    log_info "没有配置子模块，无需处理"
    exit 0
  fi

  # 3. 初始化子模块
  log_info "正在初始化子模块..."
  git submodule init 2>/dev/null || true

  # 4. 批量更新子模块（并行），然后逐个做状态补救 + 分支联动
  local jobs
  jobs="$(detect_jobs)"
  log_info "正在拉取/更新子模块（并行 jobs=${jobs}）..."
  if ! git -c submodule.alternateErrorStrategy=info \
      submodule update --init --recursive --jobs "${jobs}" 2>/dev/null; then
    log_warn "子模块批量更新存在失败项，继续逐个处理并输出报告"
  fi

  # 5. 逐个处理子模块：必要时补救 update，然后做分支联动
  while IFS= read -r sm_path; do
    [[ -z "${sm_path}" ]] && continue

    log_info "处理子模块: ${sm_path}"

    # 5.1 如果仍未初始化/状态异常，则补救一次（可观测失败原因）
    local prefix
    prefix="$(get_submodule_status_prefix "${sm_path}")"
    case "${prefix}" in
      -)
        log_warn "子模块未初始化，尝试补救拉取: ${sm_path}"
        update_one_submodule "${sm_path}" "${jobs}" || continue
        ;;
      U)
        log_warn "子模块处于冲突状态，跳过: ${sm_path}"
        REPORT_FAIL+=("${sm_path} (冲突)")
        continue
        ;;
      +)
        # 工作区与期望 commit 不一致（新 worktree 理论上不该出现），尝试对齐
        log_warn "子模块状态异常(+)，尝试对齐到父仓指针: ${sm_path}"
        update_one_submodule "${sm_path}" "${jobs}" || true
        ;;
      *)
        ;;
    esac

    # 5.2 检查子模块是否为有效 git 目录
    if ! is_git_dir "${sm_path}"; then
      log_warn "子模块不是有效 git 目录，跳过: ${sm_path}"
      REPORT_SKIP+=("${sm_path} (非 git 目录)")
      continue
    fi

    log_ok "子模块准备就绪: ${sm_path}"

    # 5.3 为子模块创建分支
    (
      cd "${sm_path}" || exit 1

      # 获取子模块当前分支/状态
      local current_ref
      current_ref="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")"

      # 如果已经在目标分支，跳过
      if [[ "${current_ref}" == "${parent_branch}" ]]; then
        log_ok "子模块已在分支 ${parent_branch}: ${sm_path}"
        echo "OK:${sm_path} (已在 ${parent_branch})"
        exit 0
      fi

      # 检查目标分支是否已存在
      if git show-ref --verify --quiet "refs/heads/${parent_branch}"; then
        # 分支存在，切换过去
        if git checkout "${parent_branch}" 2>/dev/null; then
          log_ok "子模块切换到已有分支 ${parent_branch}: ${sm_path}"
          echo "OK:${sm_path} → ${parent_branch} (已有分支)"
        else
          log_warn "子模块切换分支失败: ${sm_path}"
          echo "FAIL:${sm_path} (切换失败)"
        fi
      else
        # 分支不存在，从当前位置创建
        local base_info=""
        if [[ "${current_ref}" != "HEAD" ]]; then
          base_info="基于 ${current_ref}"
        else
          base_info="基于 $(git rev-parse --short HEAD)"
        fi

        if git checkout -b "${parent_branch}" 2>/dev/null; then
          log_ok "子模块创建分支 ${parent_branch} (${base_info}): ${sm_path}"
          echo "OK:${sm_path} → ${parent_branch} (${base_info})"
        else
          log_warn "子模块创建分支失败: ${sm_path}"
          echo "FAIL:${sm_path} (创建失败)"
        fi
      fi
    ) | while IFS= read -r result; do
      case "${result}" in
        OK:*)   REPORT_OK+=("${result#OK:}") ;;
        FAIL:*) REPORT_FAIL+=("${result#FAIL:}") ;;
        SKIP:*) REPORT_SKIP+=("${result#SKIP:}") ;;
      esac
    done

  done <<< "${submodules}"

  # 6. 输出报告
  print_report

  echo
  log_ok "完成！子模块已准备好，分支: ${parent_branch}"
}

# === 帮助信息 ===
show_help() {
  cat << 'EOF'
submodule-init - AI IDE Worktree 子模块初始化工具

用法:
  submodule-init.sh

功能:
  在 AI IDE 创建的 worktree 目录中运行，完成：
  1. 初始化/拉取所有子模块（跳过无权限的）
  2. 为每个子模块创建与父分支同名的分支

使用场景:
  # IDE 自动创建 worktree 后
  cd /path/to/repo__feature__login
  /path/to/submodule-init.sh

分支策略:
  子模块的新分支基于其当前分支（通常是父仓库 pin 的 commit 所在分支）
  例如: 子模块在 dev 分支 → 分裂出 feature/login 分支

性能:
  可通过环境变量 SUBMODULE_JOBS 调整并行度，例如:
    SUBMODULE_JOBS=8 /path/to/submodule-init.sh

EOF
}

# === 入口 ===
case "${1:-}" in
  -h|--help|help)
    show_help
    ;;
  *)
    main "$@"
    ;;
esac
