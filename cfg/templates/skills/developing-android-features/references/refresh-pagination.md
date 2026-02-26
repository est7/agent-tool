# Refresh & Pagination Template

## Contents

- Layout XML
- Fragment implementation
- ViewModel with pagination logic
- LoadState enum
- UiState sealed class

**Low freedom**: This is a complete template — follow it precisely when implementing
pull-to-refresh with pagination.

---

## Layout XML

`fragment_sample_load_more.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/white">

    <com.scwang.smart.refresh.layout.SmartRefreshLayout
        android:id="@+id/refreshLayout"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintTop_toTopOf="parent">

        <com.androidtool.common.widget.MyRefreshLayout
            android:layout_width="match_parent"
            android:layout_height="54dp" />

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/recyclerView"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:clipChildren="false"
            android:clipToPadding="false"
            android:overScrollMode="never"
            android:paddingHorizontal="12dp"
            android:paddingVertical="3dp"
            android:scrollbars="none" />

    </com.scwang.smart.refresh.layout.SmartRefreshLayout>

</androidx.constraintlayout.widget.ConstraintLayout>
```

---

## Fragment Implementation

```kotlin
import com.androidtool.common.base.BaseBindingFragment
import com.androidtool.common.base.page.EmptyPage
import com.androidtool.common.base.page.ErrorPage
import com.androidtool.common.base.page.LoadingPage
import com.androidtool.common.extension.onClick
import com.androidtool.common.utils.collectWhenStarted

class SampleLoadMoreFragment : BaseBindingFragment<FragmentSampleLoadMoreBinding>() {
    private val viewModel: SampleLoadMoreViewModel by viewModels()

    override fun registerState() = binding.recyclerView

    private val adapter by lazy { SampleLoadMoreAdapter() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = arguments?.getString("id") ?: "1000"
        viewModel.initDataById(id)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupRefreshLayout()
        setupRecyclerView()
        observeUiState()
    }

    private fun setupRefreshLayout() {
        binding.refreshLayout.setOnRefreshListener { viewModel.refresh() }
    }

    private fun setupRecyclerView() {
        binding.recyclerView.layoutManager = LinearLayoutManager(context)
        binding.recyclerView.adapter = adapter
        adapter.loadMoreModule.apply {
            isAutoLoadMore = true
            isEnableLoadMoreIfNotFullPage = false
            setOnLoadMoreListener { viewModel.loadMore() }
        }
    }

    private fun observeUiState() {
        viewModel.uiState.collectWhenStarted { state -> handleUiState(state) }
    }

    private fun handleUiState(state: SampleLoadMoreUiState<SampleUserInfo>) {
        when (state) {
            is SampleLoadMoreUiState.Loading -> showState<LoadingPage>()
            is SampleLoadMoreUiState.Empty -> {
                binding.refreshLayout.finishRefresh()
                showState<EmptyPage>()
            }
            is SampleLoadMoreUiState.Success -> {
                showSuccess()
                handleSuccessState(state)
            }
            is SampleLoadMoreUiState.Error -> {
                binding.refreshLayout.finishRefresh()
                showState<ErrorPage> {
                    val hint = view.findViewById<TextView>(R.id.hint)
                    hint?.onClick { viewModel.refresh() }
                }
            }
        }
    }

    private fun handleSuccessState(state: SampleLoadMoreUiState.Success<SampleUserInfo>) {
        when (state.loadState) {
            LoadState.REFRESHING -> { /* SmartRefreshLayout handles UI */ }
            LoadState.LOADING_MORE -> { /* BRVAH handles UI */ }
            LoadState.LOAD_MORE_COMPLETE -> {
                binding.refreshLayout.finishRefresh()
                adapter.setList(state.items)
                adapter.loadMoreModule.loadMoreComplete()
            }
            LoadState.LOAD_MORE_END -> {
                binding.refreshLayout.finishRefresh()
                adapter.setList(state.items)
                adapter.loadMoreModule.loadMoreEnd()
            }
            LoadState.LOAD_MORE_FAIL -> {
                binding.refreshLayout.finishRefresh()
                adapter.loadMoreModule.loadMoreFail()
            }
        }
    }

    companion object {
        fun newInstance(id: String) = SampleLoadMoreFragment().apply {
            arguments = Bundle().apply { putString("id", id) }
        }
    }
}
```

