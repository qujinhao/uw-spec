# 禁止生成清单（Anti-Patterns）

> **AI 代码生成前必读**。本文档汇总了项目所有规范中的 ❌ 反例，按主题分组。
> 生成代码前，AI 必须确保产物不命中以下任何一条；命中即视为不合格，必须重写。
> 用法：每写完一个文件 → 对照本表自检 → 命中条目 → 按 ✅ 替代方案修复 → 通过后再提交。

---

## 0. 速查 — 触发即拒绝的"红色信号"

下面 10 条是 AI 最常踩的雷，**任何一条出现都必须立即修复**：

| 红色信号 | 修复方向 |
|---------|---------|
| 1. `uni.request(...)` 直接调用 | 改走 `@/api/{service}Api.ts` 业务函数 |
| 2. `const list = res.data.list`（未判 state） | 先判 `if (res.state !== 'success') return; const list = res.data?.list \|\| []` |
| 3. `ref<T>(null)` 类型缺 `\| null` | 改 `ref<T \| null>(null)` |
| 4. `:style="{ color: '#ff6b4a' }"` 硬编码十六进制 | 改 `class="text-primary"` 或 `class="text-[var(--color-primary)]"` |
| 5. `<text>暂无数据</text>` 硬编码中文 | 改 `<text>{{ $t('common.empty') }}</text>` |
| 6. `if (statusCode === 401)` 业务页处理 401 | 删掉，交给 `src/api/request/` 拦截器 |
| 7. `let state = 21`（魔数） | 改 `import { StateOrder } from '@/config/EnumConst'; state = StateOrder.paid` |
| 8. `import vconsole from 'vconsole'` 顶层裸 import | 包到 `// #ifdef H5 ... // #endif` |
| 9. `window.localStorage.setItem(...)` 直接用 | 改 `uni.setStorageSync(...)` |
| 10. `v-for="item in list"` 缺 `:key` | 必须 `:key="item.id"`，禁止 `:key="index"` |

---

## 1. 数据结构 / API 调用

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| `uni.request({ url: '...', ... })` | 走 `@/api/{xxx}Api.ts` 的封装函数 | 绕过拦截器、token、错误处理、大数字处理 |
| `import axios from 'axios'` | 用项目封装的 `request` | 项目不依赖 axios |
| 自建 `httpClient.ts` / 自封 fetch | 直接调用 `@/api/*Api.ts` 函数 | 重复造轮子，拦截器不一致 |
| `const list = res.data.list` | `if (res.state !== 'success') return; const list = res.data?.list \|\| []` | 跳过业务状态判定会导致 UI 显示无效数据 |
| `const list = res.data.results` | 用 `res.data.list`（新接口） | 新列表接口统一字段 `list`；旧接口兼容由开发者按需处理 |
| `res.data` 无可选链直接解构 | `res.data?.xxx` 或先判 `res.data` 存在 | 异常响应时 `data` 可能为 undefined |
| 在页面里写 `if (res.statusCode === 401)` | 删除，交给拦截器 | 401/403/498 已统一处理 |
| 业务页直接调用 `authRefreshToken()` | 删除，498 时拦截器自动 refresh | 重复实现 refresh 流程 |
| 给 `APIwhiteList` 加非匿名接口（白名单） | 仅"完全无登录态接口"才能加，需 review | 错误加白名单会绕过登录态校验 |
| 把所有 API 拆成 `src/api/{module}/index.ts` | 平铺单文件 `src/api/{service}Api.ts` | 项目约定平铺命名 |
| 在 `src/api/request/` 外重复封装请求 | 复用 `@/api/request/` 通用层 | 拦截器不一致 |

---

