package com.androidrtc.chat.modules.basefun.example

import kotlinx.coroutines.delay

class ExamplePagingRepository {

    suspend fun loadPage(tabKey: String, page: Int, pageSize: Int): Result {
        delay(300)

        val safePage = page.coerceAtLeast(1)
        val safePageSize = pageSize.coerceAtLeast(1)

        val hasMore = safePage < MAX_PAGE
        val start = (safePage - 1) * safePageSize + 1
        val items = (start until (start + safePageSize)).map { index ->
            "${tabKey.uppercase()} item $index"
        }

        return Result(items = items, hasMore = hasMore)
    }

    data class Result(
        val items: List<String>,
        val hasMore: Boolean,
    )

    private companion object {
        private const val MAX_PAGE = 5
    }
}

