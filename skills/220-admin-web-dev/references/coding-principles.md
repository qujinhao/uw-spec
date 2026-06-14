# Admin Web 编码原则

> version: "1.1.0"
> 被 220-admin-web-dev、221-admin-web-dev-review、620-feature-dev、720-bugfix-dev 共同引用。
> 本文件是编码规范的**唯一权威来源**，其他文件不再重复列举规则。

## 四条核心原则

### 原则一：集中管理（Single Source of Truth）

**判断标准**：如果一个配置在多个地方可能被使用，或者属于字典/枚举/映射类数据，它应该集中管理。

| 集中到哪里 | 管什么 | 格式 |
|-----------|--------|------|
| `src/utils/selectOptions.ts` → `useCommonSelectTypes()` | 所有下拉选项、状态映射、标签类型映射 | `computed<commonType[]>(() => [...])` |
| `src/components/` | 可复用 UI 组件 | 已有组件优先使用 |
| `src/hooks/` | 可复用逻辑 | `useXxx()` hooks |
| `src/api/` | API 调用 | 代码生成器产出 |

**具体做法**：
- 页面内**禁止**定义 `const xxxOptions = [...]`、`const xxxTagType = {...}`、`const xxxText = {...}` 等枚举配置
- 新增枚举时，在 `useCommonSelectTypes()` 中添加 `computed` 包装的选项和可选的标签类型映射
- 标签显示文本统一使用 `handleTypeForLabel(value, xxxTypes.value, fallback)` 获取，禁止自定义 `xxxText` 映射

### 原则二：类型安全（No Escape Hatches）

**判断标准**：如果 TypeScript 编译器无法推断类型，说明代码有问题。

| 禁止 | 替代方案 |
|------|---------|
| `as any`（除 `proxy as any`） | 定义正确的类型或扩展 interface |
| `.then(res =>` 无类型 | `.then((res: ResponseData<Xxx>) =>` |
| `: any` 参数或变量 | 使用具体的接口类型 |
| `ref<any>(...)` | `ref<XxxType>(...)` |
| 隐式 string/number 混用 | 对照 API interface 确认类型后统一使用 |
| 混合导入值和类型 | `import { type Xxx, fn } from '...'` |

### 原则三：项目一致性（Use What Exists）

**判断标准**：在编写任何代码前，先检查项目中是否已有相同或类似功能的实现。

| 场景 | 做法 |
|------|------|
| 分页 | 使用 `Pagination` 组件，禁止 `el-pagination` |
| 启用/禁用确认 | 使用 `useSimplifyPrompt`，禁止直接 `ElMessageBox` |
| 列表页数据加载 | 使用 `useActivated`，禁止 `onMounted` |
| CRUD 操作 | 使用 `useCrud` hooks |
| 表单验证 | 内联写法 `:rules="[{ required: true, message: '...' }]"` |
| 导入 Vue API | 不手动导入 `ref`/`computed`/`onMounted` 等（已配置 auto-import） |
| 同一模块多次导入 | 合并为单个 `import` 语句 |

**已配置自动导入**：`vue`、`vue-router`、`@vueuse/core`。这些包的 API 不需要手动 import。
**需要手动导入**：`vue-i18n`（`useI18n`）、`element-plus`（`ElMessage`）、`@/hooks/*`、`@/utils/*`、Vue 类型（`type ComponentInternalInstance`）。

### 原则四：代码可读性（Self-Documenting Code）

**判断标准**：一个新团队成员能否在不看注释的情况下理解代码意图。

| 禁止 | 替代方案 |
|------|---------|
| v-for 单字母变量 `v-for="s in"` | 描述性名称 `v-for="sourceItem in"` |
| 数组方法单字母参数 `(a, b) =>` | `(item, index) =>` |
| 内联样式 `style="..."` | CSS 类 |
| 硬编码多个 `el-option` | `v-for` + selectOptions 动态渲染 |
| 嵌套三元 `a ? b : c ? d : e` | computed 属性或方法 |
| 表单控件无 placeholder | 所有 `el-input`/`el-select`/`el-input-number` 必须有 placeholder |
| 弹窗按钮顺序不一致 | 取消在左（icon="Close"），保存在右（icon="Check"） |

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
cd frontend/{project-name}-admin-web

# 1. 页面内枚举定义（应为0）
grep -rn 'const.*Options\s*=\s*\[' src/pages/ --include="*.vue" | wc -l

# 2. 内联样式（应为0，排除 header-cell-style）
grep -rn 'style="' src/pages/ --include="*.vue" | grep -v 'header-cell-style' | wc -l

# 3. any 类型（应仅含 proxy as any）
grep -rn ': any' src/pages/ --include="*.vue" | grep -v 'proxy as any' | wc -l

# 4. ElMessageBox 直接调用（应为0）
grep -rn 'ElMessageBox' src/pages/ --include="*.vue" | wc -l

# 5. res 未声明类型（应为0）
grep -rn '\.then(.*res =>' src/pages/ --include="*.vue" | wc -l

# 6. 本地 TagType/Text 映射（应为0）
grep -rn 'type ElTagType\|const.*TagType.*Record' src/pages/ --include="*.vue" | wc -l

# 7. onMounted 在列表页（应为0）
grep -rn 'onMounted' src/pages/ --include="*.vue" | wc -l

# 8. 手动导入 vue 自动导入项（应为0）
grep -rn "import.*{.*ref.*}.*from 'vue'" src/pages/ --include="*.vue" | wc -l

# 9. DataList 字段错误（应为0，禁止用 list 用 results）
grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" | wc -l

# 10. TypeScript 编译检查
pnpm vue-tsc --noEmit

# 11. ESLint 检查
pnpm lint
```

## 项目基础架构速查

### 目录结构
```
src/pages/[模块名]/[用户类型]/[功能域]/index.vue        # 列表页
src/pages/[模块名]/[用户类型]/[功能域+Operator]/index.vue # 编辑页（驼峰）
src/utils/selectOptions.ts                              # 枚举集中管理
src/hooks/                                              # 逻辑复用
src/components/                                         # UI 复用
```

### 路由规范
```typescript
// 列表页
{ path: '/iknow/saas/cms/article', name: 'iknow.saasCmsArticle',
  component: () => import('@/pages/iknow/saas/cms/article/index.vue'),
  meta: { title: '文章管理' } }

// 编辑/详情页（动态路由）
{ path: '/iknow/saas/cms/articleOperator/:type', name: 'iknow.saasCmsArticleOperator',
  component: () => import('@/pages/iknow/saas/cms/articleOperator/index.vue'),
  meta: { title: '文章编辑', dynamicRoute: '/iknow/saas/cms/articleOperator', isOwnHand: true } }
```
