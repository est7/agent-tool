#!/usr/bin/env bash
set -euo pipefail

# wtidex.sh
#
# 增强版入口（别名）：避免重复维护，直接复用 wtide.sh 的实现。
# 你可以把 IDE 的后置脚本指向本文件，或继续使用 wtide.sh。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
exec "${SCRIPT_DIR}/wtide.sh" "$@"

