# Guest UniApp 编码原则

> version: "1.1.0"
> 被 220-guest-uni-dev、221-guest-uni-dev-review、620-feature-dev、720-bugfix-dev 共同引用。
> 本文件是编码规范的**唯一权威来源**，其他文件不再重复列举规则。

## 四条核心原则

### 原则一：集中管理（Single Source of Truth）

**判断标准**：如果一个配置在多个地方可能被使用，或者属于字典/枚举/映射类数据，它应该集中管理。

| 集中到哪里 | 管什么 | 格式 |
|-----------|--------|------|
| `store/` | 全局客户端状态（用户、应用配置） | Pinia setup 风格 + `pinia-plugin-unistorage` 持久化 |
| `components/` | 通用 UI 组件 | 可复用组件 |
| `utils/` | 工具函数（auth、storage、tool、PubSub、format） | 纯函数 |
| `api/` | API 调用封装（平铺单文件 `xxxApi.ts` + 通用 `request/` + 通用 `type/`） | 代码生成器产出，只读不改 |
| `config/` | 项目枚举/常量/站点配置（**`EnumConst.ts` / `optionsConst.ts` 为 `pnpm gen:enums` 生成产物，勿手改**；业务扩展放 `EnumExtend.ts`） | 静态对象/常量 |
| `i18n/` | 多语言文案（zh-CN / zh-TW / en / ja 四语言） | JSON + 语言入口，通过 vue-i18n 使用 |
| UI 组件来源 | `@dcloudio/uni-ui`（`uni-*`）/ `uview-plus`（`u-*`、`up-*`、`u--*`） | easycom 自动注册，**禁止重复造同类组件** |

**具体做法**：
- 跨页面状态统一用 `store/`
- API 调用只通过 `api/` 层，禁止页面内直接 `uni.request`
- 通用业务逻辑（分享、登录态、数据加载等）抽到 `utils/` 或封装为通用组件，不引入 `composables/` 目录
- 类型来源**无强制约束**：可从 `@/api/*` 导入、可定义在页面/组件本地、也可放 `src/types/`，按团队习惯选择即可

### 原则二：类型安全（No Escape Hatches）

**判断标准**：如果 TypeScript 编译器无法推断类型，说明代码有问题。

| 禁止 | 替代方案 |
|------|---------|
| `any` 类型 | 定义具体类型或使用泛型 |
| 无类型 Props | 使用 `defineProps<T>()` 泛型风格 |
| 无类型 Emits | 使用 `defineEmits<T>()` 泛型风格 |
| 隐式 any 参数 | 使用具体的接口类型 |
| `@ts-ignore` | 修正类型定义 |

> **UniApp 框架限制**：`switch` 组件的 `@change` 事件回调参数类型在 UniApp 中为 `any`，此为框架限制，可保留。

### 原则三：项目一致性（Use What Exists）

**判断标准**：在编写任何代码前，先检查项目中是否已有相同或类似功能的实现。

