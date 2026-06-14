# 消费者端UniApp移动端开发规范（Vue3 + TypeScript）

> 面向终端消费者的移动应用（电商小程序、内容App、社交应用）。被 220-guest-uni-dev 引用。

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| UniApp | 最新 | 跨平台框架 |
| Vue 3 | 3.x | 前端框架（Composition API） |
| TypeScript | 5.x | 类型安全 |
| Pinia | 2.x | 状态管理 |
| Vite | 8.x | 构建工具 |
| uni-ui | 最新 | UI 组件库 |

## 目录结构规范

```
src/
├── pages/                     # 页面（按Tab组织）
│   ├── index/                 # 首页Tab
│   ├── category/              # 分类Tab
│   ├── discovery/             # 发现Tab
│   └── user/                  # 我的Tab
├── components/                # 组件
│   ├── common/                # 通用组件
│   └── content/               # 内容展示组件
├── api/                       # API 调用封装（gencode生成，只读不改）
│   └── {module}/index.ts
├── store/                     # Pinia 状态管理
│   └── user.ts                # 用户状态
├── composables/               # 组合函数
│   └── use{Feature}.ts
├── utils/                     # 工具函数
│   ├── request.ts             # 网络请求封装
│   └── share.ts               # 分享工具
├── static/                    # 静态资源
├── App.vue
├── main.ts
├── manifest.json
├── pages.json
└── uni.scss
```

## 页面布局模式

消费者端采用 **TabBar + 内容页模式**：

```
┌─────────────────────┐
│  Logo    [搜索] [消息]│  ← 自定义顶部导航（部分页面）
├─────────────────────┤
│                     │
│    内容区域          │  ← 页面主体
│                     │
├─────────────────────┤
│  首页  分类  发现  我的│  ← TabBar（底部固定）
└─────────────────────┘
```

### 导航模式

| 场景 | 导航方式 | 说明 |
|------|---------|------|
| 主功能切换 | TabBar | 首页/分类/发现/我的等一级页面 |
| 内容详情 | 栈式导航（uni.navigateTo） | 从列表进入详情页 |
| 功能表单 | 栈式导航（uni.navigateTo） | 填写表单、编辑资料 |
| 登录/授权 | 全屏覆盖（uni.redirectTo） | 替换当前页面栈 |
| 支付结果 | 重定向（uni.reLaunch） | 清除栈到结果页 |

## 页面编码规范

### SFC 结构顺序

```vue
<template>...</template>
<script setup lang="ts">...</script>
<style scoped lang="scss">...</style>
```

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 页面文件 | kebab-case | `product-detail.vue` |
| 组件文件 | PascalCase | `ContentCard.vue` |
| composables | use 前缀 | `useShare.ts` |
| Store 文件 | kebab-case | `user.ts` |
| API 文件 | kebab-case | `content.ts` |
| 类型文件 | kebab-case | `content.ts` |
| 页面路径 | `pages/{module}/{page}` | `pages/index/index` |

### `<script setup>` 规范

```typescript
// 1. 类型导入（从 api 层导入）
import type { CmsArticle } from '@/api/cmsArticle'

// 2. API 导入
import { cmsArticleList } from '@/api/cmsArticle'

// 3. Store 导入
import { useUserStore } from '@/store/user'

// 4. composables
const { isLogin } = storeToRefs(useUserStore())

// 5. 响应式状态
const articleList = ref<CmsArticle[]>([])

// 6. 计算属性
const featuredList = computed(() => articleList.value.filter(item => item.isTop))

// 7. 方法定义
const loadMore = async () => { ... }

// 8. 生命周期
onMounted(() => loadMore())
```

## 页面生命周期规范

UniApp 页面同时支持 Vue 生命周期和 UniApp 生命周期，需按场景选择：

| 场景 | 使用钩子 | 说明 |
|------|---------|------|
| 页面初始化、获取参数 | `onLoad((options) => {})` | 仅页面级可用，options 为页面参数 |
| 页面每次显示 | `onShow(() => {})` | 从其他页面返回或从后台切回时触发 |
| 页面隐藏 | `onHide(() => {})` | 跳转其他页面或切后台 |
| DOM 首次就绪 | `onReady(() => {})` | 仅触发一次，适合获取节点信息 |
| 页面卸载 | `onUnload(() => {})` | 清理定时器、取消请求 |
| 组件初始化 | `onMounted(() => {})` | Vue 标准钩子，组件内使用 |

