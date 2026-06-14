# 游客端Web页面代码模板

> 以下模板展示通用模式。实际开发中，类型从 `@/api/` 的生成代码导入。

---

## 首页模板 (index.vue)

```vue
<!-- pages/index.vue -->
<template>
  <div>
    <HeroBanner :banners="banners" />

    <section class="container mx-auto px-4 py-8">
      <CategoryNav :categories="categories" />
    </section>

    <section class="container mx-auto px-4 py-8">
      <h2 class="text-2xl font-bold mb-6">{{ $t('home.featured') }}</h2>
      <ProductGrid :products="featuredProducts" />
    </section>

    <section class="container mx-auto px-4 py-8">
      <h2 class="text-2xl font-bold mb-6">{{ $t('home.bestsellers') }}</h2>
      <ProductGrid :products="bestsellers" />
    </section>
  </div>
</template>

<script setup lang="ts">
// SSG 预渲染
const { data: banners } = await useFetch('/api/banners')
const { data: categories } = await useFetch('/api/categories')
const { data: featuredProducts } = await useFetch('/api/products/featured')
const { data: bestsellers } = await useFetch('/api/products/bestsellers')

// SEO
useSeoMeta({
  title: 'Home - SiteName',
  description: 'Discover amazing products at unbeatable prices.',
  ogImage: '/og-image.jpg',
})
</script>
```

## 分类页模板 (category/[id].vue)

```vue
<!-- pages/category/[id].vue -->
<template>
  <div class="container mx-auto px-4 py-6">
    <!-- 面包屑 -->
    <nav class="text-sm text-muted-foreground mb-4">
      <NuxtLink to="/">Home</NuxtLink>
      <span class="mx-2">/</span>
      <span>{{ category?.name }}</span>
    </nav>

    <div class="flex gap-6">
      <!-- 筛选侧边栏 -->
      <FilterSidebar
        v-model="filters"
        :facets="facets"
        class="hidden lg:block w-64 flex-shrink-0"
      />

      <!-- 商品列表 -->
      <div class="flex-1">
        <div class="flex items-center justify-between mb-4">
          <h1 class="text-2xl font-bold">{{ category?.name }}</h1>
          <SortSelector v-model="sortBy" />
        </div>

        <ProductGrid :products="products" :loading="pending" />

        <Pagination
          v-model:page="page"
          :total="total"
          :page-size="24"
          class="mt-8"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const categoryId = computed(() => route.params.id as string)

const page = ref(1)
const sortBy = ref('relevance')
const filters = reactive({
  priceRange: [0, 1000],
  brands: [],
  ratings: [],
})

const { data: category } = await useFetch(`/api/categories/${categoryId.value}`)
const { data: products, pending, refresh } = await useFetch('/api/products', {
  query: {
    category: categoryId,
    page,
    sort: sortBy,
    ...filters,
  },
  watch: [page, sortBy, filters],
})

useSeoMeta({
  title: computed(() => `${category.value?.name} - SiteName`),
  description: computed(() => `Shop ${category.value?.name} at SiteName.`),
})
</script>
```

## 商品详情页模板 (product/[slug].vue)

