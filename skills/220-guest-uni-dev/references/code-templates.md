# 消费者端UniApp页面代码模板

> 以下模板展示通用模式。实际开发中：
>
> - API 函数从 `@/api/` 导入；
> - **UI 组件**优先使用 easycom 自动注册的 `<uni-*>`（uni-ui）、`<u-*>` / `<up-*>` / `<u--*>`（uview-plus），无需 import；
> - **文案**统一走 `vue-i18n`（`$t()` / `t()`），4 种语言（zh-CN / zh-TW / en / ja）的 key 同步补齐。

---

## 列表页模板（通用）

适用于首页、分类、发现、搜索等列表页面。

```vue
<!-- 业务分包列表页：默认放 src/packages/{module}/index.vue -->
<!-- 特殊情况（路由不带 packages/）：src/{module}/index.vue，需在 pages.json 的 subPackages 注册 root -->
<template>
  <view class="page-container">
    <!-- 搜索/筛选区 -->
    <view class="filter-bar">
      <input class="search-input" placeholder="搜索" :value="keyword" @confirm="handleSearch" />
    </view>

    <!-- 列表 -->
    <scroll-list :loading="loading" :has-more="hasMore" @load-more="loadMore" @refresh="refresh">
      <view v-for="item in list" :key="item.id" class="list-item" @click="goToDetail(item.id)">
        <image v-if="item.coverImage" class="cover" :src="item.coverImage" mode="aspectFill" />
        <view class="info">
          <text class="title">{{ item.title }}</text>
          <text class="summary">{{ item.summary }}</text>
        </view>
      </view>
    </scroll-list>
  </view>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { onShow } from "@dcloudio/uni-app";
import { guestXxxList } from "@/api/guestXxx";
import type { XxxItem } from "@/api/guestXxx";

const list = ref<XxxItem[]>([]);
const keyword = ref("");
const loading = ref(false);
const hasMore = ref(true);
const pageNum = ref(1);

const loadList = async (isRefresh = false) => {
  if (loading.value) return;
  loading.value = true;
  try {
    if (isRefresh) pageNum.value = 1;
    const res = await guestXxxList({
      param: { $pg: pageNum.value, $rn: 20, keyword: keyword.value || undefined },
    });
    const items = res.data?.list || [];
    if (isRefresh) {
      list.value = items;
    } else {
      list.value.push(...items);
    }
    hasMore.value = items.length >= 20;
    pageNum.value++;
  } finally {
    loading.value = false;
  }
};

const refresh = () => loadList(true);
const loadMore = () => {
  if (hasMore.value) loadList();
};
const handleSearch = () => refresh();
const goToDetail = (id: number) => {
  uni.navigateTo({ url: `/pages/xxx/detail?id=${id}` });
};

onShow(() => refresh());
</script>
```

## 详情页模板（通用）

适用于文章、商品、问答等详情页面。

```vue
<!-- 详情页：默认放 src/packages/{module}/detail.vue；特殊情况放 src/{module}/detail.vue -->
<template>
  <view class="page-container" v-if="detail">
    <image v-if="detail.coverImage" class="cover" :src="detail.coverImage" mode="aspectFill" />
    <view class="content-body">
      <text class="title">{{ detail.title }}</text>
      <view class="meta">
        <text class="author">{{ detail.authorName }}</text>
        <text class="time">{{ detail.createDate }}</text>
      </view>
      <rich-text :nodes="detail.content" />
    </view>

    <!-- 底部操作栏 -->
    <view class="bottom-bar">
      <text class="action-btn" @click="handleShare">分享</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { onLoad, onShareAppMessage } from "@dcloudio/uni-app";
import { guestXxxLoad } from "@/api/guestXxx";
import type { XxxDetail } from "@/api/guestXxx";

const detail = ref<XxxDetail | null>(null);

onLoad(async (options) => {
  const id = options?.id;
  if (id) {
    const res = await guestXxxLoad({ id: Number(id) });
    detail.value = res.data ?? null;
  }
});

onShareAppMessage(() => ({
  title: detail.value?.title || "精彩内容",
  path: `/pages/xxx/detail?id=${detail.value?.id}`,
  imageUrl: detail.value?.coverImage,
}));

const handleShare = () => {
  // #ifdef APP-PLUS
  uni.share({
    provider: "weixin",
    scene: "WXSceneSession",
    type: 0,
    title: detail.value?.title,
    imageUrl: detail.value?.coverImage,
  });
  // #endif
};
</script>
```

## 我的Tab模板

```vue
<!-- 我的 Tab：建议放主包 src/pages/user/index.vue，或沿用现有分包路径 -->
<template>
  <view class="page-container">
    <!-- 用户信息卡片 -->
    <view class="user-card">
      <image
        class="avatar"
        :src="userInfo?.avatar || '/static/default-avatar.png'"
        mode="aspectFill"
      />
      <view class="user-info" v-if="isLogin">
        <text class="nickname">{{ userInfo?.nickname }}</text>
      </view>
      <view class="user-info" v-else @click="goToLogin">
        <text class="nickname">点击登录</text>
      </view>
    </view>

    <!-- 功能列表 -->
    <view class="menu-list">
      <view class="menu-item" v-for="item in menuItems" :key="item.label" @click="item.onClick">
        <text class="menu-label">{{ item.label }}</text>
        <text class="menu-arrow">></text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { onShow } from "@dcloudio/uni-app";
import { useUserStore } from "@/store/user";

const userStore = useUserStore();
const isLogin = computed(() => userStore.isLogin);
const userInfo = computed(() => userStore.userInfo);

const menuItems = [
  { label: "我的资料", onClick: () => goToProfile() },
  { label: "我的收藏", onClick: () => goToFavorites() },
  { label: "设置", onClick: () => goToSettings() },
];

const goToLogin = () => uni.navigateTo({ url: "/pages/auth/login" });
const goToProfile = () => uni.navigateTo({ url: "/pages/user/profile" });
const goToFavorites = () => uni.navigateTo({ url: "/pages/user/favorites" });
const goToSettings = () => uni.navigateTo({ url: "/pages/user/settings" });

onShow(() => {
  if (isLogin.value) userStore.setUserInfo();
});
</script>
```
