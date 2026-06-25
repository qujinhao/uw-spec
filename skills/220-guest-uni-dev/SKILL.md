---
name: 220-guest-uni-dev
description: 消费者端UniApp移动端开发（AI原生，逐页面完整交付）。当需要基于PRD进行消费者端移动端开发时触发：(1)确认页面清单与TabBar配置, (2)编写架构蓝图README.md, (3)逐页面完整交付（创建页面+pages.json+API对接+平台适配+编译验证）。当用户提及消费者小程序、电商App、内容App、UniApp前端、跨平台应用开发时使用此技能。适用于guest（消费者）角色 ⚠️【强制】完成后必须调用 221-guest-uni-dev-review，未通过前禁止声称完成。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# UniApp移动端开发（AI 原生）

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 技术栈

| 技术栈     | 版本 | 用途       |
| ---------- | ---- | ---------- |
| UniApp     | 最新 | 跨平台框架 |
| Vue 3      | 3.x  | 组合式 API |
| TypeScript | 5.x  | 类型安全   |
| Pinia      | 2.x  | 状态管理（+ `pinia-plugin-unistorage` 持久化） |
| `@dcloudio/uni-ui` | ^1.5+ | 官方 UI 组件库（`uni-*`） |
| `uview-plus`       | ^3.6+ | 社区 UI 组件库（`u-*` / `up-*` / `u--*`） |
| `vue-i18n` | 9.x | 国际化（zh-CN / zh-TW / en / ja 四语言） |
| `oxlint` + `oxfmt` | 最新 | 代码 Lint + 格式化（替代 ESLint/Prettier） |

## ⛔ AI 生成红线（最高优先级，必读）

> 任何代码生成前，AI 必须先读 [anti-patterns.md](references/anti-patterns.md)（禁止生成清单），并在生成中/后对照其 §17 自检清单逐项核查。
> 命中以下 10 条任意一条 = 代码不合格，**必须重写**：

| # | 红色信号 | 修复方向 |
|---|---------|---------|
| 1 | `uni.request(...)` 直接调用 | 走 `@/api/{service}Api.ts` 业务函数 |
| 2 | `const list = res.data.list`（未判 state） | 先 `if (res.state !== 'success') return` 再取 `res.data?.list \|\| []` |
| 3 | `ref<T>(null)` 类型缺 `\| null` | `ref<T \| null>(null)` |
| 4 | 硬编码十六进制颜色 `#xxxxxx` | 用 `class="text-primary"` / Tailwind / CSS 变量 |
| 5 | 硬编码中文字面量 | 走 `$t()` 且 zh-CN/zh-TW/en/ja **4 语言同步**补 key |
| 6 | 业务页 `if (statusCode === 401)` / 调 `authRefreshToken` | 删除，交给 `src/api/request/` 拦截器 |
| 7 | 状态判断写魔数 `if (state === 21)` | 用 `@/config/EnumConst`（生成产物禁手改） |
| 8 | 顶层裸 import `vconsole` / 用 `window` / `plus.*` 未包裹 | `// #ifdef H5` / `// #ifdef APP-PLUS` 包裹 |
| 9 | 直接 `window.localStorage.*` | 改 `uni.setStorageSync` |
| 10 | `v-for` 缺 `:key` 或用 `:key="index"` | `:key="item.id"` |

> ⚠️ 完整禁止清单（18 个主题、200+ 条 ❌/✅ 对照）见 [anti-patterns.md](references/anti-patterns.md)

## 角色职责

| 角色 | 职责                                      | 智能体            |
| ---- | ----------------------------------------- | ----------------- |
| 主导 | 页面开发 + API对接 + 编译验证（一次完成） | `js-developer`    |
| 协作 | 业务需求确认                              | `product-manager` |

## 输入

| 输入项   | 来源路径                                                  | 说明                                  |
| -------- | --------------------------------------------------------- | ------------------------------------- |
| PRD      | `PROJECT_ROOT/requirement/prds/*`                         | 产品需求文档，功能模块及页面需求      |
| API定义  | `PROJECT_ROOT/frontend/{project-name}-guest-uni/src/api/` | gencode 生成的 API 调用函数和类型定义 |
| 前端项目 | `PROJECT_ROOT/frontend/{project-name}-guest-uni/`         | init + gencode 生成的代码             |

## 前置条件

| 前置技能                                                   | 说明                         |
| ---------------------------------------------------------- | ---------------------------- |
| [220-guest-uni-init](../220-guest-uni-init/SKILL.md)       | 移动端项目已通过模板初始化   |
| [220-guest-uni-gencode](../220-guest-uni-gencode/SKILL.md) | api/types 已由代码生成器生成 |

## 架构约定速查表

### 页面路径约定（按现有项目分包结构）

主包仅放公共/入口页面，业务模块通过 `subPackages` 分包根目录平铺组织。**实际分包列表以 [src/pages.json](../../src/pages.json) 的 `subPackages` 为准**。

**项目通用顶层目录**（固定存在）：

```
src/
├── api/         # API 调用封装（gencode 产出，平铺单文件 xxxApi.ts）
│   ├── request/ # 通用请求函数（封装 uni.request、拦截器）
│   └── type/    # 通用类型（API_TYPE.ts：ResponseData / DataList 等）
├── components/  # 全局通用组件
├── config/      # 项目枚举/常量/站点配置
├── i18n/        # 多语言文案（zh-CN/zh-TW/en/ja）
├── pages/       # 主包：入口/登录/渲染容器/WebView 等公共页面
├── packages/    # 分包根（默认）：所有业务分包尽量放这里
├── static/      # 静态资源
│   ├── images/  # 图片资源（按业务域分子目录）
│   └── font/    # 字体（iconfont 等）
├── store/       # Pinia 状态管理
├── styles/      # 全局样式
├── types/       # 全局类型声明
└── utils/       # 工具函数
```

