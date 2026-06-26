# 消费者端 UniApp 开发评审检查清单

> **源技能**：[220-guest-uni-dev/SKILL.md](../../220-guest-uni-dev/SKILL.md) — AI 原生开发，逐页面完整交付。评审必须以源技能和其 references 为准。
> **编码规范权威来源**：[coding-principles.md](../../220-guest-uni-dev/references/coding-principles.md)。

## 0. 自动化验证（前置步骤，评审前必须执行）

| 检查项 | 命令 | 通过标准 | 严重程度 |
|--------|------|---------|---------|
| 综合检查 | `pnpm check` | type-check + oxlint + oxfmt --check 全部通过 | Critical |
| 类型检查 | `pnpm type-check` | 0 错误 | Critical |
| Lint | `pnpm lint` | 0 错误 | Critical |
| 格式化 | `pnpm format:check` | 0 错误 | Major |
| H5 编译 | `pnpm build:h5` | 0 错误 | Critical |
| 微信小程序编译 | `pnpm build:mp-weixin` | 0 错误 | Critical |
| 测试 | `pnpm vitest run` 或项目已有测试命令 | 0 失败 | Major |
| any 类型 | `grep -rn ': any' src/ --include="*.vue" --include="*.ts" \| grep -v 'node_modules' \| grep -v '@change' \| wc -l` | 0 | Major |
| 直接 uni.request | `grep -rn 'uni\.request(' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 | Critical |
| 新代码列表字段 | `grep -rn 'res\.data\?\.results\b' src/ --include="*.vue" --include="*.ts" \| wc -l` | 新代码 0，旧代码需标注兼容 | Critical |
| ref 双重调用 | `grep -rn 'ref<.*>(.*)(.*)' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 | Critical |
| v-for 无 key | `grep -rn 'v-for=' src/ --include="*.vue" \| grep -v ':key=' \| wc -l` | 0 | Major |
| 硬编码中文 | `grep -rn '"[\u4e00-\u9fa5]"' src/ --include="*.vue" --include="*.ts" \| wc -l` | 业务文案 0，例外需说明 | Major |
| 枚举产物手改 | `git diff --name-only HEAD -- src/config/EnumConst.ts src/config/optionsConst.ts src/config/EnumConstForFinance.ts src/config/optionsConstForFinance.ts` | JSON 未变时产物不应有 diff | Major |
| 漏判 res.state | `grep -rn 'res\.data!\?\.' src/ --include="*.vue" --include="*.ts"` | 命中项需人工确认调用前已判 `res.state === "success"` | Critical |
| 非法处理认证状态码 | `grep -rEn 'statusCode\s*===?\s*(401\|403\|498)' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 | Critical |
| 直接调用 refreshToken | `grep -rn 'authRefreshToken' src/ --include="*.vue" --include="*.ts" \| grep -v 'utils/requestEventHandler.ts' \| wc -l` | 0 | Critical |
| Loading 平衡 | `grep -rln 'uni\.showLoading' src/ --include="*.vue" --include="*.ts"` | 命中文件需人工确认 `uni.hideLoading()` 在 finally 中调用 | Major |
| 硬编码空/失败文案 | `grep -rEn '"(暂无数据\|加载失败\|网络异常\|没有更多\|重试)"' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 | Major |
| 自造全屏 Loading | `grep -rn 'position:\s*fixed.*z-index:\s*99' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 或确认为非 Loading | Major |
| H5 DOM API | `grep -rEn '(^\|[^.])\b(window\|document\|navigator)\.' src/ --include="*.vue" --include="*.ts" \| wc -l` | 命中项必须在 `#ifdef H5` 内 | Critical |
| App plus API | `grep -rn 'plus\.' src/ --include="*.vue" --include="*.ts" \| wc -l` | 命中项必须在 `#ifdef APP-PLUS` 内 | Critical |
| SCSS 条件编译 | `grep -rEn '//\s*#(ifdef\|ifndef\|endif)' src/ --include="*.scss" --include="*.vue" \| wc -l` | 0 | Major |

