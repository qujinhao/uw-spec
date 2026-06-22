# Web 后台管理系统开发规范（Vue3 + TypeScript + Vite + Element Plus）

> 适用于 SaaS 后台管理系统开发。被 220-admin-web-dev 和 220-admin-web-dev 引用。
> **编码规范详见 [coding-principles.md](coding-principles.md)**，本文件仅保留架构和框架层面的规范。

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue | ^3.5.x | 前端框架（Composition API） |
| TypeScript | ~5.7.x | 类型安全 |
| Vite | ^8.0.x | 构建工具 |
| Element Plus | ^2.14.x | UI 组件库 |
| Pinia | ^2.3.x | 状态管理 |
| Vue Router | ^4.5.x | 路由 |
| Axios | ^1.18.x | HTTP 客户端 |

## Vite 工程配置与自动导入机制

项目基于 Vite 构建，核心配置位于 `vite.config.ts`。

### 路径别名

| 别名 | 指向 | 说明 |
|------|------|------|
| `@/` | `src/` | 项目源码根目录（唯一推荐使用的别名） |
| `~/` | `src/` | 与 `@/` 等价，兼容使用 |

```typescript
// 推荐写法
import { useCrud } from '@/hooks/useCrud'
import appVersion from '@/config/appVersion'
```

`tsconfig.json` 中已配置 `paths: { "@/*": ["src/*"] }`，确保 IDE 类型推导正确。

### 自动导入机制

项目配置了 `unplugin-auto-import` 和 `unplugin-vue-components`，开发时**不需要手动导入**以下内容：

#### 1. Vue / Vue Router / VueUse API

`unplugin-auto-import` 已配置自动导入以下模块：

- `vue`：`ref`, `reactive`, `computed`, `watch`, `onMounted`, `getCurrentInstance`, `useRoute`, `useRouter` 等
- `vue-router`：`useRoute`, `useRouter` 等
- `@vueuse/core`：`useToggle`, `useDark`, `useLocalStorage` 等

```typescript
// 不需要 import，可直接使用
const count = ref(0)
const route = useRoute()
const isDark = useDark()
```

#### 2. `src/components/` 下的组件

`unplugin-vue-components` 自动扫描 `src/components/` 目录，所有组件均**不需要手动 import**。

```vue
<!-- 不需要 import SearchForm，直接使用 -->
<template>
  <SearchForm :form-type="searchFormType" />
</template>
```

> 组件类型声明由插件自动生成到 `components.d.ts`，该文件已加入 `.gitignore`，无需提交。

#### 3. Element Plus 组件

通过 `ElementPlusResolver` 自动按需导入 Element Plus 组件（如 `<el-button>`）及其样式，页面中**不需要手动 import**。

> **注意**：Element Plus 的组合式 API（如 `ElMessage`、`ElMessageBox`、`ElLoading`、`ElNotification`）**需要手动引入**。
>
> ```typescript
> import { ElMessage, ElMessageBox } from 'element-plus'
> ```
>
> Element Plus 图标（如 `Sunny`、`Moon`）来自 `@element-plus/icons-vue`，已在 [src/main.ts](src/main.ts) 中全局注册，**不需要手动导入**。

### SCSS 全局引入

每个 `.scss` 文件编译前会自动注入：

```scss
@use "@/layout/config.module.scss" as *;
```

因此页面和组件的 `<style lang="scss">` 中**可直接使用** `$asideWidth`、`$headerHeight` 等布局变量，无需重复 `@import`。

### 构建优化

| 配置项 | 说明 |
|--------|------|
| `minify: 'terser'` | 生产构建使用 Terser 压缩 |
| `drop_console: true` | 移除所有 `console.*` |
| `drop_debugger: true` | 移除所有 `debugger` |
| `chunkSizeWarningLimit: 2000` | chunk 大小警告阈值 2000KB |
| `manualChunks` | 按库分包：`vue-vendor`、`element-plus`、`echarts`、`tinymce`、`utils`、`vendor` |
| `worker: { format: 'es' }` | Web Worker 编译为 ES Module 格式 |
| `compression` | gzip 压缩 1KB 以上文件 |

