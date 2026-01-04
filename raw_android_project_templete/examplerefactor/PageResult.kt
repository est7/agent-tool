package com.androidrtc.chat.modules.basefun.examplerefactor

/**
 * 分页请求结果
 *
 * 用于 Repository 层返回分页数据给 ViewModel
 *
 * @param items 当前页的数据列表
 * @param hasMore 是否还有更多数据
 */
data class PageResult<T>(
    val items: List<T>,
    val hasMore: Boolean
)
