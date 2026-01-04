package com.androidrtc.chat.modules.basefun.examplerefactor

import kotlinx.coroutines.delay

/**
 * 重构后的示例 Repository
 *
 * 变化点：
 * - 返回类型从自定义 Result 改为通用 PageResult<T>
 *
 * Before:
 * ```
 * data class Result(val items: List<String>, val hasMore: Boolean)
 * suspend fun loadPage(...): Result
 * ```
 *
 * After:
 * ```
 * suspend fun loadPage(...): PageResult<String>
 * ```
 */
class RefactoredPagingRepository {

    /**
     * 模拟分页加载
     *
     * @param tabKey 标签键（用于区分不同 Tab 的数据）
     * @param page 页码（从 1 开始）
     * @param pageSize 每页数据量
     * @return 分页结果
     */
    suspend fun loadPage(tabKey: String, page: Int, pageSize: Int): PageResult<String> {
        // 模拟网络延迟
        delay(300)

        val safePage = page.coerceAtLeast(1)
        val safePageSize = pageSize.coerceAtLeast(1)

        // 模拟分页逻辑：5 页后无更多数据
        val hasMore = safePage < MAX_PAGE
        val start = (safePage - 1) * safePageSize + 1
        val items = (start until (start + safePageSize)).map { index ->
            "${tabKey.uppercase()} item $index"
        }

        return PageResult(items = items, hasMore = hasMore)
    }

    private companion object {
        private const val MAX_PAGE = 5
    }
}
