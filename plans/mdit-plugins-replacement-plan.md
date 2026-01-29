# mdit-plugins 替换为 markdown-it 官方独立插件计划

## 当前使用的插件分析

在 `anki/挖空/` 目录的 HTML 文件中，使用了以下 mdit-plugins：

| 插件                      | 功能            | 使用场景             |
|---------------------------|-----------------|----------------------|
| `mditPlugins.mark`        | `==text==` 高亮 | 正面.html、背面.html |
| `mditPlugins.table`       | 表格渲染        | 背面.html            |
| `mditPlugins.subscript`   | 下标 `~text~`   | 背面.html            |
| `mditPlugins.superscript` | 上标 `^text^`   | 背面.html            |

## 替换方案：使用 markdown-it 官方独立插件

### CDN 资源清单

```html
<!-- 需要新增的插件 CDN -->
<script src="https://cdn.jsdelivr.net/npm/markdown-it-mark@3.0.1/dist/markdown-it-mark.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/markdown-it-sub@1.0.2/dist/markdown-it-sub.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/markdown-it-sup@1.0.0/dist/markdown-it-sup.min.js"></script>
```

> **注意**：`markdown-it@14.x` 已内置 table 插件，无需额外引入。

### 插件对应关系

| 原 mdit-plugins           | 替换为 markdown-it 官方插件         |
|---------------------------|-------------------------------------|
| `mditPlugins.mark`        | `markdownitMark` (markdown-it-mark) |
| `mditPlugins.table`       | **已内置，无需引入**                |
| `mditPlugins.subscript`   | `markdownitSub` (markdown-it-sub)   |
| `mditPlugins.superscript` | `markdownitSup` (markdown-it-sup)   |

## 实施步骤

### 步骤 1：更新 正面.html

1. 在 `getResources` 数组中添加：
   - `markdown-it-mark` CDN
2. 修改 `processField` 函数中的插件调用：
   ```javascript
   // 之前
   if (typeof mditPlugins !== 'undefined' && mditPlugins.mark) {
       md.use(mditPlugins.mark);
   }
   
   // 之后
   if (typeof markdownitMark !== 'undefined') {
       md.use(markdownitMark);
   }
   ```

### 步骤 2：更新 背面.html

1. 在 `getResources` 数组中添加：
   - `markdown-it-mark` CDN
   - `markdown-it-sub` CDN
   - `markdown-it-sup` CDN
2. 修改 `processField` 函数中的插件调用：
   ```javascript
   // 移除 mdit-plugins 相关代码
   // 替换为独立的官方插件调用
   
   if (typeof markdownitMark !== 'undefined') {
       md.use(markdownitMark);
   }
   if (typeof markdownitSub !== 'undefined') {
       md.use(markdownitSub);
   }
   if (typeof markdownitSup !== 'undefined') {
       md.use(markdownitSup);
   }
   ```
3. 简化表格插件逻辑（使用 markdown-it 内置 table）
4. 移除 `mditPlugins` 的条件检查和相关依赖

### 步骤 3：测试验证

验证以下功能：
- [ ] `==text==` 高亮语法正常渲染
- [ ] 下标 `~text~` 语法正常渲染
- [ ] 上标 `^text^` 语法正常渲染
- [ ] 表格渲染正常
- [ ] 控制台无插件相关错误

## 代码示例

### 加载顺序（Promise.all）

```javascript
var getResources = [
    getCSS("_katex.css", "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css"),
    getCSS("_highlight.css", "https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/styles/atom-one-dark.min.css"),
    getScript("_highlight.js", "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js"),
    getScript("_katex.min.js", "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"),
    getScript("_auto-render.js", "https://cdn.jsdelivr.net/gh/Jwrede/Anki-KaTeX-Markdown/auto-render-cdn.js"),
    getScript("_markdown-it.min.js", "https://cdn.jsdelivr.net/npm/markdown-it@14.1.0/dist/markdown-it.min.js"),
    // 新增官方插件
    getScript("_markdown-it-mark.min.js", "https://cdn.jsdelivr.net/npm/markdown-it-mark@3.0.1/dist/markdown-it-mark.min.js"),
    getScript("_markdown-it-sub.min.js", "https://cdn.jsdelivr.net/npm/markdown-it-sub@1.0.2/dist/markdown-it-sub.min.js"),
    getScript("_markdown-it-sup.min.js", "https://cdn.jsdelivr.net/npm/markdown-it-sup@1.0.0/dist/markdown-it-sup.min.js"),
];

Promise.all(getResources)
    .then(() => getScript("_mhchem.js", "https://cdn.jsdelivr.net/npm/katex@0.13.11/dist/contrib/mhchem.min.js"))
    .then(render)
    .catch(e => { console.error(e); fallback() });
```

### 插件调用示例

```javascript
// 初始化 markdown-it
let md = new markdownit({
    html: true,
    breaks: true,
    highlight: function (str, lang) {
        if (lang && hljs.getLanguage(lang)) {
            try { return hljs.highlight(str, { language: lang }).value; } catch (__) { }
        }
        return '';
    }
})
    // 表格插件已内置，无需额外引入
    .use(markdownit.plugins.table || ((md) => {}));

// 加载官方独立插件（按需）
if (typeof markdownitMark !== 'undefined') {
    md.use(markdownitMark);
    console.log('[Debug] markdown-it-mark loaded');
}
if (typeof markdownitSub !== 'undefined') {
    md.use(markdownitSub);
    console.log('[Debug] markdown-it-sub loaded');
}
if (typeof markdownitSup !== 'undefined') {
    md.use(markdownitSup);
    console.log('[Debug] markdown-it-sup loaded');
}
```

## 注意事项

1. **CDN 版本兼容性**：建议使用与 `markdown-it@14.1.0` 兼容的插件版本
2. **加载顺序**：确保 `markdown-it.min.js` 先于各插件加载
3. **回退机制**：保留条件检查，确保插件未加载时不影响基础功能
4. **table 插件**：markdown-it@14.x 内置 table 支持，如需更完整功能可考虑 `markdown-it-table` 插件
