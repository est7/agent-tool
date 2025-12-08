#!/usr/bin/env bash
set -euo pipefail

# build/index.sh
#
# 平台构建/运行模块入口。

# shellcheck source=platforms.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/platforms.sh"

