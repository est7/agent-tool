# Worktree 工作流使用说明（IDE + Submodule）

本仓库提供两套**完全独立**的脚本：

- `worktree/wtide.sh`：CLI 核心（init/status/remove）
- `worktree/wtidex.sh`：增强入口（默认直通 `wtide.sh`；加 `-i` 才进入 gum TUI）
- `worktree/wt`：单文件合并版（包含 `wtide.sh` + `wtidex.sh` 完整能力，便于只传一个文件给同事）
- `worktree/wt.sh`：全托管 worktree 工作流（创建/删除/提交/合并等）

建议用一个环境变量记录脚本位置，避免每次输入绝对路径：

```bash
export AGENT_TOOL_HOME="<path-to-agent-tool>"
```

如果你当前就在 `agent-tool` 仓库根目录，也可以直接用相对路径：

```bash
./worktree/wtide.sh init .
./worktree/wtidex.sh -i
./worktree/wt init .
./worktree/wt.sh worktree list
```

两者的共同目标：
- worktree 场景下递归初始化子模块（失败不阻塞但可观测）
- 子模块分支联动，确保你能在 worktree 内直接提交子模块改动
- 解决 `fatal: working trees containing submodules cannot be moved or removed`

---

## 1) 分支联动规则（核心）

对每个子模块，目标分支按优先级选择：

1. 子模块存在与父仓当前分支同名的分支：切到该分支  
2. 否则如果 `.gitmodules` 配了 `branch = xxx` 且子模块存在该分支：切到该分支  
3. 否则如果子模块当前已经在某个分支上：保持该分支  
4. 否则（detached）：尝试找“包含当前 HEAD commit”的远端分支；再不行就创建父分支同名本地分支

切换后会尽量设置 upstream（若远端存在同名分支），并可选 `pull --ff-only`。

---

## 2) IDE 模式（推荐给 AI IDE）

适用场景：IDE 自己做了 `git worktree add/remove`，你只想在 worktree 内一键把子模块准备好。

### 2.1 初始化（最常用）

进入 IDE 创建的 worktree 目录后执行：

```bash
"${AGENT_TOOL_HOME}/worktree/wtide.sh" init .
```

常用选项：

```bash
"${AGENT_TOOL_HOME}/worktree/wtide.sh" init . --no-fetch --no-pull
"${AGENT_TOOL_HOME}/worktree/wtide.sh" init . --jobs 16
"${AGENT_TOOL_HOME}/worktree/wtide.sh" init . --remote origin
```

### 2.2 查看状态

```bash
"${AGENT_TOOL_HOME}/worktree/wtide.sh" status .
```

### 2.3 删除 worktree（含 submodules）

当你遇到：

```text
fatal: working trees containing submodules cannot be moved or removed
```

用：

```bash
"${AGENT_TOOL_HOME}/worktree/wtide.sh" remove --force-submodules -y <worktree_path>
```

说明：
- 会先尝试原生 `git worktree remove --force`
- 命中 submodule 限制时会先 `submodule deinit`
- 仍失败且你传了 `--force-submodules` 才会执行 `rm -rf <worktree> + 删除 worktrees 元数据 + worktree prune`

---

## 3) 全托管模式（你接管 worktree）

适用场景：你希望用脚本统一入口来创建/删除 worktree，并在需要时“一键提交推送/合并”。

### 3.1 创建 worktree

贴近原生 `git worktree add` 语义：

```bash
"${AGENT_TOOL_HOME}/worktree/wt.sh" worktree add -b li/test/wt ../wt-li
```

指定 start-point（等价于 `git worktree add -b <branch> <path> <start-point>`）：

```bash
"${AGENT_TOOL_HOME}/worktree/wt.sh" worktree add -b li/test/wt ../wt-li main
```

默认行为：
- 创建成功后会自动执行 `wt.sh worktree init <path>`（递归子模块初始化 + 分支标准化）

### 3.2 列出 worktree

```bash
"${AGENT_TOOL_HOME}/worktree/wt.sh" worktree list
```

### 3.3 初始化/对齐子模块（可重复执行）

```bash
"${AGENT_TOOL_HOME}/worktree/wt.sh" worktree init ../wt-li
```

### 3.4 删除 worktree（含 submodules）

```bash
"${AGENT_TOOL_HOME}/worktree/wt.sh" worktree remove --force-submodules -y ../wt-li
```

### 3.5 commit-push（先子模块后父仓）

在 worktree 目录中：

```bash
"${AGENT_TOOL_HOME}/worktree/wt.sh" worktree commit-push "feat: xxx"
```

说明：
- 先提交并 push 子模块（有改动才会提交）
- 再提交并 push 父仓（有改动才会提交）
- push 会用 `-u <remote> <branch>` 设置 upstream（默认 remote=`origin`）

### 3.6 merge（先子模块后父仓）

在 worktree 目录中：

```bash
"${AGENT_TOOL_HOME}/worktree/wt.sh" worktree merge feature/login development
```

说明：
- 先在子模块里尝试合并并 push
- 然后更新父仓 submodule 指针并提交
- 最后合并父仓并 push

---

## 4) 常见建议（避免坑）

- worktree 创建后第一步就跑一次 `wtide.sh init .`（或单文件 `wt init .` / `wt.sh worktree init <path>`），避免子模块停在 detached 导致后续无法提交。
- `--force-submodules` 属于“安全但破坏性”的最终手段：它会删除 worktree 目录并清理 worktree 元数据；确认路径正确再用。
