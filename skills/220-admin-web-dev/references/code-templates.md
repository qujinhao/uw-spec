# Web 端页面代码模板

> 以下模板展示通用模式。实际开发中，类型从 `@/api/` 的生成代码导入，API 函数也从 `@/api/` 导入。

---

## 模板变量占位符规范

> 生成代码时，按以下规则替换模板中的占位符变量。

### 变量定义表

| 占位符 | 含义 | 来源 | 示例 |
|--------|------|------|------|
| `{ProjectName}` | 项目名（PascalCase） | `project-info.md` 或目录结构 | `Iknow`、`SaasBaseApp` |
| `{projectName}` | 项目名（camelCase） | PascalCase 首字母小写 | `iknow`、`saasBaseApp` |
| `{Role}` | 角色（小写） | PRD 或页面归属 | `saas`、`mch`、`ops`、`admin`、`root` |
| `{Module}` | 模块名（PascalCase） | PRD 模块或 API 文件名 | `Cms`、`Ais`、`Base` |
| `{module}` | 模块名（camelCase） | PascalCase 首字母小写 | `cms`、`ais`、`base` |
| `{Feature}` | 功能名（PascalCase） | PRD 功能名去后缀 | `ArticleCategory`、`LinkerConfig` |
| `{feature}` | 功能名（camelCase） | PascalCase 首字母小写 | `articleCategory`、`linkerConfig` |
| `{Entity}` | 实体名（PascalCase） | API interface 名称 | `CmsCategory`、`Article` |
| `{entity}` | 实体名（camelCase） | PascalCase 首字母小写 | `cmsCategory`、`article` |
| `{ApiModule}` | API 模块前缀 | API 文件名去掉 `Api.ts` | `iknowSaas`、`saasBaseAppSaas` |
| `{ListFn}` | 列表函数名 | API 文件中 `List` 结尾的函数 | `saasCmsCategoryList` |
| `{LiteListFn}` | 轻量列表函数名 | API 文件中 `LiteList` 结尾的函数 | `saasCmsCategoryLiteList` |
| `{SaveFn}` | 保存函数名 | API 文件中 `Save` 结尾的函数 | `saasCmsCategorySave` |
| `{UpdateFn}` | 更新函数名 | API 文件中 `Update` 结尾的函数 | `saasCmsCategoryUpdate` |
| `{DeleteFn}` | 删除函数名 | API 文件中 `Delete` 结尾的函数 | `saasCmsCategoryDelete` |
| `{EnableFn}` | 启用函数名 | API 文件中 `Enable` 结尾的函数 | `saasCmsCategoryEnable` |
| `{DisableFn}` | 禁用函数名 | API 文件中 `Disable` 结尾的函数 | `saasCmsCategoryDisable` |
| `{LoadFn}` | 加载函数名 | API 文件中 `Load` 结尾的函数 | `saasCmsCategoryLoad` |
| `{ListDataHistoryFn}` | 数据历史函数名 | API 文件中 `ListDataHistory` 结尾的函数 | `saasCmsCategoryListDataHistory` |
| `{ListCritLogFn}` | 关键日志函数名 | API 文件中 `ListCritLog` 结尾的函数 | `saasCmsCategoryListCritLog` |
| `{QueryType}` | 查询参数类型 | API interface `{Entity}QueryParam` | `CmsCategoryQueryParam` |
| `{RoutePath}` | 路由 path | 见下方生成公式 | `/iknow/saas/cms/article-category` |
| `{RouteName}` | 路由 name | 见下方生成公式 | `iknow.saasCmsArticleCategory` |
| `{PermissionPrefix}` | 权限码前缀 | 与路由 path 一致 | `/iknow/saas/cms/article-category` |
| `{I18nModule}` | i18n 模块前缀 | 从 API 文件名或项目结构推断 | `iknow`、`saasBaseApp` |
| `{PageTitle}` | 页面标题 | PRD 功能名或菜单名 | `文章管理`、`分类编辑` |

### 路由生成公式

```
kebabCase(str) = 将 PascalCase/camelCase 转为短横线连接小写
  例: articleCategory → article-category

{RoutePath} = '/{projectName}/{role}/{module}/{kebabCase(feature)}'
{RouteName} = '{projectName}.{role}{Module}{Feature}'
{ComponentPath} = '@/pages/{projectName}/{role}/{module}/{feature}/index.vue'

动态路由:
  {RoutePath}Operator = '/{projectName}/{role}/{module}/{kebabCase(feature)}/:type'
  {RouteName}Operator = '{projectName}.{role}{Module}{Feature}Operator'
  meta.dynamicRoute = '/{projectName}/{role}/{module}/{kebabCase(feature)}'
```

### API 导入生成公式

```typescript
// 从 API 文件读取所有函数和类型，按以下规则导入
import {
  {ListFn},
  {SaveFn},
  {UpdateFn},
  {DeleteFn},
  {EnableFn},
  {DisableFn},
  {LoadFn},
  type {Entity},
  type {QueryType}
} from '@/api/{ApiModule}Api'
```

