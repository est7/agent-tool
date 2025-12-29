#!/usr/bin/env bash
set -euo pipefail

# 破坏性迁移：原 submodule-init.sh 已合并到 gitx.sh
# 建议直接使用：gitx.sh worktree init

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
exec "${SCRIPT_DIR}/../gitx.sh" worktree init "$@"

