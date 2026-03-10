# Layout Specification

Rules for Android XML layout generation: layout selection, dynamic control recognition,
constraint rules, unit conversion, resource extraction, naming, and preview attributes.

---

## 1. Layout Selection Priority

| Priority | Layout | Use case |
|:---------|:-------|:---------|
| 1 | ConstraintLayout | Default root layout and default choice for content regions; use it to flatten hierarchy |
| 2 | LinearLayout | Only for truly simple standalone linear regions, or when the whole container is intrinsically linear and not nested inside another `ConstraintLayout` |
| 3 | FrameLayout | Only for overlays, background decoration, or rare special grouping |
| Forbidden | RelativeLayout | Never use |

---

## 2. Dynamic Control Recognition

Design tool exports are static stacks. Identify the real UI intent:

| Design pattern | Convert to |
|:---------------|:-----------|
| Multiple similar cards, vertical | `RecyclerView (vertical)` + `item_xxx.xml` |
| Multiple similar cards, horizontal | `RecyclerView (horizontal)` |
| Top switchable tabs | `TabLayout` + `ViewPager2` |
| Carousel / Banner | `ViewPager2` + indicator |
| Bottom navigation | `BottomNavigationView` |
| Grid layout | `RecyclerView` + `GridLayoutManager` |
| Pull-to-refresh wrapping a list | `SwipeRefreshLayout` > `RecyclerView` |

**Key rules**:
- Repeated units MUST be extracted into separate `item_xxx.xml`
- Fixed areas (header, notice bar, bottom buttons) stay outside RecyclerView
- Ignore iOS status bar elements (9:41, battery icon, etc.)
- Multi-type lists: each style gets its own `item_xxx_type1.xml`, `item_xxx_type2.xml`

---

## 3. Input Source Trust Rules

The user provides two inputs: a **design screenshot** and **frontend code** (HTML/CSS).
They have fundamentally different trust levels:

### CSS values → TRUST (measurement source)

Extract exact numeric values from CSS properties:

| CSS property | Extract as | Example |
|:-------------|:-----------|:--------|
| `width`, `height`, `margin-*`, `padding-*` | Dimensions (dp) | `margin-top: 12px` → `marginTop="12dp"` |
| `font-size` | Text size (sp) | `font-size: 14px` → `textSize="14sp"` |
| `font-weight` | Text style / font family | `600` → `textStyle="bold"` or `fontFamily="@font/xxx_semibold"` |
| `color`, `background-color`, `rgba(...)` | Color values | `rgba(51,51,51,1)` → `#333333` |
| `border-radius` | Corner radius (dp) | `border-radius: 14px` → `radius="14dp"` |
| `line-height` | Line spacing | `line-height: 20px` → `lineSpacingExtra` |
| `letter-spacing` | Letter spacing | Extract value for `letterSpacing` |

### HTML structure → DO NOT TRUST (misleading)

The HTML `div` nesting from design tools is a flat static export. It does NOT represent:
- Real parent-child relationships between UI components
- Which areas scroll vs which are fixed
- Which repeated blocks should be a RecyclerView
- Conditional visibility or dynamic behavior

### Design screenshot → PRIMARY source for structure

Determine all layout hierarchy, component relationships, and structural decisions by:
1. Visually analyzing the screenshot
2. Applying the dynamic control recognition rules (Section 2 above)
3. Using your own judgment about Android UI patterns

---

## 4. ConstraintLayout Constraint Rules

Every child View must satisfy:
- At least one horizontal constraint (Start or End)
- At least one vertical constraint (Top or Bottom)
- For stretching: use `0dp` + constraints. **Never use `match_parent`**

### Core Principle: Absolute Flattening

The purpose of `ConstraintLayout` is to thin the view hierarchy. Treat it as a flattening tool, not as a drop-in replacement for `RelativeLayout`.

1. Content regions should remain a single flat layer whenever possible. Do not add nested containers unless they are truly required by `ScrollView`, `CardView`, background decoration, or another unavoidable structural need.
2. Inside a `ConstraintLayout`, do not nest meaningless `LinearLayout` or `FrameLayout` containers just to stack views horizontally or vertically.
3. For simple alignment and visibility control, prefer chains, `Group`, `Layer`, `Barrier`, guidelines, and direct anchor relationships between sibling views.
4. If a section needs expand/collapse or "height opens" behavior, implement it by changing constraints / anchors between real content views. Do not wrap the content in an extra `wrap_content` container only to fake the animation.