| 场景 | 做法 |
|------|------|
| 网络请求 | 使用 `api/request/` 封装，禁止直接 `uni.request` |
| 导航跳转 | Tab 切换用 `uni.switchTab`，详情页用 `uni.navigateTo`，登录覆盖用 `uni.redirectTo` |
| 列表数据 | 新接口统一使用 `res.data?.list`；旧接口 `res.data?.results` 由开发者按需做兼容 |
| 表单校验 | 前端提交前校验，不等后端返回 |
| Toast 提示 | 使用 `uni.showToast`，统一格式 |
| 分享功能 | 微信小程序配置 `onShareAppMessage`/`onShareTimeline`，App 用 `uni.share` |
| 页面生命周期 | 页面级用 `onLoad`/`onShow`，组件级用 `onMounted`/`onUnmounted` |
| **UI 组件** | 优先使用 easycom 注册的 `uni-*` / `u-*` / `up-*`，避免重复造同类组件 |
| **自研组件复用** | 新页面前查 [src/components/](../../../src/components) 现有 `Z*` / `Gb*` / 业务组件清单，能复用即复用；新增遵循 `Z*` / `Gb*` / 业务名 三类前缀 |
| **样式优先级** | **Tailwind class（最高）** → SCSS（仅复杂场景，必 `scoped`） → 行内 `:style`（仅动态值）；颜色用 `bg-primary` 等主题 class，禁止硬编码十六进制 |
| **文案** | 业务文案走 `vue-i18n`（`$t()` / `t()`），4 种语言文件 key 同步补齐，禁止硬编码中文 |
| **Lint/格式化** | 使用 `oxlint` + `oxfmt`，禁止引入 ESLint/Prettier 工具链 |
| **登录/Token** | 登录走 `userStore.setLoginInfo()`；token 读取走 `userStore.token`；外部 token 走 `userStore.setToken()`；禁止页面自管 token / 手拼匿名 token |
| **多租户/多平台** | `saasId` 通过 `userStore.siteInfo` 与 `setSiteInfo()`；`appId` 通过 `setAppId()` 自动按平台选取，**禁止在页面硬编码** |
| **枚举与字典** | 状态判断/类型比较走 `EnumConst.ts` 中的 `enum`；下拉/筛选走 `optionsConst.ts` 中的 `XxxOptions`；字典更新流程：改 `EnumLabelMap.json` → `pnpm gen:enums` → 提交产物 → 同步 `enumeration.json`；业务扩展放 `EnumExtend.ts`；**禁止魔数 / 禁止手抄选项数组 / 禁止手改生成产物** |
| **请求错误处理** | 业务页**先判 `res.state === 'success'`** 再用 `res.data`；401/403/498 交给拦截器，禁止页面里 `if (statusCode === 401)`；Loading 用 `try/catch/finally`；错误文案走 `res.msg`（已 i18n）；中文错误新增映射统一在 `handleErrorMsg`；大数字 ID/订单号按 string 处理；APIwhiteList 仅用于无登录态接口 |
| **Loading/空状态** | 页面级遮罩用 `<GbLoading v-model>`；关键提交用 `uni.showLoading + try/finally`；列表上拉/触底用 `<uni-load-more :status>` 三态（more/loading/noMore）；空状态/失败态必备 **图片 + i18n 文案 + 重试按钮**；骨架屏与 GbLoading 二选一 |
| **平台条件编译** | 不同端 API/import/DOM 用 `#ifdef H5 / MP-WEIXIN / APP-PLUS`（编译期剔除）；单个表达式/props 用 `process.env.VUE_APP_PLATFORM` 运行时判断；`window`/`document`/`navigator` 仅 `#ifdef H5` 内；`plus.*` 仅 `#ifdef APP-PLUS` 内；SCSS 用 `/* #ifdef */`（不可用 `//`）；多平台 appId 走 `manifest.json` + `userStore.setAppId()`；跨端能力收敛到 utils/通用组件 |

### 原则四：代码可读性（Self-Documenting Code）

**判断标准**：一个新团队成员能否在不看注释的情况下理解代码意图。

| 禁止 | 替代方案 |
|------|---------|
| v-for 单字母变量 `v-for="i in"` | 描述性名称 `v-for="item in"` |
| 数组方法单字母参数 `(a, b) =>` | `(item, index) =>` |
| 硬编码魔法数字/字符串 | 提取为命名常量 |
| 嵌套三元 `a ? b : c ? d : e` | computed 属性或方法 |
| 超长单文件组件 | 拆分为子组件、抽取 utils 工具函数 |

## 数据结构规范

> 所有 API 响应遵循统一的包装类型，解析时必须按以下规则。

| API 类型 | 返回类型 | 取值方式 |
|---------|---------|---------|
| 列表 API（新接口） | `ResponseData<DataList<T>>` | `res.data?.list` → `T[]` |
| 实体 API | `ResponseData<T>` | `res.data` → `T` |
| 无返回值 API | `ResponseData<void>` | 检查 `res.state === 'success'` |

**新代码统一使用 `res.data?.list`**；历史项目中残留的 `res.data?.results` 由开发者在调用层自行兼容，规范不强制改写。

## 自动化验证

开发完成后，**首选官方 pnpm 命令**做综合检查，再辅以 grep 做硬性扫描：

```bash
# 0. 综合检查（type-check + oxlint + oxfmt --check）
pnpm check

# 单项执行：
pnpm type-check     # vue-tsc --noEmit
pnpm lint           # oxlint
pnpm lint:fix       # oxlint --fix
pnpm format:check   # oxfmt --check
pnpm format         # oxfmt --write

# 多端编译验证
pnpm build:h5
pnpm build:mp-weixin
```

辅助 grep 扫描：