```vue
<!-- pages/product/[slug].vue -->
<template>
  <div v-if="product" class="container mx-auto px-4 py-6">
    <!-- 面包屑 -->
    <nav class="text-sm text-muted-foreground mb-6">
      <NuxtLink to="/">Home</NuxtLink>
      <span class="mx-2">/</span>
      <NuxtLink :to="`/category/${product.categoryId}`">{{ product.categoryName }}</NuxtLink>
      <span class="mx-2">/</span>
      <span class="truncate">{{ product.name }}</span>
    </nav>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12">
      <!-- 图片画廊 -->
      <ProductGallery :images="product.images" />

      <!-- 商品信息 -->
      <div>
        <h1 class="text-2xl lg:text-3xl font-bold mb-2">{{ product.name }}</h1>

        <div class="flex items-center gap-2 mb-4">
          <StarRating :rating="product.rating" />
          <span class="text-sm text-muted-foreground">({{ product.reviewCount }} reviews)</span>
        </div>

        <PriceDisplay
          :price="product.price"
          :original-price="product.originalPrice"
          class="text-3xl mb-6"
        />

        <!-- SKU 选择 -->
        <SkuSelector
          v-model="selectedSku"
          :options="product.skus"
          class="mb-6"
        />

        <!-- 数量与加入购物车 -->
        <div class="flex items-center gap-4 mb-6">
          <QuantitySelector v-model="quantity" :max="selectedSku?.stock" />
          <button
            class="flex-1 h-12 bg-primary text-white rounded-full font-semibold hover:bg-primary-hover transition-colors disabled:opacity-50"
            :disabled="!selectedSku || selectedSku.stock === 0"
            @click="addToCart"
          >
            {{ selectedSku?.stock === 0 ? 'Sold Out' : 'Add to Cart' }}
          </button>
        </div>

        <!-- 商品描述 -->
        <div class="prose prose-sm max-w-none mb-8">
          <p>{{ product.description }}</p>
        </div>
      </div>
    </div>

    <!-- 评价 -->
    <ReviewList :product-id="product.id" class="mt-12" />
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const slug = route.params.slug as string
const cart = useCartStore()

const { data: product } = await useFetch(`/api/products/${slug}`, {
  key: `product-${slug}`,
})

const selectedSku = ref(null)
const quantity = ref(1)

const addToCart = () => {
  if (!selectedSku.value) return
  cart.addItem(product.value!, selectedSku.value, quantity.value)
}

// SEO + 结构化数据
useSeoMeta({
  title: computed(() => `${product.value?.name} - SiteName`),
  description: computed(() => product.value?.description?.slice(0, 160)),
  ogImage: computed(() => product.value?.images[0]),
})

useHead({
  script: [{
    type: 'application/ld+json',
    innerHTML: computed(() => JSON.stringify({
      '@context': 'https://schema.org',
      '@type': 'Product',
      name: product.value?.name,
      image: product.value?.images,
      offers: {
        '@type': 'Offer',
        price: product.value?.price,
        priceCurrency: 'USD',
        availability: selectedSku.value?.stock > 0 ? 'InStock' : 'OutOfStock',
      },
    })),
  }],
})
</script>
```

## 购物车页模板 (cart.vue)

```vue
<!-- pages/cart.vue -->
<template>
  <div class="container mx-auto px-4 py-6">
    <h1 class="text-2xl font-bold mb-6">Shopping Cart ({{ cart.totalCount }})</h1>

    <div v-if="cart.items.length === 0" class="text-center py-16">
      <p class="text-muted-foreground mb-4">Your cart is empty</p>
      <NuxtLink to="/" class="text-primary hover:underline">Continue Shopping</NuxtLink>
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- 商品列表 -->
      <div class="lg:col-span-2 space-y-4">
        <div
          v-for="item in cart.items"
          :key="item.id"
          class="flex gap-4 p-4 bg-background-muted rounded-lg"
        >
          <NuxtImg
            :src="item.image"
            :alt="item.name"
            width="96"
            height="96"
            class="rounded-md object-cover"
          />

          <div class="flex-1">
            <h3 class="font-medium">{{ item.name }}</h3>
            <p class="text-sm text-muted-foreground">{{ item.variant }}</p>

            <div class="flex items-center justify-between mt-2">
              <QuantitySelector
                v-model="item.quantity"
                :max="item.maxStock"
                @update:model-value="cart.updateQuantity(item.id, $event)"
              />
              <span class="font-semibold">${{ (item.price * item.quantity).toFixed(2) }}</span>
            </div>
          </div>

          <button class="text-muted-foreground hover:text-danger" @click="cart.removeItem(item.id)">
            <Icon name="lucide:x" />
          </button>
        </div>
      </div>

      <!-- 结算摘要 -->
      <div class="bg-background-muted p-6 rounded-lg h-fit">
        <h2 class="font-semibold mb-4">Order Summary</h2>

        <div class="space-y-2 text-sm mb-4">
          <div class="flex justify-between">
            <span>Subtotal</span>
            <span>${{ cart.totalPrice.toFixed(2) }}</span>
          </div>
          <div class="flex justify-between">
            <span>Shipping</span>
            <span>Calculated at checkout</span>
          </div>
        </div>

        <div class="border-t pt-4 flex justify-between font-bold text-lg">
          <span>Total</span>
          <span>${{ cart.totalPrice.toFixed(2) }}</span>
        </div>

        <NuxtLink
          to="/checkout"
          class="block w-full h-14 bg-primary text-white rounded-full font-semibold text-center leading-[56px] mt-6 hover:bg-primary-hover transition-colors"
        >
          Proceed to Checkout
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const cart = useCartStore()

definePageMeta({ ssr: false })
</script>
```

