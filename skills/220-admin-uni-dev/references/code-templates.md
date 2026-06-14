# 管理端UniApp页面代码模板

> 以下模板展示通用模式。实际开发中，类型从 `@/api/` 的生成代码导入，API 函数也从 `@/api/` 导入。

---

## 列表页模板 (list.vue)

管理端列表页：顶部搜索 + 筛选 + 数据列表 + 悬浮新增按钮

```vue
<!-- src/pages/{role}/{module}/list.vue -->
<template>
  <view class="page-container">
    <!-- 搜索筛选区 -->
    <view class="search-bar">
      <SearchBar
        v-model="keyword"
        placeholder="请输入关键词搜索"
        @search="handleSearch"
      />
      <view class="filter-row">
        <text
          v-for="filter in filters"
          :key="filter.value"
          class="filter-item"
          :class="{ active: currentFilter === filter.value }"
          @click="currentFilter = filter.value"
        >
          {{ filter.label }}
        </text>
      </view>
    </view>

    <!-- 数据列表 -->
    <DataList
      :data="listData"
      :loading="loading"
      :has-more="hasMore"
      @refresh="handleRefresh"
      @load-more="handleLoadMore"
    >
      <template #item="{ item }">
        <view class="list-item" @click="handleDetail(item)">
          <view class="item-header">
            <text class="item-title">{{ item.{module}Name }}</text>
            <StatusTag :status="item.status" />
          </view>
          <view class="item-meta">
            <text class="meta-text">{{ item.createTime }}</text>
            <text class="meta-text">{{ item.operator }}</text>
          </view>
        </view>
      </template>
    </DataList>

    <!-- 空状态 -->
    <EmptyState v-if="!loading && listData.length === 0" description="暂无数据" />

    <!-- 悬浮新增按钮 -->
    <view
      v-if="menuStore.hasPermission('{module}:add')"
      class="fab-btn"
      @click="handleAdd"
    >
      <text class="fab-icon">+</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import SearchBar from '@/components/common/SearchBar.vue'
import DataList from '@/components/common/DataList.vue'
import StatusTag from '@/components/common/StatusTag.vue'
import EmptyState from '@/components/common/EmptyState.vue'
import { admin{Module}List } from '@/api/admin{Module}'
import type { {Module}Info } from '@/api/admin{Module}'
import { useMenuStore } from '@/store/menu'

const menuStore = useMenuStore()

const listData = ref<{Module}Info[]>([])
const loading = ref(false)
const hasMore = ref(true)
const keyword = ref('')
const currentFilter = ref('all')
const pageNum = ref(1)

const filters = [
  { label: '全部', value: 'all' },
  { label: '待处理', value: 'pending' },
  { label: '已通过', value: 'approved' },
]

const fetchList = async (isRefresh = false) => {
  if (loading.value) return
  loading.value = true
  try {
    if (isRefresh) pageNum.value = 1
    const res = await admin{Module}List({
      param: {
        $pg: pageNum.value,
        $rn: 20,
        keyword: keyword.value || undefined,
        status: currentFilter.value === 'all' ? undefined : currentFilter.value,
      }
    })
    const results = res.data?.results || []
    if (isRefresh) {
      listData.value = results
    } else {
      listData.value.push(...results)
    }
    hasMore.value = results.length >= 20
    pageNum.value++
  } finally {
    loading.value = false
  }
}

const handleSearch = () => fetchList(true)
const handleRefresh = () => fetchList(true)
const handleLoadMore = () => { if (hasMore.value) fetchList() }

const handleDetail = (item: {Module}Info) => {
  uni.navigateTo({ url: `/pages/{role}/{module}/detail?id=${item.id}` })
}

const handleAdd = () => {
  uni.navigateTo({ url: `/pages/{role}/{module}/form` })
}

onLoad(() => fetchList(true))
</script>
```

## 详情页模板 (detail.vue)

管理端详情页：信息展示 + 操作按钮（根据权限）