### 编译期常量

| 常量 | 来源 | 用途 |
|------|------|------|
| `import.meta.env.VITE_GIT_SHA` | 当前 Git 短 SHA | 版本追踪、系统信息展示 |
| `__APP_NAME__` | `package.json` 的 `name` | 应用名称标识 |

## 国际化（i18n）

项目基于 `vue-i18n` 实现多语言，支持 **简体中文（zh-CN）、繁体中文（zh-TW）、English（en）、日本語（ja）、한국어（ko）**。

### 语言包结构

```
src/i18n/
├── index.ts              # i18n 入口（createI18n、自动 glob 导入）
├── i18n.type.ts          # 语言类型定义
├── zh-CN/
│   ├── index.ts          # 自动聚合当前语言所有 json 文件
│   ├── common.json       # 通用文案
│   ├── login.json        # 登录模块
│   ├── userInfo.json     # 用户信息
│   ├── enumeration.json  # 枚举映射
│   ├── errorMsg.json     # 错误信息
│   └── [模块名].json     # 业务模块文案
├── zh-TW/ ...
├── en/ ...
├── ja/ ...
└── ko/ ...
```

### 使用方式

页面中使用 `useI18n()` 获取 `t` 函数：

```vue
<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>

<template>
  <el-button>{{ t('search') }}</el-button>
</template>
```

非 Vue 上下文（如 utils、errorHandler）使用 `getT()`：

```typescript
import { getT } from '@/i18n'

const t = getT()
t('login.invalid')
```

### Key 命名规范

- 采用 **camelCase**（如 `pleaseInput`、`packUpScreenCondition`）。
- 通用词汇放在 `common.json`（如 `add`、`edit`、`delete`、`search`）。
- 模块专属文案以模块名命名 json 文件（如 `login.json`、`userInfo.json`）。
- 同一 key 在不同语言包中保持**完全一致的层级和命名**。

### 新增语言或文案

1. 在目标语言的文件夹下新建或编辑对应 json 文件。
2. 确保所有语言包同步补充同一 key（至少 zh-CN 必须包含，作为 fallback）。
3. `index.ts` 会自动通过 `import.meta.glob` 聚合，**不需要手动注册**。

> fallbackLocale 为 `zh-CN`，当目标语言缺失某个 key 时会自动回退到简体中文。

## 环境变量与网关地址

项目**不依赖 `.env` 文件**，环境判断和网关地址通过运行时逻辑动态计算。

### 环境判断

| 方式 | 说明 |
|------|------|
| `import.meta.env.DEV` | Vite 内置，开发环境为 `true` |
| `import.meta.env.PROD` | Vite 内置，生产环境为 `true` |

### 网关地址（baseURL）

`src/utils/request/baseURL.ts` 中 `getGatewayUrl()` 动态计算规则：

| 场景 | 网关地址 |
|------|---------|
| 开发环境 或 IP 为 `192.168.88.21` | `http://192.168.88.21:80`（固定） |
| 带端口访问 或 直接 IP 访问 | 当前 `protocol://host` |
| 域名访问，且匹配环境后缀（如 `-dev`、`-test`、`-prod`） | `gw{env}.{domain}`（如 `gw-dev.example.com`） |
| 域名访问，无环境后缀 | `gw.{domain}` |

支持的环境后缀：`dev`、`debg`、`test`、`beta`、`stag`、`prod`、`stab`、`dbg`、`sit`、`tst`、`uat`、`stg`、`prd`、`stb`。

### 自定义环境常量

| 常量 | 说明 |
|------|------|
| `import.meta.env.VITE_GIT_SHA` | 编译时注入当前 Git 短 SHA |

## 文件命名约定