**分包放置规则**：

| 优先级           | 放置位置                        | 适用场景                                                                                                           |
| ---------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| 默认（推荐）     | `src/packages/{module}/`        | 绝大多数业务分包，例如 `setting`、`coupon`、`view`、`order` 等                                                     |
| 特殊情况（按需） | `src/{module}/` 直接挂 `src` 下 | 当业务方明确不希望路由路径上出现 `packages/` 前缀时（如 `src/product/`、`src/poi/`、`src/user/`、`src/template/`） |

> 是否放在 `src` 下需要看 [src/pages.json](../../src/pages.json) 中 `subPackages[].root` 是否为非 `packages` 的根目录。如未在 `pages.json` 中声明的新业务分包，**默认放入 `src/packages/`**。

**当前项目已声明的分包根（参考 [pages.json](../../src/pages.json)）**：

| 分包根          | 定位                                         | 备注                       |
| --------------- | -------------------------------------------- | -------------------------- |
| `src/pages/`    | 主包：入口、登录、渲染容器、WebView          | 主包，非分包               |
| `src/packages/` | 通用业务分包：`setting/`、`coupon/`、`view/` | 默认分包位置               |
| `src/template/` | 装修模板分包                                 | 特殊：路由不带 `packages/` |
| `src/product/`  | 产品域分包                                   | 特殊：路由不带 `packages/` |
| `src/poi/`      | POI 景区分包                                 | 特殊：路由不带 `packages/` |
| `src/user/`     | 用户/订单分包                                | 特殊：路由不带 `packages/` |

| ✅ 正确                                                                                     | ❌ 错误                                                |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| 新增分包**默认**放 `src/packages/{module}/`                                                 | 随意把新分包挂到 `src/` 根下                           |
| 仅当路由不想带 `packages/` 时才放 `src/{module}/`，并同步在 `pages.json` 注册               | 新分包既不放 `packages/` 也不在 `pages.json` 注册 root |
| 通用入口/登录/渲染容器放 `src/pages/` 主包                                                  | 入口页面放进分包                                       |
| 二级模块名沿用现有 camelCase（`productDetail`、`placeOrder`、`orderList`、`addressManage`） | 把已有 camelCase 模块改成 kebab-case                   |

### 登录 / Token / 多租户约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 登录成功调用 `userStore.setLoginInfo(res.data)`（自动同步 `tokenManager`） | 直接 `userStore.loginInfo = ...` 跳过 watch |
| 读取 token 用 `userStore.token`（computed） | 自己拼匿名 token `0$1!0@${saasId}` |
| 外部 token（H5 嵌入/装修预览）走 `userStore.setToken(t)` | 直接 `uni.setStorageSync('token', t)` |
| 退出登录用 `userStore.LogOut()`（含后端登出） | 仅 `clearLoginCache()` 不调后端 |
| 多平台 appId 走 `userStore.setAppId()` | 页面硬编码 appid |
| 多租户 saasId 来自 `userStore.siteInfo` | 直接改 `defaultSiteInfo` 常量 |
| 401 自动 refresh 由 request 拦截器处理 | 业务页自己写 refresh 逻辑 |

> 完整链路见 [md-dev-standards.md §登录 / Token / 多租户体系规范](references/md-dev-standards.md)

### 装修 / 渲染引擎约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 装修组件统一放 `src/mall-widgets/m-{name}/` | 把装修组件放到 `src/components/` |
| `m-*` 装修组件通过 easycom 自动注册 | 手动 `import` `m-*` 装修组件 |
| 装修组件 Props 拆为 `attrs`（业务）/ `styles`（视觉）/ `list`（数据） | 所有配置混在一个对象 |
| 新增装修组件后在 [render-widget.vue](../../src/components/render-widget.vue) 加 `v-if` 分发 | 在业务页面手写分发逻辑 |
| 装修组件跳转通过 `emit('jump', target)` 上抛 | 组件内部直接 `uni.navigateTo` |
| schema 字段放 `src/schema/m-{name}/component.json` | 字段配置写死在 `.vue` 内 |
| 装修预览页（postMessage 通信）专属 [pages/render/index.vue](../../src/pages/render/index.vue) | 业务页面也写 `window.addEventListener('message')` |
| 业务页静态渲染装修 DSL 用 `<render-widget :item="widget" :component-msg="data" />` | 重新造一套分发器 |

> 完整链路见 [md-dev-standards.md §装修 / 渲染引擎规范](references/md-dev-standards.md)

### 枚举与字典约定（项目核心，必读）

> 项目通过 `pnpm gen:enums` 把 [EnumLabelMap.json](../../src/config/EnumLabelMap.json) 自动生成为 [EnumConst.ts](../../src/config/EnumConst.ts) + [optionsConst.ts](../../src/config/optionsConst.ts)。**新页面所有状态判断/下拉选项必须复用产物，禁止写魔数**。