## 2. 类型 / TypeScript

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| `ref<UserInfo>(null)` | `ref<UserInfo \| null>(null)` | 类型不允许 null |
| `ref<UserInfo>(null)(null)` | `ref<UserInfo \| null>(null)` | 双重调用必崩 |
| `defineProps({ id: String })` | `defineProps<{ id: string }>()` | 项目统一 `<script setup lang="ts">` 类型化 props |
| `defineEmits(['close', 'submit'])` | `defineEmits<{ close: []; submit: [value: T] }>()` | 同上，事件参数类型缺失 |
| 业务页面手抄 `interface Order { ... }` 与 API 重复 | 可从 `@/api/*` import，或在 `src/types/` 集中，或本地定义后**不与 API 类型重复** | 多源类型易漂移 |
| `any` 满天飞 | 优先 `unknown` + 收窄；明确禁止 `any[]` | 失去类型保护 |
| 大数字字段（订单号/雪花 ID）用 `number` | 用 `string` | JS number 精度丢失 |
| `as` 强转替代类型守卫 | 用 `if ('field' in obj)` 或类型谓词 | 强转易出错 |

---

## 3. 命名 / 文件组织

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| 新建 `src/composables/` 目录 | 通用逻辑放 `src/utils/` 或封装为组件 | 项目不引入 composables 体系 |
| 业务分包路径硬编码 kebab-case `src/packages/user-coupon/` | 沿用现有 camelCase 风格：`src/packages/userCoupon/` | 与现有项目一致 |
| 通用顶层目录改名（如把 `static/` 改成 `assets/`） | 保持 11 项固定通用目录不变 | 通用目录不可改名/缺失 |
| 把分包乱挂到 `src/` 根 | **默认** `src/packages/{module}/`；仅当路由路径不能带 `packages/` 才挂 `src/{module}/` 并在 [pages.json](../../../../src/pages.json) `subPackages.root` 注册 | 分包位置必须有依据 |
| 同一目录 `type.ts` 和 `types.ts` 混用（同一组件内） | 单组件内只用一种（项目两种都有，新组件择一即可） | 一致性 |
| `index.vue` 与 `{Name}.vue` 在同目录同时存在 | 每个组件目录只有一个入口 | 避免歧义 |
| 自创顶层目录（`src/lib/`、`src/helpers/`） | 用 `src/utils/` | 通用目录已固定 |

---

## 4. 路由 / 页面

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| 业务页面写在 `src/pages/`（主包） | 业务页放 `src/packages/{module}/` 或对应分包根 | 主包仅放首屏/Tab/登录注册等核心页 |
| 新页面忘记注册到 [pages.json](../../../../src/pages.json) | 主包加到 `pages`；分包加到对应 `subPackages.pages` | 不注册无法访问 |
| 跳转用 `uni.navigateTo` 字符串路径硬编码 | 走 [utils/tool.ts navToUrl](../../../../src/utils/tool.ts) 封装 | 易写错、参数序列化不一致 |
| 强制要求 TabBar | TabBar **按需**配置；现项目未启用 | 业务决定 |
| 修改 TabBar 主题色硬编码 | 启用 TabBar 时用项目主题色变量 | 一致性 |

---

## 5. 国际化 / i18n

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| `<text>暂无数据</text>` 硬编码中文 | `<text>{{ $t('common.empty') }}</text>` | 缺多语言 |
| 仅在 `zh-CN.json` 加 key | 4 语言（zh-CN / zh-TW / en / ja）**同步**补齐 | 缺 key 导致英文/日文/繁体显示原 key |
| 直接拼接字符串 `'共 ' + count + ' 条'` | 用 `$t('common.total', { count })` 占位符 | 各语言语序不同 |
| 枚举 label 硬编码中文 | 通过 `enumeration.{enumName}.{value}` 走 i18n | 字典文案与多语言耦合 |
| 不引入 `useI18n` 直接拼 zh-CN 文案 | `const { t } = useI18n(); t('...')` | 单语言固化 |

---

