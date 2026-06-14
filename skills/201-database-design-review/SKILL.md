---
name: 201-database-design-review
description: 数据库设计评审技能。当数据库设计文档完成后触发：(1)检查表结构合理性和规范性, (2)评审索引设计和查询优化, (3)验证数据一致性和完整性保障。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# 数据库设计评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责
| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 数据库评审 | `system-architect` |
| 协作 | ORM映射确认 | `java-developer` |
| 协作 | 测试数据需求 | `test-engineer` |
| 协作 | 业务数据确认 | `product-manager` |

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，再基于约定进行评审，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [200-database-design/SKILL.md](../200-database-design/SKILL.md) | **必读全文**：设计规范、命名约定、设计流程、设计完成标准 |
| [200-database-design/references/database-design-guide.md](../200-database-design/references/database-design-guide.md) | 数据库设计指南 |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| 数据库设计文档 | `PROJECT_ROOT/database/database-design.md` | 表结构、索引、关联关系 |
| 需求文档 | `PROJECT_ROOT/requirement/prds/*` | 数据需求参考 |

## 输出
| 输出项 | 位置 | 说明 |
|--------|------|------|
| 数据库设计评审报告 | `PROJECT_ROOT/database/reviews/REVIEW-DB-YYMMDDHHMM.md` | 按时间戳命名，24小时制 |

报告格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度
| 维度 | 检查要点 |
|------|---------|
| 命名规范 | 表名符合命名规范（模块主表用`{module}_info`、独立实体表用`{module}_{entity}`、主从表用`{module}_{master}_{slave}`、关联表用`{module}_{e1}_{e2}_ref`）、字段snake_case、索引前缀idx_/uk_ |
| 表结构 | 字段类型选择、约束完整、通用字段齐全、设计文档每个实体有完整的实体说明+数据规模+DDL引用 |
| 索引设计 | 主键、唯一索引、普通索引合理性（检查DDL） |
| 关联关系 | 外键命名`{关联表简称}_{关联实体简称}_id`、关联表、级联策略 |
| 性能优化 | 分区策略、归档方案、查询优化 |
| 设计精简性 | 表数量合理、禁止单字段表、枚举不建表、JOIN层级控制 |
| 安全性 | 敏感数据加密、权限控制 |

详细的各维度检查项见 [checklist.md](references/checklist.md)。命名规范对照 [数据库设计指南](../200-database-design/references/database-design-guide.md)。

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 分 | 无 Critical 问题，Major ≤ 2，表名 100% 符合命名规范，索引合理，主外键约束完整 |
| 不通过 | < 95 分 | 存在 Critical 或 Major > 2 |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始评审前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 执行评审
按维度检查，记录问题。评审发现记录格式和评审报告结构详见 [评审报告模板](../0-init/references/review-report-template.md)。

详细的评审检查清单见 [checklist.md](references/checklist.md)。

**维度**: 表结构/索引/关联关系/性能/设计精简性/安全
**评审对象**: PROJECT_ROOT/database/
**参与人员**: @system-architect @java-developer @test-engineer


### 2. 评审结论

计算最终评分后，按以下规则执行：

**评分 ≥ 95（通过）：**
1. 标记评审状态为「通过」
2. 输出评审报告，任务结束

**评分 < 95（不通过）→ 自动修复循环：**
1. 立即调用 `200-database-design`，传入问题清单
2. 修复完成后立即重新执行本技能评审
3. 若仍 < 95，回到步骤 1（最多 5 轮）
4. 仅在通过或轮次耗尽时输出结果

> 此流程全自动执行：中间不暂停、不询问、不汇报。
> 未收到通过确认前，禁止结束本技能任务。

