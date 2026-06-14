# 游客端Web设计模板

> 包含 README.md 页面清单模板和 TASKS.md 任务卡片模板。遵循字段一致性原则。

---

## 1. README.md 页面清单模板

```markdown
# {project-name} 游客端Web页面清单

## 页面总览

| 页面名 | 路由 | 渲染模式 | 复杂度 | 说明 |
|--------|------|---------|--------|------|
| Home | `/` | SSG | 中等 | 首页，Banner + 分类入口 + 推荐商品 |
| Category | `/category/:id` | ISR | 中等 | 分类商品列表，筛选排序 |
| ProductDetail | `/product/:slug` | ISR | 高 | 商品详情，SKU选择，评价 |
| Search | `/search` | SSR | 中等 | 搜索结果页，筛选排序 |
| Cart | `/cart` | CSR | 中等 | 购物车，数量调整 |
| Checkout | `/checkout` | CSR | 高 | 结算页，地址 + 支付 |
| UserProfile | `/user/profile` | CSR | 简单 | 个人资料 |
| UserOrders | `/user/orders` | CSR | 中等 | 订单列表 |
| UserOrderDetail | `/user/orders/:id` | CSR | 中等 | 订单详情 |

## 路由设计

| 路由路径 | 组件 | 渲染模式 | 说明 |
|----------|------|---------|------|
| `/` | `index.vue` | SSG | 首页 |
| `/category/:id` | `category/[id].vue` | ISR | 分类页 |
| `/product/:slug` | `product/[slug].vue` | ISR | 商品详情 |
| `/search` | `search.vue` | SSR | 搜索 |
| `/cart` | `cart.vue` | CSR | 购物车 |
| `/checkout` | `checkout.vue` | CSR | 结算（需登录） |
| `/user/profile` | `user/profile.vue` | CSR | 个人中心（需登录） |
| `/user/orders` | `user/orders.vue` | CSR | 订单列表（需登录） |

## PRD功能点映射

| PRD功能点 | 页面 | 路由 | 说明 |
|-----------|------|------|------|
| 首页展示 | Home | `/` | Banner轮播、分类入口、热销推荐 |
| 分类浏览 | Category | `/category/:id` | 分类商品网格、筛选器 |
| 商品详情 | ProductDetail | `/product/:slug` | 图片画廊、SKU选择、加入购物车 |
| 搜索商品 | Search | `/search` | 关键词搜索、筛选排序 |
| 购物车 | Cart | `/cart` | 商品列表、数量修改、结算入口 |
| 结算支付 | Checkout | `/checkout` | 收货地址、配送方式、支付 |
| 订单管理 | UserOrders | `/user/orders` | 订单列表、物流跟踪 |

## 字段一致性检查

> 前端只关心后端 DTO 字段名（camelCase），不需要关心数据库字段名。
> 类型从 `@/api/` 导入，不另外定义。

### Product 模块

| 后端DTO字段 | 前端组件字段 | 说明 |
|-------------|--------------|------|
| name | product.name | 商品名称 |
| slug | product.slug | URL 友好标识 |
| price | product.price | 当前售价 |
| originalPrice | product.originalPrice | 原价（划线） |
| mainImage | product.mainImage | 主图 URL |
| images | product.images | 图片数组 |
| stock | selectedVariant.stock | 库存数量 |
| skus | product.skus | SKU 列表（颜色/尺寸） |
| rating | product.rating | 评分 |
| reviewCount | product.reviewCount | 评价数 |

### Cart 模块

| 后端DTO字段 | 前端字段 | 说明 |
|-------------|----------|------|
| id | item.id | 购物车项ID |
| productId | item.productId | 商品ID |
| skuId | item.skuId | SKU ID |
| quantity | item.quantity | 数量 |
| unitPrice | item.unitPrice | 单价 |

## 组件清单

### 通用组件

| 组件名 | 路径 | 用途 |
|--------|------|------|
| AppHeader | `components/layout/AppHeader.vue` | 顶部导航（Logo + 搜索 + 购物车） |
| AppFooter | `components/layout/AppFooter.vue` | 页脚（链接 + 订阅） |
| ProductCard | `components/product/ProductCard.vue` | 商品卡片 |
| ProductGrid | `components/product/ProductGrid.vue` | 商品网格列表 |
| QuantitySelector | `components/ui/QuantitySelector.vue` | 数量加减器 |
| PriceDisplay | `components/ui/PriceDisplay.vue` | 价格展示（现价+原价+折扣） |

### 页面级组件

| 组件名 | 路径 | 用途 |
|--------|------|------|
| HeroBanner | `components/home/HeroBanner.vue` | 首页轮播 Banner |
| CategoryNav | `components/home/CategoryNav.vue` | 分类快捷入口 |
| ProductGallery | `components/product/ProductGallery.vue` | 商品详情图片画廊 |
| SkuSelector | `components/product/SkuSelector.vue` | SKU 选择器（颜色/尺寸） |
| ReviewList | `components/product/ReviewList.vue` | 商品评价列表 |
| CartDrawer | `components/cart/CartDrawer.vue` | 购物车抽屉 |
| FilterSidebar | `components/category/FilterSidebar.vue` | 筛选侧边栏 |
```

---

## 2. TASKS.md 模板

```markdown
# 前端页面开发任务

## 页面分类

| 页面 | 分类 | 说明 |
|------|------|------|
| Home | 中等 | SSG，Banner+分类入口+推荐 |
| Category | 中等 | ISR，分类商品列表 |
| ProductDetail | 高 | ISR，SKU选择+评价 |
| Search | 中等 | SSR，搜索结果 |
| Cart | 中等 | CSR，购物车 |
| Checkout | 高 | CSR，结算+支付 |
| UserProfile | 简单 | CSR，个人资料 |

## 并行分组

| 组别 | 任务 | 说明 |
|------|------|------|
| 组1 | P1, P2, P3 | SSG/ISR 页面，独立 |
| 组2 | P4 | SSR 页面，独立 |
| 组3 | P5, P6, P7 | CSR 页面，独立 |

## 进度

- [ ] P1: Home（中等）
- [ ] P2: Category（中等）
- [ ] P3: ProductDetail（高）
- [ ] P4: Search（中等）
- [ ] P5: Cart（中等）
- [ ] P6: Checkout（高）
- [ ] P7: UserProfile（简单）
```
