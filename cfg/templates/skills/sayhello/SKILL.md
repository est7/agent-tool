---
name: sayhello
description: 用于验证 skills 管线是否可用的最小示例。当用户要求测试 Skill 是否工作时使用此 skill。
allowed-tools:
  - Bash(~/.claude/skills/sayhello/scripts/run.sh:*)
metadata:
  category: demo
---

# 用途

该 Skill 仅用于验证「Agent Skills Spec」与本仓统一的 skills 管线是否工作正常。

# 使用方法

1. 使用 Bash 工具执行脚本（使用绝对路径）：
   ```bash
   ~/.claude/skills/sayhello/scripts/run.sh
   ```

2. 可选：传入自定义名称参数：
   ```bash
   ~/.claude/skills/sayhello/scripts/run.sh "YourName"
   ```

3. 返回脚本输出，并告知用户 Skill 已成功加载并执行。

# 注意事项

- 仅在用户显式要求测试 Skill 管线时使用
- 除了演示用途，不要在真实项目中依赖本 Skill 实现业务逻辑
