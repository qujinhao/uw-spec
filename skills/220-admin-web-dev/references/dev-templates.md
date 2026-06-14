# Vue3 开发模板

> ⚠️ 本模板遵循 iknow-saas-web 项目规范。请严格按照模板编写代码。

## 页面模板（标准CRUD列表页）

### 关键规范速查

| 规范 | 要求 |
|------|------|
| 自动导入 | `ref`、`reactive`、`computed`、`onMounted`、`onActivated` 等不需要手动导入 |
| 类型导入 | 使用 `type` 关键字标记类型：`import { type AiConfig, saasAiConfigList }` |
| 枚举管理 | 所有选项/状态映射统一到 `selectOptions.ts`，不在页面内定义 |
| 内联样式 | 禁止使用 `style="..."` ，使用 CSS 类替代 |
| v-for 变量 | 禁止单字母变量名，使用 `item`、`option`、`sourceItem` 等 |
| 确认弹窗 | 使用 `usePrompt` / `useSimplifyPrompt`，禁止直接调用 `ElMessageBox` |
| 生命周期 | 列表页使用 `useActivated` 而非 `onMounted` |
| 分页组件 | 使用 `Pagination` 组件，禁止使用 `el-pagination` |
| API 响应类型 | `.then((res: ResponseData<Xxx>)` 中 `res` 必须声明类型 |
| placeholder | 所有表单控件必须包含 `placeholder` 属性 |
| 弹窗按钮 | 取消在左（icon="Close"），保存在右（icon="Check"） |

### 完整页面模板

```vue
<script setup lang="ts">
import { type ComponentInternalInstance } from 'vue'
import { SearchFormType } from '@/components/SearchForm/type'
import {
  saasCmsCategoryUpdate,
  saasCmsCategoryEnable,
  saasCmsCategoryDisable,
  saasCmsCategorySave,
  saasCmsCategoryLoad,
  saasCmsCategoryLiteList,
  saasCmsCategoryList,
  saasCmsCategoryListDataHistory,
  saasCmsCategoryListCritLog,
  saasCmsCategoryDelete,
  type CmsCategory,
  type CmsCategoryQueryParam
} from '@/api/iknowSaasApi'
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
} = useCrud<CmsCategory, CmsCategoryQueryParam, deleteParamsType>({
  listFn: (): Promise<ResponseData<DataList<CmsCategory>>> => {
    return saasCmsCategoryList(tableConfig.queryParams)
  },
  saveFn: (): Promise<ResponseData<CmsCategory | void>> => {
    return saasCmsCategorySave(dialogConfig.dialogFormData)
  },
  updateFn: (remark?: string): Promise<ResponseData<CmsCategory | void>> => {
    return saasCmsCategoryUpdate(dialogConfig.dialogFormData, { remark: remark || '' })
  },
  deleteFn: (params: deleteParamsType) => saasCmsCategoryDelete(params)
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
        label: t('iknow.CmsCategoryQueryParam.categoryName'),
        labelWidth: '90'
      },
      formItemWidth: 280,
      clearable: true,
      componentType: 'input',
      placeholder: t('pleaseInput') + t('iknow.CmsCategory.categoryName')
    },
    {
      field: 'state',
      formItem: {
        label: t('iknow.CmsCategoryQueryParam.state'),
        labelWidth: '90'
      },
      formItemWidth: 280,
      clearable: true,
      componentType: 'select',
      placeholder: t('pleaseSelect') + t('iknow.CmsCategory.state'),
      selectOptions: commonTypes
    }
  ]
})

// 启用（使用 useSimplifyPrompt，不直接调用 ElMessageBox）
const handleEnable = (item: CmsCategory) => {
  useSimplifyPrompt({
    message: t('ManagementEnableTips'),
    confirmCallBack(remark) {
      tableConfig.tableLoading = true
      saasCmsCategoryEnable({
        id: item.id!,
        remark: remark || ''
      })
        .then((res: ResponseData<CmsCategory>) => {
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
const handleDisable = (item: CmsCategory) => {
  useSimplifyPrompt({
    message: t('ManagementDisableTips'),
    confirmCallBack(remark) {
      tableConfig.tableLoading = true
      saasCmsCategoryDisable({
        id: item.id!,
        remark: remark || ''
      })
        .then((res: ResponseData<CmsCategory>) => {
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
const queryHistory = (item: CmsCategory) => {
  return saasCmsCategoryListDataHistory(item)
}

// 操作日志
const queryCritLogRef = ref()
const handleCritLog = (id: number) => {
  queryCritLogRef.value.openCritLog(id)
}
const queryCritLog = (item: CmsCategory) => {
  return saasCmsCategoryListCritLog(item)
}

// 导出列配置
const exportColumns = computed(() => {
  return [
    { field: 'id', label: 'ID' },
    { field: 'categoryName', label: '分类名称' },
    { field: 'state', label: '状态' }
  ]
})

const { startExport } = useExportExcel()

const exportExcel = () => {
  startExport({
    url: '/iknow/saas/cms/category/list',
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
    <el-table-column prop="id" :label="t('iknow.CmsCategory.id')" align="center" />
    <el-table-column prop="categoryName" :label="t('iknow.CmsCategory.categoryName')" align="center" />
    <!-- 状态列：使用 handleTypeForLabel 显示文本 -->
    <el-table-column prop="state" :label="t('iknow.CmsCategory.state')" align="center" width="90">
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
          <el-form-item :label="t('iknow.CmsCategory.categoryName')" prop="categoryName"
            :rules="[{ required: true, message: t('pleaseInput') + t('iknow.CmsCategory.categoryName') }]">
            <!-- 所有表单控件必须有 placeholder -->
            <el-input v-model="dialogConfig.dialogFormData.categoryName" :placeholder="t('pleaseInput') + t('iknow.CmsCategory.categoryName')" maxlength="50" clearable />
          </el-form-item>
        </el-col>
        <el-col :span="20">
          <el-form-item :label="t('iknow.CmsCategory.categoryDesc')" prop="categoryDesc">
            <el-input type="textarea" v-model="dialogConfig.dialogFormData.categoryDesc" :placeholder="t('pleaseInput') + t('iknow.CmsCategory.categoryDesc')" :rows="3" clearable />
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
  entityClass="uw.code.center.entity.CodeTemplateGroup"
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

## selectOptions.ts 枚举管理规范

> 所有页面的枚举配置、状态映射、选项列表必须统一到 `src/utils/selectOptions.ts` 的 `useCommonSelectTypes` hooks 中管理。

### 添加枚举示例

```typescript
// 在 useCommonSelectTypes 函数内部添加

