package com.androidrtc.chat.modules.basefun.examplerefactor

/**
 * 普通场景通用 UI 状态（非分页，单数据）
 *
 * 适用于：
 * - 详情页加载
 * - 单接口请求
 * - 不需要分页的数据展示
 *
 * 使用示例：
 * ```
 * private val _uiState = MutableStateFlow<SimpleUiState<UserInfo>>(SimpleUiState.Loading)
 * val uiState = _uiState.asStateFlow()
 * ```
 */
sealed class SimpleUiState<out T> {

    /**
     * 加载中状态
     */
    data object Loading : SimpleUiState<Nothing>()

    /**
     * 空数据状态
     */
    data object Empty : SimpleUiState<Nothing>()

    /**
     * 错误状态
     */
    data class Error(val message: String) : SimpleUiState<Nothing>()

    /**
     * 成功状态
     */
    data class Success<T>(val data: T) : SimpleUiState<T>()
}
