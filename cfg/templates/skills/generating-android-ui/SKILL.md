---
name: generating-android-ui
description: >-
  Converts design screenshots and frontend code (HTML/CSS/React) into production
  Android XML layouts with functional PRD. Supports both new page creation (0-to-1)
  and extending existing pages (1-to-2). Use when the user provides design mockups,
  Figma exports, or asks to create/modify Android XML layouts from design specs.
context: fork
---

# Android UI Generation

Converts Figma / design tool exports into production-grade Android XML layouts + functional PRD.

> [ABSOLUTE BAN] This skill must never generate Kotlin/Java files (`Activity`, `Fragment`, `Adapter`, or any other logic class). Even when the user says "implement this feature", the deliverable is limited to XML layouts plus the matching PRD/interaction notes.

**Boundary**: XML layouts + PRD only. No Kotlin/Java code, no Compose, no implementation suggestions.

---

## Workflow

Execute these phases **strictly in order**. Do not skip, merge, or reorder them.

### Phase 0: Project Convention Discovery

Before interpreting the page structure, discover the target project's conventions first. This phase is mandatory for both `0-to-1` and `1-to-2` work.

You MUST inspect the target module / existing page context and lock down these four items:

1. **Layout directory convention**: use `find` to locate the real layout scope for the module, including non-standard paths such as `res/layouts/main/layout/`
2. **Shared title bar component**: search for `TitleBarView` or the module's equivalent shared header widget before planning a custom title bar
3. **Reusable resources**: inspect existing colors, dimens, drawables, and common icons before deciding to create new ones
4. **Naming conventions**: inspect existing layout file names, `item_*.xml` names, and common ID prefixes used in the module

Output of this phase is a short internal checklist for yourself:
- Which layout directory will receive new XML files
- Whether `TitleBarView` (or an equivalent shared title bar) is mandatory
- Which resources must be reused
- Which naming pattern the new files and IDs must follow

### Phase 1: Mode Detection & Input Collection

Ask the user which mode applies:

| Mode | Description | Required inputs |
|:-----|:------------|:----------------|
| **0-to-1** (New page) | Create a brand-new page from scratch | 1) Design screenshot 2) Frontend code (HTML/CSS/React) 3) Optional: interaction notes, existing colors.xml / dimens.xml |
| **1-to-2** (Extend page) | Add new regions to an existing page | All of the above, plus: 4) Existing XML layout file path 5) Existing Kotlin/Java file path |

**0-to-1 mode: Resolve target module path**

In 0-to-1 mode, there is no existing file to anchor to. You do NOT know which module or package the new page belongs to. You MUST use AskUserQuestion to ask:

1. Target module (e.g., `app`, `feature-order`, `module-home`)
2. Page name hint (e.g., "reward list", "message detail") — used for file naming

After the target module is confirmed, you MUST inspect that module with `find` before generating any XML:

1. Search for existing layout resource directories in the target module
2. Follow the module's existing resource scoping convention exactly
3. If the module uses a non-standard path such as `res/layouts/main/layout/`, write new files there
4. If the results are ambiguous or no layout directory exists yet, ask the user to confirm the exact target directory

Do NOT guess or assume the module path. Do NOT default to `res/layout/`. Do NOT write files until the layout directory convention is verified.

**1-to-2 mode**: The user provides the existing file path, so the target location is already known. Any new `item_*.xml` or `view_*.xml` files must follow the same module-local layout directory convention as the existing page.

**Critical: Understanding the frontend code**

The HTML/CSS/React code from design tools (Lanhu, Figma, etc.) is a **static flat export**.
It does NOT reflect real UI relationships — no parent-child hierarchy, no scroll regions, no dynamic controls.

Use it for **two things only**:
1. **Exact measurements**: extract px values for dimensions, margins, padding, font sizes, border-radius from CSS
2. **Exact colors**: extract rgba/hex color values from CSS

Do NOT use it for:
- Layout structure or nesting (the HTML `div` hierarchy is meaningless)
- Component type decisions (what should be RecyclerView, TabLayout, etc.)
- View relationships (which views are siblings vs parent-child)

**Layout structure and component relationships** must come from:
1. The design screenshot (primary source of truth for visual hierarchy)
2. Your own judgment applying the dynamic control recognition rules in `references/layout-spec.md`
3. The user's interaction notes (if provided)

**For 1-to-2 mode**: Read the existing XML and code files first. Understand:
- Current layout hierarchy and View IDs
- Which regions are fixed vs scrollable
- Naming patterns already in use (ID prefixes, resource naming)

Do not start ASCII layout confirmation until Phase 0 and Phase 1 are both complete.

### Phase 2: ASCII Layout Confirmation (MANDATORY)

**This phase is BLOCKING. Do not proceed to Phase 3 until the user explicitly confirms.**

Before generating any XML, draw an ASCII diagram using box-drawing characters that shows the complete layout hierarchy.

#### Required elements

- **Root box**: labeled with target file name (e.g., `fragment_xxx.xml`)
- **Nested boxes**: for each region, showing component type
- **Tags on each region**:
  - `[FIXED]` for non-scrollable areas
  - `[SCROLL, vertical]` or `[SCROLL, horizontal]` for scrollable areas
  - `[GONE]` for conditionally visible areas (with trigger condition)