## 6. 状态管理 / Store

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| Pinia option API 写法 `defineStore('user', { state, actions, ... })` | 沿用现有 setup 风格：`defineStore('user', () => { ... }, { unistorage: true })` | 项目统一 setup |
| 业务页面直接读写 `loginInfo.token = '...'` | 走 store 方法 `setLoginInfo()` / `setToken()` / `clearLoginCache()` | 失去响应式与持久化 |
| 在多处复制 `userInfo` 状态 | 一律走 `useUserStore` 单一来源 | 状态漂移 |
| 用 `localStorage` 持久化登录态 | 用 `pinia-plugin-unistorage`，store 第三参 `{ unistorage: true }` | 跨端不通用 |
| 登出只清 `userInfo` | 调 `LogOut()` 或 `clearLoginCache()`（包含 token / refreshToken / 路由） | 残留 token 导致下次自动登录异常 |
| `import { user } from '@/store/user'` 直接拿对象 | `import { useUserStore } from '@/store/user'; const userStore = useUserStore()` | Pinia 实例化规范 |

---

## 7. 登录 / Token / 多租户

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| 业务页直接读 `userStore.loginInfo.token` | 用 `userStore.token` getter | 跨多种 token（真实/外部/匿名）的统一出口 |
| 业务页面手动调 `authRefreshToken` | 让拦截器自动处理 | 重复实现导致死循环 |
| 在页面里硬编码 `appid: 'wxxxxxx'` | 走 `manifest.json` + `userStore.setAppId()` 自动选取 | 多平台/多 appid |
| 切站点不调 `setSiteInfo` | 走 `userStore.setSiteInfo({ saasId, siteId, ... })` | 多租户状态丢失 |
| 401 弹自定义登录窗 | 走拦截器 reLaunch 到登录页 | 多端体验不一致 |

---

## 8. UI / 样式

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| `:style="{ color: '#ff6b4a' }"` | `class="text-primary"` 或 Tailwind | 主题色硬编码导致皮肤切换失败 |
| 大段自写 SCSS 代替 Tailwind | **优先 Tailwind class**，次选 SCSS（scoped），最后才行内 style | 项目样式优先级约定 |
| `<style>` 不写 `scoped` | 组件级样式必须 `scoped` | 全局污染 |
| `px` 单位写死 | 用 `rpx`（小程序/H5 自适应）或 Tailwind 间距 | 跨设备适配 |
| 自造全屏遮罩 `position: fixed; z-index: 99` Loading | 统一用 `<GbLoading v-model>` | 与项目 Loading 风格不一致 |
| 自造 Toast / Modal | 用 `uni.showToast` / `uni.showModal` 或 `<u-modal>` | 重复造轮子 |
| 同页面混用 `<uni-popup>` + `<u-popup>` | 弹窗类**统一**选 uview-plus `<u-popup>` | UI 风格不统一 |

---

## 9. 组件复用 / UI 库

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| 新建一个 LoadingCard 自定义实现 | 优先用 [GbLoading](../../../../src/components/GbLoading) 或 [waiting-cmp](../../../../src/components/waiting-cmp)（装修预览内部使用） | 项目已有 |
| 新写日期选择器 | 用 [ZCalendar](../../../../src/components/ZCalendar) 或 `<uni-datetime-picker>` | 已有组件 |
| 新写富文本展示 | 用 [ZRichText](../../../../src/components/ZRichText) 或 `<mp-html>` | 已有组件 |
| 新写支付组件 | 复用 [PaymentPopup](../../../../src/components/PaymentPopup) + [PAY_TYPE](../../../../src/config/EnumExtend.ts) | 已有完整支付体系 |
| 新写分享组件 | 复用 [SharePopup](../../../../src/components/SharePopup) | 已有 |
| 直接复用三类 UI 库未声明 easycom | 在 [pages.json easycom](../../../../src/pages.json) 已配置：`uni-* / u-* / up-* / u--* / m-*` | 已自动注册，无需 import |
| 新组件命名 `MyCard.vue` 不带前缀 | 自研组件命名 `Z*` / `Gb*` / 业务名 | 项目命名规则 |
| 装修组件随便取名 `MyBanner` | 装修组件**必须** `m-{name}` 放 [mall-widgets/](../../../../src/mall-widgets) | 装修体系硬约束 |
| 在业务页面里用 `<waiting-cmp>` | 业务页用 `<GbLoading>`；`waiting-cmp` 仅装修预览 | 用错场景 |

