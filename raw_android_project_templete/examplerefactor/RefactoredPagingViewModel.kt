package com.androidrtc.chat.modules.basefun.examplerefactor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

/**
 * 重构后的示例 ViewModel（松耦合版本）
 *
 * 设计要点：
 * - PagingDelegate 只管理分页数据，不管理页面状态
 * - 页面状态由 ViewModel 通过 combine 决定
 * - 支持复杂场景扩展（多接口组合）
 *
 * 简单场景：页面状态 = f(分页数据, 加载错误)
 * 复杂场景：页面状态 = f(用户信息, 分页数据, 其他数据...)
 */
class RefactoredPagingViewModel : ViewModel() {

    private val repository = RefactoredPagingRepository()
    private var currentTabKey: String = ""

    private val paging = PagingDelegate<String>(viewModelScope) { page, size ->
        repository.loadPage(currentTabKey, page, size)
    }

    /** 分页数据（用于更新列表） */
    val pagingData = paging.data

    /**
     * 页面状态（用于控制 StatePage）
     * 只需 combine 1 个参数，PagingData 已包含 refreshError
     */
    val pageState = paging.data.map { data ->
        when {
            data.refreshError != null && data.items.isEmpty() -> PageState.Error(data.refreshError)
            data.items.isEmpty() && data.isLoading -> PageState.Loading
            data.items.isEmpty() -> PageState.Empty
            else -> PageState.Success
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), PageState.Loading)

    fun initDataByTab(tabKey: String) {
        if (tabKey.isBlank()) return
        if (currentTabKey == tabKey) return
        currentTabKey = tabKey
        paging.reset()
    }

    fun refresh() = paging.refresh()
    fun loadMore() = paging.loadMore()
}

/**
 * 页面状态（用于 StatePage 切换）
 *
 * 与 PagingData 分离，由 ViewModel 根据业务逻辑决定
 */
sealed class PageState {
    data object Loading : PageState()
    data object Empty : PageState()
    data class Error(val message: String) : PageState()
    data object Success : PageState()
}
