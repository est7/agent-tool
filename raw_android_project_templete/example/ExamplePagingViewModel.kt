package com.androidrtc.chat.modules.basefun.example

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.androidtool.common.base.event.LoadState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ExamplePagingViewModel : ViewModel() {

    private val repository = ExamplePagingRepository()

    private var currentTabKey: String = ""
    private var currentPage = 1

    private val _uiState = MutableStateFlow<ExampleListUiState<String>>(ExampleListUiState.Loading)
    val uiState = _uiState.asStateFlow()

    fun initDataByTab(tabKey: String) {
        if (tabKey.isBlank()) return
        if (currentTabKey == tabKey) return
        currentTabKey = tabKey
        currentPage = 1
        _uiState.value = ExampleListUiState.Loading
    }

    fun refresh() {
        currentPage = 1
        loadData(isRefresh = true)
    }

    fun loadMore() {
        val currentState = _uiState.value
        if (currentState is ExampleListUiState.Success &&
            currentState.loadState != LoadState.LOADING_MORE &&
            currentState.loadState != LoadState.LOAD_MORE_END
        ) {
            loadData(isRefresh = false)
        }
    }

    private fun loadData(isRefresh: Boolean) {
        val tabKey = currentTabKey
        if (tabKey.isBlank()) return

        viewModelScope.launch {
            updateLoadingState(isRefresh)
            runCatching { repository.loadPage(tabKey, currentPage, PAGE_SIZE) }
                .onSuccess { result -> handleSuccess(result, isRefresh) }
                .onFailure { throwable -> handleError(throwable, isRefresh) }
        }
    }

    private fun updateLoadingState(isRefresh: Boolean) {
        val currentState = _uiState.value
        if (isRefresh) {
            _uiState.value = if (currentState is ExampleListUiState.Success) {
                currentState.copy(loadState = LoadState.REFRESHING)
            } else {
                ExampleListUiState.Loading
            }
        } else {
            (currentState as? ExampleListUiState.Success)?.let {
                _uiState.value = it.copy(loadState = LoadState.LOADING_MORE)
            }
        }
    }

    private fun handleSuccess(result: ExamplePagingRepository.Result, isRefresh: Boolean) {
        val isLastPage = !result.hasMore
        val loadState = if (isLastPage) LoadState.LOAD_MORE_END else LoadState.LOAD_MORE_COMPLETE

        if (isRefresh) {
            if (result.items.isEmpty()) {
                _uiState.value = ExampleListUiState.Empty
                return
            }
            _uiState.value = ExampleListUiState.Success(
                items = result.items,
                loadState = loadState,
                page = currentPage
            )
        } else {
            val currentState = _uiState.value
            if (currentState is ExampleListUiState.Success) {
                _uiState.value = currentState.copy(
                    items = currentState.items + result.items,
                    loadState = loadState,
                    page = currentPage
                )
            }
        }

        currentPage++
    }

    private fun handleError(throwable: Throwable, isRefresh: Boolean) {
        if (isRefresh) {
            _uiState.value = ExampleListUiState.Error(throwable.message ?: "Unknown error")
        } else {
            val currentState = _uiState.value
            if (currentState is ExampleListUiState.Success) {
                _uiState.value = currentState.copy(loadState = LoadState.LOAD_MORE_FAIL)
            }
        }
    }

    private companion object {
        private const val PAGE_SIZE = 20
    }
}

sealed class ExampleListUiState<out T> {
    data object Loading : ExampleListUiState<Nothing>()
    data object Empty : ExampleListUiState<Nothing>()
    data class Error(val message: String) : ExampleListUiState<Nothing>()

    data class Success<T>(
        val items: List<T>,
        val loadState: LoadState,
        val page: Int,
    ) : ExampleListUiState<T>()
}
