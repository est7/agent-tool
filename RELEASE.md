# agent-tool 发布流程

本文档描述 agent-tool 的版本发布流程，供 Claude Code 执行自动化发布使用。

## 仓库信息

| 项目 | 路径 | GitHub |
|------|------|--------|
| 源码仓库 | `/Users/est8/scripts/agent-tool` | `https://github.com/est7/agent-tool` |
| Homebrew tap | `/Users/est8/scripts/homebrew-agent-tool` | `https://github.com/est7/homebrew-agent-tool` |

## 发布步骤

### 1. 提交源码仓库变更

```bash
cd /Users/est8/scripts/agent-tool
git add -A
git commit -m "<commit message>"
git push
```

### 2. 创建并推送 tag

```bash
git tag v<VERSION>
git push origin v<VERSION>
```

### 3. 下载压缩包并计算 SHA256

```bash
cd /Users/est8/scripts/homebrew-agent-tool
curl -L -o agent-tool-v<VERSION>.tar.gz https://github.com/est7/agent-tool/archive/refs/tags/v<VERSION>.tar.gz
shasum -a 256 agent-tool-v<VERSION>.tar.gz
```

### 4. 更新 Homebrew Formula

编辑 `/Users/est8/scripts/homebrew-agent-tool/Formula/agent-tool.rb`：

- 更新 `url` 为新版本：`https://github.com/est7/agent-tool/archive/refs/tags/v<VERSION>.tar.gz`
- 更新 `sha256` 为计算得到的哈希值

### 5. 提交并推送 Homebrew tap

```bash
cd /Users/est8/scripts/homebrew-agent-tool
git add Formula/agent-tool.rb
git commit -m "chore: bump agent-tool to v<VERSION>"
git push
```

## 快速指令

发布新版本时，只需告诉 Claude：

```
发布 agent-tool v<VERSION>
```

或者如果有未提交的变更：

```
提交当前变更并发布 agent-tool v<VERSION>
```

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v0.8.0 | 2025-12-10 | 修复 1mcp 安装目录和 gemini httpUrl 配置 |
| v0.7.0 | 2025-12-10 | 将 exa-mcp 替换为 context7，重构 mcp.json 配置 |
| v0.6.0 | - | 初始 Homebrew 发布版本 |
