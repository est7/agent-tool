---
name: sayhello
description: 用于验证 skills 管线是否可用的最小示例。
metadata:
  category: demo
  example-trigger: "用户要求测试 Skill 管线或运行 scripts/run.sh"
---

该 Skill 仅用于验证「Agent Skills Spec」与本仓统一的 skills 管线是否工作正常。

使用建议：

- 当用户显式提到 `sayhello` Skill 或要求「测试 Skill 是否可用」时再启用本 Skill。
- 使用 shell 工具调用 `scripts/run.sh`（例如：`bash scripts/run.sh` 或 `./scripts/run.sh`），以验证脚本执行链路是否正常。
- 返回run.sh的输出,并且告知 Skill 已成功加载并成功执行 `scripts/run.sh`。
- 除了演示用途，不要在真实项目中依赖本 Skill 实现业务逻辑。
