# 游客端Web开发规范（Nuxt 3 + Vue 3 + TypeScript）

> 面向终端消费者的网站。被 220-guest-web-dev 引用。

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Nuxt | 3.16+ | 全栈框架，文件路由 + Nitro 引擎 |
| Vue | 3.5+ | 前端框架，启用 Vapor 模式 |
| TypeScript | 5.6+ | 严格模式，类型安全 |
| Tailwind CSS | 4.x | 原子样式、响应式、暗黑模式 |
| Radix Vue | 1.x | 无头交互组件（Dialog、Popover 等） |
| Shadcn Vue | 最新 | 基于 Radix + Tailwind 的预设组件 |
| Pinia | 2.x | 全局客户端状态（购物车、用户） |
| Vue Query | 5.x | 服务端状态缓存、自动刷新 |
| ofetch | 内置 | HTTP 客户端，自动重试、SSR 友好 |
| zod | 3.x | API 响应运行时类型校验 |
| @nuxt/image | 1.x | 图片自动优化、WebP/AVIF 转换 |
| @nuxtjs/i18n | 8.x | 多语言、SEO hreflang |
| @nuxtjs/sitemap | 最新 | 自动生成多语言 sitemap |

## Nuxt 配置

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  devtools: { enabled: true },
  future: {
    compatibilityVersion: 4,
  },
  experimental: {
    vapor: true,
  },
  nitro: {
    preset: 'node-server',
  },
  routeRules: {
    '/': { prerender: true },
    '/product/**': { isr: 60 },
    '/category/**': { isr: 60 },
    '/search': { ssr: true },
    '/user/**': { ssr: false },
    '/cart': { ssr: false },
  },
  modules: [
    '@nuxt/image',
    '@nuxtjs/i18n',
    '@nuxtjs/sitemap',
  ],
})
```

## 目录结构

```
├── pages/                     # 文件路由页面
│   ├── index.vue              # 首页（SSG）
│   ├── product/
│   │   └── [slug].vue         # 商品详情（ISR）
│   ├── category/
│   │   └── [id].vue           # 分类页（ISR）
│   ├── search.vue             # 搜索结果（SSR）
│   ├── cart.vue               # 购物车（CSR）
│   └── user/
│       ├── profile.vue        # 个人中心（CSR）
│       └── orders.vue         # 订单列表（CSR）
├── components/                # 组件
│   ├── ui/                    # Shadcn/Radix 基础组件
│   ├── product/               # 商品相关组件
│   ├── cart/                  # 购物车组件
│   └── layout/                # 布局组件
├── composables/               # 组合函数
│   ├── useCart.ts
│   ├── useProducts.ts
│   └── useAuth.ts
├── stores/                    # Pinia 状态
│   ├── cart.ts
│   ├── user.ts
│   └── checkout.ts
├── server/                    # Nitro 服务端
│   └── api/                   # API 路由
├── layouts/                   # 页面布局
│   ├── default.vue            # 默认布局（带导航/页脚）
│   └── checkout.vue           # 结算页专用布局
├── middleware/                # 路由中间件
│   └── auth.ts                # 登录守卫
└── i18n/                      # 多语言文件
    ├── en.json
    └── zh.json
```

## 路由与渲染策略

| 页面类型 | 渲染模式 | 配置 | 原因 |
|----------|---------|------|------|
| 首页 / 活动页 | SSG | `prerender: true` | 内容固定，CDN 缓存极致性能 |
| 商品详情 / 分类页 | ISR | `isr: 60` | 价格库存会变，但可缓存 60 秒 |
| 搜索 / 筛选结果 | SSR | `ssr: true` | 参数动态，必须服务端渲染 |
| 用户中心 / 购物车 | CSR | `ssr: false` | 纯个人数据，无需 SEO |

## 页面编码规范

### SFC 结构顺序

```vue
<template>...</template>
<script setup lang="ts">...</script>
<style scoped>...</style>
```

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 页面文件 | kebab-case | `index.vue`, `[slug].vue` |
| 组件文件 | PascalCase | `ProductCard.vue` |
| composables | use 前缀 | `useCart.ts` |
| Store 文件 | kebab-case | `cart.ts` |
| 类型文件 | kebab-case | `product.ts` |
| API 路由 | kebab-case | `products.get.ts` |

### `<script setup>` 结构

```typescript
// 1. 类型导入（从 api 层导入）
import type { Product } from '@/api/product'

