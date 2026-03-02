# Project Existing Resources

Catalog of reusable resources already in the project.
**Always prefer these over creating new ones.** Only create a new resource when no existing one matches.

---

## 1. Drawable Shapes (Rounded Corners / Backgrounds)

Common shape drawables already defined in the project. Reuse by referencing `@drawable/xxx`.

<!-- TODO: Fill in your project's existing shape drawables -->

| Drawable name | Description | Corners | Color / Gradient | Usage example |
|:--------------|:------------|:--------|:-----------------|:--------------|
| `shape_card_bg` | White card background | 12dp all | `#FFFFFF` | Card containers |
| `shape_btn_primary` | Primary button background | 8dp all | `#5259F7` | Action buttons |
| <!-- add more rows --> | | | | |

---

## 2. Common Icons

Vector / PNG icons already in the project. Reuse by referencing `@drawable/xxx` or `@mipmap/xxx`.

<!-- TODO: Fill in your project's existing icons -->

| Icon name | Description | Usage |
|:----------|:------------|:------|
| `ic_arrow_back` | Back arrow (toolbar) | Navigation back button |
| `ic_arrow_right` | Right chevron | List item disclosure |
| `ic_close` | Close / dismiss | Dialog close button |
| <!-- add more rows --> | | |

---

## 3. Common Colors

Colors already defined in `colors.xml`. Reuse by referencing `@color/xxx`.

<!-- TODO: Fill in your project's existing color palette -->

| Color name | Hex value | Usage |
|:-----------|:----------|:------|
| `color_primary` | `#5259F7` | Primary brand color |
| `color_text_primary` | `#333333` | Main text color |
| `color_text_secondary` | `#999999` | Secondary / hint text |
| `color_bg_page` | `#F6F6F6` | Page background |
| `color_divider` | `#EEEEEE` | Divider lines |
| <!-- add more rows --> | | |

---

## 4. Common Dimens

Dimensions already defined in `dimens.xml`. Reuse by referencing `@dimen/xxx`.

<!-- TODO: Fill in your project's existing dimension tokens -->

| Dimen name | Value | Usage |
|:-----------|:------|:------|
| `padding_screen` | `16dp` | Horizontal screen padding |
| `spacing_8` | `8dp` | Small spacing |
| `spacing_16` | `16dp` | Standard spacing |
| `corner_card` | `12dp` | Card corner radius |
| <!-- add more rows --> | | |

---

## 5. Common Text Styles

Text appearance styles defined in `styles.xml`. Use via `android:textAppearance="@style/xxx"`.

<!-- TODO: Fill in your project's existing text styles, or delete this section if not using text styles -->

| Style name | Size | Weight | Color | Usage |
|:-----------|:-----|:-------|:------|:------|
| <!-- add rows --> | | | | |

---

## Usage Rules

1. **Before creating any new drawable**: scan this list for an existing match
2. **Before defining a new color**: check if the hex value already exists here under a different name
3. **Partial match is OK**: if `shape_card_bg` has 12dp corners but you need 14dp, create a new one — but note it in the output
4. **Report reuse**: in the generated XML, add a comment when reusing an existing resource: `<!-- reuse: shape_card_bg -->`
