# 管理端UniApp移动端开发规范（Vue3 + TypeScript）

> 面向管理人员和运营人员的移动端应用（移动审批、商户管理、运营后台小程序）。被 220-admin-uni-dev 引用。

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
├── pages/                     # 页面（按角色组织）
│   ├── admin/{module}/        # 总后台模块
│   ├── mch/{module}/          # 商户模块
│   └── saas/{module}/         # SaaS管理模块
├── components/                # 组件
│   ├── common/                # 通用组件
│   └── business/              # 业务组件
├── api/                       # API 调用封装（gencode生成，只读不改）
│   └── {module}/index.ts
├── store/                     # Pinia 状态管理
│   ├── auth.ts                # 认证与权限
│   └── menu.ts                # 菜单权限
├── composables/               # 组合函数
│   └── use{Feature}.ts
├── utils/                     # 工具函数
│   ├── request.ts             # 网络请求封装
│   ├── auth.ts                # 登录/Token 管理
│   └── permission.ts          # 权限判断工具
├── static/                    # 静态资源
├── App.vue
├── main.ts
├── manifest.json
├── pages.json
└── uni.scss
```

## 页面布局模式

管理端移动端采用**导航栈模式**，不使用 TabBar：

```
┌─────────────────────┐
│  ← 页面标题          │  ← navigationBar（顶部导航栏）
├─────────────────────┤
│                     │
│    内容区域          │  ← 页面主体
│                     │
├─────────────────────┤
│  [搜索筛选]          │  ← 列表页顶部搜索/筛选区（可选）
│                     │
│  ┌───────────────┐  │
│  │ 数据项 1      │  │  ← 列表/卡片
│  │ 状态标签 时间  │  │
│  └───────────────┘  │
│  ┌───────────────┐  │
│  │ 数据项 2      │  │
│  └───────────────┘  │
│                     │
│        [+ FAB]      │  ← 新增按钮（固定悬浮）
└─────────────────────┘
```

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
| 页面文件 | kebab-case | `product-list.vue` |
| 组件文件 | PascalCase | `StatusTag.vue` |
| composables | use 前缀 | `usePermission.ts` |
| Store 文件 | kebab-case | `auth.ts` |
| API 文件 | kebab-case | `product.ts` |
| 类型文件 | kebab-case | `product.ts` |
| 页面路径 | `pages/{role}/{module}/{page}` | `pages/admin/product/list` |

### `<script setup>` 规范

```typescript
// 1. 类型导入（从 api 层导入）
import type { ProductInfo, ProductQueryParam } from '@/api/product'

// 2. 组件导入
import SearchBar from '@/components/common/SearchBar.vue'
import DataList from '@/components/common/DataList.vue'
import StatusTag from '@/components/common/StatusTag.vue'

// 3. API 导入
import { listProduct } from '@/api/product'

// 4. Store 导入
import { useMenuStore } from '@/store/menu'

// 5. composables
const { hasPermission } = usePermission()

// 6. 响应式状态
const listData = ref<ProductInfo[]>([])

// 7. 计算属性
const filteredList = computed(() => listData.value.filter(...))

// 8. 方法定义
const fetchList = async () => { ... }

// 9. 生命周期
onMounted(() => fetchList())
```

### Props & Emits 规范

```typescript
const props = defineProps<{
  product: ProductInfo
  showStatus?: boolean
}>()

const emit = defineEmits<{
  click: [product: ProductInfo]
  statusChange: [productId: number, status: string]
}>()
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
| 监听返回按钮 | `onBackPress(() => {})` | 返回 `true` 阻止默认返回 |

**使用原则**：
- 页面级逻辑（获取参数、每次刷新数据）用 UniApp 钩子（`onLoad`/`onShow`）
- 组件级逻辑（初始化、销毁）用 Vue 钩子（`onMounted`/`onUnmounted`）
- `onShow` 中避免重复初始化，用标志位或判断数据是否已加载

```typescript
import { onLoad, onShow } from '@dcloudio/uni-app'

onLoad((options) => {
  const id = options.id
  loadDetail(id)
})

onShow(() => {
  if (needsRefresh.value) {
    fetchList()
    needsRefresh.value = false
  }
})
```

## 权限管理规范（管理端特有）

### 菜单权限

后端返回当前用户的菜单权限列表，前端动态构建可访问页面：

```typescript
// store/menu.ts
export const useMenuStore = defineStore('menu', () => {
  const menus = ref<MenuItem[]>([])
  const permissions = ref<string[]>([])

  const hasMenu = (path: string) => menus.value.some(m => m.path === path)
  const hasPermission = (code: string) => permissions.value.includes(code)

  const loadMenus = async () => {
    const res = await fetchUserMenus()
    menus.value = res.data.menus
    permissions.value = res.data.permissions
  }

  return { menus, permissions, hasMenu, hasPermission, loadMenus }
})
```

### 按钮权限

在页面中根据权限码控制按钮显示：

```vue
<button v-if="menuStore.hasPermission('product:add')" @click="handleAdd">
  新增
</button>
```

### 页面级权限守卫

```typescript
// 在页面 onLoad 中检查权限
onLoad(() => {
  const menuStore = useMenuStore()
  if (!menuStore.hasMenu('/pages/admin/product/list')) {
    uni.showToast({ title: '无权限访问', icon: 'none' })
    setTimeout(() => uni.navigateBack(), 1500)
  }
})
```

## 多端适配规范

