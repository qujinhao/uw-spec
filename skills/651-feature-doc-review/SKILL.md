---
name: 651-feature-doc-review
description: 功能文档更新评审技能。当功能文档更新完成后触发：(1)检查运维文档更新完整性, (2)检查用户手册和需求文档更新, (3)验证文档合并和CHANGELOG。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# 功能文档更新评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 文档评审 | `system-architect` |
| 协作 | 运维文档评审 | `devops-engineer` |
| 协作 | 用户手册评审 | `test-engineer` |

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，再基于约定进行评审，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [650-feature-doc/SKILL.md](../650-feature-doc/SKILL.md) | **必读全文**：执行流程、输出要求、完成标准 |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| 验收报告 | `PROJECT_ROOT/issue/reviews/REVIEW-FEATURE-{YYMMDDHHMM}.md` | 630阶段输出 |
| 运维文档更新 | `manual/ops-manual/` | 650阶段输出 |
| 用户手册更新 | `manual/user-manual/` | 650阶段输出 |
| 变更记录 | `manual/xxx/CHANGELOG.md` | 650阶段输出 |
| 更新后主文档 | `manual/xxx/README.md` | 650阶段输出 |

## 输出

| 输出项 | 位置 | 说明 |
|--------|------|------|
| 评审报告 | `PROJECT_ROOT/issue/reviews/REVIEW-DOC-{YYMMDDHHMM}.md` | 评审结论和问题清单 |

报告格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

| 维度 | 分值 | 检查要点 | 源技能章节 |
|------|------|---------|-----------|
| 运维文档完整性 | 30分 | 部署手册更新（配置项、步骤）、监控手册更新（指标、告警）、故障处理更新、配置管理更新 | 650 执行流程1 |
| 用户手册准确性 | 25分 | 操作说明完整、快速入门更新、FAQ新增、故障排查更新 | 650 执行流程2 |
| 需求文档同步 | 25分 | 功能清单更新、变更记录完整、验收标准AC状态更新 | 650 执行流程3 |
| CHANGELOG与合并 | 20分 | CHANGELOG格式正确、内容完整、主文档合并无遗漏 | 650 执行流程4 |

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 分 | 无 Critical，Major ≤ 2，所有维度无零分项 |
| 不通过 | < 95 分 | 存在 Critical 或 Major > 2 或任一维度零分 |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始评审前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 文件存在性检查（前置步骤）

| 检查项 | 标准 |
|--------|------|
| 运维文档 | `manual/ops-manual/` 下文件存在且非空 |
| 用户手册 | `manual/user-manual/` 下文件存在且非空 |
| CHANGELOG | `manual/xxx/CHANGELOG.md` 存在且包含本次更新记录 |
| 主文档 | `manual/xxx/README.md` 存在且已合并 |

文件缺失或为空不得进入评审。

### 2. 执行评审

按维度逐项检查。详见 [评审报告模板](../0-init/references/review-report-template.md)。

### 3. 评审结论

**评分 ≥ 95（通过）：**
1. 标记评审状态为「通过」
2. 输出评审报告，任务结束

**评分 < 95（不通过）→ 自动修复循环：**
1. 立即调用 [650-feature-doc](../650-feature-doc/SKILL.md)，传入问题清单
2. 修复完成后立即重新执行本技能评审
3. 若仍 < 95，回到步骤 1（最多 5 轮）
4. 仅在通过或轮次耗尽时输出结果

> 此流程全自动执行：中间不暂停、不询问、不汇报。
> 未收到通过确认前，禁止结束本技能任务。

## 流转关系

```
输入: 650-feature-doc 全部输出（运维+手册+需求+CHANGELOG）
    ↓
651-feature-doc-review
    ↓
通过 → 流程结束
不通过 → 自动调用 650-feature-doc 修复 → 重新评审
```

## 参考

- [功能文档更新技能](../650-feature-doc/SKILL.md)
- [评审报告模板](../0-init/references/review-report-template.md)