---

## 10. 装修 / 渲染引擎

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| 装修组件放 `src/components/` 下 | 必须放 [src/mall-widgets/m-{name}/](../../../../src/mall-widgets) | 装修体系扫描路径 |
| 装修组件 props 自由定义 | 必须 `{ attrs, styles, list }` 三段式 | DSL 协议固定 |
| 装修组件直接 `uni.navigateTo` 跳转 | `emit('jump', { url, params })` 由父级 [render-widget](../../../../src/components/render-widget.vue) 处理 | 装修预览模式跳转走 postMessage |
| 新增装修组件忘记注册到 [render-widget.vue](../../../../src/components/render-widget.vue) | 必须在 render-widget 注册分发 | 否则不渲染 |
| 装修组件没有对应 schema | 必须在 [src/schema/](../../../../src/schema) 加 `m-{name}/component.json` | 装修后台无法配置 |
| 业务页直接复用装修 `m-*` 组件做静态展示 | ✅ 可以，但要通过 `<render-widget>` 统一入口 | 数据格式不兼容 |

---

## 11. 枚举 / 字典

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| 状态判断 `if (state === 21)`（魔数） | `import { StateOrder } from '@/config/EnumConst'; if (state === StateOrder.paid)` | 不可读、易出错 |
| 下拉选项手抄数组 `[{label:'已支付', value:21}]` | 用 `@/config/optionsConst` 的 `StateOrderOptions` | 与字典脱节 |
| 手改 [EnumConst.ts](../../../../src/config/EnumConst.ts) / [optionsConst.ts](../../../../src/config/optionsConst.ts)（生成产物） | 改 [EnumLabelMap.json](../../../../src/config/EnumLabelMap.json) → `pnpm gen:enums` 重新生成 | 生成产物提交前 `git diff` 校验无人工改动 |
| 业务扩展枚举塞到 `EnumConst.ts` | 业务扩展枚举放 [EnumExtend.ts](../../../../src/config/EnumExtend.ts) | 生成器会覆盖 |
| 枚举 label 直接硬编码中文 | 走 i18n `$t('enumeration.{EnumName}.{value}')` | 多语言失效 |
| 财务字段用 `EnumConst` | 财务字段用 [EnumConstForFinance.ts](../../../../src/config/EnumConstForFinance.ts) / [optionsConstForFinance.ts](../../../../src/config/optionsConstForFinance.ts) | 字典分域 |

---

## 12. 错误处理 / Loading

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| `showLoading` 后无 `try/catch/finally` | 必须 `try { await ... } catch { ... } finally { uni.hideLoading() }` | 异常时 loading 卡死 |
| 抛错只 `console.error`，无用户提示 | `uni.showToast({ title: res.msg \|\| t('common.error') })` | 用户无感知 |
| 列表分页不区分 more/loading/noMore | 用 `<uni-load-more :status>` 三态 | UX 不完整 |
| 空数据/失败态只显示一行 `<text>无数据</text>` | 必备**图片 + i18n 文案 + 重试按钮**三要素 | 视觉一致性 |
| 同页面同时用骨架屏 + GbLoading | 二选一 | 体验冲突 |
| 在 `App.vue` 全局 try/catch 吞所有错 | 让拦截器统一处理 | 错误黑洞 |
| 中文错误文案硬编码 | 走 `handleErrorMsg` + 4 语言 i18n key | 多语言失效 |
| 大数字（订单号 / 雪花 ID）按 `number` 处理 | API 类型声明为 `string`，请求开启大数字 JSON 兼容 | 精度丢失 |

---

