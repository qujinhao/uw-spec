# Admin Web 编码原则

> version: "1.1.0"
> 被 220-admin-web-dev、221-admin-web-dev-review、620-feature-dev、720-bugfix-dev 共同引用。
> 本文件是编码规范的**唯一权威来源**，其他文件不再重复列举规则。

## 四条核心原则

### 原则一：集中管理（Single Source of Truth）

**判断标准**：如果一个配置在多个地方可能被使用，或者属于字典/枚举/映射类数据，它应该集中管理。

| 集中到哪里 | 管什么 | 格式 |
|-----------|--------|------|
| `src/utils/selectOptions.ts` → `useCommonSelectTypes()` | 所有下拉选项、状态映射、标签类型映射 | `computed<commonType[]>(() => [...])` |
| `src/components/` | 可复用 UI 组件 | 已有组件优先使用 |
| `src/hooks/` | 可复用逻辑 | `useXxx()` hooks |
| `src/api/` | API 调用 | 代码生成器产出 |

**具体做法**：
- 页面内**禁止**定义 `const xxxOptions = [...]`、`const xxxTagType = {...}`、`const xxxText = {...}` 等枚举配置
- 新增枚举时，在 `useCommonSelectTypes()` 中添加 `computed` 包装的选项和可选的标签类型映射
- 标签显示文本统一使用 `handleTypeForLabel(value, xxxTypes.value, fallback)` 获取，禁止自定义 `xxxText` 映射

### selectOptions.ts 枚举管理规范

> 所有页面的枚举配置、状态映射、选项列表必须统一到 `src/utils/selectOptions.ts` 的 `useCommonSelectTypes` hooks 中管理。

#### 添加枚举示例

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

#### 页面中使用枚举

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

### 原则二：类型安全（No Escape Hatches）

**判断标准**：如果 TypeScript 编译器无法推断类型，说明代码有问题。

| 禁止 | 替代方案 |
|------|---------|
| `as any`（除 `proxy as any`） | 定义正确的类型或扩展 interface |
| `.then(res =>` 无类型 | `.then((res: ResponseData<Xxx>) =>` |
| `: any` 参数或变量 | 使用具体的接口类型 |
| `ref<any>(...)` | `ref<XxxType>(...)` |
| 隐式 string/number 混用 | 对照 API interface 确认类型后统一使用 |
| 混合导入值和类型 | `import { type Xxx, fn } from '...'` |

### 原则三：项目一致性（Use What Exists）

**判断标准**：在编写任何代码前，先检查项目中是否已有相同或类似功能的实现。

| 场景 | 做法 |
|------|------|
| 分页 | 使用 `Pagination` 组件，禁止 `el-pagination` |
| 启用/禁用确认 | 使用 `useSimplifyPrompt`，禁止直接 `ElMessageBox` |
| 列表页数据加载 | 使用 `useActivated`，禁止 `onMounted` |
| CRUD 操作 | 使用 `useCrud` hooks |
| 表单验证 | 内联写法 `:rules="[{ required: true, message: '...' }]"` |
| 导入 Vue API | 不手动导入 `ref`/`computed`/`onMounted` 等（已配置 auto-import） |
| 导入组件 | 不手动导入 `src/components` 下的组件（`unplugin-vue-components` 自动导入） |
| 同一模块多次导入 | 合并为单个 `import` 语句 |
| 全局工具访问 | 通过 `proxy` 获取 `dayjs`/`useActivated` 等，使用 `proxy as any` |
| 按需加载大组件 | 使用 `defineAsyncComponent` 懒加载非首屏组件 |

**已配置自动导入**：`vue`、`vue-router`、`@vueuse/core`、`unplugin-vue-components`（组件）。这些包的 API 和 `src/components` 下的组件不需要手动 import。
**需要手动导入**：`vue-i18n`（`useI18n`）、`element-plus`（`ElMessage`、`FormRules`、`FormInstance` 等）、`@/hooks/*`、`@/utils/*`、Vue 类型（`type ComponentInternalInstance`）。

### 全局工具访问（proxy）

项目中通过 `proxy` 挂载了部分全局工具（如 `dayjs`、`useActivated`、`formatDate` 等），页面中通过 `getCurrentInstance()` 获取：

```typescript
import { getCurrentInstance, type ComponentInternalInstance } from 'vue'

const { proxy } = getCurrentInstance() as ComponentInternalInstance
const { dayjs, useActivated, formatDate } = proxy as any
```

**常用挂载工具**：

| 工具 | 用途 |
|------|------|
| `dayjs` | 日期格式化与计算 |
| `useActivated` | 列表页数据加载（替代 `onMounted`） |
| `formatDate` | 日期格式化输出 |
> 通过 `proxy` 访问时统一使用 `proxy as any`，这是项目中唯一允许的 `any` 使用场景。

### 权限控制

按钮级权限通过 `v-permission` 指令控制，基于当前路由的权限码前缀拼接操作类型：

```vue
<!-- 推荐：使用 usePermissionCode 生成权限码 -->
<el-button v-permission="usePermissionCode('update')">编辑</el-button>
<el-button v-permission="usePermissionCode('delete')">删除</el-button>
<el-button v-permission="usePermissionCode('enable')">启用</el-button>
<el-button v-permission="usePermissionCode('disable')">禁用</el-button>
```

| 操作类型 | 权限码后缀 | 说明 |
|----------|-----------|------|
| 查询/列表 | `query` / `list` | 列表页展示权限 |
| 新增 | `save` | 新增按钮 |
| 编辑 | `update` | 编辑按钮 |
| 删除 | `delete` | 删除按钮 |
| 启用 | `enable` | 启用按钮 |
| 禁用 | `disable` | 禁用按钮 |
| 导入 | `import` | 导入按钮 |
| 导出 | `export` | 导出按钮 |

> `usePermissionCode` 接收操作类型，自动拼接当前路由的权限前缀。例如列表页路由 `/saasBaseApp/saas/base/dict`，`usePermissionCode('update')` 生成 `/saasBaseApp/saas/base/dict/update`。
>
> **跨页面权限**：当 A 页面需要调用 B 页面的接口时，传入第二个参数指定 B 页面的完整权限码：
>
> ```vue
> <el-button
>   v-permission="usePermissionCode('', '/uwAuthCenter/saas/mch/admin/updateAdminPerm')"
> >
>   保存权限
> </el-button>
> ```

### 原则四：代码可读性（Self-Documenting Code）

