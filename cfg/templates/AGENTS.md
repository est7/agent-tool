# AGENTS.md

## 我是谁（Who I am）
- 在这里描述你的背景（例如：Android/Kotlin 高级、iOS/Swift 入门、Web/Golang/Rust 爱好者等）

## 全局编码原则（Global coding principles）
- 示例：
  - 正确性 > 可维护性 > 性能 > 简洁
  - Kotlin：使用协程 + Flow，避免过时框架 —— 在这里写清楚
  - Swift：首选 Swift Concurrency，避免遗留 Rx 等
- 写清楚你希望 AI 遵守的「底线规则」

## 工作流默认约定（Workflow defaults）
- 示例：
  - 修改代码前先给方案，再给最小 diff
  - 所有改动都要附带测试思路 / 验证步骤
  - 不要在未经确认的情况下执行破坏性 shell 命令

## 工具与环境（Tools）
- 示例：
  - 主力 IDE：Android Studio / IntelliJ / VS Code
  - 构建工具：Android 使用 Gradle，Web 使用 pnpm，等等
- 这里主要是帮助各个 Agent 理解你真实的开发环境

