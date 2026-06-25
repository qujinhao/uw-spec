# 消费者端UniApp移动端开发规范（Vue3 + TypeScript）

> 面向终端消费者的移动应用（电商小程序、内容App、社交应用）。被 220-guest-uni-dev 引用。

## 技术栈

| 技术               | 版本  | 用途                                           |
| ------------------ | ----- | ---------------------------------------------- |
| UniApp             | 最新  | 跨平台框架                                     |
| Vue 3              | 3.x   | 前端框架（Composition API）                    |
| TypeScript         | 5.x   | 类型安全                                       |
| Pinia              | 2.x   | 状态管理（+ `pinia-plugin-unistorage` 持久化） |
| Vite               | 最新  | 构建工具                                       |
| `@dcloudio/uni-ui` | ^1.5+ | 官方 UI 组件库（`uni-*` 前缀）                 |
| `uview-plus`       | ^3.6+ | 社区 UI 组件库（`u-*` / `up-*` / `u--*` 前缀） |
| `vue-i18n`         | 9.x   | 国际化（zh-CN / zh-TW / en / ja）              |
| `oxlint`           | 最新  | 代码 Lint（替代 ESLint）                       |
| `oxfmt`            | 最新  | 代码格式化（替代 Prettier）                    |

## UI 组件库规范（双 UI 库）

> 项目同时引入 `@dcloudio/uni-ui` 与 `uview-plus`，按场景选择。两者通过 `pages.json` 的 `easycom` 自动注册，无需手动 import。

### easycom 规则（[pages.json](../../../../src/pages.json)）

```json
{
  "easycom": {
    "custom": {
      "^m-(.*)": "@/mall-widgets/m-$1/m-$1.vue",
      "^uni-(.*)": "@dcloudio/uni-ui/lib/uni-$1/uni-$1.vue",
      "^u--(.*)": "uview-plus/components/u-$1/u-$1.vue",
      "^up-(.*)": "uview-plus/components/u-$1/u-$1.vue",
      "^u-([^-].*)": "uview-plus/components/u-$1/u-$1.vue"
    }
  }
}
```

### 组件选型约定

| 前缀                                | 来源                | 适用场景                                                                       |
| ----------------------------------- | ------------------- | ------------------------------------------------------------------------------ |
| `<uni-xxx>`                         | `@dcloudio/uni-ui`  | 标准 UniApp 官方组件（form、list、popup、calendar 等基础组件）                 |
| `<u-xxx>` / `<up-xxx>` / `<u--xxx>` | `uview-plus`        | 复杂 UI 场景（按钮、表单、弹窗、tabs、grid、上传等扩展能力）                   |
| `<m-xxx>`                           | `src/mall-widgets/` | **业务装修组件**（仅装修体系项目存在，如 `m-button`、`m-swiper`、`m-product`） |

| ✅ 推荐                                | ❌ 不推荐                             |
| -------------------------------------- | ------------------------------------- |
| 同一类组件优先选**一个库**保持视觉一致 | 同页面混用两个库的按钮/弹窗           |
| 简单基础能力优先 `uni-ui`              | 简单组件直接用 `uview-plus` 大组件    |
| 自定义业务装修走 `mall-widgets/m-*`    | 把装修逻辑直接写到页面里              |
| 使用 easycom 自动引入                  | 手动 `import` 已被 easycom 注册的组件 |

## 目录结构规范

> 项目采用「主包 + 多个分包根目录」组织。**通用顶层目录固定**，业务分包**默认放入 `src/packages/`**，仅在不希望路由路径携带 `packages/` 前缀时才直接挂到 `src/` 下。

### 通用顶层目录（固定存在）

```
src/
├── api/                       # API 调用封装（gencode 产出，平铺单文件）
│   ├── request/               # 通用请求函数（封装 uni.request、拦截器、错误处理）
│   ├── type/                  # 通用类型（API_TYPE.ts：ResponseData / DataList 等）
│   └── *.ts                   # 各服务 API 函数文件（如 saasMallAppGuestApi.ts、authUwAuthCenterApiAuth.ts）
├── components/                # 全局通用组件
├── config/                    # 项目枚举/常量/站点配置
├── i18n/                      # 多语言文案（zh-CN/zh-TW/en/ja）
├── pages/                     # 主包：入口/登录/渲染容器/WebView 等
│   ├── home/                  # 首页
│   ├── login/                 # 登录/注册/忘记密码
│   ├── render/                # 装修页面渲染容器
│   └── webView/               # WebView 容器
├── packages/                  # 分包根（默认）：所有业务分包尽量放这里
│   ├── setting/               # 用户设置、资料、账号、地址
│   ├── coupon/                # 我的优惠券/领券中心
│   └── view/                  # 景区详情
├── static/                    # 静态资源
│   ├── images/                # 图片资源（按业务域分子目录，如 order/）
│   └── font/                  # 字体（iconfont 等）
├── store/                     # Pinia 状态管理
├── styles/                    # 全局样式
├── types/                     # 全局类型声明
├── utils/                     # 工具函数（auth/storage/tool/...）
├── App.vue
├── main.ts
├── manifest.json
├── pages.json
└── uni.scss
```

### 业务分包放置规则

| 优先级           | 位置                          | 适用场景                                  | 示例                                                      |
| ---------------- | ----------------------------- | ----------------------------------------- | --------------------------------------------------------- |
| **默认（推荐）** | `src/packages/{module}/`      | 绝大多数业务分包                          | `packages/setting/`、`packages/coupon/`、`packages/view/` |
| 特殊情况         | `src/{module}/` 直接挂 src 下 | 业务方不希望路由路径出现 `packages/` 前缀 | `src/product/`、`src/poi/`、`src/user/`、`src/template/`  |

> **特殊位置的分包必须同步在 [pages.json](../../../../src/pages.json) 的 `subPackages[].root` 中显式注册**。新分包默认放入 `src/packages/`，需要特殊位置时由业务方显式确认。

**关键约定**：

| 约定                           | 说明                                                                                                                                      |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 通用目录不可改名/缺失          | `api`、`components`、`config`、`i18n`、`pages`、`packages`、`static`、`store`、`styles`、`types`、`utils`                                 |
| 主包仅放入口与公共容器         | `src/pages/` 不堆放业务详情/列表页                                                                                                        |
| 业务分包默认放 `src/packages/` | 仅在路由不希望带 `packages/` 时才挂 `src/` 根                                                                                             |
| 二级模块沿用 camelCase         | `productDetail`、`placeOrder`、`orderList`、`addressManage`、`accountSafe` 等保持不变                                                     |
| 装修组件统一前缀 `m-`          | 放在 `src/mall-widgets/m-{name}/m-{name}.vue`，通过 `pages.json` easycom 自动注册（仅装修体系项目存在）                                   |
| **API 平铺单文件**             | `src/api/` 下按**服务前缀 camelCase** 平铺：`saasMallAppGuestApi.ts`、`authUwAuthCenterApiAuth.ts`，不再按模块拆目录                      |
| **API 通用基础设施**           | `src/api/request/` 通用请求函数（拦截器/错误处理）、`src/api/type/` 通用类型（`API_TYPE.ts` 中的 `ResponseData<T>`、`DataList<T>` 等）    |
| **静态资源分类**               | `src/static/` 下通常包含 `images/`（图片）与 `font/`（字体/iconfont）两个子目录；TabBar 图标可放 `static/tabbar/`，图片按业务域再分子目录 |

## 页面布局模式

消费者端通常采用「**单页/多分包页面 + 可选 TabBar**」模式，**TabBar 是否启用由业务决定，非强制**。当前项目（`uw-uni-template`）即未配置 TabBar。

**启用 TabBar 的项目**：

```
┌─────────────────────┐
│  Logo    [搜索] [消息]│  ← 自定义顶部导航（部分页面）
├─────────────────────┤
│                     │
│    内容区域          │  ← 页面主体
│                     │
├─────────────────────┤
│  首页  分类  发现  我的│  ← TabBar（底部固定，Tab 数量由 PRD 决定）
└─────────────────────┘
```

**未启用 TabBar 的项目**：通过自定义底部组件、单页面入口或装修模板渲染容器（如 [pages/render/index.vue](../../../../src/pages/render/index.vue)）实现导航。

### 导航模式

| 场景       | 导航方式                     | 说明                       |
| ---------- | ---------------------------- | -------------------------- |
| 主功能切换 | TabBar（如启用）或自定义底部 | 一级页面（数量由业务决定） |
| 内容详情   | 栈式导航（uni.navigateTo）   | 从列表进入详情页           |
| 功能表单   | 栈式导航（uni.navigateTo）   | 填写表单、编辑资料         |
| 登录/授权  | 全屏覆盖（uni.redirectTo）   | 替换当前页面栈             |
| 支付结果   | 重定向（uni.reLaunch）       | 清除栈到结果页             |

## 页面编码规范

### SFC 结构顺序

```vue
<template>...</template>
<script setup lang="ts">
...
</script>
<style scoped lang="scss">
...
</style>
```

### 命名规范

| 类型       | 规范                                        | 示例                                                                           |
| ---------- | ------------------------------------------- | ------------------------------------------------------------------------------ |
| 页面文件   | camelCase 或 kebab-case，沿用现有项目       | `productDetail/index.vue`、`orderList/index.vue`、`forgetPassword.vue`         |
| 组件文件   | PascalCase（推荐）或 kebab-case（沿用）     | `OrderItem.vue`、`render-widget.vue`                                           |
| 装修组件   | `m-{name}` 前缀                             | `m-button/m-button.vue`                                                        |
| Store 文件 | kebab-case                                  | `user.ts`                                                                      |
| API 文件   | 服务前缀 camelCase                          | `saasMallAppGuestApi.ts`、`authUwAuthCenterApiAuth.ts`                         |
| 类型文件   | UPPER_SNAKE 或 kebab-case                   | `API_TYPE.ts`、`type.ts`                                                       |
| 页面路径   | `{root}/{module}/{page}`，主包/分包分别配置 | `pages/home/index`、`product/productDetail/index`、`packages/setting/userInfo` |

### `<script setup>` 规范

```typescript
// 1. 类型导入（从 api 层导入）
import type { CmsArticle } from '@/api/cmsArticle'

// 2. API 导入
import { cmsArticleList } from '@/api/cmsArticle'

// 3. Store 导入
import { useUserStore } from '@/store/user'

// 4. Store 解构（如需响应式）
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

| 场景                 | 使用钩子                  | 说明                             |
| -------------------- | ------------------------- | -------------------------------- |
| 页面初始化、获取参数 | `onLoad((options) => {})` | 仅页面级可用，options 为页面参数 |
| 页面每次显示         | `onShow(() => {})`        | 从其他页面返回或从后台切回时触发 |
| 页面隐藏             | `onHide(() => {})`        | 跳转其他页面或切后台             |
| DOM 首次就绪         | `onReady(() => {})`       | 仅触发一次，适合获取节点信息     |
| 页面卸载             | `onUnload(() => {})`      | 清理定时器、取消请求             |
| 组件初始化           | `onMounted(() => {})`     | Vue 标准钩子，组件内使用         |

**使用原则**：

- TabBar 页面在 `onShow` 中刷新数据（返回时自动触发）
- 页面级逻辑（获取参数）用 UniApp 钩子（`onLoad`）
- 组件级逻辑（初始化、销毁）用 Vue 钩子（`onMounted`/`onUnmounted`）

```typescript
import { onLoad, onShow } from "@dcloudio/uni-app";

onLoad((options) => {
  const id = options.id;
  loadDetail(id);
});

onShow(() => {
  // TabBar 页面返回时刷新未读数
  if (tabBarNeedsRefresh.value) {
    fetchUnreadCount();
  }
});
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

| 校验类型 | 实现方式           | 示例                                                     |
| -------- | ------------------ | -------------------------------------------------------- |
| 必填     | 表单提交前检查空值 | `if (!form.phone) { showToast('请输入手机号'); return }` |
| 格式     | 正则校验           | 手机号、验证码                                           |
| 长度     | 字符串长度判断     | `if (form.comment.length > 200) { ... }`                 |

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