**判断标准**：一个新团队成员能否在不看注释的情况下理解代码意图。

| 禁止 | 替代方案 |
|------|---------|
| v-for 单字母变量 `v-for="s in"` | 描述性名称 `v-for="sourceItem in"` |
| 数组方法单字母参数 `(a, b) =>` | `(item, index) =>` |
| 内联样式 `style="..."` | CSS 类 |
| 硬编码多个 `el-option` | `v-for` + selectOptions 动态渲染 |
| 嵌套三元 `a ? b : c ? d : e` | computed 属性或方法 |
| 表单控件无 placeholder | 所有 `el-input`/`el-select`/`el-input-number` 必须有 placeholder |
| 弹窗按钮顺序不一致 | 取消在左（icon="Close"），保存在右（icon="Check"） |
| 页面内重复定义 `interface commonType` | 使用 `import { commonType } from '@/type'` |

### 搜索表单（SearchForm）

列表页统一使用 `SearchForm` 组件实现搜索区域，通过配置 `list` 属性动态渲染搜索项：

```vue
<template>
  <SearchForm
    v-model="searchForm"
    :list="searchList"
    @search="handleSearch"
    @change="handleSearch"
  />
</template>

<script setup lang="ts">
import { SearchFormType } from '@/components/SearchForm/type'

const searchForm = ref({})
const searchList = ref<SearchFormType[]>([
  {
    field: 'keyword',
    label: '关键词',
    componentType: 'input',
    placeholder: '请输入关键词',
    enterable: true
  },
  {
    field: 'state',
    label: '状态',
    componentType: 'select',
    options: commonTypes.value,
    placeholder: '请选择状态'
  }
])
</script>
```

**常用搜索项配置**：

| 属性 | 说明 | 示例值 |
|------|------|--------|
| `componentType` | 组件类型 | `'input'`、`'select'`、`'datePicker'`、`'selectv2'`、`'inputNumber'`、`'cascader'`、`'selectAndDatePicker'`、`'inputNumberRange'`、`'timePicker'`、`'radio'` |
| `field` | 字段名（唯一） | `'keyword'`、`'createTime'` |
| `label` | 标签文本 | `'关键词'` |
| `placeholder` | 占位文本 | `'请输入'`、`'请选择'` |
| `options` | select 选项数组 | `[{ label: '启用', value: 1 }]` |
| `enterable` | 回车触发搜索 | `true` |
| `br` | 强制换行 | `true` |

> 完整属性列表参考 `src/components/SearchForm/use.md`。

### SearchForm 统一规范

| 属性 | 统一值 | 说明 |
|---|---|---|
| `formItem.labelWidth` | `'110'` | 全项目统一，禁止逐项目自定义（80/90/120 等） |
| `formItemWidth`（普通项） | `280` | input/select/inputNumber 等 |
| `formItemWidth`（时间类范围项） | `480` | 创建时间/修改时间等 datetimerange |
| `formItemWidth`（其他范围项） | `380` | inputNumberRange 等
| 时间范围 componentType | `datePicker` + `type: 'datetimerange'` | 禁止用 `selectAndDatePicker` 做范围搜索 |
| 时间范围 shortcuts | `shortcuts: shortcuts.value` | 来自 `useCommonSelectTypes`，必挂 |
| 时间范围 valueFormat | `'YYYY-MM-DD HH:mm:ss'` | 与后端 `Array<string>` 字段类型对齐 |
| 时间范围 defaultTime | `[new Date(2000,1,1,0,0,0), new Date(2000,2,1,23,59,59)]` | 标准默认值 |
| 状态/类型 options | 复用 `useCommonSelectTypes` 中的 `commonTypes` / `xxxTypes` | 禁止页面内定义 |
| 关键字搜索 | `enterable: true` | 支持回车触发搜索 |

**标准时间范围搜索项示例**：

```typescript
{
  field: 'createDateRange',
  formItem: { label: '创建时间', labelWidth: '110' },
  formItemWidth: 480,
  componentType: 'datePicker',
  type: 'datetimerange',
  startPlaceholder: '请选择开始时间',
  endPlaceholder: '请选择结束时间',
  valueFormat: 'YYYY-MM-DD HH:mm:ss',
  defaultTime: [
    new Date(2000, 1, 1, 0, 0, 0),
    new Date(2000, 2, 1, 23, 59, 59)
  ],
  expand: {
    shortcuts: shortcuts.value
  }
}
```

**禁止**：

| ❌ 错误写法 | ✅ 正确写法 |
|---|---|
| `labelWidth: '80'` / `'90'` / `'120'` 等 | `labelWidth: '110'`（全项目统一） |
| 时间范围用 `componentType: 'selectAndDatePicker'` | `componentType: 'datePicker'` + `type: 'datetimerange'` |
| 时间范围不挂 `shortcuts` | 必须 `expand: { shortcuts: shortcuts.value }` |
| 时间范围 `valueFormat` 缺失 | 必须显式声明 `'YYYY-MM-DD HH:mm:ss'` |
| 页面内 `const xxxOptions = []` 作为 select options | 解构 `useCommonSelectTypes()` 中已注册的 options |


### 表格列展示统一规范

列表页表格列展示遵循以下统一规范，保证视觉一致性与可读性。

| 列类型 | 统一要求 | 说明 |
|---|---|---|
| 序号列 | `type="index"` + `width="60"` | 所有列表页统一使用 Element Plus 内置序号列 |
| 选择列 | `type="selection"` + `width="50"` | 需要批量操作时使用 |
| 文本列 | `show-overflow-tooltip` | 长文本统一省略 + tooltip 展示 |
| 时间列 | `width="160"` + `formatDate` 格式化 | 统一格式 `YYYY-MM-DD HH:mm:ss` |
| 状态列 | `el-tag` + `handleTypeForLabel` | 复用 `useCommonSelectTypes` 中的 options 与 tagTypes |
| 标签列 | `el-tag` + `class="tag-spacing"` | 禁止内联 `style`，使用 class 控制间距 |
| 操作列 | `fixed="right"` + 合适 `width` | 固定在右侧，宽度按按钮数量调整 |
| 数字/金额列 | `align="right"` | 数值类列右对齐便于对比 |

**标准表格列示例**：

