---
name: 220-guest-web-dev
description: 游客端Web开发（AI原生，逐页面完整交付）。当需要基于PRD进行游客端Web页面开发时触发：(1)确认页面清单与渲染模式, (2)编写架构蓝图README.md, (3)逐页面完整交付（页面+渲染模式+API对接+交互+测试+编译验证，一次写完直接通过）。当用户提及前台网站、Nuxt开发、消费者端Web时使用 ⚠️【强制】完成后必须调用 221-guest-web-dev-review，未通过前禁止声称完成。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# 游客端Web开发（AI 原生）

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Nuxt 3 | 3.x | 前端框架（SSG/ISR/SSR/CSR） |
| Vue 3 | 3.x | UI 框架（Composition API） |
| TypeScript | 5.x | 类型安全 |
| Tailwind CSS | 4.x | 样式 |
| Shadcn Vue | latest | UI 基础组件 |
| Vitest | latest | 单元测试 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 页面开发 + API对接 + 测试（一次完成） | `js-developer` |
| 协作 | 业务需求确认 | `product-manager` |

## 输入

| 输入项 | 来源路径 | 说明 |
|--------|----------|------|
| PRD | `PROJECT_ROOT/requirement/prds/*` | 产品需求文档，功能模块及页面需求 |
| API定义 | `PROJECT_ROOT/frontend/{project-name}-guest-web/src/api/` | gencode 生成的 API 调用函数和类型定义 |
| 前端项目 | `PROJECT_ROOT/frontend/{project-name}-guest-web/` | init + gencode 生成的代码 |

## 前置条件

| 前置技能 | 说明 |
|---------|------|
| [220-guest-web-init](../220-guest-web-init/SKILL.md) | 前端项目已通过 Nuxt 3 模板初始化 |
| [220-guest-web-gencode](../220-guest-web-gencode/SKILL.md) | api/pages 已由代码生成器生成 |

## 数据结构规范

| API 类型 | 返回类型 | 取值方式 |
|---------|---------|---------|
| 列表 API | `ResponseData<DataList<T>>` | `res.data?.results` → `T[]` |
| 实体 API | `ResponseData<T>` | `res.data` → `T` |
| 无返回值 API | `ResponseData<void>` | 检查 `res.state === 'success'` |

## 架构约定速查表

### 页面路径约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `pages/index.vue` 首页 | `pages/home.vue` |
| `pages/product/[id].vue` 动态路由 | `pages/product/detail.vue` 手动解析id |
| `pages/category/[slug].vue` 语义化参数 | `pages/category/[param].vue` 无意义参数名 |
| `pages/search/index.vue` 搜索页 | `pages/search.vue` 扁平结构 |

### 渲染模式选择

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 首页/活动页 → SSG（`prerender: true`） | 首页用 CSR |
| 内容详情/分类页 → ISR（`isr: 60`） | 详情页用 SSG |
| 搜索/筛选结果 → SSR（`ssr: true`） | 搜索页用 SSG |
| 用户中心/个人数据 → CSR（`ssr: false`） | 个人页用 SSR |

### 字段一致性

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 组件字段名与后端DTO字段名一致（camelCase） | 前端自定义字段名 |
| 搜索条件与后端QueryParam字段一致 | 前端自行命名搜索参数 |
| 类型从 `@/api/` 导入或 zod 推断 | 页面内重复定义类型接口 |
| API 响应用 zod schema 校验 | API 响应无运行时校验 |

### DataList 字段

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 列表数据用 `res.data?.results` | 用 `res.data?.list` |
| 分页信息用 `res.data?.total` | 自行计算分页 |
| 数据获取用 `useFetch` / `useAsyncData` | 自行封装 axios |

### SEO 配置

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 用 `useSeoMeta` / `useHead` | 手动操作 `<head>` |
| 详情页动态设置 OG 标签 | 所有页面用相同 meta |
| 列表页添加 JSON-LD 结构化数据 | 无结构化数据 |

### 状态管理

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 服务端数据 → Vue Query / useFetch（`composables/`） | 所有状态都放 Pinia |
| 客户端全局状态 → Pinia setup 风格（`stores/`） | 组件内 ref 管理全局状态 |
| 组件局部状态 → ref / reactive | composables 管理局部状态 |
| 相同数据获取逻辑抽取到 `composables/useXxx.ts` | 多页面重复请求代码 |

