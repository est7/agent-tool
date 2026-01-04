package com.androidrtc.chat.modules.basefun.examplerefactor

import android.os.Bundle
import android.view.View
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.androidrtc.chat.databinding.FragmentExamplePagingListBinding
import com.androidtool.common.base.BaseBindingFragment
import com.androidtool.common.base.page.EmptyPage
import com.androidtool.common.base.page.ErrorPage
import com.androidtool.common.base.page.LoadingPage
import com.androidtool.common.utils.collectWhenStarted

/**
 * 重构后的示例 Fragment（松耦合版本）
 *
 * 设计要点：
 * - 分离两个数据流：pageState（页面状态）+ pagingData（列表数据）
 * - 页面状态由 ViewModel combine 决定，Fragment 只负责渲染
 * - 支持复杂场景扩展（多接口组合）
 */
class RefactoredPagingFragment : BaseBindingFragment<FragmentExamplePagingListBinding>() {

    private val viewModel by viewModels<RefactoredPagingViewModel>()
    private val adapter by lazy { RefactoredPagingAdapter() }

    override fun registerState(): View = binding.recyclerView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tabKey = arguments?.getString(ARG_TAB_KEY).orEmpty().ifBlank { DEFAULT_TAB_KEY }
        viewModel.initDataByTab(tabKey)
    }

    override fun initView() {
        setupRefreshLayout()
        setupRecyclerView()
        observeState()
    }

    override fun onLazyLoad() {
        viewModel.refresh()
    }

    private fun setupRefreshLayout() {
        binding.refreshLayout.setEnableLoadMore(false)
        binding.refreshLayout.setOnRefreshListener {
            adapter.loadMoreModule.isEnableLoadMore = false
            viewModel.refresh()
        }
    }

    private fun setupRecyclerView() {
        binding.recyclerView.layoutManager = LinearLayoutManager(context)
        binding.recyclerView.adapter = adapter
        adapter.loadMoreModule.apply {
            isAutoLoadMore = true
            isEnableLoadMoreIfNotFullPage = false
            setOnLoadMoreListener { viewModel.loadMore() }
        }
    }

    /**
     * 观察状态
     *
     * 分离两个数据流：
     * 1. pageState - 控制 StatePage（Loading/Empty/Error/Success）
     * 2. pagingData - 更新列表数据
     */
    private fun observeState() {
        with(viewLifecycleOwner) {
            // 观察页面状态 -> 控制 StatePage
            viewModel.pageState.collectWhenStarted { state ->
                when (state) {
                    is PageState.Loading -> showState<LoadingPage>()
                    is PageState.Empty -> {
                        binding.refreshLayout.finishRefresh()
                        showState<EmptyPage>()
                    }
                    is PageState.Error -> {
                        binding.refreshLayout.finishRefresh()
                        showState<ErrorPage>()
                    }
                    is PageState.Success -> showSuccess()
                }
            }

            // 观察分页数据 -> 更新列表
            viewModel.pagingData.collectWhenStarted { data ->
                adapter.applyPagingData(data, binding.refreshLayout)
            }
        }
    }

    companion object {
        private const val ARG_TAB_KEY = "tab_key"
        private const val DEFAULT_TAB_KEY = "left"

        fun newInstance(tabKey: String) = RefactoredPagingFragment().apply {
            arguments = Bundle().apply { putString(ARG_TAB_KEY, tabKey) }
        }
    }
}