## 13. 平台条件编译

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| 顶层 `import vconsole from 'vconsole'` | `// #ifdef H5\nimport VConsole from 'vconsole'\n// #endif` | 小程序构建失败 |
| 直接 `window.localStorage.setItem(...)` | 用 `uni.setStorageSync(...)` | 小程序运行时崩溃 |
| 任意位置使用 `document` / `navigator` | 仅在 `// #ifdef H5` 包裹内 | 小程序无对应全局 |
| 任意位置使用 `plus.*` | 仅在 `// #ifdef APP-PLUS` 包裹内 | H5 / 小程序不可用 |
| SCSS 写 `// #ifdef H5`（注释式） | SCSS 必须用 `/* #ifdef H5 */` | `//` 在 CSS 中是普通注释，条件不生效 |
| 条件编译切单个 props 值 | 用 `process.env.VUE_APP_PLATFORM` 运行时判断 | 条件编译不支持表达式内切换 |
| 直接 `uni.share` 在 H5 里调用 | `#ifdef APP-PLUS` 包裹 | H5 不支持 |
| 模板里给 H5 写 `<web-view>` | H5 用 `<iframe>` | H5 渲染失败 |
| 在页面里硬编码 `appid: 'wx...'` | 走 [manifest.json](../../../../src/manifest.json) + `userStore.setAppId()` 自动选取 | 多平台维护 |
| 微信小程序分享只配 `onShareAppMessage` | 同时配 `onShareTimeline` | 朋友圈分享缺失 |
| 跨端能力（分享/支付/扫码）每页面重复写 `#ifdef` | 收敛到 `utils/` 或通用组件 | 维护成本高 |

---

## 14. Vue 语法 / 模板

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| `v-for="item in list"` 缺 `:key` | `v-for="item in list" :key="item.id"` | Vue 警告 / 渲染异常 |
| `:key="index"` | `:key="item.id"`（除非确实无 id） | index 在增删时不稳定 |
| `v-if + v-for` 同一元素 | 拆为两层 `<template v-if>` + `<view v-for>` | Vue 3 优先级问题 |
| 模板内大段三元表达式 / 链式调用 | 移到 computed | 模板可读性 |
| 直接修改 `props.xxx = ...` | `emit('update:xxx', value)` | props 单向数据流 |
| `<script>` 不写 `setup lang="ts"` | 统一 `<script setup lang="ts">` | 项目约定 |
| 异步组件无 Loading 兜底 | 用 `<Suspense>` 或自加 loading state | UX 缺失 |

---

## 15. 工程 / 工具

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| 引入 ESLint / Prettier | 使用 `oxlint` + `oxfmt`（项目已配） | 多套规则冲突 |
| 安装新 UI 库（如 `vant`、`element-plus`） | 用现有三类：uni-ui + uview-plus + mall-widgets | 包体积/风格冲突 |
| 安装 axios / fetch 库 | 用 `@/api/request/` | 拦截器统一 |
| 引入新状态库（如 vuex、zustand） | 用 Pinia | 已固定 |
| 引入新时间库（如 moment） | 用 dayjs（已引入并配 i18n locale） | 重复引入 |
| 引入新加密库（如 bcrypt） | 用 `jsencrypt` + `crypto-js`（已配 PUBLIC_KEY） | 重复 |
| 自写 console.log 调试 | 生产 terser 自动 drop；开发用 vConsole | 已配置 |
| 写测试时引入 jest | 项目目前无测试栈（vitest 依赖待引入） | 与现状不符 |

---

## 16. 提交 / 流程

