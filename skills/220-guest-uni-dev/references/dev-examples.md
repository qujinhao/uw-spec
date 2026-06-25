# UniApp开发示例

> 所有示例基于 gencode 生成的 API 类型。类型从 `@/api/` 导入，不在页面内重新定义。
> 状态/类型判断使用 [`@/config/EnumConst`](../../../../src/config/EnumConst.ts)，下拉/筛选选项使用 [`@/config/optionsConst`](../../../../src/config/optionsConst.ts)，业务扩展枚举使用 [`@/config/EnumExtend`](../../../../src/config/EnumExtend.ts)；**禁止魔数 / 禁止手抄选项数组**。

## 枚举与下拉选项

```typescript
// ✅ 状态判断 - 使用 EnumConst
import { StateOrder } from '@/config/EnumConst'

const isPaid = (state: StateOrder) => state === StateOrder.PAY_SUCCESS
const isPending = (state: StateOrder) =>
  [StateOrder.ORDER_NEW, StateOrder.ORDER_AUDIT].includes(state)
```

```vue
<!-- ✅ 下拉/筛选 - 使用 optionsConst -->
<script setup lang="ts">
import { ref } from 'vue'
import { StateOrderOptions } from '@/config/optionsConst'
import { StateOrder } from '@/config/EnumConst'

const filterState = ref<StateOrder>()
</script>

<template>
  <uni-data-select v-model="filterState" :localdata="StateOrderOptions" />

  <!-- 枚举值 → i18n 文案 -->
  <text>{{ $t(`enumeration.StateOrder.${filterState}`) }}</text>
</template>
```

## API 对接

### 列表页 API 对接

```typescript
import { ref } from 'vue'
import { guestXxxList } from '@/api/guestXxx'
import type { XxxItem } from '@/api/guestXxx'

const list = ref<XxxItem[]>([])
const loading = ref(false)
const hasMore = ref(true)
const pageNum = ref(1)

const loadList = async (isRefresh = false) => {
  if (loading.value) return
  loading.value = true
  try {
    if (isRefresh) pageNum.value = 1
    const res = await guestXxxList({
      param: { $pg: pageNum.value, $rn: 20 }
    })
    // ✅ 先判 state（业务级失败由调用方处理；401/403/498 已被拦截器接管）
    if (res.state !== 'success') {
      uni.showToast({ title: res.msg, icon: 'none' })
      return
    }
    const items = res.data?.list || []
    if (isRefresh) {
      list.value = items
    } else {
      list.value.push(...items)
    }
    hasMore.value = items.length >= 20
    pageNum.value++
  } finally {
    loading.value = false
  }
}
```

### 详情页 API 对接（含 GbLoading）

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import GbLoading from '@/components/GbLoading/index.vue'
import { guestXxxLoad } from '@/api/guestXxx'
import type { XxxDetail } from '@/api/guestXxx'

const detail = ref<XxxDetail | null>(null)
const showLoading = ref(false)

const loadDetail = async (id: number) => {
  showLoading.value = true
  try {
    const res = await guestXxxLoad({ id })
    if (res.state !== 'success') {
      uni.showToast({ title: res.msg, icon: 'none' })
      return
    }
    detail.value = res.data ?? null
  } finally {
    // ✅ 必须 finally，避免异常时 loading 卡死
    showLoading.value = false
  }
}

onLoad((options) => {
  if (options?.id) loadDetail(Number(options.id))
})
</script>

<template>
  <GbLoading v-model="showLoading" />
  <view v-if="detail">…</view>

  <!-- 加载失败占位（detail 为空且 loading 结束） -->
  <view v-else-if="!showLoading" class="flex flex-col items-center py-20">
    <image src="/static/images/empty/load-failed.png" mode="widthFix" class="w-50 h-50" />
    <text class="text-foreground-muted mt-4">{{ $t('common.loadFailed') }}</text>
    <button class="mt-4" @click="loadDetail(currentId)">{{ $t('common.retry') }}</button>
  </view>
</template>
```

### 表单提交

```typescript
import { guestXxxCreate } from '@/api/guestXxx'

const submitForm = async () => {
  // 前端校验
  if (!form.title) {
    uni.showToast({ title: '请输入标题', icon: 'none' })
    return
  }
  if (form.content.length > 500) {
    uni.showToast({ title: '内容不能超过500字', icon: 'none' })
    return
  }

  const res = await guestXxxCreate({ data: form })
  if (res.state === 'success') {
    uni.showToast({ title: '提交成功', icon: 'success' })
    uni.navigateBack()
  }
}
```

## 交互模式

### 下拉刷新 + 上拉加载

```vue
<template>
  <scroll-view
    scroll-y
    refresher-enabled
    :refresher-triggered="isRefreshing"
    @refresherrefresh="onRefresh"
    @scrolltolower="onLoadMore"
  >
    <view v-for="item in list" :key="item.id">
      {{ item.title }}
    </view>
    <view v-if="loading" class="loading">加载中...</view>
    <view v-if="!hasMore && list.length > 0" class="no-more">没有更多了</view>
  </scroll-view>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const list = ref<{ id: number; title: string }[]>([])
