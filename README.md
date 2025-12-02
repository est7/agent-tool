# agent-tool

用于在任意 Git 仓库中创建 / 管理针对单个任务的 Agent 工作空间, 并为常见平台提供统一的构建/运行入口。

## 安装与前置要求

- 需要 Bash 环境 (`#!/usr/bin/env bash`), 并确保 `git` 可用。
- 建议将 `agent-tool.sh` 放在一个固定路径, 通过绝对路径或脚本包装调用。

## 基础命令

- `./agent-tool.sh create [--base-branch <branch>] <type> <scope>`  
  基于当前仓库创建一个独立的 Agent 仓库, 并以 `agent/<type>/<scope>` 作为分支名。
- `./agent-tool.sh cleanup <type> <scope>`  
  删除对应的 Agent 仓库目录 (不影响主仓)。
- `./agent-tool.sh list`  
  列出所有已存在的 Agent 仓库及其元信息。
- `./agent-tool.sh status`  
  显示所有 Agent 仓库的简要 `git status`。

参数约定:

- `<type>`: `feat | bugfix | refactor | chore | exp`
- `<scope>`: 任务范围, 使用 kebab-case, 例如: `user-profile-header`

## 构建与运行命令

本工具内置了针对常见平台的构建/运行流程, 不需要在项目中额外创建脚本文件:

- `./agent-tool.sh build <platform> [--run] [-- <args...>]`  
  在当前仓库中执行对应平台的构建逻辑。
- `./agent-tool.sh run <platform> [-- <args...>]`  
  便捷运行, 等价于: `build <platform> --run [-- <args...>]`。

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

### 自动平台检测

当你省略 `<platform>` 时, 工具会尝试自动检测:

- `./agent-tool.sh build`  
  若只检测到一种平台结构 (例如仅存在 `gradlew` 或仅存在 `package.json`), 将自动选择该平台。
- `./agent-tool.sh run`  
  同上, 自动检测平台后以 `--run` 模式调用。

检测规则 (只在你未显式指定 `<platform>` 时使用):

- Android: 仓库根目录存在 `./gradlew`
- iOS: 仓库根目录存在 `Project.swift` 或 `Tuist/` 目录
- Web: 仓库根目录存在 `package.json`

当检测不到或检测到多个平台时, 会给出中文错误提示并要求你显式指定平台。

## 平台参数约定

不同平台对 `build`/`run` 的参数约定如下 (省略 `<platform>` 时会自动检测):

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

## 开发与校验

- 语法检查: `bash -n agent-tool.sh`
- 静态分析 (可选): `shellcheck agent-tool.sh`

建议修改脚本后至少执行一次 `bash -n` 以确保没有语法错误。

### 脚本结构说明

当前仓库将功能按职责拆分为多个脚本文件:

- `agent-tool.sh`  
  主入口脚本, 负责:
  - 命令行解析 (`create/cleanup/list/status/build/run/doctor`)
  - 计算 `REPO_ROOT` / `AGENT_ROOT` / `BRANCH` 等公共变量
  - 读取 `.agent-build.yml`, 并按平台分发到对应的构建/自检逻辑
- `agent-workspace.sh`  
  Agent 工作空间相关逻辑:
  - `create` / `cleanup` / `list` / `status`
  - 创建/删除 Agent 仓库目录, 初始化 submodules, 创建分支, 生成 `.agent-meta.yml` 与 `README_AGENT.md`
- `agent-android.sh`  
  Android 平台构建与环境检查 (`build android` / `run android` / `doctor android`)。
- `agent-ios.sh`  
  iOS(Tuist) 平台构建与环境检查 (`build ios` / `run ios` / `doctor ios`)。
- `agent-web.sh`  
  Web 平台构建与环境检查 (`build web` / `run web` / `doctor web`)。

对使用者而言, CLI 使用方式与原先保持一致, 仍然只需要调用 `./agent-tool.sh ...` 即可; 其余脚本由入口自动加载, 无需手动执行。***
