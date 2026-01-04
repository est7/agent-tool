---
description: 蓝湖设计稿提取（优化版）
argument-hint: <蓝湖设计稿 URL>
---

从蓝湖 DDS 页面提取设计稿的代码和设计图，生成 `spec.md` 供下游 agent 使用。

**输入**: `$ARGUMENTS` - 蓝湖设计稿 URL

---

## 执行流程

### Step 1: 导航 + 轻量快照 + 自动解析
```
1. navigate_page(url=$ARGUMENTS, timeout=30000)
2. SNAP=$(mktemp) && take_snapshot(filePath="$SNAP", verbose=false)
3. 从快照提取（建议用脚本自动完成，避免人工 grep）:
   - {title}: Iframe "dds" 内第一个非空 StaticText
   - {design_url}:
       a. 先找包含 "SketchCover" 的第一个 image url
       b. 若未找到，再找包含 "merge_image/imgs" 的第一个 image url
   - {jsx_btn}: textbox value="React" 后最近的 button "复制代码" 的 uid
4. mkdir -p "{title}"
5. curl -L -o "./{title}/design.png" "{design_url}"
```

可用脚本自动解析变量（放到 Step 1 第 3 步后执行）:

```bash
parse_lanhu_snapshot() {
  local snap="$1"
  python3 - "$snap" <<'PY'
import re, sys
snap_path = sys.argv[1]
lines = open(snap_path, encoding="utf-8").read().splitlines()

def find_title():
  dds_start = None
  for i, l in enumerate(lines):
    if 'Iframe "dds"' in l:
      dds_start = i
      break
  if dds_start is None:
    return ""
  for l in lines[dds_start + 1:]:
    m = re.search(r'StaticText "(.*)"', l)
    if not m:
      continue
    text = m.group(1).strip()
    if not text:
      continue
    if len(text) == 1 and not re.search(r'[A-Za-z0-9\u4e00-\u9fff]', text):
      continue
    if re.search(r'[A-Za-z0-9\u4e00-\u9fff]', text):
      return text
  return ""

def find_design_url():
  for l in lines:
    if 'image url="' in l:
      m = re.search(r'url="([^"]+)"', l)
      if m and "SketchCover" in m.group(1):
        return m.group(1)
  for l in lines:
    if 'image url="' in l:
      m = re.search(r'url="([^"]+)"', l)
      if m and "merge_image/imgs" in m.group(1):
        return m.group(1)
  return ""

def find_copy_uid(value):
  for i, l in enumerate(lines):
    if f'value="{value}"' in l and "textbox" in l:
      for l2 in lines[i + 1:]:
        if 'button "复制代码"' in l2:
          m = re.search(r'uid=(\d+_\d+)', l2)
          if m:
            return m.group(1)
      break
  return ""

title = find_title()
design_url = find_design_url()
jsx_btn = find_copy_uid("React")
css_btn = find_copy_uid("index.css")

def q(s): return repr(s or "")
print(f"title={q(title)}")
print(f"design_url={q(design_url)}")
print(f"jsx_btn={q(jsx_btn)}")
print(f"css_btn={q(css_btn)}")
PY
}

eval "$(parse_lanhu_snapshot "$SNAP")"
echo "title=$title"
echo "design_url=$design_url"
echo "jsx_btn=$jsx_btn"
```

### Step 2: 复制 JSX 代码（带等待与校验）
```
1. click(uid={jsx_btn})
2. wait_for(text="复制成功", timeout=5000)
3. pbpaste > "./{title}/component.jsx"
4. 若 component.jsx 字节数过小（如 < 50B），回到 1 重试
```

### Step 3: 复制 CSS 代码（复用临时快照）
```
1. take_snapshot(filePath="$SNAP", verbose=false)  # uid 会刷新，覆盖同一临时文件即可
2. 重新执行 eval "$(parse_lanhu_snapshot "$SNAP")" 刷新 {css_btn}
3. click(uid={css_btn})
4. wait_for(text="复制成功", timeout=5000)
5. pbpaste > "./{title}/style.css"
6. 若 style.css 字节数过小（如 < 50B），回到 3 重试
```

### Step 4: 生成 spec.md
```
写入 ./{title}/spec.md，模板如下
```

### Step 5: 清理
```bash
rm -f "$SNAP"
```

---

## spec.md 模板

````markdown
# Design Spec: {title}

## Source
- **URL**: {$ARGUMENTS}
- **Extracted**: {ISO 8601 时间}

## Assets
| File | Description |
|------|-------------|
| `design.png` | 设计图 |
| `component.jsx` | React JSX 代码 |
| `style.css` | CSS 样式 |

## Design Preview
![Design](./design.png)

## JSX Code
```jsx
{component.jsx 内容}
```

## CSS
```css
{style.css 内容}
```

## Element Mapping
| HTML/JSX | Android | iOS UIKit | iOS SwiftUI |
|----------|---------|-----------|-------------|
| `<div>` | LinearLayout/ConstraintLayout | UIView | VStack/HStack |
| `<span>` | TextView | UILabel | Text |
| `<img>` | ImageView | UIImageView | Image |
````

---

## 输出

```
{title}/
├── design.png       # 设计图
├── component.jsx    # JSX 代码（原样保存）
├── style.css        # CSS 样式
└── spec.md          # 规格文档
```

---

## 失败处理

| 问题 | 方案 |
|------|------|
| SketchCover 未找到 | 退到 grep "merge_image/imgs" 的第一个 URL |
| 复制失败或剪贴板未更新 | 重新 click 复制按钮，确认 wait_for 出现 "复制成功" |

---

## 注意事项

1. **默认不用 verbose 快照**: `verbose=false` 更轻量，降低触发蓝湖风控概率；只有定位不到 uid 时再临时用 verbose
2. **必须使用剪贴板**: 代码编辑器使用虚拟滚动，直接从快照只能获取可视区域代码
3. **点击后必须等待成功提示**: 用 `wait_for("复制成功")` 保障剪贴板已更新
4. **uid 是动态的**: 每次 take_snapshot 后 uid 都会变化，CSS 复制前需重新获取快照
5. **macOS 专用**: `pbpaste` 命令仅适用于 macOS
