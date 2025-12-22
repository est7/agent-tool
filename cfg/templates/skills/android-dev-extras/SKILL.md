---
name: android-dev-extras
description: Android 功能开发扩展模板。包含上拉刷新(SmartRefreshLayout)和 TabLayout+ViewPager2 的完整实现模板。仅在需要刷新或 Tab 切换功能时加载。
metadata:
  category: android
  platform: android
---

# Android 功能开发扩展模板

本 Skill 包含上拉刷新和 Tab 切换的完整实现模板，仅在需要这些功能时加载。

---

## 1. 上拉刷新与加载更多

When you need to integrate "pull-to-refresh and load-more" functionality, refer to the following code. Use LoadState to track loading states, use LoadSir's showState<Page> for page state changes, and use BaseRecyclerViewAdapterHelper v3.x for Adapter implementation:

### 1.1 布局文件

fragment_sample_load_more.xml:

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools" android:layout_width="match_parent"
    android:background="@color/white" android:layout_height="match_parent"
    tools:ignore="ContentDescription">

    <com.scwang.smart.refresh.layout.SmartRefreshLayout android:id="@+id/refreshLayout"
        android:layout_width="match_parent" android:layout_height="0dp"
        app:layout_constraintBottom_toBottomOf="parent" app:layout_constraintTop_toTopOf="parent">

        <com.androidtool.common.widget.MyRefreshLayout android:layout_width="match_parent"
            android:layout_height="54dp" />

        <androidx.recyclerview.widget.RecyclerView android:id="@+id/recyclerView"
            android:layout_width="match_parent" android:layout_height="match_parent"
            android:animateLayoutChanges="false" android:clipChildren="false"
            android:clipToPadding="false" android:overScrollMode="never"
            android:paddingHorizontal="12dp" android:paddingVertical="3dp"
            android:scrollbars="none" />

    </com.scwang.smart.refresh.layout.SmartRefreshLayout>

</androidx.constraintlayout.widget.ConstraintLayout>

```

### 1.2 Fragment 实现

SampleLoadMoreFragment:

```kotlin
import android.os.Bundle
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.androidtool.common.base.BaseBindingFragment
import com.androidtool.common.base.page.EmptyPage
import com.androidtool.common.base.page.ErrorPage
import com.androidtool.common.base.page.LoadingPage
import com.androidtool.common.extension.onClick
import com.androidtool.common.utils.collectWhenStarted
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.module.LoadMoreModule
import com.chad.library.adapter.base.viewholder.BaseViewHolder

/**
 * Pagination loading example Fragment
 * @author: est8
 * @date: 2025/2/28
 */
class SampleLoadMoreFragment : BaseBindingFragment<FragmentSampleLoadMoreBinding>() {
    private val viewModel: SampleLoadMoreViewModel by viewModels()
    private lateinit var id: String

    // refresh placeholder usage
    override fun registerState() = binding.recyclerView

    private val adapter by lazy {
        SampleLoadMoreAdapter()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        id = arguments?.getString("id") ?: "1000"
        viewModel.initDataById(id = id)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupRefreshLayout()
        setupRecyclerView()
        observeUiState()
    }

    /**
     * Setup pull-to-refresh
     */
    private fun setupRefreshLayout() {
        binding.refreshLayout.setOnRefreshListener {
            viewModel.refresh()
        }
    }

    /**
     * Setup RecyclerView and load more
     */
    private fun setupRecyclerView() {
        binding.recyclerView.layoutManager = LinearLayoutManager(context)
        binding.recyclerView.adapter = adapter

        adapter.loadMoreModule.apply {
            isAutoLoadMore = true
            isEnableLoadMoreIfNotFullPage = false
            setOnLoadMoreListener {
                viewModel.loadMore()
            }
        }
    }

    /**
     * Observe UI state changes
     */
    private fun observeUiState() {
        viewModel.sampleLoadMoreUiState.collectWhenStarted { state ->
            handleUiState(state)
        }
    }

    /**
     * Handle UI state
     */
    private fun handleUiState(state: SampleLoadMoreUiState<SampleUserInfo>) {
        when (state) {
            is SampleLoadMoreUiState.Loading -> {
                loadSir.show<LoadingPage>()
            }

            is SampleLoadMoreUiState.Empty -> {
                binding.refreshLayout.finishRefresh()
                loadSir.show<EmptyPage>()
            }

            is SampleLoadMoreUiState.Success -> {
                loadSir.showSuccess()
                handleSuccessState(state)
            }

            is SampleLoadMoreUiState.Error -> {
                binding.refreshLayout.finishRefresh()
                loadSir.show<ErrorPage> { it ->
                    val hint = it.view.findViewById<TextView>(R.id.hint)
                    hint?.onClick {
                        viewModel.refresh()
                    }

                }
            }
        }
    }

