模块：ws（workspace）

用于任务工作区的创建/清理/列表/状态等功能。

当前实现：
- `ws/workspace.sh`：提供 `create_agent_repo` / `cleanup_agent_repo` / `list_agents` / `status_agents` 等函数，
  由根脚本 `agent-tool.sh` 加载并在 `create` / `cleanup` / `list` / `status` 子命令中调用。

扩展建议：
- 如需拆分更细的 workspace 子逻辑（例如不同类型任务的元信息管理），可以在本目录新增更多脚本，
  并在 `workspace.sh` 中统一加载。