## 1. README.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 页面总览 | 每个页面有名称、复杂度分类、涉及 API | Phase 1 |
| TabBar 配置 | Tab 数量、图标、页面路径按 PRD 与项目固定配置记录 | Phase 1 |
| PRD 功能点映射 | 功能点 → 模块 → 页面的映射表完整 | Phase 1 |
| 路由设计 | pages.json 页面路由、主包/分包路径完整 | Phase 1 |
| 字段一致性检查表 | 表单字段 ↔ API Schema 字段对照表（camelCase） | Phase 1 |
| 平台适配策略 | 微信小程序/H5/App/目标小程序适配策略 | Phase 1 |
| 组件清单 | 复用 uni-ui/uview/自研 Z*/Gb*/业务组件的清单 | Phase 1 |

## 2. TASKS.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 并行分组 | 按业务依赖分组，组内可并行，组间串行 | Phase 1 |
| 页面分类 | 简单/复杂页面分类与 README.md 一致 | Phase 1 |
| 页面卡片 | 每个页面有文件路径、PRD来源、API列表、类型列表、功能描述、复杂度 | Phase 1 |
| 进度状态 | 所有页面已标记完成 | Phase 1 |

## 3. PRD 覆盖度（源技能 → Phase 0 + Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 页面清单 | PRD 中所有页面已识别，无遗漏 | Phase 0 |
| TabBar 确认 | TabBar 是否启用、Tab 数量与页面路径已确认 | Phase 0 |
| 平台范围 | 默认微信小程序 + H5，App/其他小程序按需求确认 | Phase 0 |
| 功能点全覆盖 | 每个 PRD 功能点在 README 映射表中有对应页面或组件 | Phase 1 |
| 核心流程 | 登录、浏览、下单/提交、支付/分享等核心流程可走通（按 PRD） | Phase 0 |

## 4. 页面组织与页面质量（源技能 → Phase 2 Step 2）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 主包职责 | `src/pages/` 仅放入口、登录、渲染容器、WebView 等公共页面 | 架构约定 |
| 业务分包 | 新业务分包默认放 `src/packages/{module}/` | 架构约定 |
| 特殊分包 | 仅业务明确不带 `packages/` 前缀时放 `src/{module}/`，且 pages.json 注册 root | 架构约定 |
| 命名沿用 | 二级目录沿用现有 camelCase，如 `productDetail`、`placeOrder` | 架构约定 |
| SFC 结构 | template → script setup lang="ts" → style scoped lang="scss" | md-dev-standards.md |
| 模板完整 | UI 结构完整，含必要条件编译平台适配代码 | Step 2 |
| 逻辑完整 | 交互逻辑 + API 调用 + 状态管理 + 分享配置（如适用） | Step 2 |
| 样式完整 | Tailwind 优先；SCSS 仅复杂场景且 scoped；安全区适配 | Step 2 + 样式规范 |
| 无空壳/TODO | 页面完整，无 TODO 标记、无空方法、无占位 mock | Step 2 |

## 5. pages.json 与 TabBar（源技能 → Phase 2 Step 3）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 主包页面 | 主包页面在 `pages` 中配置 | Step 3 |
| 分包页面 | 业务页面在对应 `subPackages[].pages` 中配置 | Step 3 |
| 分包 root | 分包 root 与实际目录一致，特殊 root 显式注册 | 架构约定 |
| 导航栏标题 | 每个页面配置 `navigationBarTitleText` | Step 3 |
| TabBar 配置 | 启用 TabBar 时 `tabBar.list` 按 PRD 配置，常见 3~5 个 | TabBar 约定 |
| Tab 页面位置 | TabBar 页面必须在主包 `pages` 中注册，不能放分包 | TabBar 约定 |
| Tab 图标 | 图标放 `static/tabbar/`，包含普通态/选中态 | TabBar 约定 |
| Tab 文案 | TabBar 文案走 i18n，由 main store `setI18n()` 设置 | TabBar 约定 |
| Tab 跳转 | Tab 页面切换使用 `uni.switchTab()` | 导航约定 |