### useCrud 配置生成公式

```typescript
useCrud<{Entity}, {QueryType}, deleteParamsType>({
  listFn: (): Promise<ResponseData<DataList<{Entity}>>> => {
    return {ListFn}(tableConfig.queryParams)
  },
  saveFn: (): Promise<ResponseData<{Entity} | void>> => {
    return {SaveFn}(dialogConfig.dialogFormData)
  },
  updateFn: (remark?: string): Promise<ResponseData<{Entity} | void>> => {
    return {UpdateFn}(dialogConfig.dialogFormData, { remark: remark || '' })
  },
  deleteFn: (params: deleteParamsType) => {DeleteFn}(params)
}, {
  openUpdateRemark: true,
  openDeleteRemark: true
})
```

### i18n Key 生成公式

```
表单字段标签: {I18nModule}.{Entity}.{fieldName}
搜索字段标签: {I18nModule}.{QueryType}.{fieldName}

示例:
  categoryName → t('{I18nModule}.{Entity}.categoryName')
  state        → t('{I18nModule}.{QueryType}.state')
```

---

## 列表页模板 (index.vue)

```vue
<!-- src/pages/{module}/{role}/{feature}/index.vue -->
<script setup lang="ts">
import { type ComponentInternalInstance } from 'vue'
import { SearchFormType } from '@/components/SearchForm/type'
import {
  {UpdateFn},
  {EnableFn},
  {DisableFn},
  {SaveFn},
  {LoadFn},
  {LiteListFn},
  {ListFn},
  {ListDataHistoryFn},
  {ListCritLogFn},
  {DeleteFn},
  type {Entity},
  type {QueryType}
} from '@/api/{ApiModule}Api'
import { ResponseData, DataList } from '@/api/uwAuthCenterAuthApi'
import { useI18n } from 'vue-i18n'
import { useCrud } from '@/hooks/useCrud'
import { usePermissionCode } from '@/hooks/usePermissionCode'
import { useSimplifyPrompt } from '@/hooks/useSimplifyPrompt'
import { useExportExcel } from '@/hooks/useExportExcel'
import { useCommonSelectTypes } from '@/utils/selectOptions'
import { ElMessage } from 'element-plus'

// 删除接口参数类型
interface deleteParamsType {
  id: number
  remark: string
}

// 获取全局挂载的方法
const { proxy } = getCurrentInstance() as ComponentInternalInstance
const { useActivated, formatDate } = proxy as any
const { t } = useI18n()
const { handleTypeForLabel, commonTypes } = useCommonSelectTypes()

const {
  tableConfig,
  handleList,
  dialogConfig,
  dialogFormRef,
  handleResetDialog,
  handleSubmitDialog,
  handleDelete,
  handleOpenSaveDialog,
  handleOpenUpdateDialog,
} = useCrud<{Entity}, {QueryType}, deleteParamsType>({
  listFn: (): Promise<ResponseData<DataList<{Entity}>>> => {
    return {ListFn}(tableConfig.queryParams)
  },
  saveFn: (): Promise<ResponseData<{Entity} | void>> => {
    return {SaveFn}(dialogConfig.dialogFormData)
  },
  updateFn: (remark?: string): Promise<ResponseData<{Entity} | void>> => {
    return {UpdateFn}(dialogConfig.dialogFormData, { remark: remark || '' })
  },
  deleteFn: (params: deleteParamsType) => {DeleteFn}(params)
}, {
  openUpdateRemark: true,
  openDeleteRemark: true
})

// 搜索表单
const searchFormConfig = computed<SearchFormType[]>(() => {
  return [
    {
      field: 'categoryName',
      formItem: {
        label: t('{I18nModule}.{QueryType}.categoryName'),
        labelWidth: '90'
      },
      formItemWidth: 280,
      clearable: true,
      componentType: 'input',
      placeholder: t('pleaseInput') + t('{I18nModule}.{Entity}.categoryName')
    },
    {
      field: 'state',
      formItem: {
        label: t('{I18nModule}.{QueryType}.state'),
        labelWidth: '90'
      },
      formItemWidth: 280,
      clearable: true,
      componentType: 'select',
      placeholder: t('pleaseSelect') + t('{I18nModule}.{Entity}.state'),
      selectOptions: commonTypes
    }
  ]
})

// 启用（使用 useSimplifyPrompt，不直接调用 ElMessageBox）
const handleEnable = (item: {Entity}) => {
  useSimplifyPrompt({
    message: t('ManagementEnableTips'),
    confirmCallBack(remark) {
      tableConfig.tableLoading = true
      {EnableFn}({
        id: item.id!,
        remark: remark || ''
      })
        .then((res: ResponseData<{Entity}>) => {
          if (res.state === 'success') {
            ElMessage.success(t('ManagementEnableSuccessTips'))
            handleList()
          } else {
            ElMessage.error(res.msg)
          }
          tableConfig.tableLoading = false
        })
        .catch(() => {
          tableConfig.tableLoading = false
        })
    }
  })
}

// 禁用
const handleDisable = (item: {Entity}) => {
  useSimplifyPrompt({
    message: t('ManagementDisableTips'),
    confirmCallBack(remark) {
      tableConfig.tableLoading = true
      {DisableFn}({
        id: item.id!,
        remark: remark || ''
      })
        .then((res: ResponseData<{Entity}>) => {
          if (res.state === 'success') {
            ElMessage.success(t('ManagementDisableSuccessTips'))
            handleList()
          } else {
            ElMessage.error(res.msg)
          }
          tableConfig.tableLoading = false
        })
        .catch(() => {
          tableConfig.tableLoading = false
        })
    }
  })
}

// 数据历史
const queryHistoryRef = ref()
const handleHistory = (id: number) => {
  queryHistoryRef.value.openHistoryLog(id)
}
const queryHistory = (item: {Entity}) => {
  return {ListDataHistoryFn}(item)
}

// 操作日志
const queryCritLogRef = ref()
const handleCritLog = (id: number) => {
  queryCritLogRef.value.openCritLog(id)
}
const queryCritLog = (item: {Entity}) => {
  return {ListCritLogFn}(item)
}

// 导出列配置（根据实际字段调整）
const exportColumns = computed(() => {
  return [
    { field: 'id', label: 'ID' },
    { field: 'categoryName', label: t('{I18nModule}.{Entity}.categoryName') },
    { field: 'state', label: t('{I18nModule}.{Entity}.state') }
  ]
})

const { startExport } = useExportExcel()

const exportExcel = () => {
  startExport({
    url: '{RoutePath}/list',
    queryParams: tableConfig.queryParams,
    columns: exportColumns.value,
    sizeAll: tableConfig.sizeAll
  })
}

// 使用 useActivated 而非 onMounted
useActivated(() => {
  handleList()
})
</script>

<template>
<div class="flex_col">
  <div class="flex_col_header">
    <SearchForm v-model="tableConfig.queryParams" :bnt-loading="tableConfig.tableLoading" :list="searchFormConfig" @change="handleList" @search="handleList">
      <template #right>
        <el-button class="margin-left-10" type="primary" size="small" round icon="Plus" @click="handleOpenSaveDialog" v-permission="usePermissionCode('save')">
          {{ t('add') }}
        </el-button>
        <el-button @click="exportExcel" round type="success" size="small" icon="Download">
          {{ t('export') }}
        </el-button>
      </template>
    </SearchForm>
  </div>

  <!-- 使用 class 而非 style -->
  <el-table border class="width-percent-100" :header-cell-style="{
    backgroundColor: 'var(--el-color-info-light-9)'
  }" :data="tableConfig.dataList" v-loading="tableConfig.tableLoading" stripe show-overflow-tooltip class="flex_col_body">
    <el-table-column prop="id" :label="t('{I18nModule}.{Entity}.id')" align="center" />
    <el-table-column prop="categoryName" :label="t('{I18nModule}.{Entity}.categoryName')" align="center" />
    <!-- 状态列：使用 handleTypeForLabel 显示文本 -->
    <el-table-column prop="state" :label="t('{I18nModule}.{Entity}.state')" align="center" width="90">
      <template v-slot="{ row }">
        <el-link :type="row.state === 1 ? 'success' : 'danger'" :underline="false">
          {{ handleTypeForLabel(row.state, commonTypes) }}
        </el-link>
      </template>
    </el-table-column>
    <el-table-column :label="t('control')" align="center" width="220">
      <template #default="scope">
        <el-button-group v-if="scope.row.state !== -1">
          <template v-if="scope.row.state === 0">
            <el-tooltip :content="t('enable')" placement="top">
              <el-button type="success" icon="CircleCheck" size="small" v-permission="usePermissionCode('enable')" @click="handleEnable(scope.row)" />
            </el-tooltip>
          </template>
          <template v-if="scope.row.state === 1">
            <el-tooltip :content="t('disable')" placement="top">
              <el-button type="info" size="small" v-permission="usePermissionCode('disable')" @click="handleDisable(scope.row)">
                <i class="iconfont jinyong"></i>
              </el-button>
            </el-tooltip>
          </template>
          <el-tooltip :content="t('edit')" placement="top">
            <el-button type="primary" icon="Edit" size="small" v-permission="usePermissionCode('update')" @click="handleOpenUpdateDialog(scope.row)" />
          </el-tooltip>
        </el-button-group>
      </template>
    </el-table-column>
  </el-table>

  <!-- 使用 Pagination 组件，禁止 el-pagination -->
  <Pagination
    v-model:page-size="tableConfig.queryParams.$rn"
    @page-size-change="handleList"
    :total="tableConfig.sizeAll"
    v-model:current-page="tableConfig.queryParams.$pg"
    @current-change="handleList"
    class="flex_col_bottom"
  />
</div>

<!-- 新增、编辑弹窗 -->
<el-dialog v-model="dialogConfig.dialogShow" :title="dialogConfig.dialogTitle" destroy-on-close @close="handleResetDialog" draggable :close-on-click-modal="false">
  <div v-loading="dialogConfig.dialogLoading">
    <el-form ref="dialogFormRef" :model="dialogConfig.dialogFormData" label-width="120px" status-icon>
      <el-row>
        <!-- 内联表单验证写法 -->
        <el-col :span="20">
          <el-form-item :label="t('{I18nModule}.{Entity}.categoryName')" prop="categoryName"
            :rules="[{ required: true, message: t('pleaseInput') + t('{I18nModule}.{Entity}.categoryName') }]">
            <!-- 所有表单控件必须有 placeholder -->
            <el-input v-model="dialogConfig.dialogFormData.categoryName" :placeholder="t('pleaseInput') + t('{I18nModule}.{Entity}.categoryName')" maxlength="50" clearable />
          </el-form-item>
        </el-col>
        <el-col :span="20">
          <el-form-item :label="t('{I18nModule}.{Entity}.categoryDesc')" prop="categoryDesc">
            <el-input type="textarea" v-model="dialogConfig.dialogFormData.categoryDesc" :placeholder="t('pleaseInput') + t('{I18nModule}.{Entity}.categoryDesc')" :rows="3" clearable />
          </el-form-item>
        </el-col>
      </el-row>
    </el-form>
  </div>
  <!-- 弹窗按钮：取消在左（Close），保存在右（Check） -->
  <template #footer>
    <el-button @click="dialogConfig.dialogShow = false" icon="Close">{{ t('cancel') }}</el-button>
    <el-button type="primary" @click="handleSubmitDialog" :loading="dialogConfig.dialogLoading" icon="Check">
      {{ dialogConfig.dialogType === 0 ? t('add') : t('edit') }}
    </el-button>
  </template>
</el-dialog>

<!-- 修改历史 -->
<HistoryLog
  ref="queryHistoryRef"
  v-model:showDetail="dialogConfig.dialogShow"
  v-model:detailDialogForm="dialogConfig.dialogFormData"
  v-model:dialogType="dialogConfig.dialogType"
  v-model:dialogTitle="dialogConfig.dialogTitle"
  width="1200px"
  :queryHistory="queryHistory"
/>
<!-- 关键日志 -->
<CritLog
  ref="queryCritLogRef"
  v-model:showDetail="dialogConfig.dialogShow"
  v-model:detailDialogForm="dialogConfig.dialogFormData"
  v-model:dialogType="dialogConfig.dialogType"
  v-model:dialogTitle="dialogConfig.dialogTitle"
  width="1400px"
  :queryCritLog="queryCritLog"
  :showPage="true"
/>
</template>

<!-- 使用 CSS 类替代内联样式 -->
<style lang="scss" scoped>
.width-percent-100 {
  width: 100%;
}
</style>
```

