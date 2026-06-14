# Nuxt 3 开发模板

> 游客端 Web 使用 Nuxt 3 + Tailwind CSS + Shadcn Vue，非 Element Plus。

## 页面模板

### 商品列表页（ISR）
```vue
<template>
  <div class="container mx-auto px-4 py-8">
    <h1 class="text-2xl font-bold mb-6">{{ category.name }}</h1>

    <!-- 筛选栏 -->
    <div class="flex gap-4 mb-6">
      <Select v-model="filters.sortBy" :options="sortOptions" placeholder="排序方式" />
      <Select v-model="filters.priceRange" :options="priceRanges" placeholder="价格区间" />
    </div>

    <!-- 商品网格 -->
    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      <ProductCard
        v-for="product in products"
        :key="product.id"
        :product="product"
        @click="navigateTo(`/product/${product.slug}`)"
      />
    </div>

    <!-- 加载更多 -->
    <div class="text-center mt-8">
      <Button v-if="hasMore" variant="outline" @click="loadMore" :loading="loadingMore">
        加载更多
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Product, Category } from '@/api/product'
import ProductCard from '@/components/product/ProductCard.vue'

const route = useRoute()
const categorySlug = route.params.slug as string

const filters = reactive({
  sortBy: 'default',
  priceRange: 'all',
})

const page = ref(1)
const loadingMore = ref(false)

const { data: category } = await useFetch<Category>(`/api/categories/${categorySlug}`)
const { data: products, pending } = await useFetch<Product[]>('/api/products', {
  query: { category: categorySlug, page, sort: filters.sortBy },
})

const hasMore = computed(() => products.value?.length === 24)

const loadMore = async () => {
  loadingMore.value = true
  page.value++
  loadingMore.value = false
}

// 实际项目中应提取到 composables/useProductFilters.ts，此处仅作演示
const sortOptions = [
  { label: '默认排序', value: 'default' },
  { label: '价格从低到高', value: 'price_asc' },
  { label: '价格从高到低', value: 'price_desc' },
]

const priceRanges = [
  { label: '全部价格', value: 'all' },
  { label: '0-100', value: '0-100' },
  { label: '100-500', value: '100-500' },
]

useSeoMeta({
  title: () => `${category.value?.name || '商品列表'} - ${siteName}`,
  description: () => category.value?.description || '',
})
</script>
```

### 商品详情页（ISR）
```vue
<template>
  <div class="container mx-auto px-4 py-8" v-if="product">
    <div class="grid md:grid-cols-2 gap-8">
      <!-- 图片 -->
      <div>
        <NuxtImg
          :src="product.images[0]"
          :alt="product.name"
          format="webp"
          sizes="sm:100vw md:50vw lg:600px"
          class="rounded-lg"
        />
      </div>

      <!-- 信息 -->
      <div>
        <h1 class="text-3xl font-bold">{{ product.name }}</h1>
        <p class="text-2xl text-primary mt-4">¥{{ product.price }}</p>
        <p class="text-muted-foreground mt-4">{{ product.description }}</p>

        <Button class="mt-6 w-full" size="lg" @click="addToCart">
          加入购物车
        </Button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Product } from '@/api/product'

const route = useRoute()
const slug = route.params.slug as string

const { data: product } = await useFetch<Product>(`/api/products/${slug}`)

const cartStore = useCartStore()

const addToCart = () => {
  if (product.value) {
    cartStore.addItem(product.value)
  }
}

useSeoMeta({
  title: () => `${product.value?.name || '商品'} - ${siteName}`,
  description: () => product.value?.description || '',
  ogImage: () => product.value?.images[0] || '',
})

useHead({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'Product',
        name: product.value?.name,
        image: product.value?.images,
        offers: {
          '@type': 'Offer',
          price: product.value?.price,
          priceCurrency: 'CNY',
        },
      }),
    },
  ],
})
</script>
```

## Composable 模板

### 数据获取
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

### 业务逻辑
```typescript
// composables/useCart.ts
export function useCart() {
  const cartStore = useCartStore()

  const addItem = (product: Product) => {
    cartStore.addItem(product)
  }

  const removeItem = (productId: string) => {
    cartStore.removeItem(productId)
  }

  return { addItem, removeItem }
}
```
