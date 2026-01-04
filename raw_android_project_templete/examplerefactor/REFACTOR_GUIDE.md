# 分页架构重构指南（v2 - 松耦合版本）

本文档详细对比 `example` 与 `examplerefactor` 目录的代码差异，逐段分析每个优化点。

---

## 目录

1. [核心设计变化](#1-核心设计变化)
2. [PagingData vs PagingUiState](#2-pagingdata-vs-paginguistate)
3. [ViewModel 职责分离](#3-viewmodel-职责分离)
4. [Fragment 双流观察](#4-fragment-双流观察)
5. [扩展函数封装](#5-扩展函数封装)
6. [复杂场景支持](#6-复杂场景支持)
7. [迁移指南](#7-迁移指南)

---

## 1. 核心设计变化

### 1.1 问题：紧耦合的 PagingUiState

原设计将**页面状态**和**分页数据**绑定在一起``：

```kotlin
sealed class PagingUiState<out T> {
    data object Loading : PagingUiState<Nothing>()      // 页面状态
    data object Empty : PagingUiState<Nothing>()        // 页面状态
    data class Error(...) : PagingUiState<Nothing>()    // 页面状态
    data class Success<T>(                              // 页面状态 + 分页数据
        val items: List<T>,
        val loadState: LoadState,
        val page: Int
    ) : PagingUiState<T>()
}
```

**问题场景**：页面需要请求多个接口（如用户信息 + 分页列表）

```
页面状态 = f(用户信息状态, 分页列表状态, 其他状态...)
```

此时 `PagingUiState` 无法直接使用，需要额外 combine 逻辑。

### 1.2 解决方案：分离两个概念

| 概念 | 类 | 职责 |
|------|-----|------|
| 分页数据 | `PagingData<T>` | items + loadState + page |
| 页面状态 | `PageState` | Loading / Empty / Error / Success |

**关系**：
```
页面状态 = ViewModel.combine(分页数据, 其他数据...)
```

### 1.3 文件结构

```
examplerefactor/
├── PagingData.kt           # 纯粹的分页数据
├── PageState.kt            # 页面状态（在 ViewModel 中定义）
├── PagingDelegate.kt       # 分页逻辑委托（只管数据，不管页面状态）
├── PagingExtensions.kt     # 扩展函数
├── PageResult.kt           # Repository 返回类型
├── PagingUiState.kt        # 兼容旧版（可选）
├── SimpleUiState.kt        # 非分页场景（可选）
├── RefactoredPagingViewModel.kt
├── RefactoredPagingFragment.kt
├── RefactoredPagingRepository.kt
└── RefactoredPagingAdapter.kt
```

---

## 2. PagingData vs PagingUiState

### 2.1 PagingData（新设计）

```kotlin
data class PagingData<T>(
    val items: List<T>,
    val loadState: LoadState = LoadState.LOAD_MORE_COMPLETE,
    val page: Int = 1,
    val refreshError: String? = null  // 刷新错误内聚到数据中
) {
    val isLoading: Boolean
        get() = loadState == LoadState.REFRESHING || loadState == LoadState.LOADING_MORE

    val hasMore: Boolean
        get() = loadState != LoadState.LOAD_MORE_END

    val isLoadFailed: Boolean
        get() = loadState == LoadState.LOAD_MORE_FAIL

    companion object {
        fun <T> empty(): PagingData<T> = PagingData(emptyList(), LoadState.REFRESHING, 1, null)
    }
}
```

### 2.2 PageState（新设计）

```kotlin
/**
 * 页面状态，由 ViewModel 根据业务逻辑决定
 */
sealed class PageState {
    data object Loading : PageState()
    data object Empty : PageState()
    data class Error(val message: String) : PageState()
    data object Success : PageState()
}
```

### 2.3 对比

| 方面 | PagingUiState（旧） | PagingData + PageState（新） |
|------|-------------------|---------------------------|
| 耦合度 | 页面状态与数据绑定 | 完全分离 |
| 复杂场景 | 需要额外处理 | 原生支持 combine |
| 灵活性 | 低 | 高 |
| 代码量 | 略少 | 略多但更清晰 |

---

## 3. ViewModel 职责分离

### 3.1 Before：PagingDelegate 管理页面状态

```kotlin
// 旧设计：PagingDelegate 内置页面状态逻辑
class PagingDelegate<T>(...) {
    val uiState: StateFlow<PagingUiState<T>>  // 包含 Loading/Empty/Error/Success

    private fun handleSuccess(result, isRefresh) {
        if (result.items.isEmpty()) {
            _uiState.value = PagingUiState.Empty  // 内置空状态判断
            return
        }
        _uiState.value = PagingUiState.Success(...)
    }

    private fun handleError(throwable, isRefresh) {
        if (isRefresh) {
            _uiState.value = PagingUiState.Error(...)  // 内置错误状态
        }
    }
}
```

### 3.2 After：PagingDelegate 只管数据

```kotlin
// 新设计：PagingDelegate 只暴露 data（error 内聚在 PagingData 中）
class PagingDelegate<T>(...) {
    val data: StateFlow<PagingData<T>>  // 包含 items + loadState + refreshError

    private fun handleError(throwable, isRefresh) {
        _data.value = current.copy(
            loadState = LoadState.LOAD_MORE_FAIL,
            refreshError = if (isRefresh) errorMsg else current.refreshError
        )
    }
}
```

### 3.3 ViewModel 负责决定页面状态

```kotlin
class RefactoredPagingViewModel : ViewModel() {
    private val paging = PagingDelegate<String>(viewModelScope) { page, size ->
        repository.loadPage(currentTabKey, page, size)
    }

    val pagingData = paging.data

    // 简单场景：只需 map，无需 combine
    val pageState = paging.data.map { data ->
        when {
            data.refreshError != null && data.items.isEmpty() -> PageState.Error(data.refreshError)
            data.items.isEmpty() && data.isLoading -> PageState.Loading
            data.items.isEmpty() -> PageState.Empty
            else -> PageState.Success
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), PageState.Loading)
}
```

---

## 4. Fragment 双流观察

### 4.1 Before：单流观察

```kotlin
// 旧设计：一个 Flow 处理所有逻辑
private fun observeUiState() {
    viewModel.uiState.collectWhenStarted { state ->
        when (state) {
            is PagingUiState.Loading -> showState<LoadingPage>()
            is PagingUiState.Empty -> showState<EmptyPage>()
            is PagingUiState.Error -> showState<ErrorPage>()
            is PagingUiState.Success -> {
                showSuccess()
                adapter.applyPagingSuccess(state, binding.refreshLayout)
            }
        }
    }
}
```

### 4.2 After：双流观察

```kotlin
// 新设计：分离页面状态和列表数据
private fun observeState() {
    with(viewLifecycleOwner) {
        // 流 1：页面状态 -> 控制 StatePage
        viewModel.pageState.collectWhenStarted { state ->
            when (state) {
                is PageState.Loading -> showState<LoadingPage>()
                is PageState.Empty -> {
                    binding.refreshLayout.finishRefresh()
                    showState<EmptyPage>()
                }
                is PageState.Error -> {
                    binding.refreshLayout.finishRefresh()
                    showState<ErrorPage>()
                }
                is PageState.Success -> showSuccess()
            }
        }

        // 流 2：分页数据 -> 更新列表
        viewModel.pagingData.collectWhenStarted { data ->
            adapter.applyPagingData(data, binding.refreshLayout)
        }
    }
}
```

### 4.3 优势

| 方面 | 单流 | 双流 |
|------|------|------|
| 职责 | 混合 | 清晰分离 |
| 复杂场景 | 难扩展 | 易扩展 |
| 调试 | 状态混杂 | 独立追踪 |

---

## 5. 扩展函数封装

### 5.1 applyPagingData（新）

```kotlin
/**
 * 应用分页数据到 Adapter 和 RefreshLayout
 */
fun <T, VH : BaseViewHolder> BaseQuickAdapter<T, VH>.applyPagingData(
    data: PagingData<T>,
    refreshLayout: SmartRefreshLayout? = null
) {
    if (data.isLoading) return

    refreshLayout?.finishRefresh()

    if (!data.isLoadFailed) {
        setList(data.items)
    }

    loadMoreModule.applyLoadState(data.loadState)
}
```

### 5.2 applyPagingSuccess（兼容旧版）

```kotlin
/**
 * 兼容旧版 PagingUiState.Success
 */
fun <T, VH : BaseViewHolder> BaseQuickAdapter<T, VH>.applyPagingSuccess(
    state: PagingUiState.Success<T>,
    refreshLayout: SmartRefreshLayout? = null
) {
    // 实现与 applyPagingData 类似
}
```

---

## 6. 复杂场景支持

### 6.1 场景：用户信息 + 分页列表

```kotlin
class ComplexViewModel : ViewModel() {
    private val _userInfo = MutableStateFlow<UserInfo?>(null)
    private val paging = PagingDelegate<Item>(viewModelScope) { page, size ->
        repository.loadItems(page, size)
    }

    val pagingData = paging.data

    // 页面状态 = f(用户信息, 分页数据) - 只需 combine 2 个参数
    val pageState = combine(_userInfo, paging.data) { user, data ->
        when {
            user == null -> PageState.Loading
            data.refreshError != null && data.items.isEmpty() -> PageState.Error(data.refreshError)
            data.items.isEmpty() && data.isLoading -> PageState.Loading
            data.items.isEmpty() -> PageState.Empty
            else -> PageState.Success
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), PageState.Loading)

    fun loadUserInfo() {
        viewModelScope.launch {
            _userInfo.value = repository.getUserInfo()
        }
    }
}
```

### 6.2 场景：多个分页列表

```kotlin
class MultiListViewModel : ViewModel() {
    private val pagingA = PagingDelegate<ItemA>(viewModelScope) { ... }
    private val pagingB = PagingDelegate<ItemB>(viewModelScope) { ... }

    val dataA = pagingA.data
    val dataB = pagingB.data

    val pageState = combine(pagingA.data, pagingB.data) { a, b ->
        when {
            a.isLoading || b.isLoading -> PageState.Loading
            a.items.isEmpty() && b.items.isEmpty() -> PageState.Empty
            else -> PageState.Success
        }
    }.stateIn(...)
}
```

---

## 7. 迁移指南

### 7.1 从旧版迁移

1. **保留 PagingUiState**（可选）
   - 简单场景可继续使用
   - 使用 `applyPagingSuccess()` 扩展函数

2. **迁移到新版**
   - 使用 `PagingData` + `PageState`
   - ViewModel 中 combine 决定页面状态
   - Fragment 双流观察

### 7.2 新项目推荐

| 场景 | 推荐方案 |
|------|---------|
| 简单分页（单接口） | PagingData + PageState |
| 复杂页面（多接口） | PagingData + combine |
| 快速原型 | PagingUiState（旧版） |

### 7.3 检查清单

- [ ] PagingDelegate 只暴露 `data` 和 `loadError`
- [ ] ViewModel 通过 combine 决定 `pageState`
- [ ] Fragment 分别观察 `pageState` 和 `pagingData`
- [ ] 使用 `applyPagingData()` 更新列表
- [ ] 测试：刷新/加载更多/空数据/错误/多接口组合

---

## 附录：文件对照表

| 文件 | 职责 | 变化 |
|------|------|------|
| `PagingData.kt` | 纯粹的分页数据 | **新增** |
| `PageState` | 页面状态 | **新增**（在 ViewModel 中） |
| `PagingDelegate.kt` | 分页逻辑委托 | 改为只管数据 |
| `PagingExtensions.kt` | 扩展函数 | 新增 `applyPagingData()` |
| `PagingUiState.kt` | 兼容旧版 | 保留 |
| `RefactoredPagingViewModel.kt` | 示例 ViewModel | combine 决定页面状态 |
| `RefactoredPagingFragment.kt` | 示例 Fragment | 双流观察 |

---

## 设计原则总结

1. **分离关注点**：分页数据 ≠ 页面状态
2. **组合优于继承**：通过 combine 灵活组合
3. **ViewModel 决策**：页面状态逻辑在 ViewModel，不在 Delegate
4. **Fragment 渲染**：只负责根据状态渲染 UI
5. **扩展性优先**：支持复杂场景，简单场景也不复杂
