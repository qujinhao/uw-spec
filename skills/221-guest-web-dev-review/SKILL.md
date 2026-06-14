---
name: 221-guest-web-dev-review
description: 游客端Web开发评审（AI原生，Nuxt 3）。当游客端Web开发完成后触发：(1)评审架构蓝图README.md, (2)检查渲染模式与SEO配置, (3)验证编译与类型检查通过, (4)检查TDD测试全绿, (5)验证类型安全与字段一致性, (6)确认安全性。当用户提及游客端评审、Nuxt评审、前台评审时使用。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# 游客端Web开发评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [220-guest-web-dev/SKILL.md](../220-guest-web-dev/SKILL.md) | **必读全文**：架构约定速查表、逐页面交付流程、完成标准 |
| [220-guest-web-dev/references/coding-principles.md](../220-guest-web-dev/references/coding-principles.md) | 编码原则（四条核心原则 + 自动化验证） |
| [220-guest-web-dev/references/web-dev-standards.md](../220-guest-web-dev/references/web-dev-standards.md) | Nuxt3 + Vue3 + TypeScript 开发规范 |
| [220-guest-web-dev/references/web-design-spec.md](../220-guest-web-dev/references/web-design-spec.md) | Tailwind + Shadcn Vue 设计规范 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 架构评审 + 代码质量审计 | `system-architect` |
| 协作 | 需求符合度 | `product-manager` |
| 协作 | 原型评审 | `prototype-reviewer` |
| 协作 | 实现难度 | `js-developer` |

## 输入

| 输入项 | 位置 | 说明 |
|--------|------|------|
| **目标页面** | 调用方传入 | 指定评审的页面。不传则评审全部 |
| README.md | 前端项目根目录 | 架构蓝图 |
| TASKS.md | 前端项目根目录 | 进度清单 |
| 页面组件 | `src/pages/**/*.vue` | Nuxt 文件路由页面 |
| 业务组件 | `src/components/**/*.vue` | 复用组件 |
| Composables | `src/composables/**/*.ts` | 组合函数 |
| 测试文件 | `src/**/*.spec.ts` | Vitest 单元测试 |
| nuxt.config.ts | 前端项目根目录 | 渲染模式配置 |
| PRD 文档 | `PROJECT_ROOT/requirement/prds/*` | 功能需求参考 |

## 输出

| 类型 | 报告位置 |
|------|---------|
| 评审报告 | `issue/reviews/REVIEW-DEV-YYMMDDHHMM.md` |

格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

> 详细检查清单见 [checklist.md](references/checklist.md)。

| 维度 | 检查要点 | 分值 |
|------|---------|------|
| 架构蓝图完整性 | README.md 页面总览/路由设计/渲染模式/PRD映射/字段一致性 | 10分 |
| 需求符合度 | PRD 功能点全覆盖、核心业务流可走通 | 10分 |
| 渲染模式与SEO | routeRules 配置正确、useSeoMeta 完整、JSON-LD 结构化数据、OG 标签 | 15分 |
| 技术架构 | Nuxt 文件路由、状态分离、国际化、图片优化、API 客户端 | 15分 |
| 类型安全与字段一致性 | 无 `any`、字段名与 API Schema 一致、DataList 规范、zod 校验 | 15分 |
| TDD 实践 | Vitest 测试全绿、composables/Store/工具函数覆盖、无跳过用例 | 10分 |
| 用户体验与视觉设计 | 布局合理、交互反馈、响应式适配、三态展示、风格统一 | 10分 |
| 安全性 | XSS 防护、CSRF 防护、敏感数据、依赖安全 | 5分 |
| 性能优化 | 图片优化、组件懒加载、包体积控制 | 5分 |
| 编码规范 | SFC 结构顺序、命名规范、导入规范、代码风格 | 5分 |

## 通过标准

| 等级 | 分值 | Critical | Major |
|------|------|----------|-------|
| 通过 | ≥ 95 | 0 | ≤1 |
| 不通过 | < 95 | 存在 或 Major >1 | — |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 编译与类型验证

```bash
pnpm build && pnpm nuxi typecheck
```

**两项必须全部通过**。AI 原生开发的核心要求——每个页面一次写完，编译和类型检查直接通过。

同时执行自动化验证（详见 [checklist.md](references/checklist.md) 第 1 节），未全部通过不得进入维度评审。

### 2. 按维度评审

逐项检查，记录问题。详细清单见 [checklist.md](references/checklist.md)。

### 3. 评审结论

**≥ 95（通过）**：输出评审报告，任务结束。

**< 95（不通过）→ 自动修复循环**：
1. 立即调用 `220-guest-web-dev`，传入问题清单
2. 修复完成后重新评审（最多 5 轮）
3. 仅在通过或轮次耗尽时输出结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [评审检查清单](references/checklist.md)
- [评审报告模板](../0-init/references/review-report-template.md)
- [编码原则](../220-guest-web-dev/references/coding-principles.md)
- [Web 开发规范](../220-guest-web-dev/references/web-dev-standards.md)
- [Web 设计规范](../220-guest-web-dev/references/web-design-spec.md)