## 表单页模板 (Operator / 新增+编辑+详情三合一)

```vue
<!-- src/pages/{module}/{role}/{featureOperator}/index.vue -->
<script setup lang="ts">
import { type ComponentInternalInstance} from 'vue'
import { ElMessage, FormInstance } from 'element-plus'
import { useSimplifyPrompt } from '@/hooks/useSimplifyPrompt'
import { useCommonSelectTypes } from '@/utils/selectOptions'
import { useMainStore } from '@/store/main'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const { commonTypes, handleTypeForLabel } = useCommonSelectTypes()
const { proxy } = getCurrentInstance() as ComponentInternalInstance
const { formatDate } = proxy as any

const formData = ref<{Entity}>({})
const currentId = ref<number>()

// 操作类型：add 新增 / edit 编辑 / detail 详情
const operatorType = computed(() => {
  return route.params.type || ''
})

const loading = ref(false)
const formRef = ref<FormInstance>()
const mainStore = useMainStore()

// 加载数据
const loadData = () => {
  if (currentId.value) {
    loading.value = true
    {LoadFn}({ id: currentId.value })
      .then(res => {
        if (res.state === 'success') {
          formData.value = { ...res.data }
          // 处理表单数据，例如转换日期格式、格式化文本内容等等等
          handleDataFeedBack()
        } else {
          ElMessage.error(res.msg)
        }
        loading.value = false
      })
      .catch(() => { loading.value = false })
  }
}

// 数据回显转换层：后端格式 → 前端组件期望格式
// 以下示例按需裁剪，遵循"遇到不一致才转换"原则
const handleDataFeedBack = () => {
  // 示例：后端返回时间戳字符串，前端组件需要 Date 对象
  // 实际需要自己手动开发，根据实际情况调整
  if (formData.value.publishTime) {
    formData.value.publishTime = new Date(formData.value.publishTime) as any
  }

  // 示例：后端返回逗号分隔字符串，前端组件需要数组
  if (typeof formData.value.tags === 'string') {
    formData.value.tags = (formData.value.tags as string).split(',') as any
  }

  // 示例：后端返回 0/1，前端 switch/radio 需要 boolean
  if (formData.value.isTop !== undefined) {
    formData.value.isTop = Boolean(formData.value.isTop) as any
  }
}

// 保存/更新
const handleConfirm = () => {
  if (!formRef.value) return
  formRef.value.validate(valid => {
    if (valid) {
      const data = handleSubmitData()
      if (operatorType.value === 'add') {
        handleSave(data)
      } else if (operatorType.value === 'edit') {
        handleUpdate(data)
      }
    }
  })
}

// 数据提交转换层：前端组件格式 → 后端期望格式
// 必须与 handleDataFeedBack 的转换逻辑一一对应，确保往返一致
const handleSubmitData = () => {
  // 实际需要自己手动开发，根据实际情况调整
  const data = { ...formData.value }

  // 示例：Date 对象转回 ISO 字符串或时间戳
  if (data.publishTime instanceof Date) {
    data.publishTime = data.publishTime.toISOString() as any
  }

  // 示例：数组转回逗号分隔字符串
  if (Array.isArray(data.tags)) {
    data.tags = (data.tags as string[]).join(',') as any
  }

  // 示例：boolean 转回 0/1
  if (typeof data.isTop === 'boolean') {
    data.isTop = (data.isTop ? 1 : 0) as any
  }

  // 示例：删除后端不需要的字段
  delete (data as any).createTime
  delete (data as any).updateTime

  return data
}

// 保存方法
const handleSave = (data: {Entity}) => {
  loading.value = true
  // 调用保存接口进行保存
  {SaveFn}(data)
    .then(res => {
      if (res.state === 'success') {
        ElMessage.success(res.msg)
        // 关闭页面，返回上一页
        toCancel()
      } else {
        ElMessage.error(res.msg)
      }
      loading.value = false
    })
    .catch(() => { loading.value = false })
}

// 更新方法
const handleUpdate = (data: {Entity}) => {
  useSimplifyPrompt({
     message: t('pleaseInputRemark'),
     confirmCallBack(remark) {
        // 调用更新接口进行保存
         loading.value = true
        // 调用保存接口进行保存
        {UpdateFn}(data, {
          remark: remark || ''
        })
          .then(res => {
            if (res.state === 'success') {
              ElMessage.success(res.msg)
              // 关闭页面，返回上一页
              toCancel()
            } else {
              ElMessage.error(res.msg)
            }
            loading.value = false
          }).catch(() => { 
            loading.value = false 
          })
        }
  })
}

// 返回页面
const toCancel = () => {
  // 如需关闭页签并返回指定页面，参考以下写法：
  // const pagesTab = mainStore.pageTabs
  // const currentTabIndex = pagesTab.findIndex(item => {
  //   return item.name && item.name === route.name
  // })
  // mainStore.singleDeletePageTabs(
  //   currentTabIndex,
  //   '/返回路径'
  // )
}

// 清除数据
const clearFormData = () => {
  formData.value = {}
  currentId.value = undefined
  // 其他重置操作，例如清空下拉选择框的值等
}


onActivated(() => {
  currentId.value = route.query.id ? Number(route.query.id) : 0
  if (operatorType.value === 'detail' || operatorType.value === 'edit') {
    loadData()
  }
})

onDeactivated(() => {
  // 组件卸载时，重置表单数据
  clearFormData()
})
</script>

<template>
  <div>
    <el-form
      label-width="120px"
      label-position="right"
      :model="formData"
      ref="formRef"
      :disabled="operatorType === 'detail'"
      v-loading="loading"
    >
      <TitleHeader :title="t('basicInfo')" />
      <!-- 以下表单项要符合实际业务需求进行开发，这里只对相关表单做出示例代码 -->
      <el-row>
        <el-col :span="10">
          <!-- 文本输入框示例 -->
          <el-form-item
            :label="t('{I18nModule}.{Entity}.fieldName')"
            prop="fieldName"
            :rules="[{ required: true, message: t('pleaseInput') + t('{I18nModule}.{Entity}.fieldName') }]"
          >
            <el-input 
              v-model="formData.fieldName" 
              :placeholder="t('pleaseInput') + t('{I18nModule}.{Entity}.fieldName')" 
            />
          </el-form-item>
        </el-col>
        <el-col :span="10">
          <!-- 下拉选择框示例 -->
          <el-form-item
            :label="t('{I18nModule}.{Entity}.status')"
            prop="status"
            :rules="[{ required: true, message: t('pleaseSelect') + t('{I18nModule}.{Entity}.status') }]"
          >
            <el-select v-model="formData.status" :placeholder="t('pleaseSelect') + t('{I18nModule}.{Entity}.status')">
              <el-option
                v-for="item in commonTypes"
                :key="item.value"
                :value="item.value"
                :label="item.label"
              />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-row>
        <el-col :span="20">
          <!-- 文本域示例 -->
          <el-form-item :label="t('{I18nModule}.{Entity}.description')" prop="description">
            <el-input
              v-model="formData.description"
              type="textarea"
              :autosize="{ minRows: 4 }"
              :placeholder="t('pleaseInput') + t('{I18nModule}.{Entity}.description')"
            />
          </el-form-item>
        </el-col>
      </el-row>
       <el-row>
        <el-col :span="20">
          <!-- 底部操作按钮 -->
            <div class="flex-center" v-if="operatorType !== 'detail'">
              <el-button @click="toCancel" icon="Close">{{ t('cancel') }}</el-button>
              <el-button type="primary" @click="handleConfirm" :loading="loading" icon="Check">
                {{ operatorType === 'edit' ? t('save') : t('add') }}
              </el-button>
            </div>
          </el-form-item>
        </el-col>
      </el-row>
    </el-form>
   
  </div>
</template>

<style lang="scss" scoped>
</style>
```