## 6. API、字段与错误处理（源技能 → Phase 2 Step 4/7）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| API 来源 | 页面通过 `src/api/{service}Api.ts` 函数调用，禁止直接 `uni.request` | coding-principles.md |
| ResponseData | 业务页先判 `res.state === 'success'`，再使用 `res.data` | 网络请求规范 |
| DataList | 新代码列表数据使用 `res.data?.list`，旧 `results` 仅兼容保留 | 数据结构规范 |
| 分页总数 | 使用 `res.data?.total` | 数据结构规范 |
| 实体数据 | 使用 `res.data`，禁止 `res.data?.data` | 数据结构规范 |
| 表单字段 | 与后端 DTO 字段名一致（camelCase） | 字段一致性 |
| 列表字段 | 与 API 返回字段名一致 | 字段一致性 |
| 错误提示 | 业务失败使用 `res.msg`，中文错误统一在 `handleErrorMsg` + i18n key | 错误处理规范 |
| 认证状态码 | 401/403/498 交给拦截器，业务页禁止自行处理 | 错误处理规范 |
| 大数字 | ID/订单号按 string 处理，禁止 `Number()` 转换 | 错误处理规范 |
| APIwhiteList | 仅无登录态接口可加入，新增需评审依赖 | 错误处理规范 |

## 7. 登录 / Token / 多租户（源技能 → 架构约定）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 登录写入 | 登录成功调用 `userStore.setLoginInfo(res.data)` | 登录/Token规范 |
| Token 读取 | 业务读取 `userStore.token` 或 request 自动注入，禁止手拼匿名 token | 登录/Token规范 |
| 外部 token | H5 嵌入 token 用 `userStore.setToken(t)` | 登录/Token规范 |
| 退出登录 | 使用 `userStore.LogOut()`，包含后端登出 | 登录/Token规范 |
| 多租户 | `saasId` 来自 `userStore.siteInfo` / `setSiteInfo()` | 登录/Token规范 |
| 多平台 appId | 通过 `userStore.setAppId()` + manifest 维护，禁止页面硬编码 | 登录/Token规范 |
| Refresh | token 刷新走 `uni.$emit('doRefreshToken')` 与拦截器 | 登录/Token规范 |

## 8. 枚举、字典与 i18n（源技能 → coding-principles.md + md-dev-standards.md）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 状态判断 | 使用 `EnumConst.ts` 中 enum，禁止魔数 | 枚举规范 |
| 下拉/筛选 | 使用 `optionsConst.ts` 的 `XxxOptions`，禁止页面手抄数组 | 枚举规范 |
| 业务扩展 | 放 `EnumExtend.ts`，禁止手改生成产物 | 枚举规范 |
| 字典更新 | 改 `EnumLabelMap.json` → `pnpm gen:enums` → 提交产物 | 枚举规范 |
| 枚举文本 | 使用 `i18n/{lang}/enumeration.json` + `$t()` | 枚举规范 |
| 业务文案 | 统一走 `$t()` / `t()`，禁止硬编码中文 | i18n规范 |
| 语言同步 | zh-CN / zh-TW / en / ja 四语言 key 完全一致 | i18n规范 |
| Tab 文案 | TabBar 文案由 i18n 同步，不在 pages.json 固定中文 | TabBar约定 |

## 9. UI、样式、Loading 与空状态（源技能 → 架构约定）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| UI 组件优先级 | 现有 Z*/Gb*/业务组件 → uview-plus → uni-ui → 新建组件 | 组件复用约定 |
| easycom | uni-ui/uview 组件通过 easycom 使用，避免手动 import | md-dev-standards.md |
| 新组件位置 | 自研通用组件放 `src/components/{Name}/index.vue` | 组件复用约定 |
| 类型定义 | 组件 Props/事件类型放 `type.ts` 或泛型定义 | 组件复用约定 |
| Tailwind | 新写样式默认 Tailwind class，颜色用主题 class | 样式规范 |
| SCSS | 仅复杂场景使用，必须 scoped | 样式规范 |
| 行内样式 | 仅用于动态值，禁止固定样式 | 样式规范 |
| 页面级 Loading | 使用 `<GbLoading v-model>` | Loading规范 |
| 关键提交 | `uni.showLoading` + `try/finally` + `uni.hideLoading()` | Loading规范 |
| 列表分页 | 使用 `<uni-load-more :status>` 三态 | Loading规范 |
| 空/失败状态 | 图片 + i18n 文案 + 重试按钮 | Loading规范 |
| 骨架屏 | 与 GbLoading 二选一 | Loading规范 |