| 场景 | 用哪个 |
|------|-------|
| 状态比较 / 类型判断 | `EnumConst.ts` 中的 `enum`（如 `StateOrder.PAY_SUCCESS`） |
| 下拉/Picker/筛选选项 | `optionsConst.ts` 中的 `XxxOptions` |
| 财务模块 | `EnumConstForFinance.ts` / `optionsConstForFinance.ts` |
| 业务特有/前端独有枚举 | `EnumExtend.ts`（**手工维护**，生成器不覆盖） |
| 枚举值 → 多语言文本 | `i18n/{lang}/enumeration.json` + `$t('enumeration.XxxEnum.value')` |

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `if (order.state === StateOrder.PAY_SUCCESS)` | `if (order.state === 21)` 魔数 |
| 下拉用 `:localdata="StateOrderOptions"` | 在页面里手抄 `[{label:'...', value:21}, ...]` |
| 类型用 `state: StateOrder` | 用 `state: number` 模糊类型 |
| 字典更新 → 改 JSON → `pnpm gen:enums` → 提交产物 | 直接手改生成产物文件 |
| 业务扩展放 `EnumExtend.ts` | 塞进 `EnumConst.ts`（下次生成被覆盖） |
| 枚举文本走 `enumeration.json` + `$t()` | 硬编码 `"已支付"` 等中文 |
| 引用统一 `@/config/EnumConst` 等绝对路径 | 相对路径 `../../config/EnumConst` |

> 完整链路见 [md-dev-standards.md §枚举与字典体系规范](references/md-dev-standards.md)

### 网络请求错误处理约定

> 拦截器（[src/api/request/index.ts](../../src/api/request/index.ts)）已统一处理底层网络与认证异常，**业务页面只负责业务级失败判定**。

#### 状态码处理矩阵

| statusCode | 拦截器行为 | 业务页面是否需介入 |
|------------|-----------|-------------------|
| `200` | 解析 + 翻译 msg → resolve | ✅ 检查 `res.state === 'success'` |
| `401` | 入队列 → reLaunch 登录 → emit `clearLoginCache` | ❌ |
| `403` | showToast(无权限,5s) → 2s 后跳登录 | ❌ |
| `498` | 入队列 → emit `doRefreshToken` → 刷新后重发 | ❌ |
| `>= 500` | 有 msg 则 showToast(3s) → reject | ✅ 可选 try/catch |
| 网络失败 | reject(error) | ✅ 必须 try/catch |

#### 业务页面标准写法

```typescript
try {
  const res = await guestOrderCreate({ data: form.value })
  if (res.state !== 'success') {
    uni.showToast({ title: res.msg, icon: 'none' })
    return
  }
  // ✅ 仅 success 时取 data
  const id = res.data!.id
} catch (err) {
  console.error(err) // 拦截器已 showToast，通常无需重复提示
} finally {
  uni.hideLoading()
}
```

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 先判 `res.state === 'success'` 再用 `res.data` | 直接 `res.data.xxx` 不判 state |
| 401 / 403 / 498 交给拦截器 | 业务页里写 `if (statusCode === 401)` |
| 错误文案用 `res.msg`（已 i18n） | 硬编码 `"操作失败"` 中文 |
| Loading 用 `try/catch/finally` | 漏 finally，loading 卡死 |
| 大数字 ID/订单号按 `string` 处理 | 用 `Number()` 转换 |
| 中文错误统一在 `handleErrorMsg` + 4 语言 i18n key 扩展 | 在每个页面 if/else 翻译错误 |
| 新增白名单接口先评审登录态依赖 | 把业务接口随意加入 APIwhiteList |
| token 刷新走 `uni.$emit('doRefreshToken')` 事件 | 业务页直接调用 `authRefreshToken` |

#### 错误提示分级

| 严重程度 | UI | 场景 |
|---------|----|----|
| 信息提示 | `showToast({ icon: 'none' })` | 搜索为空、表单未填 |
| 错误提示 | `showToast({ icon: 'error' })` | 库存不足、业务失败 |
| 确认对话 | `showModal({ showCancel: false })` | 订单超时、权限失效 |
| 阻断对话 | `showModal({ showCancel: true })` | 重新支付？放弃订单？ |
| 静默处理 | 仅 `console.warn` | 拦截器已处理 / 非关键查询失败 |

> 完整链路（含 handleErrorMsg / 大数字 JSON / 白名单维护 / 调试）见 [md-dev-standards.md §错误处理与状态码规范](references/md-dev-standards.md)

### 平台条件编译约定（H5 / 小程序 / App 跨端必读）

> 项目目标 **H5 / 小程序 / App** 三端，覆盖 mp-weixin / mp-toutiao / mp-xhs / mp-baidu / mp-alipay / app-plus。**新写跨端代码必须使用条件编译，否则某端必崩**。

#### 平台标识

| 平台 | 条件编译 | `process.env.VUE_APP_PLATFORM` |
|------|---------|-------------------------------|
| H5 | `H5` | `h5` |
| App | `APP-PLUS`（uni-app x 用 `APP`） | `app-plus` / `app` |
| 微信小程序 | `MP-WEIXIN` | `mp-weixin` |
| 抖音/头条 | `MP-TOUTIAO` | `mp-toutiao` |
| 小红书 | `MP-XHS` | `mp-xhs` |
| 百度 | `MP-BAIDU` | `mp-baidu` |
| 支付宝 | `MP-ALIPAY` | `mp-alipay` |
| 所有小程序 | `MP` | — |

#### 两种语法选择

| 场景 | 推荐 | 原因 |
|------|------|------|
| 整段 DOM / API / import 仅某端 | **A. 条件编译** `#ifdef` | 编译期剔除，产物小 |
| 单个表达式 / props 值切换 | **B. 运行时** `process.env.VUE_APP_PLATFORM` | 条件编译不支持切表达式 |
| `pages.json` / `manifest.json` 差异 | **A. JSON 条件编译** | 框架支持 |

#### 跨端 API 差异速查（高频）

