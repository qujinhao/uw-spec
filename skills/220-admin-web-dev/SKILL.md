---
name: 220-admin-web-dev
description: 管理端Web开发（AI原生，Vue3+TS+Vite+ElementPlus）。当需要基于PRD进行后台管理Web端开发时触发：(1)确认页面清单与角色权限映射, (2)编写架构蓝图README.md, (3)逐页面完整交付（页面+路由+API对接+交互+测试，一次写完直接通过）。当用户提及管理后台、Dashboard、SaaS后台、admin系统开发时使用此技能。适用于root/ops/saas/mch角色 ⚠️【强制】完成后必须调用 221-admin-web-dev-review，未通过前禁止声称完成。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# 管理端Web开发（AI 原生）

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 页面开发 + API对接 + 测试（一次完成） | `js-developer` |
| 协作 | 业务需求确认 | `product-manager` |

## 输入

| 输入项 | 来源路径 | 说明 |
|--------|----------|------|
| PRD | `PROJECT_ROOT/requirement/prds/*` | 产品需求文档 |
| API定义 | `PROJECT_ROOT/frontend/{project-name}-admin-web/src/api/` | gencode 生成的 API 函数和类型定义 |
| 前端项目 | `PROJECT_ROOT/frontend/{project-name}-admin-web/` | init 初始化 + gencode 生成的代码 |

## 前置条件

| 前置技能 | 说明 |
|---------|------|
| [220-admin-web-init](../220-admin-web-init/SKILL.md) | 前端项目已通过模板初始化 |
| [220-admin-web-gencode](../220-admin-web-gencode/SKILL.md) | api/types/pages 已由代码生成器生成 |

## 架构约定速查表

### 页面与路由约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 页面第一级为用户角色（`/saas/`、`/mch/`、`/admin/`、`/root/`、`/ops/`） | 平铺在 `pages/` 下不按角色分 |
| 路由 `/{project-name}/{role}/{module}/{page}` | 路由无角色层级 |
| 页面组件 PascalCase 命名 | 随意命名 |
| 代码生成器产出在 `src/pages/{module}/`，按角色移动 | 手动新建页面文件 |
| `src/api/` 由 gencode 生成，只读不改 | 手动修改 gencode 产出的 API 文件 |

### 编码约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 权限控制使用 appMenu 动态菜单系统 | 在路由 meta 中硬编码 roles |
| 枚举统一到 `selectOptions.ts` 的 `useCommonSelectTypes` | 页面内定义 `const xxxOptions = [...]` |
| 分页使用 `Pagination` 组件 | 使用 `el-pagination` |
| 确认弹窗使用 `usePrompt` / `useSimplifyPrompt` | 直接调用 `ElMessageBox` |
| 列表页加载使用 `useActivated` | 使用 `onMounted` |
| CRUD 操作使用 `useCrud` hooks | 手写增删改查逻辑 |
| `ref`/`computed`/`onMounted` 等自动导入，不手动 import | 手动 `import { ref } from 'vue'` |
| `src/components` 下组件自动导入（`components.d.ts`），不手动 import | 手动 import 组件 |
| 类型导入 `import { type Xxx, fn } from '...'` | 混合导入值和类型不加 type |