## 10. 多端适配与分享（源技能 → Phase 2 Step 5）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 条件编译 | 整段 DOM/API/import 使用 `#ifdef` 编译期处理 | 平台条件编译规范 |
| 运行时判断 | 仅单个表达式/props/computed 使用 `process.env.VUE_APP_PLATFORM` | 平台条件编译规范 |
| H5 API | `window` / `document` / `navigator` 仅 `#ifdef H5` 内 | 平台条件编译规范 |
| App API | `plus.*` 仅 `#ifdef APP-PLUS` 内 | 平台条件编译规范 |
| SCSS 条件编译 | CSS/SCSS 中必须用 `/* #ifdef */`，禁止 `// #ifdef` | 平台条件编译规范 |
| 微信分享 | 需要分享的页面配置 `onShareAppMessage` + `onShareTimeline` | 分享规范 |
| App 分享 | App 端使用 `uni.share()` 或 SharePopup 统一封装 | 分享规范 |
| 分享参数 | 包含 path/query、title、imageUrl（按平台要求） | 分享规范 |
| 安全区 | 顶部用 `mainStore.statusHeight`，底部用 `env(safe-area-inset-bottom)` | 样式规范 |
| 多端编译 | 至少 H5 + 微信小程序通过，目标 App/其他小程序按需通过 | 编译验证 |

## 11. 状态管理与测试质量（源技能 → Phase 2 Step 6）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| Pinia setup | `defineStore(name, () => {}, { unistorage: true })` | Pinia规范 |
| State/Getters | State 用 `ref`，Getters 用 `computed` | Pinia规范 |
| Actions | 普通函数，命名用 `setXxx` / `clearXxx` / `handleGetXxx` | Pinia规范 |
| Store 复用 | 新增 Store 前检查 user/main 是否已有字段 | Pinia规范 |
| 通用逻辑 | 抽到 `utils/` 或通用组件，不新增 `composables/` 目录 | coding-principles.md |
| 测试框架 | 使用 Vitest | Step 6 |
| Store 测试 | 覆盖状态变更、异步 action | Step 6 |
| 工具函数测试 | 覆盖纯函数输入输出和边界值 | Step 6 |
| 不测内容 | 不强制测试页面渲染、UI 样式、框架 API | Step 6 |
| 无 TODO | 测试文件无 TODO / 空断言 | Step 6 |

## 12. 安全与性能（源技能 → md-dev-standards.md）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| XSS | 禁止 `v-html` 渲染用户内容，小程序富文本使用安全组件 | 禁用规则 |
| 输入校验 | 表单提交前校验类型、长度、格式 | 多端适配规范 |
| Token 安全 | 禁止明文存储密码，禁止页面自管 token | 登录/Token规范 |
| 图片 | 使用合适 mode，启用懒加载，资源压缩 | 性能规范 |
| 列表 | 分页加载，单页 ≤ 20 条 | 性能规范 |
| 长列表 | 使用虚拟滚动或分段渲染 | 性能规范 |
| 分包体积 | 主包 ≤ 2MB，总包 ≤ 20MB（微信小程序） | 性能规范 |
| 预加载 | 合理使用 `preloadRule` | 性能规范 |
| 并行请求 | 独立请求使用 `Promise.all` | 性能规范 |
| 资源释放 | 页面卸载释放定时器、事件监听、订阅 | 性能规范 |
