---
name: 221-admin-web-dev-review
description: 管理端Web开发评审（AI原生，Vue3+TS+ElementPlus）。当管理端Web开发完成后触发：(1)评审架构蓝图README.md, (2)检查页面质量与API对接完整性, (3)验证测试全部通过（非Red→Green两阶段，一次通过）, (4)检查字段一致性与编码规范, (5)验证安全性与性能优化。当用户提及前端代码评审、管理后台评审时使用。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# 管理端Web开发评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [220-admin-web-dev/SKILL.md](../220-admin-web-dev/SKILL.md) | **必读全文**：架构约定、Phase 0-2 逐页面交付流程、完成标准 |
| [220-admin-web-dev/references/coding-principles.md](../220-admin-web-dev/references/coding-principles.md) | 编码原则（四条核心原则 + 自动化验证命令） |
| [220-admin-web-dev/references/web-dev-standards.md](../220-admin-web-dev/references/web-dev-standards.md) | Vue3+TS+Vite+ElementPlus 开发规范 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 代码质量审计 + 架构评审 | `js-lead` |
| 协作 | 需求符合度 | `product-manager` |
| 协作 | 原型评审 | `prototype-reviewer` |
| 协作 | 技术可行性 | `system-architect` |

## 输入

| 输入项 | 位置 | 说明 |
|--------|------|------|
| 前端项目 | `PROJECT_ROOT/frontend/{project-name}-admin-web/` | 220 逐页面交付产出的可运行项目 |
| README.md | 前端项目根目录 | 架构蓝图 |
| TASKS.md | 前端项目根目录 | 进度清单 |
| PRD 文档 | `PROJECT_ROOT/requirement/prds/*` | 功能需求参考 |
| 测试文件 | `src/**/*.test.ts` | 单元测试文件 |

## 输出

| 输出项 | 位置 |
|--------|------|
| 评审报告 | `issue/reviews/REVIEW-DEV-YYMMDDHHMM.md` |

格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

> 详细检查清单见 [checklist.md](references/checklist.md)。

| 维度 | 检查要点 | 分值 |
|------|---------|------|
| README.md 完整性 | 页面总览、角色权限映射、路由设计、PRD功能点映射 | 10分 |
| TASKS.md 完整性 | 拓扑分组、状态复选框、全部标记完成 | 5分 |
| 需求符合度 | PRD功能覆盖、核心流程可走通、角色覆盖 | 10分 |
| 页面质量 | SFC结构、导入顺序、编码规范、ElementPlus使用、角色目录组织 | 20分 |
| API对接质量 | 响应类型声明、错误处理、CRUD hooks、列表数据取值 | 15分 |
| 字段一致性 | 表单字段名、表格列prop、搜索条件field、状态字段number值 | 10分 |
| 状态管理质量 | Pinia setup风格、跨页面共享vs页面私有、Store命名 | 5分 |
| 编码原则 | 集中管理、类型安全、一致性、自动化验证全过 | 10分 |
| 测试质量 | composables/hooks/Store测试全绿、无TODO残留 | 5分 |
| 安全性 | XSS防护、Token管理、权限校验、API调用安全 | 5分 |
| 性能优化 | 路由懒加载、keep-alive、组件按需加载 | 5分 |

## 通过标准

| 等级 | 分值 | Critical | Major |
|------|------|----------|-------|
| 通过 | ≥ 95 | 0 | ≤1 |
| 不通过 | < 95 | 存在 或 Major >1 | — |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 自动化验证（前置步骤）

执行 [coding-principles.md](../220-admin-web-dev/references/coding-principles.md) 中的自动化验证命令 + 编译验证：

```bash
cd frontend/{project-name}-admin-web
pnpm build && pnpm vue-tsc --noEmit
```

未全部通过不得进入维度评审。

### 2. 按维度评审

逐项检查，记录问题。详细清单见 [checklist.md](references/checklist.md)。

### 3. 评审结论

**≥ 95（通过）**：输出评审报告，任务结束。

**< 95（不通过）→ 自动修复循环**：
1. 立即调用 `220-admin-web-dev`，传入问题清单
2. 修复完成后重新评审（最多 5 轮）
3. 仅在通过或轮次耗尽时输出结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [评审检查清单](references/checklist.md)
- [编码原则](../220-admin-web-dev/references/coding-principles.md)
- [Web 开发规范](../220-admin-web-dev/references/web-dev-standards.md)
- [评审报告模板](../0-init/references/review-report-template.md)
