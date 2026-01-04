package com.androidrtc.chat.modules.basefun.examplerefactor

import com.androidtool.common.base.event.LoadState
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.module.BaseLoadMoreModule
import com.chad.library.adapter.base.viewholder.BaseViewHolder
import com.scwang.smart.refresh.layout.SmartRefreshLayout

/**
 * 分页扩展函数集合
 *
 * 核心设计：
 * - 职责单一：只处理分页数据的列表更新逻辑
 * - 页面状态切换（Loading/Empty/Error）由 Fragment/ViewModel 自行控制
 */

// ============================================================================
// LoadMoreModule 扩展
// ============================================================================

/**
 * 根据 LoadState 更新加载更多模块的状态
 */
fun BaseLoadMoreModule.applyLoadState(loadState: LoadState) {
    isEnableLoadMore = true
    when (loadState) {
        LoadState.LOAD_MORE_COMPLETE -> loadMoreComplete()
        LoadState.LOAD_MORE_END -> loadMoreEnd()
        LoadState.LOAD_MORE_FAIL -> loadMoreFail()
        else -> Unit // REFRESHING, LOADING_MORE 时不处理
    }
}

// ============================================================================
// SmartRefreshLayout 扩展
// ============================================================================

/**
 * 结束所有刷新状态（下拉刷新 + 上拉加载）
 */
fun SmartRefreshLayout.finishAllRefresh() {
    finishRefresh()
    finishLoadMore()
}

// ============================================================================
// Adapter + PagingData 扩展
// ============================================================================

/**
 * 应用分页数据到 Adapter 和 RefreshLayout
 *
 * @param data 分页数据
 * @param refreshLayout 刷新控件（可选）
 */
fun <T, VH : BaseViewHolder> BaseQuickAdapter<T, VH>.applyPagingData(
    data: PagingData<T>,
    refreshLayout: SmartRefreshLayout? = null
) {
    // 加载中状态不更新 UI
    if (data.isLoading) return

    // 结束刷新控件
    refreshLayout?.finishRefresh()

    // 更新列表数据（加载失败时不更新数据，保留原有列表）
    if (!data.isLoadFailed) {
        setList(data.items)
    }

    // 更新加载更多状态
    loadMoreModule.applyLoadState(data.loadState)
}

// ============================================================================
// 兼容旧版 PagingUiState（可选，用于渐进迁移）
// ============================================================================

/**
 * 应用 PagingUiState.Success 到 Adapter（兼容旧版）
 */
fun <T, VH : BaseViewHolder> BaseQuickAdapter<T, VH>.applyPagingSuccess(
    state: PagingUiState.Success<T>,
    refreshLayout: SmartRefreshLayout? = null
) {
    if (state.isLoading) return

    refreshLayout?.finishRefresh()

    if (state.loadState != LoadState.LOAD_MORE_FAIL) {
        setList(state.items)
    }

    loadMoreModule.applyLoadState(state.loadState)
}
