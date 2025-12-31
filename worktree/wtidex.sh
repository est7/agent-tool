#!/usr/bin/env bash
set -euo pipefail

# wtidex.sh
#
# 增强版入口（可选 TUI）：默认直通 wtide.sh；加 -i/--interactive 才进入 gum 菜单。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
WTIDE_SH="${SCRIPT_DIR}/wtide.sh"

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

GUM_EXE="$(resolve_exe "${WT_GUM_EXE:-}" "${GUM_EXE:-}" "/opt/homebrew/bin/gum" "/usr/local/bin/gum" "gum" || true)"

is_interactive() {
  [[ -t 0 && -t 1 ]]
}

gum_md() {
  "${GUM_EXE}" format --type markdown --theme "pink"
}

show_action_help_init() {
  cat <<'MD' | gum_md
## init：初始化子模块并标准化分支

适用场景：IDE 已执行 `git worktree add`，但子模块可能未初始化 / 停在 detached，导致无法提交。

此操作会：
- `git submodule init` + `git submodule update --init --recursive`（失败不阻塞，但会报告）
- 为每个子模块选择一个“可提交”的目标分支并 checkout

分支模式（可选）：
- `WT_SUBMODULE_BRANCH_MODE=parent`：强制子模块跟随父仓同名分支（默认）
- `WT_SUBMODULE_BRANCH_MODE=gitmodules`：父分支不存在时优先用 `.gitmodules.branch`（旧行为）

子模块分支选择规则（单个子模块）：
1. 若存在与父仓同名分支：切到该分支
2. 否则若 `.gitmodules` 配置了 `branch`：切到该分支
3. 否则若子模块当前已在某分支：保持该分支
4. 否则（detached）：找包含 HEAD 的远端分支；再不行就创建父分支同名本地分支
MD
}

show_action_help_status() {
  cat <<'MD' | gum_md
## status：查看父仓 / 子模块状态

会输出：
- 父仓路径与当前分支
- `git status --short`（截断显示）
- 子模块是否初始化、当前分支、是否 dirty
MD
}

show_action_help_remove() {
  cat <<'MD' | gum_md
## remove：删除 worktree（含子模块兜底）

流程：
1. 先尝试：`git worktree remove --force`
2. 若遇到 `containing submodules cannot be moved or removed`：
   - 尝试在该 worktree 中执行：`git submodule deinit -f --all`
3. 仍失败时，开启 `--force-submodules` 会执行更激进的清理：
   - `rm -rf <worktree_path>`
   - 删除 `.git/worktrees/...` 元数据（仅限在 common dir 下才会删除）
   - `git worktree prune`
MD
}

gum_choose_action() {
  "${GUM_EXE}" choose \
    --header "wtidex：选择操作（Enter 确认，Esc 退出）" \
    "init   初始化子模块/分支" \
    "status 查看父仓/子模块状态" \
    "remove 删除 worktree"
}

gum_input_path() {
  local prompt="${1:-路径（默认 .）: }"
  local value=""
  value="$("${GUM_EXE}" input --header "输入 worktree 路径（留空表示当前目录 .）" --prompt "${prompt}" --placeholder ".")" || return 1
  [[ -z "${value}" ]] && value="."
  echo "${value}"
}

gum_confirm_default_yes() {
  local prompt="${1:-确认?}"
  if "${GUM_EXE}" confirm --default "${prompt}"; then
    return 0
  fi
  return 1
}

gum_confirm_default_no() {
  local prompt="${1:-确认?}"
  if "${GUM_EXE}" confirm "${prompt}"; then
    return 0
  fi
  return 1
}

run_init_tui() {
  show_action_help_init
  local wt_path="${1:-}"
  if [[ -z "${wt_path}" ]]; then
    wt_path="$(gum_input_path "worktree path（默认 .）: ")" || return 1
  fi

  local no_fetch="0"
  local no_pull="0"
  local allow_main="0"
  local branch_mode="parent"

  if ! gum_confirm_default_yes "子模块分支强制跟随父仓（branch-mode=parent）?"; then
    branch_mode="gitmodules"
  fi

  if ! gum_confirm_default_yes "执行 git fetch（子模块）?"; then
    no_fetch="1"
  fi
  if ! gum_confirm_default_yes "执行 git pull --ff-only（子模块）?"; then
    no_pull="1"
  fi
  if gum_confirm_default_no "允许在主工作区执行（--allow-main）?"; then
    allow_main="1"
  fi

  local args=()
  args+=(init "${wt_path}")
  [[ "${no_fetch}" == "1" ]] && args+=(--no-fetch)
  [[ "${no_pull}" == "1" ]] && args+=(--no-pull)
  [[ "${allow_main}" == "1" ]] && args+=(--allow-main)
  [[ "${branch_mode}" != "parent" ]] && args+=(--branch-mode "${branch_mode}")

  exec "${WTIDE_SH}" "${args[@]}"
}

run_status_tui() {
  show_action_help_status
  local wt_path="${1:-}"
  if [[ -z "${wt_path}" ]]; then
    wt_path="$(gum_input_path "worktree path（默认 .）: ")" || return 1
  fi
  exec "${WTIDE_SH}" status "${wt_path}"
}

run_remove_tui() {
  show_action_help_remove
  local wt_path="${1:-}"
  if [[ -z "${wt_path}" ]]; then
    wt_path="$(gum_input_path "worktree path（默认 .）: ")" || return 1
  fi

  local force_submodules="0"

  if ! gum_confirm_default_no "确认删除 worktree '${wt_path}' ?"; then
    return 0
  fi
  if gum_confirm_default_no "强制清理子模块（--force-submodules，必要时 rm -rf）?"; then
    force_submodules="1"
  fi

  local args=()
  args+=(remove "${wt_path}")
  args+=(-y)
  [[ "${force_submodules}" == "1" ]] && args+=(--force-submodules)

  exec "${WTIDE_SH}" "${args[@]}"
}

main() {
  local interactive="0"
  if [[ "${1:-}" == "-i" || "${1:-}" == "--interactive" ]]; then
    interactive="1"
    shift
  fi

  if [[ "${interactive}" != "1" ]]; then
    if [[ $# -eq 0 ]]; then
      exec "${WTIDE_SH}" help
    fi
    exec "${WTIDE_SH}" "$@"
  fi

  if ! is_interactive || [[ -z "${GUM_EXE}" ]]; then
    exec "${WTIDE_SH}" help
  fi

  local cmd="${1:-}"
  if [[ -n "${cmd}" ]]; then
    shift || true
    case "${cmd}" in
      init) run_init_tui "${1:-}" ;;
      status|st) run_status_tui "${1:-}" ;;
      remove|rm) run_remove_tui "${1:-}" ;;
      *) exec "${WTIDE_SH}" help ;;
    esac
    exit 0
  fi

  local action=""
  action="$(gum_choose_action)" || exit 0

  case "${action}" in
    init*) run_init_tui ;;
    status*) run_status_tui ;;
    remove*) run_remove_tui ;;
    *) exec "${WTIDE_SH}" help ;;
  esac
}

main "$@"

