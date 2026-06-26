---
name: 221-guest-uni-dev-review
description: 消费者端UniApp开发评审（Vue3+TS）。当220-guest-uni-dev完成后触发：(1)校验README/TASKS、pages.json与TabBar, (2)检查页面/API/字段/i18n/多端适配, (3)执行pnpm check、H5/小程序编译与grep验证并驱动修复循环。guest端评审时使用。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.1.0"
---

# 消费者端 UniApp 开发评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [220-guest-uni-dev/SKILL.md](../220-guest-uni-dev/SKILL.md) | **必读全文**：架构约定、Phase 0-2、完成标准、强制评审循环 |
| [220-guest-uni-dev/references/coding-principles.md](../220-guest-uni-dev/references/coding-principles.md) | **唯一编码规范来源**：四条核心原则、pnpm 检查命令、18 项辅助 grep 扫描 |
| [220-guest-uni-dev/references/md-dev-standards.md](../220-guest-uni-dev/references/md-dev-standards.md) | UniApp 架构、分包、UI、Pinia、登录/Token、枚举、请求、i18n、平台适配规范 |
| [220-guest-uni-dev/references/md-design-spec.md](../220-guest-uni-dev/references/md-design-spec.md) | 移动端体验与设计规范 |
| [220-guest-uni-dev/references/design-templates.md](../220-guest-uni-dev/references/design-templates.md) | README.md / TASKS.md 结构要求 |
| [220-guest-uni-dev/references/code-templates.md](../220-guest-uni-dev/references/code-templates.md) | 页面代码模板 |
| [220-guest-uni-dev/references/dev-examples.md](../220-guest-uni-dev/references/dev-examples.md) | 开发示例 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 架构评审 + 页面质量审计 + 修复闭环跟踪 | `js-lead` |
| 协作 | 需求符合度 | `product-manager` |
| 协作 | 消费者端体验 | `prototype-reviewer` |
| 协作 | 移动端实现 | `js-developer` |

## 输入

| 输入项 | 位置 | 说明 |
|--------|------|------|
| 前端项目 | `PROJECT_ROOT/frontend/{project-name}-guest-uni/` | 220 开发阶段产出的可运行项目 |
| README.md | 前端项目根目录 | 架构蓝图：页面总览、TabBar、PRD 映射、路由、字段、平台适配 |
| TASKS.md | 前端项目根目录 | 并行分组和页面完成状态 |
| PRD 文档 | `PROJECT_ROOT/requirement/prds/*` | 功能需求参考 |
| API 定义 | `src/api/` | gencode 生成的 API 函数和类型定义，只读不改 |
| pages.json | `src/pages.json` | 主包、分包、TabBar、easycom、平台条件配置 |
| 页面代码 | `src/pages/`、`src/packages/`、`src/{module}/` | 主包公共页面和业务分包页面 |
| 测试文件 | `tests/**/*.spec.ts` / `src/**/*.spec.ts` | Vitest 单元测试 |

## 输出

| 输出项 | 位置 | 要求 |
|--------|------|------|
| 评审报告 | `issue/reviews/REVIEW-DEV-YYMMDDHHMM.md` | 使用统一评审报告模板，记录分数、问题、修复轮次、最终结论 |

格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

> 详细检查清单见 [checklist.md](references/checklist.md)。

| 维度 | 检查要点 | 分值 |
|------|---------|------|
| README.md 完整性 | 页面总览、TabBar配置、PRD功能点映射、路由设计、字段一致性、平台适配策略 | 10分 |
| TASKS.md 完整性 | 并行分组、页面简单/复杂分类、状态复选框、全部标记完成 | 5分 |
| 需求符合度 | PRD功能覆盖、核心流程、消费者端页面链路、目标平台覆盖 | 10分 |
| 页面质量 | 主包/分包组织、SFC结构、API调用、状态管理、分享配置、无空壳/TODO | 15分 |
| pages.json 与 TabBar | 主包/分包注册、navigationBarTitleText、TabBar按 PRD 配置、Tab页主包注册 | 10分 |
| API 与字段一致性 | ResponseData、DataList.list、state 判定、DTO字段、错误处理、Loading finally | 10分 |
| 编码原则 | 集中管理、类型安全、项目一致性、可读性、oxlint/oxfmt/pnpm check 全过 | 10分 |
| UI / 样式 / i18n | uni-ui/uview/自研组件复用、Tailwind优先、主题色、4语言 key 同步 | 10分 |
| 登录/Token/枚举 | userStore/tokenManager、APIwhiteList、EnumConst/optionsConst、gen:enums 流程 | 5分 |
| 多端适配与分享 | 条件编译、H5/MP/App API隔离、微信分享、App分享、安全区 | 5分 |
| 测试质量 | Store/工具函数测试全绿、断言有效、无 TODO | 5分 |
| 安全与性能 | XSS、输入校验、分页、图片懒加载、分包体积、资源释放 | 5分 |