```bash
# 1. any 类型检查（应为 0，框架限制的 switch 事件除外）
grep -rn ': any' src/ --include="*.vue" --include="*.ts" | grep -v 'node_modules' | grep -v '@change' | wc -l

# 2. 直接 uni.request 调用（应为 0，应使用封装的 request）
grep -rn 'uni\.request(' src/ --include="*.vue" --include="*.ts" | wc -l

# 3. 新代码列表字段（新代码不应使用 results，旧代码兼容期允许存在）
grep -rn 'res\.data\?\.results\b' src/ --include="*.vue" --include="*.ts" | wc -l

# 4. ref 双重调用（应为 0，运行时必崩）
grep -rn 'ref<.*>(.*)(.*)' src/ --include="*.vue" --include="*.ts" | wc -l

# 5. v-for 无 key（应为 0）
grep -rn 'v-for=' src/ --include="*.vue" | grep -v ':key=' | wc -l

# 6. 硬编码中文文案（业务文案应走 i18n，应为 0 或仅少量例外）
grep -rn '"[\u4e00-\u9fa5]"' src/ --include="*.vue" --include="*.ts" | wc -l

# 7. 枚举产物是否被手改（git 提交前检查；正确流程：改 JSON + pnpm gen:enums）
git diff --name-only HEAD -- src/config/EnumConst.ts src/config/optionsConst.ts src/config/EnumConstForFinance.ts src/config/optionsConstForFinance.ts
# 如有差异但 EnumLabelMap.json 未变 → 说明被手改，需回退并改走 EnumExtend.ts

# 8. 字典/枚举重新生成（字典 JSON 变更后必跑）
pnpm gen:enums

# 9. 业务页面是否漏判 res.state（应为 0；模式扫描 res.data 后紧接 .xxx 调用且文件内未出现 res.state）
grep -rn 'res\.data!\?\.' src/ --include="*.vue" --include="*.ts" | xargs -L 1 -I {} sh -c 'echo {}'
# 人工抽样审查：未在调用前判 res.state === "success" 的需修复

# 10. 业务页面是否非法处理 401/403/498（应为 0，统一由拦截器处理）
grep -rEn 'statusCode\s*===?\s*(401|403|498)' src/ --include="*.vue" --include="*.ts" | wc -l

# 11. 业务页面是否直接调用 authRefreshToken（应为 0，统一走 uni.$emit('doRefreshToken')）
grep -rn 'authRefreshToken' src/ --include="*.vue" --include="*.ts" | grep -v 'utils/requestEventHandler.ts' | wc -l

# 12. Loading 有 showLoading 但无 hideLoading 的页面（人工审查 finally 是否齐全）
grep -rln 'uni\.showLoading' src/ --include="*.vue" --include="*.ts" | xargs -L 1 sh -c 'echo "==> $1"; grep -c "uni\.hideLoading" "$1"' _

# 13. 硬编码空/失败/无更多文案（应走 i18n.common.*）
grep -rEn '"(暂无数据|加载失败|网络异常|没有更多|重试)"' src/ --include="*.vue" --include="*.ts" | wc -l

# 14. 自造全屏遮罩 loading（应统一用 GbLoading）
grep -rn 'position:\s*fixed.*z-index:\s*99' src/ --include="*.vue" --include="*.ts" | wc -l

# 15. window/document/navigator 是否在 #ifdef H5 外被引用（应为 0；命中需人工核对是否在 #ifdef H5 包裹内）
grep -rEn '(^|[^.])\b(window|document|navigator)\.' src/ --include="*.vue" --include="*.ts" | wc -l

# 16. plus.* 是否在 #ifdef APP-PLUS 外被引用（应为 0；命中需人工核对）
grep -rn 'plus\.' src/ --include="*.vue" --include="*.ts" | wc -l

# 17. SCSS 错用 // 注释式条件编译（应为 0；CSS 必须用 /* #ifdef */）
grep -rEn '//\s*#(ifdef|ifndef|endif)' src/ --include="*.scss" --include="*.vue" | wc -l

# 18. 多端编译验证（合并主线前必跑）
pnpm build:h5 && pnpm build:mp-weixin
# 项目目标 App / 其他小程序按需补：pnpm build:app-plus / pnpm build:mp-toutiao 等
```

## 项目基础架构速查

### 目录结构

**通用顶层目录（固定存在）**：

```
src/api/         # API 调用（gencode 产出，平铺单文件 xxxApi.ts）
  ├── request/   # 通用请求函数
  └── type/      # 通用类型（API_TYPE.ts）
src/components/  # 全局通用组件
src/config/      # 枚举/常量/站点配置
src/i18n/        # 多语言
src/pages/       # 主包：入口/登录/render/webView
src/packages/    # 分包根（默认）：业务分包尽量放这里
src/static/      # 静态资源
  ├── images/    # 图片
  └── font/      # 字体（iconfont）
src/store/       # Pinia 状态管理
src/styles/      # 全局样式
src/types/       # 全局类型声明
src/utils/       # 工具函数
pages.json       # 页面路由配置（subPackages 决定分包 root）
```

**业务分包**：默认放 `src/packages/{module}/`；仅当业务方不希望路由路径携带 `packages/` 前缀时，才将分包根直接挂到 `src/{module}/`，并在 [pages.json](../../../../src/pages.json) 的 `subPackages[].root` 显式注册。

### 导航模式
- **TabBar 模式**：底部固定 Tab 导航（首页/分类/发现/我的）
- **Tab 切换**：`uni.switchTab`
- **详情页**：`uni.navigateTo`（栈式导航）
- **登录覆盖**：`uni.redirectTo`