| 能力 | 微信小程序                                         | H5                  | App (Android/iOS)                            |
| ---- | -------------------------------------------------- | ------------------- | -------------------------------------------- |
| 登录 | `uni.login({ provider: 'weixin' })` → 后端 wxLogin | 手机号验证码登录    | `plus.oauth.getServices()`                   |
| 分享 | `onShareAppMessage()` / `onShareTimeline()`        | `navigator.share()` | `plus.share.sendWithSystem()`                |
| 支付 | `uni.requestPayment({ provider: 'wxpay' })`        | 跳转支付页          | `uni.requestPayment({ provider: 'alipay' })` |
| 定位 | `uni.getLocation()`                                | HTML5 Geolocation   | `uni.getLocation()`                          |
| 扫码 | `uni.scanCode()`                                   | 不支持              | `uni.scanCode()`                             |
| 存储 | `uni.setStorageSync`                               | localStorage        | `plus.io`                                    |

### 样式单位

| 单位    | 使用场景         | 说明                                |
| ------- | ---------------- | ----------------------------------- |
| `rpx`   | 宽度、间距、字体 | 响应式单位，750rpx = 屏幕宽度       |
| `px`    | 边框、阴影       | 固定尺寸                            |
| `%`     | 弹性布局         | 相对父容器                          |
| `vh/vw` | 全屏布局         | 相对视口（仅 H5/App，小程序不支持） |

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

> 对齐现有项目 [src/store/](../../../../src/store) 实际风格，避免重复造轮子。

### 风格与目录

| 约定           | 说明                                                                                                                                                          |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Store 实例化   | [src/store/index.ts](../../../../src/store/index.ts) 中 `createPinia()` + `pinia-plugin-unistorage` 插件，全局开启持久化                                      |
| Store 定义风格 | **setup 风格**：`defineStore('name', () => { ... }, { unistorage: true })`                                                                                    |
| 文件命名       | kebab-case，按业务域单文件：`user.ts`（用户/登录/Token）、`main.ts`（应用配置/i18n/域名/支付配置）等                                                          |
| State          | 用 `ref()` 定义，命名 camelCase（如 `loginInfo`、`userInfo`、`siteInfo`、`saasDomain`）                                                                       |
| Getters        | 用 `computed()` 定义（如 `token`、`saasId`、`isRealWeiXin`、`DEV`）                                                                                           |
| Actions        | 用普通函数定义，命名采用 `setXxx` / `clearXxx` / `handleGetXxx` 等动词前缀                                                                                    |
| 退出/重大操作  | 沿用现有命名（如 `LogOut`、`clearLoginCache`、`handleGetUploadDomain`）                                                                                       |
| 持久化         | 通过 `{ unistorage: true }` 第三参开启 store 级持久化，不再手写 `uni.setStorageSync`/`uni.removeStorageSync` 来同步 state                                     |
| 副作用同步     | 跨 store 同步用 `watch(() => xxx, (v) => {...}, { immediate: true })`（参考 [user.ts](../../../../src/store/user.ts) 中 `loginInfo` → `tokenManager` 的同步） |
| 类型来源       | 直接从 `@/api/{service}Api` 导入业务类型，本地补充时定义 `interface SiteInfo` 即可，无强制约束                                                                |
| 统一导出       | 末尾 `return { ...state, ...getters, ...actions }` 集中导出，分组用注释分割 `/* state */`、`/* getters */`、`/* actions */`                                   |

### 推荐模板（对齐 [user.ts](../../../../src/store/user.ts)）

```typescript
import { defineStore } from "pinia";
import { ref, computed, watch } from "vue";
import type { TokenResponse } from "@/api/saasMallAppOpenApi";
import { setAuthToken, getAuthToken } from "@/utils/auth";

interface SiteInfo {
  siteId: number;
  saasId: number;
}

export const useUserStore = defineStore(
  "user",
  () => {
    /* ---------- state ---------- */
    const loginInfo = ref<TokenResponse>({});
    const userInfo = ref<Record<string, any>>({});
    const outSideToken = ref<string>(getAuthToken() || "");

    /* ---------- getters ---------- */
    const token = computed(() => loginInfo.value?.token || "");
    const isLogin = computed(() => !!token.value);

    /* ---------- watch（跨 store / 副作用同步）---------- */
    watch(
      () => loginInfo.value,
      (newVal) => {
        // 例如：同步到 tokenManager / 本地存储
      },
      { immediate: true, deep: true },
    );

    /* ---------- actions ---------- */
    function setLoginInfo(info: TokenResponse) {
      loginInfo.value = info;
    }

    function setToken(t: string) {
      setAuthToken(t);
      outSideToken.value = t;
    }

    function clearLoginCache() {
      loginInfo.value = {};
      userInfo.value = {};
    }

    function LogOut() {
      clearLoginCache();
      uni.reLaunch({ url: "/pages/login/index" });
    }

    /* ---------- 统一导出 ---------- */
    return {
      /* state */
      loginInfo,
      userInfo,
      outSideToken,
      /* getters */
      token,
      isLogin,
      /* actions */
      setLoginInfo,
      setToken,
      clearLoginCache,
      LogOut,
    };
  },
  {
    unistorage: true, // 开启 state 持久化（pinia-plugin-unistorage）
  },
);
```

### 现有 Store 一览

| Store  | 文件                                               | 职责                                                                 |
| ------ | -------------------------------------------------- | -------------------------------------------------------------------- |
| `user` | [src/store/user.ts](../../../../src/store/user.ts) | 登录信息、用户信息、Token、站点 saasId、登录代理、场景值等           |
| `main` | [src/store/main.ts](../../../../src/store/main.ts) | 语言、UI 样式常量、站点项目信息、OSS 域名、支付配置、浏览器/系统信息 |

> 新增 Store 前应先检查 `user` / `main` 是否已有适配字段，避免重复建立同类 Store。

## 登录 / Token / 多租户体系规范

> 项目的登录与多租户能力由 `useUserStore` + `useMainStore` + `utils/tokenManager` + `utils/auth` + `api/request` 协同实现，**新业务页面不要再造同名机制**。

### 体系架构

```
┌──────────────────────┐         ┌──────────────────────┐
│  useUserStore        │ watch   │  utils/tokenManager  │
│  - loginInfo         │ ──────► │  - currentToken      │
│  - userInfo          │         │  - currentRefresh    │
│  - siteInfo          │         │  - currentSaasId     │
│  - outSideToken      │         └──────────┬───────────┘
│  - openId/scene/...  │                    │
└──────────┬───────────┘                    │ getToken()
           │ setLoginInfo()                 ▼
           │ setUserInfo()         ┌──────────────────────┐
           │ setSiteInfo()         │  api/request/index   │
           │ clearLoginCache()     │  - Authorization     │
           │ LogOut()              │  - 401 自动 refresh  │
           ▼                       │  - Subject/Observer  │
   uni.* / 业务页面                └──────────────────────┘
```

### 关键模块

| 模块         | 文件                                                                 | 职责                                                                                                                   |
| ------------ | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 用户 Store   | [src/store/user.ts](../../../../src/store/user.ts)                   | 登录信息、用户信息、站点信息、外部 token、appId、openId、scene、dyVideoId 等持久化状态                                 |
| 应用 Store   | [src/store/main.ts](../../../../src/store/main.ts)                   | 语言、UI 常量、OSS 域名、支付配置、登录代理                                                                            |
| Token 管理器 | [src/utils/tokenManager.ts](../../../../src/utils/tokenManager.ts)   | 解耦 store 与 request 的循环依赖；维护 `currentToken / currentRefreshToken / currentSaasId`；提供 `onTokenChange` 订阅 |
| 鉴权工具     | [src/utils/auth.ts](../../../../src/utils/auth.ts)                   | `getAuthToken / setAuthToken / removeAuthToken`（基于 sessionStorage，用于外部 token 注入）                            |
| 站点配置     | [src/config/initSiteInfo.ts](../../../../src/config/initSiteInfo.ts) | 默认 `defaultSiteInfo = { siteId, saasId }`                                                                            |
| 请求拦截     | [src/api/request/index.ts](../../../../src/api/request/index.ts)     | 自动注入 `Authorization: Bearer <token>` + `Accept-Language`；401 触发 refresh；接口白名单；大数字 JSON 处理           |

### Token 体系（三层）

| 层             | 来源                                                    | 说明                                                                                 |
| -------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **真实 token** | `loginInfo.token`（登录后写入）                         | 通过 `useUserStore().setLoginInfo()` 设置，自动同步到 `tokenManager`                 |
| **外部 token** | URL query `?token=xxx` 或装修预览 `requestConfig.token` | 通过 `useUserStore().setToken()` 写入 sessionStorage；常用于 H5 嵌入、装修预览       |
| **匿名 token** | `0$1!0@${saasId}`                                       | `tokenManager.getToken()` 在无真实/外部 token 时自动生成，用于游客身份调用白名单接口 |

> 实际取值优先级：`loginInfo.token` > `outSideToken`(sessionStorage) > 匿名 token。请求层通过 `getToken()` 统一获取。

### 多租户（saasId / siteId）

| 字段               | 来源                                                                               | 用途                                                             |
| ------------------ | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `siteInfo.saasId`  | [defaultSiteInfo](../../../../src/config/initSiteInfo.ts) 或运行时 `setSiteInfo()` | 多租户隔离 ID，决定后端数据范围                                  |
| `siteInfo.siteId`  | 同上                                                                               | 站点 ID（同一 saas 可有多站点）                                  |
| `loginInfo.saasId` | 登录返回                                                                           | 登录后覆盖默认 saasId                                            |
| 实际生效           | `computed(() => loginInfo.saasId \|\| siteInfo.saasId)`                            | 通过 `watch` 同步到 `tokenManager.currentSaasId`，影响匿名 token |

### 多平台 appId

| 字段        | 来源                                                            | 用途                                                         |
| ----------- | --------------------------------------------------------------- | ------------------------------------------------------------ |
| `appId`     | [manifest.json](../../../../src/manifest.json) 中各平台 `appid` | 通过 `setAppId()` 按 `process.env.VUE_APP_PLATFORM` 自动选取 |
| `openId`    | 平台登录回调                                                    | 微信/支付宝小程序的用户 openId                               |
| `scene`     | 平台启动参数                                                    | 进入场景值（小程序），用于业务埋点                           |
| `dyVideoId` | 抖音平台                                                        | 抖音视频 ID（带货场景）                                      |

### 401 自动 Refresh 流程

> 由 [request/index.ts](../../../../src/api/request/index.ts) 实现，**新页面无需关心**：

1. 业务接口返回 `statusCode === 401`（非登录接口）
2. 请求被加入 `Subject` 订阅队列，挂起
3. `__API_LOGIN_` 标志加锁，触发 `uw-auth-center/auth/refreshToken`
4. 刷新成功 → 调用 `setRefreshTokenInfo()` 更新 token → `notifyTokenChange()` → 所有 `Observer` 重新发起原请求
5. 刷新失败 → `clearLoginCache()` → `uni.reLaunch('/pages/login/index')`

### 接口白名单

[request/index.ts](../../../../src/api/request/index.ts) 中维护 `APIwhiteList`，登录/注册/验证码/站点初始化等接口可使用匿名 token 调用，**不需要登录态**。新增此类接口需同步加入白名单。

### 业务约定

| ✅ 正确                                             | ❌ 错误                                            |
| --------------------------------------------------- | -------------------------------------------------- |
| 登录成功后调用 `userStore.setLoginInfo(res.data)`   | 直接 `userStore.loginInfo = res.data` 后跳过 watch |
| 外部 H5 嵌入注入 token 用 `userStore.setToken(t)`   | 直接 `uni.setStorageSync('token', t)`              |
| 读取 token 用 `userStore.token`（computed）         | 自己拼 `0$1!0@${saasId}` 匿名 token                |
| 退出登录调用 `userStore.LogOut()`（含后端登出接口） | 仅 `clearLoginCache()` 不调后端                    |
| 多语言请求头通过 request 拦截器自动注入             | 页面里手动加 `Accept-Language`                     |
| 站点切换走 `userStore.setSiteInfo()`                | 直接改 `defaultSiteInfo` 常量                      |
| 多平台 appId 走 `userStore.setAppId()`              | 在页面硬编码 appid                                 |

### 典型登录页代码模板

