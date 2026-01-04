---
description: 蓝湖设计稿代码提取（设计图截图）
argument-hint: <蓝湖设计稿 URL>
---

从蓝湖 DDS 页面提取设计稿的 React/CSS 代码并保存，截图为「纯设计图」PNG。

**输入**: `$ARGUMENTS` - 蓝湖设计稿 URL（包含 ddsUrl 参数的完整链接）

---

## 执行流程

### Step 1: 导航并获取快照
```
1. mcp__1mcp__chrome-devtools_1mcp_navigate_page(url=$ARGUMENTS, timeout=30000)
2. mcp__1mcp__chrome-devtools_1mcp_take_snapshot(filePath="./{title}/temp/lanhu-dds-snapshot.txt")
3. 从快照中提取 {title}（Iframe "dds" 内第一个非空 StaticText）
```

> 实际实现时，如果一开始还不知道 {title}，可以先将快照保存到临时路径，解析出 {title} 后再移动/重新保存到 `./{title}/temp/`。

### Step 2: 创建输出文件夹
```bash
mkdir -p ./{title}/
mkdir -p ./{title}/temp/
```

### Step 3: 截图设计图（merge_image 快速定位）
```
1. 在 DDS 快照中查找第一个 url 包含 "merge_image/imgs" 的 image 节点，记为 <design_image_uid>
2. mcp__1mcp__chrome-devtools_1mcp_take_screenshot(uid=<design_image_uid>, filePath="./{title}/{title}.png")
```

> 说明：`merge_image/imgs` 对应 DDS 合成的整张设计图 PNG，直接对该 image 截图即可得到完整设计图，而不依赖「代码运行效果」容器结构。

### Step 4: 提取代码（剪贴板方式）

**重要**: 代码编辑器使用虚拟滚动，必须通过剪贴板获取完整代码。

#### 4.1 复制并保存 JSX 代码
```
1. 定位: textbox value="React" 后的第一个 button "复制代码"
2. mcp__1mcp__chrome-devtools_1mcp_click(uid=<jsx_copy_button_uid>)
3. 等待 tooltip "复制成功" 出现（确认复制完成）
4. pbpaste > "./{title}/index.jsx"
5. 验证: head -5 检查是否以 "use strict" 或 import 开头
```

#### 4.2 复制并保存 CSS 代码
```
1. 重新获取快照（uid 会变化，可同样保存到 ./{title}/temp/ 下）
2. 定位: textbox value="index.css" 后的第一个 button "复制代码"
3. mcp__1mcp__chrome-devtools_1mcp_click(uid=<css_copy_button_uid>)
4. 等待 tooltip "复制成功" 出现
5. pbpaste > "./{title}/index.css"
6. 验证: head -5 检查是否以 . 或 # 开头（CSS 选择器）
```

### Step 5: 生成 Markdown
读取保存的代码文件，创建 `./{title}/{title}.md`（模板见下方）

### Step 6: 清理中间文件
```bash
rm -rf "./{title}/temp/"
```

---

## 元素定位表

在 `Iframe "dds"` 内，按出现顺序/匹配规则：

| 目标 | 定位方式 | 用途 |
|------|---------|------|
| 标题 | 第一个非空 `StaticText` | 提取 {title} |
| 设计图 | 第一个 `image`，其 url 包含 `merge_image/imgs` | 截图纯设计图 |
| JSX 复制按钮 | `textbox value="React"` 后的 `button "复制代码"` | 点击复制 JSX |
| CSS 复制按钮 | `textbox value="index.css"` 后的 `button "复制代码"` | 点击复制 CSS |

---

## 失败处理

| 问题 | 解决方案 |
|------|---------|
| pbpaste 内容不是代码 | 重新点击复制按钮，等待 tooltip 后再 pbpaste |
| 截图失败 | 重新 take_snapshot 获取新 uid 或重新匹配 `merge_image/imgs` image |
| 页面未加载完成 | 增加 navigate_page timeout 或 wait_for "代码运行效果" |
| 中间文件残留 | 确认执行 `rm -rf "./{title}/temp/"`，或在脚本最后统一清理 |

---

## 输出文件结构

```
./{title}/
├── {title}.png      # 纯设计图截图（merge_image PNG）
├── index.jsx        # 完整 JSX 代码（剪贴板）
├── index.css        # 完整 CSS 代码（剪贴板）
└── {title}.md       # Markdown 汇总文档
```

---

## Markdown 模板

```markdown
# 蓝湖设计稿代码 - {title}

> 来源: 蓝湖 DDS
> 设计稿: {title}

## 设计图预览

![设计图](./{title}.png)

---

## React JSX 代码 (index.jsx)

\`\`\`jsx
{index.jsx 文件内容}
\`\`\`

---

## CSS 代码 (index.css)

\`\`\`css
{index.css 文件内容}
\`\`\`

---

## 通用 CSS (common.css)

\`\`\`css
.flex-col { display: flex; flex-direction: column; }
.flex-row { display: flex; flex-direction: row; }
.justify-between { justify-content: space-between; }
\`\`\`
```

---

## 注意事项

1. **必须使用剪贴板**: 代码编辑器是虚拟滚动的，直接从快照读取只能获得可视区域的部分代码
2. **等待复制完成**: 点击复制按钮后，必须等待 tooltip "复制成功" 出现再执行 pbpaste
3. **uid 是动态的**: 每次 take_snapshot 后 uid 都会变化，需要重新定位元素
4. **中间文件放在 temp**: 所有快照、调试 txt 等中间文件统一放在 `./{title}/temp/`，命令结束后删除该目录
5. **macOS 专用**: `pbpaste` 命令仅适用于 macOS，其他系统需替换剪贴板读取方式