| 类别 | 命名规则 | 示例 |
|------|----------|------|
| **页面** | 目录使用 camelCase（或 snake_case 的历史遗留），入口文件固定为 `index.vue` | `pages/uwAuthCenter/ops/log/loginLog/index.vue` |
| **编辑/新增/详情页** | `[对应页面名]Operator`，入口文件固定为 `index.vue` | `pages/saasBaseApp/saas/ais/linkerConfigOperator/index.vue` |
| **纯详情页** | `[对应页面名]Detail`，入口文件固定为 `index.vue` | `pages/saasBaseApp/saas/components/noticeDetail/index.vue` |
| **组件** | PascalCase，目录名与组件名一致，入口为 `index.vue` | `components/SearchForm/index.vue` |
| **单文件组件** | PascalCase + `.vue` | `components/Pagination.vue` |
| **Hooks** | `use` + PascalCase + `.ts` | `hooks/useCrud.ts`、`hooks/usePrompt.ts` |
| **API 模块** | `[模块名][角色]Api.ts`，camelCase（首字母小写） | `api/saasBaseAppSaasApi.ts`、`api/uwAuthCenterAuthApi.ts` |
| **API 接口** | `[角色][业务域][实体][操作]` 或 `[模块][实体][操作]`，camelCase | `saasSaasInfoUpdate`、`saasPartnerMchInfoEnable`、`authRefreshToken`、`openRegistrySave` |
| **Config** | camelCase + `.ts`，纯常量导出 | `config/appVersion.ts`、`config/common.ts` |
| **Store** | `use` + PascalCase + `Store` | `useMainStore`、`useAppMenuStore` |
| **类型文件** | `type.ts` 或 `types.ts`，与使用方同目录 | `components/SearchForm/type.ts` |
| **工具函数** | camelCase + `.ts` | `utils/tool.ts`、`utils/selectOptions.ts` |

## 目录结构规范

```
src/
├── pages/                     # 页面（按模块+角色组织）
│   └── [模块名]/[角色]/[功能域]/[页面]/index.vue
├── components/                # 组件
│   ├── business/              # 业务组件
│   └── common/                # 通用组件（Pagination 等）
├── api/                       # API 调用封装（代码生成器产出，只读不改）
├── utils/
│   ├── selectOptions.ts       # 枚举集中管理（useCommonSelectTypes）
│   └── request/               # Axios 封装
├── hooks/                     # 组合函数
│   ├── useCrud.ts             # CRUD 操作
│   ├── usePrompt.ts           # 确认弹窗（替代 ElMessageBox）
│   ├── useSimplifyPrompt.ts   # 简化确认弹窗
│   ├── useActivated.ts        # 页面缓存激活（替代 onMounted）
│   └── useExportExcel.ts      # 导出
├── config/                    # 全局配置文件
│   ├── appVersion.ts          # 应用版本信息
│   ├── common.ts              # 全局常量与变量
│   └── icon.ts                # 菜单图标配置
├── store/                     # Pinia 状态管理（Options 风格）
├── router/                    # 路由配置
├── i18n/                      # 国际化（多语言）
├── layout/                    # 布局组件
└── styles/                    # 全局样式
```

### 通用组件索引

`src/components/common/`（含根级组件）已沉淀 30+ 通用组件，部分组件自带 `use.md` 使用说明。开发时优先查看组件目录下是否有 `use.md` 文件，具体用法以文件内说明为准。常用组件包括：`SearchForm`、`Pagination`、`UploadFile`、`ECharts`、`RichTextEditor`、`PreviewImage` 等。

### 页面内组件

当页面需要拆分子组件时，在页面目录下创建 `components/` 子目录，子组件使用 PascalCase：

```
src/pages/saasBaseApp/saas/notice/saas/
├── index.vue                          # 列表页入口
└── components/
    └── NoticeListCard/index.vue       # 公告列表卡片组件
```

**命名规则**：
- 子组件目录使用 PascalCase（如 `UpdatePasswordDialog`、`MFACodeDialog`）。
- 入口文件固定为 `index.vue`。
- 仅在当前页面复用的组件不应放入 `src/components/`。

### Hooks 索引

项目已沉淀以下 hooks，开发时优先复用：