| ❌ 错误 | ✅ 正确 | 原因 |
|--------|--------|------|
| 直接修改 [EnumConst.ts](../../../../src/config/EnumConst.ts) 并提交 | 改 EnumLabelMap.json → `pnpm gen:enums` → `git diff` 校验产物 → 提交 | 生成产物会被下次覆盖 |
| 不跑 `pnpm check` 直接 commit | husky pre-commit 会拦；本地先跑 `pnpm check` | 提交前必须通过 lint/format |
| 跨端能力只在 H5 测过就上线 | 合并主线前**至少跑通** `pnpm build:h5` + `pnpm build:mp-weixin`（+ 目标 App / 其他小程序） | 某一端必崩 |
| commit 信息任意 | 遵循 [commitlint.config.cjs](../../../../commitlint.config.cjs) 规则 | 提交记录可追溯 |
| 推 main/master 用 `--force` | 禁止 | 数据丢失风险 |

---

## 17. AI 生成专属"自检清单"

每次生成完一个文件，AI 必须自问以下问题，**有任何一项答 No 必须修复**：

```
□ 我的 import 都用了 @/ 前缀，而不是相对路径 ../../../ 吗？
□ 我没有用 res.data.list 直接取值吗？（必须先判 res.state === 'success'）
□ 我的 ref<T>(null) 类型写对了吗？（必须 T | null）
□ 我没有用魔数判断状态吗？（必须从 @/config/EnumConst 引入）
□ 我没有硬编码中文吗？（必须走 $t() 且 4 语言同步）
□ 我没有硬编码十六进制颜色吗？（必须用主题 class / Tailwind / CSS 变量）
□ 我的 v-for 都加了 :key="item.id" 吗？
□ 我没有自造 Loading / Toast / Popup 吗？（必须复用 GbLoading / uni.showToast / u-popup）
□ 跨端 API 是否都用了 #ifdef 包裹？（window/document/plus 必须）
□ 我没有在页面里手动处理 401 / 调 authRefreshToken 吗？（必须交给拦截器）
□ 我没有在业务页面直接 uni.request 吗？（必须走 @/api/*Api.ts）
□ 我没有把分包随便挂到 src/ 根吗？（默认 src/packages/{module}/）
□ 我新建的组件命名符合 Z* / Gb* / 业务名 / m-* 规则吗？
□ 我没有同时引入 ESLint/Prettier/axios/vant 等冲突依赖吗？
□ 我没有手改 EnumConst.ts / optionsConst.ts 生成产物吗？（必须改 JSON + gen:enums）
□ 我的新 i18n key 在 zh-CN / zh-TW / en / ja 四份都加了吗？
□ 我的 SCSS 条件编译用的是 /* */ 而不是 // 吗？
□ 业务页面的 await 调用是否都在 try/catch/finally 内、loading 是否一定 hide？
```

---

## 18. "看到这些模式必须停手"清单（高危信号）

| 看到这种模式 | 立即停手并修改 |
|------------|--------------|
| 任何字面量数字状态码（21、91、'2'、'3'） | 检查是否应改 EnumConst |
| 任何字面量中文字符串 | 检查是否应改 $t() |
| 任何 `#xxxxxx` 颜色 | 检查是否应改 class |
| 任何 `position: fixed; z-index: 99` | 检查是否应改 GbLoading |
| 任何 `uni.request(` | 改 `@/api/*Api.ts` |
| 任何 `authRefreshToken(` 业务页调用 | 删除 |
| 任何 `loginInfo.token =` 直接赋值 | 改 setLoginInfo |
| 任何 `localStorage.` / `sessionStorage.` | 改 uni.setStorageSync |
| 任何 `console.error` 替代用户提示 | 加 showToast |
| 任何 `try { ... }` 缺 `finally` 且前面有 showLoading | 加 finally + hideLoading |

---

## 用法（写给 AI）

1. **生成前**：读本表 §0 红色信号 + §17 自检清单
2. **生成中**：每输出一段代码，对照 §1–§16 主题表自问"我有没有命中 ❌"
3. **生成后**：跑一遍 §17 自检清单；命中任意一条 → 重写
4. **提交前**：执行 §16 流程项（`pnpm gen:enums` / `pnpm check` / 跨端编译）

> 命中 ❌ 而不修复 = 代码不合格。开发者会按本表逐条审查。