---

## 5. Title Bar Standardization

Before generating a page header, search the project for reusable title bar components.

- If `com.androidtool.common.widget.TitleBarView` exists, every standard `icon-title-text-icon` child-page title bar MUST use it.
- Do not manually compose a standard title bar with `ImageView` + `TextView` in XML when `TitleBarView` (or the project's equivalent shared title component) is available.
- Only build a custom header when the design is clearly non-standard or no reusable project component exists.

---

## 6. Unit Conversion

| CSS | Android | Notes |
|:----|:--------|:------|
| `width: 343px` | `layout_width="343dp"` | 1px = 1dp |
| `font-size: 14px` | `textSize="14sp"` | Text size uses sp |
| `border-radius: 12px` | shape `radius="12dp"` | Corner radius |
| `rgba(82,89,247,1)` | `#5259F7` | Opaque color |
| `rgba(82,89,247,0.14)` | `#245259F7` | With alpha (ARGB format) |

---

## 7. RTL Compatibility

- Use `marginStart` / `marginEnd` / `paddingStart` / `paddingEnd`
- **Never** use `marginLeft` / `marginRight` / `paddingLeft` / `paddingRight`

---

## 8. Resource Extraction

### 8.1 colors.xml

Extract colors that appear 2+ times. Use **semantic names**:
- `color_primary`, `color_text_secondary`, `color_bg_card`
- Never name by hex value (e.g., `color_5259F7` is forbidden)

### 8.2 dimens.xml

Extract dimensions that appear 2+ times:
- Spacing: `spacing_8`, `spacing_16`, `padding_screen`
- Corner radius: `corner_card`, `corner_button`
- Text size: `text_size_body`, `text_size_title`

### 8.3 Drawable Shapes

Extract rounded corners / gradients / borders into separate files:
- `shape_card_bg.xml`, `shape_btn_primary.xml`

---

## 9. Resource Scoping

Before writing any new XML file, determine the real layout directory convention of the target module.

1. You MUST use `find` to inspect the target module for existing layout directories.
2. Follow the module-local convention exactly, including non-standard scopes such as `res/layouts/main/layout/`.
3. New page layouts, item layouts, and shared view layouts must be written into that discovered scope.
4. If multiple candidate directories exist or nothing matches, stop and ask the user to confirm the target directory.
5. Never assume `res/layout/` by default.

---

## 10. Naming Conventions

### 10.1 File Naming

| Type | Format | Example |
|:-----|:-------|:--------|
| Page | `fragment_xxx.xml` / `activity_xxx.xml` | `fragment_reward_list.xml` |
| List item | `item_xxx.xml` | `item_reward_card.xml` |
| Shared component | `view_xxx.xml` | `view_notice_bar.xml` |

### 10.2 View ID Naming

| Widget | Prefix | Example |
|:-------|:-------|:--------|
| ImageView | `iv_` | `iv_back`, `iv_icon` |
| TextView | `tv_` | `tv_title`, `tv_amount` |
| Button | `btn_` | `btn_submit` |
| RecyclerView | `rv_` | `rv_list` |
| LinearLayout | `ll_` | `ll_badges` |
| ConstraintLayout | `cl_` | `cl_header` |

---

## 11. Preview Attributes (Required)

Every layout must include tools namespace attributes for Android Studio preview:

```xml
xmlns:tools="http://schemas.android.com/tools"

tools:text="Sample text"
tools:src="@tools:sample/avatars"
tools:listitem="@layout/item_xxx"
tools:itemCount="3"
tools:context=".feature.XxxFragment"
tools:visibility="visible"  <!-- pair with android:visibility="gone" -->
```

### RecyclerView Preview Rules

- Every `RecyclerView` MUST include `tools:listitem="@layout/item_xxx"`.
- `tools:itemCount="3"` is the default recommendation unless a different preview count better reflects the design.
- A list without preview attributes is incomplete. Do not leave Android Studio preview as a blank white list.
