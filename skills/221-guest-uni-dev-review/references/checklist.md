# 消费者端 UniApp 开发评审检查清单

> **源技能**：[220-guest-uni-dev/SKILL.md](../../220-guest-uni-dev/SKILL.md) — AI 原生开发，逐页面完整交付。
> **编码规范权威来源**：[coding-principles.md](../../220-guest-uni-dev/references/coding-principles.md)

## 0. 自动化验证（前置步骤，评审前必须执行）

| # | 检查项 | 命令 | 通过标准 | 严重程度 |
|---|--------|------|---------|---------|
| 0.1 | any 类型 | `grep -rn ': any' src/ --include="*.vue" --include="*.ts" \| grep -v '@change' \| wc -l` | 0 行 | Critical |
| 0.2 | 直接 uni.request | `grep -rn 'uni\.request(' src/pages/ --include="*.vue" \| wc -l` | 0 行 | Critical |
| 0.3 | DataList 字段错误 | `grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 行 | Critical |
| 0.4 | ref 双重调用 | `grep -rn 'ref<.*>(.*)(.*)' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 行 | Critical |
| 0.5 | v-for 无 key | `grep -rn 'v-for=' src/pages/ --include="*.vue" \| grep -v ':key=' \| wc -l` | 0 行 | Critical |
| 0.6 | H5 编译 | `pnpm build:h5` | 通过 | Critical |
| 0.7 | 微信编译 | `pnpm build:mp-weixin` | 通过 | Critical |

## 1. README.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 页面总览 | 每个页面有名称、模块、复杂度分类、涉及API | Phase 1 |
| TabBar 配置 | 4 Tab 定义（首页/分类/发现/我的）、图标路径、页面路径 | Phase 1 |
| PRD 功能点映射 | 功能点 → 模块 → 页面的映射表 | Phase 1 |
| 路由设计 | pages.json 页面路由配置完整 | Phase 1 |
| 字段一致性检查表 | 表单字段 ↔ API Schema 字段对照表（camelCase） | Phase 1 |
| 平台适配策略 | 微信小程序/H5/App 适配方案 | Phase 1 |

## 2. TASKS.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 并行分组 | TabBar 页面为组1，认证页面为组2，内容页面为组3，特殊功能为组4，用户子页面为组5 | Phase 1 |
| 页面卡片 | 每个页面有文件路径、PRD来源、API列表、类型列表、功能描述、复杂度 | Phase 1 |
| 进度状态 | 所有页面已标记完成 | Phase 1 |

## 3. PRD 覆盖度（源技能 → Phase 0 + Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 功能点全覆盖 | 每个 PRD 功能点在 README 映射表中有对应页面 | Phase 1 |
| 页面全覆盖 | 映射表中的页面在 `src/pages/` 中有实现 | Phase 2 |
| 核心流程可走通 | 核心业务流程可在项目中走通 | Phase 0 |

## 4. 页面质量（源技能 → Phase 2 Step 2）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 模板完整 | UI 结构完整，含条件编译的平台适配代码 | Step 2 |
| 逻辑完整 | 交互逻辑 + API 调用 + 状态管理 + 分享配置（如适用） | Step 2 |
| 样式完整 | scoped 样式，rpx 单位，安全区域适配 | Step 2 |
| 页面路径 | `src/pages/{module}/{page}.vue`，无角色目录前缀 | 架构约定 |
| 页面命名 | 模块名和页面名均为 kebab-case | 架构约定 |
| **方法体完整** | **无 TODO 标记，无空壳页面。发现空壳视为 Critical** | Step 2 |

## 5. 路由配置（源技能 → Phase 2 Step 3）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| pages.json 完整 | 所有页面在 pages 数组中有配置 | Step 3 |
| TabBar 配置 | tabBar.list 包含 4 个 Tab（首页/分类/发现/我的） | Step 3 |
| TabBar 图标 | 图标在 `static/tabbar/` 目录，含选中态颜色 | 架构约定 |
| 首页路径 | 首页路径为 `pages/index/index` | 架构约定 |
| 导航栏标题 | 每个页面配置 `navigationBarTitleText` | Step 3 |
| Tab 切换 | TabBar 页面使用 `uni.switchTab()`，禁止 `uni.navigateTo()` | 架构约定 |

