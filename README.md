# agent-tool

用于在任意 Git 仓库中创建 / 管理针对单个任务的 Agent 工作空间, 并为常见平台提供统一的构建/运行入口。内部按模块目录拆分：

- `cfg/`：统一配置脚本（软链初始化/刷新、1mcp 网关管理、MCP 配置生成）
- `doctor/`：自检脚本（含 cfg_doctor）
- `ws/`、`dev/`、`build/`：预留模块目录，便于后续拆分

## 安装与前置要求

- 需要 Bash 环境 (`#!/usr/bin/env bash`), 并确保 `git` 可用。
- 建议将 `agent-tool.sh` 放在一个固定路径, 通过绝对路径或脚本包装调用。

## 基础命令

- `./agent-tool.sh help [group]`  
  显示整体或某个分组的帮助（group 可为 `cfg/ws/test/build/run/doctor` 等）。
- `./agent-tool.sh cfg <subcommand> [...]`  
  针对统一配置目录的快捷操作（软链刷新、自检、生成 MCP 等）。  
  仅输入 `./agent-tool.sh cfg` 时会输出 cfg 子命令帮助。
- `./agent-tool.sh ws <subcommand> [...]`  
  workspace 分组入口，所有 Agent 工作区相关操作都挂在 `ws` 之下。  
  仅输入 `./agent-tool.sh ws` 时会输出 workspace 子命令帮助。
- `./agent-tool.sh dev <subcommand> [...]`  
  预留：开发期流程/规范/模板（当前未实现）。
- `./agent-tool.sh test <platform> <kind> [-- <args...>]`  
  项目级测试入口，用于统一执行各平台的单元测试和覆盖率任务。  
  仅输入 `./agent-tool.sh test` 或加 `-h/--help` 会输出 test 子命令帮助。
- `./agent-tool.sh build <platform> [--run] [-- <args...>]`  
  在当前仓库中执行对应平台的构建逻辑。  
  仅输入 `./agent-tool.sh build` 或加 `-h/--help` 会输出 build 子命令帮助。
- `./agent-tool.sh run <platform> [-- <args...>]`  
  便捷运行, 等价于: `build <platform> --run [-- <args...>]`。  
  仅输入 `./agent-tool.sh run` 或加 `-h/--help` 会输出 run 子命令帮助。
- `./agent-tool.sh doctor <target>`  
  检查当前仓库针对平台的构建环境，或对 CLI 自身做自检。  
  仅输入 `./agent-tool.sh doctor` 或加 `-h/--help` 会输出 doctor 子命令帮助。

参数约定:

- `<type>`: `feat | bugfix | refactor | chore | exp`
- `<scope>`: 任务范围, 使用 kebab-case, 例如: `user-profile-header`
- `cfg` 子命令:
  - `cfg init` / `cfg init-force`: 运行 `cfg/install_symlinks.sh -v [--force]`
  - `cfg refresh`: 刷新文件级软链（新增 commands/skills/hooks/agents 后用）
  - `cfg selftest [--v]`: 自检配置目录与软链状态
  - `cfg mcp [options]`: 在项目根生成项目级 .1mcprc 配置
  - `cfg 1mcp <cmd>`: 管理 1mcp 统一 MCP 网关（详见下方 1mcp 章节）
 - `ws` 子命令:
  - `ws create [--base-branch <branch>] <type> <scope>`
  - `ws cleanup [--force] <type> <scope>` # 默认交互确认；--force 为非交互危险删除
  - `ws list`
  - `ws status`

## 构建与运行命令

本工具内置了针对常见平台的构建/运行流程, 不需要在项目中额外创建脚本文件:

支持的平台与行为概要:

- `android`:
  - 使用 `./gradlew assemble<Variant>` 进行构建。
  - `--run` 时额外执行 `./gradlew install<Variant>` + `adb shell monkey -p <包名> ...` 启动应用。
- `ios`:
  - 使用 `tuist build <Scheme> [destination...]` 构建。
  - `--run` 时使用 `tuist run <Scheme> [destination...]` 运行。
- `web`:
  - 自动选择 `pnpm` > `yarn` > `npm` 作为包管理器。
  - 构建: `pnpm build` / `yarn build` / `npm run build`。
  - 运行: `pnpm dev` / `yarn dev` / `npm run dev`。

