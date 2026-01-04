package com.androidrtc.chat.modules.basefun.examplerefactor

import com.androidrtc.chat.R
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.module.LoadMoreModule
import com.chad.library.adapter.base.viewholder.BaseViewHolder

/**
 * 重构后的示例 Adapter
 *
 * 与原版相同，无需修改
 * Adapter 层不涉及状态管理逻辑
 */
class RefactoredPagingAdapter :
    BaseQuickAdapter<String, BaseViewHolder>(R.layout.item_example_paging_text),
    LoadMoreModule {

    override fun convert(holder: BaseViewHolder, item: String) {
        holder.setText(R.id.tvTitle, item)
    }
}