```typescript
import { useUserStore } from "@/store/user";
import { useMainStore } from "@/store/main";
import { guestAuthLogin } from "@/api/saasMallAppOpenApi";

const userStore = useUserStore();
const mainStore = useMainStore();

const handleLogin = async () => {
  const res = await guestAuthLogin({
    data: {
      account: form.account,
      password: form.password,
      loginAgent: mainStore.loginAgent, // `${name}:${version}`
      saasId: userStore.siteInfo.saasId,
    },
  });
  if (res.state === "success" && res.data) {
    userStore.setLoginInfo(res.data); // 自动同步 tokenManager + 持久化
    await userStore.setUserInfo(); // 拉取用户信息
    uni.reLaunch({ url: "/pages/home/index" });
  } else {
    uni.showToast({ title: res.msg, icon: "none" });
  }
};
```

### 外部 token 注入模板（装修预览 / H5 嵌入）

```typescript
// onLoad 或入口页
const launch = uni.getLaunchOptionsSync();
if (launch.query?.token && launch.query.token !== "null") {
  userStore.setToken(launch.query.token); // 写入 sessionStorage，跳转后不丢失
}
if (launch.query?.requestConfig) {
  const cfg = JSON.parse(launch.query.requestConfig);
  if (cfg.token) userStore.setToken(cfg.token);
}
```

## 装修 / 渲染引擎规范

> 项目内置「装修 DSL + `m-*` 组件库 + render-widget 渲染器」三件套，是项目的核心特色。新增装修能力请遵循以下约定。

### 体系架构

```
┌────────────────────────┐
│  装修平台（外部 iframe）│
│  postMessage(init/move │
│   /drop/list/...)      │
└──────────┬─────────────┘
           │ window.message
           ▼
┌────────────────────────────────────────┐
│ src/pages/render/index.vue             │
│ - 接收平台消息（init/move/drop/list）  │
│ - 维护 list[] = ComponentItem[]        │
│ - vuedraggable 渲染                    │
│ - listeningDom() 上报高度              │
└──────────┬─────────────────────────────┘
           │ v-for
           ▼
┌────────────────────────────────────────┐
│ <widget-shape :widget>                 │
│   <render-widget :item :component-msg> │
│     ↓ 根据 item.component 分发         │
│     <m-swiper> / <m-product> / ...     │
│   </render-widget>                     │
│ </widget-shape>                        │
└────────────────────────────────────────┘
```

### 关键模块

| 模块        | 文件                                                                             | 职责                                                                                 |
| ----------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 渲染容器    | [src/pages/render/index.vue](../../../../src/pages/render/index.vue)             | 装修预览页，监听 `window.message`，维护 `list` + `pageConfig`，向父窗口回传高度/封面 |
| 形状包装    | [src/components/widget-shape.vue](../../../../src/components/widget-shape.vue)   | 给每个装修组件加边距/选中态/拖拽容器                                                 |
| 渲染分发    | [src/components/render-widget.vue](../../../../src/components/render-widget.vue) | 根据 `item.component` 字符串分发到对应 `m-*` 组件                                    |
| 装修组件库  | [src/mall-widgets/](../../../../src/mall-widgets)                                | `m-*` 装修组件（≈25 个：m-swiper / m-product / m-cap-cube / m-cms / ...）            |
| Schema 描述 | [src/schema/](../../../../src/schema)                                            | 每个装修组件的字段配置（`component.json`），供装修平台生成属性面板                   |
| 装修模板    | [src/template/](../../../../src/template)                                        | 装修示例模板分包（首页/Tab 模板/自定义页等）                                         |

### 装修组件 DSL（`item` 数据结构）

```typescript
interface WidgetItem {
  id: string; // 唯一 ID（widget+id 用于 DOM 锚点）
  component: string; // 组件名，如 'm-swiper' / 'm-product' / 'waiting'
  attrs?: Record<string, any>; // 业务属性（数据源、行列、模板号等）
  styles?: Record<string, any>; // 视觉样式（padding、radius、background...）
  options?: Record<string, any>; // 编辑器附加配置（如 catalogId、绑定的内容来源）
  listField?: { pathKey?: string; imgKey?: string }; // 数据字段映射
  height?: number; // 由 render 页计算后回传给装修平台
}
```

> 每个装修组件必须能接收 `attrs` / `styles` / `list`（或 `data` / `lists`），并通过 `@jump` 触发跳转。

### 新增装修组件流程

| 步骤            | 操作                                                                                                                                   |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 创建目录     | `src/mall-widgets/m-{name}/`，约定结构：`m-{name}.vue` + 可选 `type.ts`（Props 类型） + 可选 `style/index.scss` + 可选 `images/`       |
| 2. 类型定义     | 在 `type.ts` 中导出 `Attrs` / `Styles` / 其他 props 接口（参考 [m-cap-cube/type.ts](../../../../src/mall-widgets/m-cap-cube/type.ts)） |
| 3. 实现组件     | Props: `attrs: Attrs`、`styles: Styles`、`list?: any[]`；通过 `defineEmits(['jump'])` 触发跳转                                         |
| 4. 注册分发     | 在 [render-widget.vue](../../../../src/components/render-widget.vue) 中添加 `v-if="item.component == 'm-{name}'"` 分支                 |
| 5. Schema 描述  | 在 [src/schema/m-{name}/component.json](../../../../src/schema/m-search/component.json) 定义字段（name/icon/fields），供装修平台读取   |
| 6. easycom 注册 | `m-*` 已通过 `pages.json` easycom 规则 `^m-(.*)` 自动注册，无需 import                                                                 |
| 7. 公共样式     | 如有共享样式注册到 [mall-widgets/utils/registerBaseStyle.ts](../../../../src/mall-widgets/utils/registerBaseStyle.ts)                  |

### 约定

| ✅ 正确                                                                                                       | ❌ 错误                                   |
| ------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| `m-*` 装修组件统一放 `src/mall-widgets/`                                                                      | 把装修组件放到 `src/components/`          |
| 业务页面引用装修组件用 `<m-xxx>`（easycom 注册）                                                              | 手动 `import` 装修组件                    |
| 装修组件接收 `attrs` / `styles` / `list` 三类 props                                                           | 把所有配置混在一个对象里                  |
| 装修页面通过 `<render-widget :item>` 渲染                                                                     | 在业务页面手写 `v-if` 分发                |
| 跳转通过 `emit('jump', target)` 上抛                                                                          | 装修组件内部直接 `uni.navigateTo`         |
| schema 字段定义放 `src/schema/m-{name}/component.json`                                                        | 把字段配置塞到 `.vue` 里                  |
| 装修预览页处理 `window.message` 与父平台通信                                                                  | 装修组件内部直接 `postMessage`            |
| 外部 token / requestConfig 由 [pages/render/index.vue](../../../../src/pages/render/index.vue) 在入口统一处理 | 每个装修组件自己读 `getLaunchOptionsSync` |

### 装修页面与正式页面的关系

| 用途                               | 文件                                                             | 说明                               |
| ---------------------------------- | ---------------------------------------------------------------- | ---------------------------------- |
| **装修预览**（带平台 iframe 通信） | [pages/render/index.vue](../../../../src/pages/render/index.vue) | 接收 `init` 等消息，可拖拽编辑     |
| **正式页面渲染**                   | 业务页面引用 `<render-widget :item>` 即可静态渲染装修 DSL        | 不需要 vuedraggable / postMessage  |
| **示例模板**                       | [template/](../../../../src/template)                            | 装修模板分包，包含完整页面结构示例 |

> **新业务页面**如需复用装修体系，直接用 `<render-widget :item="widget" :component-msg="data" />` 渲染 DSL，不要复制 `render/index.vue` 的 postMessage 逻辑。

## 样式体系规范

> 项目同时支持 **Tailwind CSS v4**（含 `weapp-tailwindcss` 小程序兼容）+ **SCSS** + **uni.scss / uview-plus theme**。

### 优先级（必读）

1. **Tailwind class（最高）**：原子化、无需写 `<style>`、易复用、构建期 PurgeCSS，**新写代码默认走 Tailwind**
2. **SCSS（其次）**：以下场景才允许使用：
   - 动态/复杂样式（如 `:style="{ backgroundImage: url(...) }"` 不可表达的复杂选择器、伪类、动画 keyframes）
   - 组件内私有样式（建议加 `scoped`）
   - 复用 `src/styles/base.scss` 中的公共 class（`.ellipsis` / `.div-shadow` / `.div-line` 等）
3. **行内 `style`（最后）**：仅用于真正动态的样式值（变量驱动、运行时拼接），禁止用于固定样式

### 关键文件与机制

| 文件                                                       | 职责                                                                                                                              |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| [src/app.css](../../../../src/app.css)                     | Tailwind 入口 + 主题变量 `@theme`（`--color-primary` / `--color-foreground` / 行程状态色等）                                      |
| [src/main.css](../../../../src/main.css)                   | `@import "tailwindcss/css"`，配置 `@source not` 排除目录                                                                          |
| [src/styles/base.scss](../../../../src/styles/base.scss)   | 全局基础样式：`box-sizing`、`.ellipsis` / `.ellipsis2` / `.ellipsis3`、`.div-shadow` / `.div-br` / `.div-line`、`.order-btn-item` |
| [src/styles/index.scss](../../../../src/styles/index.scss) | 仅 `@import "base.scss"`                                                                                                          |
| [src/uni.scss](../../../../src/uni.scss)                   | `@import "uview-plus/theme.scss"`（uview-plus 主题变量）                                                                          |
| [vite.config.ts](../../../../vite.config.ts)               | `UnifiedViteWeappTailwindcssPlugin`（小程序 Tailwind 兼容） + `tailwindcss postcss`（H5/MP 平台条件加载）                         |

### 主题变量（来自 [src/app.css](../../../../src/app.css)）

直接通过 Tailwind 颜色 class 使用，如 `bg-primary` / `text-foreground` / `border-border`：

| 类别       | 变量                                                                           | 用途                  |
| ---------- | ------------------------------------------------------------------------------ | --------------------- |
| 主色       | `--color-primary` `#ff6b4a`（珊瑚橙）                                          | 主题主色，按钮/CTA    |
| 主色辅助   | `--color-primary-light` `--color-primary-bg` `--color-primary-buy`             | 浅底/购买强调         |
| 多站点主题 | `--color-primary-gz/zh/qy`                                                     | 广州/珠海/清远        |
| 语义色     | `--color-success` `--color-warning` `--color-destructive` `--color-info`       | 状态提示              |
| 表面色     | `--color-background` `--color-surface` `--color-muted` `--color-border`        | 页面/卡片/输入框/边框 |
| 文字色     | `--color-foreground` `--color-foreground-secondary` `--color-foreground-muted` | 主/次/弱文字          |
| 功能色     | `--color-like` `--color-collected` `--color-ai` `--color-trip-*`               | 点赞/收藏/AI/行程状态 |

### 单位规范

| 平台 / 场景             | 推荐单位                                                                           |
| ----------------------- | ---------------------------------------------------------------------------------- |
| 装修/小程序内 SCSS 尺寸 | `rpx`（750 设计稿基准）                                                            |
| Tailwind class          | Tailwind 默认尺寸（`p-4` / `text-sm` ...），`rem2rpx: false` 不自动转换            |
| 字号（page 全局）       | [base.scss](../../../../src/styles/base.scss) 已定义 `page { font-size: 28rpx }`   |
| 安全区 / 刘海屏         | 通过 `mainStore.statusHeight`（顶部状态栏 px）+ `env(safe-area-inset-bottom)` 处理 |

### 推荐写法

```vue
<template>
  <!-- ✅ Tailwind 优先 -->
  <view class="flex items-center justify-between bg-surface px-4 py-3 rounded-lg">
    <text class="text-foreground text-base">{{ title }}</text>
    <text class="text-primary text-sm">{{ price }}</text>
  </view>

  <!-- ✅ 复用 base.scss 公共 class（多行省略号） -->
  <text class="ellipsis2">{{ description }}</text>

  <!-- ✅ 行内 style 仅用于动态值 -->
  <view :style="{ backgroundImage: `url(${bgUrl})` }" />

  <!-- ❌ 不要：在 SCSS 中重复实现 Tailwind 已能表达的样式 -->
  <!-- ❌ 不要：在 <template> 中写大量行内 style 固定样式 -->
</template>

<style lang="scss" scoped>
/* 仅在 Tailwind 无法表达时使用 SCSS */
.complex-animation {
  @keyframes slide-in {
    from {
      transform: translateX(-100%);
    }
    to {
      transform: translateX(0);
    }
  }
  animation: slide-in 0.3s ease-out;
}
</style>
```

