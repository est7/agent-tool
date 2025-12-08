#!/usr/bin/env bash
set -euo pipefail

# doctor/index.sh
#
# doctor 模块入口，加载平台自检脚本。

# shellcheck source=platforms.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/platforms.sh"
