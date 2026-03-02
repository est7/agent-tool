---
description: 智能分析代码，自动推荐最合适的审查角色和方法
argument-hint: <可选：文件或目录路径>
---

分析 `$ARGUMENTS` 指定的代码（默认当前目录），自动推荐审查角色和方法。

## 检测规则

### 文件类型 → 角色映射

| 文件特征 | 推荐角色 |
|----------|----------|
| `*.tsx`, `*.vue`, `*.css` | frontend |
| `Dockerfile`, `*.yaml`, `terraform/` | architect |
| `*_test.go`, `*.spec.ts` | qa |
| `auth/`, `jwt`, `crypto` | security |
| `**/api/**`, `handler`, `service` | backend |
| `android/`, `ios/`, `*.swift`, `*.kt` | mobile |
| 性能相关关键词 | performance |

### 复杂度判断

**单角色**: 文件类型单一、变更范围集中
**多角色**: 涉及 2+ 技术领域、有架构变更
**辩论模式**: 涉及 3+ 专业角色、存在权衡决策（使用 `analyzing-project-health` 的多角色辩论流程产出结论与路线图）

## 优先级排序

1. 🔴 安全问题
2. 🟠 关键错误
3. 🟡 架构问题
4. 🔵 性能问题
5. 🟢 UI/UX
6. ⚪ 测试质量

## 输出格式

```markdown
📁 分析: <路径>

检测到:
- <文件类型统计>

推荐:
- 审查模式: <单角色|多角色|辩论>
- 推荐角色: <role1>[, <role2>...]
- 若为“辩论”模式：按 `analyzing-project-health` 输出辩论结论与改进路线图（无需 `/role-debate`）

原因:
- <推荐理由>
```