### 关键约定

| ✅ 正确                                                               | ❌ 错误                                                |
| --------------------------------------------------------------------- | ------------------------------------------------------ |
| 新写代码默认走 Tailwind class                                         | 简单样式也写一大段 SCSS                                |
| 颜色用 `bg-primary` / `text-foreground` 等主题 class                  | 硬编码 `#ff6b4a` / `#1c1a19` 等十六进制色              |
| 多行省略号复用 `.ellipsis2` / `.ellipsis3`                            | 在每个组件里重写 `-webkit-line-clamp`                  |
| 卡片阴影复用 `.div-shadow`                                            | 重复写 `box-shadow: 0px 2px 20px 0px rgba(0,0,0,0.05)` |
| 安全区高度用 `mainStore.statusHeight` + `env(safe-area-inset-bottom)` | 硬编码 `padding-top: 44px`                             |
| SCSS 必须加 `scoped`                                                  | 全局 `<style>` 污染其他组件                            |
| 小程序兼容 Tailwind 已由 `weapp-tailwindcss` 处理，直接写 class       | 为了兼容小程序退回纯 SCSS                              |
| 装修组件保留必要的 inline `:style` 驱动配置                           | 装修组件把所有动态样式写成 SCSS 类名                   |

## 业务通用组件清单（新增页面优先复用）

> 来源：[src/components/](../../../../src/components)。新增页面前请先查此表，能复用即复用，避免重复造同类组件。

### 命名规范

| 前缀                 | 含义                                             | 示例                                                                                               |
| -------------------- | ------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| `Z*`                 | 自研业务组件（zowoyoo 系），偏视觉/容器/能力封装 | `ZCalendar`、`ZRichText`、`ZScrollView`、`ZTag`、`ZTitle`、`ZUp`、`ZScenicInfo`、`ZDateScrollView` |
| `Gb*`                | 全局通用组件（Global），偏 UI 框架级             | `GbLoading`、`GbNavbar`                                                                            |
| 业务名               | 单一职责的业务弹窗/能力组件，按业务命名          | `PaymentPopup`、`SharePopup`、`Verify`、`NavBar`                                                   |
| `*-cmp` / kebab-case | 渲染/装修体系内部使用的辅助组件                  | `waiting-cmp`、`render-widget`、`widget-shape`                                                     |

### 现有组件目录索引

| 组件                | 路径                                                                         | 用途 / 适用场景                                                       |
| ------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| **GbLoading**       | [components/GbLoading/](../../../../src/components/GbLoading)                | 全局加载占位（含 `LoopLoading` 子组件），列表/页面级 Loading 统一用它 |
| **GbNavbar**        | [components/GbNavbar/](../../../../src/components/GbNavbar)                  | 全局自定义导航栏（支持 Tailwind 主题），需要自绘顶部时使用            |
| **NavBar**          | [components/NavBar/](../../../../src/components/NavBar)                      | 业务级导航栏（搜索/分类等顶部组合）                                   |
| **ZCalendar**       | [components/ZCalendar/](../../../../src/components/ZCalendar)                | 日期选择日历（含独立 `style/index.scss`），出行/预订选日期            |
| **ZDateScrollView** | [components/ZDateScrollView/](../../../../src/components/ZDateScrollView)    | 横向日期滚动条，多日预订日期切换                                      |
| **ZRichText**       | [components/ZRichText/](../../../../src/components/ZRichText)                | 富文本渲染（封装 `mp-html`），商品详情/资讯正文                       |
| **ZScenicInfo**     | [components/ZScenicInfo/](../../../../src/components/ZScenicInfo)            | 景点信息卡片，旅游/POI 场景                                           |
| **ZScrollView**     | [components/ZScrollView/](../../../../src/components/ZScrollView)            | 通用滚动容器（处理懒加载/触底）                                       |
| **ZTag**            | [components/ZTag/](../../../../src/components/ZTag)                          | 标签组件，分类/属性展示                                               |
| **ZTitle**          | [components/ZTitle/](../../../../src/components/ZTitle)                      | 区块标题，列表分区头部                                                |
| **ZUp**             | [components/ZUp/](../../../../src/components/ZUp)                            | 文件/图片上传，表单上传场景                                           |
| **PaymentPopup**    | [components/PaymentPopup/](../../../../src/components/PaymentPopup)          | 支付方式选择弹窗（配合 `mainStore.paymentConfigList`）                |
| **SharePopup**      | [components/SharePopup/](../../../../src/components/SharePopup)              | 分享方式选择弹窗（H5/小程序/App 三端）                                |
| **Verify**          | [components/Verify/](../../../../src/components/Verify)                      | 行为验证码（输入/点选/旋转/滑动 4 种），登录/敏感操作前置校验         |
| **waiting-cmp**     | [components/waiting-cmp/](../../../../src/components/waiting-cmp)            | 装修拖拽时的占位组件（仅装修体系使用）                                |
| **render-widget**   | [components/render-widget.vue](../../../../src/components/render-widget.vue) | 装修 DSL 渲染分发器（详见装修规范）                                   |
| **widget-shape**    | [components/widget-shape.vue](../../../../src/components/widget-shape.vue)   | 装修组件的形状/选中态包装容器                                         |

### 复用决策流程

```
新页面需要某 UI 能力
        ↓
  Step 1：本表是否有 Z* / Gb* / 业务组件可直接用？──► 用之
        ↓ 否
  Step 2：uview-plus（u-* / up-*）是否有？        ──► 用之
        ↓ 否
  Step 3：@dcloudio/uni-ui（uni-*）是否有？       ──► 用之
        ↓ 否
  Step 4：是否是装修能力 → mall-widgets（m-*）？  ──► 用之 / 新增 m-{name}
        ↓ 否
  Step 5：自研，放 src/components/ 下，按命名规范命名（Z* / Gb* / 业务名）
```

### 新增通用组件约定

| ✅ 正确                                                                                                | ❌ 错误                                                   |
| ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------- |
| 自研通用组件放 `src/components/{Name}/index.vue`                                                       | 散落在某个业务页面目录里复制粘贴                          |
| 命名遵循 `Z*` / `Gb*` / 业务名 三类前缀                                                                | 用 kebab-case 命名业务组件（kebab-case 留给装修体系内部） |
| 独立 `style/index.scss` 放组件目录下                                                                   | 把组件样式写到全局 `styles/base.scss`                     |
| 组件类型定义放 `type.ts`（如 [PaymentPopup/type.ts](../../../../src/components/PaymentPopup/type.ts)） | 在 `.vue` 内重复定义类型                                  |
| Props 通过 `defineProps<T>()` + `withDefaults`，事件通过 `defineEmits<{...}>()`                        | 用 Options API 风格                                       |
| 新增前先查本表 + 看现有组件能否扩展                                                                    | 直接复制粘贴造同类组件                                    |

### 何时新增 vs 何时扩展

- 现有组件能覆盖 **80%** 场景 → **扩展 Props** 复用
- 完全不同的能力（如新的弹窗类型、新的列表容器）→ **新增组件**
- 仅样式不同（颜色/尺寸）→ **通过 Tailwind class** 控制，不新增组件

## 枚举与字典体系规范

> 项目通过「后端字典 → JSON 中转 → 自动生成 enum/options」的方式实现统一枚举体系。**所有 CRUD/表单/筛选/状态判断必须复用生成产物**，不要手写魔数。

### 体系架构

```
┌──────────────────────┐
│ 后端字典接口          │ HTTP
│ (EnumLabelMap)       │ ───────┐
└──────────────────────┘        ▼
                        ┌────────────────────────────────┐
                        │ src/config/EnumLabelMap.json   │  ◄── 中转原始数据（含 data 字段）
                        └──────────┬─────────────────────┘
                                   │ pnpm gen:enums
                                   ▼
                  ┌────────────────────────────────────────────┐
                  │ scripts/generate-enums.js                  │
                  └────┬─────────────────────────────┬─────────┘
                       │                             │
                       ▼                             ▼
       ┌──────────────────────┐         ┌──────────────────────────┐
       │ src/config/          │         │ src/config/              │
       │   EnumConst.ts       │         │   optionsConst.ts        │
       │ export enum 形式     │         │ export const XxxOptions  │
       │ 用于判断/比较/赋值   │         │ 用于 Picker/Select 渲染  │
       └──────────────────────┘         └──────────────────────────┘
                       │
                       │  ──── 业务手写扩展，生成器不覆盖
                       ▼
       ┌──────────────────────┐
       │ src/config/          │
       │   EnumExtend.ts      │  ◄── 业务特有/前端独有的枚举与映射
       └──────────────────────┘
```

### 关键文件

| 文件                                                                                     | 类型                   | 说明                                                                                              |
| ---------------------------------------------------------------------------------------- | ---------------------- | ------------------------------------------------------------------------------------------------- |
| [src/config/EnumLabelMap.json](../../../../src/config/EnumLabelMap.json)                 | **数据源**             | 后端字典原始数据；结构 `{ state, data: { EnumName: { KEY: { value, label } } } }`                 |
| [scripts/generate-enums.js](../../../../scripts/generate-enums.js)                       | **生成器**             | 由 `pnpm gen:enums` 调用，读取 JSON 产出 `EnumConst.ts` + `optionsConst.ts`                       |
| [src/config/EnumConst.ts](../../../../src/config/EnumConst.ts)                           | **生成产物**（勿手改） | `export enum XxxName { KEY = value }`，JSDoc 注释来自 label                                       |
| [src/config/optionsConst.ts](../../../../src/config/optionsConst.ts)                     | **生成产物**（勿手改） | `export const XxxNameOptions = [{ label, value }]`，用于下拉/Picker                               |
| [src/config/EnumConstForFinance.ts](../../../../src/config/EnumConstForFinance.ts)       | **生成产物**           | 财务模块专用枚举                                                                                  |
| [src/config/optionsConstForFinance.ts](../../../../src/config/optionsConstForFinance.ts) | **生成产物**           | 财务模块专用 options                                                                              |
| [src/config/EnumExtend.ts](../../../../src/config/EnumExtend.ts)                         | **手工维护**           | 业务扩展枚举与映射（如 `productLimitKeyEnum`、`PAY_TYPE`、`ContactFormFieldArray`），生成器不覆盖 |

### 生成器规则

| 输入类型                                              | 处理方式                                                                     |
| ----------------------------------------------------- | ---------------------------------------------------------------------------- |
| 简单字符串映射（`KEY === value`，如 `TypeTagParent`） | 生成 enum，不生成 options                                                    |
| 标准对象 `{ value, label }`                           | 生成 enum + options，注释取 `label`                                          |
| `ResponseCode`（特殊）                                | 仅取 `code` 字段生成 enum，跳过 options                                      |
| `TypeData`（特殊）                                    | 跳过，不生成任何产物                                                         |
| label 取值优先级                                      | `label > message > langName > labelKey > value > code > item`                |
| value 取值优先级                                      | `code === 0/'' 优先` → `value === 0/'' 优先` → `fullCode` → `langKey` → 原值 |

### 何时使用哪个枚举/常量

| 场景                                      | 用哪个                                                 | 示例                                                  |
| ----------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------- |
| 比较订单状态、产品类型等判断              | `EnumConst.ts` 中的 `enum`                             | `if (order.state === StateOrder.PAY_SUCCESS) { ... }` |
| 下拉/Picker/筛选选项                      | `optionsConst.ts` 中的 `XxxOptions`                    | `<uni-data-select :localdata="StateOrderOptions" />`  |
| 业务特有的前端枚举（后端没有/不该走字典） | `EnumExtend.ts` 手工维护                               | `productLimitKeyEnum.SaleRangeLimiter`                |
| 枚举值 → 国际化文本                       | i18n `enumeration.json` + EnumLabelMap 协同            | `t(\`enumeration.StateOrder.${order.state}\`)`        |
| 财务/特殊业务模块                         | `EnumConstForFinance.ts` / `optionsConstForFinance.ts` | 独立分组，避免与主模块冲突                            |

### 标准用法

```typescript
// ✅ 状态判断 — 使用 enum
import { StateOrder } from "@/config/EnumConst";

if (order.state === StateOrder.PAY_SUCCESS) {
  // 已支付，显示退款按钮
}
if ([StateOrder.ORDER_NEW, StateOrder.ORDER_AUDIT].includes(order.state)) {
  // 待处理
}
```

