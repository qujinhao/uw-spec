---
name: 221-admin-uni-dev-review
description: 管理端UniApp开发评审（AI原生，UniApp+Vue3）。当管理端移动端开发完成后触发：(1)评审架构蓝图README.md, (2)检查页面代码质量与多端适配, (3)验证多端编译通过, (4)检查条件编译与权限控制, (5)确认测试覆盖。当用户提及管理端App评审、UniApp评审时使用。适用于root/ops/saas/mch角色。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# 管理端UniApp开发评审（AI 原生）

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [220-admin-uni-dev/SKILL.md](../220-admin-uni-dev/SKILL.md) | **必读全文**：架构约定、逐页面交付流程、完成标准 |
| [220-admin-uni-dev/references/md-dev-standards.md](../220-admin-uni-dev/references/md-dev-standards.md) | UniApp 移动端开发规范 |
| [220-admin-uni-dev/references/coding-principles.md](../220-admin-uni-dev/references/coding-principles.md) | 编码原则（四条核心原则 + 自动化验证） |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 架构评审 + 代码评审 | `system-architect` / `js-lead` |
| 协作 | 原型评审 | `prototype-reviewer` |
| 协作 | 代码修改 | `js-developer` |
| 协作 | 业务确认 | `product-manager` |

## 输入

| 输入项 | 位置 | 说明 |
|--------|------|------|
| **目标模块** | 调用方传入 | 指定评审的页面或模块。不传则评审全部 |
| README.md | `PROJECT_ROOT/frontend/{project-name}-admin-uni/` | 架构蓝图 |
| TASKS.md | `PROJECT_ROOT/frontend/{project-name}-admin-uni/` | 进度清单 |
| 页面代码 | `PROJECT_ROOT/frontend/{project-name}-admin-uni/src/pages/` | 完整实现 |
| API 代码 | `PROJECT_ROOT/frontend/{project-name}-admin-uni/src/api/` | API 函数和类型 |
| 测试代码 | `PROJECT_ROOT/frontend/{project-name}-admin-uni/tests/**/*.spec.ts` | 单元测试 |
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
| 架构蓝图完整性 | README.md 页面总览、角色权限映射、PRD功能点映射、路由设计、字段一致性、平台适配策略 | 15分 |
| 页面代码质量 | 页面完整实现（非空壳TODO）、API 对接正确、字段一致、DataList 规范、角色路径正确 | 15分 |
| 跨平台兼容 | 条件编译 #ifdef 规范、rpx 样式适配、API 兼容、功能降级 | 15分 |
| 交互规范 | 下拉刷新/上拉加载/空状态/错误处理/安全区/加载反馈 | 10分 |
| 权限控制 | 页面级权限守卫、按钮权限 v-if、菜单权限动态加载、root/ops/saas/mch 角色覆盖 | 10分 |
| UniApp 技术栈合规 | script setup、类型安全无 any、集中管理导入、Pinia setup 风格、pages.json 配置正确 | 10分 |
| 测试质量 | composables/Store/工具函数测试全绿、覆盖率≥70%、无 TODO 残留 | 10分 |
| PRD 覆盖度 | 所有功能点有对应页面、角色覆盖 | 5分 |
| 安全性 | Token 安全存储、输入校验、敏感数据保护 | 5分 |
| 性能优化 | 分包加载≤2MB、图片压缩、分页加载、资源释放 | 5分 |

## 通过标准

| 等级 | 分值 | Critical | Major |
|------|------|----------|-------|
| 通过 | ≥ 95 | 0 | ≤1 |
| 不通过 | < 95 | 存在 或 Major >1 | — |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 编译与多端验证

```bash
pnpm build:h5 && pnpm build:mp-weixin && pnpm test
```

**pnpm test 必须全绿**。这是 AI 原生开发的核心要求——代码和测试一次写完，不存在"Red 骨架"阶段。

**自动化验证**（全量检查项，所有结果必须为 0）：

| 检查项 | 命令 |
|--------|------|
| any 类型 | `grep -rn ': any' src/ --include="*.vue" --include="*.ts" \| grep -v '@change' \| wc -l` |
| DataList 字段 | `grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" \| wc -l` |
| ref 双重调用 | `grep -rn 'ref<.*>(.*)(.*)' src/ --include="*.vue" --include="*.ts" \| wc -l` |
| v-for 无 key | `grep -rn 'v-for=' src/pages/ --include="*.vue" \| grep -v ':key=' \| wc -l` |
| 直接 uni.request | `grep -rn 'uni\.request(' src/pages/ --include="*.vue" \| wc -l` |

### 2. 按维度评审

逐项检查，记录问题。详细清单见 [checklist.md](references/checklist.md)。

### 3. 评审结论

**≥ 95（通过）**：输出评审报告，任务结束。

**< 95（不通过）→ 自动修复循环**：
1. 立即调用 `220-admin-uni-dev`，传入问题清单
2. 修复完成后重新评审（最多 5 轮）
3. 仅在通过或轮次耗尽时输出结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [评审检查清单](references/checklist.md)
- [评审报告模板](../0-init/references/review-report-template.md)
- [编码原则](../220-admin-uni-dev/references/coding-principles.md)
- [开发规范](../220-admin-uni-dev/references/md-dev-standards.md)
- [设计规范](../220-admin-uni-dev/references/md-design-spec.md)