| 能力 | H5 | 微信小程序 | App |
|------|----|----------|-----|
| 分享 | `navigator.share` / SharePopup | `onShareAppMessage` + `onShareTimeline` | `uni.share` |
| 支付 | 跳支付页（H5/H5_WEB） | `uni.requestPayment({ provider: 'wxpay' })` | `uni.requestPayment` |
| 扫码 | 第三方库 / `<input>` 拍照 | `uni.scanCode` | `uni.scanCode` |
| 定位 | `navigator.geolocation` | `uni.getLocation` | `uni.getLocation` |
| 复制 | `navigator.clipboard` | `uni.setClipboardData` | `uni.setClipboardData` |
| `window`/`document` | ✅ | ❌ | ❌ |
| `plus.*` | ❌ | ❌ | ✅ |
| `ResizeObserver`/`MutationObserver` | ✅ | ❌ | ❌ |
| `<web-view>` | ❌（用 iframe） | ✅ | ✅ |
| `responseType: 'arraybuffer'` | ✅ | ✅ | ✅（MP-ALIPAY ❌） |

#### 标准用法

```vue
<template>
  <!-- #ifdef MP-WEIXIN -->
  <button open-type="getPhoneNumber" @getphonenumber="onGetPhone">微信授权</button>
  <!-- #endif -->

  <!-- ✅ 单个表达式用运行时判断 -->
  <CustomCard :duration="isToutiao ? 1500 : 600" />
</template>

<script setup lang="ts">
// #ifdef H5
import VConsole from 'vconsole'
if (import.meta.env.DEV) new VConsole()
// #endif

const isToutiao = computed(() => process.env.VUE_APP_PLATFORM === 'mp-toutiao')

// #ifdef MP-WEIXIN
onShareAppMessage(() => ({ title: '...', path: '...' }))
onShareTimeline(() => ({ title: '...', query: '...' }))
// #endif
</script>

<style lang="scss" scoped>
.box {
  /* #ifdef H5 */    /* ⚠️ CSS 必须用 /* */ 注释 */
  position: sticky;
  /* #endif */
}
</style>
```

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| H5 专属 `import` 包在 `// #ifdef H5` 内 | 顶层 import 后再 `if (isH5)` |
| `window` / `document` / `navigator` 仅 `#ifdef H5` 内 | 任意位置引用（小程序崩溃） |
| `plus.*` 仅 `#ifdef APP-PLUS` 内 | H5 / 小程序里引用 |
| SCSS 条件编译用 `/* #ifdef H5 */` | 用 `// #ifdef H5`（不生效） |
| 单个 props 值切换用运行时判断 | 用条件编译切表达式（语法不支持） |
| 多平台 appId 走 `manifest.json` + `userStore.setAppId()` | 页面里硬编码 appid |
| 跨端能力收敛到 utils / 通用组件 | 每个页面重复写 `#ifdef` |
| 微信分享 `onShareAppMessage` + `onShareTimeline` 都配置 | 仅写一处 |
| `localStorage` 改用 `uni.setStorageSync` | 直接 `window.localStorage` |

#### 编译验证

```bash
pnpm build:h5         # H5
pnpm build:mp-weixin  # 微信小程序
pnpm build:app-plus   # App
# 合并主线前至少跑通 H5 + 微信小程序 + 目标 App
```

> 完整链路（语法、决策表、跨端 API 完整速查、模板、appId 维护、调试方法）见 [md-dev-standards.md §平台条件编译规范](references/md-dev-standards.md)

### Loading / 骨架屏 / 空状态约定

> 项目提供**4 类标准 UI**：页面级遮罩 / 关键提交 Loading / 列表分页 / 空状态。**禁止自造同类组件**。

| 场景 | 方案 | 显示 / 隐藏 |
|------|------|------------|
| 页面首屏 | `<GbLoading v-model="showLoading" />`（[GbLoading](../../src/components/GbLoading)） | `try`/`finally` 中置 true/false |
| 关键提交（下单/支付/改密码） | `uni.showLoading({ mask: true })` | `try` / `finally { uni.hideLoading() }` |
| 按钮 loading | `<button :loading>` / `<u-button :loading>` | API 前置 true，`finally` 置 false |
| 极短反馈 | `uni.showToast({ icon: 'loading' })` | 自动消失 |
| 列表上拉 / 触底 | `<uni-load-more :status>` 三态：`more` / `loading` / `noMore` | 翻页时切 `loading`，结果后切 `more` / `noMore` |
| 列表空状态 | 图片 + i18n 文案 + 重试按钮 | 首屏返回 0 条时显示 |
| 加载失败 | 业务自定义错误占位 + **重试按钮** | `catch` 分支 / `state !== 'success'` |
| 骨架屏（可选） | `<uni-skeleton>` / `<u-skeleton>` / Tailwind `animate-pulse` | 与 `GbLoading` 二选一 |
| 装修预览占位 | `waiting-cmp`（**仅装修体系**，业务页面不要用） | — |

#### 业务页面标准写法

```vue
<script setup>
const showLoading = ref(false)
const loadData = async () => {
  showLoading.value = true
  try {
    const res = await api()
    if (res.state !== 'success') {
      uni.showToast({ title: res.msg, icon: 'none' })
      return
    }
    detail.value = res.data
  } finally {
    showLoading.value = false // ✅ 必须 finally，避免异常时卡死
  }
}
</script>
<template>
  <GbLoading v-model="showLoading" />
</template>
```

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 页面级 Loading 用 `<GbLoading v-model>` | 自造全屏遮罩 + 转圈 |
| 关键提交用 `showLoading + try/finally` 三段式 | 漏 finally / 用 setTimeout 兜底 |
| 列表分页用 `<uni-load-more :status>` 三态 | 自己拼 `<view>没有更多了</view>` |
| 空状态显示 **图片 + i18n 文案 + 重试按钮** | 仅显示文字"暂无数据"无引导 |
| 失败状态提供 **重试按钮** | 仅 Toast 一闪而过 |
| 文案统一走 i18n（`common.noData` / `common.retry`） | 硬编码"暂无数据"等中文 |
| 骨架屏与 `GbLoading` 二选一 | 同一页面两者同时出现 |
| 装修预览占位用 `waiting-cmp` | 在业务页面用 `waiting-cmp` |

