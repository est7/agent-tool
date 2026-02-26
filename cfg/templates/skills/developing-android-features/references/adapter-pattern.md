# Adapter Pattern

BRVAH v3.x (BaseRecyclerViewAdapterHelper) adapter conventions.

---

## Simple List Adapter

```kotlin
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.module.LoadMoreModule
import com.chad.library.adapter.base.viewholder.BaseViewHolder

class SampleLoadMoreAdapter :
    BaseQuickAdapter<SampleUserInfo, BaseViewHolder>(R.layout.item_sample_user),
    LoadMoreModule {

    override fun convert(holder: BaseViewHolder, item: SampleUserInfo) {
        holder.setText(R.id.tvName, item.name)
        holder.setText(R.id.tvAge, "Age: ${item.age}")
        holder.getView<View>(R.id.btnAction).setOnClickListener {
            Toast.makeText(context, "Clicked ${item.name}", Toast.LENGTH_SHORT).show()
        }
    }
}
```

---

## Multi-type Adapter

```kotlin
import com.chad.library.adapter.base.BaseMultiItemQuickAdapter
import com.chad.library.adapter.base.viewholder.BaseViewHolder

class InterestTagAdapter(
    private val onChosen: (List<InterestTagShowBean>) -> Unit
) : BaseMultiItemQuickAdapter<InterestTagShowBean, BaseViewHolder>() {

    init {
        addItemType(TYPE_HEADER, R.layout.item_header)
        addItemType(TYPE_CONTENT, R.layout.item_content)
    }

    override fun convert(holder: BaseViewHolder, item: InterestTagShowBean) {
        when (holder.itemViewType) {
            TYPE_HEADER -> { /* bind header */ }
            TYPE_CONTENT -> { /* bind content */ }
        }
    }
}
```

---

## LoadMore Module Setup

```kotlin
adapter.loadMoreModule.apply {
    isAutoLoadMore = true
    isEnableLoadMoreIfNotFullPage = false
    setOnLoadMoreListener { viewModel.loadMore() }
}

// In success handler:
adapter.loadMoreModule.loadMoreComplete()  // more data available
adapter.loadMoreModule.loadMoreEnd()       // no more data
adapter.loadMoreModule.loadMoreFail()      // load failed
```
