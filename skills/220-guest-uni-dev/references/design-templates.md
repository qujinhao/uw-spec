# 消费者端UniApp移动端设计模板

> 包含 README.md 页面清单模板和 TASKS.md 任务卡片模板。遵循字段一致性原则。

---

## 1. README.md 页面清单模板

````markdown
# {project-name} 消费者端移动端页面清单

## 页面总览

| 页面名   | 文件路径              | 复杂度 | 涉及API                    | 平台   |
| -------- | --------------------- | ------ | -------------------------- | ------ |
| 首页     | pages/index/index     | 高     | guestXxxList, guestYyyList | 全平台 |
| 分类     | pages/category/index  | 中等   | guestCategoryList          | 全平台 |
| 发现     | pages/discovery/index | 中等   | guestXxxList               | 全平台 |
| 我的     | pages/user/index      | 简单   | guestInfoLoad              | 全平台 |
| 内容详情 | pages/article/detail  | 中等   | guestXxxLoad               | 全平台 |
| 搜索结果 | pages/search/index    | 中等   | guestXxxList               | 全平台 |
| 个人资料 | pages/user/profile    | 简单   | guestInfoUpdate            | 全平台 |

## TabBar 配置（按需，启用时填写；未启用可省略本章节）

| Tab  | 页面路径         | 图标 | 说明                      |
| ---- | ---------------- | ---- | ------------------------- |
| 首页 | pages/home/index | home | 由业务定义                |
| ...  | ...              | ...  | Tab 数量与图标按 PRD 决定 |

## PRD功能点映射

| PRD功能点 | 模块     | 页面路径             | 说明                   |
| --------- | -------- | -------------------- | ---------------------- |
| 首页推荐  | index    | pages/index/index    | Banner轮播、推荐内容流 |
| 分类浏览  | category | pages/category/index | 分类网格、筛选器       |
| 内容详情  | article  | pages/article/detail | 内容展示、互动操作     |
| 搜索      | search   | pages/search/index   | 关键词搜索、结果列表   |
| 个人中心  | user     | pages/user/index     | 用户信息、功能入口     |

## 路由设计

### pages.json 配置（示例：主包 + packages 分包）

> 业务分包默认放 `src/packages/`，特殊情况按需调整 `subPackages[].root`。

```json
{
  "pages": [
    { "path": "pages/home/index", "style": { "navigationBarTitleText": "首页" } },
    { "path": "pages/login/index", "style": { "navigationBarTitleText": "登录" } }
  ],
  "subPackages": [
    {
      "root": "packages",
      "pages": [
        { "path": "setting/userInfo", "style": { "navigationBarTitleText": "用户资料" } },
        { "path": "coupon/center", "style": { "navigationBarTitleText": "领券中心" } }
      ]
    }
  ]
  // 如业务需要 TabBar，再补充 "tabBar": { ... }；当前项目未启用
}
```
````

## 字段一致性检查

> 表单字段名必须与后端 DTO 字段名一致（camelCase）。类型来源无强制约束，按团队约定即可。

| 后端DTO字段 | 前端字段   | 说明      |
| ----------- | ---------- | --------- |
| title       | title      | 标题      |
| coverImage  | coverImage | 封面图URL |
| summary     | summary    | 摘要      |
| viewCount   | viewCount  | 浏览量    |
| likeCount   | likeCount  | 点赞数    |

## 平台适配策略

| 平台       | 适配要点                                              |
| ---------- | ----------------------------------------------------- |
| 微信小程序 | 使用 rpx 单位，支持 onShareAppMessage/onShareTimeline |
| H5         | 响应式设计，适配各种屏幕                              |
| App        | iOS/Android 原生体验，处理安全区和刘海屏              |

## 国际化（i18n）

| 项目     | 说明                                                                                           |
| -------- | ---------------------------------------------------------------------------------------------- |
| 支持语言 | zh-CN / zh-TW / en / ja（4 种）                                                                |
| 使用方式 | 模板 `$t('key')`、`<script setup>` 中 `useI18n().t('key')`                                     |
| 文件分布 | `src/i18n/{lang}/*.json`（common / login / errorMsg / pageTitle / userInfo / enumeration ...） |
| 新增 key | 4 种语言文件**必须同步**新增同名 key                                                           |

## UI 组件选型

| 来源               | 前缀                    | 使用场景                                       |
| ------------------ | ----------------------- | ---------------------------------------------- |
| `@dcloudio/uni-ui` | `uni-*`                 | 官方基础组件（form、list、popup、calendar 等） |
| `uview-plus`       | `u-*` / `up-*` / `u--*` | 复杂业务组件（按钮、上传、tabs、grid 等）      |
| `mall-widgets`     | `m-*`                   | 业务装修组件（仅装修体系项目）                 |

````

---

## 2. TASKS.md 模板

```markdown
# 前端页面开发任务

## 页面分类

| 页面 | 分类 | 说明 |
|------|------|------|
| 首页 | 高 | TabBar，Banner+内容流 |
| 分类 | 中等 | TabBar，分类网格+筛选 |
| 发现 | 中等 | TabBar，社区内容+推荐 |
| 我的 | 简单 | TabBar，个人中心 |
| 内容详情 | 中等 | 详情展示+互动 |
| 搜索结果 | 中等 | 搜索+结果列表 |
| 个人资料 | 简单 | 表单编辑 |

## 并行分组

| 组别 | 任务 | 说明 |
|------|------|------|
| 组1 | P1, P2, P3, P4 | TabBar 页面，独立 |
| 组2 | P5, P6, P7 | 非 Tab 页面，独立 |

## 进度

- [ ] P1: 首页（高）
- [ ] P2: 分类（中等）
- [ ] P3: 发现（中等）
- [ ] P4: 我的（简单）
- [ ] P5: 内容详情（中等）
- [ ] P6: 搜索结果（中等）
- [ ] P7: 个人资料（简单）
````