### 数据与样式约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 表单字段名与 API Schema 一致（camelCase） | 凭 PRD 描述猜测字段名 |
| 状态字段值使用 number（`0`、`1`、`2`） | 使用 string（`'draft'`、`'published'`） |
| 列表数据取值 `res.data?.results` | `res.data?.list` |
| v-for 变量描述性名称（`item`、`option`） | 单字母（`s`、`i`、`e`） |
| 样式使用 CSS 类 | `style="..."` 内联样式 |
| 表单控件包含 `placeholder` 属性 | 无 placeholder |
| 弹窗按钮：取消在左（icon="Close"），保存在右（icon="Check"） | 按钮顺序不一致 |
| 禁用按钮：`<el-button type="info"><i class="iconfont jinyong"></i></el-button>` | `icon="CircleClose"` 等 Element Plus 图标 |
| SearchForm `formItemWidth` 普通项 280、时间范围 480、其他范围 380 | 自由设值（240/300/320 等） |
| 状态字段 `el-tag` type：1=success / 0=info / -1=danger，文本用 `handleTypeForLabel(row.state, commonTypes)` | 三元表达式硬编码（`row.state === 1 ? '启用' : '停用'`） |
| 时间字段展示统一 `{{ formatDate(row.xxxDate) }}` | `row.xxxDate ? formatDate(row.xxxDate) : '--'`（formatDate 内部已处理空值） |
| 表单/详情页表单项必须用 `el-row + el-col` 包裹，`el-col` 统一 `:xl="10" :lg="12"`（数字绑定，不用 `span`），表单组件默认宽度 100% | 用 `:span=` 写死栅格、用无冒号 `xl="10"` 传字符串、表单组件设固定像素宽度 |
| `el-table` 统一配置：`:style="{ width: '100%' }"` + `:header-cell-style="{ backgroundColor: 'var(--el-color-info-light-9)' }"` + `stripe` | 自定义表格背景色 / 无 stripe / 无统一宽度 |
| 币种下拉统一用 `currencyTypes` from `useCommonSelectTypes`，不手写 CNY/USD/JPY/HKD 等 option | 页面内硬编码 `<el-option label="人民币" value="CNY"/>` |
| 图片/文件上传统一用 `UploadFile` 组件，配 `v-model:fileListForShow` + `v-model:fileListForUpload` + `uploadParams` | 用 `el-upload` 直接接 OSS / 用 `el-input` 让用户粘贴 URL |
| 表单项 `size` 默认不设置（让 `el-form` 全局统一），表单内 `el-input` / `el-select` / `el-button` / `el-input-number` / `el-date-picker` / `el-time-picker` 等组件均不写 `size="small"` / `size="large"` | 表单内组件单独设 `size="small"`、`size="large"` 等导致大小不一致 |
| API 响应类型 `.then((res: ResponseData<Xxx>)` | `.then(res =>` 无类型 |

> 编码规范详见 [coding-principles.md](references/coding-principles.md)，目录结构和框架规范详见 [web-dev-standards.md](references/web-dev-standards.md)

## 数据结构规范

| API 类型 | 返回类型 | 取值方式 |
|---------|---------|---------|
| 列表 API | `ResponseData<DataList<T>>` | `res.data?.results` → `T[]`，`res.data?.total` |
| 实体 API | `ResponseData<T>` | `res.data` → `T` |
| 无返回值 API | `ResponseData<void>` | `res.state === 'success'` |

**禁止使用**：`res.data?.list`（DataList 的数组字段固定为 `results`）

## 工作流程

### Phase 0: 需求确认

| 确认项 | 目的 | 启发式问题 |
|--------|------|-----------|
| 页面清单 + 复杂度分类 | 决定裁剪策略和开发工作量 | "根据PRD，识别到N个页面[列出]，是否有遗漏？" |
| 角色权限映射 | 确定页面归属角色 | "各页面分别属于哪个角色（root/ops/saas/mch）？" |
| 定制页面 | 确认非标准页面 | "除标准CRUD页面外，还有哪些定制页面？" |

页面分类决策：

| 分类 | 条件 | 代码策略 |
|------|------|---------|
| 简单页面 | 仅标准CRUD（列表/详情/表单） | 代码生成器产出，裁剪即可 |
| 复杂页面 | 含特殊交互、多表联动、自定义布局 | 基于生成器页面改造或新建 |

**完成标准**：页面清单无遗漏、每个页面复杂度已分类、角色权限已映射。

### Phase 1: 架构蓝图

**输入**：PRD 文档 + Phase 0 确认结果
**输出**：前端项目根目录 `README.md` 和 `TASKS.md`

| 文件 | 定位 | 内容 |
|------|------|------|
| `README.md` | 架构蓝图（给人+AI 读） | 页面总览、角色权限映射、路由设计、PRD功能点映射、字段一致性检查表 |
| `TASKS.md` | 进度清单（仅追踪） | 拓扑分组（按角色）、页面分类、状态复选框 |

**模板**：参见 [design-templates.md](references/design-templates.md)

### Phase 2: 逐页面完整交付

按 TASKS.md 的拓扑分组顺序，**每组内可并行，组间串行**。每个页面执行以下步骤：

#### Step 1: 加载上下文

