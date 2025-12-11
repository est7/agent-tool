# Web Rules — Web/TypeScript 开发规范

---

## 1. TypeScript 代码风格

### 1.1 命名约定

- **类/接口/类型**: `PascalCase`（如 `UserService`、`LoginProps`）
- **函数/变量**: `camelCase`（如 `getUserById`、`isLoading`）
- **常量**: `UPPER_SNAKE_CASE` 或 `camelCase`（根据场景）
- **文件名**: `kebab-case.ts` 或 `PascalCase.tsx`（组件）

### 1.2 类型规范

- 开启所有 strict 选项
- 优先使用 `interface` 定义对象形状，`type` 用于联合/交叉类型
- 避免 `any`，使用 `unknown` + 类型守卫
- 导出类型时使用 `export type`

### 1.3 模块规范

- 使用 ES 模块语法（`import/export`），**禁用** CommonJS（`require`）
- 尽可能解构导入：`import { foo } from 'bar'`
- 优先 `const`，必要时 `let`，**禁用** `var`

---

## 2. 架构规范

### 2.1 项目结构

```
src/
├── components/     # 可复用 UI 组件
├── pages/          # 页面组件（路由入口）
├── hooks/          # 自定义 Hooks
├── services/       # API 调用、业务服务
├── stores/         # 状态管理（Zustand/Redux）
├── types/          # 类型定义
└── utils/          # 工具函数
```

### 2.2 组件规范

- 一个文件一个组件
- Props 使用 interface 定义，命名为 `ComponentNameProps`
- 避免在组件内定义组件（提取到外部）

---

## 3. React 规范

### 3.1 函数组件

```tsx
// 推荐写法
interface UserCardProps {
  user: User;
  onSelect?: (id: string) => void;
}

export function UserCard({ user, onSelect }: UserCardProps) {
  return (
    <div onClick={() => onSelect?.(user.id)}>
      {user.name}
    </div>
  );
}
```

### 3.2 Hooks 规范

- 自定义 Hook 以 `use` 开头
- 遵循 Rules of Hooks（顶层调用、条件外调用）
- 依赖数组完整，使用 ESLint 插件检查

### 3.3 状态管理

- 简单状态：`useState` / `useReducer`
- 跨组件共享：Context / Zustand / Redux Toolkit
- 服务端状态：TanStack Query / SWR

---

## 4. Vue 规范（如使用）

### 4.1 组件规范

- 使用 `<script setup>` 语法
- Props 使用 `defineProps<T>()` 类型定义
- Emits 使用 `defineEmits<T>()`

### 4.2 Composition API

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'

interface Props {
  title: string
}

const props = defineProps<Props>()
const count = ref(0)
const doubled = computed(() => count.value * 2)
</script>
```

---

## 5. 异步编程

### 5.1 async/await

- 优先使用 `async/await`，避免回调地狱
- 错误处理使用 `try/catch` 或 `.catch()`
- 并行请求使用 `Promise.all()` 或 `Promise.allSettled()`

### 5.2 API 调用

```typescript
// 推荐：封装 API 服务
export async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) {
    throw new ApiError(response.status, await response.text());
  }
  return response.json();
}
```

---

## 6. 构建与测试

### 6.1 包管理

- 优先使用 **pnpm**，其次 npm
- 锁定依赖版本（`pnpm-lock.yaml` / `package-lock.json`）
- 定期更新依赖，检查安全漏洞

### 6.2 测试规范

- 单元测试：Vitest / Jest
- 组件测试：Testing Library
- E2E 测试：Playwright / Cypress
- 测试命名：`describe('Component')` + `it('should ...')`

### 6.3 常用命令

```bash
# 开发
pnpm dev

# 构建
pnpm build

# 测试
pnpm test

# Lint
pnpm lint

# 类型检查
pnpm typecheck
```

---

## 7. 代码质量

### 7.1 Lint & Format

- ESLint + Prettier
- 提交前自动格式化（lint-staged + husky）
- 开启 TypeScript 严格模式

### 7.2 性能优化

- 避免不必要的 re-render（memo、useMemo、useCallback）
- 图片懒加载，代码分割
- 使用 React DevTools / Vue DevTools 分析性能