```vue
<!-- ✅ 下拉/筛选 — 使用 options -->
<script setup lang="ts">
import { StateOrderOptions } from "@/config/optionsConst";
import { ref } from "vue";

const state = ref<number>();
</script>

<template>
  <uni-data-select v-model="state" :localdata="StateOrderOptions" />
</template>
```

```typescript
// ✅ 业务扩展 — 使用 EnumExtend
import { productLimitKeyEnum, PAY_TYPE } from "@/config/EnumExtend";

const key = productLimitKeyEnum.SaleRangeLimiter;
const wxPayMode = PAY_TYPE.WXPAY; // 'H5'
```

```vue
<!-- ✅ 枚举文本国际化（结合 i18n/enumeration.json） -->
<text>{{ $t(`enumeration.StateOrder.${order.state}`) }}</text>
```

### 生成流程（开发者操作）

1. **后端更新字典** → 通过约定接口（或手动导出）拿到最新的 `EnumLabelMap` JSON
2. **替换** [src/config/EnumLabelMap.json](../../../../src/config/EnumLabelMap.json)
3. **执行** `pnpm gen:enums`
4. **检查** `EnumConst.ts` / `optionsConst.ts` diff，确认无破坏性变更（已用值不要被改）
5. **同步 i18n 文案** —— 若枚举 label 有变化，更新 `src/i18n/{lang}/enumeration.json` 中对应 key
6. **提交** JSON + 生成产物 + i18n 文件

### 关键约定

| ✅ 正确                                                                                    | ❌ 错误                                                 |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------- |
| 状态比较用 `StateOrder.PAY_SUCCESS`                                                        | 写死魔数 `if (order.state === 21)`                      |
| 下拉选项用 `XxxOptions` 数组                                                               | 在页面里手抄一份 `[{ label: '...', value: 21 }, ...]`   |
| 枚举值类型用 `keyof typeof XxxEnum` / `XxxEnum`                                            | 用 `number` / `string` 模糊类型                         |
| 新增字典 → 改 JSON + `pnpm gen:enums` + 提交产物                                           | 直接手改 `EnumConst.ts` / `optionsConst.ts`（会被覆盖） |
| 业务特有枚举放 `EnumExtend.ts`                                                             | 把业务扩展塞进 `EnumConst.ts`（下次生成被覆盖）         |
| 枚举文本走 i18n `enumeration.json`                                                         | 在页面里硬编码中文 `"已支付"`                           |
| 财务/特殊模块用 `*ForFinance.ts` 文件                                                      | 与主模块混在一个文件                                    |
| 引用枚举统一从 `@/config/EnumConst` / `@/config/optionsConst` / `@/config/EnumExtend` 导入 | 用相对路径 `../../config/...`                           |

### 类型增强

```typescript
import { StateOrder } from '@/config/EnumConst'

// 限定函数参数为枚举值
function getOrderStatusText(state: StateOrder): string { ... }

// 联合类型
type FinalState = StateOrder.PAY_SUCCESS | StateOrder.ORDER_AUDIT
```

## 网络请求规范

> 网络请求由 `src/api/request/` 通用封装，页面中禁止直接使用 `uni.request`。API 调用通过 `src/api/` 层平铺的 `xxxApi.ts` 函数完成。

### `src/api/` 目录结构

| 子路径                    | 定位                          | 说明                                                                                                                                                                             |
| ------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/api/request/`        | **通用请求函数**              | 封装 `uni.request`、拦截器、错误处理、Token 注入；全项目复用                                                                                                                     |
| `src/api/type/`           | **通用类型**                  | `API_TYPE.ts` 定义 `ResponseData<T>`、`DataList<T>` 等公共泛型                                                                                                                   |
| `src/api/{service}Api.ts` | 各服务 API 函数（平铺单文件） | 按服务前缀 camelCase 命名，如 [saasMallAppGuestApi.ts](../../../../src/api/saasMallAppGuestApi.ts)、[authUwAuthCenterApiAuth.ts](../../../../src/api/authUwAuthCenterApiAuth.ts) |

| ✅ 正确                                                    | ❌ 错误                                      |
| ---------------------------------------------------------- | -------------------------------------------- |
| 调用 `request` 通过 `src/api/{service}Api.ts` 中的函数封装 | 页面/组件内直接 `uni.request(...)`           |
| 公共类型从 `@/api/type/API_TYPE` 导入                      | 在页面内重复定义 `ResponseData` / `DataList` |
| 新增服务 API 在 `src/api/` 下平铺一个 `xxxApi.ts` 文件     | 按模块拆 `src/api/{module}/index.ts` 目录    |
| 服务文件命名 `{platform}{module}Api.ts` camelCase          | 文件名使用 kebab-case 或不含 `Api` 后缀      |

### ResponseData<T> 解析规范

```
列表 API 返回：ResponseData<DataList<T>>
  - 列表数据：res.data?.list       → 类型 T[]（新接口规范）
  - 分页总数：res.data?.total
  - 当前页码：res.data?.pageNum

实体 API 返回：ResponseData<T>
  - 实体数据：res.data             → 类型 T

无返回值 API：ResponseData<void>
  - 检查状态：res.state === 'success'
```

> **新代码统一使用 `res.data?.list`**；旧接口的 `res.data?.results` 由开发者在调用层做兼容处理，本规范不强制改写历史代码。

### 标准用法

```typescript
import { cmsArticleList, cmsArticleLoad } from "@/api/cmsArticle";
import type { CmsArticle } from "@/api/cmsArticle";

// 列表页（新接口）
const res = await cmsArticleList({ param: { $pg: 1, $rn: 20 } });
const list: CmsArticle[] = res.data?.list || [];
const total = res.data?.total || 0;

// 详情页
const res = await cmsArticleLoad({ id: articleId });
const detail: CmsArticle = res.data!;
```

### 平台条件编译规范（H5 / 小程序 / App 跨端必读）

> 项目目标支持 **H5 / 小程序 / App** 三端，覆盖：H5、微信小程序（mp-weixin）、抖音/头条（mp-toutiao）、小红书（mp-xhs）、百度（mp-baidu）、支付宝（mp-alipay）、App-Plus。**新写跨端代码必须使用条件编译，否则在某一端必崩**。

#### 平台标识总览

| 平台                 | 条件编译标识        | `process.env.VUE_APP_PLATFORM` 值 | 备注                                              |
| -------------------- | ------------------- | --------------------------------- | ------------------------------------------------- |
| H5                   | `H5`                | `h5`                              | 浏览器 / 嵌入 webview                             |
| App（Android / iOS） | `APP-PLUS` 或 `APP` | `app-plus` / `app`                | uni-app x 用 `APP`                                |
| 微信小程序           | `MP-WEIXIN`         | `mp-weixin`                       |                                                   |
| 支付宝小程序         | `MP-ALIPAY`         | `mp-alipay`                       | 部分 API 受限（如 `responseType: 'arraybuffer'`） |
| 抖音/头条小程序      | `MP-TOUTIAO`        | `mp-toutiao`                      | 项目用于带货 / 视频卡片                           |
| 百度小程序           | `MP-BAIDU`          | `mp-baidu`                        |                                                   |
| 小红书小程序         | `MP-XHS`            | `mp-xhs`                          |                                                   |
| 所有小程序通配       | `MP`                | —                                 | 命中所有 `mp-*`                                   |

#### 两种语法 — 优先级

##### A. 注释式条件编译（编译期处理）—— 优先使用

适用：**Vue 模板 / JS/TS / SCSS / pages.json / manifest.json**。编译期剔除不匹配代码，**性能最优、产物最小**。

```vue
<template>
  <!-- #ifdef H5 -->
  <view>仅 H5 显示</view>
  <!-- #endif -->

  <!-- #ifdef MP-WEIXIN -->
  <button open-type="getPhoneNumber" @getphonenumber="onGetPhone">微信授权手机号</button>
  <!-- #endif -->

  <!-- #ifdef APP-PLUS -->
  <view>App 专属</view>
  <!-- #endif -->

  <!-- #ifndef H5 -->
  <view>除 H5 外的端</view>
  <!-- #endif -->

  <!-- #ifdef H5 || APP-PLUS -->
  <view>H5 与 App 共有</view>
  <!-- #endif -->
</template>

<script setup lang="ts">
// #ifdef H5
import VConsole from "vconsole";
// #endif

const doShare = () => {
  // #ifdef MP-WEIXIN
  uni.shareAppMessage({ title: "..." });
  // #endif
  // #ifdef H5
  if (navigator.share) navigator.share({ title: "...", url: "..." });
  // #endif
  // #ifdef APP-PLUS
  uni.share({ provider: "weixin", type: 0, href: "..." });
  // #endif
};
</script>

<style lang="scss" scoped>
.box {
  /* #ifdef H5 */
  position: sticky;
  /* #endif */
  /* #ifdef MP-WEIXIN */
  position: fixed;
  /* #endif */
}
</style>
```

> ⚠️ CSS 中条件编译**必须**用 `/* #ifdef */`（不能用 `// #ifdef`，否则会被当作普通注释，样式全端生效）。

##### B. 运行时判断 `process.env.VUE_APP_PLATFORM` —— 仅在条件编译不能表达时用

适用：**computed / v-if / 单个 props 表达式**。代码**不会被剔除**，但语义可读。

```typescript
import { computed } from "vue";

const env = computed(() => process.env.VUE_APP_PLATFORM);
const isH5 = computed(() => env.value === "h5");
const isMP = computed(() => env.value?.startsWith("mp-"));
const isWeixin = computed(() => env.value === "mp-weixin");
const isToutiao = computed(() => env.value === "mp-toutiao");
```

```vue
<template>
  <!-- ✅ 同一组件按平台切换 props（条件编译无法切表达式） -->
  <CustomCard :duration="isToutiao ? 1500 : 600" />
</template>
```

#### 决策表

| 场景                                    | 推荐              | 理由                                    |
| --------------------------------------- | ----------------- | --------------------------------------- |
| 整段 DOM 仅某端渲染                     | **A. 条件编译**   | 编译期剔除，产物小                      |
| 不同端使用不同 API                      | **A. 条件编译**   | 避免引用不存在的 API 导致编译错误       |
| 不同端 import 不同模块                  | **A. 条件编译**   | H5 用 `vconsole` / App 用 plus 原生模块 |
| 仅在 props 数值 / 类名差异              | **B. 运行时判断** | 条件编译不能切表达式                    |
| computed / v-if 切换                    | **B. 运行时判断** | 同上                                    |
| `pages.json` / `manifest.json` 平台差异 | **A. 条件编译**   | 框架支持 JSON 条件编译                  |

#### 跨端 API 差异速查（项目高频能力）

| 能力                                | H5                                                                      | 微信小程序                                        | App                                 | 推荐方案                                                                                                               |
| ----------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------- | ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 分享                                | `navigator.share` / [SharePopup](../../../../src/components/SharePopup) | `onShareAppMessage` + `onShareTimeline`           | `uni.share`（provider）             | 条件编译 + 公用 `SharePopup`                                                                                           |
| 微信登录                            | OAuth 重定向                                                            | `uni.login({ provider: 'weixin' })`               | `uni.login({ provider: 'weixin' })` | 条件编译                                                                                                               |
| 支付                                | H5 跳支付页 / H5_WEB                                                    | `uni.requestPayment({ provider: 'wxpay' })`       | `uni.requestPayment` 各 provider    | 走 [PaymentPopup](../../../../src/components/PaymentPopup) + [PAY_TYPE](../../../../src/config/EnumExtend.ts) 统一收口 |
| 扫码                                | `<input>` 拍照 / 第三方库                                               | `uni.scanCode`                                    | `uni.scanCode`                      | 条件编译，H5 降级                                                                                                      |
| 文件下载                            | `<a download>`                                                          | `uni.downloadFile` + `uni.saveImageToPhotosAlbum` | 同小程序                            | 条件编译                                                                                                               |
| 定位                                | `navigator.geolocation`                                                 | `uni.getLocation`                                 | `uni.getLocation`                   | 条件编译                                                                                                               |
| 路由                                | URL hash                                                                | `uni.navigateTo` 等                               | `uni.navigateTo` 等                 | 统一走 [tool.ts navToUrl](../../../../src/utils/tool.ts)                                                               |
| 复制文本                            | `navigator.clipboard`                                                   | `uni.setClipboardData`                            | `uni.setClipboardData`              | 条件编译 + 工具函数                                                                                                    |
| 状态栏 / 安全区                     | 不存在                                                                  | `getMenuButtonBoundingClientRect`                 | `plus.navigator.setStatusBarStyle`  | `mainStore.statusHeight` 统一处理                                                                                      |
| 顶部胶囊按钮                        | 不存在                                                                  | `uni.getMenuButtonBoundingClientRect()`           | 不存在                              | `#ifdef MP-WEIXIN`                                                                                                     |
| WebView 嵌入                        | `<iframe>`                                                              | `<web-view>`                                      | `<web-view>` 或 `plus.webview`      | 条件编译                                                                                                               |
| `responseType: 'arraybuffer'`       | 支持                                                                    | 支持                                              | 支持                                | **MP-ALIPAY 不支持**，需 `#ifndef MP-ALIPAY`                                                                           |
| ResizeObserver / MutationObserver   | 支持                                                                    | 不支持                                            | 不支持                              | `#ifdef H5`                                                                                                            |
| `window` / `document` / `navigator` | 可用                                                                    | 不可用                                            | 不可用                              | **禁止**在非 `#ifdef H5` 内引用                                                                                        |
| `plus.*`                            | 不可用                                                                  | 不可用                                            | 可用                                | **必须** `#ifdef APP-PLUS`                                                                                             |
| `localStorage`                      | 5MB                                                                     | 不存在                                            | 不存在                              | 统一用 `uni.setStorageSync`（10MB）                                                                                    |

