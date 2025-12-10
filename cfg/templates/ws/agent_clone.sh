#!/usr/bin/env bash
set -euo pipefail

echo "==> 初始化 submodules (agent_clone.sh) ..."

git submodule init || true

if git config -f .gitmodules --get-regexp path >/dev/null 2>&1; then
  git config -f .gitmodules --get-regexp path | awk '{print $2}' | \
  while IFS= read -r m; do
    echo "  -> 初始化 submodule: ${m}"
    git -c submodule.alternateErrorStrategy=info \
        submodule update --init --recursive "${m}" 2>/dev/null || echo "  !! 跳过: ${m}"
  done
else
  echo "  (没有配置任何 submodule，跳过初始化)"
fi

echo "==> submodules 初始化完成。"
