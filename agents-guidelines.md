# Agent 开发指南（多 submodule 并行开发）

本文件约定 Codex / 代码 Agent 在本仓库中开发 feature 时的 Git 使用方式，目标：

- 通过“主仓 1 个 + 多个 agent clone”实现并行开发；
- 每个 agent 在自己的 clone + 分支里独立工作；
- 多层 Git submodule 下避免互相踩工作区、避免破坏仓库结构。

---

## 1. 目录结构与命名规范

### 1.1 顶层目录布局

```text
<parent-dir>/
  ├─ <repo-name>/                         # 主开发仓库（人类日常开发）
  └─ <repo-name>-agents/                  # 所有 Agent 专用 clone 放在这里
       ├─ <repo-name>-agent-feat-user-profile-header/
       ├─ <repo-name>-agent-bugfix-payment-api-timeout/
       └─ ...

约束：
	•	不在主仓目录内部再创建新的 Git 仓库（除正式配置的 submodule 外）。
	•	所有 Agent clone 必须放在 <repo-name>-agents/ 目录下，由脚本统一创建。

1.2 任务类型与命名规则
	•	type（任务类型）：
	•	feat / bugfix / refactor / chore / exp
	•	scope（任务范围）：
	•	简短 kebab-case，如：user-profile-header, payment-api-timeout
	•	分支命名（父仓 & 子仓统一）：
	•	agent/<type>/<scope>
	•	例如：agent/feat/user-profile-header
	•	Agent 目录命名：
	•	<repo-name>-agent-<type>-<scope>/
	•	例如：<repo-name>-agent-feat-user-profile-header/

⸻

2. 使用 agent-tool.sh 管理 Agent 环境

脚本位置（主仓内）：

<repo-root>/
  ├─ scripts/
  │    └─ agent-tool.sh
  └─ AGENTS.md

2.1 创建 Agent 环境：create

在主仓根目录内部执行：

cd /path/to/your/repo

# 默认：以当前主仓所在分支为基线
./scripts/agent-tool.sh create <type> <scope>

# 显式：以指定分支为基线（如 dev/main/release/*）
./scripts/agent-tool.sh create --base-branch dev <type> <scope>

示例：

# 假设当前在分支 feature/homepage 上
./scripts/agent-tool.sh create feat user-profile-header
# => Agent 父仓分支基于 feature/homepage 创建 agent/feat/user-profile-header
# => submodule 也优先尝试基于 feature/homepage 创建/切换 agent/feat/user-profile-header

# 若希望强制基于 dev 分支：
./scripts/agent-tool.sh create --base-branch dev feat user-profile-header
# => Agent 父仓分支基于 dev 创建 agent/feat/user-profile-header
# => submodule 也优先尝试基于 dev 创建/切换 agent/feat/user-profile-header

基线选择规则：
	•	默认（未指定 --base-branch）：
	•	读取当前主仓分支 CURRENT_BRANCH；
	•	父仓：
	•	优先 origin/CURRENT_BRANCH；
	•	否则本地 CURRENT_BRANCH；
	•	都不存在则回退 HEAD。
	•	submodule：
	•	优先 origin/CURRENT_BRANCH；
	•	否则本地 CURRENT_BRANCH；
	•	若不存在该分支，则保持子仓当前分支/commit 不变。
	•	显式指定 --base-branch <branch>：
	•	父仓：
	•	优先 origin/<branch>；
	•	否则本地 <branch>；
	•	都不存在则回退 HEAD。
	•	submodule：
	•	优先 origin/<branch>；
	•	否则本地 <branch>；
	•	若不存在该分支，则保持子仓当前分支/commit 不变。

创建流程自动完成：
	1.	在 <parent-dir>/<repo-name>-agents/ 下创建独立 Agent 仓库；
	2.	运行 agent_clone.sh 初始化可访问的 submodule（对 invalid alternate 使用 submodule.alternateErrorStrategy=info）；
	3.	在 Agent 父仓中基于选定基线分支创建并切换到 agent/<type>/<scope>；
	4.	对所有已初始化且可访问的 submodule：
	•	若存在与基线同名分支（远端或本地），基于该分支创建/切换 agent/<type>/<scope>；
	•	否则保持当前状态并打印提示；
	5.	在 Agent 根目录生成：
	•	.agent-meta.yml（包含 type/scope/branch/base_branch/created_at/...）
	•	README_AGENT.md。

2.2 清理 Agent 环境：cleanup

仅删除本地 Agent 仓库目录，不修改远端分支：

cd /path/to/your/repo
./scripts/agent-tool.sh cleanup <type> <scope>

示例：

./scripts/agent-tool.sh cleanup feat user-profile-header

删除：

<parent-dir>/<repo-name>-agents/<repo-name>-agent-feat-user-profile-header/

2.3 列出所有 Agent 仓库：list

cd /path/to/your/repo
./scripts/agent-tool.sh list

输出示例：

==> Agent 根目录: /Users/you/Projects/my-app-agents

DIR                                      TYPE     SCOPE                          BASE_BRANCH          CREATED_AT           BRANCH
---------------------------------------- -------- ------------------------------ -------------------- -------------------- ------------------------------
my-app-agent-feat-user-profile-header    feat     user-profile-header           feature/homepage     2025-11-26T06:30:00Z agent/feat/user-profile-header
...

数据来自每个 Agent 根目录的 .agent-meta.yml。

2.4 查看 Agent 仓库状态：status

cd /path/to/your/repo
./scripts/agent-tool.sh status

示例：

==> Agent 根目录: /Users/you/Projects/my-app-agents

==> my-app-agent-feat-user-profile-header (agent/feat/user-profile-header) [base:feature/homepage]
  M app/src/...
  M common/...

==> my-app-agent-bugfix-payment-api-timeout (agent/bugfix/payment-api-timeout) [base:dev]
  工作区干净


⸻

3. Codex / Agent 使用规范
	•	Codex / 任何 Agent 工具的“项目根目录”必须指向某个 Agent 仓库，例如：

<parent-dir>/<repo-name>-agents/<repo-name>-agent-feat-user-profile-header


	•	不直接在主仓根目录上运行 Codex 改代码。

3.1 Agent 允许的操作
	•	git status / git diff / git log
	•	修改父仓业务代码
	•	在已切到 agent/<type>/<scope> 的 submodule 内编辑并提交
	•	生成 commit message / PR 描述 / 影响分析

3.2 Agent 禁止的操作
	•	在任何层级执行 git clone / git worktree
	•	修改 .gitmodules
	•	执行 git reset --hard / git clean -xfd / git gc / git prune
	•	执行 git push --force / 删除远端分支 / 修改 remote 配置

⸻

4. agent_clone.sh

每个 Agent 仓库根目录下自动生成，创建时自动执行一次：

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

需要重新初始化 submodule 时，在 Agent 仓库根目录执行：

./agent_clone.sh


⸻

5. 给 Codex / Agent 的提示模板（示例）

	•	项目根目录：<parent-dir>/<repo-name>-agents/<repo-name>-agent-<type>-<scope>
	•	当前 Agent 分支：agent/<type>/<scope>
	•	基线分支：base_branch 字段指定（如 feature/homepage 或 dev）
	•	submodule 已初始化并尽可能基于同名基线分支创建/切换到 agent/<type>/<scope>；不存在该基线分支的子仓保持原状
	•	禁止执行 git clone / git worktree / 修改 .gitmodules / 强制 push / reset –hard 等破坏性操作
	•	仅在当前 Agent 仓库内进行增量、可 review 的改动