示例:

- Android:
  - 仅构建: `./agent-tool.sh build android com.myapp Debug`
  - 构建并运行: `./agent-tool.sh build android --run com.myapp Debug`
  - 便捷运行: `./agent-tool.sh run android com.myapp Debug`
- iOS:
  - 仅构建: `./agent-tool.sh build ios MyAppScheme`
  - 构建并运行: `./agent-tool.sh build ios --run MyAppScheme "iPhone 16 Pro"`
- Web:
  - 仅构建: `./agent-tool.sh build web`
  - 构建并运行: `./agent-tool.sh build web --run`
  - 便捷运行: `./agent-tool.sh run web`

> 注意：`build` / `run` 在真正执行构建/运行时仍需要显式指定 `<platform>`；  
> 若未指定，则被视为查看该子命令的帮助，而不会尝试自动检测平台。

## 项目测试命令

- `./agent-tool.sh test <platform> <kind> [-- <args...>]`  
  在当前仓库中执行对应平台的测试逻辑。

platform:
- `android`：通过 `./gradlew` 运行 Android 测试。
- `ios`：通过 `tuist test` 运行 iOS 测试（依赖 `.agent-build.yml` 中的 `ios_scheme` 或命令行显式传入）。
- `web`：通过 `pnpm` / `yarn` / `npm` 运行 Web 测试。

kind:
- `unit`：运行单元测试。
- `coverage`：运行覆盖率相关任务（具体命令视平台和项目而定）。

示例:

- Android:
  - 单元测试（默认任务）:  
    `./agent-tool.sh test android unit` → `./gradlew test`
  - 单元测试（自定义任务）:  
    `./agent-tool.sh test android unit -- testDebugUnitTest`
  - 覆盖率（默认任务）:  
    `./agent-tool.sh test android coverage` → `./gradlew jacocoTestReport`
  - 覆盖率（自定义任务）:  
    `./agent-tool.sh test android coverage -- jacocoMyModuleReport`

- iOS:
  - 单元测试（从 `.agent-build.yml` 读取 `ios_scheme`）:  
    `./agent-tool.sh test ios unit`
  - 单元测试（显式指定 scheme）:  
    `./agent-tool.sh test ios unit MyAppScheme`
  - 覆盖率:  
    `./agent-tool.sh test ios coverage MyAppScheme -- --configuration Debug`  
    > 覆盖率开关由 Xcode/Tuist 工程配置控制，本命令只负责调用 `tuist test`。

- Web:
  - 单元测试:  
    `./agent-tool.sh test web unit` → `pnpm/yarn/npm test`
  - 覆盖率（假设使用支持 `--coverage` 的测试框架，如 Jest）:  
    `./agent-tool.sh test web coverage` → `pnpm/yarn/npm test -- --coverage`

## 推荐开发流程（Android 示例）

以下是一个从「初始化配置」到「构建/测试/自检」的完整工作流示例：

1. 在新机器上初始化统一配置目录（仅需执行一次）：

   ```bash
   ./agent-tool.sh cfg init
   ```

2. 在主仓中为当前需求创建 Agent workspace：

   ```bash
   ./agent-tool.sh ws create feat user-profile-header
   ```

3. 在主仓根目录根据需要配置 `.agent-build.yml`（可选），例如：

   ```yaml
   android_package: com.myapp
   android_default_variant: Debug
   ios_scheme: MyAppScheme
   ```

4. 在主仓根目录执行构建（以 Android 为例）：

   ```bash
   ./agent-tool.sh build android com.myapp Debug
   ```

5. 在主仓根目录运行项目级单元测试：

   ```bash
   ./agent-tool.sh test android unit
   ```

6. 检查当前仓库的 Android 构建环境（可选）：

   ```bash
   ./agent-tool.sh doctor android
   ```

7. 需求完成后，清理对应的 Agent workspace（在主仓根目录执行）：

   ```bash
   ./agent-tool.sh ws cleanup feat user-profile-header
   ```

   如需在脚本/CI 中非交互清理，可使用：

   ```bash
   ./agent-tool.sh ws cleanup --force feat user-profile-header
   ```

## 平台参数约定

不同平台对 `build`/`run` 的参数约定如下：