---

## 表单字段组件映射规范

AI 根据原型或 PRD 描述，按以下规则映射为具体表单组件：

| 原型描述关键词 | 组件 | 示例属性 |
|-------------|------|---------|
| 文本 / 名称 / 标题 / 编码 | `el-input` | `v-model="formData.xxx" placeholder="t('pleaseInput')"` |
| 多行文本 / 描述 / 备注 | `el-input type="textarea"` | `type="textarea" :rows="4" :placeholder="t('pleaseInput')"` |
| 数字 / 金额 / 数量 | `el-input-number` | `v-model="formData.xxx"  :placeholder="t('pleaseInput')"` |
| 下拉 / 选择 / 状态 / 类型 | `el-select` | `<el-option v-for="item in xxxOptions" />` | `v-model="formData.xxx"  :placeholder="t('pleaseSelect')"` |
| 单选 / 是否 / 开关 | `el-radio-group` / `el-switch` | `<el-radio :label="1">是</el-radio>` | `v-model="formData.xxx"  :placeholder="t('pleaseSelect')"` |
| 日期 | `el-date-picker` | `type="date"` | `v-model="formData.xxx"  :placeholder="t('pleaseSelect')"` |
| 日期时间 | `el-date-picker` | `type="datetime"` | `v-model="formData.xxx"  :placeholder="t('pleaseSelect')" value-format="yyyy-MM-DD HH:mm:ss"` |
| 日期范围 | `el-date-picker` | `type="daterange"` | `v-model="formData.xxx"  :placeholder="t('pleaseSelect')" value-format="yyyy-MM-DD HH:mm:ss"` |
| 文件 / 图片 / 上传 | `UploadFile` | 专用组件，详见下方说明 |
| 富文本 / 编辑器 | `RichTextEditor` | 专用组件，详见下方说明 |
| 手机号 | `el-input` | `maxlength="11"` |
| 邮箱 | `el-input` | 配合 `rules` 邮箱验证 |