```vue
<el-table :data="tableData" border>
  <el-table-column type="index" label="序号" width="60" align="center" />
  <el-table-column prop="name" label="名称" show-overflow-tooltip />
  <el-table-column prop="state" label="状态" width="100">
    <template #default="scope">
      <el-tag :type="stateTagTypes[scope.row.state]" size="small">
        {{ handleTypeForLabel(scope.row.state, stateTypes.value) }}
      </el-tag>
    </template>
  </el-table-column>
  <el-table-column prop="createTime" label="创建时间" width="160">
    <template #default="scope">
      {{ formatDate(scope.row.createTime) }}
    </template>
  </el-table-column>
  <el-table-column label="操作" fixed="right" width="240" align="center">
    <!-- 操作按钮 -->
  </el-table-column>
</el-table>
```

**禁止**：

| ❌ 错误写法 | ✅ 正确写法 |
|---|---|
| 自定义序号实现 | `type="index"` 内置序号 |
| 长文本不加 `show-overflow-tooltip` | 文本列统一加 `show-overflow-tooltip` |
| 时间列内联 `new Date(...).toLocaleString()` | `formatDate(scope.row.xxx)` |
| 操作列不固定 | `fixed="right"` 固定在右侧 |
| 标签间距用 `style="margin:2px"` | `class="tag-spacing"` |


### 表格操作按钮图标规范

操作列按钮统一使用 `el-button` + Element Plus 图标 或 项目自建 iconfont 图标，禁止内联 `style`。

| 操作 | 按钮 type | 图标方式 | 写法 |
|---|---|---|---|
| 启用 | `success` | Element Plus 图标 | `icon="CircleCheck"` |
| **禁用** | `info` | **项目 iconfont** | `<i class="iconfont jinyong"></i>` 作为按钮 slot |
| 编辑 | `primary` | Element Plus 图标 | `icon="Edit"` |
| 删除 | `danger` | Element Plus 图标 | `icon="Delete"` |
| 多语言 | `warning` | Element Plus 图标 | `icon="ChatLineRound"` |
| 历史日志 | `warning` | Element Plus 图标 | `icon="Comment"` |
| 关键日志 | `success` | Element Plus 图标 | `icon="DocumentChecked"` |

**禁用按钮标准写法**（图标用项目自建 iconfont，不用 Element Plus 的 `CircleClose`）：

```vue
<el-tooltip content="禁用" placement="top">
  <el-button
    type="info"
    size="small"
    v-permission="usePermissionCode('disable')"
    @click="handleDisable(scope.row)"
  >
    <i class="iconfont jinyong"></i>
  </el-button>
</el-tooltip>
```

> ❌ 禁止：`<el-button type="info" icon="CircleClose" />`
> ✅ 必须：`<el-button type="info"><i class="iconfont jinyong"></i></el-button>`


### 表单/详情页响应式布局规范

**原则**：所有表单项必须使用 `el-row + el-col` 双层包裹，确保不同屏幕尺寸下的自适应展示。

#### 1. el-row 配置（必设）

| 属性 | 统一值 | 说明 |
|---|---|---|
| `:gutter` | `10` | 列间距固定为 10px，防止表单挤在一起 |

**标准写法**：
```vue
<el-row
  :gutter="10"
>
  <el-col ...>
    <el-form-item ... />
  </el-col>
  <el-col ...>
    <el-form-item ... />
  </el-col>
</el-row>
```

#### 2. el-col 配置（必填）

| 属性 | 统一值 | 说明 |
|---|---|---|
| `:xl` | `10`（数字） | 大屏幕（≥1920px）栅格宽度，一行 2 列 |
| `:lg` | `12`（数字） | 中等屏幕（≥1200px）栅格宽度，一行 2 列 |

> ⚠️ **必须用冒号前缀 `:xl :lg`**（v-bind 数字），不要用 `xl="10" lg="12"`（字符串）
> ❌ **禁止**：使用 `:span=` 写死栅格宽度
> ❌ **禁止**：使用 `:push=` 偏移（已由栅格自动居中处理）

#### 3. 表单控件宽度

- **所有可设宽度的表单控件**（`el-input` / `el-input-number` / `el-date-picker` / `el-select` 等）默认宽度 **100%**，自适应所在 `el-col` 的宽度
- 无需设置 `width-full` class，不写任何宽度样式即可（Element Plus 控件默认 100% 宽度）
- ❌ **禁止**：写死固定像素宽度（如 `style="width: 480px"` / `class="form-input-w-480"` /`:style="{width:'480px'}"`）

#### 4. 推荐行结构

| 一行列数 | el-col 配置 | 布局效果 |
|---|---|---|
| 2 列 | `:xl="10" :lg="12"` × 2 | 标准双列，大屏幕/中屏自动适配，左右留白均匀 |
| 1 列 | `:xl="20" :lg="22"` | 大跨度字段（富文本/备注/附件等），居中对齐 |

#### 5. 标准参考样例

**双列布局**（每行 2 个字段，自适应大屏/中屏）：

```vue
<el-row
  :gutter="10"
>
  <el-col
    :xl="10"
    :lg="12"
  >
    <el-form-item
      label="联系人姓名"
      prop="contactName"
    >
      <el-input
        v-model="baseForm.contactName"
        placeholder="请输入"
        clearable
      />
    </el-form-item>
  </el-col>
  <el-col
    :xl="10"
    :lg="12"
  >
    <el-form-item
      label="手机号码"
      prop="contactMobile"
    >
      <el-input
        v-model="baseForm.contactMobile"
        placeholder="请输入"
        clearable
      />
    </el-form-item>
  </el-col>
</el-row>
```

**要点解读**：
- `:xl="10"` 大屏（≥1920px）每列占 10/24，两列总 20/24
- `:lg="12"` 中屏（≥1200px）每列占 12/24，两列总 24/24 撑满
- **必须用冒号前缀**（v-bind 数字），不带冒号会被解析为字符串 `"10"`，Element Plus 内部会做严格 number 类型校验
- 表单组件**不设宽度**，自动 100% 撑满所在 `el-col`

**单列大跨度布局**（富文本、长文本、附件区等）：

```vue
<el-row
  :gutter="10"
>
  <el-col
    :xl="20"
    :lg="22"
  >
    <el-form-item
      label="详细描述"
      prop="description"
    >
      <el-input
        v-model="formData.description"
        type="textarea"
        :autosize="{ minRows: 3 }"
        placeholder="请输入"
        maxlength="500"
      />
    </el-form-item>
  </el-col>
</el-row>
```

#### 6. 禁止清单

