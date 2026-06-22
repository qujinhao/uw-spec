# 页面类型判断规则

> 根据 PRD 描述自动判断页面类型、复杂度、目录命名。被 220-admin-web-dev 引用。

## 页面类型映射

### 关键词 → 页面类型

| PRD 关键词 | 页面类型 | 目录命名 | 路由后缀 | 说明 |
|-----------|---------|---------|---------|------|
| 管理、列表、查询、一览、目录、清单 | 列表页 | `{feature}` | 无 | 标准 CRUD 列表，含搜索+表格+分页 |
| 新增、创建、添加、录入 | 表单页 | `{feature}Operator` | `/:type` | 与编辑共用 Operator 页面，type=add |
| 编辑、修改、更新、变更 | 表单页 | `{feature}Operator` | `/:type` | 与新增共用 Operator 页面，type=edit |
| 查看、详情、明细、查看详情 | 详情页 | `{feature}Detail` | 无 | 纯展示，只读 |
| Dashboard、看板、数据概览、首页 | 看板页 | `{feature}` | 无 | 自定义布局，通常无标准 CRUD |
| 配置、设置、参数 | 配置页 | `{feature}` | 无 | 可能是表单或列表，视 PRD 而定 |

### 复合页面判断

当 PRD 中一个功能模块包含多种操作时，拆分为多个页面：

```
PRD: "文章管理（含新增、编辑、查看详情）"
  → ArticleList（列表页）
  → ArticleOperator（表单页，type=add/edit）
  → ArticleDetail（详情页，如需要独立详情）

PRD: "订单管理（含查询、导出、批量发货）"
  → OrderList（列表页，含导出按钮）
  → OrderOperator（表单页，如需要编辑）
```

## 复杂度判断

### 简单页面

满足以下全部条件：
- 仅标准 CRUD（列表 / 新增 / 编辑 / 删除）
- 无特殊交互（导入、导出不算特殊）
- 单表操作，无关联查询
- 表单字段 ≤ 15 个
- 列表列 ≤ 12 列

**代码策略**：基于代码生成器产出裁剪

### 复杂页面

满足以下任一条件：
- 含树形结构、级联选择、关联表弹窗
- 多 Tab 切换、步骤条表单
- 自定义布局（非标准 flex_col）
- 含复杂图表（ECharts 定制化）
- 表单字段 > 15 个或列表列 > 12 列
- 需要自定义 hooks 或业务组件

**代码策略**：基于模板新建，按需引用生成器代码

## 目录命名规则

### 页面目录

```
src/pages/{projectName}/{role}/{module}/{feature}/index.vue              # 列表页
src/pages/{projectName}/{role}/{module}/{feature}Operator/index.vue      # 表单页
src/pages/{projectName}/{role}/{module}/{feature}Detail/index.vue        # 详情页
```

### 命名转换

| 来源 | 规则 | 示例 |
|------|------|------|
| PRD 功能名 | 去掉"管理"、"查询"等后缀，取核心名词 | 文章管理 → article |
| 模块名 | PRD 中的模块或从 API 文件名推断 | cms → cms |
| 角色 | PRD 中明确标注或从路由前缀推断 | saas → saas |
| 路由 path | kebab-case(功能名) | articleCategory → article-category |
| 路由 name | projectName + role + module + PascalCase(feature) | iknow.saasCmsArticleCategory |

### 示例

```
PRD: "SaaS 管理员管理文章分类"
  → role: saas
  → module: cms
  → feature: articleCategory
  → 列表页目录: src/pages/iknow/saas/cms/articleCategory/index.vue
  → 表单页目录: src/pages/iknow/saas/cms/articleCategoryOperator/index.vue
  → 路由 path: /iknow/saas/cms/articleCategory
  → 路由 name: iknow.saasCmsArticleCategory
```

## 操作按钮映射

根据 PRD 描述的操作，确定页面需要哪些按钮：

| PRD 描述 | 页面类型 | 按钮 | 权限码 |
|---------|---------|------|--------|
| 可新增 | 列表页 | 新增（Plus） | save |
| 可编辑 | 列表页 | 编辑（Edit） | update |
| 可删除 | 列表页 | 删除（Delete） | delete |
| 可启用/禁用 | 列表页 | 启用/禁用（CircleCheck） | enable/disable |
| 可导出 | 列表页 | 导出（Download） | export |
| 可导入 | 列表页 | 导入（Upload） | import |
| 查看详情 | 列表页 | 详情（View） | query/detail |
| 查看历史 | 列表页 | 历史（Comment） | listDataHistory |
| 查看日志 | 列表页 | 日志（DocumentChecked） | listCritLog |

> 列表页按钮统一放在 `SearchForm` 的 `#right` 插槽和操作列中。
> 表单页按钮统一放在底部：`取消（Close）` + `保存（Check）`。