```vue
<!-- src/pages/{role}/{module}/detail.vue -->
<template>
  <view class="page-container" v-if="detail">
    <view class="detail-card">
      <view class="detail-header">
        <text class="detail-title">{{ detail.{module}Name }}</text>
        <StatusTag :status="detail.status" />
      </view>
      <view class="detail-section">
        <view class="section-title">基本信息</view>
        <view class="info-row" v-for="field in infoFields" :key="field.key">
          <text class="info-label">{{ field.label }}</text>
          <text class="info-value">{{ detail[field.key] }}</text>
        </view>
      </view>
    </view>

    <view class="action-bar">
      <button v-if="menuStore.hasPermission('{module}:edit')" class="btn-primary" @click="handleEdit">编辑</button>
      <button v-if="menuStore.hasPermission('{module}:delete')" class="btn-danger" @click="handleDelete">删除</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import StatusTag from '@/components/common/StatusTag.vue'
import { admin{Module}Load, admin{Module}Delete } from '@/api/admin{Module}'
import type { {Module}Info } from '@/api/admin{Module}'
import { useMenuStore } from '@/store/menu'

const menuStore = useMenuStore()
const detail = ref<{Module}Info | null>(null)
const infoFields = [
  { label: '名称', key: '{module}Name' },
  { label: '状态', key: 'statusText' },
  { label: '创建时间', key: 'createTime' },
]

onLoad(async (options) => {
  const id = options?.id
  if (id) {
    const res = await admin{Module}Load({ id: Number(id) })
    detail.value = res.data ?? null
  }
})

const handleEdit = () => {
  uni.navigateTo({ url: `/pages/{role}/{module}/form?id=${detail.value?.id}` })
}

const handleDelete = () => {
  uni.showModal({
    title: '确认删除',
    content: '删除后不可恢复，是否继续？',
    success: async (res) => {
      if (res.confirm) {
        await admin{Module}Delete({ id: detail.value!.id })
        uni.showToast({ title: '删除成功', icon: 'success' })
        setTimeout(() => uni.navigateBack(), 1500)
      }
    }
  })
}
</script>
```

## 表单页模板 (form.vue)

管理端表单页：字段输入 + 底部提交按钮

```vue
<!-- src/pages/{role}/{module}/form.vue -->
<template>
  <view class="page-container">
    <view class="form-card">
      <view class="form-item">
        <text class="form-label">名称 <text class="required">*</text></text>
        <input v-model="form.{module}Name" class="form-input" placeholder="请输入名称" />
      </view>
      <view class="form-item">
        <text class="form-label">状态</text>
        <picker mode="selector" :range="statusOptions" @change="onStatusChange">
          <view class="form-picker">
            {{ form.status || '请选择状态' }}
            <text class="picker-arrow">▼</text>
          </view>
        </picker>
      </view>
      <view class="form-item">
        <text class="form-label">备注</text>
        <textarea v-model="form.remark" class="form-textarea" placeholder="请输入备注" />
      </view>
    </view>
    <view class="submit-bar">
      <button class="btn-submit" @click="handleSubmit">提交</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { admin{Module}Load, admin{Module}Create, admin{Module}Update } from '@/api/admin{Module}'
import type { {Module}Form } from '@/api/admin{Module}'

const form = ref<{Module}Form>({
  {module}Name: '',
  status: '',
  remark: '',
})

const statusOptions = ['待处理', '已通过', '已拒绝']
const isEdit = ref(false)

onLoad(async (options) => {
  const id = options?.id
  if (id) {
    isEdit.value = true
    const res = await admin{Module}Load({ id: Number(id) })
    if (res.data) form.value = res.data as unknown as {Module}Form
  }
})

const onStatusChange = (e: { detail: { value: number } }) => {
  form.value.status = statusOptions[e.detail.value]
}

const handleSubmit = async () => {
  if (!form.value.{module}Name.trim()) {
    uni.showToast({ title: '请输入名称', icon: 'none' })
    return
  }
  if (isEdit.value) {
    await admin{Module}Update({ data: form.value })
  } else {
    await admin{Module}Create({ data: form.value })
  }
  uni.showToast({ title: '保存成功', icon: 'success' })
  setTimeout(() => uni.navigateBack(), 1500)
}
</script>
```