### 表单校验规范

前端提交前必须校验，不等后端返回错误：

| 校验类型 | 实现方式 | 示例 |
|---------|---------|------|
| 必填 | 表单提交前检查空值 | `if (!form.name) { showToast('请输入名称'); return }` |
| 格式 | 正则校验 | 手机号、邮箱、身份证 |
| 长度 | 字符串长度判断 | `if (form.name.length > 50) { ... }` |
| 范围 | 数值范围判断 | 金额 > 0 |
| 一致性 | 双字段比对 | 确认密码与密码一致 |

```typescript
const validateForm = (): boolean => {
  if (!form.name.trim()) {
    uni.showToast({ title: '请输入名称', icon: 'none' })
    return false
  }
  if (form.price <= 0) {
    uni.showToast({ title: '价格必须大于0', icon: 'none' })
    return false
  }
  return true
}
```

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

// #ifndef MP-WEIXIN
// 非微信小程序代码
// #endif
```

### 平台差异对照

| 能力 | 微信小程序 | H5 | App (Android/iOS) |
|------|-----------|-----|-------------------|
| 登录 | `uni.login({ provider: 'weixin' })` → 后端 wxLogin | 账号密码登录 | `plus.oauth.getServices()` |
| 扫码 | `uni.scanCode()` | 不支持（需摄像头） | `uni.scanCode()` |
| 推送 | 微信模板消息 | WebSocket / SSE | `plus.push.addEventListener()` |
| 存储 | `uni.setStorageSync` / `uni.getStorageSync` | localStorage | `plus.io` |
| 网络状态 | `uni.getNetworkType()` | `navigator.onLine` | `uni.getNetworkType()` |
| 文件选择 | `uni.chooseImage()` | `<input type="file">` | `plus.gallery.pick()` |

### 样式单位

| 单位 | 使用场景 | 说明 |
|------|---------|------|
| `rpx` | 宽度、间距、字体 | 响应式单位，750rpx = 屏幕宽度 |
| `px` | 边框、阴影 | 固定尺寸 |
| `%` | 弹性布局 | 相对父容器 |
| `vh/vw` | 全屏布局 | 相对视口（仅 H5/App，小程序不支持） |

### 安全区适配

```css
/* 底部安全区 */
padding-bottom: constant(safe-area-inset-bottom);
padding-bottom: env(safe-area-inset-bottom);

/* 顶部状态栏 */
.status-bar {
  height: var(--status-bar-height);
}
```

## 状态管理规范（Pinia）

使用 Pinia setup 风格：`defineStore('name', () => { ... })`，State 用 ref，Getters 用 computed，Actions 为普通函数。

```typescript
// 认证状态
export const useAuthStore = defineStore('auth', () => {
  const token = ref('')
  const userInfo = ref<UserInfo | null>(null)

  const isLogin = computed(() => !!token.value)

  const login = async (credentials: LoginParams) => {
    const res = await apiLogin(credentials)
    token.value = res.data.token
    userInfo.value = res.data.userInfo
    uni.setStorageSync('token', token.value)
  }

  return { token, userInfo, isLogin, login }
})
```

## 网络请求规范

> 网络请求已由 `src/api/request/` 封装，页面中禁止直接使用 `uni.request`。API 调用通过 `src/api/` 层的生成函数完成。

### ResponseData<T> 解析规范

```
列表 API 返回：ResponseData<DataList<T>>
  - 列表数据：res.data?.results     → 类型 T[]（注意是 results，不是 list）
  - 分页总数：res.data?.total

实体 API 返回：ResponseData<T>
  - 实体数据：res.data              → 类型 T

无返回值 API：ResponseData<void>
  - 检查状态：res.state === 'success'
```

### 标准用法

```typescript
import { adminProductList, adminProductLoad } from '@/api/adminProduct'
import type { ProductInfo } from '@/api/adminProduct'

// 列表页
const res = await adminProductList({ param: { $pg: 1, $rn: 20 } })
const list: ProductInfo[] = res.data?.results || []

// 详情页
const res = await adminProductLoad({ id: productId })
const detail: ProductInfo = res.data!
```

## 路由配置规范（pages.json）

| 规范 | 说明 |
|------|------|
| 路径格式 | `pages/{role}/{module}/{page}` |
| 导航栏 | 每个页面配置 `navigationBarTitleText` |
| TabBar | **管理端不使用 TabBar**，采用导航栈 |
| 分包 | 主包 ≤ 2MB，超出使用 `subPackages` 分包 |
| 懒加载 | 非首屏页面使用分包懒加载 |

## 字段一致性原则

| 层级 | 命名规范 | 示例 |
|------|---------|------|
| 数据库字段 | snake_case | `product_name` |
| 后端 DTO 字段 | camelCase | `productName` |
| 前端表单字段 | camelCase（与 DTO 一致） | `productName` |
| 前端列表字段 | camelCase（与 DTO 一致） | `productName` |
| API 参数 | camelCase（与 DTO 一致） | `productName` |

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
| 列表 | 上拉加载分页，单页 ≤ 20 条 |
| 缓存 | 列表页使用 `uni.setStorageSync` 缓存首屏数据 |
| 分包 | 主包 ≤ 2MB，总包 ≤ 20MB（微信小程序） |
| 请求 | 并行请求使用 `Promise.all`，避免瀑布式请求 |
| 页面栈 | 页面栈 ≤ 10 层，超层使用 `uni.reLaunch` |