#### 必备 i18n key（4 语言同步）

`common.noData` / `common.emptyList` / `common.loadFailed` / `common.networkError` / `common.retry` / `common.needLogin` / `common.goLogin` / `common.noPermission` / `common.back` / `common.submitting`

> 完整链路（含场景与方案映射 / 完整代码模板 / Loading 时长与体验约定 / 空状态 UI 约定）见 [md-dev-standards.md §Loading / 骨架屏 / 空状态规范](references/md-dev-standards.md)

### 样式体系约定（Tailwind 优先）

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| **新写代码默认 Tailwind class**（`bg-primary` / `text-foreground` / `flex items-center` 等） | 简单样式也写 `<style lang="scss">` |
| 颜色用主题 class（`bg-primary` / `text-primary` / `border-border`） | 硬编码 `#ff6b4a` / `#1c1a19` 等十六进制 |
| 多行省略号复用 [base.scss](../../src/styles/base.scss) `.ellipsis2` / `.ellipsis3` | 在每个组件里重写 `-webkit-line-clamp` |
| 卡片阴影复用 `.div-shadow`、分割线复用 `.div-line` | 重复写 `box-shadow` / `border-bottom` |
| SCSS 仅用于 keyframes / 复杂选择器 / 复用 base.scss | 把 Tailwind 能表达的样式写成 SCSS |
| SCSS `<style>` 必须 `scoped` | 全局 `<style>` 污染其他组件 |
| 安全区用 `mainStore.statusHeight` + `env(safe-area-inset-bottom)` | 硬编码 `padding-top: 44px` |
| 行内 `:style` 仅用于真正动态值 | 行内 `style` 写固定样式 |

> 完整链路见 [md-dev-standards.md §样式体系规范](references/md-dev-standards.md)

### 业务通用组件复用约定（优先级最高）

新页面需要 UI 能力时，**按以下顺序判断**：

```
1. src/components/ 现有 Z* / Gb* / 业务组件 → 直接复用
2. uview-plus（u-* / up-*）                  → 直接用
3. @dcloudio/uni-ui（uni-*）                 → 直接用
4. 装修能力 → mall-widgets（m-*）            → 用 / 新增 m-{name}
5. 都没有 → 在 src/components/ 新建（命名遵循 Z* / Gb* / 业务名）
```

**现有自研组件清单**（详情见 [md-dev-standards.md §业务通用组件清单](references/md-dev-standards.md)）：

| 类别 | 组件 |
|------|------|
| Loading / 导航 | `GbLoading`、`GbNavbar`、`NavBar` |
| 容器 / 滚动 | `ZScrollView`、`ZDateScrollView` |
| 内容展示 | `ZRichText`、`ZScenicInfo`、`ZTag`、`ZTitle` |
| 表单 / 上传 | `ZUp`、`ZCalendar` |
| 弹窗 / 业务能力 | `PaymentPopup`、`SharePopup`、`Verify`（4 种行为验证码） |

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 新页面前先查本清单 | 直接造同类组件 |
| 自研通用组件放 `src/components/{Name}/index.vue` | 散落在业务页面目录里复制粘贴 |
| 命名走 `Z*` / `Gb*` / 业务名 三类前缀 | 业务组件用 kebab-case |
| 类型定义放 `type.ts`（Props/事件） | `.vue` 内重复定义 |
| 仅样式不同 → Tailwind class 调，不新建组件 | 仅为换色复制一份组件 |

### TabBar 配置约定（按需，非必须）

**TabBar 不是强制要求**，由实际业务决定是否启用。现有项目（`uw-uni-template`）即未配置 TabBar。

仅当业务确认需要底部固定多 Tab 导航时，按以下约定执行：

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| Tab 数量由 PRD 决定（常见 3~5 个，无固定数量） | 强制要求 4 Tab |
| Tab 页面切换使用 `uni.switchTab()` | Tab 页面使用 `uni.navigateTo()` |
| TabBar 图标使用 `static/tabbar/` 目录 | 图标放 `src/assets/` 目录 |
| **未启用 TabBar 的项目**：通过自定义底部组件或单页面导航实现 | 强行配置空 TabBar |

### pages.json 配置约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 启用 TabBar 时，TabBar 页面在 `tabBar.list` 中配置 | TabBar 页面仅在 `pages` 中配置 |
| 首页路径沿用项目惯例（如 `pages/home/index`） | 强制要求 `pages/index/index` |
| 每个页面配置 `navigationBarTitleText` | 页面缺少导航栏标题 |

### 字段一致性约定

| ✅ 正确                                      | ❌ 错误              |
| -------------------------------------------- | -------------------- |
| 表单字段名与 API DTO 字段名一致（camelCase） | 自行命名表单字段     |
| 列表项名与 API 返回字段名一致                | 前端字段名与后端不同 |
| 使用 label 显示中文，字段名保持英文          | 字段名直接用中文     |

### DataList 字段约定

新列表接口统一返回 `res.data?.list`。**新代码一律使用 `res.data?.list`**；旧接口返回的 `res.data?.results` 由开发者在调用层自行做兼容，不在此规范约束。