- Android:
  - `./agent-tool.sh build android [--run] <包名> [variant]`
  - 默认 `variant` 为 `Debug`。
  - 例如:
    - `./agent-tool.sh build android com.myapp`
    - `./agent-tool.sh run android com.myapp Release`
- iOS:
  - `./agent-tool.sh build ios [--run] <scheme> [destination...]`
  - `destination` 用于透传 Tuist 的参数, 如:
    - `--device "iPhone 16 Pro"`
    - `--configuration Debug`
- Web:
  - `./agent-tool.sh build web [--run] [extra-args...]`
  - `extra-args` 会透传给 `dev`/`build` 命令, 例如:
    - `./agent-tool.sh run web -- --host 0.0.0.0`

## .agent-build.yml 配置 Schema

`.agent-build.yml` 是**可选**的:  
没有该文件时, `build`/`run` 仍然可以使用, 只是需要你在命令行中显式传入包名 / scheme 等参数。

当你希望减少重复输入时, 可以在每个工程根目录下创建 `.agent-build.yml` 来提供默认值。

### 推荐模板

```yaml
# Android 相关 (可选)
android_package: com.myapp              # 默认包名, 例如 com.myapp
android_default_variant: Debug          # 默认构建变体, 例如 Debug / Release

# iOS 相关 (可选, Tuist 工程)
ios_scheme: MyApp                       # 默认 Tuist scheme 名称, 例如 MyApp

# Web 相关 (预留字段, 当前版本未读取)
# web_package_manager: pnpm             # 指定包管理器: pnpm / yarn / npm
# web_dev_script: dev                   # dev 脚本名: 默认为 dev
# web_build_script: build               # build 脚本名: 默认为 build
```

### 字段说明 (当前支持)

- `android_package` (可选)
  - 用于 Android 平台, 表示默认应用包名。
  - 当你执行 `build android` / `run android` 且**没有传入包名**时, 会使用该值。
- `android_default_variant` (可选)
  - 用于 Android 平台, 表示默认构建变体 (如 `Debug` / `Release`)。
  - 当你未在命令行中指定 variant 且配置了该字段时, 会作为第二个参数传给 `gradlew assemble/install`。
- `ios_scheme` (可选)
  - 用于 iOS (Tuist) 平台, 表示默认 scheme。
  - 当你执行 `build ios` / `run ios` 且**没有传入 scheme**时, 会使用该值。

当前版本中, `agent-tool.sh` 只会读上述三个字段; Web 相关字段为将来扩展预留, 不会影响当前行为。

### 行为细节

- 当你执行 `build`/`run` 且**没有提供任何额外参数**时:
  - Android:
    - 若平台为 `android`, 且 `.agent-build.yml` 中配置了 `android_package`:
      - 使用该值作为包名。
      - 若还配置了 `android_default_variant`, 则作为默认 variant。
      - 例如: `.agent-build.yml` 如推荐模板配置时:
        - `./agent-tool.sh run android`  
          等价于执行: `./gradlew assembleDebug && ./gradlew installDebug && adb shell monkey -p com.myapp ...`
    - 若 `android_package` 未配置且你也未在命令行传参:
      - 工具会报错, 提示你在命令行传入包名, 或在 `.agent-build.yml` 中补充 `android_package`。
  - iOS:
    - 若平台为 `ios`, 且 `.agent-build.yml` 中配置了 `ios_scheme`:
      - 使用该值作为默认 scheme。
      - 例如: `./agent-tool.sh build ios` → `tuist build MyApp`。
    - 若 `ios_scheme` 未配置且你也未在命令行传参:
      - 工具会报错, 提示你在命令行传入 scheme, 或在 `.agent-build.yml` 中补充 `ios_scheme`。
  - Web:
    - 当前版本不会从 `.agent-build.yml` 中读取 Web 字段, 即使不存在 `.agent-build.yml`, 也可以正常运行:
      - `./agent-tool.sh build web`
      - `./agent-tool.sh run web -- --host 0.0.0.0`

## doctor 自检命令

- `./agent-tool.sh doctor <platform>`

用途: 快速检查当前仓库是否已经为指定平台准备好必要的工程结构与关键工具链。  
仅输入 `./agent-tool.sh doctor` 或加 `-h/--help` 会输出 doctor 子命令帮助。
额外检查: 自动调用 `doctor/cfg_doctor.sh` 执行统一配置目录（AGENT_HOME）软链与目录自检。

