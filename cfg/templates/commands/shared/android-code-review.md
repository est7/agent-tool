---
description: "对 Android/Kotlin 代码进行专业审查，检查状态管理、协程使用、架构分层等最佳实践"
argument-hint: "<可选：要审查的文件路径或关注点>"
allowed-tools:
  - Bash
---

# Android/Kotlin Code Reviewer

## Android 特定检查

### 1. 状态管理

**必须遵循单向数据流：**
```kotlin
// ✅ 正确: 单一可变源
private val _state = MutableStateFlow(UiState())
val state: StateFlow<UiState> = _state.asStateFlow()

// ❌ 错误: 多个可变源
var isLoading = mutableStateOf(false)
var data = mutableStateOf<List<Item>>(emptyList())
```

**Reducer 模式检查：**
```kotlin
// Action → Reducer → State + Effects
data class ReduceResult(val state: State, val effects: List<Effect>)
fun reduce(state: State, action: Action): ReduceResult
```

- [ ] StateFlow 是否为唯一可变源
- [ ] Reducer 是否为纯函数（无副作用）
- [ ] Effects 是否在 CoroutineScope 中执行
- [ ] UI 是否只订阅 StateFlow（不直接修改）

### 2. ViewModel 规范

- [ ] 是否使用 viewModelScope 管理协程
- [ ] 是否暴露不可变 StateFlow 给 UI
- [ ] 是否避免在 ViewModel 中持有 Context/View 引用
- [ ] 配置变更时状态是否正确保留

### 3. Coroutines 使用

```kotlin
// ✅ 结构化并发
viewModelScope.launch {
    withTimeout(30_000) {
        repository.fetchData()
    }
}

// ❌ 裸线程/非结构化
Thread { /* ... */ }.start()
GlobalScope.launch { /* ... */ }
```

- [ ] 是否使用结构化并发（viewModelScope/lifecycleScope）
- [ ] 外部调用是否设置 withTimeout
- [ ] 是否正确处理 CancellationException
- [ ] Dispatcher 选择是否合理（IO/Default/Main）

### 4. 依赖方向（Android 分层）

```
ui (Activity/Fragment/Compose)
    ↓
app (ViewModel/DI/Navigation)
    ↓
domain (UseCase/Entity - 纯 Kotlin，无 Android 依赖)
    ↑
data (Repository/DataSource/API)
```

- [ ] domain 层是否无 Android SDK 依赖
- [ ] Repository 是否只在 data 层实现
- [ ] UI 是否直接访问网络/数据库（禁止）

### 5. Kotlin 特定规范

**函数设计：**
- [ ] 参数 ≤ 5 个，超过用 data class 封装
- [ ] 使用 sealed class/interface 表达有限状态集
- [ ] 使用 Result<T> 或自定义 Either 表达可失败操作

**空安全：**
```kotlin
// ✅ 显式处理
user?.let { processUser(it) } ?: handleNull()

// ❌ 强制解包
user!!.name
```

- [ ] 是否避免 `!!` 强制解包
- [ ] nullable 类型是否有明确处理策略

**扩展函数：**
- [ ] 是否滥用扩展函数（应限于工具性转换）
- [ ] 扩展函数是否放在合适的作用域

### 6. 错误处理

```kotlin
// ✅ 使用 sealed class 表达领域错误
sealed class DomainError {
    data class Network(val code: Int): DomainError()
    data class Validation(val field: String): DomainError()
    object Unknown: DomainError()
}

// ✅ Repository 层转换错误
suspend fun fetchUser(): Result<User, DomainError>

// ❌ 异常穿透到 UI
throw NetworkException("...")
```

- [ ] 外部错误是否在 data 层转换为 sealed class
- [ ] 是否使用 Result/Either 而非异常
- [ ] 可重试错误是否携带幂等键

### 7. Android 组件生命周期

- [ ] Flow 收集是否在正确的生命周期范围
- [ ] 是否使用 repeatOnLifecycle 收集 Flow
- [ ] Fragment 中是否使用 viewLifecycleOwner

```kotlin
// ✅ 正确的 Flow 收集
viewLifecycleOwner.lifecycleScope.launch {
    viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
        viewModel.state.collect { /* ... */ }
    }
}
```

### 8. 复杂度阈值

- [ ] 单函数行数 ≤ 40
- [ ] 圈复杂度 ≤ 10
- [ ] 文件行数 ≤ 400
- [ ] 类行数 ≤ 500

### 9. Android 反模式

- [ ] **神 Activity/Fragment**: 业务逻辑堆积在 UI 组件
- [ ] **Context 泄漏**: ViewModel/Singleton 持有 Activity Context
- [ ] **硬编码资源**: 字符串/尺寸直接写在代码中
- [ ] **同步主线程 IO**: 在主线程执行网络/数据库操作
- [ ] **过度使用 LiveData**: 应迁移到 StateFlow

## 代码风格

- Lint: ktlint, detekt
- 命名: camelCase (函数/变量), PascalCase (类/接口)
- 常量: SCREAMING_SNAKE_CASE

## 审查输出格式

```markdown
## Android Code Review: {file_name}

### 评估: [Good/Needs Improvement/Major Issues]

### Critical
- [ ] {issue} @ line {n} - {reason}

### Warning
- [ ] {issue} @ line {n} - {reason}

### Suggestion
- [ ] {issue} @ line {n} - {reason}

### 亮点
- {good_practice}
```
