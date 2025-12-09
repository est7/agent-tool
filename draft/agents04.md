项目配置 (CLAUDE.md) - 项目级的配置文件
项目结构化 MD 样例：

# 项目指导文件

## 项目架构

## 项目技术栈

## 项目模块划分
### 文件与文件夹布局

## 项目业务模块

## 项目代码风格与规范
### 命名约定(类命名、变量命名)
### 代码风格
#### Import 规则
#### 依赖注入
#### 日志规范
#### 异常处理
#### 参数校验
#### 其他一些规范

## 测试与质量
### 单元测试
### 集成测试

## 项目构建、测试与运行
### 环境与配置

## Git 工作流程

## 文档目录(重要)
### 文档存储规范


以我们只保留影响核心链路：输入 → 思考 → 输出 的关键 MCP 服务，我选取的是：

mcp-server-fetch - 搜索能力
context7 - 搜索能力
sequential-thinking - 深度思考能力
server-memory - 记忆能力
serena - 大型代码库搜索与修改能力(看个人取舍，serena 要启动一个后台 java 进程，可能会过多占用内存，特别是大型项目)
codex-cli - 输出能力
其他一些特殊场景如需要前后端同时开发，可以加入 chrome-dev-tools、playwright 等交互式的 MCP 服务，但不要一次性全部添加

并且在全局配置的中编写好各个 MCP 服务的触发时机，当然也可以在单次 prompts 中指定使用

在 ~/.claude.json 中保留：

```
"mcpServers": {
    "Serena": {
      "args": [
        "--from",
        "git+https://github.com/oraios/serena",
        "serena",
        "start-mcp-server",
        "--context",
        "ide-assistant"
      ],
      "command": "uvx",
      "type": "stdio"
    },
    "codex-cli": {
      "args": [
        "-y",
        "@cexll/codex-mcp-server"
      ],
      "command": "npx",
      "type": "stdio"
    },
    "context7": {
      "args": [
        "-y",
        "@upstash/context7-mcp"
      ],
      "command": "npx",
      "type": "stdio"
    },
    "fetch": {
      "args": [
        "mcp-server-fetch"
      ],
      "command": "uvx",
      "type": "stdio"
    },
    "memory": {
      "args": [
        "-y",
        "@modelcontextprotocol/server-memory"
      ],
      "command": "npx",
      "type": "stdio"
    },
    "sequential-thinking": {
      "args": [
        "-y",
        "@modelcontextprotocol/server-sequential-thinking"
      ],
      "command": "npx",
      "type": "stdio"
    }
  }
```