**使用原则**：
- TabBar 页面在 `onShow` 中刷新数据（返回时自动触发）
- 页面级逻辑（获取参数）用 UniApp 钩子（`onLoad`）
- 组件级逻辑（初始化、销毁）用 Vue 钩子（`onMounted`/`onUnmounted`）

```typescript
import { onLoad, onShow } from '@dcloudio/uni-app'

onLoad((options) => {
  const id = options.id
  loadDetail(id)
})

onShow(() => {
  // TabBar 页面返回时刷新未读数
  if (tabBarNeedsRefresh.value) {
    fetchUnreadCount()
  }
})
```

## 分享能力规范（消费者端特有）

### 页面分享配置

```vue
<script setup lang="ts">
import { onShareAppMessage, onShareTimeline } from '@dcloudio/uni-app'

// 微信小程序分享
onShareAppMessage(() => {
  return {
    title: pageTitle.value,
    path: `/pages/content/detail?id=${contentId.value}`,
    imageUrl: coverImage.value,
  }
})

// 微信朋友圈分享（仅微信小程序）
# ifdef MP-WEIXIN
onShareTimeline(() => {
  return {
    title: pageTitle.value,
    query: `id=${contentId.value}`,
    imageUrl: coverImage.value,
  }
})
# endif
</script>
```

### 通用分享工具

```typescript
// utils/share.ts
export const shareToWechat = (options: ShareOptions) => {
  # ifdef MP-WEIXIN
  // 小程序内直接调起分享
  return
  # endif

  # ifdef APP-PLUS
  uni.share({
    provider: 'weixin',
    scene: 'WXSceneSession',
    type: 0,
    title: options.title,
    href: options.url,
    imageUrl: options.imageUrl,
  })
  # endif
}
```

## 多端适配规范

### 表单校验规范

前端提交前必须校验，不等后端返回错误：

| 校验类型 | 实现方式 | 示例 |
|---------|---------|------|
| 必填 | 表单提交前检查空值 | `if (!form.phone) { showToast('请输入手机号'); return }` |
| 格式 | 正则校验 | 手机号、验证码 |
| 长度 | 字符串长度判断 | `if (form.comment.length > 200) { ... }` |

### 条件编译

```typescript
// #ifdef MP-WEIXIN
// 微信小程序专用代码
// #endif

// #ifdef H5
// H5 专用代码
// #endif

// #ifdef APP-PLUS
// App 专用代码（Android/iOS）
// #endif
```

### 平台差异对照

| 能力 | 微信小程序 | H5 | App (Android/iOS) |
|------|-----------|-----|-------------------|
| 登录 | `uni.login({ provider: 'weixin' })` → 后端 wxLogin | 手机号验证码登录 | `plus.oauth.getServices()` |
| 分享 | `onShareAppMessage()` / `onShareTimeline()` | `navigator.share()` | `plus.share.sendWithSystem()` |
| 支付 | `uni.requestPayment({ provider: 'wxpay' })` | 跳转支付页 | `uni.requestPayment({ provider: 'alipay' })` |
| 定位 | `uni.getLocation()` | HTML5 Geolocation | `uni.getLocation()` |
| 扫码 | `uni.scanCode()` | 不支持 | `uni.scanCode()` |
| 存储 | `uni.setStorageSync` | localStorage | `plus.io` |

### 样式单位

| 单位 | 使用场景 | 说明 |
|------|---------|------|
| `rpx` | 宽度、间距、字体 | 响应式单位，750rpx = 屏幕宽度 |
| `px` | 边框、阴影 | 固定尺寸 |
| `%` | 弹性布局 | 相对父容器 |
| `vh/vw` | 全屏布局 | 相对视口（仅 H5/App，小程序不支持） |

### 安全区适配

```css
/* TabBar 安全区 */
.tab-bar {
  padding-bottom: constant(safe-area-inset-bottom);
  padding-bottom: env(safe-area-inset-bottom);
}

/* 顶部状态栏 */
.status-bar {
  height: var(--status-bar-height);
}
```

## 状态管理规范（Pinia）

使用 Pinia setup 风格：`defineStore('name', () => { ... })`，State 用 ref，Getters 用 computed，Actions 为普通函数。