    /**
     * Handle success state
     */
    private fun handleSuccessState(state: SampleLoadMoreUiState.Success<SampleUserInfo>) {
        when (state.loadState) {
            LoadState.REFRESHING -> {
                // refreshLayout will automatically handle pull-to-refresh UI
            }

            LoadState.LOADING_MORE -> {
                // BRVAH will automatically handle load more UI
            }

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
}

```

### 1.3 Adapter 实现

SampleListAdapter:

```kotlin
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.BaseMultiItemQuickAdapter
import com.chad.library.adapter.base.module.LoadMoreModule
import com.chad.library.adapter.base.viewholder.BaseViewHolder

/**
 * Using https://github.com/CymChad/BaseRecyclerViewAdapterHelper v3.x
 * User information adapter
 */
class SampleLoadMoreAdapter :
    BaseQuickAdapter<SampleUserInfo, BaseViewHolder>(R.layout.item_sample_user),
    LoadMoreModule {

    override fun convert(holder: BaseViewHolder, item: SampleUserInfo) {
        holder.setText(R.id.tvName, item.name)
        holder.setText(R.id.tvAge, "Age: ${item.age}")
        holder.setText(R.id.tvEmail, item.email)

        holder.getView<View>(R.id.btnAction).setOnClickListener {
            Toast.makeText(context, "Clicked on ${item.name}", Toast.LENGTH_SHORT).show()
        }
    }
}


// Complex multi-type list adapter uses BaseMultiItemQuickAdapter
class InterestTagAdapter(private val chosenListListener: (List<InterestTagShowBean>) -> Unit) :
    BaseMultiItemQuickAdapter<InterestTagShowBean, BaseViewHolder>() {}

```

### 1.4 ViewModel 实现

```kotlin

package com.androidrtc.chat.samples.loadmore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.androidrtc.chat.samples.data.SampleLoadMoreRepository
import com.androidrtc.chat.samples.data.SampleLoadMoreService
import com.androidrtc.chat.samples.data.SampleUserInfo
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch

/**
 * ViewModel for pagination loading data
 * @author: est8
 * @date: 2025/2/28
 */
class SampleLoadMoreViewModel : ViewModel() {
    private val repository = SampleLoadMoreRepository.getSingleInstance()
    private var currentPage = 1
    private var currentId = ""

    private val _uiState =
        MutableStateFlow<SampleLoadMoreUiState<SampleUserInfo>>(SampleLoadMoreUiState.Loading)
    val sampleLoadMoreUiState = _uiState.asStateFlow()

    /**
     * Initialize data loading
     * @param id Data ID
     */
    fun initDataById(id: String) {
        if (currentId != id) {
            this.currentId = id
            this.currentPage = 1
        }
        loadData(isRefresh = true)
    }

    /**
     * Refresh data
     */
    fun refresh() {
        currentPage = 1
        loadData(isRefresh = true)
    }

    /**
     * Load more data
     */
    fun loadMore() {
        if (_uiState.value is SampleLoadMoreUiState.Success) {
            val currentState = _uiState.value as SampleLoadMoreUiState.Success<SampleUserInfo>
            // Only trigger load more when not in loading state and not in load complete state
            if (currentState.loadState != LoadState.LOADING_MORE &&
                currentState.loadState != LoadState.LOAD_MORE_END
            ) {
                loadData(isRefresh = false)
            }
        }
    }

    /**
     * Load data
     * @param isRefresh Whether it's a refresh operation
     */
    private fun loadData(isRefresh: Boolean = false) {
        viewModelScope.launch {
            updateLoadingState(isRefresh)

            repository.loadDataById(currentId, currentPage)
                .catch { exception ->
                    handleError(exception, isRefresh)
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { data -> handleSuccess(data, isRefresh) },
                        onFailure = { exception -> handleError(exception, isRefresh) }
                    )
                }
        }
    }

    /**
     * Update loading state
     */
    private fun updateLoadingState(isRefresh: Boolean) {
        if (isRefresh) {
            _uiState.value = if (_uiState.value is SampleLoadMoreUiState.Success) {
                (_uiState.value as SampleLoadMoreUiState.Success<SampleUserInfo>).copy(
                    loadState = LoadState.REFRESHING
                )
            } else {
                SampleLoadMoreUiState.Loading
            }
        } else if (_uiState.value is SampleLoadMoreUiState.Success) {
            _uiState.value = (_uiState.value as SampleLoadMoreUiState.Success<SampleUserInfo>).copy(
                loadState = LoadState.LOADING_MORE
            )
        }
    }

    /**
     * Handle successfully loaded data
     */
    private fun handleSuccess(data: List<SampleUserInfo>, isRefresh: Boolean) {
        if (isRefresh) {
            // Handle empty data case
            if (data.isEmpty()) {
                _uiState.value = SampleLoadMoreUiState.Empty
                return
            }

            _uiState.value = SampleLoadMoreUiState.Success(
                items = data,
                loadState = if (data.size < SampleLoadMoreService.pageSize) LoadState.LOAD_MORE_END else LoadState.LOAD_MORE_COMPLETE,
                page = currentPage
            )
        } else if (_uiState.value is SampleLoadMoreUiState.Success) {
            val currentItems =
                (_uiState.value as SampleLoadMoreUiState.Success<SampleUserInfo>).items
            _uiState.value = (_uiState.value as SampleLoadMoreUiState.Success<SampleUserInfo>).copy(
                items = currentItems + data,
                loadState = if (data.size < SampleLoadMoreService.pageSize) LoadState.LOAD_MORE_END else LoadState.LOAD_MORE_COMPLETE,
                page = currentPage
            )
        }
        currentPage++ // Load next page next time
    }

    /**
     * Handle loading error
     */
    private fun handleError(exception: Throwable, isRefresh: Boolean) {
        if (isRefresh) {
            _uiState.value = SampleLoadMoreUiState.Error(exception.message ?: "Unknown error")
        } else if (_uiState.value is SampleLoadMoreUiState.Success) {
            _uiState.value = (_uiState.value as SampleLoadMoreUiState.Success<SampleUserInfo>).copy(
                loadState = LoadState.LOAD_MORE_FAIL
            )
        }
    }
}

```

### 1.5 LoadState 枚举

LoadState:

```kotlin
package com.androidtool.common.base.event

/**
 * Loading state enum
 */
enum class LoadState {
    REFRESHING,        // Pull-to-refresh in progress
    LOADING_MORE,      // Load more in progress
    LOAD_MORE_COMPLETE, // Load more completed
    LOAD_MORE_END,     // No more data
    LOAD_MORE_FAIL     // Load more failed
}
```

### 1.6 Contract 文件

SampleLoadMoreContract.kt:

```kotlin

sealed class SampleLoadMoreUiState<out T> {
    // Initial loading state
    data object Loading : SampleLoadMoreUiState<Nothing>()