| ❌ 错误写法 | ✅ 正确写法 |
|---|---|
| `el-form` 直接子节点是 `el-form-item`（无 row/col 包裹） | `el-form-item` 外层必须先包 `el-col`，再外层包 `el-row` |
| `<el-col :span="6">` / `<el-col :span="10">` | `<el-col :xl="10" :lg="12">`（标准双列）或 `<el-col :xl="20" :lg="22">`（单列） |
| `<el-col xl="10" lg="12">` 无冒号传字符串 | `<el-col :xl="10" :lg="12">` 必须冒号绑定数字 |
| `<el-col :push="2">` 用偏移控制对齐 | 用栅格自适应，无需 push |
| `<el-input style="width: 480px" />` | `<el-input />`（默认 100% 撑满 col 即可） |
| `<el-input class="form-input-w-480" />` 自定义宽度类 | `<el-input />`（无需宽度类） |
| `gutter=0` 或无 gutter 配置 | 统一 `:gutter="10"` |
| 垂直间距靠 `<br />` 或内联 `style` 处理 | 用 `class="margin-bottom-10"` 统一控制行间距 |

#### 7. 特殊字段处理

- **大跨度字段**（富文本、长描述、图片上传区等）：单 `el-col` 用 `:xl="20" :lg="22"`
- **状态/单选组字段**：用标准 `:xl="10" :lg="12"` 即可
- **多组件一行场景**（如 daterange+input 组合）：放入同一 `el-form-item`，由 form-item 内部 flex 布局处理，外层 col 仍用 `:xl="10" :lg="12"` 或 `:xl="20" :lg="22"`


### 表单项 size 规范

**原则**：表单内所有组件（`el-input` / `el-select` / `el-button` / `el-input-number` / `el-date-picker` / `el-time-picker` 等）**默认不设置 `size` 属性**，由 `el-form` 的 `size` 全局统一控制（默认 `default`），从而保证表单内字段大小一致、风格统一。

### 标准写法

```vue
<!-- ✅ 正确：表单内所有控件均不写 size -->
<el-form :model="formData" label-width="110px">
  <el-form-item label="名称">
    <el-input v-model="formData.name" placeholder="请输入" />
  </el-form-item>
  <el-form-item label="状态">
    <el-select v-model="formData.state" placeholder="请选择">
      <el-option label="启用" :value="1" />
      <el-option label="禁用" :value="0" />
    </el-select>
  </el-form-item>
  <el-form-item label="价格">
    <el-input-number v-model="formData.price" :min="0" />
  </el-form-item>
  <el-form-item>
    <el-button @click="onCancel" icon="Close">取消</el-button>
    <el-button type="primary" @click="onSubmit" icon="Check">保存</el-button>
  </el-form-item>
</el-form>
```

### 禁止清单

| ❌ 错误写法 | ✅ 正确写法 |
|---|---|
| `<el-input size="small" />` 表单内单独设小号 | `<el-input />` 不设 size |
| `<el-button size="small" />` 表单底部按钮设小号 | `<el-button />` 不设 size |
| `<el-input-number size="large" />` 单字段设大号 | `<el-input-number />` 不设 size |
| `<el-date-picker size="small" />` 表单内日期单独设小号 | `<el-date-picker />` 不设 size |
| 表格行内编辑按钮（非表单）需要 `size="small"` 才合规 | 表格内操作按钮可保留 `size="small"`（属于表格规范，非表单规范） |

> **例外**：表格行内的操作按钮（`<el-table-column>` → `<el-button size="small">`）允许设 `size="small"` —— 这是**表格规范**而非表单规范，两者互不冲突。

### 文件 / 图片上传规范

**原则**：项目内所有文件 / 图片上传必须使用 `@/components/UploadFile/index.vue` 业务组件，**禁止直接使用 `el-upload`** 或让用户手填 URL。该组件已封装：① OSS 直传签名 ② 图片子线程压缩 ③ 进度条 ④ 多类型预览（图/视频/PDF/Excel/Word）⑤ ref 关联与解绑。

#### 1. 标准用法

**模板**：

```vue
<UploadFile
  ref="uploadFileRef"
  v-model:fileListForShow="uploadFileList"
  v-model:fileListForUpload="needUploadFileList"
  :accept="acceptKeys"
  :multiple="true"
  :item-width="100"
  :item-height="100"
  :limit="2"
  :uploadParams="uploadParams"
/>
```

**Script**：

```ts
import { type UploadUserFile } from 'element-plus'
import { type uploadFileUrl } from '@/components/UploadFile/type'

// 已上传文件展示（el-upload 风格列表）
const uploadFileList = ref<UploadUserFile[]>([])
// 需要提交给后端的文件（含 id / realUrl / blobUrl）
const needUploadFileList = ref<uploadFileUrl[]>([])
// UploadFile 组件 ref，用于调用 handleUpdateRefId / handleUnLinkFile
const uploadFileRef = ref<InstanceType<typeof UploadFile>>()

// 接受的扩展名（必填）
const acceptKeys = '.jpg,.jpeg,.png,.gif,.webp'

// 上传业务参数（必填）
const uploadParams = {
  objectId: 0,                 // 关联业务记录 ID，新增前可填 0，保存后回填
  objectType: 'xxxRefType'     // 业务约定的 refType 字符串
}
```

**保存后必须调用**：

```ts
// 表单保存成功后，把临时上传的文件关联到真实业务 ID
const handleSave = async () => {
  const res = await saveXxx(formData.value)
  if (res.state === 'success') {
    // 关联 refId（必须）
    uploadFileRef.value?.handleUpdateRefId(res.data?.id)
    // 解绑被删除的文件（必须）
    uploadFileRef.value?.handleUnLinkFile()
    ElMessage.success('保存成功')
  }
}
```

#### 2. 常用 Props 速查

