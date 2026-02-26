# Network Layer

Repository → ViewModel → ApiService patterns.

---

## Repository Layer

```kotlin
import com.androidtool.common.extension.asResult
import com.androidtool.common.extension.requestToFlow

class OneFeatureRepository {
    private val apiService = /* retrofit instance */

    fun loadData(): Flow<Result<DataModel>> {
        return requestToFlow { apiService.fetchData() }.asResult()
    }

    fun loadDataById(id: String, page: Int): Flow<Result<List<DataModel>>> {
        return requestToFlow {
            apiService.fetchDataById(mapOf("id" to id, "page" to page.toString()))
        }.asResult()
    }
}
```

---

## ViewModel Layer

```kotlin
fun loadData() {
    viewModelScope.launch {
        _state.value = _state.value.copy(isLoading = true)
        repository.loadData()
            .catch { exception -> handleError(exception) }
            .collect { result ->
                result.fold(
                    onSuccess = { data -> handleSuccess(data) },
                    onFailure = { exception -> handleError(exception) }
                )
            }
    }
}
```

---

## ApiService Definition

```kotlin
import com.androidtool.common.troll.BaseResponse
import com.androidtool.common.net.Apis

interface OneFeatureApiService {
    // Simple GET
    @GET(Apis.ENDPOINT_DATA)
    suspend fun fetchData(): BaseResponse<DataModel>

    // GET with query params (always use Map)
    @GET(Apis.ENDPOINT_DATA_LIST)
    suspend fun fetchDataById(
        @QueryMap map: Map<String, String>
    ): BaseResponse<List<DataModel>>
}
```

**Key conventions:**

- All API responses are wrapped in `BaseResponse<T>`
- All request parameters use `@QueryMap Map<String, String>`
- Endpoint constants are defined in `Apis.ENDPOINT_*`
- All API methods are `suspend` functions