- **View IDs**: shown in `[brackets]` next to each component
- **Item layouts**: drawn as separate nested boxes labeled `item_xxx.xml`

#### 1-to-2 mode additions

- `[NEW]` tag on all added regions
- Existing regions show `...existing...` as placeholder content
- Preserve existing View IDs exactly

#### Example (0-to-1 mode)

```
┌─ fragment_reward_list.xml ──────────────────────────────┐
│                                                          │
│  ┌─ TitleBarView [titleBar] ───────── [FIXED] ────────┐ │
│  │  Standard child-page title bar                     │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─ ConstraintLayout [cl_notice] ─ [FIXED] [GONE] ───┐ │
│  │  ImageView [iv_notice_icon]  TextView [tv_notice]   │ │
│  │  Condition: show when hasNotice == true              │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─ RecyclerView [rv_rewards] ── [SCROLL, vertical] ──┐ │
│  │                                                     │ │
│  │  ┌─ item_reward_card.xml ────────────────────────┐  │ │
│  │  │  ImageView [iv_icon]                          │  │ │
│  │  │  TextView [tv_name]   TextView [tv_points]    │  │ │
│  │  └───────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─ Button [btn_redeem] ─────────── [FIXED] ──────────┐ │
│  │  "Redeem"                                           │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

#### Confirmation protocol

1. Present the ASCII diagram
2. Ask: "Please confirm the layout structure, or describe what changes are needed."
3. If user requests changes → redraw and re-confirm
4. Only after explicit user approval → proceed to the Pre-Generate Checklist

### Pre-Generate Checklist (BLOCKING)

After the user confirms the ASCII layout and before writing any XML, verify all of the following:

- `TitleBarView` check: if the page uses a standard `icon-title-text-icon` child-page header and the project contains `com.androidtool.common.widget.TitleBarView` (or equivalent shared title bar), the layout uses that shared component instead of a hand-built header
- Flattening check: no meaningless nested `LinearLayout` / `FrameLayout` containers remain inside `ConstraintLayout`
- RecyclerView preview check: every `RecyclerView` includes `tools:listitem="@layout/item_xxx"` and preferably `tools:itemCount="3"`
- Resource reuse check: colors, dimens, drawables, and icons have been matched against existing project resources before creating new ones
- Layout directory check: the real module layout directory has been confirmed with `find`; nothing will be written to a guessed default path
- Boundary check: the output remains XML + PRD only, with no Kotlin/Java generation

If any item fails, stop and fix the plan first. Do not proceed to XML generation with unresolved checklist failures.

### Phase 3: XML Generation + PRD

1. Read `references/layout-spec.md` first. Apply its mandatory rules for title bar reuse, absolute ConstraintLayout flattening, RecyclerView preview attributes, and resource scoping.
2. Search the project for reusable title bar components before drawing a custom header. If `com.androidtool.common.widget.TitleBarView` exists, all standard `icon-title-text-icon` child-page headers MUST use it instead of manually assembling back icon + title text in XML.
3. Verify the actual target layout directory with `find` before writing any XML. Never assume `res/layout/`.
4. Read `references/project-resources.md` for existing project resources (drawables, shapes, icons, colors). **Reuse existing resources whenever possible** — do not create a new shape/icon/color if an equivalent already exists in the project.
5. Read `references/output-format.md` for the required output structure.
6. Generate output following the format spec exactly.

#### 1-to-2 mode specifics

- Output the **complete modified XML** (not a diff)
- Mark added sections with `<!-- NEW: description -->` and `<!-- /NEW -->` comment pairs
- Preserve all existing View IDs, attributes, and resource references unchanged
- New resources (colors, dimens, drawables) must not conflict with existing ones

---

## Return Summary

This skill runs in `context: fork`. The forked agent handles all heavy work (reading CSS, drawing ASCII, generating XML, writing files). When complete, return **only** the following to the main conversation:

### Required output format

```
## Generated Files

- `<discovered-layout-dir>/fragment_xxx.xml` — Main page layout
- `<discovered-layout-dir>/item_xxx.xml` — List item layout
- `res/drawable/shape_xxx.xml` — Background shape
- `res/values/colors.xml` — (snippet appended)
- `res/values/dimens.xml` — (snippet appended)

## PRD Summary

**Page**: [page name]
**Entry**: [where users navigate from]
**Responsibility**: [core function in one sentence]

### Regions
- [region 1]: [brief description + display condition]
- [region 2]: [brief description]
- ...

### Key Interactions
- [view_id]: [click behavior + result]
- [view_id]: [click behavior + result]
- ...

### Page States
Loading → Normal → Empty → Error (with retry)
```

**Rules**:
- Write all XML files to disk using the Write tool during Phase 3
- Use the real layout directory discovered from the target module; never hardcode `res/layout/`
- The return summary must be concise — no XML code, no full PRD prose
- Include every generated file path so the user can read them directly
- PRD summary covers structure + interactions + states in bullet points only
- Never generate or propose Kotlin/Java implementation files in this skill
