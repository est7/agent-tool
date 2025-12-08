模块：build

用于平台构建/运行相关子脚本的集中存放位置。

当前实现：
- `build/platforms.sh`：
  - `maybe_fill_build_args_from_config`：读取 `.agent-build.yml`，为各平台补全默认参数。
  - `build_agent_project`：根据 `BUILD_PLATFORM` 分发到具体平台构建函数。
  - `build_android_project` / `build_ios_project` / `build_web_project`：
    对应 Android / iOS(Tuist) / Web 的具体构建与运行逻辑。

这些函数由根脚本 `agent-tool.sh` 加载，并在 `build` / `run` 子命令中调用。

扩展建议：
- 如需拆分更细的构建逻辑（例如不同 Web framework、自定义打包脚本），可以在本目录新增脚本，
  由 `platforms.sh` 统一加载和分发。
