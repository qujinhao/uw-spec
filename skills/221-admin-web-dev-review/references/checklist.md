# 管理端Web开发评审检查清单

> **源技能**：[220-admin-web-dev/SKILL.md](../../220-admin-web-dev/SKILL.md) — AI 原生开发，逐页面完整交付。评审必须以源技能和其 references 为准。

## 0. 自动化验证前置检查（强制）

> 以下检查必须在人工评审之前执行，未全部通过不得进入人工评审。

| 检查项 | 命令 | 通过标准 | 依据 |
|--------|------|---------|------|
| 页面内枚举 | `grep -rn 'const.*Options\s*=\s*\[' src/pages/ --include="*.vue" \| wc -l` | 0 | coding-principles.md |
| 内联样式 | `grep -rn 'style="' src/pages/ --include="*.vue" \| grep -v 'header-cell-style' \| wc -l` | 0 | coding-principles.md |
| any 类型 | `grep -rn ': any' src/pages/ --include="*.vue" \| grep -v 'proxy as any' \| wc -l` | 0 | coding-principles.md |
| ElMessageBox | `grep -rn 'ElMessageBox' src/pages/ --include="*.vue" \| wc -l` | 0 | coding-principles.md |
| res 未声明类型 | `grep -rn '\.then(.*res =>' src/pages/ --include="*.vue" \| wc -l` | 0 | coding-principles.md |
| 本地 TagType/Text 映射 | `grep -rn 'type ElTagType\|const.*TagType.*Record' src/pages/ --include="*.vue" \| wc -l` | 0 | coding-principles.md |
| onMounted | `grep -rn 'onMounted' src/pages/ --include="*.vue" \| wc -l` | 0 | coding-principles.md |
| 手动导入 Vue 自动导入项 | `grep -rn "import.*{.*ref.*}.*from 'vue'" src/pages/ --include="*.vue" \| wc -l` | 0 | coding-principles.md |
| DataList 字段 | `grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 | coding-principles.md |
| 类型检查 | `pnpm vue-tsc --noEmit` | 0 错误 | coding-principles.md |
| ESLint | `pnpm lint` | 0 错误 | coding-principles.md |
| 编译通过 | `pnpm build` | 0 错误 | Phase 2 Step 5 |
| 测试通过 | `pnpm test` 或项目已有 Vitest 命令 | 0 失败 | Phase 2 Step 4 |

## 1. Phase 0 需求确认（源技能 → Phase 0）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 页面清单 | PRD 中所有页面已识别，无遗漏 | Phase 0 |
| 页面分类 | 每个页面已标记简单/复杂，复杂页面有代码策略 | Phase 0 |
| 功能覆盖 | PRD 中所有功能点都有对应页面或组件 | Phase 0 |
| 核心流程 | 核心业务流程可在项目中走通 | Phase 0 |
| 角色覆盖 | 每个页面的角色归属与需求确认一致 | Phase 0 |

## 2. README.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 页面总览 | 每个页面有名称、说明、复杂度、代码策略 | Phase 1 |
| 角色权限映射 | 角色 × 页面的访问权限矩阵完整 | Phase 1 |
| 路由设计 | 路由路径符合 `/{project-name}/{role}/{module}/{page}` 规范 | Phase 1 |
| PRD 功能点映射 | 每个 PRD 功能点对应到页面和组件 | Phase 1 |
| 字段一致性检查表 | PRD 字段与 API interface 字段有对照记录 | Phase 1 |

## 3. TASKS.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 拓扑分组 | 按角色分组，组内可并行，组间串行 | Phase 1 |
| 页面分类 | 简单/复杂页面分类与 README.md 一致 | Phase 1 |
| 页面卡片 | 每个页面包含文件、PRD、API、类型、功能、交互、Store、复杂度信息 | Phase 1 |
| 进度状态 | 所有页面已标记完成 | Phase 1 |

## 4. 编译与规范验证（源技能 → Phase 2 Step 5）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| pnpm build | 无编译错误 | Step 5 |
| pnpm vue-tsc --noEmit | 无类型错误 | Step 5 |
| pnpm lint | 无 ESLint 错误 | coding-principles.md |
| 编码规范验证 | 9 条 grep 命令输出均为 0 | coding-principles.md |

## 5. 页面质量（源技能 → Phase 2 Step 2，逐页面检查）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 角色目录 | 页面已移动到 `pages/{role}/` 或项目约定的角色层级目录 | Step 2 + web-dev-standards.md |
| 导入路径修正 | 移动后页面内导入路径已更新 | Step 2 |
| SFC 结构顺序 | template → script setup lang="ts" → style scoped | web-dev-standards.md |
| 导入顺序 | Vue类型 → 组件类型 → API → 第三方 → hooks/工具 | web-dev-standards.md |
| 枚举集中管理 | 状态/选项枚举在 `selectOptions.ts` 的 `useCommonSelectTypes()`，禁止页面内定义 | Step 2 + coding-principles.md |
| 路由配置 | 角色级路由已注册，权限使用 appMenu，禁止 `meta.roles` 硬编码 | Step 2 |
| SearchForm componentType | 仅使用白名单：input/select/datePicker/selectv2/inputNumber/cascader/selectAndDatePicker/inputNumberRange/timePicker/radio | Step 2 |
| 弹窗按钮顺序 | 取消在左（icon="Close"），保存在右（icon="Check"） | 架构约定 |
| v-for 变量名 | 使用描述性名称，禁止单字母 | 架构约定 |
| placeholder | 所有表单控件包含 placeholder | 架构约定 |
| 自动导入 | 不手动导入 ref/computed/onMounted 等已配置自动导入项 | 架构约定 |
| useActivated | 列表页使用 useActivated 替代 onMounted | 架构约定 |
| useCrud | CRUD 操作使用 useCrud hooks | 架构约定 |
| Pagination | 分页使用 Pagination 组件，禁止 el-pagination | 架构约定 |
| 无空壳/TODO | 页面包含完整模板、逻辑、样式，无 TODO 标记 | Step 2 |

## 6. API对接质量（源技能 → Phase 2 Step 3）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 真实 API | mock/占位数据已替换为真实 API 调用 | Step 3 |
| 响应类型声明 | `.then((res: ResponseData<Xxx>)` 中 res 声明类型 | Step 3 |
| 错误处理 | 统一使用 `res.state === 'success'` 判断，失败时提示 `res.msg` | Step 3 |
| 加载状态 | API 调用前 loading = true，完成（含 catch）后 loading = false | Step 3 |
| 列表数据取值 | 使用 `res.data?.results`，禁止 `res.data?.list` | Step 3 |
| 启用/禁用 | useSimplifyPrompt → API → ElMessage.success → 刷新列表 | Step 3 |
| 删除确认 | useSimplifyPrompt → API → 刷新列表 | Step 3 |
| 表单提交 | 校验 → API → 成功后关闭弹窗/返回列表 | Step 3 |
| 搜索/重置 | SearchForm @search / @change 事件触发 handleList | Step 3 |
| 分页事件 | Pagination @page-size-change / @current-change | Step 3 |
| 导出 | 使用 useExportExcel hooks | Step 3 |
| useSimplifyPrompt | 确认操作使用 useSimplifyPrompt，禁止 ElMessageBox | Step 3 |

## 7. 状态管理质量（源技能 → Phase 2 Step 3）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| Pinia setup 风格 | Store 使用 setup 风格（defineStore + setup 函数） | web-dev-standards.md |
| State 用 ref | Store 中 State 使用 ref | web-dev-standards.md |
| Getters 用 computed | Store 中 Getters 使用 computed | web-dev-standards.md |
| Actions 普通函数 | Store Actions 使用普通函数 | web-dev-standards.md |
| 跨页面共享 | 跨页面共享状态使用 Pinia Store | Step 3 |
| 页面私有 | 页面私有状态使用 ref/reactive | Step 3 |
| 业务组件提取 | 多页面复用 UI → src/components/business/，复用逻辑 → src/hooks/useXxx.ts | Step 3 |

## 8. 字段一致性（源技能 → Phase 2 Step 1/5）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 表单字段名 | 与 API Schema 字段名一致（camelCase） | Step 1 + Step 5 |
| 表格列 prop | 与后端返回字段名一致，prop 值存在于 interface | Step 5 |
| 搜索条件 field | 与 QueryParam 字段一致 | Step 5 |
| 状态字段值 | 使用 number 而非 string | Step 5 |
| API interface 已读取 | 开发前已读取 API 类型定义，字段名来源于 interface | Step 1 |
| DataList 类型 | 列表 API 使用 `ResponseData<DataList<T>>` | 数据结构规范 |

## 9. 测试质量（源技能 → Phase 2 Step 4）

> **AI 原生 TDD**：开发阶段执行 Red-Green-Refactor 内部循环；评审阶段只验收最终测试质量和全绿结果。

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 测试框架 | 使用 Vitest | Step 4 |
| 测试全绿 | `pnpm test` 或项目已有 Vitest 命令全部通过 | Step 4 |
| composables/hooks | 核心逻辑分支覆盖 | Step 4 |
| Store actions | 状态变更正确性测试 | Step 4 |
| 工具函数 | 边界条件覆盖 | Step 4 |
| 断言有效 | 测试断言能覆盖失败场景，禁止仅快照或空断言 | Step 4 |
| 无 TODO 残留 | 测试文件中无 TODO 标记 | Step 4 |

## 10. 安全性（源技能 → 架构约定 + web-dev-standards.md）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| XSS 防护 | 用户输入经过转义，禁止 v-html 渲染用户输入 | web-dev-standards.md |
| Token 管理 | Token 不存储在 localStorage，使用 httpOnly Cookie 或内存 | web-dev-standards.md |
| API 拦截 | 所有 API 调用经拦截器添加 Token，401 自动跳转登录 | web-dev-standards.md |
| 路由守卫 | 页面级权限通过路由守卫控制 | 架构约定 |
| 按钮权限 | 按钮级权限通过指令控制 | 架构约定 |

## 11. 性能优化（源技能 → Phase 2 Step 3 + web-dev-standards.md）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 路由懒加载 | 页面组件使用动态 import() 加载 | web-dev-standards.md |
| keep-alive | 内容区使用 keep-alive 缓存已访问页面 | web-dev-standards.md |
| 组件按需加载 | 大型组件使用 defineAsyncComponent | Step 3 |
| 分页查询 | 表格单页 ≤ 50 条 | web-dev-standards.md |
| 并行请求 | 独立请求使用 Promise.all | web-dev-standards.md |
| 状态管理效率 | 跨页面共享用 Store，页面私有用 ref/reactive | Step 3 |