// 使用 computed 包装以支持 i18n
const knowledgeSourceOptions = computed<commonType[]>(() => [
  { label: '全部文章', value: 'allArticles' },
  { label: '指定分类文章', value: 'specifiedCategoryArticles' },
  { label: '全部问答', value: 'allQA' },
  { label: '指定版块问答', value: 'specifiedSectionQA' }
])

// 索引状态选项（用于 handleTypeForLabel 显示）
const indexStateTypes = computed<commonType[]>(() => [
  { label: '索引中', value: 'indexing' },
  { label: '已完成', value: 'completed' },
  { label: '索引失败', value: 'failed' },
  { label: '待索引', value: 'pending' }
])

// 标签类型映射（不需要 computed，纯映射）
const indexStateTagTypes: Record<string, string> = {
  indexing: 'warning',
  completed: 'success',
  failed: 'danger',
  pending: 'info'
}

// 在 return 中导出
return {
  // ...已有选项
  knowledgeSourceOptions,
  indexStateTypes,
  indexStateTagTypes,
}
```

### 页面中使用枚举

```vue
<script setup lang="ts">
// 从 useCommonSelectTypes 解构获取
const {
  handleTypeForLabel,
  commonTypes,
  knowledgeSourceOptions,
  indexStateTypes,
  indexStateTagTypes,
  categorySelectOptions,
  sectionSelectOptions
} = useCommonSelectTypes()

// 使用 handleTypeForLabel 获取枚举显示文本（不用自定义 xxxText 映射）
const getIndexStateLabel = (state: string) => {
  return handleTypeForLabel(state, indexStateTypes.value, state)
}
</script>

<template>
  <!-- 使用 v-for 动态渲染选项，禁止硬编码 el-option -->
  <el-select v-model="form.category" placeholder="请选择分类">
    <el-option v-for="option in categorySelectOptions" :key="option.value" :label="option.label" :value="option.value" />
  </el-select>

  <!-- 使用 class 替代 style -->
  <el-tag :type="indexStateTagTypes[row.indexState]" size="small" class="tag-spacing">
    {{ getIndexStateLabel(row.indexState) }}
  </el-tag>

  <!-- v-for 使用描述性变量名 -->
  <el-tag v-for="sourceItem in getTags(row.sources)" :key="sourceItem" size="small" class="tag-spacing">
    {{ sourceItem }}
  </el-tag>
</template>

<style lang="scss" scoped>
.tag-spacing {
  margin: 2px;
}
.width-percent-100 {
  width: 100%;
}
</style>
```
