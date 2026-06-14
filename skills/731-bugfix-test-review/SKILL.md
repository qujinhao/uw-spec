---
name: 731-bugfix-test-review
description: Bug修复测试验收评审技能。当730-bugfix-test测试完成后触发：(1)评审回归测试覆盖和验收报告, (2)确认文档更新, (3)输出评审结论。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# Bug修复测试验收评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 测试评审 + 验收确认 | `test-lead` |
| 协作 | 修复确认 | `product-manager` |
| 协作 | 风险评估 | `project-manager` |

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，再基于约定进行评审，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [730-bugfix-test/SKILL.md](../730-bugfix-test/SKILL.md) | **必读全文**：Phase 1-4 全部要求 |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| 回归测试脚本 | `PROJECT_ROOT/test/scripts/` | 730 Phase 1 输出 |
| 测试报告 | `PROJECT_ROOT/test/reports/` | 730 Phase 3 输出 |
| 修复验收报告 | `PROJECT_ROOT/issue/reviews/REVIEW-BUGFIX-*.md` | 730 Phase 4 输出 |

## 输出

| 输出项 | 位置 | 说明 |
|--------|------|------|
| 评审报告 | `PROJECT_ROOT/issue/reviews/REVIEW-BUGFIX-TEST-{YYMMDDHHMM}.md` | 评审结论和问题清单 |

报告格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

> 详细检查清单见 [checklist.md](references/checklist.md)。

| 维度 | 检查要点 | 源技能章节 |
|------|---------|-----------|
| 回归测试质量 | Bug场景覆盖、回归范围、防复发 | 730 Phase 1-2 |
| 测试执行 | Bug场景100%修复、核心流程100%通过 | 730 Phase 3 |
| 验收报告 | 完整性、风险评估、人工确认 | 730 Phase 4 |

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 分 | Bug场景100%修复，核心流程100%通过，文档完整 |
| 不通过 | < 95 分 | Bug未完全修复或核心流程失败或文档不完整 |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始评审前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 执行评审

按维度检查。详见 [评审报告模板](../0-init/references/review-report-template.md)。详细的评审检查清单见 [checklist.md](references/checklist.md)。

### 2. 评审结论

**评分 ≥ 95（通过）：**
1. 标记评审状态为「通过」
2. 输出评审报告，任务结束

**评分 < 95（不通过）→ 自动修复循环：**
1. 立即调用 `730-bugfix-test`，传入问题清单
2. 修复完成后立即重新执行本技能评审
3. 若仍 < 95，回到步骤 1（最多 5 轮）
4. 仅在通过或轮次耗尽时输出结果

> 此流程全自动执行：中间不暂停、不询问、不汇报。
> 未收到通过确认前，禁止结束本技能任务。

## 流转关系

```
输入: 730-bugfix-test 全部输出（测试+报告+文档）
    ↓
731-bugfix-test-review
    ↓
通过 → 流程结束
不通过 → 自动调用 730 修复 → 重新评审
```

## 参考

- [Bug修复测试技能](../730-bugfix-test/SKILL.md)
- [评审报告模板](../0-init/references/review-report-template.md)