| Hook | 用途 | 使用场景 |
|------|------|---------|
| `useCrud` | CRUD 操作封装 | 列表页的增删改查 |
| `useActivated` | 页面缓存激活（替代 `onMounted`） | 所有列表页数据加载 |
| `usePrompt` | 确认弹窗（复杂配置） | 需要自定义弹窗内容 |
| `useSimplifyPrompt` | 简化确认弹窗 | 启用/禁用/删除确认 |
| `useExportExcel` | 导出 Excel | 列表页导出功能 |
| `usePermissionCode` | 生成权限码 | 按钮权限控制 |
| `usePermissionCheck` | 权限检查 | 条件渲染权限判断 |
| `useCustomDark` | 暗色模式切换 | 主题切换 |
| `useCountdown` | 倒计时 | 验证码倒计时 |
| `usePolling` | 轮询请求 | 定时刷新数据 |
| `useCalendar` | 日历逻辑 | 日历组件 |
| `usePostMessage` | 跨窗口通信 | iframe 通信 |
| `useValidate` | 表单验证辅助 | 复杂表单验证 |
| `useAreaCascader` | 地区级联选择 | 省市区选择 |
| `useSaasCurrency` | 货币处理 | 多币种场景 |
| `useCollapseItem` | 折叠面板 | 折叠展开逻辑 |
| `useIsGlobeTradeApp` | 平台判断 | 平台1.0特殊逻辑 |
| `useAbnormalMessage` | 异常消息处理 | 错误提示统一处理 |

> 各 hooks 的具体用法请参考源码注释或对应文件内的说明。

## 字段一致性原则

前端字段名与 API Schema 保持一致（camelCase）。不需要关心数据库字段名（snake_case），后端框架自动转换。

## 路由规范

> **name 属性极其重要，格式：`[模块名].[角色][功能域][页面]`（驼峰连写，如 `uwAuthCenter.opsLogLoginLog`）**

```typescript
// 列表页
{ path: '/uwAuthCenter/ops/log/loginLog', name: 'uwAuthCenter.opsLogLoginLog',
  component: () => import('@/pages/uwAuthCenter/ops/log/loginLog/index.vue'),
  meta: { title: '登录日志查询' } }

// 编辑/新增/详情页（动态路由），目录名格式为 [对应页面名]Operator
{ path: '/saasBaseApp/saas/ais/linkerConfigOperator/:type',
  name: 'saasBaseApp.saasAisLinkerConfigOperator',
  component: () => import('@/pages/saasBaseApp/saas/ais/linkerConfigOperator/index.vue'),
  meta: { title: '链接配置编辑', dynamicRoute: '/saasBaseApp/saas/ais/linkerConfigOperator', isOwnHand: true } }

// 纯详情页，目录名格式为 [对应页面名]Detail
{ path: '/saasBaseApp/saas/notice/saasNoticeDetail',
  name: 'saasBaseApp.saasNoticeSaasNoticeDetail',
  component: () => import('@/pages/saasBaseApp/saas/components/noticeDetail/index.vue'),
  meta: { title: '公告详情', isOwnHand: true } }
```

权限通过 `store/appMenu` 动态菜单控制，路由配置不需要 `meta.roles`。

### 路由 meta 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `title` | `string` | 路由标题 |
| `icon` | `string` | 路由 icon 图标 |
| `keepAlive` | `boolean` | 是否缓存页面，**列表页默认 `true`**（由 `store/main.ts` 自动设置） |
| `isOwnHand` | `boolean` | 是否手动添加页面，无需权限限制 |
| `isShowInSlideMenu` | `boolean` | 是否显示在侧边栏菜单，需配合 `isOwnHand` 使用 |
| `isHomePage` | `boolean` | 是否是首页，仅自身且 children 只有一个时去除一级展示 |
| `dynamicRoute` | `string` | 动态路由匹配路径，存在则该路由为动态路由 |
| `displayBackgroundColor` | `boolean` | 是否展示背景色，默认 `true` |
| `showMenuIcon` | `boolean` | 是否显示菜单图标 |

