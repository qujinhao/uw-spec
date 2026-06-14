# Web 端页面代码模板

> 以下模板展示通用模式。实际开发中，类型从 `@/api/` 的生成代码导入，API 函数也从 `@/api/` 导入。

---

## 列表页模板 (index.vue)

```vue
<!-- src/pages/{module}/{role}/{feature}/index.vue -->
<template>
  <div class="page-container">
    <!-- 搜索表单 -->
    <SearchForm
      v-model="searchForm"
      :fields="searchFields"
      @search="handleSearch"
      @reset="handleReset"
    />

    <!-- 操作按钮 -->
    <div class="operation-bar">
      <el-button type="primary" @click="handleAdd">
        <el-icon><Plus /></el-icon>新增
      </el-button>
    </div>

    <!-- 数据表格 -->
    <DataTable
      :data="tableData"
      :columns="tableColumns"
      :loading="loading"
      :pagination="pagination"
      @page-change="handlePageChange"
      @sort-change="handleSortChange"
    >
      <!-- 状态列 -->
      <template #status="{ row }">
        <el-tag :type="stateTagType[row.status]">
          {{ handleTypeForLabel(row.status, statusOptions.value) }}
        </el-tag>
      </template>

      <!-- 操作列 -->
      <template #actions="{ row }">
        <el-button link type="primary" @click="handleEdit(row)">编辑</el-button>
        <el-button link type="danger" @click="handleDelete(row)">删除</el-button>
      </template>
    </DataTable>
  </div>
</template>

<script setup lang="ts">
import { Plus } from '@element-plus/icons-vue'
import SearchForm from '@/components/SearchForm.vue'
import DataTable from '@/components/DataTable.vue'
import { saasCmsArticleList, saasCmsArticleDelete } from '@/api/iknowSaasApi'
import type { CmsArticle, CmsArticleQueryParam } from '@/api/iknowSaasApi'
import { useCrud } from '@/hooks/useCrud'
import { useCommonSelectTypes, handleTypeForLabel } from '@/utils/selectOptions'
import { ElMessage } from 'element-plus'
import { useSimplifyPrompt } from '@/hooks/useSimplifyPrompt'
import type { SearchFormType } from '@/components/SearchForm/type'

const { statusOptions } = useCommonSelectTypes()
const stateTagType: Record<number, string> = { 0: 'danger', 1: 'success' }

const loading = ref(false)

// 搜索表单 — 字段名与 API QueryParam 一致
const searchForm = reactive<CmsArticleQueryParam>({
  keyword: '',
  status: undefined,
  pageNum: 1,
  pageSize: 20
})

// 搜索字段配置 — componentType 必须使用白名单中的值
const searchFields = computed<SearchFormType[]>(() => [
  {
    field: 'keyword',
    formItem: { label: '关键词', labelWidth: '90' },
    formItemWidth: 280,
    componentType: 'input',
    placeholder: '请输入名称'
  },
  {
    field: 'status',
    formItem: { label: '状态', labelWidth: '90' },
    formItemWidth: 280,
    componentType: 'select',
    placeholder: '请选择状态',
    selectOptions: statusOptions.value
  }
])

// 表格列 — prop 与 API 返回字段一致
const tableColumns = [
  { prop: 'id', label: 'ID', width: 80 },
  { prop: '{module}Name', label: '名称', sortable: true },
  { prop: 'status', label: '状态', slot: 'status' },
  { prop: 'createTime', label: '创建时间', width: 180 },
  { prop: 'actions', label: '操作', width: 150, slot: 'actions', fixed: 'right' }
]

const tableData = ref<CmsArticle[]>([])
const pagination = reactive({
  total: 0,
  pageNum: 1,
  pageSize: 20
})

// 查询列表
const fetchList = async () => {
  loading.value = true
  try {
    const res = await saasCmsArticleList(searchForm)
    tableData.value = res.data?.results || []
    pagination.total = res.data?.total || 0
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  searchForm.pageNum = 1
  fetchList()
}

const handleReset = () => {
  searchForm.keyword = ''
  searchForm.status = undefined
  handleSearch()
}

const handlePageChange = (page: number, size: number) => {
  searchForm.pageNum = page
  searchForm.pageSize = size
  fetchList()
}

const handleSortChange = ({ prop, order }: { prop: string; order: string }) => {
  fetchList()
}

const handleAdd = () => {
  router.push(`/iknow/saas/cms/articleOperator/add`)
}

const handleEdit = (row: CmsArticle) => {
  router.push(`/iknow/saas/cms/articleOperator/edit/${row.id}`)
}

const { handleSimplifyPrompt } = useSimplifyPrompt()
const handleDelete = async (row: CmsArticle) => {
  await handleSimplifyPrompt(`确认删除该记录？`)
  await saasCmsArticleDelete(row.id)
  ElMessage.success('删除成功')
  fetchList()
}

useActivated(fetchList)
</script>

<style scoped>
.page-container {
  padding: 20px;
}
.operation-bar {
  margin: 16px 0;
}
</style>
```