#### 常见误用与陷阱

| ❌ 错误                                     | ✅ 正确                                | 后果                       |
| ------------------------------------------- | -------------------------------------- | -------------------------- |
| 在 `<script>` 顶层直接 `import vconsole`    | `// #ifdef H5` 包裹 import             | 小程序构建失败             |
| 直接 `window.localStorage.setItem(...)`     | 用 `uni.setStorageSync`                | 小程序运行时崩溃           |
| 在 `onShow` 里直接 `document.title = '...'` | `// #ifdef H5` 包裹                    | 小程序无 document          |
| 用条件编译切换单个 props 值                 | 用 `process.env.VUE_APP_PLATFORM` 计算 | 条件编译不支持表达式内切换 |
| H5/小程序代码混在同一函数体                 | 拆为两个函数，各自 `#ifdef`            | 难维护 / 易漏端            |
| 直接调用 `uni.share`（H5 不支持）           | `#ifdef APP-PLUS` 包裹                 | H5 静默失败                |
| 模板里给 H5 写 `<web-view>`                 | H5 用 `<iframe>`                       | H5 渲染失败                |
| SCSS 用 `// #ifdef H5`                      | 用 `/* #ifdef H5 */`                   | 条件不生效，样式全端       |
| 顶层 `import VConsole` 后再 `if (isH5)` 用  | import 也包在 `#ifdef H5`              | 小程序构建报错             |
| 平台差异大段代码各处复制                    | 统一收敛到 utils / 通用组件            | 多端维护成本高             |

#### 常用模板

##### 微信小程序分享（业务页面标配）

```vue
<script setup lang="ts">
import { onShareAppMessage, onShareTimeline } from "@dcloudio/uni-app";

// #ifdef MP-WEIXIN
onShareAppMessage(() => ({
  title: detail.value?.name || "",
  path: `/packages/product/detail?id=${detail.value?.id}`,
  imageUrl: detail.value?.cover,
}));

onShareTimeline(() => ({
  title: detail.value?.name || "",
  query: `id=${detail.value?.id}`,
  imageUrl: detail.value?.cover,
}));
// #endif
</script>
```

##### 跨端复制文本（工具函数）

```typescript
import { i18n } from "@/i18n/instance";

export const copyText = (text: string, tipKey = "common.copySuccess") => {
  const { t } = i18n().global;
  // #ifdef H5
  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(() => {
      uni.showToast({ title: t(tipKey), icon: "success" });
    });
    return;
  }
  // #endif

  uni.setClipboardData({
    data: text,
    success: () => uni.showToast({ title: t(tipKey), icon: "success" }),
  });
};
```

##### 平台专属 import

```typescript
// #ifdef H5
import VConsole from "vconsole";
if (import.meta.env.DEV) new VConsole();
// #endif

// #ifdef APP-PLUS
import { showWebViewLogin } from "@/utils/app/webViewLogin";
// #endif
```

##### `pages.json` 平台差异（JSON 条件编译）

```json
{
  "pages": [
    /* #ifdef MP-WEIXIN */
    { "path": "pages/wx-only/index", "style": { "navigationBarTitleText": "微信专属" } },
    /* #endif */
    { "path": "pages/home/index" }
  ]
}
```

#### 平台 appId / manifest 维护

