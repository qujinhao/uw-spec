# Guest Web 编码原则

> version: "1.1.0"
> 被 220-guest-web-dev、221-guest-web-dev-review、620-feature-dev、720-bugfix-dev 共同引用。
> 本文件是编码规范的**唯一权威来源**，其他文件不再重复列举规则。

## 四条核心原则

### 原则一：集中管理（Single Source of Truth）

**判断标准**：如果一个配置在多个地方可能被使用，或者属于字典/枚举/映射类数据，它应该集中管理。

| 集中到哪里 | 管什么 | 格式 |
|-----------|--------|------|
| `composables/` | 组合函数（数据获取、业务逻辑） | `useXxx()` 函数 |
| `stores/` | 全局客户端状态（购物车、用户偏好） | Pinia setup 风格 |
| `components/ui/` | Shadcn Vue 基础组件 | 按需复制，不自建 |
| `components/{domain}/` | 业务组件 | 领域划分 |
| `api/` | API 调用封装 | 代码生成器产出，只读不改 |

**具体做法**：
- 页面内**禁止**定义重复的类型接口，应从 `@/api/` 的类型中导入或从 zod schema 推断
- 相同的数据获取逻辑抽取到 `composables/useXxx.ts`，禁止多页面重复请求代码
- 状态分层：服务端状态用 Vue Query（`composables/`），客户端状态用 Pinia（`stores/`）

### 原则二：类型安全（No Escape Hatches）

**判断标准**：如果 TypeScript 编译器无法推断类型，说明代码有问题。

| 禁止 | 替代方案 |
|------|---------|
| `any` 类型 | 定义具体类型或使用 `z.infer<typeof XxxSchema>` |
| 无类型校验的 API 响应 | 使用 zod 运行时校验 `XxxSchema.parse(response)` |
| 隐式 any 参数 | 使用具体类型标注 |
| `@ts-ignore` | 修正类型定义或使用类型守卫 |
| Props 无类型定义 | 使用 `defineProps<T>()` 泛型风格 |
| API 响应未校验 | 关键 API 响应用 zod schema 校验 |

### 原则三：项目一致性（Use What Exists）

**判断标准**：在编写任何代码前，先检查项目中是否已有相同或类似功能的实现。

| 场景 | 做法 |
|------|------|
| UI 组件 | 使用 Shadcn Vue 组件（`components/ui/`），不自建基础组件 |
| 数据获取 | 使用 `useFetch` / `useAsyncData`（Nuxt 内置），禁止自行封装 axios |
| 服务端状态 | 使用 Vue Query（`useQuery`/`useMutation`），配合 `staleTime` 缓存策略 |
| 图片 | 使用 `<NuxtImg>` 组件，禁止 `<img>` 标签 |
| SEO | 使用 `useSeoMeta` / `useHead`，禁止手动操作 `<head>` |
| 国际化 | 使用 `@nuxtjs/i18n` 的 `$t()` / `localePath()`，禁止硬编码文案 |
| 路由 | 使用 Nuxt 文件路由，禁止手动配置 `router.ts` |

**Nuxt 自动导入**：Vue API（`ref`/`computed`/`watch` 等）、Nuxt composables（`useFetch`/`useHead`/`useRoute` 等）均自动导入，不需要手动 import。

### 原则四：代码可读性（Self-Documenting Code）

**判断标准**：一个新团队成员能否在不看注释的情况下理解代码意图。

| 禁止 | 替代方案 |
|------|---------|
| v-for 单字母变量 `v-for="p in"` | 描述性名称 `v-for="product in"` |
| 数组方法单字母参数 `(a, b) =>` | `(item, index) =>` |
| 硬编码魔法数字 | 提取为命名常量或配置 |
| 嵌套三元 `a ? b : c ? d : e` | computed 属性或方法 |
| 超长单文件组件 | 拆分为子组件和 composables |
| 内联复杂样式 | 使用 Tailwind CSS 类组合或提取 CSS 变量 |

## 数据结构规范

> 所有 API 响应遵循统一的包装类型，解析时必须按以下规则。

| API 类型 | 返回类型 | 取值方式 |
|---------|---------|---------|
| 列表 API | `ResponseData<DataList<T>>` | `res.data?.results` → `T[]` |
| 实体 API | `ResponseData<T>` | `res.data` → `T` |
| 无返回值 API | `ResponseData<void>` | 检查 `res.state === 'success'` |

**禁止使用**：`res.data?.list`（DataList 的字段是 `results`）

## 自动化验证

开发完成后，执行以下命令验证编码规范：

```bash
cd frontend/{project-name}-guest-web

# 1. any 类型检查（应为 0）
grep -rn ': any' src/ --include="*.vue" --include="*.ts" | grep -v 'node_modules' | wc -l

# 2. @ts-ignore 使用（应为 0）
grep -rn '@ts-ignore' src/ --include="*.vue" --include="*.ts" | wc -l

# 3. 原生 img 标签（应为 0，应使用 NuxtImg）
grep -rn '<img' src/ --include="*.vue" | wc -l

# 4. 手动导入 Nuxt 自动导入项（应为 0）
grep -rn "import.*{.*ref.*}.*from 'vue'" src/ --include="*.vue" | wc -l

# 5. zod 校验覆盖（应大于 0，关键 API 有校验）
grep -rn 'Schema.parse\|\.parse(' src/ --include="*.ts" | wc -l

# 6. DataList 字段错误（应为0，禁止用 list 用 results）
grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" | wc -l

# 7. TypeScript 编译检查
pnpm nuxi typecheck

# 8. ESLint 检查
pnpm lint
```

## 项目基础架构速查

### 目录结构
```
src/pages/                    # 文件路由页面（Nuxt 自动映射）
src/components/ui/            # Shadcn Vue 基础组件
src/components/{domain}/      # 业务组件
src/composables/              # 组合函数（数据获取 + 业务逻辑）
src/stores/                   # Pinia 全局客户端状态
src/api/                      # API 调用封装（代码生成器产出，只读不改）
src/server/api/               # Nitro 服务端 API 路由
src/layouts/                  # 页面布局
src/i18n/                     # 多语言文件
```

### 渲染模式配置
```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  routeRules: {
    '/': { prerender: true },         // SSG
    '/product/**': { isr: 60 },       // ISR
    '/search': { ssr: true },         // SSR
    '/user/**': { ssr: false },       // CSR
  }
})
```
