package com.androidrtc.chat.modules.basefun.examplerefactor

import com.androidtool.common.base.event.LoadState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * ViewModel 分页逻辑委托（松耦合版本）
 *
 * 设计要点：
 * - 只管理分页数据（PagingData），不管理页面状态（Loading/Empty/Error）
 * - 页面状态由 ViewModel 根据业务逻辑 combine 决定
 * - 支持复杂场景：页面状态 = f(用户信息, 分页列表, 其他数据...)
 *
 * 简单场景使用：
 * ```
 * class SimpleViewModel : ViewModel() {
 *     private val paging = PagingDelegate<String>(viewModelScope) { page, size ->
 *         repository.loadPage(page, size)
 *     }
 *
 *     val pagingData = paging.data
 *     val loadError = paging.loadError
 *
 *     // 页面状态由 ViewModel 决定
 *     val pageState = combine(pagingData, loadError) { data, error ->
 *         when {
 *             error != null && data.items.isEmpty() -> PageState.Error(error)
 *             data.items.isEmpty() && data.isLoading -> PageState.Loading
 *             data.items.isEmpty() -> PageState.Empty
 *             else -> PageState.Success
 *         }
 *     }
 * }
 * ```
 *
 * 复杂场景使用（多接口组合）：
 * ```
 * class ComplexViewModel : ViewModel() {
 *     private val paging = PagingDelegate<Item>(viewModelScope) { ... }
 *     private val _userInfo = MutableStateFlow<UserInfo?>(null)
 *
 *     // 页面状态 = f(用户信息, 分页数据)
 *     val pageState = combine(_userInfo, paging.data, paging.loadError) { user, data, error ->
 *         when {
 *             user == null -> PageState.Loading  // 用户信息未加载
 *             error != null && data.items.isEmpty() -> PageState.Error(error)
 *             data.items.isEmpty() && data.isLoading -> PageState.Loading
 *             data.items.isEmpty() -> PageState.Empty
 *             else -> PageState.Success
 *         }
 *     }
 * }
 * ```
 */
class PagingDelegate<T>(
    private val scope: CoroutineScope,
    private val pageSize: Int = 20,
    private val loader: suspend (page: Int, pageSize: Int) -> PageResult<T>
) {
    private val _data = MutableStateFlow(PagingData.empty<T>())
    val data: StateFlow<PagingData<T>> = _data.asStateFlow()

    private var currentPage = 1

    fun refresh() {
        currentPage = 1
        load(isRefresh = true)
    }

    fun loadMore() {
        val current = _data.value
        if (!current.isLoading && current.hasMore) {
            load(isRefresh = false)
        }
    }

    fun reset() {
        currentPage = 1
        _data.value = PagingData.empty()
    }

    private fun load(isRefresh: Boolean) {
        scope.launch {
            updateLoadingState(isRefresh)

            runCatching { loader(currentPage, pageSize) }
                .onSuccess { result -> handleSuccess(result, isRefresh) }
                .onFailure { throwable -> handleError(throwable, isRefresh) }
        }
    }

    private fun updateLoadingState(isRefresh: Boolean) {
        val current = _data.value
        _data.value = current.copy(
            loadState = if (isRefresh) LoadState.REFRESHING else LoadState.LOADING_MORE,
            refreshError = if (isRefresh) null else current.refreshError
        )
    }

    private fun handleSuccess(result: PageResult<T>, isRefresh: Boolean) {
        val loadState = if (result.hasMore) LoadState.LOAD_MORE_COMPLETE else LoadState.LOAD_MORE_END
        val current = _data.value

        _data.value = if (isRefresh) {
            PagingData(result.items, loadState, currentPage, null)
        } else {
            current.copy(items = current.items + result.items, loadState = loadState, page = currentPage)
        }

        currentPage++
    }

    private fun handleError(throwable: Throwable, isRefresh: Boolean) {
        val current = _data.value
        val errorMsg = throwable.message ?: "Unknown error"

        _data.value = current.copy(
            loadState = LoadState.LOAD_MORE_FAIL,
            refreshError = if (isRefresh) errorMsg else current.refreshError
        )
    }
}
