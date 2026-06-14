# UniApp开发示例

> 所有示例基于 gencode 生成的 API 类型。类型从 `@/api/` 导入，不在页面内重新定义。

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
    const results = res.data?.results || []
    if (isRefresh) {
      list.value = results
    } else {
      list.value.push(...results)
    }
    hasMore.value = results.length >= 20
    pageNum.value++
  } finally {
    loading.value = false
  }
}
```

### 详情页 API 对接

```typescript
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { guestXxxLoad } from '@/api/guestXxx'
import type { XxxDetail } from '@/api/guestXxx'

const detail = ref<XxxDetail | null>(null)

onLoad(async (options) => {
  const id = options?.id
  if (id) {
    const res = await guestXxxLoad({ id: Number(id) })
    detail.value = res.data ?? null
  }
})
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

## Store 使用

```typescript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { guestInfoLoad } from '@/api/guestInfo'
import type { GuestInfoVO } from '@/api/guestInfo'

export const useUserStore = defineStore('user', () => {
  const token = ref('')
  const userInfo = ref<GuestInfoVO | null>(null)
  const isLogin = computed(() => !!token.value)

  const fetchUserInfo = async () => {
    const res = await guestInfoLoad()
    userInfo.value = res.data ?? null
  }

  const logout = () => {
    token.value = ''
    userInfo.value = null
    uni.removeStorageSync('token')
  }

  return { token, userInfo, isLogin, fetchUserInfo, logout }
})
```

## 测试

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useUserStore } from '@/store/user'

describe('useUserStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('logout 应清除用户信息', () => {
    const store = useUserStore()
    store.token = 'test-token'
    store.userInfo = { nickname: 'test' } as any

    store.logout()

    expect(store.token).toBe('')
    expect(store.userInfo).toBeNull()
    expect(uni.removeStorageSync).toHaveBeenCalledWith('token')
  })

  it('isLogin 应反映 token 状态', () => {
    const store = useUserStore()
    store.token = ''
    expect(store.isLogin).toBe(false)

    store.token = 'valid-token'
    expect(store.isLogin).toBe(true)
  })
})
```