    // Empty data state - only shown when no data is retrieved on first page
    data object Empty : SampleLoadMoreUiState<Nothing>()

    // Data state - contains all data-related states
    data class Success<T>(
        val loadState: LoadState = LoadState.LOAD_MORE_COMPLETE,
        val page: Int = 1,
        val items: List<T> = emptyList()
    ) : SampleLoadMoreUiState<T>()

    // Error state
    data class Error(val message: String) : SampleLoadMoreUiState<Nothing>()
}
```

---

## 2. TabLayout + ViewPager2

When you need to implement TabLayout and ViewPager2 in your Fragment, reference the following code that uses BaseRecyclerViewAdapterHelper v3.x for Adapter implementation:

### 2.1 布局文件

fragment_sample_dynamic_tab.xml:

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.google.android.material.tabs.TabLayout
        android:id="@+id/tabLayout"
        style="@style/SampleDynamicTabLayout"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginHorizontal="16dp"
        android:layout_marginTop="8dp"
        android:layout_marginBottom="8dp"
        android:background="@android:color/transparent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:tabGravity="start" />

    <androidx.viewpager2.widget.ViewPager2
        android:id="@+id/viewPager"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/tabLayout" />
</androidx.constraintlayout.widget.ConstraintLayout>

```

### 2.2 Fragment 实现

SampleDynamicTabFragment:

```kotlin
package com.androidrtc.chat.samples.dynamictab

import android.view.View
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.viewpager2.adapter.FragmentStateAdapter
import com.androidtool.common.base.BaseBindingFragment
import com.androidtool.common.base.page.EmptyPage
import com.androidtool.common.base.page.ErrorPage
import com.androidtool.common.base.page.LoadingPage
import com.androidtool.common.utils.collectWhenStarted
import com.google.android.material.tabs.TabLayoutMediator

/**
 * Pagination loading example Fragment
 */
class SampleDynamicTabFragment : BaseBindingFragment<FragmentSampleDynamicTabBinding>() {
    private val viewModel: SampleDynamicTabViewModel by viewModels()
    private var tabLayoutMediator: TabLayoutMediator? = null

    override fun initView() {
        observeData()
        viewModel.loadData()
    }

    override fun registerState(): View? {
        return binding.root
    }

    private fun observeData() {
        viewModel.tabCategoryListUiState.collectWhenStarted {
            when (it) {
                SampleTopicCategoryListUiState.Empty -> {
                    loadSir.show<EmptyPage>()
                }

                is SampleTopicCategoryListUiState.Error -> {
                    loadSir.show<ErrorPage>()
                }

                SampleTopicCategoryListUiState.Loading -> {
                    loadSir.show<LoadingPage>()
                }

                is SampleTopicCategoryListUiState.Success -> {
                    loadSir.showSuccess()
                    initTabLayoutAndViewPager(it.items)
                }
            }
        }
    }

    private fun initTabLayoutAndViewPager(categories: List<SampleTabCategory>) {
        val pagerAdapter = SampleTabPagerAdapter(this, categories)

        binding.viewPager.adapter = pagerAdapter
        tabLayoutMediator?.detach()
        tabLayoutMediator =
            TabLayoutMediator(binding.tabLayout, binding.viewPager) { tab, position ->
                tab.text = categories[position].name
            }.apply {
                attach()
            }

        if (categories.isNotEmpty()) {
            binding.viewPager.setCurrentItem(0, false)
        }
    }

    override fun onDestroy() {
        tabLayoutMediator?.detach()
        tabLayoutMediator = null
        super.onDestroy()
    }

    companion object {
    }

}

```

### 2.3 PagerAdapter 实现

SampleTabPagerAdapter:
```kotlin
class SampleTabPagerAdapter(
    fragment: Fragment,
    private val categories: List<SampleTabCategory>
) : FragmentStateAdapter(fragment) {

    override fun getItemCount(): Int = categories.size

    override fun createFragment(position: Int): Fragment {
        val category = categories[position]
        // Create different sub-Fragments based on different categories
        // return SampleLoadMoreFragment.newInstance(category)
        return SampleLoadMoreFragment()
    }
}
```

### 2.4 ViewModel 实现

SampleDynamicTabViewModel:
```kotlin

package com.androidrtc.chat.samples.dynamictab

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.androidrtc.chat.samples.data.SampleLoadMoreRepository
import com.androidrtc.chat.samples.data.SampleTabCategory
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch

class SampleDynamicTabViewModel : ViewModel() {
    private val repository = SampleLoadMoreRepository.getSingleInstance()

    private val _uiState =
        MutableStateFlow<SampleTopicCategoryListUiState<SampleTabCategory>>(
            SampleTopicCategoryListUiState.Loading
        )
    val tabCategoryListUiState = _uiState.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            updateLoadingState()

            repository.loadTabList()
                .catch { exception ->
                    handleError(exception)
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { data ->
                            handleSuccess(
                                data
                            )
                        },
                        onFailure = { exception -> handleError(exception) }
                    )
                }
        }
    }

    /**
     * Update loading state
     */
    private fun updateLoadingState() {
        _uiState.value = SampleTopicCategoryListUiState.Loading
    }

    /**
     * Handle successfully loaded data
     */
    private fun handleSuccess(data: List<SampleTabCategory>) {
        // Handle empty data case
        if (data.isEmpty()) {
            _uiState.value = SampleTopicCategoryListUiState.Empty
            return
        }

        _uiState.value = SampleTopicCategoryListUiState.Success(
            items = data,
        )
    }

    /**
     * Handle loading error
     */
    private fun handleError(exception: Throwable) {
        _uiState.value = SampleTopicCategoryListUiState.Error(exception.message ?: "unknown error")
    }
}

```

### 2.5 Contract 文件

SampleTopicCategoryListContract.kt:

```kotlin
sealed class SampleTopicCategoryListUiState<out T> {
    // Initial loading state
    data object Loading : SampleTopicCategoryListUiState<Nothing>()

    // Empty data state
    data object Empty : SampleTopicCategoryListUiState<Nothing>()

    // Data state - contains all data-related states
    data class Success<T>(
        val items: List<T> = emptyList()
    ) : SampleTopicCategoryListUiState<T>()

    // Error state
    data class Error(val message: String) : SampleTopicCategoryListUiState<Nothing>()
}

```