| Prop | 类型 | 默认 | 说明 |
|---|---|---|---|
| `v-model:fileListForShow` | `UploadUserFile[]` | `[]` | 展示用列表（含 url、name、uid 等） |
| `v-model:fileListForUpload` | `uploadFileUrl[]` | `[]` | 提交给后端的真实文件（含 id/realUrl） |
| `accept` | `string` | - | 扩展名白名单逗号分隔，如 `'.jpg,.png,.pdf'` |
| `multiple` | `boolean` | `false` | 是否多选 |
| `limit` | `number` | - | 最大上传数量 |
| `itemWidth` / `itemHeight` | `number/string` | `128px` | 单个文件缩略图尺寸 |
| `listType` | `'picture-card' \| 'text'` | `'picture-card'` | 卡片式/文本列表 |
| `disabled` | `boolean` | `false` | 禁用上传（详情模式） |
| `accessType` | `number` | `0` | OSS 访问类型（私有/公开） |
| `ossSite` | `'saasOssSite' \| 'sysOssSite'` | `'saasOssSite'` | OSS 站点选择 |
| `needCompress` | `boolean` | `true` | 图片是否子线程压缩为 webp（80%） |
| `autoUpload` | `boolean` | `true` | 选中后自动上传 |
| `uploadParams` | `{ objectId, objectType }` | - | 必填业务参数 |
| `expireDate` | `string` | - | 文件过期时间（按需） |

#### 3. 暴露方法（必须按时机调用）

| 方法 | 调用时机 | 用途 |
|---|---|---|
| `handleUpdateRefId(refId)` | 表单**保存成功后** | 把临时文件关联到真实业务 ID |
| `handleUnLinkFile()` | 表单**保存成功后** | 解绑用户已删除的旧文件 |
| `clearFiles()` | 弹窗关闭 / 表单 reset | 清空所有缓存 |

#### 4. 不同场景配置参考

| 场景 | 关键配置 |
|---|---|
| 单张头像 | `:limit="1"`, `:multiple="false"`, `accept=".jpg,.png,.webp"` |
| 多张产品图 | `:limit="9"`, `:multiple="true"`, `:item-width="100" :item-height="100"` |
| 视频上传 | `accept=".mp4,.mov"`, `:limit="1"` |
| 附件（PDF/Excel/Word） | `accept=".pdf,.xlsx,.docx"`, `listType="text"` |
| 详情页只读展示 | `disabled` |

#### 5. 禁止清单

| ❌ 错误写法 | ✅ 正确写法 |
|---|---|
| 直接用 `el-upload` 接业务 OSS | 用 `UploadFile` 组件 |
| 用 `el-input` 让用户粘贴图片 URL | 用 `UploadFile` 上传 |
| 不传 `uploadParams` | 必须传 `{ objectId, objectType }` |
| 保存后不调用 `handleUpdateRefId` | 表单保存成功后必调 |
| 删除文件不调用 `handleUnLinkFile` | 解绑被删除的旧文件，避免 OSS 文件残留 |
| 多次实例化时不调 `clearFiles` 清缓存 | 弹窗/详情切换时调用 |
| 图片字段在表单存 base64 / blob URL | 存 `realUrl`（OSS 真实路径），由 `needUploadFileList` 给出 |


### el-table 统一配置规范

**原则**：项目内所有 `el-table` 必须保持一致的基础视觉与行为，统一以下配置。

| 属性 | 统一值 | 说明 |
|---|---|---|
| `:style` | `{ width: '100%' }` | 表格宽度撑满容器 |
| `:header-cell-style` | `{ backgroundColor: 'var(--el-color-info-light-9)' }` | 表头浅灰背景，使用 CSS Var 兼容暗色模式 |
| `stripe` | 必加 | 行斑马纹 |
| `border` | 视场景加 | 列表页/表单内嵌表格建议加，简单展示可不加 |
| `show-overflow-tooltip` | 视场景加 | 长文本列建议加 |

**标准写法**：

```vue
<el-table
  :data="tableData"
  :style="{ width: '100%' }"
  :header-cell-style="{
    backgroundColor: 'var(--el-color-info-light-9)'
  }"
  stripe
  border
>
  <el-table-column ... />
</el-table>
```

> 适用范围：
> - **列表页**：直接遵循
> - **表单页/详情页中的内嵌表格**（如时间段配置、批量数据预览、子表）：同样必须遵循
> - **业务组件**（如 `DataDiffTable`、`HistoryLog`）：以此为标杆

| ❌ 错误写法 | ✅ 正确写法 |
|---|---|
| `<el-table>` 无 style/header-cell-style/stripe | 三件套必加 |
| `style="width: 100%; background: #fff"` 内联混杂 | `:style="{ width: '100%' }"` 单独写 |
| `header-cell-style="background: #f5f7fa"` 硬编码颜色 | `var(--el-color-info-light-9)` 用 CSS Var |
| 表单页内嵌的临时表格"省略" stripe | 全项目统一，临时表格也必须 |


### 币种 / 通用枚举下拉规范

**原则**：所有公共枚举（币种、用户类型、状态、性别、语言等）必须使用 `@/utils/selectOptions.ts` 中 `useCommonSelectTypes` 暴露的 computed 数组，**禁止任何页面内硬编码 option**。

**币种下拉标准写法**：

```vue
<script setup lang="ts">
import { useCommonSelectTypes } from '@/utils/selectOptions'
const { currencyTypes } = useCommonSelectTypes()
</script>

<template>
  <el-select
    v-model="formData.currency"
    placeholder="请选择"
    clearable
    filterable
  >
    <el-option
      v-for="currencyItem in currencyTypes"
      :key="currencyItem.value"
      :label="currencyItem.label"
      :value="currencyItem.value"
    />
  </el-select>
</template>
```

**已注册的常用枚举速查**：

| 枚举名 | 用途 | 备注 |
|---|---|---|
| `currencyTypes` | 币种（CNY/USD/JPY/HKD/MOP 等 100+ 种） | 必加 `filterable` 支持搜索 |
| `commonTypes` | 通用状态（1=启用 / 0=停用 / -1=删除） | 配合 `handleTypeForLabel` 使用 |
| `userTypes` | 用户类型 | - |
| `genderTypes` | 性别 | - |
| `langTypes` | 语言 | - |

> ⚠️ **重要**：如发现某枚举尚未在 `useCommonSelectTypes` 注册（如新增的业务枚举），必须先添加到 `selectOptions.ts`，再在页面使用，**禁止**在页面内 `const xxxOptions = [...]`。

**禁止清单**：

| ❌ 错误写法 | ✅ 正确写法 |
|---|---|
| `<el-option label="人民币" value="CNY"/>` 硬编码 4 个币种 | `v-for` 循环 `currencyTypes` |
| 页面内 `const currencyOptions = [{label:'CNY', value:'CNY'}, ...]` | 用 `useCommonSelectTypes` 解构 |
| 复用 `commonTypes` 显示币种 | 用专属 `currencyTypes`（带 i18n 翻译） |
| 币种下拉无 `filterable` | 必加 `filterable`（币种数量多，需要搜索） |


