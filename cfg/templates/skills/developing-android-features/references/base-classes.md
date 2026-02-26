# Base Classes

## Contents

- BaseBindingFragment API
- BaseBindingActivity API
- LoadSir state page management
- TitleBarView API
- Fragment usage example
- Activity usage example

---

## BaseBindingFragment API

Package: `com.androidtool.common.base`

Extends `Fragment` with ViewBinding delegation and LoadSir integration.

| Override | Purpose | Default |
|----------|---------|---------|
| `registerState(): View?` | View to wrap with LoadSir state pages | `null` (no state pages) |
| `onStateClick()` | Called when user taps a state page | no-op |
| `initView()` | Called in `onViewCreated` after binding is ready | no-op |
| `onLazyLoad()` | Lazy loading for fragments in ViewPager (called once on first `onResume`) | no-op |

**Available methods:**

| Method | Description |
|--------|------------|
| `showState<T>(ifShow?, useAnim?, block?)` | Show a state page (`LoadingPage`, `EmptyPage`, `ErrorPage`) |
| `showSuccess(useAnim?)` | Dismiss state page, show real content |
| `showLoading()` | Shorthand for `loadSir.show<LoadingPage>()` |
| `isLazyLoaded()` | Whether `onLazyLoad()` has been called |

**`showState` parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `ifShow` | `Any?` | Condition: `Collection` → show if empty; `Boolean` → show if true; `null` → always show |
| `useAnim` | `Boolean` | Animate state transition (default `true`) |
| `block` | `(T.() -> Unit)?` | Configure the state page view (e.g., set click listeners) |

**Lifecycle flow:**

```
onCreateView → createViewBinding → registerState → LoadSir.register
onViewCreated → initView()
onResume (first time) → onLazyLoad()
```

---

## BaseBindingActivity API

Package: `com.androidtool.common.base`

Extends `RootActivity` with ViewBinding delegation and LoadSir integration.
**Does NOT include TitleBar** — you must add it yourself via XML.

| Override | Purpose | Default |
|----------|---------|---------|
| `registerState(): View?` | View to wrap with LoadSir | `null` |
| `onStateClick()` | Called when state page is tapped | no-op |
| `initView()` | **Abstract** — must implement | — |
| `initData()` | Called after `initView()` | no-op |

Same `showState<T>()`, `showSuccess()`, `showLoading()` methods as Fragment.

**Lifecycle flow:**

```
onCreate → createViewBinding → registerState → LoadSir.register → setContentView → initView → initData
```

---

## LoadSir State Page Usage

1. Override `registerState()` to return the view to wrap:

```kotlin
// Wrap a specific view (e.g., RecyclerView)
override fun registerState() = binding.recyclerView

// Wrap the entire root
override fun registerState() = binding.root
```

2. Show/dismiss state pages:

```kotlin
showState<LoadingPage>()
showState<EmptyPage>()
showSuccess()

// ErrorPage with retry button
showState<ErrorPage> {
    val hint = view.findViewById<TextView>(R.id.hint)
    hint?.onClick { viewModel.refresh() }
}
```

---

## TitleBarView API

Package: `com.androidtool.common.widget.TitleBarView`

Add in XML layout (typically at top of a LinearLayout):

```xml
<com.androidtool.common.widget.TitleBarView
    android:id="@+id/titleBar"
    android:layout_width="match_parent"
    android:layout_height="wrap_content" />
```

Available methods:

```kotlin
// Set title text
binding.titleBar.setTitle(TranslateResource.getStringResources("topic"))

// Set back button action
binding.titleBar.setOnBackClickListener { finish() }

// Set right-side icon button
binding.titleBar.setExtraButton(R.drawable.ic_share) { view -> /* click */ }

// Set right-side custom layout
binding.titleBar.setExtraButtonLayout(customView)
```

---

## Fragment Usage Example

```kotlin
import com.androidtool.common.base.BaseBindingFragment
import com.androidtool.common.utils.collectWhenStarted

class SampleListFragment : BaseBindingFragment<FragmentSampleListBinding>() {
    private val viewModel: SampleListViewModel by viewModels()

    override fun registerState() = binding.recyclerView

    private val adapter by lazy { SampleListAdapter() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = arguments?.getString("id") ?: "0"
        viewModel.initDataById(id)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupRecyclerView()
        viewModel.uiState.collectWhenStarted { handleUiState(it) }
        viewModel.effect.collectWhenStarted { handleEffect(it) }
    }

    companion object {
        fun newInstance(id: String) = SampleListFragment().apply {
            arguments = Bundle().apply { putString("id", id) }
        }
    }
}
```

---

## Activity Usage Example

```kotlin
import com.androidtool.common.base.BaseBindingActivity
import com.androidtool.common.utils.TranslateResource
import com.androidtool.common.utils.collectWhenStarted

class SampleActivity : BaseBindingActivity<ActivitySampleBinding>() {
    private val viewModel: SampleViewModel by viewModels()

    override fun registerState(): View = binding.contentView

    override fun initView() {
        binding.titleBar.setTitle(TranslateResource.getStringResources("sample"))
        binding.titleBar.setOnBackClickListener { finish() }
    }

    override fun initData() {
        viewModel.uiState.collectWhenStarted { handleUiState(it) }
        viewModel.loadData()
    }

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, SampleActivity::class.java))
        }
    }
}
```
