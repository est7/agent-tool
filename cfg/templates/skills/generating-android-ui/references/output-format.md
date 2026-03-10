# Output Format

Strict output structure for Android UI generation results.
Follow this order exactly. Do not omit or reorder sections.

---

## Part 1: Page Structure Analysis

Summarize in 3-5 lines:
- Overall page hierarchy
- Fixed regions vs dynamic regions
- Core components used

Then provide a region table:

| Region | Component | Description |
|:-------|:----------|:------------|
| Top navigation | TitleBarView | Standard child-page title bar |
| Notice bar | ConstraintLayout | Conditional display |
| Main list | RecyclerView | Data list |

---

## Part 2: File List

```
<discovered-layout-dir>/fragment_xxx.xml  # Main page
<discovered-layout-dir>/item_xxx.xml      # List item
res/drawable/shape_xxx.xml           # Background shape
res/values/colors.xml (snippet)
res/values/dimens.xml (snippet)
```

---

## Part 3: Complete XML Code

Output each file in order from the file list. Each file in its own code block:

```xml
<!-- res/drawable/shape_xxx.xml -->
<?xml version="1.0" encoding="utf-8"?>
<shape>...</shape>
```

### 1-to-2 mode specifics

- Output the **complete modified XML** (not a diff)
- Wrap added sections with comment pairs:
  ```xml
  <!-- NEW: description of added region -->
  ...new views...
  <!-- /NEW -->
  ```
- Preserve all existing attributes and IDs unchanged
- New resource names must not conflict with existing ones

---

## Part 4: Functional PRD

### 4.1 Page Overview

```markdown
**Page name**: xxx
**Entry point**: Where users navigate from
**Responsibility**: Core function in one sentence
```

### 4.2 Region Descriptions

Describe each region:
- Display conditions (when shown/hidden)
- Contained elements
- Data source

### 4.3 Interaction Behavior

Describe per interactive control:
- Click behavior
- Success / failure handling
- State changes

### 4.4 Data Display Logic

- Data source for each field
- Display rules (line limits, ellipsis, default values)
- Image loading fallback

### 4.5 Page States

| State | Trigger | Display |
|:------|:--------|:--------|
| Loading | First entry | Skeleton / Loading |
| Normal | Data loaded | List content |
| Empty | List is empty | Empty state image + text |
| Error | Request failed | Error message + retry |

### 4.6 Layout-to-Function Mapping

| View ID | Function |
|:--------|:---------|
| `titleBar` | Standard title bar / back navigation |
| `rv_list` | Data list |

---

## Prohibited Items

This skill **must NOT output**:
- Kotlin / Java code
- Adapter / ViewHolder / ViewModel implementations
- Data model definitions
- Any code-level implementation suggestions
- Jetpack Compose code
- Absolute positioning layouts (no CSS `position: absolute` simulation)

---

## Completion Signal

End output with:

```
---
Done: XML layouts + functional PRD
Files: [number of files]
Next: Review XML manually, then proceed to code implementation phase
```
