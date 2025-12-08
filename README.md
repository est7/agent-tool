# agent-tool

用于在任意 Git 仓库中创建 / 管理针对单个任务的 Agent 工作空间, 并为常见平台提供统一的构建/运行入口。内部按模块目录拆分：

- `cfg/`：统一配置脚本（软链初始化/刷新、MCP 生成、别名）
- `doctor/`：自检脚本（含 cfg_doctor）
- `ws/`、`dev/`、`build/`：预留模块目录，便于后续拆分

## 安装与前置要求

- 需要 Bash 环境 (`#!/usr/bin/env bash`), 并确保 `git` 可用。
- 建议将 `agent-tool.sh` 放在一个固定路径, 通过绝对路径或脚本包装调用。

## 基础命令

- `./agent-tool.sh ws <subcommand> [...]`  
  workspace 分组入口，所有 Agent 工作区相关操作都挂在 `ws` 之下。
- `./agent-tool.sh cfg <subcommand> [...]`  
  针对统一配置目录的快捷操作（软链刷新、自检、生成 MCP 等）。

参数约定:

- `<type>`: `feat | bugfix | refactor | chore | exp`
- `<scope>`: 任务范围, 使用 kebab-case, 例如: `user-profile-header`
- `ws` 子命令:
  - `ws create [--base-branch <branch>] <type> <scope>`
  - `ws cleanup --force <type> <scope>`   # 危险: 删除 agent workspace 目录
  - `ws list`
  - `ws status`
- `cfg` 子命令:
  - `cfg init` / `cfg init-force`: 运行 `cfg/install_symlinks.sh -v [--force]`
  - `cfg refresh`: 刷新文件级软链（新增 commands/skills/hooks/agents 后用）
  - `cfg selftest [--v]`: 自检配置目录与软链状态
  - `cfg mcp [options]`: 在项目根生成项目级 MCP 配置（透传选项到 `project_mcp_setup.sh`）

## 构建与运行命令

本工具内置了针对常见平台的构建/运行流程, 不需要在项目中额外创建脚本文件:

- `./agent-tool.sh build <platform> [--run] [-- <args...>]`  
  在当前仓库中执行对应平台的构建逻辑（必须显式指定 `<platform>`）。
- `./agent-tool.sh run <platform> [-- <args...>]`  
  便捷运行, 等价于: `build <platform> --run [-- <args...>]`（同样需要显式指定 `<platform>`）。

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

> 注意：`build` / `run` 必须显式指定 `<platform>`，不再支持省略后自动检测平台。

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
额外检查: 自动调用 `doctor/cfg_doctor.sh` 执行统一配置目录（AI_HOME）软链与目录自检。

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
# 初始化软链
./agent-tool.sh cfg init

# 强制接管非软链路径
./agent-tool.sh cfg init-force

# 新增 commands/skills/hooks/agents 后刷新软链
./agent-tool.sh cfg refresh

# 自检配置目录及软链
./agent-tool.sh cfg selftest -v

# 在项目根生成项目级 MCP 配置（Claude/Gemini/Codex）
./agent-tool.sh cfg mcp -v --claude
```

## 开发与校验

- 语法检查: `bash -n agent-tool.sh`
- 静态分析 (可选): `shellcheck agent-tool.sh`
- 自检: `./agent-tool.sh test self`（对核心脚本执行一次 `bash -n`）

## 全局配置文件 (~/.agent-tool/config)

`agent-tool.sh` 启动时会尝试加载全局配置文件（默认路径 `~/.agent-tool/config`，可通过 `AGENT_TOOL_CONFIG` 环境变量覆盖），该文件是一个普通的 shell 脚本片段，可以用来设置一些默认变量，例如:

```bash
# 默认 Agent workspace 根目录（未显式设置 AGENT_ROOT 时，用于拼接 <repo>-agents）
AGENT_ROOT="$HOME/Agents"

# ws create 默认基线分支（未指定 --base-branch 时优先使用）
DEFAULT_BASE_BRANCH="dev"

# 统一配置目录（cfg/install_symlinks.sh 和 doctor/cfg_doctor.sh 会读取）
AI_HOME="$HOME/.agents"
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
- `build/platforms.sh`  
  平台构建与运行逻辑:
  - `build_agent_project` 统一入口
  - `build_android_project` / `build_ios_project` / `build_web_project`
  - `maybe_fill_build_args_from_config` 读取 `.agent-build.yml` 补全默认参数
- `doctor/` 目录  
  - `doctor/cfg_doctor.sh`：检查统一配置目录（AI_HOME）与软链状态
  - `doctor/platforms.sh`：针对 Android / iOS / Web 的构建环境自检 (`doctor_*_environment` + `doctor_agent_environment`)
- `cfg/` 目录  
  - `cfg/install_symlinks.sh`：初始化/刷新软链
  - `cfg/project_mcp_setup.sh`：基于 snippet 生成项目级 MCP 配置
  - `cfg/aliases.sh`：别名 loader（按职责拆分在 `cfg/aliases.d/*.sh` 中）
  - `cfg/index.sh`：提供 `agent_error` 等通用工具函数
 - `dev/` 目录  
   - `dev/index.sh`：预留 dev 模块入口（未来扩展用）
 - `test/` 目录  
   - `test/index.sh`：`agent-tool test` 子命令实现入口

对使用者而言, CLI 使用方式与原先保持一致, 仍然只需要调用 `./agent-tool.sh ...` 即可; 其余脚本由入口自动加载, 无需手动执行。***