### 代码风格

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 组件用 `<script setup lang="ts">` | 使用 Options API |
| 图片用 `<NuxtImg>` | 用 `<img>` 标签 |
| UI 基础组件用 Shadcn Vue（`components/ui/`） | 自建基础组件 |
| v-for 用描述性名称 `v-for="product in"` | 单字母 `v-for="p in"` |
| 组件文件 PascalCase 命名 | 组件文件 camelCase 命名 |
| Props 用 `defineProps<T>()` 泛型风格 | Props 无类型定义 |
| 国际化用 `@nuxtjs/i18n` 的 `$t()` | 硬编码中文文案 |
| 路由用 Nuxt 文件路由 | 手动配置 `router.ts` |
| composables 用 `use` 前缀 | composables 无统一前缀 |

> 编码原则详见 [coding-principles.md](references/coding-principles.md)，开发规范详见 [web-dev-standards.md](references/web-dev-standards.md)

## 工作流程

### Phase 0: 需求确认

| 确认项 | 目的 | 启发式问题 |
|--------|------|-----------|
| 页面清单 + 渲染模式分类 | 决定各页面用 SSG/ISR/SSR/CSR | "根据PRD，识别到N个页面[列出]，是否有遗漏？" |
| 定制页面 | 确定开发工作量 | "除标准列表/详情/表单页面外，还有哪些定制页面？" |
| SEO 策略 | 确定搜索引擎可见性要求 | "哪些页面需要重点 SEO？是否需要 JSON-LD？" |

**渲染模式决策**：

| 页面类型 | 渲染模式 | 原因 |
|----------|---------|------|
| 首页 / 活动页 | SSG | 内容固定，CDN 缓存极致性能 |
| 内容详情 / 分类页 | ISR | 内容会变，但可缓存 |
| 搜索 / 筛选结果 | SSR | 参数动态，必须服务端渲染 |
| 用户中心 / 个人数据页 | CSR | 纯个人数据，无需 SEO |

**确认完成标准**：页面清单无遗漏、每个页面渲染模式已分类、SEO 策略已明确。

### Phase 1: 架构蓝图

**输出位置**：`PROJECT_ROOT/frontend/{project-name}-guest-web/`

**输出两个文件**：

| 文件 | 定位 | 内容 |
|------|------|------|
| `README.md` | 架构蓝图（给人+AI 读） | 页面总览、路由设计、渲染模式、PRD功能点映射、字段一致性检查、组件清单 |
| `TASKS.md` | 进度清单（仅追踪） | 按渲染模式分组、页面分类、状态复选框 |

**README.md 必须章节**：

| 章节 | 内容 | 必要性 |
|------|------|--------|
| 页面总览 | 页面清单、渲染模式、复杂度、说明 | 必须 |
| 路由设计 | 路由路径、组件、渲染模式 | 必须 |
| PRD功能点映射 | 功能点 → 页面的映射表 | 必须 |
| 字段一致性检查 | 前端字段 ↔ API Schema字段对照表 | 必须 |
| 组件清单 | 复用组件列表 | 按需 |

**模板**：参见 [design-templates.md](references/design-templates.md)

### Phase 2: 逐页面完整交付

按 TASKS.md 的分组顺序，**每组内可并行，组间串行**。每个页面执行以下步骤：

#### Step 1: 裁剪页面

> 页面由代码生成器自动生成，不新建文件，仅裁剪。

| 裁剪类型 | 操作 |
|---------|------|
| 删除不需要的页面 | 如资源不需要详情页，删除对应 `.vue` |
| 调整页面内容 | 按业务需求增删区块，适配图/文/视频前台布局 |
| 补充字段校验 | 使用 zod 添加运行时类型校验 |
| 配置渲染模式 | 在 `nuxt.config.ts` 的 `routeRules` 中设置 |

#### Step 2: 渲染模式配置

```typescript
export default defineNuxtConfig({
  routeRules: {
    '/': { prerender: true },
    '/product/**': { isr: 60 },
    '/category/**': { isr: 60 },
    '/search': { ssr: true },
    '/user/**': { ssr: false },
    '/cart': { ssr: false },
  }
})
```

#### Step 3: 字段一致性检查

| 检查项 | 要求 |
|--------|------|
| 组件字段名 | 与后端DTO字段名一致（camelCase） |
| 搜索条件 | 与后端QueryParam字段一致 |
| 显示文本 | 使用 `label` 属性显示中文，字段名保持英文 |
| 类型导入 | 从 `@/api/` 导入，不另外定义 |

