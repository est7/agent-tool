# Project Structure

Feature directory layout and layer constraints.

---

## Feature Directory Layout

```
app/src/main/java/com/package/one_feature/
├── data/
│   ├── repository/
│   │   └── OneFeatureRepositoryImpl.kt
│   ├── datasource/ (optional)
│   │   ├── local/
│   │   │   ├── OneFeatureDao.kt
│   │   │   └── OneFeatureDatabase.kt
│   │   └── remote/
│   │       └── OneFeatureApiService.kt
│   ├── model/
│   │   ├── OneFeatureEntity.kt
│   │   └── OneFeatureResponse.kt
│   └── mapper/ (optional)
│       └── OneFeatureMapper.kt
├── di/ (optional)
│   └── OneFeatureModule.kt
├── ui/
│   ├── fragment/
│   │   ├── OneFeatureFragment.kt
│   │   ├── OneFeatureListAdapter.kt
│   │   ├── OneFeatureSubListViewModel.kt
│   │   └── OneFeatureListContract.kt
│   ├── view/ (optional)
│   │   ├── CustomViews.kt
│   │   └── OneFeatureItemView.kt
│   ├── OneFeatureListContract.kt
│   ├── OneFeatureActivity.kt
│   └── OneFeatureViewModel.kt
└── domain/ (optional)
      ├── usecase/
      │   ├── GetOneFeatureUseCase.kt
      │   └── UpdateOneFeatureUseCase.kt
      ├── repository/
      │   └── IOneFeatureRepository.kt
      └── model/
            └── OneFeatureModel.kt
```

---

## Layer Constraints

1. **No DI framework** — Due to project constraints, do not use any dependency injection tools.
2. **No usecase layer** unless explicitly requested — Repository can be called directly from ViewModel.
3. **No mapper** unless explicitly requested — Use response models directly.
4. **No datasource split** unless explicitly requested — Use `OneFeatureApiService` with Retrofit suspend directly.
5. **Repository interface** not required — `OneFeatureRepositoryImpl` does not need an `IOneFeatureRepository` interface.
6. **Backend types**: If backend response types are provided, use them for ApiService. Otherwise define a `SampleBean` placeholder.
7. **Package path**: If user provides a specific package path, replace `com/package/one_feature` accordingly.