### 字段命名规则

- **必须与 API Schema 字段名保持一致**（camelCase）
- 禁止根据中文语义猜测，必须从 `@/api/` 的类型定义中获取

### 验证规则映射

| 原型描述 | 规则 |
|---------|------|
| 必填 / 不能为空 | `:rules="[{ required: true, message: t('pleaseInput') + t('xxx') }]"` |
| 长度限制 | `{ min: 2, max: 50, message: '长度2-50个字符', trigger: 'blur' }` |
| 手机号 | 内置正则或自定义 validator |
| 邮箱 | 内置 `type: 'email'` |
| 数字范围 | `el-input-number` 的 `:min` / `:max` |

### 布局规则

| 场景 | 布局 |
|------|------|
| 2 列并排 | `<el-col :span="10">`（左右间距通过 `el-row` 自动处理） |
| 1 列占满 | `<el-col :span="20">` |
| 按钮区域 | 放在 `el-form` **外部**，使用 `form-footer` 类居中 |

### 专用组件说明

#### UploadFile（文件上传）

**组件路径**：`src/components/UploadFile/index.vue`
**类型定义**：`src/components/UploadFile/type.ts`

**常用 Props**：

| Prop | 类型 | 说明 |
|------|------|------|
| `fileListForShow` | `UploadUserFile[]` | 展示的文件列表 |
| `fileListForUpload` | `uploadFileUrl[]` | 实际上传的文件列表 |
| `listType` | `'text' \| 'picture-card'` | 展示类型，默认 `picture-card` |
| `multiple` | `boolean` | 是否多选 |
| `accept` | `string` | 接收的文件格式 |
| `limit` | `number` | 限制上传数量 |
| `autoUpload` | `boolean` | 是否自动上传 |
| `disabled` | `boolean` | 是否禁用 |
| `accessType` | `0 \| 1` | 访问类型，0 公共 / 1 隐私 |
| `uploadParams` | `uploadParamsType` | 上传附带参数（`objectType` / `objectId`） |
| `itemWidth` | `string \| number` | 照片项宽度 |
| `itemHeight` | `string \| number` | 照片项高度 |

