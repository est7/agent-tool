package com.androidrtc.chat.modules.basefun.example

import com.androidrtc.chat.R
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.module.LoadMoreModule
import com.chad.library.adapter.base.viewholder.BaseViewHolder

class ExamplePagingAdapter :
    BaseQuickAdapter<String, BaseViewHolder>(R.layout.item_example_paging_text),
    LoadMoreModule {

    override fun convert(holder: BaseViewHolder, item: String) {
        holder.setText(R.id.tvTitle, item)
    }
}