## 表单页模板 (save.vue / operator/index.vue)

```vue
<!-- src/pages/{module}/{role}/{featureOperator}/index.vue -->
<template>
  <div class="page-container">
    <el-card class="form-card">
      <template #header>
        <span>{{ isEdit ? '编辑' : '新增' }}</span>
      </template>

      <el-form
        ref="formRef"
        :model="formData"
        :rules="formRules"
        label-width="120px"
      >
        <!-- 表单字段 — 字段名与 API Schema 一致 -->
        <el-form-item label="名称" prop="{module}Name">
          <el-input v-model="formData.{module}Name" placeholder="请输入名称" />
        </el-form-item>

        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="描述" prop="description">
          <el-input
            v-model="formData.description"
            type="textarea"
            :rows="4"
            placeholder="请输入描述"
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleSubmit">保存</el-button>
          <el-button @click="handleCancel">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { saasCmsArticleLoad, saasCmsArticleSave } from '@/api/iknowSaasApi'
import type { CmsArticle, CmsArticleForm } from '@/api/iknowSaasApi'

const route = useRoute()
const router = useRouter()
const formRef = ref<FormInstance>()

const isEdit = ref(false)
const id = ref<number>()

// 表单数据 — 字段名与 API Schema 一致
const formData = reactive<CmsArticleForm>({
  id: undefined,
  {module}Name: '',
  status: 1,
  description: ''
})

// 表单校验规则 — 内联写法
const formRules: FormRules = {
  {module}Name: [
    { required: true, message: '请输入名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度2-50个字符', trigger: 'blur' }
  ],
  status: [
    { required: true, message: '请选择状态', trigger: 'change' }
  ]
}

const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate()

  await saasCmsArticleSave(formData)
  ElMessage.success('保存成功')
  router.back()
}

const handleCancel = () => {
  router.back()
}

const loadDetail = async (detailId: number) => {
  const res = await saasCmsArticleLoad({ id: detailId })
  if (res.data) Object.assign(formData, res.data)
}

// 动态路由 :type 参数判断新增/编辑
const initPage = () => {
  const type = route.params.type
  if (type === 'edit') {
    const queryId = route.query.id
    if (queryId) {
      isEdit.value = true
      id.value = Number(queryId)
      loadDetail(id.value)
    }
  }
}

useActivated(initPage)
</script>

<style scoped>
.page-container {
  padding: 20px;
}
.form-card {
  max-width: 800px;
}
</style>
```

## 详情页模板 (Detail.vue)