检查内容 (不会修改任何文件, 仅输出信息):

- Android:
  - 仓库根目录是否存在 `./gradlew`
  - `adb` 是否可用
- iOS:
  - 是否存在 `Project.swift` 或 `Tuist/` 目录
  - `tuist` 是否可用
  - `xcodebuild` 是否可用
- Web:
  - 仓库根目录是否存在 `package.json`
  - 是否存在 `pnpm` / `yarn` / `npm` 之一

示例:

- `./agent-tool.sh doctor android`
- `./agent-tool.sh doctor ios`
- `./agent-tool.sh doctor web`

输出中会用 `✔` / `✖` 标记检查结果, 并在失败时给出建议 (例如「请安装 tuist 并配置 PATH」等)。

## 配置快捷命令 (cfg)

`agent-tool.sh` 内置 `cfg` 子命令，调用 `cfg/` 目录下的脚本（默认路径 `$(dirname agent-tool.sh)/cfg`，可通过 `CFG_DIR` 覆盖，`DOCTOR_DIR` 覆盖自检脚本路径）。

示例：

```bash
# 初始化软链（同时配置 1mcp 端点）
./agent-tool.sh cfg init

# 强制接管非软链路径
./agent-tool.sh cfg init-force

# 新增 commands/skills/hooks/agents 后刷新软链
./agent-tool.sh cfg refresh

# 自检配置目录及软链
./agent-tool.sh cfg selftest -v

# 在项目根生成项目级 .1mcprc 配置
./agent-tool.sh cfg mcp
./agent-tool.sh cfg mcp --tags "core"
```

## 1mcp 统一 MCP 网关

