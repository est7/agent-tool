# Android Rules — Android/Kotlin 开发规范

---

## 1. Kotlin 代码风格

### 1.1 命名约定

- **类名**: `PascalCase`（如 `UserRepository`、`LoginViewModel`）
- **函数/变量**: `camelCase`（如 `getUserById`、`isLoading`）
- **常量**: `UPPER_SNAKE_CASE`（如 `MAX_RETRY_COUNT`）
- **包名**: 全小写，使用点分隔（如 `com.example.feature.login`）

### 1.2 代码组织

- 使用 `internal` 限制模块可见性
- 优先使用 `data class` 表示数据模型
- 使用 `sealed class/interface` 表示有限状态集
- 扩展函数放在独立的 `Extensions.kt` 文件中

### 1.3 空安全

- 优先使用非空类型，避免 `!!` 操作符
- 使用 `?.let { }` 或 `?: return` 处理可空值
- 平台类型（Java 互操作）显式标注可空性

---

## 2. 架构规范

### 2.1 MVVM + Clean Architecture

```
app/
├── data/           # 数据层：Repository 实现、数据源
├── domain/         # 领域层：Use Case、领域模型
├── presentation/   # 表现层：ViewModel、UI 状态
└── ui/             # UI 层：Composable/Fragment/Activity
```

### 2.2 ViewModel 规范

- ViewModel 中**不持有** Context、View 或 Activity 引用
- 使用 `StateFlow` 暴露 UI 状态，`SharedFlow` 处理一次性事件
- 通过 `SavedStateHandle` 处理进程恢复

### 2.3 依赖注入

- 优先使用 **constructor injection**
- 使用 Hilt/Dagger 管理依赖图
- 避免 `@Inject lateinit var` 字段注入

---

## 3. 异步编程

### 3.1 协程规范

- 使用 `viewModelScope` / `lifecycleScope` 管理协程生命周期
- IO 操作使用 `Dispatchers.IO`，CPU 密集型使用 `Dispatchers.Default`
- 避免在协程中使用 `GlobalScope`

### 3.2 Flow 规范

- 使用 `StateFlow` 表示状态，`SharedFlow` 表示事件
- 在 ViewModel 中使用 `stateIn()` 转换冷流为热流
- UI 层使用 `collectAsStateWithLifecycle()` 收集

---

## 4. Jetpack Compose

### 4.1 Composable 规范

- Composable 函数名使用 `PascalCase`
- 无状态 Composable 优先（状态提升）
- 使用 `remember` 缓存计算结果，`rememberSaveable` 保存配置变更

### 4.2 状态管理

```kotlin
// 推荐：状态提升
@Composable
fun LoginScreen(
    state: LoginUiState,
    onEvent: (LoginEvent) -> Unit
)

// 避免：内部状态过多
@Composable
fun LoginScreen(viewModel: LoginViewModel)
```

---

## 5. 构建与测试

### 5.1 Gradle 配置

- 使用 **Kotlin DSL** (`build.gradle.kts`)
- 版本目录 `libs.versions.toml` 管理依赖版本
- 启用 `buildConfig` 和 `compose` 仅在需要时

### 5.2 测试规范

- 单元测试：`src/test/`，使用 JUnit 5 + MockK
- UI 测试：`src/androidTest/`，使用 Compose Testing
- 测试命名：`methodName_condition_expectedResult`

### 5.3 常用命令

```bash
# 构建
./gradlew assembleDebug

# 测试
./gradlew testDebugUnitTest

# Lint 检查
./gradlew lintDebug

# 安装到设备
./gradlew installDebug
```

---

## 6. 资源管理

- 字符串放在 `strings.xml`，支持多语言
- 颜色/尺寸使用 Material Theme tokens
- 图片优先使用 Vector Drawable 或 Coil 加载网络图
