---
name: 201-database-deploy-review
description: 数据库部署评审技能。当DDL执行完成后触发：(1)验证表结构与设计文档一致, (2)检查索引是否正确创建, (3)验证初始数据正确性。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# 数据库DDL执行评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | DDL执行评审 | `system-architect` |
| 协作 | ORM映射确认 | `java-developer` |
| 协作 | 业务数据确认 | `product-manager` |

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，再基于约定进行评审，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [200-database-deploy/SKILL.md](../200-database-deploy/SKILL.md) | **必读全文**：DDL执行流程、验证标准 |
| [200-database-design/SKILL.md](../200-database-design/SKILL.md) | 设计阶段命名约定和设计完成标准 |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| 执行报告 | `PROJECT_ROOT/database/deploy/DDL-EXECUTION-REPORT-*.md` | 200阶段产出 |
| DDL文件 | `PROJECT_ROOT/database/database-ddl.sql` | 执行的DDL |
| 设计文档 | `PROJECT_ROOT/database/database-design.md` | 设计参照 |
| 实际数据库 | 目标数据库 | 通过SQL查询验证 |

## 输出

| 输出项 | 位置 | 说明 |
|--------|------|------|
| DDL执行评审报告 | `PROJECT_ROOT/database/deploy/reviews/REVIEW-DDL-EXECUTION-{YYMMDDHHMM}.md` | 评审结论 |

报告格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

| 维度 | 检查要点 |
|------|---------|
| 表完整性 | 设计文档中的所有表都已创建 |
| 字段一致性 | 字段名、类型、约束与DDL一致 |
| 索引正确性 | 主键、唯一索引、普通索引均已创建 |
| 通用字段 | id/saas_id/state/create_date/modify_date 齐全 |
| 初始数据 | 枚举表、配置表数据正确 |
| 无多余对象 | 无遗留的测试表或临时表 |

**验证方式**：对每张表执行 `SHOW CREATE TABLE` 和 `SHOW INDEX`，与 `database-ddl.sql` 逐项比对。

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 分 | 无 Critical 问题，表完整率 100%，字段一致率 ≥ 99%，索引完整率 ≥ 95%，通用字段齐全 |
| 不通过 | < 95 分 | 存在 Critical 或表/字段/索引不达标 |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始评审前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 执行评审
逐表验证，记录问题。评审发现记录格式和评审报告结构详见 [评审报告模板](../0-init/references/review-report-template.md)。

详细的评审检查清单见 [checklist.md](references/checklist.md)。

**维度**: 表完整性/字段一致性/索引正确性/通用字段/初始数据
**评审对象**: `PROJECT_ROOT/database/` + 实际数据库
**参与人员**: @system-architect @java-developer


### 2. 评审结论

计算最终评分后，按以下规则执行：

**评分 ≥ 95（通过）：**
1. 标记评审状态为「通过」
2. 输出评审报告，任务结束

**评分 < 95（不通过）→ 自动修复循环：**
1. 立即调用 `200-database-deploy`，传入问题清单
2. 修复完成后立即重新执行本技能评审
3. 若仍 < 95，回到步骤 1（最多 5 轮）
4. 仅在通过或轮次耗尽时输出结果

> 此流程全自动执行：中间不暂停、不询问、不汇报。
> 未收到通过确认前，禁止结束本技能任务。

## 参考

- [评审报告模板](../0-init/references/review-report-template.md) - 通用评审报告格式
- [评审检查清单](references/checklist.md) - DDL执行评审检查项
- [数据库部署技能](../200-database-deploy/SKILL.md) - 被评审的上游技能
- [数据库设计评审技能](../201-database-design-review/SKILL.md) - 设计评审参考