`agent-tool` 使用 [1mcp](https://github.com/1mcp-app/agent) 作为统一 MCP 网关，为 Claude Code、Codex CLI、Gemini CLI 提供统一的 MCP 服务入口。

### 架构说明

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Claude Code   │    │    Codex CLI    │    │   Gemini CLI    │
└────────┬────────┘    └────────┬────────┘    └────────┬────────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                │
                                ▼
                   ┌────────────────────────┐
                   │  1mcp HTTP Server      │
                   │  http://127.0.0.1:3050 │
                   └────────────┬───────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
         ▼                      ▼                      ▼
   ┌───────────┐        ┌───────────┐        ┌───────────┐
   │ sequential│        │  context7 │        │  memory   │
   │ -thinking │        │           │        │           │
   └───────────┘        └───────────┘        └───────────┘
```

### 1mcp 子命令

```bash
# 安装 1mcp binary
./agent-tool.sh cfg 1mcp install

# 启动 1mcp server（后台运行）
./agent-tool.sh cfg 1mcp start

# 停止 1mcp server
./agent-tool.sh cfg 1mcp stop

# 重启 1mcp server
./agent-tool.sh cfg 1mcp restart

# 查看运行状态
./agent-tool.sh cfg 1mcp status

# 设置开机自启（macOS: launchd, Linux: systemd）
./agent-tool.sh cfg 1mcp enable

# 取消开机自启
./agent-tool.sh cfg 1mcp disable

# 查看日志
./agent-tool.sh cfg 1mcp logs
./agent-tool.sh cfg 1mcp logs -f  # 实时跟踪
```

### 配置文件

| 文件 | 说明 |
|------|------|
| `~/.agents/mcp/mcp.json` | 全局 MCP servers 配置（1mcp 格式） |
| `~/.agents/mcp/1mcp.pid` | 1mcp 进程 PID 文件 |
| `~/.agents/mcp/logs/1mcp.log` | 1mcp 日志文件 |
| `.1mcprc` | 项目级配置（可选，用于过滤 servers） |

### 首次设置流程

```bash
# 1. 初始化配置（会自动配置各 CLI 的 1mcp 端点）
./agent-tool.sh cfg init

# 2. 安装 1mcp binary
./agent-tool.sh cfg 1mcp install

# 3. 启动 1mcp server
./agent-tool.sh cfg 1mcp start

# 4. 验证状态
./agent-tool.sh cfg 1mcp status

# 5.（可选）设置开机自启
./agent-tool.sh cfg 1mcp enable
```

### 项目级配置

在项目根目录运行 `cfg mcp` 可生成 `.1mcprc` 文件，用于过滤该项目使用的 MCP servers：

```bash
# 生成默认配置（使用所有 servers）
./agent-tool.sh cfg mcp

# 只使用带 "core" 标签的 servers
./agent-tool.sh cfg mcp --tags "core"

# 使用预设
./agent-tool.sh cfg mcp --preset web-dev
```

### 默认 MCP Servers

`cfg init` 会在 `~/.agents/mcp/mcp.json` 中配置以下 MCP servers：

| Server | 标签 | 说明 |
|--------|------|------|
| `sequential-thinking` | core, all | 结构化思考 |
| `context7` | core, all, search | 库/框架文档查询 |
| `memory` | core, all | 知识图谱 |
| `claudecode-mcp-async` | agent-cli, all | Claude Code 异步调用 |
| `codex-mcp-async` | agent-cli, all | Codex CLI 异步调用 |
| `gemini-cli-mcp-async` | agent-cli, all | Gemini CLI 异步调用 |

## 开发与校验

- 语法检查: `bash -n agent-tool.sh`
- 静态分析 (可选): `shellcheck agent-tool.sh`
- CLI 自检: `./agent-tool.sh doctor cli`（对核心脚本执行一次 `bash -n`，包括 `cfg/aliases.d/*.sh`）

## 错误码约定

所有错误码均通过 `agent_error "<CODE>" "<message>"` 输出，便于人类与脚本/AI 统一解析。

- 命名规则: `E_<域>_<含义>`，例如:
  - `E_GIT_MISSING`：环境缺失类错误（缺少 git）
  - `E_ANDROID_GRADLEW_MISSING`：平台工具缺失（缺少 `./gradlew`）
  - `E_BUILD_CONFIG`：配置不完整或缺失（如 `.agent-build.yml` 中未设置必须字段）
  - `E_INTERNAL`：内部逻辑错误（通常表示 bug，应该修脚本而不是改调用方式）

常见错误码示例（部分）:

- Git / Workspace 相关
  - `E_GIT_MISSING`：未找到 `git` 命令，需先安装 git 并确保在 PATH 中。
  - `E_NOT_GIT_REPO`：当前目录不在任何 Git 仓库内，需要在主仓根目录或其子目录调用 `agent-tool.sh`。
  - `E_AGENT_ROOT_INVALID`：`AGENT_ROOT` 或 `AGENT_DIR` 不合法（为空、为根目录、或不在 `AGENT_ROOT` 下等），为避免误删会拒绝执行 `ws cleanup`。
- 参数与配置相关
  - `E_ARG_MISSING`：缺少必要参数，例如未提供 `<type>/<scope>` 或 `<platform>/<kind>`。
  - `E_ARG_INVALID`：参数值不在支持列表中，例如未知的 `type` 或 `platform`。
  - `E_BUILD_CONFIG`：构建相关配置不完整，例如未提供 Android 包名或 iOS scheme，且 `.agent-build.yml` 也未补全。
  - `E_TEST_CONFIG`：测试相关配置不完整，例如 iOS 测试中未提供 scheme 且 `.agent-build.yml` 中缺少 `ios_scheme`。
- 平台环境相关
  - `E_ANDROID_GRADLEW_MISSING`：当前仓库根目录缺少 `./gradlew`。
  - `E_ANDROID_ADB_MISSING`：`adb` 不可用，无法在 `--run` 模式下安装/启动应用。
  - `E_ANDROID_DEVICE_MISSING`：未检测到任何已连接的设备/模拟器。
  - `E_IOS_TUIST_MISSING` / `E_IOS_XCODEBUILD_MISSING`：缺少 `tuist` 或 `xcodebuild`。
  - `E_WEB_PACKAGE_JSON_MISSING`：当前目录不存在 `package.json`，不被视为 Web 工程根目录。
  - `E_WEB_PM_MISSING`：未找到 `pnpm`/`yarn`/`npm` 任意一个包管理器。
- 自检相关
  - `E_TEST_FILE_MISSING`：`doctor cli` 期望存在的脚本文件缺失。
  - `E_TEST_BASH_N`：对某个脚本执行 `bash -n` 语法检查失败。
  - `E_TEST_FAILED`：`doctor cli` 总体自检失败（至少一个子检查失败）。

整体约定:

- 若错误属于「调用方式或配置问题」，会尽量给出下一步建议（需要补哪些参数/字段）。  
- 若错误属于「环境问题」，会指明缺少哪个工具/文件及安装方向。  
- 若出现 `E_INTERNAL`，一般表示脚本本身需要修复，建议先跑一次 `doctor cli` 并查看 issue/TODO。  

## 全局配置文件 (~/.agent-tool/config)

`agent-tool.sh` 启动时会尝试加载全局配置文件（默认路径 `~/.agent-tool/config`，可通过 `AGENT_TOOL_CONFIG` 环境变量覆盖），该文件是一个普通的 shell 脚本片段，可以用来设置一些默认变量，例如:

```bash
# 默认 Agent workspace 根目录（未显式设置 AGENT_ROOT 时，用于拼接 <repo>-agents）
AGENT_ROOT="$HOME/Agents"

# ws create 默认基线分支（未指定 --base-branch 时优先使用）
DEFAULT_BASE_BRANCH="dev"

# 统一配置目录（cfg/install_symlinks.sh 和 doctor/cfg_doctor.sh 会读取）
AGENT_HOME="$HOME/.agents"
```

注意:
- 配置文件在加载时会继承 `set -euo pipefail`，请只写简单的赋值语句，避免有副作用的命令。
- CLI 实际行为以命令行参数优先（例如 `ws create --base-branch` 会覆盖 `DEFAULT_BASE_BRANCH`）。

建议修改脚本后至少执行一次 `bash -n` 以确保没有语法错误。

### 脚本结构说明

当前仓库将功能按职责拆分为多个脚本文件/子目录:

- `agent-tool.sh`  
  主入口脚本, 负责:
  - 命令行解析 (`create/cleanup/list/status/build/run/doctor/cfg/ws/dev`)
  - 计算 `REPO_ROOT` / `AGENT_ROOT` / `BRANCH` 等公共变量
  - 读取 `.agent-build.yml`, 并按平台分发到对应的构建/自检逻辑
  - 将 `ws/` / `build/` / `doctor/` 等子模块加载进来
  - `ws/workspace.sh`  
  Agent 工作空间相关逻辑:
  - `create_agent_repo` / `cleanup_agent_repo` / `list_agents` / `status_agents`
  - 创建/删除 Agent 仓库目录, 初始化 submodules, 创建分支, 生成 `.agent-meta.yml` 与 `README_AGENT.md`
  - 对 `ws cleanup` 的删除操作增加了路径安全保护, 仅允许删除位于 `AGENT_ROOT` 下且合法的 Agent 仓库目录, 并在非 `--force` 模式下要求交互确认。
- `build/platforms.sh`  
  平台构建与运行逻辑:
  - `build_agent_project` 统一入口
  - `build_android_project` / `build_ios_project` / `build_web_project`
  - `maybe_fill_build_args_from_config` 读取 `.agent-build.yml` 补全默认参数
- `doctor/` 目录  
  - `doctor/cfg_doctor.sh`：检查统一配置目录（AGENT_HOME）与软链状态
  - `doctor/platforms.sh`：针对 Android / iOS / Web 的构建环境自检 (`doctor_*_environment` + `doctor_agent_environment`)
- `cfg/` 目录
  - `cfg/install_symlinks.sh`：初始化/刷新软链，配置 1mcp HTTP 端点
  - `cfg/1mcp/index.sh`：1mcp 子命令（install/start/stop/status/enable/disable/logs/init-project）
  - `cfg/aliases.sh`：别名 loader（按职责拆分在 `cfg/aliases.d/*.sh` 中）
  - `cfg/index.sh`：提供 `agent_error` 等通用工具函数
 - `dev/` 目录  
   - `dev/index.sh`：预留 dev 模块入口（未来扩展用）
 - `test/` 目录  
   - `test/index.sh`：`agent-tool test` 子命令实现入口

对使用者而言, CLI 使用方式与原先保持一致, 仍然只需要调用 `./agent-tool.sh ...` 即可; 其余脚本由入口自动加载, 无需手动执行。***