```vue
<!-- src/pages/{module}/{role}/{feature}/detail.vue -->
<template>
  <div class="page-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>详情</span>
          <el-button @click="handleBack">返回</el-button>
        </div>
      </template>

      <el-descriptions :column="2" border>
        <el-descriptions-item label="ID">{{ detail.id }}</el-descriptions-item>
        <el-descriptions-item label="名称">{{ detail.{module}Name }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="stateTagType[detail.status]">
            {{ handleTypeForLabel(detail.status, statusOptions.value) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detail.createTime }}</el-descriptions-item>
        <el-descriptions-item label="描述" :span="2">{{ detail.description }}</el-descriptions-item>
      </el-descriptions>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { saasCmsArticleLoad } from '@/api/iknowSaasApi'
import type { CmsArticle } from '@/api/iknowSaasApi'
import { useCommonSelectTypes, handleTypeForLabel } from '@/utils/selectOptions'

const { statusOptions } = useCommonSelectTypes()
const stateTagType: Record<number, string> = { 0: 'danger', 1: 'success' }

const route = useRoute()
const router = useRouter()

const detail = ref<Partial<CmsArticle>>({})

const loadDetail = async () => {
  const id = route.params.id
  if (!id) return

  const res = await saasCmsArticleLoad({ id: Number(id) })
  detail.value = res.data ?? {}
}

const handleBack = () => {
  router.back()
}

useActivated(loadDetail)
</script>

<style scoped>
.page-container {
  padding: 20px;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
```

---

## 路由配置模板

> 模板框架使用 appMenu 动态菜单系统控制权限，路由 meta 不需要 roles 字段。

```typescript
// src/router/iknowRouter.ts
import type { RouteRecordRaw } from 'vue-router'

const RouterList: RouteRecordRaw[] = [
  {
    path: '/iknow/saas/dashboard',
    name: 'iknow.saasDashboard',
    component: () => import('@/pages/iknow/saas/dashboard/index.vue'),
    meta: { title: '数据概览' }
  },
  {
    path: '/iknow/saas/cms/article',
    name: 'iknow.saasCmsArticle',
    component: () => import('@/pages/iknow/saas/cms/article/index.vue'),
    meta: { title: '文章管理' }
  },
  {
    path: '/iknow/saas/cms/articleOperator/:type',
    name: 'iknow.saasCmsArticleOperator',
    component: () => import('@/pages/iknow/saas/cms/articleOperator/index.vue'),
    meta: { title: '文章编辑', dynamicRoute: '/iknow/saas/cms/articleOperator', isOwnHand: true }
  }
]

export default RouterList
```

---

## 类型安全示例

### 状态标签映射

```typescript
// ✅ 使用 useCommonSelectTypes 集中管理，禁止页面内定义
const { statusOptions, articleStateOptions } = useCommonSelectTypes()

// ✅ 类型安全的标签类型映射
const stateTagType: Record<number, string> = {
  0: 'danger',    // 禁用
  1: 'success',   // 启用
}

// 模板中直接使用
// <el-tag :type="stateTagType[row.status]">
//   {{ handleTypeForLabel(row.status, statusOptions.value) }}
// </el-tag>
```

### 状态值选项

```typescript
// ✅ 对照 API interface 确认类型后使用 number
// API interface: articleState?: number
const articleStateOptions = computed(() => [
  { label: '草稿', value: 0 },
  { label: '已发布', value: 1 },
  { label: '待审核', value: 2 },
  { label: '已下架', value: 3 },
])

// ❌ 禁止：使用 string 值（与 API interface number 类型不匹配）
// const articleStateOptions = [
//   { label: '草稿', value: 'draft' },
// ]
```

### SearchForm 搜索表单配置

```typescript
// ✅ 使用白名单中的 componentType
const searchFormConfig = computed<SearchFormType[]>(() => [
  {
    field: 'articleTitle',
    formItem: { label: '文章标题', labelWidth: '90' },
    formItemWidth: 280,
    componentType: 'input',        // ✅ 白名单
    placeholder: '请输入文章标题',
  },
  {
    field: 'articleState',
    formItem: { label: '状态', labelWidth: '90' },
    formItemWidth: 280,
    componentType: 'select',        // ✅ 白名单
    placeholder: '请选择状态',
    selectOptions: articleStateOptions.value,
  },
  {
    field: 'createDateRange',
    formItem: { label: '创建时间', labelWidth: '90' },
    formItemWidth: 280,
    componentType: 'datePicker',    // ✅ 白名单（不是 'dateRange'）
    placeholder: '选择时间范围',
  },
])
```
