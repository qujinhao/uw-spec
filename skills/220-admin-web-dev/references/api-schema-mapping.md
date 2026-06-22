# API Schema 到前端代码映射规范

> 定义如何从 `src/api/` 中的 TypeScript interface 和函数生成页面代码。被 220-admin-web-dev 引用。

## API 文件定位规则

### 文件路径

```
src/api/{模块名}{角色}Api.ts
```

| 来源 | 推断方式 | 示例 |
|------|---------|------|
| 模块名 | 从项目结构或 PRD 模块推断 | iknow、saasBaseApp |
| 角色 | 从 PRD 或页面归属推断 | saas、mch、ops、admin |
| 完整文件名 | `{模块名}{角色首字母大写}Api.ts` | `iknowSaasApi.ts` |

### API 命名模式

| 操作 | 函数命名 | 返回类型 | 用途 |
|------|---------|---------|------|
| 列表查询 | `{role}{Module}{Entity}List` | `ResponseData<DataList<T>>` | 表格数据 |
| 轻量列表 | `{role}{Module}{Entity}LiteList` | `ResponseData<DataList<T>>` | 下拉选择数据源 |
| 单条加载 | `{role}{Module}{Entity}Load` | `ResponseData<T>` | 编辑/详情回显 |
| 新增保存 | `{role}{Module}{Entity}Save` | `ResponseData<T \| void>` | 新增提交 |
| 更新 | `{role}{Module}{Entity}Update` | `ResponseData<T \| void>` | 编辑提交 |
| 删除 | `{role}{Module}{Entity}Delete` | `ResponseData<void>` | 删除 |
| 启用 | `{role}{Module}{Entity}Enable` | `ResponseData<T>` | 状态变更 |
| 禁用 | `{role}{Module}{Entity}Disable` | `ResponseData<T>` | 状态变更 |
| 数据历史 | `{role}{Module}{Entity}ListDataHistory` | `ResponseData<DataList<T>>` | 修改历史 |
| 关键日志 | `{role}{Module}{Entity}ListCritLog` | `ResponseData<DataList<T>>` | 操作日志 |

### 类型命名

| 类型 | 命名 | 示例 |
|------|------|------|
| 实体 | `{Entity}`（PascalCase） | `CmsCategory`、`Article` |
| 查询参数 | `{Entity}QueryParam` | `CmsCategoryQueryParam` |
| 删除参数 | 页面内定义 `deleteParamsType` | `{ id: number, remark: string }` |

## 字段类型 → 前端组件映射

### 列表页列映射

| API 类型 | 表格列处理 | 列宽建议 | 对齐 |
|---------|-----------|---------|------|
| `string`（名称/标题） | 直接显示 | auto | center |
| `string`（描述/备注） | 省略显示 | 200 | center |
| `number`（ID） | 直接显示 | 80 | center |
| `number`（金额/数量） | 格式化显示 | 120 | center |
| `number`（状态码） | `el-link` + `handleTypeForLabel` | 90 | center |
| `Date` / `string`（时间戳） | `formatDate` 格式化 | 160 | center |
| `boolean` | 是/否标签 | 80 | center |

### 搜索表单组件映射

| API 类型 | SearchForm componentType | 额外属性 |
|---------|------------------------|---------|
| `string`（名称/编码） | `input` | `enterable: true` |
| `number`（ID） | `inputNumber` | — |
| `number`（状态码） | `select` | `selectOptions: xxxOptions` |
| `string`（枚举） | `select` | `selectOptions: xxxOptions` |
| `Date` / 时间戳 | `datePicker` | `type: datetime` |
| `Date` 范围 | `datePicker` | `type: daterange` |
| 外键 ID（关联查询） | `select` / `cascader` | 配合 liteList 接口 |

### 表单组件映射