**暴露方法**（通过 `ref` 调用）：

| 方法 | 说明 |
|------|------|
| `clearFiles()` | 清除组件缓存，重置状态 |
| `handleUpdateRefId(refId?)` | 更新文件引用的 refID，保存后调用 |
| `handleUnLinkFile()` | 解除文件关联 |
| `fileListToJsonMap()` | 将文件数组转为 JSON Map 格式提交 |

**使用示例**：

```vue
<template>
    <UploadFile
      ref="uploadRef"
      v-model:fileListForShow="fileListShow"
      v-model:fileListForUpload="fileListUpload"
      :accept="acceptKeys"
      :multiple="true"
      :item-width="100"
      :item-height="100"
      :limit="2"
      :uploadParams="uploadParams"
    />
</template>

<script setup>
import { type UploadUserFile } from 'element-plus'
import { uploadFileUrl, uploadFileExposeMethods } from '@/components/UploadFile/type'

const uploadRef = ref<uploadFileExposeMethods>()
const fileListShow = ref<UploadUserFile[]>([])
const fileListUpload = ref<uploadFileUrl[]>([])
// 接收的文件类型
const acceptKeys = '.jpeg,.jpg,.png,.gif'
// 上传附带参数
const uploadParams = ref({
  objectType: 'EntityName', // 实体表名
  objectId: 0 // 上传到的表 ID  eg: 新增时为0，编辑时为实体ID
})

// 验证是否上传
const validateImg = (rule, value, callback) => {
  if (fileListUpload.value?.length) {
    callback()
  } else {
    callback(new Error('请上传文件'))
  }
}

// 保存时调用
const handleSave = () => {
  // 接口保存成功后才调用  编辑成功后也要调用
  uploadRef.value?.handleUpdateRefId(formData.value.id)
  uploadRef.value?.handleUnLinkFile()
}

// 弹窗关闭时清除缓存
const resetCatch = () => {
  fileListShow.value = []
  fileListUpload.value = []
}

</script>
```

