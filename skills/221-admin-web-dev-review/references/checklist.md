# 管理端Web开发评审检查清单

> **源技能**：[220-admin-web-dev/SKILL.md](../../220-admin-web-dev/SKILL.md) — AI 原生开发，逐页面完整交付。下表"依据"列指向源技能的具体 Phase/Step。

## 0. 自动化验证前置检查（强制）

> 以下检查必须在人工评审之前执行，未全部通过不得进入人工评审。

| 检查项 | 命令 | 通过标准 | 依据 |
|--------|------|---------|------|
| any 类型 | `grep -rn ': any' src/ --include="*.vue" --include="*.ts" \| grep -v 'proxy as any' \| wc -l` | 0 行 | Phase 2 Step 5 |
| DataList 字段 | `grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" \| wc -l` | 0 行 | Phase 2 Step 5 |
| 页面内枚举 | `grep -rn 'const.*Options\s*=\s*\[' src/pages/ --include="*.vue" \| wc -l` | 0 行 | Phase 2 Step 2 |
| 内联样式 | `grep -rn 'style="' src/pages/ --include="*.vue" \| grep -v 'header-cell-style' \| wc -l` | 0 行 | coding-principles.md |
| ElMessageBox | `grep -rn 'ElMessageBox' src/pages/ --include="*.vue" \| wc -l` | 0 行 | Phase 2 Step 3 |
| 编译通过 | `pnpm build` | 0 错误 | Phase 2 Step 5 |
| 类型检查 | `pnpm vue-tsc --noEmit` | 0 错误 | Phase 2 Step 5 |

## 1. Phase 0 需求确认（源技能 → Phase 0）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 功能覆盖 | PRD 中所有功能点都有对应页面 | Phase 0 |
| 核心流程 | 核心业务流程可在项目中走通 | Phase 0 |
| 角色覆盖 | 每个页面的角色归属与 Phase 0 确认一致 | Phase 0 |

## 2. README.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 页面总览 | 每个页面有名称、说明、复杂度、代码策略 | Phase 1 |
| 角色权限映射 | 角色 × 页面的访问权限矩阵 | Phase 1 |
| 路由设计 | 路由路径符合 `/{project-name}/{role}/{module}/{page}` 规范 | Phase 1 |
| PRD 功能点映射 | 每个 PRD 功能点对应到页面和组件 | Phase 1 |

## 3. TASKS.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 拓扑分组 | 按角色分组，组内可并行 | Phase 1 |
| 页面卡片 | 每个页面包含文件/PRD/API/类型/功能/交互/Store/复杂度信息 | Phase 1 |
| 进度状态 | 所有页面已标记完成 | Phase 1 |

## 4. 编译验证（源技能 → Phase 2 Step 5）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| pnpm build | 无编译错误 | Step 5 |
| pnpm vue-tsc --noEmit | 无类型错误 | Step 5 |
| 编码规范验证 | 7 条 grep 命令输出均为 0 | Step 5 |

## 5. 页面质量（源技能 → Phase 2 Step 2，逐页面检查）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 角色目录 | 页面已移动到 `pages/{role}/` 目录 | Step 2 |
| 导入路径修正 | 移动后页面内导入路径已更新 | Step 2 |
| SFC 结构顺序 | template → script setup lang="ts" → style scoped | web-dev-standards.md |
| 导入顺序 | 类型→组件→API→composables→响应式状态→方法→生命周期 | web-dev-standards.md |
| 枚举集中管理 | 状态/选项枚举在 `selectOptions.ts`，禁止页面内定义 | Step 2 |
| 路由配置 | 角色级路由已注册，权限使用 appMenu | Step 2 |
| SearchForm componentType | 仅使用白名单中的值 | Step 2 |
| 弹窗按钮顺序 | 取消在左（Close），保存在右（Check） | 架构约定 |
| v-for 变量名 | 使用描述性名称，禁止单字母 | 架构约定 |
| placeholder | 所有表单控件包含 placeholder | 架构约定 |
| 自动导入 | 不手动导入 ref/computed/onMounted 等已配置自动导入项 | 架构约定 |
| useActivated | 列表页使用 useActivated 替代 onMounted | 架构约定 |
| useCrud | CRUD 操作使用 useCrud hooks | 架构约定 |
| Pagination | 分页使用 Pagination 组件，禁止 el-pagination | 架构约定 |

## 6. API对接质量（源技能 → Phase 2 Step 3）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 响应类型声明 | `.then((res: ResponseData<Xxx>)` 中 res 声明类型 | Step 3 |
| 错误处理 | 统一使用 `res.state === 'success'` 判断 | Step 3 |
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

## 9. 测试质量（源技能 → Phase 2 Step 4）

> **AI 原生关键**：测试与实现同步编写，直接通过，无 Red 阶段。

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 测试框架 | 使用 Vitest | Step 4 |
| 测试全绿 | `pnpm test` 全部通过，不存在 Red 骨架阶段 | Step 4 |
| composables/hooks | 核心逻辑分支覆盖 | Step 4 |
| Store actions | 状态变更正确性测试 | Step 4 |
| 工具函数 | 边界条件覆盖 | Step 4 |
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
| 状态管理效率 | 跨页面共享用 Store，页面私有用 ref/reactive | Step 3 |