## 6. 字段一致性（源技能 → Phase 2 Step 4）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 表单字段名 | 与后端 DTO 字段名一致（camelCase） | Step 4 |
| 列表项名 | 与后端返回字段名一致 | Step 4 |
| DataList 规范 | 列表数据使用 `res.data?.results`，禁止 `res.data?.list` | 架构约定 |
| 实体数据 | 使用 `res.data`，禁止 `res.data?.data` | 架构约定 |
| 显示文本 | 使用 label 显示中文，字段名保持英文 | Step 4 |

## 7. 平台适配（源技能 → Phase 2 Step 5）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 条件编译 | 使用 `#ifdef MP-WEIXIN` / `#ifdef H5`，禁止运行时判断平台 | Step 5 |
| 安全区域 | 使用 `safe-area-inset-bottom`，禁止固定 padding-bottom | Step 5 |
| 布局单位 | 使用 rpx 单位，禁止 px 布局 | 架构约定 |
| 多端编译 | `pnpm build:h5` + `pnpm build:mp-weixin` 均通过 | Step 6 |

## 8. 消费者端体验（源技能 → 设计规范 + 架构约定）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 触摸交互 | 按钮点击区域≥44x44px，有点击态反馈 | [md-design-spec.md](../../220-guest-uni-dev/references/md-design-spec.md) |
| 手势操作 | 下拉刷新、上拉加载、滑动操作可用 | [md-design-spec.md](../../220-guest-uni-dev/references/md-design-spec.md) |
| 加载反馈 | 数据加载有 loading 状态 | [md-design-spec.md](../../220-guest-uni-dev/references/md-design-spec.md) |
| 空状态 | 无数据时有友好提示 | [md-design-spec.md](../../220-guest-uni-dev/references/md-design-spec.md) |
| 支付集成 | 微信支付/支付宝接入（如适用），支付结果回调处理 | PRD |
| 扫码能力 | 扫码、相机/相册调用规范（如适用） | PRD |
| 导航简洁 | TabBar 导航清晰，返回路径明确 | 架构约定 |

## 9. 分享能力（源技能 → 架构约定）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 微信分享 | 需分享页面配置 `onShareAppMessage` + `onShareTimeline` | 架构约定 |
| App 分享 | App 端使用 `uni.share()` | 架构约定 |
| 分享参数 | 包含 path + imageUrl + title，path 不能为空 | 架构约定 |
| 分享封装 | 分享逻辑统一封装到 `composables/useShare.ts` | [coding-principles.md](../../220-guest-uni-dev/references/coding-principles.md) |

## 10. 编码原则（源技能 → coding-principles.md）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| API 层隔离 | 页面禁止直接 `uni.request`，统一通过 `api/` 层 | 集中管理 |
| 类型导入 | 页面禁止重复定义类型接口，从 `@/api/` 导入 | 集中管理 |
| 状态管理 | 跨页面状态用 `store/`，数据获取逻辑抽取到 `composables/` | 集中管理 |
| 禁止 any | 除 switch 组件 `@change` 事件外无 `: any` | 类型安全 |
| 泛型 Props | 使用 `defineProps<T>()` 和 `defineEmits<T>()` | 类型安全 |
| DataList 字段 | `res.data?.results`（禁止 `res.data?.list`） | 一致性 |
| 导航方式 | Tab→switchTab、详情→navigateTo、登录→redirectTo、返回→navigateBack | 一致性 |
| v-for 变量名 | 禁止单字母，使用描述性名称 | 可读性 |
| 命名常量 | 禁止硬编码魔法数字/字符串 | 可读性 |

## 11. 安全性（源技能 → md-dev-standards.md）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| XSS 防护 | 用户输入内容渲染前转义，禁止 v-html 直接渲染用户内容 | 安全规范 |
| Token 存储 | 使用 `uni.setStorageSync`，禁止明文存储密码 | 安全规范 |
| 请求安全 | API 请求携带 Token，敏感操作有二次确认 | 安全规范 |
| 登录态校验 | 未登录跳转登录页（`uni.redirectTo`） | 安全规范 |
| 输入校验 | 表单输入有前端校验（类型、长度、格式） | 安全规范 |

## 12. 性能优化（源技能 → Phase 2 Step 5）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 图片优化 | 图片压缩、懒加载、使用 webp 格式 | Step 5 |
| 分页加载 | 列表数据分页请求，上拉加载更多 | Step 5 |
| 资源释放 | 页面销毁时释放定时器、事件监听等资源 | Step 5 |
| 组件拆分 | 超长页面拆分为子组件和 composables | [coding-principles.md](../../220-guest-uni-dev/references/coding-principles.md) |