#### RichTextEditor（富文本编辑器）

**组件路径**：`src/components/RichTextEditor/index.vue`
**类型定义**：`src/components/RichTextEditor/type.ts`

**常用 Props**：

| Prop | 类型 | 说明 |
|------|------|------|
| `ricText` | `string` | 显示内容文本 |
| `width` | `string \| number` | 编辑器宽度 |
| `height` | `string \| number` | 编辑器高度 |
| `objectId` | `string \| number` | 文件上传到的表 ID |
| `objectType` | `string` | 文件上传到的表名（必填） |
| `editorId` | `string \| number` | 编辑器唯一 ID（必填，同一页面多个编辑器需不同 ID） |
| `disabled` | `boolean` | 是否禁用 |
| `accessType` | `0 \| 1` | 访问类型，0 公共 / 1 隐私 |
| `placeholder` | `string` | 占位提示文本 |

**暴露方法**（通过 `ref` 调用）：

| 方法 | 说明 |
|------|------|
| `clearCatch()` | 清除缓存 |
| `handleUpdateRefId(refId)` | 更新关联 ID，保存后调用 |
| `handleUnLinkFile()` | 解除文件关联 |

**使用示例**：

```vue
<template>
    <RichTextEditor
      ref="editorRef"
      v-model:ric-text="formData.content"
      :object-type="uploadParams.objectType"
      :object-id="uploadParams.objectId"
      :editorId="`notice_content`"
      :placeholder="t('pleaseInput') + t('content')"
    />
</template>

<script setup>
import { richTextEditorExposeMethods } from '@/components/RichTextEditor/type'

const editorRef = ref<richTextEditorExposeMethods>()
// 上传参数
const uploadParams = ref({
  objectType: 'SysNotice', // 实体表名
  objectId: 0 // 上传到的表 ID  eg: 新增时为0，编辑时为实体ID
})

// 弹窗关闭时清除缓存
const resetForm = () => {
  editorRef.value?.clearCatch()
  editorRef.value = undefined
}

// 保存时调用
const handleSave = () => {
  // 接口保存成功后才调用, 更新关联 ID. 编辑成功后也要调用
  editorRef.value?.handleUpdateRefId(formData.value.id)
  editorRef.value?.handleUnLinkFile()
}
</script>
```

> **重要**：AI 生成表单时，应根据原型中的字段类型描述，优先从上述映射表查找对应组件，不得随意使用不在表中的组件。

## 详情页模板 ({feature}Detail/index.vue)

