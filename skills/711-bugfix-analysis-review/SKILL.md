---
name: 711-bugfix-analysis-review
description: Bug分析评审技能。当Bug分析完成后触发：(1)检查根因分析正确性和影响评估完整性, (2)验证修复建议可行性与复现步骤准确性, (3)确认CHANGELOG同步并输出评审结论。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "2.0.0"
---

# Bug分析评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责
| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 分析评审 | `system-architect` |
| 协作 | 根因确认 | `java-developer` / `js-developer` |
| 协作 | 复现验证 | `test-engineer` |

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，再基于约定进行评审，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [710-bugfix-analysis/SKILL.md](../710-bugfix-analysis/SKILL.md) | **必读全文**：Bug分析流程、交付物规范、报告结构 |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| Bug分析报告 | `PROJECT_ROOT/issue/bugs/BUGFIX-{YYMMDD}-{topic}.md` | 710阶段产出的分析报告 |
| 原始Bug描述 | 用户输入 | Bug现象描述 |

## 输出
| 输出项 | 位置 | 说明 |
|--------|------|------|
| Bug分析评审报告 | `PROJECT_ROOT/issue/reviews/REVIEW-BUGFIX-{YYMMDDHHMM}.md` | 评审结论和问题清单 |

报告格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度
| 维度 | 检查要点 |
|------|---------|
| 根因分析 | 根因定位准确、分析过程完整、无潜在类似问题 |
| 影响评估 | 影响范围完整、影响程度准确、数据影响评估、修复风险评估 |
| 复现步骤 | 步骤清晰可执行、环境信息完整、发生频率标注 |
| 修复建议 | 建议针对根因、方案可行、风险评估合理 |
| 文档质量 | 关联代码定位准确、报告结构完整、CHANGELOG已追加 |

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 分 | 无 Critical 问题，Major ≤ 2，根因分析正确，复现步骤可执行 |
| 不通过 | < 95 分 | 存在 Critical 或 Major > 2 或根因分析错误 |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始评审前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 执行评审
按维度检查，记录问题。评审发现记录格式和评审报告结构详见 [评审报告模板](../0-init/references/review-report-template.md)。

详细的评审检查清单见 [checklist.md](references/checklist.md)。

**维度**: 根因分析/影响评估/复现步骤/修复建议/文档质量
**评审对象**: `PROJECT_ROOT/issue/bugs/`
**参与人员**: @system-architect @developer @test-engineer

### 2. 评审结论

计算最终评分后，按以下规则执行：

**评分 ≥ 95（通过）：**
1. 标记评审状态为「通过」
2. 输出评审报告，任务结束

**评分 < 95（不通过）→ 自动修复循环：**
1. 立即调用 `710-bugfix-analysis`，传入问题清单
2. 修复完成后立即重新执行本技能评审
3. 若仍 < 95，回到步骤 1（最多 5 轮）
4. 仅在通过或轮次耗尽时输出结果

> 此流程全自动执行：中间不暂停、不询问、不汇报。
> 未收到通过确认前，禁止结束本技能任务。
