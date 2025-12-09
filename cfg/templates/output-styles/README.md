# output-styles 模板目录

这个目录用于存放「输出风格（output styles）」的模板文件，方便在不同机器或新环境下复用：

- 实际生效的路径是 `$AGENT_HOME/output-styles/`（由 `cfg/install_symlinks.sh` 初始化目录结构）。
- Claude Desktop / Claude Web 会从 `~/.claude/output-styles/` 读取输出风格配置，本仓库通过软链把它指向 `$AGENT_HOME/output-styles/`。

推荐约定（可按个人习惯调整）：

- `output-styles/shared/`：通用输出风格，Claude / Codex 等都可以复用。
- `output-styles/claude-only/`：仅 Claude 使用的输出风格。

在这里维护你常用的输出风格文件，然后手动或通过脚本同步到 `$AGENT_HOME/output-styles/`。后续如果需要，也可以在 `install_symlinks.sh` 中增加从本目录复制示例样式的逻辑。+