```vue
<!-- src/pages/{module}/{role}/{feature}Detail/index.vue -->
<script setup lang="ts">
import { type ComponentInternalInstance} from 'vue'
import { ElMessage, FormInstance } from 'element-plus'
import { useSimplifyPrompt } from '@/hooks/useSimplifyPrompt'
import { useCommonSelectTypes } from '@/utils/selectOptions'
import { useMainStore } from '@/store/main'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const { commonTypes, handleTypeForLabel } = useCommonSelectTypes()
const { proxy } = getCurrentInstance() as ComponentInternalInstance
const { formatDate } = proxy as any

const formData = ref<{Entity}>({})
const currentId = ref<number>()

const loading = ref(false)
const formRef = ref<FormInstance>()
const mainStore = useMainStore()

// 加载数据
const loadData = () => {
  if (currentId.value) {
    loading.value = true
    {LoadFn}({ id: currentId.value })
      .then(res => {
        if (res.state === 'success') {
          formData.value = { ...res.data }
          // 处理表单数据，例如转换日期格式、格式化文本内容等等等
          handleDataFeedBack()
        } else {
          ElMessage.error(res.msg)
        }
        loading.value = false
      })
      .catch(() => { loading.value = false })
  }
}

// 数据回显转换层：后端格式 → 前端组件期望格式
// 以下示例按需裁剪，遵循"遇到不一致才转换"原则
const handleDataFeedBack = () => {
  // 示例：后端返回时间戳字符串，前端组件需要 Date 对象
  // 实际需要自己手动开发，根据实际情况调整
  if (formData.value.publishTime) {
    formData.value.publishTime = new Date(formData.value.publishTime) as any
  }

  // 示例：后端返回逗号分隔字符串，前端组件需要数组
  if (typeof formData.value.tags === 'string') {
    formData.value.tags = (formData.value.tags as string).split(',') as any
  }

  // 示例：后端返回 0/1，前端 switch/radio 需要 boolean
  if (formData.value.isTop !== undefined) {
    formData.value.isTop = Boolean(formData.value.isTop) as any
  }
}

// 清除数据
const clearFormData = () => {
  formData.value = {}
  currentId.value = undefined
  // 其他重置操作，例如清空下拉选择框的值等
}


onActivated(() => {
  currentId.value = route.query.id ? Number(route.query.id) : 0
  loadData()
})

onDeactivated(() => {
  // 组件卸载时，重置表单数据
  clearFormData()
})
</script>

<template>
  <div>
    <el-form
      label-width="120px"
      label-position="right"
      :model="formData"
      ref="formRef"
      :disabled="true"
      v-loading="loading"
    >
      <TitleHeader :title="t('basicInfo')" />
      <!-- 以下表单项要符合实际业务需求进行开发，这里只对相关表单做出示例代码 -->
      <el-row>
        <el-col :span="10">
          <!-- 文本输入框示例 -->
          <el-form-item
            :label="t('{I18nModule}.{Entity}.fieldName')"
            prop="fieldName"
          >
            <el-input 
              v-model="formData.fieldName" 
              :placeholder="t('pleaseInput') + t('{I18nModule}.{Entity}.fieldName')" 
            />
          </el-form-item>
        </el-col>
        <el-col :span="10">
          <!-- 下拉选择框示例 -->
          <el-form-item
            :label="t('{I18nModule}.{Entity}.status')"
            prop="status"
          >
            <el-select v-model="formData.status" :placeholder="t('pleaseSelect') + t('{I18nModule}.{Entity}.status')">
              <el-option
                v-for="item in commonTypes"
                :key="item.value"
                :value="item.value"
                :label="item.label"
              />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-row>
        <el-col :span="20">
          <!-- 文本域示例 -->
          <el-form-item :label="t('{I18nModule}.{Entity}.description')" prop="description">
            <el-input
              v-model="formData.description"
              type="textarea"
              :autosize="{ minRows: 4 }"
              :placeholder="t('pleaseInput') + t('{I18nModule}.{Entity}.description')"
            />
          </el-form-item>
        </el-col>
      </el-row>
    </el-form>
  </div>
</template>

<style lang="scss" scoped>
</style>
```

---

## 路由配置模板

> 模板框架使用 appMenu 动态菜单系统控制权限，路由 meta 不需要 roles 字段。

```typescript
// src/router/iknowRouter.ts
import type { RouteRecordRaw } from 'vue-router'

const RouterList: RouteRecordRaw[] = [
  // 列表页
  {
    path: '{RoutePath}',
    name: '{RouteName}',
    component: () => import('{ComponentPath}'),
    meta: { title: '{PageTitle}' }
  },
  // 表单页（Operator）
  {
    path: '{RoutePath}Operator/:type',
    name: '{RouteName}Operator',
    component: () => import('@/pages/{projectName}/{role}/{module}/{feature}Operator/index.vue'),
    meta: { title: '{PageTitle}Operator', dynamicRoute: '{RoutePath}Operator', isOwnHand: true }
  },
  // 详情页（Detail）
  {
    path: '{RoutePath}Detail/:id',
    name: '{RouteName}Detail',
    component: () => import('@/pages/{projectName}/{role}/{module}/{feature}Detail/index.vue'),
    meta: { title: '{PageTitle}Detail', dynamicRoute: '{RoutePath}Detail', isOwnHand: true }
  },
]

export default RouterList
```

