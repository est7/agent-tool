---
description: "分析代码设计模式使用情况，检查 SOLID 原则，识别反模式"
argument-hint: "<可选：文件或目录路径>"
---

# 设计模式分析 (Design Patterns)

分析代码的设计模式使用情况，评估 SOLID 原则遵循度，识别反模式并提供重构建议。

## 使用方式

```
/design-patterns                     # 分析当前目录
/design-patterns src/services/       # 分析指定目录
/design-patterns src/payment.ts      # 分析指定文件
```

## 分析维度

### 1. 设计模式识别

#### 创建型模式 (Creational)
| 模式 | 用途 | 识别特征 |
|------|------|----------|
| **Factory** | 对象创建解耦 | `createXxx()`, 返回接口类型 |
| **Builder** | 复杂对象构建 | 链式调用, `.build()` |
| **Singleton** | 全局唯一实例 | `getInstance()`, 私有构造 |
| **Prototype** | 克隆创建 | `clone()`, 深拷贝实现 |

#### 结构型模式 (Structural)
| 模式 | 用途 | 识别特征 |
|------|------|----------|
| **Adapter** | 接口转换 | 包装不兼容接口 |
| **Decorator** | 动态扩展 | 实现相同接口，包装原对象 |
| **Facade** | 简化接口 | 统一多个子系统调用 |
| **Proxy** | 访问控制 | 延迟加载、权限控制 |

#### 行为型模式 (Behavioral)
| 模式 | 用途 | 识别特征 |
|------|------|----------|
| **Observer** | 事件通知 | `subscribe/publish`, 回调列表 |
| **Strategy** | 算法替换 | 接口 + 多实现，运行时切换 |
| **Command** | 操作封装 | `execute()`, 可撤销 |
| **Iterator** | 遍历抽象 | `next()`, `hasNext()` |

### 2. SOLID 原则检查

每项 0-20 分，总分 100：

| 原则 | 含义 | 检查点 |
|------|------|--------|
| **S** - 单一职责 | 一个类只有一个变化原因 | 类行数、方法数、依赖数 |
| **O** - 开闭原则 | 对扩展开放，对修改关闭 | switch/if-else 分支、硬编码 |
| **L** - 里氏替换 | 子类可替换父类 | 覆写行为一致性 |
| **I** - 接口隔离 | 不依赖不需要的接口 | 接口方法数、空实现 |
| **D** - 依赖倒置 | 依赖抽象而非具体 | 构造函数参数类型 |

**评分标准**：
- 90-100: 优秀
- 70-89: 良好
- 50-69: 需要改进
- <50: 需要重构

### 3. 反模式检测

| 反模式 | 症状 | 风险 |
|--------|------|------|
| **God Object** | 单类 >500 行，>20 方法 | 难维护、难测试 |
| **Spaghetti Code** | 高圈复杂度，深嵌套 | 难理解、易出错 |
| **Copy-Paste** | 重复代码块 >10 行 | 改一处漏多处 |
| **Magic Numbers** | 未命名常量 | 含义不明、难修改 |
| **Callback Hell** | 嵌套回调 >3 层 | 难追踪、难调试 |
| **Premature Optimization** | 无度量的复杂优化 | 增加复杂度无收益 |

## 输出格式

```markdown
## 设计模式分析: {target}

### 概览
- **SOLID 评分**: 75/100
- **已识别模式**: 3 个
- **反模式警告**: 2 个

### SOLID 评估
| 原则 | 得分 | 说明 |
|------|------|------|
| S | 18/20 | UserService 职责略多 |
| O | 12/20 | PaymentHandler 有 switch 分支 |
| L | 20/20 | 继承关系合理 |
| I | 15/20 | IRepository 方法过多 |
| D | 10/20 | 直接依赖具体类 |

### 已识别模式
1. **Factory** @ `src/factory/`
   - 使用合理 ✅

2. **Singleton** @ `src/config.ts`
   - ⚠️ 建议改用依赖注入

### 反模式警告
1. **God Object** @ `src/services/UserService.ts`
   - 行数: 650
   - 方法: 28
   - 建议: 拆分为 UserAuthService, UserProfileService

2. **Magic Numbers** @ `src/utils/calc.ts:45`
   - `if (status === 3)`
   - 建议: 使用枚举 `Status.COMPLETED`

### 重构建议

#### 高优先级
1. **PaymentHandler → Strategy 模式**
   ```typescript
   // Before: switch-case
   switch (type) {
     case 'credit': ...
     case 'paypal': ...
   }

   // After: Strategy
   interface PaymentStrategy {
     pay(amount: number): Promise<Result>
   }

   class CreditPayment implements PaymentStrategy { ... }
   class PaypalPayment implements PaymentStrategy { ... }
   ```

#### 中优先级
2. **UserService 拆分**
   - 提取认证逻辑 → UserAuthService
   - 提取资料管理 → UserProfileService
```

## 使用原则

1. **解决实际问题** - 不为模式而模式
2. **渐进式引入** - 一次只加一个模式
3. **度量优先** - 重构前后对比指标
4. **团队共识** - 确保团队理解所用模式
