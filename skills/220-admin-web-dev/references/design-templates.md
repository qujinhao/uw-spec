# Web 端设计模板

> 包含 README.md 页面清单模板和 TASKS.md 任务卡片模板。遵循字段一致性原则。

---

## 1. README.md 页面清单模板

```markdown
# {project-name} Web端页面清单

## 页面总览

| 页面名 | 所属角色 | 模块 | 复杂度 | 代码策略 | 涉及API |
|--------|---------|------|--------|---------|---------|
| ArticleList | saas | cms | 简单 | 裁剪生成代码 | saasCmsArticleList |
| ArticleSave | saas | cms | 简单 | 裁剪生成代码 | saasCmsArticleLoad, saasCmsArticleSave |
| OrderList | mch | order | 复杂 | 基于生成器改造 | mchOrderList |
| Dashboard | admin | system | 简单 | 裁剪生成代码 | adminDashboard |

## 角色权限映射

| 角色 | ArticleList | ArticleSave | OrderList | Dashboard |
|------|-------------|-------------|-----------|-----------|
| SAAS | R/W | R/W | - | - |
| MCH | R | - | R/W | - |
| ADMIN | R | - | R | R/W |

R=只读（列表/详情），W=写入（新增/编辑/删除）

## PRD功能点映射

| PRD功能点 | 模块 | 页面 | 路由 | 说明 |
|-----------|------|------|------|------|
| 文章管理 | cms | ArticleList | /iknow/saas/cms/article | SaaS管理文章列表 |
| 文章编辑 | cms | ArticleSave | /iknow/saas/cms/articleOperator/:type | 新增/编辑文章 |
| 订单处理 | order | OrderList | /iknow/mch/order | 商户处理订单 |
| 数据概览 | system | Dashboard | /iknow/admin/dashboard | 管理员数据看板 |

## 路由设计

### 路由层级

```
/{project-name}/{role}/{module}/{page}
```

### 路由配置

| 路由路径 | 组件 | 说明 |
|----------|------|------|
| /iknow/saas/cms/article | pages/iknow/saas/cms/article/index.vue | 文章列表 |
| /iknow/saas/cms/articleOperator/:type | pages/iknow/saas/cms/articleOperator/index.vue | 文章编辑（动态路由） |
| /iknow/mch/order | pages/iknow/mch/order/index.vue | 订单列表 |

> 权限通过 `store/appMenu` 动态菜单控制，路由 meta 不需要 roles 字段。

## 字段一致性检查

> 前端只关心 API Schema 字段名（camelCase），不需要关心数据库 snake_case 字段名。
> 类型从 `@/api/` 导入，不另外定义。

### Article 模块

| API Schema字段 | 前端表单字段 | 表格列 | 说明 |
|---------|--------------|--------|------|
| articleTitle | articleTitle | 文章标题 | 文本输入 |
| articleState | articleState | 文章状态 | 选择器（number） |
| categoryId | categoryId | 分类 | 选择器 |
| createTime | - | 创建时间 | 只读显示 |

### Order 模块

| API Schema字段 | 前端表单字段 | 表格列 | 说明 |
|---------|--------------|--------|------|
| orderNo | orderNo | 订单号 | 文本显示 |
| totalAmount | totalAmount | 总金额 | 金额显示 |
| orderStatus | orderStatus | 订单状态 | 状态标签（number） |

## 组件清单

### 通用组件

| 组件名 | 路径 | 用途 |
|--------|------|------|
| DataTable | components/DataTable.vue | 通用表格（分页/排序/筛选） |
| SearchForm | components/SearchForm.vue | 通用搜索表单 |
| StatusTag | components/StatusTag.vue | 状态标签 |

### 业务组件

| 组件名 | 路径 | 用途 |
|--------|------|------|
| ArticleCard | components/business/ArticleCard.vue | 文章卡片 |
| OrderItem | components/business/OrderItem.vue | 订单项展示 |
```

> **降级策略**：如果 220-init 未生成 SearchForm/DataTable/StatusTag 通用组件，列表页模板中可直接使用 Element Plus 原生组件（`<el-form>` + `<el-table>` + `<el-tag>`）替代。

---

## 2. TASKS.md 模板

```markdown
# 前端页面开发任务

## 页面分类

| 页面 | 分类 | 说明 |
|------|------|------|
| ArticleList | 简单 | 裁剪生成代码 |
| ArticleSave | 简单 | 裁剪生成代码 |
| OrderList | 复杂 | 基于生成器改造 |
| Dashboard | 简单 | 裁剪生成代码 |

## 并行分组

| 组别 | 任务 | 说明 |
|------|------|------|
| 组1 | P1, P2 | saas角色页面，独立 |
| 组2 | P3 | mch角色页面，独立 |
| 组3 | P4 | admin角色页面，独立 |

## 进度

- [ ] P1: ArticleList（简单）
- [ ] P2: ArticleSave（简单）
- [ ] P3: OrderList（复杂）
- [ ] P4: Dashboard（简单）
```