---

## ViewModel with Pagination

```kotlin
class SampleLoadMoreViewModel : ViewModel() {
    private val repository = SampleLoadMoreRepository.getSingleInstance()
    private var currentPage = 1
    private var currentId = ""

    private val _uiState =
        MutableStateFlow<SampleLoadMoreUiState<SampleUserInfo>>(SampleLoadMoreUiState.Loading)
    val uiState = _uiState.asStateFlow()

    fun initDataById(id: String) {
        if (currentId != id) {
            currentId = id
            currentPage = 1
        }
        loadData(isRefresh = true)
    }

    fun refresh() {
        currentPage = 1
        loadData(isRefresh = true)
    }

    fun loadMore() {
        val current = _uiState.value
        if (current is SampleLoadMoreUiState.Success &&
            current.loadState != LoadState.LOADING_MORE &&
            current.loadState != LoadState.LOAD_MORE_END
        ) {
            loadData(isRefresh = false)
        }
    }

    private fun loadData(isRefresh: Boolean) {
        viewModelScope.launch {
            updateLoadingState(isRefresh)
            repository.loadDataById(currentId, currentPage)
                .catch { exception -> handleError(exception, isRefresh) }
                .collect { result ->
                    result.fold(
                        onSuccess = { data -> handleSuccess(data, isRefresh) },
                        onFailure = { exception -> handleError(exception, isRefresh) }
                    )
                }
        }
    }

    private fun updateLoadingState(isRefresh: Boolean) {
        val current = _uiState.value
        if (isRefresh) {
            _uiState.value = if (current is SampleLoadMoreUiState.Success) {
                current.copy(loadState = LoadState.REFRESHING)
            } else {
                SampleLoadMoreUiState.Loading
            }
        } else if (current is SampleLoadMoreUiState.Success) {
            _uiState.value = current.copy(loadState = LoadState.LOADING_MORE)
        }
    }

    private fun handleSuccess(data: List<SampleUserInfo>, isRefresh: Boolean) {
        val pageSize = PAGE_SIZE
        if (isRefresh) {
            if (data.isEmpty()) {
                _uiState.value = SampleLoadMoreUiState.Empty
                return
            }
            _uiState.value = SampleLoadMoreUiState.Success(
                items = data,
                loadState = if (data.size < pageSize) LoadState.LOAD_MORE_END
                           else LoadState.LOAD_MORE_COMPLETE,
                page = currentPage
            )
        } else {
            val current = _uiState.value as? SampleLoadMoreUiState.Success ?: return
            _uiState.value = current.copy(
                items = current.items + data,
                loadState = if (data.size < pageSize) LoadState.LOAD_MORE_END
                           else LoadState.LOAD_MORE_COMPLETE,
                page = currentPage
            )
        }
        currentPage++
    }

    private fun handleError(exception: Throwable, isRefresh: Boolean) {
        if (isRefresh) {
            _uiState.value = SampleLoadMoreUiState.Error(exception.message ?: "Unknown error")
        } else {
            val current = _uiState.value as? SampleLoadMoreUiState.Success ?: return
            _uiState.value = current.copy(loadState = LoadState.LOAD_MORE_FAIL)
        }
    }

    companion object {
        const val PAGE_SIZE = 20
    }
}
```

---

## LoadState Enum

```kotlin
package com.androidtool.common.base.event

enum class LoadState {
    REFRESHING,         // Pull-to-refresh in progress
    LOADING_MORE,       // Load more in progress
    LOAD_MORE_COMPLETE, // More data available
    LOAD_MORE_END,      // No more data
    LOAD_MORE_FAIL      // Load more failed
}
```

---

## UiState Sealed Class

```kotlin
sealed class SampleLoadMoreUiState<out T> {
    data object Loading : SampleLoadMoreUiState<Nothing>()
    data object Empty : SampleLoadMoreUiState<Nothing>()

    data class Success<T>(
        val loadState: LoadState = LoadState.LOAD_MORE_COMPLETE,
        val page: Int = 1,
        val items: List<T> = emptyList()
    ) : SampleLoadMoreUiState<T>()

    data class Error(val message: String) : SampleLoadMoreUiState<Nothing>()
}
```
