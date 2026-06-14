---
name: 221-guest-uni-dev-review
description: 消费者端UniApp开发评审（AI原生）。当消费者端UniApp开发完成后触发：(1)评审架构蓝图README.md, (2)验证H5+微信小程序编译通过, (3)检查页面质量与pages.json配置, (4)检查平台适配与分享能力, (5)验证消费者端体验与安全性。当用户提及消费者端评审、UniApp评审、小程序评审时使用。适用于guest角色。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# 消费者端 UniApp 开发评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [220-guest-uni-dev/SKILL.md](../220-guest-uni-dev/SKILL.md) | **必读全文**：架构约定、逐页面交付流程、完成标准 |
| [220-guest-uni-dev/references/coding-principles.md](../220-guest-uni-dev/references/coding-principles.md) | **必读"自动化验证"**：7 条编译命令 + 四条核心原则 |
| [220-guest-uni-dev/references/md-dev-standards.md](../220-guest-uni-dev/references/md-dev-standards.md) | UniApp 移动端开发规范 |
| [220-guest-uni-dev/references/md-design-spec.md](../220-guest-uni-dev/references/md-design-spec.md) | 移动端设计规范 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 架构评审 + 页面质量审计 | `js-lead` |
| 协作 | 需求符合度 | `product-manager` |
| 协作 | 消费者端体验 | `prototype-reviewer` |
| 协作 | 移动端实现 | `js-developer` |

## 输入

| 输入项 | 位置 | 说明 |
|--------|------|------|
| **目标页面** | 调用方传入 | 指定评审的页面。不传则评审全部 |
| 前端项目 | `PROJECT_ROOT/frontend/{project-name}-guest-uni/` | 220 开发阶段产出的可运行项目 |
| README.md | 前端项目根目录 | 架构蓝图 |
| TASKS.md | 前端项目根目录 | 进度清单 |
| 页面代码 | `src/pages/{module}/` | 逐页面完整交付的页面组件 |
| pages.json | 前端项目根目录 | 路由与 TabBar 配置 |
| 需求文档 | `PROJECT_ROOT/requirement/prds/*` | 功能需求参考 |

## 输出

| 类型 | 报告位置 |
|------|---------|
| 评审报告 | `issue/reviews/REVIEW-DEV-YYMMDDHHMM.md` |

格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

> 详细检查清单见 [checklist.md](references/checklist.md)。

| 维度 | 检查要点 | 分值 |
|------|---------|------|
| 架构蓝图完整性 | README.md 页面总览、TabBar配置、PRD功能点映射、字段对照表、平台适配策略 | 15分 |
| 页面质量 | 模板完整（UI结构+条件编译）、逻辑完整（交互+API+状态）、样式完整（rpx+安全区域） | 15分 |
| 路由配置 | pages.json 页面路径完整、TabBar 4 Tab 配置、导航栏标题 | 10分 |
| 平台适配 | 条件编译 #ifdef 使用规范、安全区域适配、rpx 单位 | 10分 |
| 字段一致性 | 表单字段名与 DTO 一致（camelCase）、DataList 使用 results | 10分 |
| PRD 覆盖度 | 所有功能点有对应页面、核心流程可走通 | 5分 |
| 消费者端体验 | 支付/扫码集成、触摸交互≥44px、加载/空状态、手势操作 | 10分 |
| 分享能力 | onShareAppMessage + onShareTimeline、uni.share（App端） | 5分 |
| 编码原则 | 集中管理、类型安全（无 any）、项目一致性、可读性 | 10分 |
| 安全性 | XSS防护、Token存储、输入校验、登录态校验 | 5分 |
| 性能优化 | 图片压缩、分页加载、资源释放 | 5分 |

## 通过标准

| 等级 | 分值 | Critical | Major |
|------|------|----------|-------|
| 通过 | ≥ 95 | 0 | ≤1 |
| 不通过 | < 95 | 存在 或 Major >1 | — |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 自动化验证（前置步骤）

执行 [coding-principles.md](../220-guest-uni-dev/references/coding-principles.md) 中的自动化验证命令，未全部通过不得进入人工评审。

```bash
cd frontend/{project-name}-guest-uni

grep -rn ': any' src/ --include="*.vue" --include="*.ts" | grep -v '@change' | wc -l
grep -rn 'uni\.request(' src/pages/ --include="*.vue" | wc -l
grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" | wc -l
grep -rn 'ref<.*>(.*)(.*)' src/ --include="*.vue" --include="*.ts" | wc -l
grep -rn 'v-for=' src/pages/ --include="*.vue" | grep -v ':key=' | wc -l
pnpm build:h5
pnpm build:mp-weixin
```

### 2. 按维度评审

逐项检查，记录问题。详细清单见 [checklist.md](references/checklist.md)。

### 3. 评审结论

**≥ 95（通过）**：输出评审报告，任务结束。

**< 95（不通过）→ 自动修复循环**：
1. 立即调用 `220-guest-uni-dev`，传入问题清单
2. 修复完成后重新评审（最多 5 轮）
3. 仅在通过或轮次耗尽时输出结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [评审检查清单](references/checklist.md)
- [评审报告模板](../0-init/references/review-report-template.md)
- [编码原则](../220-guest-uni-dev/references/coding-principles.md)
- [UniApp 开发规范](../220-guest-uni-dev/references/md-dev-standards.md)
- [移动端设计规范](../220-guest-uni-dev/references/md-design-spec.md)