// 2. 组件导入
import ProductCard from '@/components/product/ProductCard.vue'

// 3. 工具/composables
const { data: products } = useProducts(category)
const cart = useCartStore()

// 4. 响应式状态
const selectedVariant = ref<string>('')

// 5. 方法定义
const addToCart = () => { ... }
```

## 状态管理

### Pinia（客户端状态）

```typescript
// stores/cart.ts
export const useCartStore = defineStore('cart', () => {
  const items = ref<CartItem[]>([])
  const totalCount = computed(() => items.value.reduce((sum, i) => sum + i.qty, 0))
  const totalPrice = computed(() => items.value.reduce((sum, i) => sum + i.price * i.qty, 0))

  const addItem = (product: Product, variant: string, qty: number) => { ... }
  const removeItem = (id: string) => { ... }

  return { items, totalCount, totalPrice, addItem, removeItem }
})
```

### Vue Query（服务端状态）

```typescript
// composables/useProducts.ts
export function useProducts(category: string) {
  return useQuery({
    queryKey: ['products', category],
    queryFn: () => $fetch(`/api/products?category=${category}`),
    staleTime: 1000 * 60 * 5,
  })
}
```

## API 数据获取规范

```typescript
// 商品列表
const { data: products, pending, error } = await useFetch('/api/products', {
  query: { category, page, limit },
  key: `products-${category}-${page}`,
})

// 商品详情（SSR 友好）
const { data: product } = await useFetch(`/api/products/${slug}`, {
  key: `product-${slug}`,
})

// 运行时类型校验
import { z } from 'zod'

const ProductSchema = z.object({
  id: z.string(),
  name: z.string(),
  price: z.number().positive(),
  images: z.array(z.string().url()),
})

type Product = z.infer<typeof ProductSchema>

// 校验响应
const validated = ProductSchema.parse(response)
```

## SEO 规范

```typescript
// 商品页 SEO
useSeoMeta({
  title: `${product.name} - ${siteName}`,
  description: product.description,
  ogImage: product.images[0],
  twitterCard: 'summary_large_image',
})

// JSON-LD 结构化数据
useHead({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'Product',
        name: product.name,
        image: product.images,
        offers: {
          '@type': 'Offer',
          price: product.price,
          priceCurrency: 'USD',
        },
      }),
    },
  ],
})
```

## 图片优化

```vue
<NuxtImg
  :src="product.image"
  :alt="product.name"
  format="webp"
  sizes="sm:100vw md:50vw lg:400px"
  loading="lazy"
  quality="80"
/>
```

## 国际化

```vue
<template>
  <p>{{ $t('product.addToCart') }}</p>
  <NuxtLink :to="localePath('/cart')">{{ $t('cart.view') }}</NuxtLink>
</template>
```

## 禁用规则

| 禁用项 | 说明 |
|--------|------|
| `any` 类型 | 必须定义具体类型或使用 zod 推断 |
| Options API | 统一使用 Composition API + `<script setup>` |
| jQuery | 禁止引入 |
| 直接 DOM 操作 | 使用 Vue 响应式 |
| `v-html` 渲染用户输入 | 禁止，存在 XSS 风险 |
| Element Plus / Ant Design Vue | 面向后台管理的组件库，不适用于前台电商 |

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

## 性能规范

| 场景 | 规范 |
|------|------|
| 商品列表 | 分页加载，单次 ≤ 24 条 |
| 图片 | 使用 `<NuxtImg>` 自动 WebP/AVIF 转换 |
| 组件懒加载 | 大组件使用 `defineAsyncComponent` |
| 数据缓存 | Vue Query `staleTime` 设置 5 分钟 |
| 路由 | 按页面类型配置 SSG/ISR/SSR/CSR |
| 包体积 | 避免引入完整组件库，使用 Shadcn 按需复制 |
