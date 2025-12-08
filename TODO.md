# TODO

## CLI & UX

- [ ] 为 `agent-tool help` 增加机器可解析输出模式（例如 `agent-tool help --json`），包含各 group 的子命令、参数和示例，便于 AI 自动生成调用。

## dev 模块

- [ ] 实现 `agent-tool dev spec new <name>`：在当前仓根目录下创建基于 open spec 风格的 `spec/<date>-<name>.md`，模板字段包括背景、目标、非目标、风险、验收标准等。
- [ ] 实现 `agent-tool dev spec check`：在仓库中查找 `spec/*.md`，对必填字段（如目标、验收标准）做简单校验，并打印缺失项摘要。
- [ ] 实现 `agent-tool dev checklist`：输出一份约定好的开发流程 checklist（如「是否有 spec」「是否跑过 agent-tool test self」「是否更新 README/AGENTS」），供 AI 在 PR 前自检。

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

## 错误码与日志规范

- [ ] 在 README 或单独文档中列出当前使用的错误码列表（`E_NOT_GIT_REPO` / `E_BUILD_CONFIG` / `E_ANDROID_*` 等），约定：
  - 错误码的命名规则。
  - 哪些错误属于“用户输入问题”、哪些属于“环境问题”、哪些属于“内部错误”。
- [ ] 将 doctor/cfg/install_symlinks 等脚本中的错误输出也逐步迁移到 `agent_error` 风格（保持同一前缀规范，方便 AI 统一解析）。

## 代码结构与复用

- [ ] 在 `cfg/index.sh` 中继续抽取复用工具函数（如带颜色的 log_info/log_warn/log_success），并在各模块中替换重复实现，统一日志格式。
- [ ] 为 ws/build/doctor 模块增加轻量级的「调试 verbose 模式」开关（例如读取 `AGENT_TOOL_DEBUG` 环境变量），控制额外的调试输出，不影响默认体验。
