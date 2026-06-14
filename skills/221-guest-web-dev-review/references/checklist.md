# 游客端Web开发评审检查清单

> **源技能**：[220-guest-web-dev/SKILL.md](../../220-guest-web-dev/SKILL.md) — AI 原生开发，逐页面完整交付。

## 0. 架构蓝图完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 页面总览 | 每个页面有名称、路由、渲染模式、复杂度、说明 | Phase 1 |
| 路由设计 | 路由路径、组件、渲染模式完整列出 | Phase 1 |
| PRD 功能点映射 | 每个 PRD 功能点对应到页面 | Phase 1 |
| 字段一致性检查 | 前端字段 ↔ API Schema 字段对照表 | Phase 1 |
| 组件清单 | 复用组件列表（按需） | Phase 1 |
| TASKS.md 并行分组 | 按渲染模式分组，页面卡片含文件路径/API/类型/功能/状态 | Phase 1 |
| TASKS.md 进度 | 所有页面已标记完成 | Phase 1 |

## 1. 编译与自动化验证（前置步骤，评审前必须执行）

> 以下检查必须在维度评审之前自动化执行，未全部通过不得进入维度评审。

| # | 检查项 | 命令 | 通过标准 | 严重程度 |
|---|--------|------|---------|---------|
| 1.1 | any 类型 | `grep -rn ': any' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 行 | Critical |
| 1.2 | DataList 字段 | `grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 行 | Critical |
| 1.3 | 原生 img 标签 | `grep -rn '<img' src/ --include="*.vue" \| wc -l` | 0 行 | Major |
| 1.4 | @ts-ignore | `grep -rn '@ts-ignore' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 行 | Critical |
| 1.5 | 编译通过 | `pnpm build` | 0 错误 | Critical |
| 1.6 | 类型检查 | `pnpm nuxi typecheck` | 0 错误 | Critical |

## 2. 需求符合度（源技能 → Phase 0）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 功能覆盖 | PRD 中所有功能点都有对应页面 | Phase 0 |
| 核心流程 | 核心业务流可在项目中走通 | Phase 0 |
| 验收标准 | 每个 AC 在项目中有体现 | Phase 0 |

## 3. 渲染模式与SEO（源技能 → Phase 2 Step 2 + Step 4）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| routeRules 配置 | nuxt.config.ts 中每个页面路由已配置 SSG/ISR/SSR/CSR | Step 2 |
| SSG 页面 | 首页/活动页使用 `prerender: true` | 架构约定「渲染模式选择」 |
| ISR 页面 | 内容详情/分类页使用 `isr: 60` | 架构约定「渲染模式选择」 |
| SSR 页面 | 搜索/筛选页使用 `ssr: true` | 架构约定「渲染模式选择」 |
| CSR 页面 | 用户中心/个人数据页使用 `ssr: false` | 架构约定「渲染模式选择」 |
| useSeoMeta | 每个页面有 title/description，动态页面使用 computed | Step 4 + 架构约定「SEO 配置」 |
| OG 标签 | 详情页动态设置 ogTitle/ogDescription/ogImage | Step 4 |
| JSON-LD | 关键页面（如商品详情）有 JSON-LD Schema 注入 | Step 4 + 架构约定「SEO 配置」 |

## 4. 技术架构（源技能 → Phase 2 + 架构约定）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 文件路由 | pages/ 目录层级正确，[param] 动态路由语法规范 | 架构约定「页面路径约定」 |
| 首页路径 | 使用 `pages/index.vue`，非 `pages/home.vue` | 架构约定「页面路径约定」 |
| 动态路由参数 | 使用语义化参数名如 `[id]`/`[slug]`，非 `[param]` | 架构约定「页面路径约定」 |
| 状态分离 | 服务端数据用 Vue Query/useFetch，客户端全局状态用 Pinia | 架构约定「状态管理」 |
| Composable 抽取 | 相同数据获取逻辑抽取到 `composables/useXxx.ts` | 架构约定「状态管理」 |
| Pinia 风格 | setup 风格，State 用 ref，Getters 用 computed | 架构约定「状态管理」 |
| 国际化 | @nuxtjs/i18n 配置、localePath 使用、$t() 替代硬编码文案 | 架构约定「代码风格」 |
| NuxtImg | 使用 `<NuxtImg>` 替代原生 `<img>`，配置 format/sizes/loading | 架构约定「代码风格」+ Step 4 |
| HTTP 客户端 | 使用 ofetch/$fetch，配置拦截器和错误处理 | 架构约定「代码风格」 |
| zod 运行时校验 | 关键 API 响应使用 zod schema 校验 | 架构约定「字段一致性」 |

## 5. 类型安全与字段一致性（源技能 → Phase 2 Step 3 + 编码原则）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 禁止 any | 无 `: any` 类型注解（grep 验证） | coding-principles.md |
| 字段名一致 | 组件 props 与后端 DTO 字段名一致（camelCase） | Step 3 + 架构约定「字段一致性」 |
| 搜索条件一致 | 搜索条件与后端 QueryParam 字段一致 | Step 3 |
| 类型导入 | 从 `@/api/` 导入类型，不另外定义 | 架构约定「字段一致性」 |
| DataList 规范 | 列表数据使用 `res.data?.results`，禁止 `res.data?.list` | 架构约定「DataList 字段」 |
| 分页信息 | 使用 `res.data?.total`，不自行计算 | 架构约定「DataList 字段」 |
| 数据获取 | 使用 `useFetch`/`useAsyncData`，不自行封装 axios | 架构约定「DataList 字段」 |

## 6. TDD 实践（源技能 → Phase 2 Step 6）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 测试框架 | 使用 Vitest，测试文件与源文件同目录（*.spec.ts） | Step 6 |
| composables 测试 | 关键 composables 有对应单元测试 | Step 6 |
| Store 测试 | Pinia Store 有状态变更测试 | Step 6 |
| 工具函数测试 | 纯函数工具有完整测试覆盖 | Step 6 |
| **测试全绿** | **`pnpm test` 全部通过。AI 原生要求一次写完直接通过** | Step 6 |
| 无跳过用例 | 无 `skip`/`todo` 残留 | Step 6 |
| 关键路径覆盖 | 核心业务流（如搜索、下单）有测试验证 | Step 6 |

## 7. 用户体验与视觉设计（源技能 → Phase 2 Step 4 + 设计规范）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 首页布局 | 核心价值传达、导航清晰、CTA 明确 | [web-design-spec.md](../../220-guest-web-dev/references/web-design-spec.md) |
| 页面流转 | 核心功能路径最短、无断点 | Step 4 |
| 交互反馈 | 操作成功/失败有明确反馈（Toast、动画） | Step 4 |
| 三态展示 | loading / error / empty 状态完整展示 | Step 4 |
| 空状态 | 无数据状态有友好提示 | Step 4 |
| 响应式适配 | 移动端/平板/桌面布局正确 | [web-design-spec.md](../../220-guest-web-dev/references/web-design-spec.md) |
| 风格统一 | 全站风格统一，符合 Tailwind + Shadcn Vue 规范 | [web-design-spec.md](../../220-guest-web-dev/references/web-design-spec.md) |
| 排版规范 | 字体层级、行高、字重符合规范 | [web-design-spec.md](../../220-guest-web-dev/references/web-design-spec.md) |

## 8. 安全性（源技能 → Phase 2 + web-dev-standards.md）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| XSS 防护 | 用户输入使用 v-text 或转义处理，禁止 v-html 渲染用户内容 | web-dev-standards.md |
| CSRF 防护 | 表单提交有 CSRF token 或 SameSite Cookie 策略 | web-dev-standards.md |
| 输入校验 | 表单输入使用 zod schema 前端校验 | Step 4 |
| 敏感数据 | Token/密钥不硬编码，使用 runtime config | web-dev-standards.md |
| API 安全 | $fetch 配置 credentials 合理，无跨域风险暴露 | web-dev-standards.md |
| 依赖安全 | `pnpm audit` 无 high/critical 漏洞 | web-dev-standards.md |

## 9. 性能优化（源技能 → Phase 2 Step 4-5）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 图片格式 | NuxtImg 配置 format（webp/avif）、sizes 响应式、懒加载 | Step 4 + 架构约定「代码风格」 |
| 组件懒加载 | 大组件使用 defineAsyncComponent 或动态导入 | Step 5 |
| 按需加载 | 页面组件通过 Nuxt 文件路由自动 code splitting | 架构约定 |
| 包体积 | 无未使用的大型依赖引入 | Step 5 |

## 10. 编码规范（源技能 → 架构约定「代码风格」+ coding-principles.md）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| SFC 结构顺序 | template → script setup lang="ts" → style scoped | 架构约定「代码风格」 |
| Composition API | 使用 `<script setup lang="ts">`，禁止 Options API | 架构约定「代码风格」 |
| 组件命名 | PascalCase 命名 | 架构约定「代码风格」 |
| Props 类型 | 使用 `defineProps<T>()` 泛型风格 | 架构约定「代码风格」 |
| v-for 变量名 | 使用描述性名称，禁止单字母 | 架构约定「代码风格」 |
| UI 组件 | 基础组件使用 Shadcn Vue（components/ui/） | 架构约定「代码风格」 |
| 文件路由 | 使用 Nuxt 文件路由，禁止手动配置 router.ts | 架构约定「代码风格」 |
| Composable 前缀 | composables 使用 `use` 前缀 | 架构约定「代码风格」 |
| 导入规范 | `type` 关键字标记类型，合并导入 | coding-principles.md |

**自动化验证命令汇总**（在项目根目录执行，所有结果应为 0）：

```bash
grep -rn ': any' src/ --include="*.vue" --include="*.ts" | wc -l
grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" | wc -l
grep -rn '<img' src/ --include="*.vue" | wc -l
grep -rn '@ts-ignore' src/ --include="*.vue" --include="*.ts" | wc -l
```
