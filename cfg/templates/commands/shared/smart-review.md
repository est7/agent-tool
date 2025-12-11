---
description: "智能分析代码，自动推荐最合适的审查角色和方法"
argument-hint: "<可选：文件或目录路径>"
---

# 智能审查 (Smart Review)

自动分析代码特征，推荐最合适的审查角色和方法。

## 使用方式

```
/smart-review                    # 分析当前目录
/smart-review src/auth/          # 分析指定目录
/smart-review api/handler.go     # 分析指定文件
```

## 智能检测规则

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

**单角色场景**:
- 文件类型单一
- 变更范围集中
- 无跨领域影响

**多角色场景**:
- 涉及 2+ 技术领域
- 有架构层面变更
- 存在权衡决策

**辩论模式**:
- 涉及 3+ 专业角色
- 安全与性能权衡
- 重大架构变更
- 跨平台影响

## 优先级排序

1. 🔴 **安全问题** - 认证、加密、权限
2. 🟠 **关键错误** - 系统崩溃、数据丢失
3. 🟡 **架构问题** - 大规模重构、依赖变更
4. 🔵 **性能问题** - 用户体验影响
5. 🟢 **UI/UX** - 界面和交互
6. ⚪ **测试质量** - 覆盖率和可靠性

## 输出示例

### 场景1: 单一领域
```
📁 分析: src/components/

检测到:
- 12 个 React 组件 (.tsx)
- 3 个样式文件 (.css)
- 2 个测试文件 (.spec.tsx)

✅ 推荐: /role frontend
   - 组件结构审查
   - 可访问性检查
   - 状态管理评估
```

### 场景2: 多角色
```
📁 分析: src/auth/

检测到:
- JWT 认证实现
- 数据库操作
- API 端点

⚠️ 建议多角色审查:

[1] /role security
    - 认证流程安全性
    - Token 处理规范

[2] /role backend
    - API 设计合理性
    - 错误处理完整性

[3] /role-debate security,backend
    - 安全性 vs 易用性权衡
```

### 场景3: 建议辩论
```
📁 分析: src/core/

检测到:
- 核心架构变更
- 影响 mobile + web + backend
- 涉及性能和安全权衡

🔶 建议: /role-debate architect,security,performance

原因:
- 3+ 专业角色相关
- 存在明显权衡点
- 架构决策影响深远
```

## 分析维度

### 代码特征扫描
- 文件扩展名和路径模式
- 导入依赖分析
- 关键词识别（auth, cache, db 等）

### 变更影响评估
- 变更文件数量
- 影响模块范围
- 是否触及核心逻辑

### 风险识别
- 安全敏感操作
- 性能关键路径
- 外部依赖变更
