# Backend Rules — 后端开发规范 (Python/Go/Rust)

---

## 1. Python 规范

### 1.1 代码风格

- 遵循 **PEP 8**
- 使用 **type hints**（Python 3.10+ 语法）
- 优先使用 **pathlib** 处理路径
- 字符串格式化使用 f-string

### 1.2 命名约定

- **类名**: `PascalCase`
- **函数/变量**: `snake_case`
- **常量**: `UPPER_SNAKE_CASE`
- **私有成员**: `_leading_underscore`

### 1.3 项目结构

```
src/
├── api/            # API 路由
├── services/       # 业务逻辑
├── repositories/   # 数据访问
├── models/         # 数据模型
└── utils/          # 工具函数
```

### 1.4 异步编程

```python
# 推荐：async/await
async def fetch_user(user_id: str) -> User:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"/users/{user_id}")
        return User.model_validate(response.json())
```

### 1.5 依赖管理

- 使用 **uv** 或 **pip** + `requirements.txt`
- 虚拟环境：`venv` 或 `uv venv`
- 类型检查：mypy / pyright

### 1.6 常用命令

```bash
# 运行
uv run python main.py

# 测试
uv run pytest tests/

# Lint
uv run ruff check .

# 格式化
uv run ruff format .
```

---

## 2. Go 规范

### 2.1 代码风格

- 遵循 **Effective Go** 和官方风格指南
- 使用 `gofmt` / `goimports` 格式化
- 注释以被注释对象名称开头

### 2.2 命名约定

- **导出标识符**: `PascalCase`（首字母大写）
- **非导出标识符**: `camelCase`（首字母小写）
- **包名**: 小写单词，不使用下划线
- **接口**: 单方法接口使用 `-er` 后缀（如 `Reader`、`Writer`）

### 2.3 项目结构

```
cmd/
└── myapp/          # 主程序入口
internal/
├── api/            # API 处理器
├── service/        # 业务逻辑
├── repository/     # 数据访问
└── model/          # 数据模型
pkg/                # 可导出的公共包
```

### 2.4 错误处理

```go
// 推荐：显式错误处理
func GetUser(id string) (*User, error) {
    user, err := repo.FindByID(id)
    if err != nil {
        return nil, fmt.Errorf("get user %s: %w", id, err)
    }
    return user, nil
}
```

### 2.5 并发

- 使用 goroutine + channel 进行并发
- 使用 `context.Context` 传递取消信号和超时
- 避免共享内存，优先通过 channel 通信

### 2.6 常用命令

```bash
# 运行
go run ./cmd/myapp

# 构建
go build -o bin/myapp ./cmd/myapp

# 测试
go test ./...

# Lint
golangci-lint run
```

---

## 3. Rust 规范

### 3.1 代码风格

- 使用 `cargo fmt` 格式化
- 使用 `cargo clippy` 检查代码质量
- 遵循 Rust API Guidelines

### 3.2 命名约定

- **类型/Trait**: `PascalCase`
- **函数/变量**: `snake_case`
- **常量**: `UPPER_SNAKE_CASE`
- **模块**: `snake_case`

### 3.3 项目结构

```
src/
├── main.rs         # 二进制入口
├── lib.rs          # 库入口
├── api/            # API 模块
├── service/        # 业务逻辑
├── repository/     # 数据访问
└── model/          # 数据模型
```

### 3.4 错误处理

```rust
// 推荐：使用 Result + thiserror/anyhow
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("user not found: {0}")]
    UserNotFound(String),
    #[error("database error")]
    Database(#[from] sqlx::Error),
}

pub async fn get_user(id: &str) -> Result<User, AppError> {
    // ...
}
```

### 3.5 异步编程

- 使用 **tokio** 运行时
- 优先使用 `async/await` 语法
- 避免阻塞异步运行时（使用 `spawn_blocking`）

### 3.6 常用命令

```bash
# 运行
cargo run

# 构建（release）
cargo build --release

# 测试
cargo test

# Lint
cargo clippy

# 格式化
cargo fmt
```

---

## 4. 通用后端规范

### 4.1 API 设计

- RESTful 风格或 gRPC
- 使用标准 HTTP 状态码
- 统一错误响应格式
- API 版本化（`/api/v1/`）

### 4.2 日志规范

- 结构化日志（JSON 格式）
- 日志级别：DEBUG < INFO < WARN < ERROR
- 包含请求 ID、时间戳、调用链信息

### 4.3 配置管理

- 环境变量 + 配置文件
- 敏感信息不写入代码或配置文件
- 支持多环境（dev/staging/prod）

### 4.4 数据库

- 使用 ORM 或 Query Builder
- 数据库迁移版本化管理
- 连接池配置合理

### 4.5 测试

- 单元测试覆盖核心逻辑
- 集成测试使用测试数据库
- Mock 外部依赖