完整类型定义见 `src/router/typings.d.ts`。

### keepAlive 缓存规范

- **列表页默认缓存**：`store/main.ts` 在构建菜单时自动为所有路由设置 `meta.keepAlive = true`。
- **编辑/详情页不缓存**：动态路由（`Operator` / `Detail`）通常不需要缓存，编辑完成后返回列表页会自动刷新数据。
- **缓存白名单**：`store/main.ts` 的 `keepAliveInclude` getter 基于 `pageTabs` 动态计算，只有加入页签的路由才会被缓存。
- **手动控制**：如需显式关闭缓存，在路由配置中设置 `meta.keepAlive = false`。

```typescript
// 列表页（自动缓存）
{ path: '/saasBaseApp/saas/base/dict', name: 'saasBaseApp.saasBaseDict',
  component: () => import('@/pages/saasBaseApp/saas/base/dict/index.vue'),
  meta: { title: '字典管理' } }

// 编辑页（不缓存）
{ path: '/saasBaseApp/saas/ais/linkerConfigOperator/:type',
  name: 'saasBaseApp.saasAisLinkerConfigOperator',
  component: () => import('@/pages/saasBaseApp/saas/ais/linkerConfigOperator/index.vue'),
  meta: { title: '链接配置编辑', dynamicRoute: '/saasBaseApp/saas/ais/linkerConfigOperator', isOwnHand: true } }
```

### 表格操作列按钮顺序

表格「操作」列按钮按以下顺序排列，统一使用 `el-button-group` 包裹：

| 顺序 | 操作 | 按钮类型 | 图标 | 权限码 |
|------|------|---------|------|--------|
| 1 | 启用/禁用（状态切换） | `type="success"` / `type="info"` | `CircleCheck` / 自定义图标 | `enable` / `disable` |
| 2 | 编辑 | `type="primary"` | `Edit` | `update` |
| 3 | 历史日志 | `type="warning"` | `Comment` | `listDataHistory` |
| 4 | 关键日志 | `type="success"` | `DocumentChecked` | `listCritLog` |
| 5 | 删除 | `type="danger"` | `Delete` | `delete` |

> - 状态为 `-1`（已删除）的数据不展示操作按钮。
> - 启用/禁用按钮根据 `row.state` 条件渲染（`0` 展示启用，`1` 展示禁用）。
> - 删除按钮仅在 `state === 0`（未启用）时展示。

## 状态管理（Pinia）

使用 Options 风格：`state: () => ({ ... })`，Getters 为 `computed` 函数，Actions 为普通函数。

```typescript
export const useMainStore = defineStore('main', {
  state: () => {
    const loginInfo = JSON.parse(sessionStorage.getItem('ops-web-loginInfo') || '{}')
    return { loginInfo }
  },
  getters: {
    isLogin(): boolean {
      return !!this.loginInfo.token
    }
  },
  actions: {
    logout() {
      this.loginInfo = {}
      sessionStorage.removeItem('ops-web-loginInfo')
    }
  }
})
```

## 配置目录（`config/`）

`config/` 目录存放全局级配置文件，所有文件均为纯常量导出，可直接 import 使用。

### appVersion.ts

定义和展示应用程序的当前版本信息。

```typescript
import appVersion from '@/config/appVersion'

// appVersion.name     → package.json 中的 name
// appVersion.version  → package.json 中的 version
// appVersion.buildTime → 构建时间戳（毫秒）
```

### common.ts

全局常量集中定义，包含 RSA 公钥、菜单显隐控制、请求白名单、匿名 Token 等。具体变量含义和用途请直接参考文件内的注释说明。

```typescript
import { PUBLIC_KEY, HIDE_MENU, REQUEST_WHITE_LIST } from '@/config/common'
```

### icon.ts

菜单图标统一配置，**键为路由路径，值为对应图标名称**。返回值为字符串，供 `<el-icon>` 或自定义图标组件使用。

图标来源：