const loading = ref(false)
const isRefreshing = ref(false)
const hasMore = ref(true)

const onRefresh = async () => {
  isRefreshing.value = true
  await loadList(true)
  isRefreshing.value = false
}

const onLoadMore = () => {
  if (!loading.value && hasMore.value) {
    loadList()
  }
}
</script>
```

### Tab 切换

```vue
<template>
  <view class="tab-bar">
    <view
      v-for="tab in tabs"
      :key="tab.key"
      class="tab-item"
      :class="{ active: currentTab === tab.key }"
      @click="switchTab(tab.key)"
    >
      {{ tab.label }}
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'

interface TabItem {
  key: string
  label: string
}

const tabs: TabItem[] = [
  { key: 'latest', label: '最新' },
  { key: 'hot', label: '热门' },
  { key: 'follow', label: '关注' },
]
const currentTab = ref('latest')

const switchTab = (key: string) => {
  if (currentTab.value === key) return
  currentTab.value = key
  loadList(true)
}
</script>
```

## 平台适配

### 分享

```typescript
import { onShareAppMessage, onShareTimeline } from '@dcloudio/uni-app'

// 微信小程序分享（自动触发右上角菜单）
onShareAppMessage(() => ({
  title: detail.value?.title || '精彩内容',
  path: `/pages/article/detail?id=${detail.value?.id}`,
  imageUrl: detail.value?.coverImage,
}))

// #ifdef MP-WEIXIN
onShareTimeline(() => ({
  title: detail.value?.title || '精彩内容',
  query: `id=${detail.value?.id}`,
}))
// #endif

// App 端主动分享
const handleShare = () => {
  // #ifdef APP-PLUS
  uni.share({
    provider: 'weixin',
    scene: 'WXSceneSession',
    type: 0,
    title: detail.value?.title,
    imageUrl: detail.value?.coverImage,
  })
  // #endif
}
```

### 登录

```typescript
const handleLogin = async () => {
  // #ifdef MP-WEIXIN
  const loginRes = await uni.login({ provider: 'weixin' })
  if (loginRes[1].code) {
    const res = await guestLoginWx({ data: { code: loginRes[1].code } })
    // 处理登录成功
  }
  // #endif

  // #ifdef H5
  uni.navigateTo({ url: '/pages/auth/login' })
  // #endif
}
```

## Store 使用（对齐现有 [src/store/user.ts](../../../../src/store/user.ts) 风格）

```typescript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { guestUserInfoLoad, type GuestInfoExt } from '@/api/saasMallAppGuestApi'
import type { TokenResponse } from '@/api/saasMallAppOpenApi'

export const useUserStore = defineStore(
  'user',
  () => {
    /* ---------- state ---------- */
    const loginInfo = ref<TokenResponse>({})
    const userInfo = ref<GuestInfoExt>({})

    /* ---------- getters ---------- */
    const token = computed(() => loginInfo.value?.token || '')
    const isLogin = computed(() => !!loginInfo.value?.token)

    /* ---------- actions ---------- */
    function setLoginInfo(info: TokenResponse) {
      loginInfo.value = info
    }

    async function setUserInfo(info?: GuestInfoExt) {
      if (info) {
        userInfo.value = info
        return
      }
      const res = await guestUserInfoLoad()
      if (res.state === 'success') userInfo.value = res.data || {}
    }

    function clearLoginCache() {
      loginInfo.value = {}
      userInfo.value = {}
    }

    /* ---------- 统一导出 ---------- */
    return {
      loginInfo,
      userInfo,
      token,
      isLogin,
      setLoginInfo,
      setUserInfo,
      clearLoginCache,
    }
  },
  {
    unistorage: true, // pinia-plugin-unistorage 持久化
  }
)
```

## 测试

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useUserStore } from '@/store/user'

describe('useUserStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('clearLoginCache 应清除登录与用户信息', () => {
    const store = useUserStore()
    store.setLoginInfo({ token: 'test-token' } as any)
    store.userInfo = { nickname: 'test' } as any

    store.clearLoginCache()

    expect(store.token).toBe('')
    expect(store.userInfo).toEqual({})
  })

  it('isLogin / token 应反映 loginInfo.token', () => {
    const store = useUserStore()
    store.setLoginInfo({} as any)
    expect(store.isLogin).toBe(false)

    store.setLoginInfo({ token: 'valid-token' } as any)
    expect(store.isLogin).toBe(true)
    expect(store.token).toBe('valid-token')
  })
})
```
