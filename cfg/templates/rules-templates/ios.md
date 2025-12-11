# iOS Rules — iOS/Swift 开发规范

---

## 1. Swift 代码风格

### 1.1 命名约定

- **类型名**: `PascalCase`（如 `UserRepository`、`LoginViewModel`）
- **函数/变量**: `camelCase`（如 `getUserById`、`isLoading`）
- **常量**: `camelCase` 或 `PascalCase`（遵循 Apple 惯例）
- **协议**: 名词或 `-able`/`-ible` 后缀（如 `Codable`、`DataSource`）

### 1.2 代码组织

- 使用 `// MARK: -` 分隔代码区域
- 扩展放在独立文件或使用 `extension` 分组
- 遵循 `public` > `internal` > `private` 的声明顺序

### 1.3 可选值处理

- 优先使用 `guard let` 提前返回
- 避免强制解包 `!`，除非确定非空
- 使用 `??` 提供默认值

---

## 2. 架构规范

### 2.1 MVVM + Coordinator

```
App/
├── Models/         # 数据模型
├── Views/          # SwiftUI Views / UIKit Views
├── ViewModels/     # 业务逻辑、状态管理
├── Services/       # 网络、存储等服务
└── Coordinators/   # 导航逻辑
```

### 2.2 ViewModel 规范

- 使用 `@Published` 暴露状态
- 实现 `ObservableObject` 协议
- 避免在 ViewModel 中持有 View 引用

### 2.3 依赖注入

- 使用构造器注入
- 可选：使用 `@EnvironmentObject` 或依赖注入框架

---

## 3. 异步编程

### 3.1 Swift Concurrency

```swift
// 推荐：async/await
func fetchUser() async throws -> User {
    let data = try await networkService.fetch(url)
    return try JSONDecoder().decode(User.self, from: data)
}

// 在 View 中使用
.task {
    await viewModel.loadData()
}
```

### 3.2 Combine（如需兼容旧版本）

- 使用 `@Published` + `sink` 订阅
- 在 `deinit` 中取消订阅（`cancellables`）
- 优先使用 `async/await` 替代复杂的 Combine 链

---

## 4. SwiftUI

### 4.1 View 规范

- View 保持轻量，逻辑放在 ViewModel
- 使用 `@State` 管理本地状态
- 使用 `@StateObject` 管理 ViewModel 生命周期
- 使用 `@ObservedObject` 接收外部传入的 ViewModel

### 4.2 状态管理

```swift
// 推荐：状态提升
struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        // ...
    }
}

// ViewModel
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
}
```

### 4.3 Preview

- 为每个 View 提供 Preview
- 使用 Mock 数据展示不同状态

---

## 5. UIKit（如需）

### 5.1 规范

- 使用 Auto Layout（代码或 Storyboard）
- 优先使用 `UICollectionView` + `DiffableDataSource`
- 避免 Massive View Controller，使用 Child VC 或 Coordinator

---

## 6. 构建与测试

### 6.1 项目配置

- 使用 **Swift Package Manager** 管理依赖
- 多 Target 项目使用 xcconfig 管理配置
- 启用 Strict Concurrency Checking

### 6.2 测试规范

- 单元测试：XCTest，Mock 使用协议 + 手写 Mock
- UI 测试：XCUITest
- 测试命名：`test_methodName_condition_expectedResult`

### 6.3 常用命令

```bash
# 构建
xcodebuild -scheme MyApp -configuration Debug build

# 测试
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' test

# Swift Package
swift build
swift test
```

---

## 7. 资源管理

- 使用 Asset Catalog 管理图片和颜色
- 字符串本地化使用 `String(localized:)`
- SF Symbols 优先于自定义图标
