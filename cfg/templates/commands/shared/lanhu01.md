---
description: 蓝湖设计稿提取（生成跨平台开发规格）
argument-hint: <蓝湖设计稿 URL>
---

从蓝湖 DDS 页面提取设计稿的 HTML/CSS 代码和设计图，生成标准化的 `spec.md` 供下游 agent（Android/iOS）使用。

**输入**: `$ARGUMENTS` - 蓝湖设计稿 URL（包含 ddsUrl 参数的完整链接）

---

## 执行流程

### Step 1: 导航并提取标题
```
1. mcp__1mcp__chrome-devtools_1mcp_navigate_page(url=$ARGUMENTS, timeout=30000)
2. mcp__1mcp__chrome-devtools_1mcp_take_snapshot(filePath="./temp-snapshot.txt")
3. 从快照中提取 {title}（Iframe "dds" 内第一个非空 StaticText）
4. mkdir -p "{title}"
```

### Step 2: 截图设计图
```
1. 在快照中查找第一个 url 包含 "merge_image/imgs" 的 image 节点，记为 <design_image_uid>
2. mcp__1mcp__chrome-devtools_1mcp_take_screenshot(uid=<design_image_uid>, filePath="./{title}/design.png")
```

> **说明**: `merge_image/imgs` 对应 DDS 合成的完整设计图 PNG，直接截图该 image 即可。

### Step 3: 提取 HTML 代码

#### 3.1 复制 JSX 代码
```
1. 定位: textbox value="React" 后的第一个 button "复制代码"
2. mcp__1mcp__chrome-devtools_1mcp_click(uid=<jsx_copy_button_uid>)
3. 等待 tooltip "复制成功" 出现
4. pbpaste > "./temp-jsx.txt"
```

#### 3.2 转换 JSX → HTML
```
读取 temp-jsx.txt，执行以下转换：
- className → class
- 移除 import/export 语句
- 移除 "use strict"
- <></> → <div></div>
- 移除事件处理器（onClick, onChange 等）
- {变量} → 保留为 {{变量}} 或替换为占位文本
- 保留完整 DOM 结构

保存为: ./{title}/component.html
```

### Step 4: 提取 CSS 代码
```
1. mcp__1mcp__chrome-devtools_1mcp_take_snapshot(filePath="./temp-snapshot-2.txt")
   （重新获取快照，因为 uid 已变化）
2. 定位: textbox value="index.css" 后的第一个 button "复制代码"
3. mcp__1mcp__chrome-devtools_1mcp_click(uid=<css_copy_button_uid>)
4. 等待 tooltip "复制成功" 出现
5. pbpaste > "./{title}/style.css"
6. 验证: head -5 检查是否以 . 或 # 开头（CSS 选择器）
```

### Step 5: 生成 spec.md
读取 `design.png`, `component.html`, `style.css`，生成 `./{title}/spec.md`（模板见下方）

### Step 6: 清理临时文件
```bash
rm -f ./temp-snapshot.txt ./temp-snapshot-2.txt ./temp-jsx.txt
```

---

## 元素定位表

在 `Iframe "dds"` 内，按出现顺序/匹配规则：

| 目标 | 定位方式 | 用途 |
|------|---------|------|
| 标题 | 第一个非空 `StaticText` | 提取 {title} |
| 设计图 | 第一个 `image`，其 url 包含 `merge_image/imgs` | 截图设计图 |
| JSX 复制按钮 | `textbox value="React"` 后的第一个 `button "复制代码"` | 点击复制 JSX |
| CSS 复制按钮 | `textbox value="index.css"` 后的第一个 `button "复制代码"` | 点击复制 CSS |

---

## JSX → HTML 转换规则

| 原始 JSX | 转换后 HTML | 说明 |
|---------|------------|------|
| `className="xxx"` | `class="xxx"` | 属性名转换 |
| `<></>` | `<div></div>` | Fragment 转换 |
| `onClick={handler}` | 删除 | 移除事件处理器 |
| `{variable}` | `{{variable}}` 或 `placeholder` | 变量占位 |
| `import ...` | 删除 | 移除模块导入 |
| `export default ...` | 删除 | 移除导出语句 |
| `"use strict";` | 删除 | 移除严格模式 |

---

## spec.md 模板

````markdown
# Design Spec: {title}

## Source
- **Platform**: Lanhu DDS
- **URL**: {$ARGUMENTS}
- **Extracted**: {当前时间 ISO 8601 格式，如 2025-12-12T14:30:00+08:00}

## Assets
- Design Preview: `./design.png`
- HTML Structure: `./component.html`
- Stylesheet: `./style.css`

## Design Preview
![Design](./design.png)

## HTML Structure
```html
{component.html 完整内容}
```

## Stylesheet
```css
{style.css 完整内容}
```

## Common CSS Utilities
```css
.flex-col { display: flex; flex-direction: column; }
.flex-row { display: flex; flex-direction: row; }
.justify-between { justify-content: space-between; }
.justify-center { justify-content: center; }
.items-center { align-items: center; }
```

## Implementation Notes
- **Original Framework**: React (converted to plain HTML)
- **Layout System**: Flexbox
- **Responsive**: No (fixed width design)
- **Assets**: Embedded/inline (no external image dependencies)
- **Font**: Check CSS for custom font requirements

## Next Steps
Use this specification to implement native UI:
- [ ] Android XML Layout
- [ ] Android Jetpack Compose
- [ ] iOS UIKit (Storyboard/XIB)
- [ ] iOS SwiftUI

## Usage for Downstream Agents
1. Read `design.png` for visual reference
2. Parse `component.html` for DOM structure and hierarchy
3. Apply `style.css` for layout, spacing, colors, typography
4. Map HTML elements to native components:
   - `<div>` → `View`/`LinearLayout`/`UIView`/`VStack`
   - `<span>` → `Text`/`TextView`/`UILabel`/`Text`
   - `<img>` → `Image`/`ImageView`/`UIImageView`/`Image`
````

---

## 输出文件结构

```
{title}/
├── design.png          # 设计图截图（完整 PNG）
├── component.html      # HTML 结构（从 JSX 转换）
├── style.css           # CSS 样式（完整代码）
└── spec.md             # 📄 规格文档（下游 agent 入口）
```

---

## 失败处理

| 问题 | 解决方案 |
|------|---------|
| pbpaste 内容不是代码 | 重新点击复制按钮，等待 tooltip "复制成功" 后再 pbpaste |
| 截图失败 | 重新 take_snapshot 获取新 uid，或检查 `merge_image/imgs` 匹配 |
| JSX 转换失败 | 保留原始 JSX 在 spec.md 中，添加警告注释 |
| {title} 包含特殊字符 | 保持原样（macOS/Linux 支持 UTF-8 文件名） |
| 临时文件残留 | 确保执行 Step 6 清理命令 |

---

## 注意事项

1. **必须使用剪贴板**: 代码编辑器使用虚拟滚动，直接从快照只能获取可视区域代码
2. **等待复制完成**: 点击复制按钮后，必须等待 tooltip "复制成功" 出现再执行 pbpaste
3. **uid 是动态的**: 每次 take_snapshot 后 uid 都会变化，CSS 复制前需重新获取快照
4. **保留 {title} 原样**: 不转换为 slug，保持语义化（如 "登录页面"）
5. **macOS 专用**: `pbpaste` 命令仅适用于 macOS
6. **spec.md 是核心**: 下游 agent 只需读取这一个文件即可获得所有信息
