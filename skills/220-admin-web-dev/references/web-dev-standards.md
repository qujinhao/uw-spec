# Web 后台管理系统开发规范（Vue3 + TypeScript + Vite + Element Plus）

> 适用于 SaaS 后台管理系统开发。被 220-admin-web-dev 和 220-admin-web-dev 引用。
> **编码规范详见 [coding-principles.md](coding-principles.md)**，本文件仅保留架构和框架层面的规范。

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue | 3.x | 前端框架（Composition API） |
| TypeScript | 5.x | 类型安全 |
| Vite | 8.x | 构建工具 |
| Element Plus | 2.x | UI 组件库 |
| Pinia | 2.x | 状态管理 |
| Vue Router | 4.x | 路由 |
| Axios | 1.x | HTTP 客户端 |

## 目录结构规范

```
src/
├── pages/                     # 页面（按角色组织）
│   └── [模块名]/[用户类型]/[功能域]/index.vue
├── components/                # 组件
│   ├── business/              # 业务组件
│   └── common/                # 通用组件（Pagination 等）
├── api/                       # API 调用封装（代码生成器产出，只读不改）
├── utils/
│   ├── selectOptions.ts       # 枚举集中管理（useCommonSelectTypes）
│   └── request.ts             # Axios 封装
├── hooks/                     # 组合函数
│   ├── useCrud.ts             # CRUD 操作
│   ├── usePrompt.ts           # 确认弹窗（替代 ElMessageBox）
│   ├── useSimplifyPrompt.ts   # 简化确认弹窗
│   ├── useActivated.ts        # 页面缓存激活（替代 onMounted）
│   └── useExportExcel.ts      # 导出
├── store/                     # Pinia 状态管理
├── router/                    # 路由配置
```

## `<script setup>` 导入顺序

```typescript
// 1. Vue 类型（需手动导入的 type）
import { type ComponentInternalInstance } from 'vue'

// 2. 组件类型
import { SearchFormType } from '@/components/SearchForm/type'

// 3. API（合并导入，type 关键字标记类型）
import {
  saasCmsCategoryList,
  type CmsCategory,
  type CmsCategoryQueryParam
} from '@/api/iknowSaasApi'
import { ResponseData, DataList } from '@/api/uwAuthCenterAuthApi'

// 4. 第三方库
import { useI18n } from 'vue-i18n'

// 5. 项目 hooks 和工具
import { useCrud } from '@/hooks/useCrud'
import { useCommonSelectTypes } from '@/utils/selectOptions'
import { ElMessage } from 'element-plus'

// 以下不需要手动导入（已配置 auto-import）：
// ref, reactive, computed, onActivated, getCurrentInstance, useRoute, useRouter...
```

## 字段一致性原则

前端字段名与 API Schema 保持一致（camelCase）。不需要关心数据库字段名（snake_case），后端框架自动转换。

## 路由规范

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

权限通过 `store/appMenu` 动态菜单控制，路由配置不需要 `meta.roles`。

## 数据结构规范

> 所有 API 响应遵循统一的包装类型，解析时必须按以下规则。

```
列表 API 返回：ResponseData<DataList<T>>
  - 列表数据：res.data?.results     → 类型 T[]（注意是 results，不是 list）
  - 分页总数：res.data?.total

实体 API 返回：ResponseData<T>
  - 实体数据：res.data              → 类型 T

无返回值 API：ResponseData<void>
  - 检查状态：res.state === 'success'
```

## 状态管理（Pinia）

使用 setup 风格：State 用 ref，Getters 用 computed，Actions 为普通函数。

## 性能规范

| 场景 | 规范 |
|------|------|
| 表格数据 | 分页查询，单页 ≤ 50 条 |
| 组件懒加载 | 大组件使用 `defineAsyncComponent` |
| 路由 | 懒加载 `() => import()` |
| 请求 | 并行使用 `Promise.all` |
