#!/usr/bin/env bash
set -euo pipefail

# ws/index.sh
#
# workspace 模块入口，统一加载本目录下的子模块。

# shellcheck source=workspace.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/workspace.sh"