### 状态字段（state）展示规范

`state` 字段是项目内最常用的枚举字段，列表/详情/标签均必须遵循以下规范。

**项目通用 state 取值**：`1`=正常/启用，`0`=停用/禁用，`-1`=已删除。

**列表 `el-tag` 标准写法**：

```vue
<el-table-column prop="state" label="状态" align="center" width="90">
  <template #default="{ row }">
    <el-tag
      :type="row.state === 1 ? 'success' : row.state === -1 ? 'danger' : 'info'"
      size="small"
    >
      {{ handleTypeForLabel(row.state, commonTypes) }}
    </el-tag>
  </template>
</el-table-column>
```

**统一规范**：

| 规范项 | 要求 | 说明 |
|---|---|---|
| `el-tag` type 映射 | `1=success / 0=info / -1=danger` | 全项目统一 |
| 文本来源 | `handleTypeForLabel(row.state, commonTypes)` | 从 `useCommonSelectTypes` 解构，禁止硬编码 |
| commonTypes 来源 | `const { handleTypeForLabel, commonTypes } = useCommonSelectTypes()` | 不允许在页面内定义状态文本映射 |

**禁止**：

| ❌ 错误写法 | ✅ 正确写法 |
|---|---|
| `row.state === 1 ? '启用' : '停用'` | `handleTypeForLabel(row.state, commonTypes)` |
| `row.state === 1 ? 'success' : 'danger'`（缺 -1 分支） | `1=success / 0=info / -1=danger` 三分支 |
| 页面内 `const stateText = { 1: '启用', 0: '禁用' }` | 复用 `commonTypes` |
| 用 `el-link` 替代 `el-tag` 展示状态 | 统一使用 `el-tag` |


### 时间字段展示规范

所有时间字段展示统一使用 `formatDate`，**禁止任何空值判断**——`formatDate` 内部已对 `null/undefined/''/0` 做了兜底（返回空字符串或 `--`）。

**标准写法**：

```vue
<el-table-column prop="createDate" label="创建时间" align="center" width="180">
  <template #default="{ row }">
    {{ formatDate(row.createDate) }}
  </template>
</el-table-column>
```

**合并展示（创建/修改时间双行）**：

```vue
<el-table-column label="创建/修改时间" align="center" width="190">
  <template #default="{ row }">
    <div>{{ formatDate(row.createDate) }}</div>
    <div>{{ formatDate(row.modifyDate) }}</div>
  </template>
</el-table-column>
```

**禁止**：

| ❌ 错误写法 | ✅ 正确写法 |
|---|---|
| `row.createDate ? formatDate(row.createDate) : '--'` | `formatDate(row.createDate)` |
| `{{ row.createDate || '-' }}` 直出 ISO 字符串 | `{{ formatDate(row.createDate) }}` |
| 内联 `new Date(row.createDate).toLocaleString()` | `formatDate(row.createDate)` |
| `dayjs(row.createDate).format(...)` 重复格式化 | `formatDate(row.createDate)` 统一封装 |


### 状态值类型规范

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

### 状态标签映射

```typescript
// ✅ 使用 useCommonSelectTypes 集中管理，禁止页面内定义
const { statusOptions, articleStateOptions } = useCommonSelectTypes()

// ✅ 类型安全的标签类型映射
const stateTagType: Record<number, string> = {
  0: 'info',    // 禁用
  1: 'success',   // 启用
  -1: 'danger',   // 已下架
}

// 模板中直接使用
// <el-tag :type="stateTagType[row.status]">
//   {{ handleTypeForLabel(row.status, statusOptions.value) }}
// </el-tag>
```

## 数据结构规范

> 所有 API 响应遵循统一的包装类型，解析时必须按以下规则。

| API 类型 | 返回类型 | 取值方式 |
|---------|---------|---------|
| 列表 API | `ResponseData<DataList<T>>` | `res.data?.results` → `T[]` |
| 实体 API | `ResponseData<T>` | `res.data` → `T` |
| 无返回值 API | `ResponseData<void>` | 检查 `res.state === 'success'` |

**禁止使用**：`res.data?.list`（DataList 的字段是 `results`）

## 自动化验证

开发完成后，执行以下命令验证编码规范：

```bash
cd frontend/{project-name}-admin-web

# 1. 页面内枚举定义（应为0）
grep -rn 'const.*Options\s*=\s*\[' src/pages/ --include="*.vue" | wc -l

# 2. 内联样式（应为0，排除 header-cell-style）
grep -rn 'style="' src/pages/ --include="*.vue" | grep -v 'header-cell-style' | wc -l

# 3. any 类型（应仅含 proxy as any）
grep -rn ': any' src/pages/ --include="*.vue" | grep -v 'proxy as any' | wc -l

# 4. ElMessageBox 直接调用（应为0）
grep -rn 'ElMessageBox' src/pages/ --include="*.vue" | wc -l

# 5. res 未声明类型（应为0）
grep -rn '\.then(.*res =>' src/pages/ --include="*.vue" | wc -l

# 6. 本地 TagType/Text 映射（应为0）
grep -rn 'type ElTagType\|const.*TagType.*Record' src/pages/ --include="*.vue" | wc -l

# 7. onMounted 在列表页（应为0）
grep -rn 'onMounted' src/pages/ --include="*.vue" | wc -l

# 8. 手动导入 vue 自动导入项（应为0）
grep -rn "import.*{.*ref.*}.*from 'vue'" src/pages/ --include="*.vue" | wc -l

# 9. DataList 字段错误（应为0，禁止用 list 用 results）
grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" | wc -l

# 10. 手动导入已自动导入的组件（应为0）
grep -rn "import.*from '@/components/" src/pages/ --include="*.vue" | grep -v "type\|SearchFormType" | wc -l

# 11. 页面内重复定义 commonType（应为0）
grep -rn 'interface commonType' src/pages/ --include="*.vue" | wc -l

# 12. TypeScript 编译检查
pnpm vue-tsc --noEmit

# 13. Oxlint 检查
pnpm lint
```

## `<script setup>` 导入顺序