1. **Element Plus 图标** — 来自 `@element-plus/icons-vue`，已在 [src/main.ts](src/main.ts) 中全局注册（`app.component(key, component)`）。
2. **自定义图标** — 来自项目自建图标库，参考 [src/assets/font/demo_index.html](src/assets/font/demo_index.html) 查看可用图标名称。

```typescript
import getIcon from '@/config/icon'

const iconName = getIcon('/saasBaseApp/saas/home') // 's-home'
```

## 布局系统（`layout/`）

项目内置三种布局模式，通过 `store/main.ts` 中的 `layoutMode` 控制，取值范围为 `'default' | 'vertical' | 'slide'`。

### 布局切换机制

- **状态存储**：`mainStore.layoutMode`，持久化到 `localStorage`（key 为 `{name}-layout`）。
- **切换入口**：页面右上角的「个性化设置」抽屉（`SettingForTheme` 组件），提供三种布局的图标切换。
- **渲染入口**：`src/layout/index.vue` 通过 `v-if` 条件渲染对应的布局容器组件。

### 三种布局模式

| 模式 | 说明 | 典型使用场景 |
|------|------|-------------|
| `default`（默认布局） | 顶部横向一级模块导航 + 左侧二级侧边栏菜单 + 内容区 | 模块较多、层级较深的管理后台，顶部快速切换业务模块 |
| `vertical`（垂直布局） | 顶部紧凑标题栏 + 左侧完整垂直导航菜单（含全部层级）+ 内容区 | 模块较少、希望左侧一目了然展示全部菜单的场景 |
| `slide`（侧边栏布局） | 极简顶部标题栏（无模块导航）+ 左侧完整侧边栏菜单 + 内容区 | 极简风格、聚焦内容展示，或菜单结构扁平的场景 |

### 布局文件结构

```
src/layout/
├── index.vue                              # 布局入口（条件渲染三种布局）
├── config.module.scss                     # 布局 SCSS 变量（侧边栏宽度、顶部高度等）
├── default/
│   ├── layoutContainerByDefault.vue       # 默认布局容器
│   ├── layoutHeaderByDefault.vue          # 默认布局顶部栏（含模块导航）
│   ├── layoutAside.vue                    # 默认布局侧边栏（二级菜单）
│   └── menu/                              # 侧边栏菜单组件
├── vertical/
│   ├── layoutContainerByVertical.vue      # 垂直布局容器
│   └── layoutHeaderByVertical.vue         # 垂直布局顶部栏（紧凑标题栏）
└── slide/
    ├── layoutContainerBySlide.vue         # 侧边栏布局容器
    └── layoutHeaderBySlide.vue            # 侧边栏布局顶部栏（极简标题栏）
```

### 布局样式变量

布局尺寸统一在 `src/layout/config.module.scss` 中配置：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `$asideWidth` | `180px` | 侧边栏展开宽度 |
| `$asideCollapseWidth` | `50px` | 侧边栏收起宽度 |
| `$headerHeight` | `50px` | 顶部栏高度 |
| `$pageTabHeight` | `35px` | 页签栏高度 |

CSS 自定义属性 `--header-height` 和 `--page-tab-height` 导出给 JS 使用，用于动态计算内容区高度。

### 开发注意事项

- 页面组件**不应**直接依赖具体布局模式，所有布局差异由 `layout/` 内部封装。
- 如需获取当前布局模式进行特殊处理，通过 `useMainStore().layoutMode` 读取。
- 新增布局模式时，需在 `store/main.ts` 扩展 `layoutMode` 类型，并在 `layout/index.vue` 中增加对应的 `v-else-if` 分支。

## HTTP 请求与错误处理

请求封装位于 `src/utils/request/`，基于 Axios 统一处理拦截、Token 刷新和错误提示。

### 请求拦截器

`request.ts` 在请求发出前完成以下处理：