| 配置项                        | 位置                                                              | 备注                                                  |
| ----------------------------- | ----------------------------------------------------------------- | ----------------------------------------------------- |
| H5 路由 base                  | [vite.config.ts](../../../../vite.config.ts) `base: './'`         | 部署路径变化时调整                                    |
| App appId                     | [manifest.json](../../../../src/manifest.json) 顶层 `appid`       | DCloud 申请                                           |
| iOS Bundle ID                 | `manifest.json` `app-plus.distribute.ios.appid`                   | App Store 一致                                        |
| Android 包名                  | `manifest.json` `app-plus.distribute.android.packagename`         | Google Play 一致                                      |
| 微信小程序 appid              | `manifest.json` `mp-weixin.appid`                                 | 微信公众平台                                          |
| 抖音 / 百度 / 小红书 / 支付宝 | `manifest.json` `mp-{platform}.appid`                             | 各平台开放后台                                        |
| 运行时获取                    | `userStore.setAppId()` 按 `process.env.VUE_APP_PLATFORM` 自动选取 | 详见 [§登录/Token 体系](#登录--token--多租户体系规范) |

#### 编译验证

| 校验项                        | 命令 / 方法                                                                                                       |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| H5 编译通过                   | `pnpm build:h5`                                                                                                   |
| 微信小程序编译通过            | `pnpm build:mp-weixin`                                                                                            |
| App 编译                      | HBuilderX 云打包 / `pnpm build:app-plus`                                                                          |
| 项目目标小程序（如抖音）      | `pnpm build:mp-toutiao` 等                                                                                        |
| 未包裹 `window/document` 检查 | `grep -rEn '(^\|[^.])\b(window\|document)\.' src/ --include="*.vue" --include="*.ts"` 后核对是否在 `#ifdef H5` 内 |
| 未包裹 `plus.*` 检查          | `grep -rn 'plus\.' src/` 应仅在 `#ifdef APP-PLUS` 内                                                              |
| SCSS 错用 `//` 注释式条件编译 | `grep -rEn '//\s*#(ifdef\|ifndef\|endif)' src/ --include="*.scss" --include="*.vue"` 应为 0                       |
| 跨端验证                      | 合并主线前**至少跑通 H5 + 微信小程序 + 目标 App** 三端编译                                                        |

#### 关键约定

| ✅ 正确                                                         | ❌ 错误                          |
| --------------------------------------------------------------- | -------------------------------- |
| 不同端用不同 API → **条件编译** `#ifdef`                        | 全部走运行时 `if (env === 'h5')` |
| 单个表达式 / props 切换 → **运行时判断**                        | 用条件编译切表达式（语法不支持） |
| H5 专属 `import` 包在 `// #ifdef H5` 内                         | 顶层 import 后再 `if (isH5)` 用  |
| `window` / `document` / `navigator` 仅 `#ifdef H5` 内           | 任意位置直接引用                 |
| `plus.*` 仅 `#ifdef APP-PLUS` 内                                | H5 / 小程序里引用                |
| SCSS 用 `/* #ifdef H5 */`                                       | 用 `// #ifdef H5`                |
| `pages.json` / `manifest.json` 用 JSON 条件编译                 | 维护多份 JSON 人工切换           |
| 多平台 appId 走 `manifest.json` + `userStore.setAppId()`        | 页面里硬编码 appid               |
| 跨端能力收敛到 utils / 通用组件                                 | 每个页面重复写三套 `#ifdef`      |
| 新增 API 前查阅本表「跨端 API 差异速查」                        | 直接在 H5 测一下就上线           |
| 微信小程序分享通过 `onShareAppMessage` + `onShareTimeline` 配置 | 仅写一处 `onShareAppMessage`     |

#### 调试

| 端               | 调试方式                                             |
| ---------------- | ---------------------------------------------------- |
| H5               | Chrome DevTools；移动调试用 vConsole（DEV 自动注入） |
| 微信小程序       | 微信开发者工具，开启「不校验合法域名」               |
| 抖音/百度/小红书 | 各平台官方开发者工具                                 |
| App              | HBuilderX 真机运行 + Safari/Chrome remote debug      |

### Loading / 骨架屏 / 空状态规范

> 项目层面提供「页面级遮罩 Loading」+ 「按钮 Loading」+ 「列表上拉/触底分页」+ 「空状态」四类标准 UI。**新增页面必须按下表场景选择对应方案，禁止自造同类组件**。

#### 关键模块

| 模块               | 文件 / 来源                                                                                                        | 用途                                                                                    |
| ------------------ | ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| 页面级遮罩 Loading | [components/GbLoading/](../../../../src/components/GbLoading)                                                      | 全屏白底 + Logo + LoopLoading 动效，首屏 / 跳转 / 关键写操作时使用，通过 `v-model` 控制 |
| 内嵌 Loading 动效  | [components/GbLoading/components/LoopLoading.vue](../../../../src/components/GbLoading/components/LoopLoading.vue) | 局部 Loading 动效，可单独嵌入卡片                                                       |
| 系统 Loading       | `uni.showLoading` / `uni.hideLoading`                                                                              | 操作反馈（提交订单、上传、支付前等），必须与 hideLoading 配对                           |
| Toast 加载         | `uni.showToast({ icon: 'loading' })`                                                                               | 极短反馈（< 1.5s）                                                                      |
| 列表分页           | `<uni-load-more>`（uni-ui）/ `<u-loadmore>`（uview-plus）                                                          | 列表上拉加载 / 触底加载                                                                 |
| 空状态             | `<uni-load-more status="noMore">` + 业务图文                                                                       | 列表无数据 / 加载失败                                                                   |
| 装修占位           | [components/waiting-cmp/](../../../../src/components/waiting-cmp)                                                  | **仅装修拖拽预览使用**，业务页面不要用                                                  |

#### 场景与方案映射

| 场景                         | 方案                                                                             | 何时显示                                | 何时隐藏                               |
| ---------------------------- | -------------------------------------------------------------------------------- | --------------------------------------- | -------------------------------------- |
| 页面首屏加载                 | `<GbLoading v-model="showLoading" />`                                            | `onLoad` / `onShow` 开始请求时置 true   | 主数据请求完成（无论成功失败）置 false |
| 关键提交（下单/支付/改密码） | `uni.showLoading({ title, mask: true })`                                         | API 调用前                              | `finally { uni.hideLoading() }`        |
| 按钮局部 loading             | `<button :loading="submitting" :disabled="submitting">` 或 `<u-button :loading>` | API 调用前置 true                       | `finally` 置 false                     |
| 极短反馈                     | `uni.showToast({ icon: 'loading', duration: 1500 })`                             | 同步触发                                | 自动消失                               |
| 列表上拉加载                 | `<uni-load-more :status="loadStatus">`                                           | 触底/翻页时 status="loading"            | 请求完成后切 "more" / "noMore"         |
| 列表空数据                   | `status="noMore"` + 业务图文（图片 + 提示语 + 重试按钮）                         | 首屏返回 0 条                           | 列表非空时不渲染                       |
| 加载失败                     | 业务自定义错误占位（图片 + msg + 重试按钮）                                      | `catch` 分支 / `state !== 'success'` 时 | 重试请求时切回 loading                 |

#### 标准用法：页面级 Loading 三段式（`try/catch/finally`）

```vue
<script setup lang="ts">
import { ref, onLoad } from "vue";
import GbLoading from "@/components/GbLoading/index.vue";
import { guestProductLoad } from "@/api/saasMallAppGuestApi";

const showLoading = ref(false);
const detail = ref();

const loadData = async () => {
  showLoading.value = true;
  try {
    const res = await guestProductLoad({ id: "..." });
    if (res.state !== "success") {
      uni.showToast({ title: res.msg, icon: "none" });
      return;
    }
    detail.value = res.data;
  } finally {
    // ✅ 必须 finally，避免请求异常时 loading 卡死
    showLoading.value = false;
  }
};

onLoad(loadData);
</script>

<template>
  <GbLoading v-model="showLoading" />
  <view v-if="detail">…</view>
</template>
```

#### 标准用法：列表 Loading + 空状态 + 上拉加载

```vue
<script setup lang="ts">
import { ref } from "vue";
import { guestArticleList, type Article } from "@/api/saasMallAppGuestApi";

type LoadStatus = "more" | "loading" | "noMore";

const list = ref<Article[]>([]);
const loadStatus = ref<LoadStatus>("more");
const pageNum = ref(1);
const PAGE_SIZE = 20;

const loadList = async (isRefresh = false) => {
  if (loadStatus.value === "loading") return;
  loadStatus.value = "loading";
  try {
    if (isRefresh) pageNum.value = 1;
    const res = await guestArticleList({ param: { $pg: pageNum.value, $rn: PAGE_SIZE } });
    if (res.state !== "success") {
      uni.showToast({ title: res.msg, icon: "none" });
      loadStatus.value = "more";
      return;
    }
    const items = res.data?.list || [];
    list.value = isRefresh ? items : list.value.concat(items);
    loadStatus.value = items.length < PAGE_SIZE ? "noMore" : "more";
    pageNum.value += 1;
  } catch {
    loadStatus.value = "more";
  }
};
</script>

<template>
  <scroll-view scroll-y @scrolltolower="loadList()">
    <view v-for="item in list" :key="item.id">…</view>

    <!-- 上拉加载 / 触底 / 无更多（三态） -->
    <uni-load-more :status="loadStatus" />

    <!-- 空状态（仅首屏空时显示） -->
    <view v-if="!list.length && loadStatus !== 'loading'" class="flex flex-col items-center py-20">
      <image src="/static/images/empty/no-data.png" mode="widthFix" class="w-50 h-50" />
      <text class="text-foreground-muted mt-4">{{ $t("common.noData") }}</text>
      <button class="mt-4" @click="loadList(true)">{{ $t("common.retry") }}</button>
    </view>
  </scroll-view>
</template>
```

#### 关键提交标准用法（下单 / 支付 / 表单提交）

```typescript
const handleSubmit = async () => {
  try {
    uni.showLoading({ title: t("common.submitting"), mask: true }); // mask:true 防止误点
    const res = await guestOrderCreate({ data: form.value });
    if (res.state !== "success") {
      uni.showToast({ title: res.msg, icon: "none" });
      return;
    }
    uni.showToast({ title: t("order.createSuccess"), icon: "success" });
    uni.navigateTo({ url: `/packages/order/detail?id=${res.data!.id}` });
  } finally {
    uni.hideLoading(); // ✅ 必须 finally
  }
};
```

#### 骨架屏（可选）

- 当前项目**未集成统一骨架屏组件**，如业务有需要：
  - 复杂详情页可使用 `<uni-skeleton>`（uni-ui）或 `<u-skeleton>`（uview-plus）
  - 简单列表项使用占位：`<view class="bg-muted h-4 w-full animate-pulse rounded" />`
- 骨架屏与 `GbLoading` **二选一**：
  - 首屏数据较多/重要 → 骨架屏（更好的感知性能）
  - 关键写操作（下单/支付）→ `GbLoading` 全屏遮罩（防止误操作）

#### 空状态 / 错误占位 / 网络异常 UI 约定

| 状态           | 必备元素                         | 建议 i18n key                          |
| -------------- | -------------------------------- | -------------------------------------- |
| **空数据**     | 图片 + 提示语（可选 + 操作按钮） | `common.noData` / `common.emptyList`   |
| **加载失败**   | 图片 + 错误描述 + **重试按钮**   | `common.loadFailed` / `common.retry`   |
| **网络异常**   | 图片 + 网络异常文案 + 重试按钮   | `common.networkError` / `common.retry` |
| **未登录引导** | 图片 + 引导文案 + 登录按钮       | `common.needLogin` / `common.goLogin`  |
| **无权限**     | 图片 + 权限提示 + 返回按钮       | `common.noPermission` / `common.back`  |

> 4 种语言文件（`zh-CN/zh-TW/en/ja`）的 `common.json` 必须同步补齐上述 key；占位图片统一放 `static/images/empty/`。

#### Loading 时长与体验约定

| 操作类型              | 期望响应                                              | 超时处理                                         |
| --------------------- | ----------------------------------------------------- | ------------------------------------------------ |
| 首屏 / 列表加载       | < 1s 不显示 Loading；1~3s 显示；> 3s 提示「正在加载」 | > 10s 弹 Modal 询问「网络较慢，是否继续？」      |
| 关键提交（下单/支付） | 立即显示遮罩 Loading                                  | > 8s 隐藏 Loading + 提示「网络较慢，请稍候重试」 |
| 极短反馈（点赞/收藏） | 不显示 Loading，乐观更新 + 失败回滚                   | 失败 Toast 提示，状态自动回滚                    |
| 上传文件              | 显示进度条（百分比）                                  | 网络断开时提示并保留已选文件                     |

#### 关键约定

| ✅ 正确                                                              | ❌ 错误                                     |
| -------------------------------------------------------------------- | ------------------------------------------- |
| 页面级 Loading 用 `<GbLoading v-model="..." />` 标准组件             | 自己写一份"全屏遮罩 + 转圈"                 |
| 关键提交用 `uni.showLoading + try/finally` 三段式                    | 漏 finally / 用 setTimeout 兜底 hideLoading |
| 列表分页用 `<uni-load-more :status>` 三态（more / loading / noMore） | 自己拼 `<view>没有更多了</view>`            |
| 空状态显示 **图片 + 文案 + 重试按钮**                                | 仅显示文字「暂无数据」无引导                |
| 失败状态提供 **重试按钮**                                            | 仅 Toast 一闪而过，用户无法重试             |
| 列表空 + loading 并存场景（首屏）优先显示 loading                    | 同时显示「加载中」和「暂无数据」            |
| 文案走 i18n（`common.noData` / `common.retry`）                      | 硬编码中文「暂无数据」                      |
| `GbLoading` 的 `v-model` 在 `finally` 置 false                       | 仅在 try 末尾置 false（异常时卡死）         |
| 装修组件预览用 `waiting-cmp`（仅装修）                               | 在业务页面用 `waiting-cmp`                  |
| 骨架屏与 `GbLoading` 二选一                                          | 同一页面两者同时出现                        |

#### 自动化检查

```bash
# Loading 平衡度检查（showLoading 与 hideLoading 数量应一致）
grep -rln 'uni\.showLoading' src/ --include="*.vue" --include="*.ts" | \
  xargs -L 1 sh -c 'h=$(grep -c "uni\.showLoading" "$1"); f=$(grep -c "uni\.hideLoading" "$1"); test "$h" -gt "$f" && echo "[WARN] $1: show=$h hide=$f"' _

# 硬编码空/失败文案（应走 i18n）
grep -rn '"暂无数据"\|"加载失败"\|"网络异常"\|"没有更多"' src/ --include="*.vue" | wc -l

# 自造全屏遮罩 loading（应统一用 GbLoading）
grep -rn 'position:\s*fixed.*z-index:\s*99' src/ --include="*.vue" --include="*.ts" | wc -l
```

### 错误处理与状态码规范

> 由 [src/api/request/index.ts](../../../../src/api/request/index.ts) 统一拦截，业务页面**不需要重复处理**底层网络异常与认证失败。仅在「业务级失败」（如订单冲突、库存不足、参数校验失败）需要在调用方手动处理。

#### HTTP 状态码处理矩阵

| statusCode         | 拦截器行为                                                                                                                                                                 | 业务页面是否需介入                | 说明                                   |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- | -------------------------------------- |
| `200`              | 解析 JSON（含大数字处理），翻译 `msg`，`resolve(JSONResData)`                                                                                                              | ✅ 检查 `res.state === 'success'` | 业务级判定由页面负责                   |
| `401`              | 入 `Subject` 队列 → `uni.reLaunch('/pages/login/index')` → `uni.$emit('clearLoginCache')`                                                                                  | ❌ 不处理                         | 登录失效，自动跳登录；登录接口本身排除 |
| `403`              | `showToast(curUserNotPerm, 5s)` → 2s 后跳 `/pages/login/index?redirectUrl=...`                                                                                             | ❌ 不处理                         | 权限不足，自动提示并跳转               |
| `498`              | 入 `Subject` 队列 → `uni.$emit('doRefreshToken')` → 刷新成功后由 [requestEventHandler.ts](../../../../src/utils/requestEventHandler.ts) 通过 `subject.notify()` 重发原请求 | ❌ 不处理                         | Token 即将过期，无感刷新               |
| `>= 500`           | 若 `JSONResData.msg` 存在则 `showToast(msg, 3s)`；`reject(JSONResData)`                                                                                                    | ✅ 业务可选 try/catch 兜底        | 服务端异常                             |
| 其他               | `reject(JSONResData)`                                                                                                                                                      | ✅ 必须 try/catch                 | 兜底通道                               |
| 网络失败（`fail`） | `reject(error)`                                                                                                                                                            | ✅ 必须 try/catch                 | 弱网/离线/请求被中断                   |

#### 业务级状态判定（200 内）

```typescript
// ✅ 标准模式：先校验 res.state，再用 res.data
const res = await guestQuestionList({ param: { $pg: 1, $rn: 20 } });
if (res.state !== "success") {
  uni.showToast({ title: res.msg || t("common.requestFailed"), icon: "none" });
  return;
}
const list = res.data?.list || [];
```

| 字段        | 含义                                            | 用法                                                               |
| ----------- | ----------------------------------------------- | ------------------------------------------------------------------ |
| `res.state` | `'success'` / `'fail'` 等                       | **必须先判断**，非 success 时不应使用 `res.data`                   |
| `res.code`  | 业务错误码（与后端约定）                        | 当 `state === 'fail'` 时用于分支处理（如「库存不足」「重复下单」） |
| `res.msg`   | 错误提示文案（已被 `handleErrorMsg` i18n 翻译） | 直接 `showToast(res.msg)` 即可                                     |
| `res.data`  | 业务数据                                        | 仅在 `state === 'success'` 时使用                                  |

#### 错误提示分级（业务约定）

| 严重程度     | UI 反馈                                                        | 场景                                         |
| ------------ | -------------------------------------------------------------- | -------------------------------------------- |
| **信息提示** | `uni.showToast({ icon: 'none', duration: 2000 })`              | 非阻断的轻量提示（搜索为空、表单未填）       |
| **错误提示** | `uni.showToast({ icon: 'error', duration: 3000 })`             | 业务失败但用户无需决策（库存不足、网络异常） |
| **确认对话** | `uni.showModal({ showCancel: false })`                         | 需要用户确认的关键信息（订单超时、权限失效） |
| **阻断对话** | `uni.showModal({ showCancel: true, confirmText, cancelText })` | 需要用户决策（重新支付？放弃订单？）         |
| **静默处理** | 不弹任何 UI，仅 `console.warn`                                 | 拦截器已处理（401/403/498）或非关键查询失败  |

#### handleErrorMsg 中文 → i18n 扩展

拦截器内置 `handleErrorMsg` 把后端返回的中文错误转为 i18n key（[request/index.ts](../../../../src/api/request/index.ts)）：

| 后端 msg 关键字            | 翻译为                              | 对应 i18n key                  |
| -------------------------- | ----------------------------------- | ------------------------------ |
| `账号不可用`               | `t('AccountUnavailable')`           | `AccountUnavailable`           |
| `图形识别码验证错误`       | `t('imgCodeError')`                 | `imgCodeError`                 |
| `请输入图形识别码`         | `t('InputImgCode')`                 | `InputImgCode`                 |
| `用户名或密码不正确`       | `t('AccountOrPwdError')`            | `AccountOrPwdError`            |
| `用户名密码错误或状态异常` | `t('AccountPwdErrorOrStatusError')` | `AccountPwdErrorOrStatusError` |
| 其他                       | 原样返回                            | —                              |

**新增映射规则**：

1. 优先推动后端改造为直接返回错误码（`res.code`），由前端按 code 翻译
2. 短期内需补关键字 → i18n 映射时，编辑 [request/index.ts](../../../../src/api/request/index.ts) 的 `handleErrorMsg`
3. 同步在 4 种语言文件中补对应 key（`zh-CN/zh-TW/en/ja`）
4. 不要在业务页里逐个 if/else 翻译错误，统一收口在拦截器

#### 大数字 JSON 处理

后端订单号/ID 常有 16~20 位长整数，JS 原生 `JSON.parse` 会丢精度。拦截器统一通过 `processLargeNumbersInJSON` 把 16-20 位数字转为字符串：

| 场景     | 是否启用                          | 说明                                                   |
| -------- | --------------------------------- | ------------------------------------------------------ |
| 普通接口 | ✅ 全部走                         | 拦截器默认对所有 200 响应启用                          |
| 字段约定 | ID/订单号字段用 `string` 类型接收 | 前端业务侧也要按 string 处理（避免再 `Number()`）      |
| 跳过场景 | ❌ 无                             | 不允许业务侧绕过；如确需原始数字，需在拦截器层加白名单 |

#### 接口白名单（APIwhiteList）

[request/index.ts](../../../../src/api/request/index.ts) 维护 `APIwhiteList`，**白名单中的接口可使用匿名 token 调用**，无需登录态。

**新增白名单条件**：

| ✅ 应加入白名单                                            | ❌ 不应加入                 |
| ---------------------------------------------------------- | --------------------------- |
| 登录 / 注册 / 验证码相关接口                               | 任何涉及用户数据的查询/写入 |
| 站点信息初始化（如 `/saas-mall-app/guest/site/info/load`） | 商品收藏、订单、个人信息等  |
| 重置密码相关接口                                           | 任何修改类业务接口          |
| 全球国家信息等纯字典接口                                   | —                           |

**新增流程**：

1. 在 [request/index.ts](../../../../src/api/request/index.ts) 的 `APIwhiteList` 中加入接口路径（精确匹配）
2. **同步在 Code Review 中确认**该接口确实不依赖登录态
3. 新增后用真实匿名 token 测试一遍接口路径，避免拦截器误判

#### 业务页面标准处理模板

```typescript
import { useI18n } from "vue-i18n";
import { guestOrderCreate } from "@/api/saasMallAppGuestApi";

const { t } = useI18n();

const handleCreateOrder = async () => {
  try {
    uni.showLoading({ title: t("common.submitting"), mask: true });

    const res = await guestOrderCreate({ data: orderForm.value });

    // ✅ 必须先判 state
    if (res.state !== "success") {
      // 业务级失败，由页面决定 UI
      uni.showToast({ title: res.msg || t("common.requestFailed"), icon: "none" });
      return;
    }

    // ✅ 仅在 success 时取 data
    uni.showToast({ title: t("order.createSuccess"), icon: "success" });
    uni.navigateTo({ url: `/packages/order/detail?id=${res.data!.id}` });
  } catch (err) {
    // ✅ 仅兜底网络异常 / 500 等已被拦截器 reject 的情况
    // 401/403/498 已由拦截器处理，不会进 catch
    console.error("createOrder error:", err);
    // 拦截器对 5xx 已 showToast，这里通常无需重复提示
  } finally {
    uni.hideLoading();
  }
};
```

#### 关键约定

| ✅ 正确                                                    | ❌ 错误                                      |
| ---------------------------------------------------------- | -------------------------------------------- |
| 业务页面**先判 `res.state === 'success'`** 再用 `res.data` | 直接 `res.data.xxx` 不判 state               |
| 401/403/498 交给拦截器处理                                 | 业务页面里写 `if (res.statusCode === 401)`   |
| 错误文案统一走 `res.msg`（已 i18n 翻译）                   | 在业务页里 hardcode `"操作失败"` 中文        |
| Loading 用 `try/catch/finally` 保证 `hideLoading`          | 漏掉 finally，loading 卡死                   |
| 大数字 ID/订单号按 `string` 处理                           | 用 `Number()` 转换 / 用 `===` 比较数字字面量 |
| 新增白名单接口先评审登录态依赖                             | 把业务接口随意加入白名单                     |
| 中文错误翻译统一在 `handleErrorMsg` + 4 语言 i18n key      | 在每个页面 if 翻译                           |
| token 刷新走 `doRefreshToken` 事件                         | 业务页面直接调用 `authRefreshToken`          |

#### 调试

| 场景             | 方法                                                                                                      |
| ---------------- | --------------------------------------------------------------------------------------------------------- |
| 查看请求/响应    | 取消 [request/index.ts](../../../../src/api/request/index.ts) 中 `console.log('request 入参...')` 注释    |
| 401 重发链路     | 在 `Subject.add / notify` 处加日志，观察 `subject.observers` 队列                                         |
| 499/498 刷新失败 | 检查 [requestEventHandler.ts](../../../../src/utils/requestEventHandler.ts) `doRefreshToken` 监听是否注册 |
| 白名单未生效     | 路径需精确匹配 `APIwhiteList`；含动态 ID 时拦截器会把 `/数字` 替换为 `/` 再匹配                           |

## 路由配置规范（pages.json）

| 规范       | 说明                                                                                 |
| ---------- | ------------------------------------------------------------------------------------ |
| 路径格式   | `{root}/{module}/{page}`：主包加到 `pages`，业务分包加到 `subPackages[].pages`       |
| TabBar     | **按需，非必须**。是否启用、Tab 数量、图标均由业务/PRD 决定（当前项目未启用 TabBar） |
| 导航栏     | 每个页面配置 `navigationBarTitleText`                                                |
| 自定义导航 | 需要自绘顶部时使用 `navigationStyle: "custom"`                                       |
| 分包       | 主包 ≤ 2MB，超出使用 `subPackages` 分包                                              |

### TabBar 配置示例（仅在业务启用时参考）

```json
{
  "tabBar": {
    "color": "#999999",
    "selectedColor": "#E53935",
    "borderStyle": "black",
    "backgroundColor": "#ffffff",
    "list": [
      {
        "pagePath": "pages/home/index",
        "text": "首页",
        "iconPath": "static/tabbar/home.png",
        "selectedIconPath": "static/tabbar/home-active.png"
      }
      // ...Tab 数量与配置由业务决定
    ]
  }
}
```

## 字段一致性原则

| 层级          | 命名规范                 | 示例            |
| ------------- | ------------------------ | --------------- |
| 数据库字段    | snake_case               | `content_title` |
| 后端 DTO 字段 | camelCase                | `contentTitle`  |
| 前端字段      | camelCase（与 DTO 一致） | `contentTitle`  |
| API 参数      | camelCase（与 DTO 一致） | `contentTitle`  |

## 禁用规则

| 禁用项            | 说明                                        |
| ----------------- | ------------------------------------------- |
| `any` 类型        | 禁止使用 `any`，必须定义具体类型            |
| `v-html`          | 小程序不支持，使用 `rich-text` 组件         |
| DOM 操作          | 禁止直接操作 DOM，使用 Vue 响应式           |
| 全局事件总线      | 禁止 `uni.$emit`/`uni.$on`，使用 Pinia 替代 |
| `window/document` | 禁止直接使用，需条件编译包裹                |
| 同步存储          | 大数据使用 `uni.setStorage` 异步版本        |

## 性能规范

| 场景     | 规范                                                     |
| -------- | -------------------------------------------------------- |
| 图片     | 使用 `mode="aspectFill"` / `mode="widthFix"`，启用懒加载 |
| 列表     | 下拉刷新 + 上拉加载分页，单页 ≤ 20 条                    |
| 虚拟列表 | 长列表使用虚拟滚动（如 `recycle-view`）                  |
| 缓存     | TabBar 页面使用 `uni.setStorageSync` 缓存首屏数据        |
| 分包     | 主包 ≤ 2MB，总包 ≤ 20MB（微信小程序）                    |
| 预加载   | 使用 `preloadRule` 预加载分包页面                        |
| 请求     | 并行请求使用 `Promise.all`，避免瀑布式请求               |

## 国际化规范（vue-i18n）

> 项目位于 [src/i18n/](../../../../src/i18n)，已支持 **4 种语言**：`zh-CN`（简体中文）、`zh-TW`（繁体中文）、`en`（英文）、`ja`（日文）。新增页面/组件文案必须走 i18n，禁止硬编码中文。

### 目录结构

```
src/i18n/
├── zh-CN/          # 简体中文（默认）
│   ├── common.json
│   ├── commonExtend.json
│   ├── component.json
│   ├── enumeration.json
│   ├── errorMsg.json
│   ├── login.json
│   ├── pageTitle.json
│   ├── userInfo.json
│   └── index.ts    # 聚合导出
├── zh-TW/          # 繁体中文
├── en/             # English
├── ja/             # 日本語
├── dayjsLocale.ts  # dayjs 语言切换
├── i18n.type.ts    # 类型定义（I18N type）
├── index.ts        # vue-i18n 实例创建
└── instance.ts     # i18n 实例导出
```

### 约定

| 约定                  | 说明                                                                                                                   |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 翻译键命名            | 按域分文件（`common`、`login`、`errorMsg`、`pageTitle`...），键名 camelCase，**4 种语言文件 key 必须完全一致**         |
| 模板使用              | `<text>{{ $t('common.confirm') }}</text>`                                                                              |
| `<script setup>` 使用 | `import { useI18n } from 'vue-i18n'; const { t } = useI18n(); t('common.confirm')`                                     |
| 语言切换              | 通过 `useMainStore().setI18n(lang)`，自动同步 `dayjs` 语言（见 [main.ts](../../../../src/store/main.ts) 中 `setI18n`） |
| 默认语言              | `zh-CN`；可通过浏览器语言或用户设置自动切换                                                                            |
| 新增文案              | **必须同时在 4 种语言文件中添加 key**，不允许缺漏                                                                      |
| 枚举/选项             | 文案走 `enumeration.json`，结合 [src/config/EnumConst.ts](../../../../src/config/EnumConst.ts) 使用                    |

```vue
<template>
  <view>
    <text class="title">{{ $t("pageTitle.userInfo") }}</text>
    <button>{{ $t("common.confirm") }}</button>
  </view>
</template>

<script setup lang="ts">
import { useI18n } from "vue-i18n";
const { t } = useI18n();

const showError = () => {
  uni.showToast({ title: t("errorMsg.networkError"), icon: "none" });
};
</script>
```

| ✅ 正确                                 | ❌ 错误                       |
| --------------------------------------- | ----------------------------- |
| `$t('common.confirm')`                  | 硬编码 `"确认"`               |
| 4 语言文件同步新增 key                  | 仅在 `zh-CN/` 添加 key        |
| 通过 store action 切换语言              | 直接修改 `i18n.global.locale` |
| 日期格式使用 dayjs + `dayjsLocale` 同步 | 手动拼接日期字符串            |

## 代码规范工具（oxlint + oxfmt）

> 项目使用 [oxlint](https://oxc.rs/docs/guide/usage/linter.html) 与 [oxfmt](https://oxc.rs/) 替代传统的 ESLint + Prettier，性能更高。配置文件：[.oxlintrc.json](../../../../.oxlintrc.json) / [.oxfmt.json](../../../../.oxfmt.json)。

### 常用命令

| 场景                             | 命令                                    |
| -------------------------------- | --------------------------------------- |
| 类型检查                         | `pnpm type-check`（`vue-tsc --noEmit`） |
| Lint 检查                        | `pnpm lint`                             |
| Lint 自动修复                    | `pnpm lint:fix`                         |
| Lint 静默（仅错误）              | `pnpm lint:quiet`                       |
| 格式化（src 目录）               | `pnpm format`                           |
| 格式化校验                       | `pnpm format:check`                     |
| 全量格式化                       | `pnpm format:all`                       |
| 综合检查（type + lint + format） | `pnpm check`                            |

### 规范要点

| 约定                   | 说明                                                                                               |
| ---------------------- | -------------------------------------------------------------------------------------------------- |
| 提交前                 | husky `pre-commit` 钩子自动跑 lint/format（见 [.husky/pre-commit](../../../../.husky/pre-commit)） |
| 提交信息               | `commit-msg` 钩子走 `commitlint`（[commitlint.config.cjs](../../../../commitlint.config.cjs)）     |
| 不引入 ESLint/Prettier | 项目已迁移到 oxlint/oxfmt，不要混用两套工具链                                                      |
| CI 验证                | 编译验证前先 `pnpm check` 通过                                                                     |
