---
name: developing-android-features
description: >-
  Implements Android features following project-specific MVI architecture,
  custom base classes (BaseBindingFragment/Activity), LoadSir state pages,
  BRVAH v3.x adapters, and internal utility APIs (onClick, dp, VLog,
  TranslateResource, collectWhenStarted). Use when developing any Android
  feature, creating new screens, implementing lists with pagination,
  or adding TabLayout+ViewPager2 patterns.
---

# Android Feature Development

This skill contains project-specific conventions for Android feature development.
Load the appropriate reference files based on your task.

---

## 1. Import Quick Reference

Always use project-provided utilities. Never put a full package name in a code block —
always add an import statement at the top of the file.

### Click Handling

```kotlin
import com.androidtool.common.extension.onClick

button.onClick { /* handle click */ }
button.onClick(delay = 600) { /* custom debounce */ }
```

### Dimension Conversion

```kotlin
import com.androidtool.common.extension.dp

val padding = 16.dp
```

### Screen & Device Info

```kotlin
import com.androidtool.common.utils.ScreenUtil

ScreenUtil.getStatusBarHeight()
ScreenUtil.getScreenWidth()
ScreenUtil.getScreenHeight()
```

### Logging

```kotlin
import com.androidtool.common.log.VLog

// Always use "lilili" as primary tag
VLog.d("lilili", "Retrieved user ID: $userId")
```

### String Resources (i18n)

```kotlin
import com.androidtool.common.utils.TranslateResource

binding.title = TranslateResource.getStringResources("title")
```

### Lifecycle-aware Flow Collection

```kotlin
import com.androidtool.common.utils.collectWhenStarted

viewModel.uiState.collectWhenStarted { state ->
    handleUiState(state)
}
```

### State Pages (LoadSir)

```kotlin
import com.androidtool.common.base.page.EmptyPage
import com.androidtool.common.base.page.ErrorPage
import com.androidtool.common.base.page.LoadingPage

// Show state pages
showState<LoadingPage>()
showState<EmptyPage>()
showState<ErrorPage> {
    val hint = view.findViewById<TextView>(R.id.hint)
    hint?.onClick { viewModel.refresh() }
}
showSuccess()  // dismiss state page, show real content
```

### Adapter (BRVAH v3.x)

```kotlin
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.BaseMultiItemQuickAdapter
import com.chad.library.adapter.base.module.LoadMoreModule
import com.chad.library.adapter.base.viewholder.BaseViewHolder
```

### Model Package

```kotlin
// All model/bean classes live in com.model
import com.model.SomeBean
```

### Network Layer

```kotlin
import com.androidtool.common.extension.asResult
import com.androidtool.common.extension.requestToFlow
import com.androidtool.common.troll.BaseResponse
import com.androidtool.common.net.Apis
```

---

## 2. Architecture Overview

- **Layers**: `ui/` → `data/` (→ optional `domain/`)
- **No DI framework** — instantiate repositories directly
- **No usecase layer** unless explicitly requested
- **No mapper** unless explicitly requested
- **All models** in `com.model` package
- **Network**: All API responses wrapped in `BaseResponse<T>`;
  all request params use `Map<String, String>`
- **State management**: MVI — State (StateFlow), Event (sealed interface), Effect (Channel)
- **Base classes**: `BaseBindingFragment<VB>`, `BaseBindingActivity<VB>` with LoadSir integration
- **Adapters**: BRVAH v3.x (`BaseQuickAdapter`, `BaseMultiItemQuickAdapter`, `LoadMoreModule`)
- **Refresh**: SmartRefreshLayout + custom `MyRefreshLayout` header

---

## 3. Feature Implementation Workflow

Choose reference files based on your task:

| Task | Required References |
|------|-------------------|
| **Create a new feature screen** | [project-structure](references/project-structure.md) + [mvi-pattern](references/mvi-pattern.md) + [base-classes](references/base-classes.md) + [network-layer](references/network-layer.md) |
| **Add a list with adapter** | [adapter-pattern](references/adapter-pattern.md) |
| **Add pull-to-refresh + pagination** | [refresh-pagination](references/refresh-pagination.md) |
| **Add TabLayout + ViewPager2** | [tab-viewpager](references/tab-viewpager.md) |
| **Fix ViewModel / state bug** | [mvi-pattern](references/mvi-pattern.md) |
| **Understand base class API** | [base-classes](references/base-classes.md) |

---

## 4. Constraints & Naming

- **Layout**: XML with ConstraintLayout preferred; FrameLayout/LinearLayout for simple cases
- **ViewBinding**: Always use ViewBinding, never `findViewById` in new code
- **Coroutines**: Prefer `suspend` functions and `Flow`; use `suspendCancellableCoroutine`
  or `callbackFlow` instead of callbacks
- **Naming**: PascalCase for classes, camelCase for functions/variables,
  UPPER_SNAKE_CASE for constants. Use complete descriptive names.
- **Interface**: No `I` prefix unless needed for disambiguation
- **Contract file**: State, Event, Effect grouped in `OneFeatureContract.kt`
- **Chinese annotations**: Add on complex logic functions and classes
- **Package path**: If user provides a specific package path, use it; otherwise use the feature name

---

## 5. Property Delegation Pattern

For complex logic in Activities/Fragments, delegate to specialized Impl classes
with lifecycle awareness:

```kotlin
class FloatingVideoFragment : BaseBindingFragment<FragmentFloatingVideoBinding>(),
    DraggableBehavior by DraggableBehaviorImpl(),
    LoopVideoPlayerBehavior by LoopVideoPlayerBehaviorImpl() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        bindLifecycle(lifecycle)
    }
}

// Interface defines the contract
interface LoopVideoPlayerBehavior {
    fun bindLifecycle(lifecycle: Lifecycle)
    fun setupVideoPlayer(container: ViewPager2)
    fun startLoop()
    fun pauseLoop()
    fun releasePlayerResource()
}

// Implementation observes lifecycle
class LoopVideoPlayerBehaviorImpl : LoopVideoPlayerBehavior, DefaultLifecycleObserver {
    override fun bindLifecycle(lifecycle: Lifecycle) {
        lifecycle.addObserver(this)
    }
    override fun onResume(owner: LifecycleOwner) { /* auto resume */ }
    override fun onPause(owner: LifecycleOwner) { /* auto pause */ }
    override fun onDestroy(owner: LifecycleOwner) { releasePlayerResource() }
}
```

---

## 6. Reference Navigation

| File | Description |
|------|------------|
| [references/project-structure.md](references/project-structure.md) | Feature directory layout and layer constraints |
| [references/mvi-pattern.md](references/mvi-pattern.md) | Contract file, State/Event/Effect data flow patterns |
| [references/base-classes.md](references/base-classes.md) | BaseBindingFragment/Activity API, LoadSir, TitleBarView |
| [references/network-layer.md](references/network-layer.md) | Repository → ViewModel → ApiService patterns |
| [references/adapter-pattern.md](references/adapter-pattern.md) | BRVAH v3.x simple and multi-type adapters |
| [references/refresh-pagination.md](references/refresh-pagination.md) | Complete SmartRefreshLayout + pagination template |
| [references/tab-viewpager.md](references/tab-viewpager.md) | Complete TabLayout + ViewPager2 template |