| ✅ 正确                       | ❌ 错误             |
| ----------------------------- | ------------------- |
| `res.data?.list`（列表数据，新接口） | 新代码使用 `res.data?.results` |
| `res.data?.total`（分页总数） | `res.data?.count`   |
| `res.data!`（实体数据）       | `res.data?.data`    |

### 导航方式约定

| ✅ 正确                        | ❌ 错误                                |
| ------------------------------ | -------------------------------------- |
| Tab 切换：`uni.switchTab()`    | Tab 切换：`uni.navigateTo()`           |
| 详情页栈式：`uni.navigateTo()` | 详情页：`uni.redirectTo()`             |
| 登录覆盖：`uni.redirectTo()`   | 登录：`uni.navigateTo()`（会保留历史） |
| 返回：`uni.navigateBack()`     | 返回：`uni.redirectTo()`               |

### 分享能力约定

| ✅ 正确                                             | ❌ 错误                    |
| --------------------------------------------------- | -------------------------- |
| 微信小程序：`onShareAppMessage` + `onShareTimeline` | 仅配置 `onShareAppMessage` |
| App 端：`uni.share()`                               | App 端无分享能力           |
| 分享参数包含 path + imageUrl + title                | 分享参数缺少 path          |

### 平台适配约定

| ✅ 正确                                    | ❌ 错误                                   |
| ------------------------------------------ | ----------------------------------------- |
| 条件编译：`#ifdef MP-WEIXIN` / `#ifdef H5` | 运行时 `uni.getSystemInfoSync()` 判断平台 |
| 安全区域：`safe-area-inset-bottom`         | 固定 padding-bottom 值                    |
| rpx 单位布局                               | px 单位布局                               |

> 完整开发规范见 [md-dev-standards.md](references/md-dev-standards.md)
> 编码原则见 [coding-principles.md](references/coding-principles.md)
> 设计规范见 [md-design-spec.md](references/md-design-spec.md)
> ⛔ **AI 生成前/中/后必读**：[anti-patterns.md](references/anti-patterns.md)（禁止生成清单 — 所有 ❌ 反例汇总）

## ResponseData\<T\> 解析规范

```
列表 API 返回：ResponseData<DataList<T>>
  - 列表数据：res.data?.list       → 类型 T[]（新接口规范）
  - 分页总数：res.data?.total

实体 API 返回：ResponseData<T>
  - 实体数据：res.data             → 类型 T
```

```typescript
const res = await guestQuestionList({ param: { $pg: 1, $rn: 20 } });
const list: PostQuestion[] = res.data?.list || [];

const res = await guestQuestionLoad({ id: 1 });
const detail: PostQuestion = res.data!;
```

> **新代码统一使用 `res.data?.list`**。历史代码中残留的 `res.data?.results` 由开发者按需做兼容处理，规范不强制改写。

## 工作流程

### Phase 0: 需求确认

确认聚焦业务层面。消费者端（guest）只有一个角色，跳过角色权限映射。

| 确认项                | 启发式问题                                            |
| --------------------- | ----------------------------------------------------- |
| 页面清单 + 复杂度分类 | "根据PRD，识别到N个页面[列出]，是否有遗漏？"          |
| TabBar 配置           | "本项目是否需要 TabBar？如需，确认 Tab 数量与对应页面（默认不启用）" |
| 平台适配              | "需要支持哪些平台？默认微信小程序+H5"                 |
| 定制页面              | "除标准CRUD页面外，还有哪些定制页面？"                |

### Phase 1: 架构蓝图

**输入**：PRD 文档 + Phase 0 确认结果

**输出两个文件**：

| 文件        | 定位                   | 内容                                                                          |
| ----------- | ---------------------- | ----------------------------------------------------------------------------- |
| `README.md` | 架构蓝图（给人+AI 读） | 页面总览、TabBar配置、PRD功能点映射、路由设计、字段一致性检查表、平台适配策略 |
| `TASKS.md`  | 进度清单（仅追踪）     | 并行分组、页面清单（简单/复杂分类）、状态复选框                               |

**README.md 必须包含的章节**：

| 章节           | 内容                            | 必要性 |
| -------------- | ------------------------------- | ------ |
| 页面总览       | 页面清单、复杂度分类、涉及API   | 必须   |
| TabBar 配置    | Tab 定义、图标、页面路径        | 按需（启用 TabBar 时必须） |
| PRD功能点映射  | 功能点 → 模块 → 页面的映射表    | 必须   |
| 路由设计       | pages.json 页面路由配置         | 必须   |
| 字段一致性检查 | 表单字段 ↔ API Schema字段对照表 | 必须   |
| 平台适配       | 微信小程序/H5/App 适配策略      | 必须   |
| 组件清单       | 复用组件列表                    | 按需   |

模板见 [references/design-templates.md](references/design-templates.md)

### Phase 2: 逐页面完整交付

按 TASKS.md 的分组顺序，**每组内可并行，组间串行**。每个页面执行以下步骤：

#### Step 1: 加载上下文

| 操作            | 说明                                    |
| --------------- | --------------------------------------- |
| 读 PRD 功能点   | 确认页面功能需求和交互要求              |
| 读 API 类型定义 | 从 `src/api/` 确认可用的 API 函数和类型 |
| 读 README.md    | 确认路由、TabBar、字段映射              |

#### Step 2: 创建页面

> 基于 gencode 产出的 API 类型定义，按业务需求创建页面。

| 策略              | 条件                                 | 操作                                  |
| ----------------- | ------------------------------------ | ------------------------------------- |
| 裁剪 gencode 页面 | gencode 生成了对应页面且质量可接受   | 调整字段、样式、交互                  |
| 基于类型新建      | gencode 未生成页面，或生成页面质量差 | 导入 gencode API 类型和函数，从零创建 |