| 操作 | 说明 |
|------|------|
| 读 PRD 相关章节 | 确认页面功能需求、交互要求 |
| 读 API 类型定义 | `src/api/` 中对应 TypeScript interface，记录字段名和类型 |
| 读后端 Swagger（按需） | 联调时读取接口定义，确认请求/响应结构 |
| 对照字段 | PRD 字段需求 ↔ API 字段名一一对应，不一致立即标注 |

#### Step 2: 创建页面 + 配置路由

> **一次写完，不建空壳**。页面包含完整的模板、逻辑和样式，无 TODO 标记。

| 操作 | 说明 |
|------|------|
| 按角色移动 | 根据 README.md 角色权限映射，将 `{module}/` 移动到目标角色目录 |
| 修正导入路径 | 更新页面内的组件导入路径 |
| 裁剪搜索表单 | 精简搜索字段（3-5个），使用 SearchForm 支持的 componentType |
| 裁剪列表列 | 按业务需求增删表格列，字段名与 API 返回字段一致 |
| 裁剪弹窗表单 | 按业务需求增删表单项，字段名与 API Schema 一致 |
| 补充字段校验 | 添加内联 `rules` 校验规则 |
| 新增枚举 | 状态/选项枚举添加到 `selectOptions.ts` 的 `useCommonSelectTypes` |
| 配置路由 | 在 `src/router/index.ts` 中注册路由，权限守卫使用 appMenu |

**SearchForm componentType 白名单**：

`input` | `select` | `datePicker` | `selectv2` | `inputNumber` | `cascader` | `selectAndDatePicker` | `inputNumberRange` | `timePicker` | `radio`

> 禁止使用 `dateRange`、`date`、`checkbox` 等不在白名单中的 componentType。

**SearchForm componentType 选型规则**（按业务场景，不是按白名单顺序）：

| 业务场景 | API 字段类型 | componentType | 关键属性 |
|---|---|---|---|
| 时间段范围（创建时间/修改时间等 Range） | Array<string> | `datePicker` | `type: 'datetimerange'` + `shortcuts` |
| 单个日期 | string | `datePicker` | `type: 'date'` 或 'datetime' |
| 单选下拉（状态/类型枚举） | number | `select` | `options: xxxTypes.value` |
| 多选下拉 | Array<number> | `selectv2` | `multiple: true` |
| 关键字搜索 | string | `input` | `enterable: true` |
| 数值范围 | Array<number> | `inputNumberRange` | - |
| 时间段（仅时分） | Array<string> | `timePicker` | - |
| 层级选择 | Array<string/number> | `cascader` | - |

> ❌ 禁用：`selectAndDatePicker` 用于纯范围搜索（它是"单选+单日期"组合，不是范围）

**页面模板**：参见 [code-templates.md](references/code-templates.md)

#### Step 3: API 对接 + 交互完善

| 操作 | 说明 |
|------|------|
| 替换 mock 数据 | 将页面中的占位数据替换为真实 API 调用 |
| 响应类型声明 | `.then((res: ResponseData<Xxx>)` 中 res 必须声明类型 |
| 错误处理 | 统一使用 `res.state === 'success'` 判断，失败时 `ElMessage.error(res.msg)` |
| 加载状态 | API 调用前 `loading = true`，完成（含 catch）后 `loading = false` |
| 列表数据 | 使用 `res.data?.results`（非 `res.data?.list`） |
| 启用/禁用 | `useSimplifyPrompt` → API 调用 → `ElMessage.success` → 刷新列表 |
| 删除确认 | `useSimplifyPrompt` → API 调用 → 刷新列表 |
| 表单提交 | 表单校验 → API 调用 → 成功后关闭弹窗/返回列表 |
| 搜索/重置 | SearchForm `@search` / `@change` 事件触发 `handleList` |
| 分页 | Pagination 组件 `@page-size-change` / `@current-change` 事件 |
| 导出 | `useExportExcel` hooks |
| 状态管理 | 跨页面共享状态使用 Pinia Store（Options 风格），页面私有使用 `ref`/`reactive` |
| 业务组件 | 多页面复用 UI 提取到 `src/components/business/`，复用逻辑提取为 `src/hooks/useXxx.ts` |

#### Step 4: 测试驱动开发（Red-Green 内部循环）

> **AI 原生 TDD**：内部自动执行 Red-Green 循环，用户只看到最终通过的结果。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)。

