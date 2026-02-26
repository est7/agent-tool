# MVI Pattern

## Contents

- Contract file structure
- State: StateFlow pattern
- Event: Action dispatch pattern
- Effect: Channel pattern

---

## Contract File Structure

State, Event, and Effect are grouped in a single `OneFeatureContract.kt` file:

```kotlin
/**
 * Contract file for OneFeature
 */

/**
 * UI state — contains all data needed for display
 */
data class OneFeatureState(
    val isLoading: Boolean = false,
    val data: List<String> = emptyList(),
    val error: String? = null,
    val selectedItemId: String? = null
)

/**
 * User intentions or system events that trigger state changes
 */
sealed interface OneFeatureEvent {
    data object LoadData : OneFeatureEvent
    data object RefreshData : OneFeatureEvent
    data class DeleteItem(val itemId: String) : OneFeatureEvent
}

/**
 * One-time side effects (navigation, Toast, Snackbar)
 */
sealed interface OneFeatureEffect {
    data class ShowToast(val message: String) : OneFeatureEffect
    data class ShareContent(val content: String) : OneFeatureEffect
}
```

---

## State: StateFlow Pattern

ViewModel exposes immutable StateFlow; mutates via private MutableStateFlow:

```kotlin
// In ViewModel
private val _state = MutableStateFlow(OneFeatureState())
val state = _state.asStateFlow()

// Update state
_state.value = _state.value.copy(isLoading = true)
```

View layer collects state:

```kotlin
import com.androidtool.common.utils.collectWhenStarted

viewModel.state.collectWhenStarted { state ->
    // render UI based on state
}
```

---

## Event: Action Dispatch Pattern

ViewModel provides an `onAction()` method to handle all events:

```kotlin
// In ViewModel
fun onAction(event: OneFeatureEvent) {
    when (event) {
        is OneFeatureEvent.LoadData -> loadData()
        is OneFeatureEvent.RefreshData -> refresh()
        is OneFeatureEvent.DeleteItem -> deleteItem(event.itemId)
    }
}
```

View layer dispatches events:

```kotlin
binding.refreshButton.onClick {
    viewModel.onAction(OneFeatureEvent.RefreshData)
}

adapter.setOnItemClickListener { _, _, position ->
    val item = adapter.getItem(position)
    viewModel.onAction(OneFeatureEvent.ItemClicked(item))
}
```

---

## Effect: Channel Pattern

Use `Channel` for one-time events (navigation, Toast) to avoid replaying on config changes:

```kotlin
// In ViewModel
private val _effect = Channel<OneFeatureEffect>(Channel.BUFFERED)
val effect = _effect.receiveAsFlow()

fun showToast(message: String) {
    viewModelScope.launch {
        _effect.send(OneFeatureEffect.ShowToast(message))
    }
}
```

View layer collects effects:

```kotlin
import com.androidtool.common.utils.collectWhenStarted

viewModel.effect.collectWhenStarted { effect ->
    when (effect) {
        is OneFeatureEffect.ShowToast ->
            Toast.makeText(context, effect.message, Toast.LENGTH_SHORT).show()
        is OneFeatureEffect.Navigate ->
            findNavController().navigate(effect.destination)
    }
}
```