```typescript
// 用户状态
export const useUserStore = defineStore('user', () => {
  const token = ref('')
  const userInfo = ref<UserInfo | null>(null)
  const isLogin = computed(() => !!token.value)

  const login = async (params: LoginParams) => {
    const res = await apiLogin(params)
    token.value = res.data.token
    userInfo.value = res.data.userInfo
    uni.setStorageSync('token', token.value)
  }

  const logout = () => {
    token.value = ''
    userInfo.value = null
    uni.removeStorageSync('token')
  }

  return { token, userInfo, isLogin, login, logout }
})
```

## 网络请求规范

> 网络请求已由 `src/api/request/` 封装，页面中禁止直接使用 `uni.request`。API 调用通过 `src/api/` 层的生成函数完成。

### ResponseData<T> 解析规范

```
列表 API 返回：ResponseData<DataList<T>>
  - 列表数据：res.data?.results     → 类型 T[]（注意是 results，不是 list）
  - 分页总数：res.data?.total
  - 当前页码：res.data?.pageNum

实体 API 返回：ResponseData<T>
  - 实体数据：res.data              → 类型 T

无返回值 API：ResponseData<void>
  - 检查状态：res.state === 'success'
```

### 标准用法

```typescript
import { cmsArticleList, cmsArticleLoad } from '@/api/cmsArticle'
import type { CmsArticle } from '@/api/cmsArticle'

// 列表页
const res = await cmsArticleList({ param: { $pg: 1, $rn: 20 } })
const list: CmsArticle[] = res.data?.results || []
const total = res.data?.total || 0

// 详情页
const res = await cmsArticleLoad({ id: articleId })
const detail: CmsArticle = res.data!
```

## 路由配置规范（pages.json）

| 规范 | 说明 |
|------|------|
| 路径格式 | `pages/{module}/{page}` |
| TabBar | **必须配置 TabBar**，定义一级导航 |
| 导航栏 | 每个页面配置 `navigationBarTitleText` |
| 自定义导航 | 部分页面使用 `navigationStyle: "custom"` |
| 分包 | 主包 ≤ 2MB，超出使用 `subPackages` 分包 |

### TabBar 配置示例

```json
{
  "tabBar": {
    "color": "#999999",
    "selectedColor": "#E53935",
    "borderStyle": "black",
    "backgroundColor": "#ffffff",
    "list": [
      { "pagePath": "pages/index/index", "text": "首页", "iconPath": "static/tabbar/home.png", "selectedIconPath": "static/tabbar/home-active.png" },
      { "pagePath": "pages/category/category", "text": "分类", "iconPath": "static/tabbar/category.png", "selectedIconPath": "static/tabbar/category-active.png" },
      { "pagePath": "pages/discovery/discovery", "text": "发现", "iconPath": "static/tabbar/discovery.png", "selectedIconPath": "static/tabbar/discovery-active.png" },
      { "pagePath": "pages/user/user", "text": "我的", "iconPath": "static/tabbar/user.png", "selectedIconPath": "static/tabbar/user-active.png" }
    ]
  }
}
```

## 字段一致性原则

| 层级 | 命名规范 | 示例 |
|------|---------|------|
| 数据库字段 | snake_case | `content_title` |
| 后端 DTO 字段 | camelCase | `contentTitle` |
| 前端字段 | camelCase（与 DTO 一致） | `contentTitle` |
| API 参数 | camelCase（与 DTO 一致） | `contentTitle` |

## 禁用规则

| 禁用项 | 说明 |
|--------|------|
| `any` 类型 | 禁止使用 `any`，必须定义具体类型 |
| `v-html` | 小程序不支持，使用 `rich-text` 组件 |
| DOM 操作 | 禁止直接操作 DOM，使用 Vue 响应式 |
| 全局事件总线 | 禁止 `uni.$emit`/`uni.$on`，使用 Pinia 替代 |
| `window/document` | 禁止直接使用，需条件编译包裹 |
| 同步存储 | 大数据使用 `uni.setStorage` 异步版本 |

## 性能规范

| 场景 | 规范 |
|------|------|
| 图片 | 使用 `mode="aspectFill"` / `mode="widthFix"`，启用懒加载 |
| 列表 | 下拉刷新 + 上拉加载分页，单页 ≤ 20 条 |
| 虚拟列表 | 长列表使用虚拟滚动（如 `recycle-view`） |
| 缓存 | TabBar 页面使用 `uni.setStorageSync` 缓存首屏数据 |
| 分包 | 主包 ≤ 2MB，总包 ≤ 20MB（微信小程序） |
| 预加载 | 使用 `preloadRule` 预加载分包页面 |
| 请求 | 并行请求使用 `Promise.all`，避免瀑布式请求 |
