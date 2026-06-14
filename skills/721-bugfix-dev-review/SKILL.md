---
name: 721-bugfix-dev-review
description: Bug修复开发评审技能。当720-bugfix-dev修复完成后触发：(1)评审修复方案和代码规范, (2)检查回归测试与安全性, (3)输出评审结论。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# Bug修复开发评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 方案评审 + 代码审计 | `system-architect` + `java-lead` + `js-lead` |
| 协作 | 根因确认 | `java-developer` |
| 协作 | 安全审计 | `system-architect` |

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，再基于约定进行评审，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [720-bugfix-dev/SKILL.md](../720-bugfix-dev/SKILL.md) | **必读全文**：修改范围决策表、Phase 1-6 全部要求 |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| Bug分析报告 | `PROJECT_ROOT/issue/bugs/BUGFIX-{YYMMDD}-{topic}.md` | 710阶段输出 |
| 修复方案 | `PROJECT_ROOT/issue/bugs/BUGFIX-DESIGN-{YYMMDD}-{topic}.md` | 720 Phase 2 输出 |
| DDL文件 | `PROJECT_ROOT/database/migrations/BUGFIX-*.sql` | 720 Phase 2 输出（如有） |
| 各端修复代码 | 各端 `src/` | 720 Phase 4 输出 |
| 各端回归测试 | 各端 `src/test/` 或 `src/**/*.spec.ts` | 720 Phase 4 输出 |

## 输出

| 输出项 | 位置 | 说明 |
|--------|------|------|
| 评审报告 | `PROJECT_ROOT/issue/reviews/REVIEW-BUGFIX-DEV-{YYMMDDHHMM}.md` | 评审结论和问题清单 |

报告格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

> 详细检查清单见 [checklist.md](references/checklist.md)。

| 维度 | 检查要点 | 源技能章节 |
|------|---------|-----------|
| 修复方案 | 针对根因、彻底性、回滚方案、兼容性 | 720 Phase 2 |
| 修复正确性 | Bug根因已修复，修复逻辑正确，边界场景覆盖 | 720 Phase 4 |
| 代码规范 | 后端uw-base规范（禁Lombok）、前端Vue3/UniApp规范 | 720 Phase 4 |
| 回归测试 | Bug复现测试 + 关联功能回归测试 | 720 Phase 4 |
| 副作用 | 未引入新问题，变更范围最小化 | 720 修改范围决策表 |
| 安全性 | 修复未引入安全漏洞，SQL参数化，租户隔离 | 720 安全性 |

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 分 | 无 Critical，Major ≤ 2，Bug根因已修复，有回归测试 |
| 不通过 | < 95 分 | 存在 Critical 或 Major > 2 或根因未修复或无回归测试 |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始评审前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 编译验证（前置步骤）

| 端 | 验证命令 |
|----|---------|
| 后端 | `mvn compile` + `mvn test -Dspring.profiles.active=debug` |
| Admin Web | `pnpm build` + `pnpm vue-tsc --noEmit` |
| Guest Web | `pnpm build` + `pnpm nuxi typecheck` |
| UniApp | `pnpm build:h5` + `pnpm build:mp-weixin` |

编译未通过不得进入评审。

### 2. 执行评审

按维度检查。详见 [评审报告模板](../0-init/references/review-report-template.md)。详细的评审检查清单见 [checklist.md](references/checklist.md)。

### 3. 评审结论

**评分 ≥ 95（通过）：**
1. 标记评审状态为「通过」
2. 输出评审报告，任务结束

**评分 < 95（不通过）→ 自动修复循环：**
1. 立即调用 `720-bugfix-dev`，传入问题清单
2. 修复完成后立即重新执行本技能评审
3. 若仍 < 95，回到步骤 1（最多 5 轮）
4. 仅在通过或轮次耗尽时输出结果

> 此流程全自动执行：中间不暂停、不询问、不汇报。
> 未收到通过确认前，禁止结束本技能任务。

## 流转关系

```
输入: 720-bugfix-dev 全部输出（方案+代码+测试）
    ↓
721-bugfix-dev-review
    ↓
通过 → 等待 730-bugfix-test
不通过 → 自动调用 720 修复 → 重新评审
```

## 参考

- [Bug修复开发技能](../720-bugfix-dev/SKILL.md)
- [评审报告模板](../0-init/references/review-report-template.md)
