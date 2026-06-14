---
name: 611-feature-clarify-review
description: 功能需求澄清评审技能。当功能需求澄清完成后触发：(1)检查需求文档完整性与验收标准可测试性, (2)验证业务场景覆盖与边界条件, (3)确认PRD同步更新并输出评审结论。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "2.0.0"
---

# 功能需求澄清评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责
| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 需求评审 | `product-manager` |
| 协作 | 技术可行性评估 | `system-architect` |
| 协作 | 验收标准可测试性 | `test-engineer` |

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，再基于约定进行评审，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [610-feature-clarify/SKILL.md](../610-feature-clarify/SKILL.md) | **必读全文**：功能需求澄清流程、交付物规范、验收标准定义、文档合并规则 |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| 功能需求文档 | `PROJECT_ROOT/issue/features/FEATURE-{YYMMDD}-{topic}.md` | 610阶段产出的功能需求文档 |
| 更新后的PRD | `PROJECT_ROOT/requirement/prds/README.md` | 610合并后的主PRD |
| 变更记录 | `PROJECT_ROOT/requirement/prds/CHANGELOG.md` | 需求变更历史 |

## 输出
| 输出项 | 位置 | 说明 |
|--------|------|------|
| 需求澄清评审报告 | `PROJECT_ROOT/issue/reviews/REVIEW-FEATURE-{YYMMDDHHMM}.md` | 评审结论和问题清单 |

报告格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度
| 维度 | 检查要点 |
|------|---------|
| 需求完整性 | 功能范围明确、包含/不包含内容清晰、用户故事完整 |
| 验收标准 | 每个AC可测试、优先级合理、覆盖正常和异常场景 |
| 业务场景 | 核心流程覆盖、边界条件识别、异常处理说明 |
| 技术提示 | 涉及模块明确、数据库/接口变更标识清晰 |
| PRD同步 | 功能清单已更新、CHANGELOG已追加、主PRD内容一致 |
| 可行性 | 技术可行、资源可行、与现有功能无冲突 |

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 分 | 无 Critical 问题，Major ≤ 2，验收标准 100% 可测试，PRD 已同步 |
| 不通过 | < 95 分 | 存在 Critical 或 Major > 2 或验收标准不可测试或PRD未同步 |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始评审前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 执行评审
按维度检查，记录问题。评审发现记录格式和评审报告结构详见 [评审报告模板](../0-init/references/review-report-template.md)。

详细的评审检查清单见 [checklist.md](references/checklist.md)。

**维度**: 需求完整性/验收标准/业务场景/技术提示/PRD同步/可行性
**评审对象**: `PROJECT_ROOT/issue/features/` + `PROJECT_ROOT/requirement/prds/`
**参与人员**: @product-manager @system-architect @test-engineer

### 2. 评审结论

计算最终评分后，按以下规则执行：

**评分 ≥ 95（通过）：**
1. 标记评审状态为「通过」
2. 输出评审报告，任务结束

**评分 < 95（不通过）→ 自动修复循环：**
1. 立即调用 `610-feature-clarify`，传入问题清单
2. 修复完成后立即重新执行本技能评审
3. 若仍 < 95，回到步骤 1（最多 5 轮）
4. 仅在通过或轮次耗尽时输出结果

> 此流程全自动执行：中间不暂停、不询问、不汇报。
> 未收到通过确认前，禁止结束本技能任务。
