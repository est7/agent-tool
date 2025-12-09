# Agent 开发全流程指南

本文件描述从「任务创建（CTG/Issue）」到「通过 `ws` 创建 Agent 副本、初始化 MCP、开发/测试/构建/运行，再到发布与清理」的完整工作流，适用于人类与代码 Agent 协同开发。

目标：
- 主仓 1 个，多 Agent clone 并行开发；
- 每个任务在独立分支 + 独立 clone 中进行；
- 在多层 Git submodule 场景下避免互相踩工作区、避免误删目录。

---

## 1. 目录结构与命名

顶层目录约定：

```text
<parent-dir>/
  ├─ <repo-name>/                         # 主开发仓库（人类日常开发）
  └─ <repo-name>-agents/                  # 所有 Agent 专用 clone 由 ws 管理
       ├─ <repo-name>-agent-feat-user-profile-header/
       ├─ <repo-name>-agent-bugfix-payment-api-timeout/
       └─ ...
```

约束：
- 不在主仓目录内部再创建新的 Git 仓库（除正式配置的 submodule 外）。
- 所有 Agent clone 必须放在 `<repo-name>-agents/` 目录下，由 `agent-tool.sh ws` 创建和清理。

任务与分支命名：
- `type`（任务类型）：`feat | bugfix | refactor | chore | exp`
- `scope`（任务范围）：简短 kebab-case，例如 `user-profile-header`、`payment-api-timeout`
- 分支：`agent/<type>/<scope>`（主仓 & Agent 仓统一）
- Agent 目录：`<repo-name>-agent-<type>-<scope>/`

---

## 2. 从 CTG/Issue 到 Agent Workspace

1. 在 CTG/任务系统中确认本次任务的：
   - 任务类型：映射为 `type`
   - 范围/关键词：整理为 `scope`（kebab-case）
2. 在主仓根目录（`<repo-name>/`）拉取最新基线分支，例如：
   - `git checkout dev` 或 `git checkout main`
   - `git pull`
3. 使用 `ws create` 创建 Agent 副本与分支：

```bash
./agent-tool.sh ws create [--base-branch dev] <type> <scope>
```

效果：
- 在 `<parent-dir>/<repo-name>-agents/` 下创建对应 Agent 仓；
- 为主仓和 Agent 仓各自创建/切换到 `agent/<type>/<scope>` 分支；
- 写入 `.agent-meta.yml` 记录任务元信息。

---

## 3. 在 Agent 仓内初始化 MCP 与工具

进入新建的 Agent 仓目录（示例）：

```bash
cd ../<repo-name>-agents/<repo-name>-agent-<type>-<scope>/
```

推荐初始化步骤：

1. 若是首次在该机器使用 agent-tool，全局初始化统一配置目录：

```bash
./agent-tool.sh cfg init
```

2. 为当前项目生成 MCP 配置（按实际使用的提供方选择参数）：

```bash
./agent-tool.sh cfg mcp -v --codex       # 或 --claude / --gemini 等
```

3. 可选：对 CLI 自身做一次自检，确保脚本语法与软链正常：

```bash
./agent-tool.sh doctor cli
```

---

## 4. 开发与本地验证（test / build / run）

在 Agent 仓内进行日常开发（编辑代码、提交 commit），并通过统一入口运行测试与构建：

- 项目级单元测试：

```bash
./agent-tool.sh test <platform> unit
```

- 覆盖率任务：

```bash
./agent-tool.sh test <platform> coverage
```

- 构建当前项目：

```bash
./agent-tool.sh build <platform> [--run] [-- <args...>]
```

- 便捷运行（等价于 `build <platform> --run`）：

```bash
./agent-tool.sh run <platform> [-- <args...>]
```

说明：
- `platform` 为 `android | ios | web`，具体行为见根目录 `README.md`。
- 可在目标项目根目录配置 `.agent-build.yml`，减少重复传参（包名、scheme、变体等）。

推荐顺序：
1. 频繁跑 `test unit` 做快速反馈；
2. 重要改动前后跑一次 `test coverage` 或平台自带覆盖率；
3. 通过 `build`/`run` 验证可构建、可运行；
4. 有环境问题时优先用 `./agent-tool.sh doctor <platform>` 排查。

---

## 5. 提交、发布与清理

在 Agent 仓内：
- 使用约定格式编写 commit message，例如：`feat: add web build helper`
- 确保所有相关测试通过、`doctor cli` 无错误。

在主仓根目录：
1. 确认本地分支 `agent/<type>/<scope>` 与远程同步：

```bash
git push -u origin agent/<type>/<scope>
```

2. 在代码托管平台上以该分支创建 PR：
   - 标题包含 `type` + 简短说明；
   - 描述中简要写明背景、变更点、验证用到的 `agent-tool.sh test/build/run` 命令；
   - 链接 CTG 任务或 Issue。

3. PR 合并并上线后，清理对应 Agent workspace：

```bash
cd <repo-name>/
./agent-tool.sh ws cleanup <type> <scope>          # 交互确认
# 或
./agent-tool.sh ws cleanup --force <type> <scope>  # 非交互模式（脚本/CI）
```

注意：
- 只通过 `ws cleanup` 删除 Agent 仓，不要手动 rm 目录；
- 如需查看当前活跃 Agent 列表，可使用：

```bash
./agent-tool.sh ws list
./agent-tool.sh ws status
```

---

## 6. 示例：从 CTG 任务到完成发布

假设 CTG 中有任务「为 Android 项目新增用户中心页」，约定：
- `type = feat`
- `scope = user-center-screen`

典型流程：

```bash
# 在主仓
cd <repo-name>/
git checkout dev
git pull
./agent-tool.sh ws create --base-branch dev feat user-center-screen

# 进入 Agent 仓
cd ../<repo-name>-agents/<repo-name>-agent-feat-user-center-screen/
./agent-tool.sh cfg mcp -v --codex
./agent-tool.sh doctor cli

# 开发 & 本地验证
./agent-tool.sh test android unit
./agent-tool.sh build android com.myapp Debug
./agent-tool.sh run android com.myapp Debug

# 提交 & 推送
git commit -am "feat: add user center screen"
git push -u origin agent/feat/user-center-screen

# PR 合并上线后，在主仓清理
cd ../<repo-name>/
./agent-tool.sh ws cleanup feat user-center-screen
```

按照以上流程，人类与代码 Agent 均可以在统一的 Git 结构与命令约定下，高效且可控地完成从「任务创建」到「发布与清理」的完整闭环。
