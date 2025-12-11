# TODO

## agent-tool 脚本改进（本次评审）

- [ ] `ws cleanup` 增加路径安全保护  
  - [x] 在 `agent-tool.sh` 中为 `cleanup_agent_repo` 所在分支增加对 `AGENT_ROOT`/`AGENT_DIR` 的空值和根路径检测（例如 `"/"`、`"/home"` 这类明显不合法的 agent 根目录）。  
  - [x] 在 `ws/workspace.sh` 的 `cleanup_agent_repo` 内部增加前缀检查：`AGENT_DIR` 必须以 `"${AGENT_ROOT}/"` 开头，否则调用 `agent_error "E_AGENT_ROOT_INVALID"` 并退出。  
  - [x] 在 README 中补充 `E_AGENT_ROOT_INVALID` 的错误码说明。  
  - [ ] 手动验证（待在真实项目中执行）：  
    - 在正常配置下执行 `ws cleanup --force <type> <scope>`，确认删除行为不受影响；  
    - 将 `AGENT_ROOT` 人为设置成错误路径（如临时目录），确认脚本拒绝执行并给出清晰错误。
- [ ] 修正 `agent-tool test web coverage` 在 `npm` 场景下多余的 `--` 传参，统一为 `… test -- --coverage` 行为  
  - [x] 在 `test/index.sh` 的 `test_web_project` 中，将默认 `extra_args` 调整为 `(--coverage)`，并分别对 `pnpm` / `yarn` / `npm` 做参数展开检查。  
  - [x] 确认 `npm` 分支最终调用形态为：`npm test -- --coverage`，没有多余的 `--`（通过代码审查和参数展开逻辑确认）。  
  - [ ] 在没有 `package.json` 的目录下运行 `agent-tool test web coverage`，确认仍然优先触发 `E_WEB_PACKAGE_JSON_MISSING` 而不是参数错误。  
  - [ ] 在真实 Web 仓库中手动跑一次 `pnpm` 或 `npm` 的单元测试/覆盖率命令，确保行为符合预期。
- [ ] 在计算 `REPO_ROOT` 前增加 `git` 可用性检查，给出清晰的中文错误提示  
  - [x] 在 `agent-tool.sh` 中、调用 `git rev-parse --show-toplevel` 之前增加 `command -v git` 检查，若不存在则输出 `E_GIT_MISSING` 并提示安装 git。  
  - [x] 调整非 git 仓库场景下的错误信息文案，明确区分「没装 git」和「当前目录不是 git 仓库」。  
  - [ ] 在一个无 git 命令的模拟环境（或手动 `PATH` 隔离）中试运行脚本，确认错误信息对人类和 AI 都足够清晰（可通过阅读代码进行静态验证）。
- [x] 为 `ws cleanup` 增加交互式确认模式：无 `--force` 时提示确认，带 `--force` 时保持当前非交互行为。
- [x] 抽取 help 分支中的 `-h/--help` 判断为通用工具函数，减少重复逻辑。
- [x] 优化 `agent_tool_test_self`：改为自动发现/匹配脚本（特别是 `cfg/aliases.d/*.sh`），避免新增脚本时漏检。
- [x] 减少模块函数对全局变量的隐式依赖，为 `create_agent_repo` 等增加参数化入口，提升可维护性与可测试性。
- [x] 在 usage/README 中更显式说明 `run` 等价于 `build <platform> --run` 的关系，改善用户理解。

## CLI & UX

- [ ] 为 `agent-tool help` 增加机器可解析输出模式（例如 `agent-tool help --json`），包含各 group 的子命令、参数和示例，便于 AI 自动生成调用。

## Workspace 生命周期与元信息

- [ ] 为 `ws create` 增加可选 `--task-id <id>` 参数，将 CTG/Issue ID 写入 `.agent-meta.yml`，并用于默认分支/目录命名（如 `agent/feat/1234-user-center-screen`）。
- [ ] 在 `.agent-meta.yml` 中补充字段：对应 spec 路径（如 `spec/<date>-<scope>.md`）、主要平台列表（android/ios/web），便于后续统计和自动清理。
- [ ] 设计并实现 workspace 垃圾回收能力（例如 `agent-tool ws gc` 或扩展 `ws status`），支持发现「分支已合并且 N 天未更新」的 workspace，并提供交互式/非交互式批量 cleanup。

## dev 模块

- [ ] 实现 `agent-tool dev spec new <name>`：在当前仓根目录下创建基于 open spec 风格的 `spec/<date>-<name>.md`，模板字段包括背景、目标、非目标、风险、验收标准等。
- [ ] 实现 `agent-tool dev spec check`：在仓库中查找 `spec/*.md`，对必填字段（如目标、验收标准）做简单校验，并打印缺失项摘要。
- [ ] 实现 `agent-tool dev checklist`：输出一份约定好的开发流程 checklist（如「是否有 spec」「是否跑过 agent-tool test self」「是否更新 README/AGENTS」），供 AI 在 PR 前自检。
- [ ] 预留 `agent-tool dev checklist --ci` 模式，输出适合 CI 机读的结果（例如 JSON），便于在 CI 流水线中统一校验。