**4.1 Red 阶段**：
- 为 composable/hook/Store 编写测试代码
- 执行 `pnpm vitest run src/composables/useXxx.spec.ts` → **确认测试失败**
- ⚠️ 如果测试意外通过 → 说明断言不够严格，需加强

**4.2 Green 阶段**：
- 编写实现代码
- 执行 `pnpm vitest run src/composables/useXxx.spec.ts` → **确认测试通过**

**4.3 Refactor 阶段**（按需）：
- 优化代码结构
- 执行 `pnpm vitest run` → 确认仍然通过

| 测试对象 | 工具 | 覆盖范围 |
|---------|------|---------|
| composables/hooks | Vitest | 核心逻辑分支覆盖 |
| Store actions | Vitest | 状态变更正确性 |
| 工具函数 | Vitest | 边界条件 |

#### Step 5: 页面验证

**字段一致性检查**：

| 检查项 | 要求 | 验证方法 |
|--------|------|---------|
| 表单字段名 | 与 API Schema 字段名一致（camelCase） | 逐项对照 interface |
| 表格列 prop | 与后端返回字段名一致 | prop 值必须存在于 interface 中 |
| 搜索条件 field | 与 QueryParam 字段一致 | 逐项对照 QueryParam interface |
| 状态/类型字段值 | 使用 number 而非 string | 确认 interface 中字段类型为 number |

**编码规范验证**：

```bash
cd frontend/{project-name}-admin-web

grep -rn 'const.*Options\s*=\s*\[' src/pages/ --include="*.vue" | wc -l
grep -rn 'style="' src/pages/ --include="*.vue" | grep -v 'header-cell-style' | wc -l
grep -rn ': any' src/pages/ --include="*.vue" | grep -v 'proxy as any' | wc -l
grep -rn 'ElMessageBox' src/pages/ --include="*.vue" | wc -l
grep -rn '\.then(.*res =>' src/pages/ --include="*.vue" | wc -l
grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" | wc -l
grep -rn 'onMounted' src/pages/ --include="*.vue" | wc -l
grep -rn "import.*from '@/components/" src/pages/ --include="*.vue" | grep -v "type\|SearchFormType" | wc -l
grep -rn 'interface commonType' src/pages/ --include="*.vue" | wc -l
```

以上命令输出均应为 `0`。完整验证命令见 [coding-principles.md](references/coding-principles.md)。

**编译验证**：

```bash
pnpm build && pnpm vue-tsc --noEmit
```

**全部通过后**，在 TASKS.md 中标记该页面为已完成，进入下一个页面。

## 完成标准

- [ ] README.md 覆盖所有页面和角色权限映射
- [ ] TASKS.md 包含拓扑分组，所有页面已标记完成
- [ ] 所有 PRD 功能点都有对应页面
- [ ] 每个页面已读取 API interface 定义后再开发
- [ ] 表单字段名与 API Schema 字段名一致
- [ ] 列表数据使用 `res.data?.results`（非 `res.data?.list`）
- [ ] 状态/类型字段使用 number 值（非 string）
- [ ] 无 `as any`（模板框架 `proxy as any` 除外）
- [ ] SearchForm componentType 全部使用白名单中的值
- [ ] 页面按模块+角色正确组织到 `pages/{模块名}/{角色}/` 目录
- [ ] 路由配置正确，权限控制正常
- [ ] `pnpm build` 编译通过
- [ ] `pnpm vue-tsc --noEmit` 无类型错误
- [ ] 编码规范验证命令全部输出 0

## ⚠️ 完成验证（强制，全自动执行）

1. **强制调用** `221-admin-web-dev-review`
2. 不通过（< 95）→ 自动修复 → 重新评审（最多 5 轮）
3. 通过（≥ 95）→ 向用户报告最终结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [Web 开发规范](references/web-dev-standards.md) - Vue3+TS+Vite+Element Plus 架构和框架规范
- [编码原则](references/coding-principles.md) - 四条核心原则 + 自动化验证命令
- [设计模板](references/design-templates.md) - README页面清单 + TASKS.md模板
- [代码模板](references/code-templates.md) - 列表页/详情页/表单页代码模板
- [页面类型规则](references/page-type-rules.md) - PRD关键词→页面类型/复杂度/目录命名
- [API Schema映射](references/api-schema-mapping.md) - API字段→前端组件映射规范
- [Web 端评审技能](../221-admin-web-dev-review/SKILL.md)
