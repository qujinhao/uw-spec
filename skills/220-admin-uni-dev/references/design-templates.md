# 管理端UniApp移动端设计模板

> 包含 README.md 页面清单模板和 TASKS.md 任务卡片模板。遵循字段一致性原则。

---

## 1. README.md 页面清单模板

```markdown
# {project-name} 管理端移动端页面清单

## 页面总览

| 页面名 | 所属角色 | 模块 | 复杂度 | 涉及API | 平台 |
|--------|---------|------|--------|---------|------|
| product-list | admin | product | 简单 | adminProductList | 全平台 |
| product-detail | admin | product | 简单 | adminProductLoad | 全平台 |
| product-form | admin | product | 中等 | adminProductCreate, adminProductUpdate | 全平台 |
| order-list | mch | order | 复杂 | adminOrderList | 全平台 |
| order-detail | mch | order | 中等 | adminOrderLoad | 全平台 |
| audit-list | saas | audit | 复杂 | adminAuditList | 全平台 |

## 角色权限映射

| 角色 | product-list | product-form | order-list | order-detail | audit-list |
|------|-------------|-------------|-----------|-------------|-----------|
| SAAS | - | - | - | - | R/W |
| MCH | R | - | R/W | R/W | - |
| ADMIN | R/W | R/W | R | R | - |

R=只读（列表/详情），W=写入（新增/编辑/删除/审核）

## PRD功能点映射

| PRD功能点 | 模块 | 页面 | 路径 | 说明 |
|-----------|------|------|------|------|
| 商品管理 | product | product-list | pages/admin/product/list | 管理员查看/管理商品 |
| 商品编辑 | product | product-form | pages/admin/product/form | 新增/编辑商品 |
| 订单处理 | order | order-list | pages/mch/order/list | 商户处理订单 |
| 订单详情 | order | order-detail | pages/mch/order/detail | 查看订单详情 |
| 审核管理 | audit | audit-list | pages/saas/audit/list | SaaS管理员审核 |

## 路由设计

### pages.json 配置

```json
{
  "pages": [
    { "path": "pages/admin/product/list", "style": { "navigationBarTitleText": "商品管理", "enablePullDownRefresh": true } },
    { "path": "pages/admin/product/detail", "style": { "navigationBarTitleText": "商品详情" } },
    { "path": "pages/admin/product/form", "style": { "navigationBarTitleText": "编辑商品" } },
    { "path": "pages/mch/order/list", "style": { "navigationBarTitleText": "订单管理", "enablePullDownRefresh": true } },
    { "path": "pages/mch/order/detail", "style": { "navigationBarTitleText": "订单详情" } },
    { "path": "pages/saas/audit/list", "style": { "navigationBarTitleText": "审核管理", "enablePullDownRefresh": true } }
  ]
}
```

> **注意**：管理端不使用 TabBar，采用导航栈模式。

## 字段一致性检查

> 表单字段名必须与后端 DTO 字段名一致（camelCase）。类型从 `@/api/` 导入，不另外定义。

| 后端DTO字段 | 前端字段 | 列表项 | 说明 |
|------------|----------|--------|------|
| productName | productName | 商品名称 | 文本输入 |
| price | price | 价格 | 数字输入 |
| status | status | 状态 | 选择器 |
| createTime | createTime | 创建时间 | 只读显示 |

## 平台适配策略

| 平台 | 适配要点 |
|------|---------|
| 微信小程序 | 使用 rpx 单位，遵循微信小程序设计规范 |
| H5 | 响应式设计，适配各种屏幕 |
| App | iOS/Android 原生体验，处理安全区和刘海屏 |
```

---

## 2. TASKS.md 模板

```markdown
# 前端页面开发任务

## 页面分类

| 页面 | 分类 | 说明 |
|------|------|------|
| product-list | 简单 | 裁剪生成代码 |
| product-detail | 简单 | 裁剪生成代码 |
| product-form | 中等 | 基于生成器改造 |
| order-list | 复杂 | 基于生成器改造 |
| order-detail | 中等 | 基于生成器改造 |
| audit-list | 复杂 | 基于生成器改造 |

## 并行分组

| 组别 | 任务 | 说明 |
|------|------|------|
| 组1 | P1, P2, P3 | admin角色页面，独立 |
| 组2 | P4, P5 | mch角色页面，独立 |
| 组3 | P6 | saas角色页面，独立 |

## 进度

- [ ] P1: product-list（简单）
- [ ] P2: product-detail（简单）
- [ ] P3: product-form（中等）
- [ ] P4: order-list（复杂）
- [ ] P5: order-detail（中等）
- [ ] P6: audit-list（复杂）
```
