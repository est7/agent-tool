模块：test

用于集中放置与「项目级测试入口」相关的逻辑（即 `agent-tool test ...` 子命令实现），以及内部使用的 CLI 自检工具函数。

当前约定：
- `agent-tool test`：面向「当前项目代码」的测试（单元测试 / 覆盖率等），按平台分发到对应命令。
- `agent-tool doctor cli`：对 agent-tool 自身脚本做一次自检（bash -n），内部复用 `agent_tool_test_self`。

注意：
- 这里的 `test/` 是「功能模块」目录，用于统一封装各平台测试命令。
- 针对本仓库脚本的额外自动化测试（如 bats/shell 测试），仍建议统一放在根目录下的 `tests/` 中，
  遵循通用测试目录约定。