## test 模块 & 自动化测试

- [ ] 新增 `tests/` 目录，采用 bats 或纯 bash 脚本，为以下场景增加自动化测试：
  - `ws create` / `ws cleanup --force` / `ws list` / `ws status` 的基本流程（在临时 Git 仓库上运行，验证目录和 .agent-meta.yml 输出）。
  - `build` / `run` 的参数解析（在没有实际 gradlew/tuist 的情况下，只验证错误码和错误信息）。
  - `cfg` 子命令在未知 subcommand/缺少 subcommand 时的错误输出（包含 `E_SUBCOMMAND_UNKNOWN` / `E_ARG_MISSING`）。
- [ ] 为 `agent-tool test self` 增加对 shellcheck 的可选检测（如果系统存在 shellcheck，则对核心脚本运行一次，失败时输出 `E_TEST_SHELLCHECK` 前缀。

## doctor 模块

- [ ] 实现 `agent-tool doctor all` 子命令，聚合：
  - 当前仓库的 git 清洁度检查（类似 `git status --short`，在有改动时输出 `E_GIT_DIRTY` 提示）。
  - `doctor <platform>` 的平台依赖检查。
  - `cfg selftest` 的配置目录/软链检查结果。
  - 统一总结一段「下一步建议」（如先修复哪些错误再尝试 build）。

## 配置与可扩展性

- [ ] 在 README 中补充更多 `~/.agent-tool/config` 示例，包括：
  - 针对不同语言/项目类型设置不同的 `DEFAULT_BASE_BRANCH`（如 Android 用 `dev`, Web 用 `main`）。
  - 为特定仓库前缀设置自定义 `AGENT_ROOT`（例如单独挂载到更大磁盘）。
- [ ] 为 `AGENT_TOOL_CONFIG` 支持按项目覆盖策略（例如在当前仓根查找 `.agent-tool/config`，若存在则优先加载，以实现 per-repo 配置）。

## CI & PR 流程集成

- [ ] 在仓库中补充 CI 配置示例，演示如何只通过 `agent-tool.sh build/test/doctor` 完成构建与测试，确保本地命令与 CI 行为一致。
- [ ] 提供 PR 模板示例（或文档片段），要求在 PR 中列出：CTG/Issue 链接、变更摘要、实际执行过的 `agent-tool.sh` 命令，以及风险/回滚方式。
- [ ] 在文档中提供本地 Git hook 示例（如 `pre-push`），调用 `agent-tool.sh dev checklist` 或最小验证命令（`doctor cli` + 核心 `test`），帮助在推送前自动自检。

## 错误码与日志规范

- [x] 在 README 或单独文档中列出当前使用的错误码列表（`E_NOT_GIT_REPO` / `E_BUILD_CONFIG` / `E_ANDROID_*` 等），约定：
  - [x] 错误码的命名规则。
  - [x] 哪些错误属于“用户输入问题”、哪些属于“环境问题”、哪些属于“内部错误”。
- [ ] 将 doctor/cfg/install_symlinks 等脚本中的错误输出也逐步迁移到 `agent_error` 风格（保持同一前缀规范，方便 AI 统一解析）。

## 代码结构与复用

- [ ] 在 `cfg/index.sh` 中继续抽取复用工具函数（如带颜色的 log_info/log_warn/log_success），并在各模块中替换重复实现，统一日志格式。
- [ ] 为 ws/build/doctor 模块增加轻量级的「调试 verbose 模式」开关（例如读取 `AGENT_TOOL_DEBUG` 环境变量），控制额外的调试输出，不影响默认体验。

## 蓝湖命令自动化（后续）

- [ ] 基于当前 `lanhu-extract.md` 模板，设计并实现一个 `lanhu` 命令：
  - [ ] 在 `.claude/commands/lanhu.md` 中增加带 frontmatter 的命令定义，支持 `lanhu "<DDS_URL>"` 一键执行「导航 → 截图 → 复制代码 → 生成 Markdown」流程。
  - [ ] 截图逻辑改为通过 DDS 快照中第一个 `url` 含有 `merge_image/imgs` 的 `image` 节点截取纯设计图 PNG。
  - [ ] 规范中间文件路径为 `./{title}/temp/`，将快照/调试 txt 等全部放入该目录，并在命令结束时清理（`rm -rf "./{title}/temp/"`）。
  - [ ] 复制代码仍通过「点击复制按钮 + 等待 tooltip '复制成功' + pbpaste」实现，保持与现有蓝湖脚本风格一致。
