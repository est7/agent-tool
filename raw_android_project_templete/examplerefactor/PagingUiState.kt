package com.androidrtc.chat.modules.basefun.examplerefactor

import com.androidtool.common.base.event.LoadState

/**
 * 分页场景通用 UI 状态
 *
 * 设计要点：
 * 1. LoadState 作为 Success 的属性，而非独立状态
 * 2. 增加 isLoading / hasMore 便捷属性
 * 3. 泛型协变 out T 支持类型灵活性
 *
 * 使用示例：
 * ```
 * private val _uiState = MutableStateFlow<PagingUiState<String>>(PagingUiState.Loading)
 * val uiState = _uiState.asStateFlow()
 * ```
 */
sealed class PagingUiState<out T> {

    /**
     * 初始加载中状态
     * 用于首次进入页面时显示全屏 Loading
     */
    data object Loading : PagingUiState<Nothing>()

    /**
     * 空数据状态
     * 用于刷新后列表为空时显示空页面
     */
    data object Empty : PagingUiState<Nothing>()

    /**
     * 错误状态
     * 用于刷新失败时显示错误页面
     */
    data class Error(val message: String) : PagingUiState<Nothing>()

    /**
     * 成功状态（包含分页加载状态）
     *
     * @param items 当前列表数据
     * @param loadState 加载状态（刷新中/加载更多中/加载完成/没有更多/加载失败）
     * @param page 当前页码
     */
    data class Success<T>(
        val items: List<T>,
        val loadState: LoadState = LoadState.LOAD_MORE_COMPLETE,
        val page: Int = 1
    ) : PagingUiState<T>() {

        /**
         * 是否正在加载中（刷新或加载更多）
         * 用于判断是否需要更新 UI
         */
        val isLoading: Boolean
            get() = loadState == LoadState.REFRESHING || loadState == LoadState.LOADING_MORE

        /**
         * 是否还有更多数据
         * 用于判断是否允许触发加载更多
         */
        val hasMore: Boolean
            get() = loadState != LoadState.LOAD_MORE_END
    }
}
