---
name: 221-admin-web-dev-review
description: 管理端Web开发评审（Vue3+TS+Vite+ElementPlus）。当220-admin-web-dev完成后触发：(1)校验README/TASKS与角色路由, (2)检查页面/API/字段/编码规范, (3)执行build、vue-tsc、lint与自动化grep验证并驱动修复循环。管理后台评审时使用。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.1.0"
---

# 管理端Web开发评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [220-admin-web-dev/SKILL.md](../220-admin-web-dev/SKILL.md) | **必读全文**：架构约定、Phase 0-2、完成标准、强制评审循环 |
| [220-admin-web-dev/references/coding-principles.md](../220-admin-web-dev/references/coding-principles.md) | **唯一编码规范来源**：四条核心原则、11 条自动化验证命令 |
| [220-admin-web-dev/references/web-dev-standards.md](../220-admin-web-dev/references/web-dev-standards.md) | Vue3+TS+Vite+ElementPlus 架构、目录、路由、Pinia、性能规范 |
| [220-admin-web-dev/references/design-templates.md](../220-admin-web-dev/references/design-templates.md) | README.md / TASKS.md 结构要求 |
| [220-admin-web-dev/references/code-templates.md](../220-admin-web-dev/references/code-templates.md) | 标准页面代码形态 |
| [220-admin-web-dev/references/dev-templates.md](../220-admin-web-dev/references/dev-templates.md) | CRUD 页面与 selectOptions 实现细节 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 代码质量审计 + 架构评审 + 修复闭环跟踪 | `js-lead` |
| 协作 | 需求符合度 | `product-manager` |
| 协作 | 原型评审 | `prototype-reviewer` |
| 协作 | 技术可行性 | `system-architect` |

## 输入

| 输入项 | 位置 | 说明 |
|--------|------|------|
| 前端项目 | `PROJECT_ROOT/frontend/{project-name}-admin-web/` | 220 逐页面交付产出的可运行项目 |
| README.md | 前端项目根目录 | 架构蓝图：页面总览、角色权限、路由、PRD 映射 |
| TASKS.md | 前端项目根目录 | 拓扑分组和页面完成状态 |
| PRD 文档 | `PROJECT_ROOT/requirement/prds/*` | 功能需求参考 |
| API 定义 | `src/api/` | gencode 生成的 API 函数和类型定义，只读不改 |
| 测试文件 | `src/**/*.spec.ts` / `src/**/*.test.ts` | Vitest 单元测试 |

## 输出

| 输出项 | 位置 | 要求 |
|--------|------|------|
| 评审报告 | `issue/reviews/REVIEW-DEV-YYMMDDHHMM.md` | 使用统一评审报告模板，记录分数、问题、修复轮次、最终结论 |

格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

> 详细检查清单见 [checklist.md](references/checklist.md)。

| 维度 | 检查要点 | 分值 |
|------|---------|------|
| README.md 完整性 | 页面总览、角色权限映射、路由设计、PRD功能点映射、字段一致性检查表 | 10分 |
| TASKS.md 完整性 | 拓扑分组、页面分类、状态复选框、全部标记完成 | 5分 |
| 需求符合度 | PRD功能覆盖、核心流程、角色覆盖、复杂页面处理 | 10分 |
| 页面质量 | 角色目录、SFC结构、导入顺序、SearchForm、Pagination、useCrud、useActivated | 20分 |
| API对接质量 | 响应类型、错误处理、loading、DataList.results、确认弹窗、导出 | 15分 |
| 字段一致性 | 表单字段、表格列、搜索条件、状态值均与 API interface 一致 | 10分 |
| 状态管理质量 | Pinia setup风格、跨页面共享、页面私有状态、业务组件/Hook 提取 | 5分 |
| 编码原则 | 集中管理、类型安全、项目一致性、代码可读性、自动化验证全过 | 10分 |
| 测试质量 | Vitest 覆盖 composables/hooks/Store/工具函数，最终全绿，无 TODO | 5分 |
| 安全性 | XSS、Token、API拦截、路由守卫、按钮权限 | 5分 |
| 性能优化 | 路由懒加载、keep-alive、组件按需、分页与并行请求 | 5分 |

## 通过标准

| 等级 | 分值 | Critical | Major |
|------|------|----------|-------|
| 通过 | ≥ 95 | 0 | ≤1 |
| 不通过 | < 95 | 存在 或 Major >1 | — |

> 评分 < 95 进入修复循环，无“有条件通过”中间态。

## 评审流程

> 开始前，先按“源技能引用”读取源技能，按“输入”读取所有评审对象。

### 1. 自动化验证（前置步骤）

在 `frontend/{project-name}-admin-web` 下执行以下验证，未全部通过不得进入维度评审。

| 验证项 | 命令来源 | 通过标准 |
|--------|----------|----------|
| 编码规范 grep | [coding-principles.md](../220-admin-web-dev/references/coding-principles.md) 的 1-9 条命令 | 输出均为 `0` |
| TypeScript | `pnpm vue-tsc --noEmit` | 0 错误 |
| ESLint | `pnpm lint` | 0 错误 |
| 构建 | `pnpm build` | 0 错误 |
| 测试 | `pnpm test` 或项目已有 Vitest 命令 | 0 失败 |

**必须覆盖的 grep 检查**：页面内枚举、内联样式、`: any`、`ElMessageBox`、`.then(res =>`、本地 TagType/Text 映射、`onMounted`、手动导入 Vue 自动导入项、`res.data?.list`。

### 2. 按维度评审

逐项检查并记录问题，严重级别按下表判定。

| 级别 | 判定条件 | 处理 |
|------|----------|------|
| Critical | 编译失败、类型失败、核心流程不可用、权限绕过、API 字段严重不一致 | 必须修复后重评 |
| Major | 页面功能缺失、规范批量违规、测试缺失、状态/分页/搜索不可用 | >1 个不通过 |
| Minor | 文案、局部样式、个别可读性问题 | 可计入扣分 |

### 3. 修复循环

| 结果 | 动作 |
|------|------|
| ≥ 95 且 Critical=0 且 Major≤1 | 输出评审报告，任务结束 |
| < 95 或 Critical>0 或 Major>1 | 立即调用 `220-admin-web-dev`，传入问题清单，修复完成后重新评审 |

修复循环最多 5 轮。仅在通过或轮次耗尽时输出结果。

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [评审检查清单](references/checklist.md)
- [编码原则](../220-admin-web-dev/references/coding-principles.md)
- [Web 开发规范](../220-admin-web-dev/references/web-dev-standards.md)
- [设计模板](../220-admin-web-dev/references/design-templates.md)
- [代码模板](../220-admin-web-dev/references/code-templates.md)
- [开发模板](../220-admin-web-dev/references/dev-templates.md)
- [评审报告模板](../0-init/references/review-report-template.md)
