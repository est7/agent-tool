# TabLayout + ViewPager2 Template

## Contents

- Layout XML
- Fragment with TabLayoutMediator
- FragmentStateAdapter (PagerAdapter)
- ViewModel with category loading
- UiState sealed class

**Low freedom**: This is a complete template — follow it precisely when implementing
TabLayout with ViewPager2.

---

## Layout XML

`fragment_sample_dynamic_tab.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.google.android.material.tabs.TabLayout
        android:id="@+id/tabLayout"
        style="@style/SampleDynamicTabLayout"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginHorizontal="16dp"
        android:layout_marginTop="8dp"
        android:layout_marginBottom="8dp"
        android:background="@android:color/transparent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:tabGravity="start" />

    <androidx.viewpager2.widget.ViewPager2
        android:id="@+id/viewPager"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/tabLayout" />

</androidx.constraintlayout.widget.ConstraintLayout>
```

---

## Fragment Implementation

```kotlin
import com.androidtool.common.base.BaseBindingFragment
import com.androidtool.common.base.page.EmptyPage
import com.androidtool.common.base.page.ErrorPage
import com.androidtool.common.base.page.LoadingPage
import com.androidtool.common.utils.collectWhenStarted
import com.google.android.material.tabs.TabLayoutMediator

class SampleDynamicTabFragment : BaseBindingFragment<FragmentSampleDynamicTabBinding>() {
    private val viewModel: SampleDynamicTabViewModel by viewModels()
    private var tabLayoutMediator: TabLayoutMediator? = null

    override fun registerState(): View? = binding.root

    override fun initView() {
        observeData()
        viewModel.loadData()
    }

    private fun observeData() {
        viewModel.uiState.collectWhenStarted {
            when (it) {
                SampleCategoryUiState.Loading -> showState<LoadingPage>()
                SampleCategoryUiState.Empty -> showState<EmptyPage>()
                is SampleCategoryUiState.Error -> showState<ErrorPage>()
                is SampleCategoryUiState.Success -> {
                    showSuccess()
                    initTabLayoutAndViewPager(it.items)
                }
            }
        }
    }

    private fun initTabLayoutAndViewPager(categories: List<SampleTabCategory>) {
        val pagerAdapter = SampleTabPagerAdapter(this, categories)
        binding.viewPager.adapter = pagerAdapter

        tabLayoutMediator?.detach()
        tabLayoutMediator = TabLayoutMediator(
            binding.tabLayout, binding.viewPager
        ) { tab, position ->
            tab.text = categories[position].name
        }.apply { attach() }

        if (categories.isNotEmpty()) {
            binding.viewPager.setCurrentItem(0, false)
        }
    }

    override fun onDestroy() {
        tabLayoutMediator?.detach()
        tabLayoutMediator = null
        super.onDestroy()
    }
}
```

---

## PagerAdapter (FragmentStateAdapter)

```kotlin
import androidx.fragment.app.Fragment
import androidx.viewpager2.adapter.FragmentStateAdapter

class SampleTabPagerAdapter(
    fragment: Fragment,
    private val categories: List<SampleTabCategory>
) : FragmentStateAdapter(fragment) {

    override fun getItemCount(): Int = categories.size

    override fun createFragment(position: Int): Fragment {
        val category = categories[position]
        // Create sub-fragment based on category
        return SampleLoadMoreFragment.newInstance(category.id)
    }
}
```

---

## ViewModel

```kotlin
class SampleDynamicTabViewModel : ViewModel() {
    private val repository = SampleRepository.getSingleInstance()

    private val _uiState =
        MutableStateFlow<SampleCategoryUiState<SampleTabCategory>>(SampleCategoryUiState.Loading)
    val uiState = _uiState.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            _uiState.value = SampleCategoryUiState.Loading
            repository.loadTabList()
                .catch { exception -> handleError(exception) }
                .collect { result ->
                    result.fold(
                        onSuccess = { data -> handleSuccess(data) },
                        onFailure = { exception -> handleError(exception) }
                    )
                }
        }
    }

    private fun handleSuccess(data: List<SampleTabCategory>) {
        _uiState.value = if (data.isEmpty()) {
            SampleCategoryUiState.Empty
        } else {
            SampleCategoryUiState.Success(items = data)
        }
    }

    private fun handleError(exception: Throwable) {
        _uiState.value = SampleCategoryUiState.Error(exception.message ?: "Unknown error")
    }
}
```

---

## UiState Sealed Class

```kotlin
sealed class SampleCategoryUiState<out T> {
    data object Loading : SampleCategoryUiState<Nothing>()
    data object Empty : SampleCategoryUiState<Nothing>()

    data class Success<T>(
        val items: List<T> = emptyList()
    ) : SampleCategoryUiState<T>()

    data class Error(val message: String) : SampleCategoryUiState<Nothing>()
}
```