## 布局模板 (layouts/default.vue)

```vue
<!-- layouts/default.vue -->
<template>
  <div class="min-h-screen flex flex-col">
    <AppHeader />

    <main class="flex-1">
      <slot />
    </main>

    <AppFooter />

    <CartDrawer />
  </div>
</template>
```

## 商品卡片组件模板 (components/product/ProductCard.vue)

```vue
<!-- components/product/ProductCard.vue -->
<template>
  <NuxtLink
    :to="`/product/${product.slug}`"
    class="group block bg-background rounded-lg overflow-hidden transition-shadow hover:shadow-md"
  >
    <!-- 图片 -->
    <div class="relative aspect-[3/4] overflow-hidden bg-background-muted">
      <NuxtImg
        :src="product.mainImage"
        :alt="product.name"
        format="webp"
        sizes="sm:50vw md:33vw lg:25vw"
        loading="lazy"
        class="w-full h-full object-cover transition-transform duration-200 group-hover:scale-105"
      />

      <!-- 折扣标签 -->
      <span
        v-if="discount > 0"
        class="absolute top-2 left-2 px-2 py-1 text-xs font-semibold bg-primary text-white rounded"
      >
        -{{ discount }}%
      </span>

      <!-- 收藏按钮 -->
      <button
        class="absolute top-2 right-2 p-2 rounded-full bg-white/80 opacity-0 group-hover:opacity-100 transition-opacity"
        @click.prevent="toggleWishlist"
      >
        <Icon :name="isWishlisted ? 'lucide:heart' : 'lucide:heart-off'" />
      </button>
    </div>

    <!-- 信息 -->
    <div class="p-3">
      <h3 class="text-sm font-medium line-clamp-2 mb-1">{{ product.name }}</h3>

      <div class="flex items-center gap-1 mb-2">
        <StarRating :rating="product.rating" size="sm" />
        <span class="text-xs text-muted-foreground">({{ product.reviewCount }})</span>
      </div>

      <PriceDisplay
        :price="product.price"
        :original-price="product.originalPrice"
        size="sm"
      />
    </div>
  </NuxtLink>
</template>

<script setup lang="ts">
import type { Product } from '@/api/product'

const props = defineProps<{
  product: Product
}>()

const discount = computed(() => {
  if (!props.product.originalPrice) return 0
  return Math.round((1 - props.product.price / props.product.originalPrice) * 100)
})

const isWishlisted = ref(false)
const toggleWishlist = () => {
  isWishlisted.value = !isWishlisted.value
}
</script>
```

## 布局组件模板 (components/layout/AppHeader.vue)

```vue
<!-- components/layout/AppHeader.vue -->
<template>
  <header
    class="sticky top-0 z-50 h-16 bg-background/80 backdrop-blur-md border-b transition-shadow"
    :class="{ 'shadow-sm': isScrolled }"
  >
    <div class="container mx-auto px-4 h-full flex items-center gap-4">
      <!-- Logo -->
      <NuxtLink to="/" class="text-xl font-bold flex-shrink-0">SiteName</NuxtLink>

      <!-- 搜索框 -->
      <div class="flex-1 max-w-xl hidden md:block">
        <div class="relative">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search products..."
            class="w-full h-10 pl-10 pr-4 rounded-full bg-background-muted border border-border focus:border-primary focus:outline-none"
            @keyup.enter="handleSearch"
          />
          <Icon name="lucide:search" class="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
        </div>
      </div>

      <!-- 右侧图标 -->
      <div class="flex items-center gap-2">
        <NuxtLink to="/cart" class="relative p-2">
          <Icon name="lucide:shopping-cart" />
          <span
            v-if="cart.totalCount > 0"
            class="absolute -top-1 -right-1 w-5 h-5 bg-primary text-white text-xs rounded-full flex items-center justify-center"
          >
            {{ cart.totalCount }}
          </span>
        </NuxtLink>

        <NuxtLink to="/user/profile" class="p-2">
          <Icon name="lucide:user" />
        </NuxtLink>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
const cart = useCartStore()
const searchQuery = ref('')
const router = useRouter()

const isScrolled = ref(false)
onMounted(() => {
  window.addEventListener('scroll', () => {
    isScrolled.value = window.scrollY > 10
  })
})

const handleSearch = () => {
  if (searchQuery.value.trim()) {
    router.push(`/search?q=${encodeURIComponent(searchQuery.value)}`)
  }
}
</script>
```
