# Web端设计规范

> Web端设计规范，被 220-admin-web-dev 引用。

## 色彩规范

```css
--primary-color: #409EFF;      /* 主题色 */
--success-color: #67C23A;      /* 成功色 */
--warning-color: #E6A23C;      /* 警告色 */
--danger-color: #F56C6C;       /* 危险色 */
--text-primary: #303133;       /* 主要文字 */
--text-regular: #606266;       /* 常规文字 */
--border-color: #DCDFE6;       /* 边框颜色 */
--bg-color: #F5F7FA;           /* 背景颜色 */
```

## 字体规范

| 级别 | 大小 | 用途 |
|------|------|------|
| 主标题 | 20px | 页面主标题 |
| 标题 | 18px | 模块标题 |
| 小标题 | 16px | 子模块标题 |
| 正文 | 14px | 常规内容 |
| 辅助 | 12px | 辅助信息 |

## 间距规范

| 类型 | 间距 |
|------|------|
| 基础间距 | 8px |
| 模块间距 | 16px/24px |
| 页面边距 | 24px |

## 主题与暗色模式

项目支持**主题色切换**和**暗色/亮色模式切换**，通过页面右上角「个性化设置」抽屉操作。

### 主题色

系统提供 8 种预设主题色，修改后会覆盖 Element Plus 的 `--el-color-primary` 变量：

`#409eff` `#009688` `#536DFE` `#FF5C93` `#EE4F12` `#0096C7` `#9C27B0` `#FF9800`

### 暗色模式

通过 `useCustomDark()` 切换，暗色模式下自动覆盖以下 CSS 变量：

| 变量 | 亮色模式 | 暗色模式 |
|------|---------|---------|
| `--el-slide-menu-background` | 跟随侧边栏主题色 | `#222222` |
| `--el-header-tab-background` | `#ffffff` | `transparent` |
| `--el-main-container-background` | `#f2f3f5` | `#393A3C` |
| `--el-expand-table-border-bottom-color` | `#f0f2f5` | `#414243` |

### 侧边栏主题色

侧边栏背景色独立配置，提供 8 种预设：

`#001529` `#222222` `#016259` `#0f467f` `#2a377f` `#802e49` `#77280b` `#0c4b64`

## 自定义 CSS 变量

项目自定义变量定义于 `src/styles/var.css`：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `--el-slide-menu-background` | `#222222` | 侧边栏背景色 |
| `--el-header-tab-background` | `#ffffff` | 页签/面包屑背景色 |
| `--el-main-container-background` | `#f2f3f5` | 内容区背景色 |
| `--el-expand-table-border-bottom-color` | `#f0f2f5` | 表格展开行边框色 |
| `--el-table-flex-value` | `1` | 表格 flex 占比 |

## 工具类

### Margin / Padding

`src/styles/basics.scss` 自动生成以 5px 为步长的工具类（5 ~ 50px）：

```
.margin-top-10    → margin-top: 10px
.padding-left-20  → padding-left: 20px
.margin-15        → margin: 15px
```

类名格式：`.{property}-{direction}-{value}` 或 `.{property}-{value}`

- property：`margin` / `padding`
- direction：`top` / `bottom` / `left` / `right`（省略则为四边）
- value：5 的倍数（5 ~ 50）

### 文本省略

| 类名 | 说明 |
|------|------|
| `.ellipsis` | 单行省略 |
| `.ellipsis2` | 两行省略 |
| `.ellipsis3` | 三行省略 |

### Flex 布局

`src/styles/layout.css` 提供标准 flex 纵向布局类：

| 类名 | 说明 |
|------|------|
| `.flex_col` | `display: flex; flex-direction: column; height: 100%` |
| `.flex_col_header` | 头部区域，`flex: none` |
| `.flex_col_body` | 内容区域，`flex: 1`，自动滚动 |
| `.flex_col_bottom` | 底部区域，`flex: none` |

## Element Plus 样式覆盖

`src/styles/basics.scss` 中对 Element Plus 组件进行了统一覆盖，典型示例：

- **Dialog**：圆角 `8px`，header 背景 `#2c3940`，标题白色
- 其他覆盖请直接查看文件内容，避免页面内重复覆盖。

## 样式文件目录结构

```
src/styles/
├── var.css              # 项目自定义 CSS 变量
├── basics.scss          # 基础工具类 + Element Plus 样式覆盖
├── flex.scss            # Flex 布局辅助
├── layout.css           # 标准 flex 纵向布局类
├── normalize.css        # 浏览器样式重置
├── tableExpand.scss     # 表格展开行样式
└── element/
    └── index.scss       # Element Plus 主题入口
```

## 响应式断点

| 端 | 宽度 | 说明 |
|----|------|------|
| 桌面端 | 1200px+ | 大屏体验 |
| 平板端 | 768px-1199px | 适配 |
| 移动端 | <768px | 响应式 |