```typescript
// 1. Vue 类型（需手动导入的 type）
import { type ComponentInternalInstance } from 'vue'

// 2. 组件类型
import { SearchFormType } from '@/components/SearchForm/type'

// 3. API（合并导入，type 关键字标记类型）
import {
  saasCmsCategoryList,
  type CmsCategory,
  type CmsCategoryQueryParam
} from '@/api/iknowSaasApi'
import { ResponseData, DataList } from '@/api/uwAuthCenterAuthApi'

// 4. 第三方库
import { useI18n } from 'vue-i18n'

// 5. 项目 hooks 和工具
import { useCrud } from '@/hooks/useCrud'
import { useCommonSelectTypes } from '@/utils/selectOptions'
import { ElMessage } from 'element-plus'

// 以下不需要手动导入（已配置 auto-import）：
// ref, reactive, computed, onActivated, getCurrentInstance, useRoute, useRouter...
// src/components/ 下的组件也不需手动导入，类型声明在 components.d.ts
```

## 组件通信规范

### defineProps — 声明组件属性

```typescript
<script setup lang="ts">
interface Props {
  title: string
  count?: number        // 可选属性
  user?: User           // 引用外部类型
}

// 带默认值需配合 withDefaults
const props = withDefaults(defineProps<Props>(), {
  count: 0,
  user: () => ({ name: 'Guest' })
})
</script>
```

### defineEmits — 声明组件事件

```typescript
<script setup lang="ts">
// Vue 3.3+ 推荐语法（更简洁）
const emit = defineEmits<{
  change: [id: number]           // 命名元组语法
  update: [value: string]
  submit: [email: string, password: string]
}>()

// 旧语法（仍可兼容）
const emit = defineEmits<{
  (e: 'change', id: number): void
  (e: 'update', value: string): void
}>()

// 触发事件
const handleClick = () => {
  emit('change', 123)
}
</script>
```

### defineExpose — 暴露公共 API

```typescript
<!-- Child.vue -->
<script setup>
import { ref, computed } from 'vue'

const count = ref(0)
const isDirty = ref(false)

const isValid = computed(() => count.value > 0)

function increment() {
  count.value++
}

function reset() {
  count.value = 0
  isDirty.value = false
}

// 只暴露必要的公共 API
defineExpose({
  increment,    // 暴露方法
  reset,
  isValid,      // 暴露计算属性（保持响应性）
  // 注意：暴露的 ref 在父组件中会自动解包
})
</script>
```

### 核心原则

| 原则 | 说明 |
|------|------|
| **最小暴露** | `defineExpose` 只暴露必要方法，避免直接暴露内部状态 |
| **私有标记** | 用 `_` 前缀标记私有属性和方法，不暴露在 `defineExpose` 中 |
| **通信优先顺序** | `props/emits` > `defineExpose` > `provide/inject`，优先使用标准父子通信 |
| **v-model 实现** | 基于 `props` + `emit('update:xxx')` 模式实现双向绑定 |
| **默认值工厂函数** | 对象/数组类型默认值必须用工厂函数 `() => ({})` 返回，避免引用共享 |
| **逻辑复用** | 复杂逻辑优先抽成 composable 函数，保持组件简洁 |

### 标准结构示例

```typescript
<script setup lang="ts">

// 1. Props 定义（类型优先）
interface Props {
  roleFilter?: string
  showInactive?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showInactive: false
})

// 2. Emits 定义
const emit = defineEmits<{
  select: [id: string]
  update: [user: User]
}>()

// 3. 组件逻辑
const count = ref(0)
const filteredList = computed(() => { /* ... */ })

function handleSelect(id: string) {
  emit('select', id)
}

// 4. 谨慎暴露公共 API
defineExpose({
  refresh: () => { /* 刷新逻辑 */ }
})
</script>
```

## computed 使用规范

### 完整示例

```typescript
<script setup lang="ts">
import { ref, computed } from 'vue'

// ===== 数据源 =====
const items = ref([
  { id: 1, name: 'Apple', price: 10, qty: 2, category: 'fruit' },
  { id: 2, name: 'Banana', price: 5, qty: 3, category: 'fruit' },
  { id: 3, name: 'Carrot', price: 3, qty: 5, category: 'vegetable' }
])
const selectedCategory = ref<string>('all')
const couponCode = ref<string>('')

// ===== 派生计算（纯函数，无副作用）=====
// 1. 过滤列表
const filteredItems = computed(() => {
  if (selectedCategory.value === 'all') return items.value
  return items.value.filter(item => item.category === selectedCategory.value)
})

// 2. 小计
const subtotal = computed<number>(() => {
  return filteredItems.value.reduce((sum, item) => sum + item.price * item.qty, 0)
})

// 3. 折扣
const discountRate = computed(() => {
  const rates: Record<string, number> = { SAVE10: 0.1, SAVE20: 0.2 }
  return rates[couponCode.value] || 0
})
const discountAmount = computed(() => subtotal.value * discountRate.value)

// 4. 最终价格
const totalPrice = computed(() => subtotal.value - discountAmount.value)

// 5. 状态判断
const isEmpty = computed(() => items.value.length === 0)
const hasDiscount = computed(() => discountAmount.value > 0)
const canCheckout = computed(() => !isEmpty.value && totalPrice.value > 0)

// ===== 可写计算属性（仅用于 v-model 场景）=====
const searchCategory = computed({
  get: () => selectedCategory.value,
  set: (val) => { selectedCategory.value = val }
})
</script>
```

### 命名规范

| 类型 | 命名规则 | 示例 |
|------|---------|------|
| 布尔判断 | `is` / `has` / `can` 前缀 | `isLoading`, `hasPermission`, `canEdit` |
| 列表过滤 | `filtered` / `sorted` 前缀 | `filteredUsers`, `sortedItems` |
| 格式化 | 动词 + 名词 | `formattedDate`, `displayName` |
| 派生对象 | 原始名 + 派生含义 | `userProfile`, `cartSummary` |

### 类型声明（TS 项目）

```typescript
// ✅ 显式声明返回类型，增强可读性和类型安全
const totalPrice = computed<number>(() => {
  return items.value.reduce((sum, item) => sum + item.price, 0)
})

// ✅ 复杂对象类型
interface CartSummary {
  total: number
  count: number
  discount: number
}

const cartSummary = computed<CartSummary>(() => ({
  total: ...,
  count: ...,
  discount: ...
}))
```

### 拆分复杂逻辑