| 处理项 | 说明 |
|--------|------|
| **Authorization** | 有登录 Token 时设置 `Bearer` 头；无 Token 且请求在 `ANONYMOUS_TOKEN_LIST` 中，且当前用户角色为 `saas` 或 `mch` 时，设置匿名 Token |
| **水印操作时间** | 每 10 秒更新一次 `waterMarkOperatorTime` |
| **GET 参数** | 数组转为逗号分隔字符串；过滤 `[]\{}\`` 等特殊字符避免 400；`list/List` 接口中空字符串转为 `undefined` |
| **PUT/POST/PATCH** | 仅含 URL 参数且无请求体时，自动转为 `FormData` 并修改 `Content-Type` |

### 响应拦截器

`response.ts` 在数据返回页面之前完成以下处理：

| 处理项 | 说明 |
|--------|------|
| **字段兼容** | 将后端 `list` 接口返回的 `results` 字段兼容处理（过渡方案） |
| **i18n 错误码** | `code` 包含 `-` 时，使用 `t(code)` 映射国际化错误信息 |
| **load 接口兜底** | `load` 接口返回 `warn` 且无数据时，msg 自动替换为「暂无数据」 |

### 错误处理与状态码

`error.ts` 统一拦截 HTTP 错误状态码：

| 状态码 | 行为 |
|--------|------|
| `498` | Token 过期。如有 `refreshToken`，进入 **Token 刷新队列** 等待重试；否则跳转登录页 |
| `401` | 未授权。若正在刷新 Token，加入等待队列；否则展示错误弹窗并跳转登录页（MFA 验证特殊处理） |
| `409` | 账号在其他设备登录。弹窗提示后跳转登录页 |
| 其他 | `ElNotification` 统一展示错误提示（300ms 防抖避免弹窗叠加） |

### Token 刷新机制

`TokenRefresher` 采用 **Pub/Sub 模式** 管理 Token 刷新期间的请求队列：

1. Token 过期触发 498 时，失败请求被挂起加入等待队列。
2. 首次过期请求发起 `authRefreshToken` 刷新 Token。
3. 刷新成功后，`notify()` 通知队列中所有等待请求自动重试。
4. 刷新失败（如 refreshToken 也失效），`rejectAll()` 拒绝所有等待请求并跳转登录页。

```typescript
// 使用封装后的请求方法
import request from '@/utils/request'
import { type ResponseData } from '@/api/uwAuthCenterAuthApi'

request<ResponseData<void>>('/saas-base-app/saas/info/load')
  .then(res => { ... })
  .catch(err => { ... })
```

### 错误信息映射

`errorHandler.ts` 对后端返回的原始错误文本进行关键字识别，转换为对应的国际化提示：

| 关键字 | 说明 |
|--------|------|
| `!Center AccessToken expired` | Token 已失效 |
| `LOGIN_DOUBLE` | 账号在其他 IP 重复登录 |
| `LOGOUT` | 用户已登出 |
| `REFRESH` | RefreshToken 已作废 |
| `KICK_OUT` | 用户被踢出 |
| `Token header null` | 请求头缺少 Token |
| `No Permission!` | 无权限访问 |

## 性能规范

| 场景 | 规范 |
|------|------|
| 表格数据 | 分页查询，单页 ≤ 50 条 |
| 组件懒加载 | 大组件使用 `defineAsyncComponent` |
| 路由 | 懒加载 `() => import()` |
| 请求 | 并行使用 `Promise.all` |

## Git 提交规范

提交信息必须以以下关键字开头，格式为：`git commit -m '关键字: 描述'`。

| 关键字 | 说明 |
|--------|------|
| `feat` | 新功能 |
| `fix` | 修复 bug |
| `docx` | 文档变更 |
| `style` | 修改代码格式，不影响代码逻辑 |
| `refactor` | 代码重构，理论上不影响功能逻辑 |
| `perf` | 性能优化 |
| `test` | 增加测试 |
| `chore` | 构建或其他工具的变动（如 webpack、vite） |
| `revert` | 还原以前的提交 |
| `build` | 打包 |

> 示例：`git commit -m 'feat: 新增首页路由'`