| API 类型 | 表单组件 | 校验规则 | placeholder |
|---------|---------|---------|-------------|
| `string`（名称/标题） | `el-input` | `required` | `t('pleaseInput') + t('xxx')` |
| `string`（描述/备注） | `el-input type="textarea"` | — | `t('pleaseInput') + t('xxx')` |
| `string`（编码） | `el-input` | `required + pattern` | `t('pleaseInput') + t('xxx')` |
| `number`（金额） | `el-input-number` | `required` | `t('pleaseInput') + t('xxx')` |
| `number`（状态码） | `el-select` | `required` | `t('pleaseSelect') + t('xxx')` |
| `boolean` | `el-switch` / `el-radio-group` | — | — |
| `Date` | `el-date-picker` | — | `t('pleaseSelect') + t('xxx')` |
| `string[]`（标签） | 自定义标签输入 | — | — |
| 文件/图片 | `UploadFile` | — | — |
| 富文本 | `RichTextEditor` | — | — |

## 字段归属判断规则

### 列表页默认列

1. 读取 API `DataList<T>` 的实体 interface
2. 默认显示字段（按优先级）：
   - `id`（ID 列，固定宽度 80）
   - 业务主键字段（如 `categoryName`、`articleTitle`）
   - 状态字段（`state`、`status`，映射为标签）
   - 时间字段（`createTime`、`updateTime`，格式化）
3. 排除字段（默认不显示）：
   - `createBy`、`updateBy`（操作人 ID）
   - 长文本字段（`content`、`description`）
   - 内部字段（`version`、`deleted`）

### 搜索表单默认字段

1. 取 `QueryParam` interface 中的字段
2. 默认搜索字段（3-5 个）：
   - 关键词搜索（名称/编码，input）
   - 状态筛选（select）
   - 时间范围（datePicker，如适用）
3. 排除字段：
   - 分页参数（`$pg`、`$rn`）
   - ID 精确查询（除非 PRD 明确要求）
   - 排序字段（`$ob`）

### 表单默认字段

1. 读取 API `Save`/`Update` 接口的请求参数类型
2. 默认表单字段：
   - 所有可编辑的业务字段
   - 必填字段标 `required`
3. 排除字段：
   - `id`（编辑时从 query 获取，新增时无）
   - `createTime`、`updateTime`（后端自动填充）
   - `createBy`、`updateBy`（后端自动填充）

## API 函数导入规则

### 列表页导入

```typescript
// 自动识别并导入以下函数（根据 PRD 操作需求）
import {
  {role}{Module}{Entity}List,           // 必导：列表
  {role}{Module}{Entity}LiteList,       // 按需：下拉数据源
  {role}{Module}{Entity}Load,           // 按需：编辑回显
  {role}{Module}{Entity}Save,           // 按需：新增
  {role}{Module}{Entity}Update,         // 按需：编辑
  {role}{Module}{Entity}Delete,         // 按需：删除
  {role}{Module}{Entity}Enable,         // 按需：启用
  {role}{Module}{Entity}Disable,        // 按需：禁用
  {role}{Module}{Entity}ListDataHistory,// 按需：历史
  {role}{Module}{Entity}ListCritLog,    // 按需：日志
  type {Entity},
  type {Entity}QueryParam
} from '@/api/{ApiFile}'
```

### 表单页导入

```typescript
import {
  {role}{Module}{Entity}Load,   // 编辑时加载数据
  {role}{Module}{Entity}Save,   // 新增
  {role}{Module}{Entity}Update, // 编辑
  type {Entity}
} from '@/api/{ApiFile}'
```

## 字段一致性检查表

生成代码后，逐项验证：

| 检查项 | 验证方法 | 通过标准 |
|--------|---------|---------|
| 表单字段名 | 对照 API interface | 字段名完全一致（camelCase） |
| 表格列 prop | 对照 API interface | prop 存在于 interface 中 |
| 搜索条件 field | 对照 QueryParam | field 存在于 QueryParam 中 |
| 状态值类型 | 对照 API interface | number，非 string |
| API 函数名 | 对照 `src/api/` 文件 | 函数名存在且正确 |
| 类型导入 | 检查 `type` 关键字 | 类型带 `type`，值不带 |
