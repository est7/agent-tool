#!/usr/bin/env bash
set -euo pipefail

# 破坏性迁移：原 gitwrapper.sh 已迁移到 gitx.sh
# 建议直接使用：gitx.sh worktree ...

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
exec "${SCRIPT_DIR}/../gitx.sh" worktree "$@"

