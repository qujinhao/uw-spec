---
name: 111-requirement-review
description: 需求评审技能。当需求规划文档完成后触发：(1)检查需求完整性和覆盖度, (2)验证需求一致性和可测试性, (3)输出评审结论和改进建议。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# 需求评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责
| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 需求评审 | `project-manager` |
| 协作 | 需求解释 | `product-manager` |
| 协作 | 技术可行性 | `system-architect` |
| 协作 | 可测试性 | `test-engineer` |

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，再基于约定进行评审，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [110-requirement-planning/SKILL.md](../110-requirement-planning/SKILL.md) | **必读全文**：需求规划规范、交付物规范、章节结构要求、交互流程设计规范 |
| [110-requirement-planning/references/templates.md](../110-requirement-planning/references/templates.md) | **必读全文**：README模板、前端P文档模板、领域M文档模板，作为评审对照基准 |

## 输入
| 输入项 | 来源 | 说明 |
|--------|------|------|
| 需求文档 | `PROJECT_ROOT/requirement/prds/` | PRD、用户故事、验收标准 |

## 输出
| 输出项 | 位置 | 说明 |
|--------|------|------|
| 需求评审报告 | `PROJECT_ROOT/requirement/reviews/REVIEW-PRD-YYMMDDHHMM.md` | 时间戳24小时制 |

报告格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度
| 维度 | 检查要点 |
|------|---------|
| README结构 | 章节完整性、业务领域顺序、端章节三子节、无子目录README |
| 交互流程 | 核心领域覆盖、跨端联动覆盖、单端状态流转、链路完整性、participant命名 |
| 领域模块 | 文档结构、对象关系、跨端交互一致性、不含技术设计 |
| 前端页面 | 文档结构、数据需求引用领域M、线框图完整性 |
| 映射覆盖 | 领域映射覆盖度、领域模块清单覆盖、前端页面覆盖、验收标准各端独立 |
| 可行性 | 技术可行、资源可行、业务可行、法律合规 |
| 一致性 | 术语一致（无旧术语残留）、逻辑一致、标准一致 |
| 可测试性 | 可验证、可度量、独立性 |

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 分 | 无 Critical 问题，Major ≤ 2 且有解决方案，需求完整度 ≥ 95%，验收标准 100% 可测试，风险可控 |
| 不通过 | < 95 分 | 存在 Critical 或 Major > 2 或需求完整度 < 95% |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始评审前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 执行评审
按维度检查，记录问题。评审发现记录格式和评审报告结构详见 [评审报告模板](../0-init/references/review-report-template.md)。

详细的评审检查清单见 [checklist.md](references/checklist.md)。

**维度**: 完整性/可行性/一致性/可测试性
**评审对象**: PROJECT_ROOT/requirement/
**参与人员**: @project-manager @product-manager @system-architect @test-engineer


### 2. 评审结论

计算最终评分后，按以下规则执行：

**评分 ≥ 95（通过）：**
1. 标记评审状态为「通过」
2. 输出评审报告，任务结束

**评分 < 95（不通过）→ 自动修复循环：**
1. 立即调用 `110-requirement-planning`，传入问题清单
2. 修复完成后立即重新执行本技能评审
3. 若仍 < 95，回到步骤 1（最多 5 轮）
4. 仅在通过或轮次耗尽时输出结果

> 此流程全自动执行：中间不暂停、不询问、不汇报。
> 未收到通过确认前，禁止结束本技能任务。