#### Step 4: API 对接 + 交互完善

| 任务 | 说明 |
|------|------|
| 对接真实后端API | 将 useFetch 指向后端实际接口，替换 mock 数据 |
| 错误处理 | 添加 loading / error / empty 状态展示 |
| 表单交互 | 表单验证、提交、反馈（成功/失败提示） |
| 页面间导航 | 面包屑、分页、筛选联动、返回逻辑 |
| SEO 完善 | useSeoMeta 设置标题/描述/OG，JSON-LD 结构化数据 |

#### Step 5: 业务组件 + 状态管理

| 产出 | 位置 | 说明 |
|------|------|------|
| 业务组件 | `src/components/{domain}/` | 商品卡片、购物车抽屉、筛选栏等 |
| 组合函数 | `src/composables/` | 数据获取逻辑抽取（useProducts、useCart） |
| Pinia Store | `src/stores/` | 客户端全局状态（购物车、用户偏好） |

#### Step 6: 测试驱动开发（Red-Green 内部循环）

> **AI 原生 TDD**：内部自动执行 Red-Green 循环，用户只看到最终通过的结果。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)。

**6.1 Red 阶段**：
- 为 composable/Store 编写测试代码
- 执行 `pnpm vitest run src/composables/useXxx.spec.ts` → **确认测试失败**
- ⚠️ 如果测试意外通过 → 说明断言不够严格，需加强

**6.2 Green 阶段**：
- 编写实现代码
- 执行 `pnpm vitest run src/composables/useXxx.spec.ts` → **确认测试通过**

**6.3 Refactor 阶段**（按需）：
- 优化代码结构
- 执行 `pnpm vitest run` → 确认仍然通过

| 测试对象 | 位置 | 框架 |
|---------|------|------|
| composables | `src/**/*.spec.ts` | Vitest（与源文件同目录） |
| Store | `src/**/*.spec.ts` | Vitest |
| 工具函数 | `src/**/*.spec.ts` | Vitest |

#### Step 7: 页面验证

```bash
pnpm build && pnpm nuxi typecheck
```

| 检查项 | 命令 | 通过标准 |
|--------|------|---------|
| 编译 | `pnpm build` | 通过 |
| 类型检查 | `pnpm nuxi typecheck` | 0 错误 |
| any 类型 | `grep -rn ': any' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 行 |
| DataList 字段 | `grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 行 |
| @ts-ignore | `grep -rn '@ts-ignore' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 行 |
| 原生 img | `grep -rn '<img' src/ --include="*.vue" \| wc -l` | 0 行 |

**全部通过后**，在 TASKS.md 中标记该页面为已完成，进入下一个页面。

**代码模板**：参见 [code-templates.md](references/code-templates.md)、[dev-templates.md](references/dev-templates.md)

## 完成标准

- [ ] README.md 覆盖所有页面和渲染模式
- [ ] TASKS.md 包含所有页面的任务卡片，全部已标记完成
- [ ] 所有PRD功能点都有对应页面
- [ ] 表单字段名与API Schema字段名一致
- [ ] 列表数据使用 `res.data?.results`
- [ ] `nuxt.config.ts` 中 routeRules 渲染模式配置正确
- [ ] `pnpm build` 编译通过
- [ ] `pnpm nuxi typecheck` 0 错误
- [ ] 所有页面可正常访问展示
- [ ] 单元测试通过
- [ ] 后端可基于Swagger开始联调

## ⚠️ 完成验证（强制，全自动执行）

1. **强制调用** `221-guest-web-dev-review`
2. 不通过（< 95）→ 自动修复 → 重新评审（最多 5 轮）
3. 通过（≥ 95）→ 向用户报告最终结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [编码原则](references/coding-principles.md) - 集中管理、类型安全、项目一致性、代码可读性
- [Web开发规范](references/web-dev-standards.md) - Nuxt 3 + Vue 3 + TypeScript 开发规范
- [Web设计规范](references/web-design-spec.md) - Tailwind CSS + Radix Vue + Shadcn Vue 设计规范
- [设计模板](references/design-templates.md) - README页面清单 + TASKS.md模板
- [代码模板](references/code-templates.md) - 页面组件代码模板
- [开发模板](references/dev-templates.md) - Composable + 页面模板
- [Web端评审技能](../221-guest-web-dev-review/SKILL.md)