**消费者端页面组织**：

- 主包 `src/pages/` 仅放入口、登录、渲染容器、WebView 等公共页面
- 业务分包**默认**放入 `src/packages/{module}/`
- 仅当业务方明确不希望路由路径携带 `packages/` 前缀时，才允许将分包根直接挂到 `src/{module}/`（需同步在 [pages.json](../../src/pages.json) 的 `subPackages[].root` 注册）
- 实际分包以 [pages.json](../../src/pages.json) 的 `subPackages` 配置为准
- 分包内不再细分角色目录（guest 端只有一个角色）
- 二级目录命名沿用现有项目 camelCase（如 `productDetail`、`placeOrder`、`orderList`）

**每个页面必须完整包含**：

| 内容                 | 说明                                          |
| -------------------- | --------------------------------------------- |
| 模板（template）     | 完整 UI 结构，含条件编译的平台适配代码        |
| 逻辑（script setup） | 完整交互逻辑 + API 调用 + 状态管理 + 分享配置 |
| 样式（style scoped） | 完整样式，rpx 单位，安全区域适配              |

代码模板见 [references/code-templates.md](references/code-templates.md)

#### Step 3: 配置路由

| 内容     | 说明                                                                                                            |
| -------- | --------------------------------------------------------------------------------------------------------------- |
| 页面路径 | 在 `pages.json` 中添加 `{root}/{module}/{page}`：主包加到 `pages`，业务分包加到 对应 `subPackages` 项的 `pages` |
| 导航栏   | 配置 `navigationBarTitleText`                                                                                   |
| TabBar   | **按需**：仅在业务确认需要时配置 `tabBar.list`，Tab 数量与图标由 PRD 决定                                       |

#### Step 4: 字段一致性检查

| 检查项     | 要求                                |
| ---------- | ----------------------------------- |
| 表单字段名 | 与后端 DTO 字段名一致（camelCase）  |
| 列表项名   | 与后端返回字段名一致                |
| 显示文本   | 使用 label 显示中文，字段名保持英文 |

#### Step 5: 平台适配

| 平台       | 适配内容                                                    |
| ---------- | ----------------------------------------------------------- |
| 微信小程序 | `onShareAppMessage` + `onShareTimeline`、安全区域、条件编译 |
| H5         | 响应式布局、浏览器 API 兼容                                 |
| App        | `uni.share()`、原生组件适配                                 |

> 多端适配规范详见 [md-dev-standards.md](references/md-dev-standards.md)

#### Step 6: 测试驱动开发（Red-Green 内部循环）

> **AI 原生 TDD**：内部自动执行 Red-Green 循环，用户只看到最终通过的结果。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)。

**6.1 Red 阶段**：

- 为 Store/工具函数编写测试代码
- 执行 `pnpm vitest run tests/store/useXxx.spec.ts` → **确认测试失败**
- ⚠️ 如果测试意外通过 → 说明断言不够严格，需加强

**6.2 Green 阶段**：

- 编写实现代码
- 执行 `pnpm vitest run tests/store/useXxx.spec.ts` → **确认测试通过**

**6.3 Refactor 阶段**（按需）：

- 优化代码结构
- 执行 `pnpm vitest run` → 确认仍然通过

| 测试对象 | 测试内容              | 文件位置                  |
| -------- | --------------------- | ------------------------- |
| Store    | 状态变更、异步 action | `tests/store/xxx.spec.ts` |
| 工具函数 | 纯函数输入输出        | `tests/utils/xxx.spec.ts` |

| ❌ 不测试    | ✅ 测试        |
| ------------ | -------------- |
| 页面组件渲染 | Store 状态变更 |
| UI 样式      | 工具函数边界值 |
| 框架 API     | 纯逻辑函数     |

#### Step 7: 编译验证

| 检查项               | 命令                                                                       |
| -------------------- | -------------------------------------------------------------------------- |
| 类型检查通过         | `pnpm type-check`                                                          |
| Lint 通过            | `pnpm lint`（必要时 `pnpm lint:fix`）                                      |
| 格式化通过           | `pnpm format:check`（必要时 `pnpm format`）                                |
| 综合检查             | `pnpm check`（type + lint + format 一键执行）                              |
| H5 编译通过          | `pnpm build:h5`                                                            |
| 微信小程序编译通过   | `pnpm build:mp-weixin`                                                     |
| 无 ref 双重调用      | `grep -rn 'ref<.*>(.*)(.*)' src/ --include="*.vue" --include="*.ts"`       |
| 新代码列表字段为 list | `grep -rn 'res\.data\?\.results\b' src/ --include="*.vue" --include="*.ts"`（新写代码应为 0，旧代码兼容期允许存在） |
| 文案走 i18n          | `grep -rn '"[\u4e00-\u9fa5]"' src/ --include="*.vue" --include="*.ts"`（业务文案应全部走 `$t()`） |
| 枚举产物未被手改     | `git diff --name-only HEAD -- src/config/EnumConst.ts src/config/optionsConst.ts`（应为空；如有差异且 `EnumLabelMap.json` 未变 → 回退并改走 `EnumExtend.ts`） |
| 字典 JSON 已重新生成 | 若 [EnumLabelMap.json](../../src/config/EnumLabelMap.json) 有变更 → 必须执行 `pnpm gen:enums` 并提交产物 |
| 业务页未非法处理认证状态码 | `grep -rEn 'statusCode\s*===?\s*(401\|403\|498)' src/`（应为 0，统一由拦截器处理） |
| 业务页未直接调 refreshToken | `grep -rn 'authRefreshToken' src/` 过滤掉 `requestEventHandler.ts` 后应为 0 |
| Loading 平衡 | 单文件中 `uni.showLoading` 数量 ≤ `uni.hideLoading` 数量；`<GbLoading v-model>` 状态置 false 必须在 `finally` |
| 空状态/失败态文案走 i18n | `grep -rEn '"(暂无数据\|加载失败\|网络异常\|没有更多)"' src/`（应为 0） |
| 跨端 API 未包裹条件编译 | `grep -rEn '(^\|[^.])\b(window\|document)\.' src/ --include="*.vue" --include="*.ts"` 后人工核对在 `#ifdef H5` 内 |
| App 专属 API 未包裹 | `grep -rn 'plus\.' src/` 应仅出现在 `#ifdef APP-PLUS` 内 |
| SCSS 错用 `//` 注释式条件编译 | `grep -rEn '//\s*#(ifdef\|ifndef\|endif)' src/ --include="*.scss" --include="*.vue"`（应为 0） |

