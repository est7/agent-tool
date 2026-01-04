package com.androidrtc.chat.modules.basefun.examplerefactor

import com.androidtool.common.base.event.LoadState

/**
 * 纯粹的分页数据状态
 *
 * 设计要点：
 * - 只关注分页数据本身，不包含页面状态（Loading/Empty/Error）
 * - 页面状态由 ViewModel 根据业务逻辑 combine 决定
 * - 支持复杂场景：页面状态 = f(用户信息, 分页列表, 其他数据...)
 *
 * 简单场景（单接口分页）：
 * ```
 * val uiState = pagingData.map { data ->
 *     when {
 *         data == null -> PageState.Loading
 *         data.items.isEmpty() && !data.isLoading -> PageState.Empty
 *         else -> PageState.Success
 *     }
 * }
 * ```
 *
 * 复杂场景（多接口组合）：
 * ```
 * val pageState = combine(userInfo, pagingData) { user, paging ->
 *     when {
 *         user == null -> PageState.Loading
 *         paging == null -> PageState.Loading
 *         user.isError -> PageState.Error(user.message)
 *         paging.items.isEmpty() && !paging.isLoading -> PageState.Empty
 *         else -> PageState.Success
 *     }
 * }
 * ```
 */
data class PagingData<T>(
    val items: List<T>,
    val loadState: LoadState = LoadState.LOAD_MORE_COMPLETE,
    val page: Int = 1,
    val refreshError: String? = null
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