```typescript
// ❌ 错误：一个 computed 做太多事
const orderSummary = computed(() => {
  const subtotal = items.value.reduce(...)
  const discount = coupon.value ? subtotal * 0.1 : 0
  const tax = (subtotal - discount) * taxRate.value
  const shipping = subtotal > 100 ? 0 : 10
  return { subtotal, discount, tax, shipping, total: subtotal - discount + tax + shipping }
})

// ✅ 正确：拆分为多个可复用的 computed
const subtotal = computed(() => items.value.reduce((sum, item) => sum + item.price * item.qty, 0))
const discountAmount = computed(() => coupon.value ? subtotal.value * coupon.value.rate : 0)
const taxableAmount = computed(() => subtotal.value - discountAmount.value)
const taxAmount = computed(() => taxableAmount.value * taxRate.value)
const shippingFee = computed(() => subtotal.value > freeShippingThreshold ? 0 : baseShippingFee)
const totalPrice = computed(() => subtotal.value - discountAmount.value + taxAmount.value + shippingFee.value)
```

### 可写计算属性的限制使用

可写计算属性（带 setter）仅在实现 `v-model` 双向绑定或需要封装赋值逻辑时使用，且 setter 内只能修改源状态，不能产生其他副作用。

```typescript
// ✅ 可接受：v-model 场景
const fullName = computed({
  get: () => `${firstName.value} ${lastName.value}`,
  set: (val) => {
    const [first, last] = val.split(' ')
    firstName.value = first
    lastName.value = last
  }
})

// ❌ 禁止：setter 中产生副作用
const searchQuery = computed({
  get: () => query.value,
  set: (val) => {
    query.value = val
    router.push({ query: { q: val } }) // 副作用！应放在 watch 中
    analytics.track('search', val)     // 副作用！
  }
})
```

### 禁止事项

| 禁止项 | 说明 | 正确替代方案 |
|--------|------|-------------|
| **异步操作** | computed getter 中禁止 `await`、Promise、定时器 | 使用 `watch` 或 `watchEffect` |
| **修改外部状态** | 禁止修改非自身依赖的响应式数据 | 使用 `watch` 处理副作用 |
| **DOM 操作** | 禁止在 getter 中访问/修改 DOM | 使用生命周期钩子或 `watch` + `nextTick` |
| **直接赋值** | 禁止对计算属性直接赋值（只读场景） | 修改源状态 |
| **非响应式依赖** | 禁止依赖 `Date.now()`、`Math.random()` 等非响应式值 | 使用 `ref` + `watch` 或方法 |

### 性能优化规范

1. **避免不必要的重新计算**：确保 computed 的依赖尽可能精确，避免在 getter 中引入无关的响应式依赖导致频繁重算。
2. **避免返回新对象引用导致不必要的重新渲染**：

```typescript
// ❌ 错误：每次返回新对象引用，依赖它的组件会不必要的重新渲染
const userInfo = computed(() => ({ name: user.value.name, age: user.value.age }))

// ✅ 正确：Vue 3.4+ 使用 computed 的 previous 参数实现稳定引用
const userInfo = computed((prev) => {
  const next = { name: user.value.name, age: user.value.age }
  // 如果内容相同，返回之前的引用，避免触发下游更新
  if (prev && prev.name === next.name && prev.age === next.age) {
    return prev
  }
  return next
})
```
3. **优先使用 computed 而非方法**：

```vue
<!-- ❌ 每次渲染都重新执行 -->
<p>{{ calculateTotal() }}</p>

<!-- ✅ 依赖未变化时直接返回缓存 -->
<p>{{ totalPrice }}</p>
```

## 深层对象响应式处理

### 场景选择

| 场景 | 推荐方案 | 理由 |
|------|---------|------|
| 简单对象状态 | `ref({})` | 心智负担小，支持整体替换 |
| 复杂表单状态（多字段关联） | `reactive` + `toRefs` | 代码更简洁，组合方便 |
| 大型列表/对象（性能敏感） | `shallowRef` | 避免深层代理开销 |
| 第三方库实例 | `shallowRef` | 避免代理非 Vue 对象 |
| 需要解构到模板 | `toRefs(reactive(...))` 或 `ref` | 保持响应式 |
| 深层嵌套对象修改频繁 | `ref({})` | 统一 `.value` 访问模式 |
| 只读派生数据 | `computed` | 不直接操作响应式对象 |

### 注意事项

- **`ref` 与 `reactive` 不要混用**于同一数据结构，统一访问模式可降低心智负担。
- **`shallowRef` 修改深层属性不会触发响应**，需手动替换整个对象或使用 `triggerRef`。
- **`toRefs` 解构后仍保持响应式**，但仅在 `reactive` 对象上有效，对 `ref` 对象无效。

## 响应式与副作用管理

### watch 与 watchEffect 选择

| 场景 | 推荐方案 | 说明 |
|------|---------|------|
| 单一/多个明确依赖变化时执行回调 | `watch` | 可控性更强，仅监听指定源 |
| 多依赖立即执行、嵌套对象部分属性监听、代码显著更简洁 | `watchEffect` | 自动追踪依赖，需警惕隐式依赖 |
| 数据监听非必要场景 | **不使用** | 优先用 `computed` 派生状态，避免无谓的性能开销 |

### 核心约束

| 约束 | 说明 |
|------|------|
| **非必要不使用** | 监听是昂贵的，能用 `computed` 推导的就不要用 `watch` |
| **默认优先 watch** | 除非满足 `watchEffect` 的明确优势场景，否则用 `watch` |
| **watchEffect 限制使用** | 仅用于：多依赖立即执行、嵌套对象部分属性监听、代码显著更简洁的场景 |
| **必须处理副作用清理** | 异步操作（如请求、定时器）在重新执行或组件卸载前必须清理 |
| **禁止在回调中直接修改监听源** | 避免死循环，如需修改必须加条件判断 |

### 副作用清理

```typescript
// 正确：watch 中清理副作用
const stopWatch = watch(queryParams, (newVal, oldVal) => {
  const controller = new AbortController()
  fetchList({ ...newVal, signal: controller.signal })

  // 返回清理函数，在下次触发或停止监听时执行
  return () => controller.abort()
})

// 正确：watchEffect 中清理副作用
watchEffect((onCleanup) => {
  const timer = setInterval(pollData, 5000)
  onCleanup(() => clearInterval(timer))
})
```

### 避免死循环

```typescript
// 错误：直接修改监听源导致无限循环
watch(count, (val) => {
  count.value = val + 1  // 死循环！
})

// 正确：加条件判断阻断循环
watch(count, (val, oldVal) => {
  if (val !== oldVal && val < 100) {
    count.value = val + 1
  }
})
```

---

## 附录：关键规范速查表

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