**全部通过后**，在 TASKS.md 中标记该页面为已完成，进入下一个页面。

## 完成标准

- [ ] README.md 覆盖所有页面和 PRD 功能点映射
- [ ] TASKS.md 包含并行分组，所有页面已标记完成
- [ ] 所有 PRD 功能点都有对应页面
- [ ] 表单字段名与 API Schema 字段名一致（camelCase）
- [ ] 列表数据（新代码）使用 `res.data?.list`（旧 `res.data?.results` 由开发者按需兼容）
- [ ] pages.json 路由配置正确；如启用 TabBar 则按业务需要配置 `tabBar.list`
- [ ] H5 和微信小程序编译通过
- [ ] `pnpm check`（type-check + oxlint + oxfmt）通过
- [ ] 业务文案统一走 `vue-i18n`（`$t()` / `t()`），4 种语言（zh-CN / zh-TW / en / ja）的 key 同步补齐
- [ ] UI 组件优先复用 `@dcloudio/uni-ui`（`uni-*`）/ `uview-plus`（`u-*` / `up-*`）/ `mall-widgets`（`m-*`），避免自造重复组件
- [ ] 自研 UI 能力先查 [src/components/](../../src/components) 现有 `Z*` / `Gb*` / 业务组件清单，能复用即复用
- [ ] 样式默认走 Tailwind class（颜色使用 `bg-primary` / `text-foreground` 等主题 class，不硬编码十六进制）；SCSS 仅用于复杂场景且 `scoped`
- [ ] 状态判断/类型比较走 `EnumConst.ts` 中的 `enum`；下拉/筛选走 `optionsConst.ts` 中的 `XxxOptions`，禁止魔数与手抄选项数组
- [ ] 新增/变更字典通过 `pnpm gen:enums` 重新生成；业务扩展放 `EnumExtend.ts` 不手改生成产物
- [ ] 业务页面调用 API 时**先判 `res.state === 'success'` 再用 `res.data`**；401/403/498 交给拦截器；错误文案统一走 `res.msg`（已 i18n）
- [ ] Loading 包裹在 `try/catch/finally`，确保 `uni.hideLoading()` 被调用；大数字 ID/订单号按 `string` 处理
- [ ] 中文错误翻译统一在 `handleErrorMsg` + 4 语言 i18n key，禁止在每个页面 if/else 翻译；APIwhiteList 仅用于无登录态接口
- [ ] 页面级 Loading 用 `<GbLoading v-model>`；关键提交用 `uni.showLoading` + `try/finally`；列表分页用 `<uni-load-more :status>` 三态
- [ ] 列表空状态显示 **图片 + i18n 文案 + 重试按钮**；加载失败必须提供 **重试按钮**；必备 i18n key（`common.noData`/`loadFailed`/`retry` 等）4 语言同步
- [ ] 登录/Token 走 `userStore.setLoginInfo()` + `tokenManager`，禁止页面自管 token；外部 token 用 `setToken()`
- [ ] 多租户 `saasId` 通过 `userStore.siteInfo` / `setSiteInfo()`，多平台 `appId` 通过 `setAppId()`
- [ ] 新增装修组件统一放 `src/mall-widgets/m-{name}/`，并在 [render-widget.vue](../../src/components/render-widget.vue) 注册分发；schema 字段放 `src/schema/m-{name}/`
- [ ] 无 `ref<...>(null)(null)` 双重调用
- [ ] 微信小程序分享能力已配置（`onShareAppMessage` + `onShareTimeline`）
- [ ] 平台适配代码使用条件编译（`#ifdef`），跨端能力遵循 [§平台条件编译约定](#平台条件编译约定h5--小程序--app-跨端必读)：`window`/`document`/`navigator` 仅 `#ifdef H5`、`plus.*` 仅 `#ifdef APP-PLUS`；SCSS 条件编译用 `/* */`；多平台 appId 走 `manifest.json` + `userStore.setAppId()`

## ⚠️ 完成验证（强制，全自动执行）

1. **强制执行编译验证**（Phase 2 Step 6 的所有检查项）
2. **强制调用** `221-guest-uni-dev-review`
3. 不通过（< 95）→ 自动修复 → 重新评审（最多 5 轮）
4. 通过（≥ 95）→ 向用户报告最终结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [UniApp 开发规范](references/md-dev-standards.md) - Vue3+TS 多端开发规范
- [设计模板](references/design-templates.md) - README页面清单 + TASKS.md模板
- [代码模板](references/code-templates.md) - 页面组件代码模板
- [移动端开发评审技能](../221-guest-uni-dev-review/SKILL.md)
