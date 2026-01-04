package com.androidrtc.chat.modules.basefun.example

import android.os.Bundle
import android.view.View
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.androidrtc.chat.databinding.FragmentExamplePagingListBinding
import com.androidtool.common.base.BaseBindingFragment
import com.androidtool.common.base.event.LoadState
import com.androidtool.common.base.page.EmptyPage
import com.androidtool.common.base.page.ErrorPage
import com.androidtool.common.base.page.LoadingPage
import com.androidtool.common.utils.collectWhenStarted

class ExamplePagingListFragment : BaseBindingFragment<FragmentExamplePagingListBinding>() {

    private val viewModel by viewModels<ExamplePagingViewModel>()
    private val adapter by lazy { ExamplePagingAdapter() }

    override fun registerState(): View = binding.recyclerView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tabKey = arguments?.getString(ARG_TAB_KEY).orEmpty().ifBlank { DEFAULT_TAB_KEY }
        viewModel.initDataByTab(tabKey)
    }

    override fun initView() {
        setupRefreshLayout()
        setupRecyclerView()
        observeUiState()
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

    private fun observeUiState() {
        with(viewLifecycleOwner) {
            viewModel.uiState.collectWhenStarted { state ->
                when (state) {
                    is ExampleListUiState.Loading -> showState<LoadingPage>()
                    is ExampleListUiState.Empty -> {
                        binding.refreshLayout.finishRefresh()
                        showState<EmptyPage>()
                    }

                    is ExampleListUiState.Error -> {
                        binding.refreshLayout.finishRefresh()
                        showState<ErrorPage>()
                    }

                    is ExampleListUiState.Success -> {
                        showSuccess()
                        handleSuccessState(state)
                    }
                }
            }
        }
    }

    private fun handleSuccessState(state: ExampleListUiState.Success<String>) {
        when (state.loadState) {
            LoadState.REFRESHING,
            LoadState.LOADING_MORE -> Unit

            LoadState.LOAD_MORE_COMPLETE -> {
                binding.refreshLayout.finishRefresh()
                adapter.setList(state.items)
                adapter.loadMoreModule.isEnableLoadMore = true
                adapter.loadMoreModule.loadMoreComplete()
            }

            LoadState.LOAD_MORE_END -> {
                binding.refreshLayout.finishRefresh()
                adapter.setList(state.items)
                adapter.loadMoreModule.isEnableLoadMore = true
                adapter.loadMoreModule.loadMoreEnd()
            }

            LoadState.LOAD_MORE_FAIL -> {
                binding.refreshLayout.finishRefresh()
                adapter.loadMoreModule.isEnableLoadMore = true
                adapter.loadMoreModule.loadMoreFail()
            }
        }
    }

    companion object {
        private const val ARG_TAB_KEY = "tab_key"
        private const val DEFAULT_TAB_KEY = "left"

        fun newInstance(tabKey: String) = ExamplePagingListFragment().apply {
            arguments = Bundle().apply { putString(ARG_TAB_KEY, tabKey) }
        }
    }
}