## 通过标准

| 等级 | 分值 | Critical | Major |
|------|------|----------|-------|
| 通过 | ≥ 95 | 0 | ≤1 |
| 不通过 | < 95 | 存在 或 Major >1 | — |

> 评分 < 95 进入修复循环，无“有条件通过”中间态。

## 评审流程

> 开始前，先按“源技能引用”读取源技能，按“输入”读取所有评审对象。

### 1. 自动化验证（前置步骤）

在 `frontend/{project-name}-guest-uni` 下执行以下验证，未全部通过不得进入维度评审。

| 验证项 | 命令来源 | 通过标准 |
|--------|----------|----------|
| 综合检查 | `pnpm check` | type-check + oxlint + oxfmt --check 全部通过 |
| 类型检查 | `pnpm type-check` | 0 错误 |
| Lint | `pnpm lint` | 0 错误 |
| 格式化 | `pnpm format:check` | 0 错误 |
| H5 编译 | `pnpm build:h5` | 0 错误 |
| 微信小程序编译 | `pnpm build:mp-weixin` | 0 错误 |
| 测试 | `pnpm vitest run` 或项目已有测试命令 | 0 失败 |
| 辅助 grep 扫描 | [coding-principles.md](../220-guest-uni-dev/references/coding-principles.md) 18 项扫描 | 硬性项为 0，人工审查项已确认合规 |

**必须覆盖的扫描项**：`: any`、直接 `uni.request`、新代码 `res.data?.results`、ref 双重调用、v-for 无 key、硬编码中文、枚举产物手改、漏判 `res.state`、非法处理 401/403/498、直接 `authRefreshToken`、Loading 平衡、硬编码空/失败文案、自造 Loading、未包裹 `window/document/navigator`、未包裹 `plus.*`、SCSS 错用 `// #ifdef`。

### 2. 按维度评审

逐项检查并记录问题，严重级别按下表判定。

| 级别 | 判定条件 | 处理 |
|------|----------|------|
| Critical | 编译失败、pnpm check 失败、核心流程不可用、页面空壳、登录/Token链路错误、非 H5 端引用 DOM 崩溃、DataList 新代码仍用 results | 必须修复后重评 |
| Major | 页面功能缺失、pages.json/TabBar 配置错误、i18n 缺语言、枚举/字典流程错误、Loading/空状态/分享能力缺失 | >1 个不通过 |
| Minor | 文案、局部样式、个别可读性或体验问题 | 可计入扣分 |

### 3. 修复循环

| 结果 | 动作 |
|------|------|
| ≥ 95 且 Critical=0 且 Major≤1 | 输出评审报告，任务结束 |
| < 95 或 Critical>0 或 Major>1 | 立即调用 `220-guest-uni-dev`，传入问题清单，修复完成后重新评审 |

修复循环最多 5 轮。仅在通过或轮次耗尽时输出结果。

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [评审检查清单](references/checklist.md)
- [编码原则](../220-guest-uni-dev/references/coding-principles.md)
- [UniApp 开发规范](../220-guest-uni-dev/references/md-dev-standards.md)
- [移动端设计规范](../220-guest-uni-dev/references/md-design-spec.md)
- [设计模板](../220-guest-uni-dev/references/design-templates.md)
- [代码模板](../220-guest-uni-dev/references/code-templates.md)
- [开发示例](../220-guest-uni-dev/references/dev-examples.md)
- [评审报告模板](../0-init/references/review-report-template.md)
