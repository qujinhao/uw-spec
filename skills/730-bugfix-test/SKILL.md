---
name: 730-bugfix-test
description: Bug修复测试与验收综合技能。当Bug修复开发完成后触发：(1)开发并执行回归测试脚本, (2)生成修复验收报告, (3)人工确认修复完成并更新5xx文档。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "2.0.0"
---

# Bug修复测试与验收

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 回归测试 + 验收 | `test-engineer` |
| 协作 | 场景验证 | `product-manager` |
| 协作 | 风险评估 | `project-manager` |
| 决策 | 修复确认 | `product-manager` ★ |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| Bug分析报告 | `PROJECT_ROOT/issue/bugs/BUGFIX-{YYMMDD}-{topic}.md` | 710阶段输出 |
| 修复方案 | `PROJECT_ROOT/issue/bugs/BUGFIX-DESIGN-{YYMMDD}-{topic}.md` | 720阶段输出 |
| 各端修复代码 | 各端 `src/` | 720阶段输出 |
| 后端Swagger | `PROJECT_ROOT/backend/{project-name}-app/` | API接口定义 |
| 现有测试 | `PROJECT_ROOT/test/scripts/` | 现有测试基线 |

## 输出

| 输出项 | 位置 | 说明 |
|--------|------|------|
| 回归测试脚本（API） | `PROJECT_ROOT/test/scripts/api/regression-{bug}.spec.ts` | 回归API测试 |
| 回归测试脚本（E2E） | `PROJECT_ROOT/test/scripts/e2e/{project-name}/regression-{bug}.spec.ts` | 回归E2E测试 |
| 测试文档 | `PROJECT_ROOT/test/issue/BUGFIX-DESIGN-*-test.md` | 测试记录 |
| 修复验收报告 | `PROJECT_ROOT/issue/reviews/REVIEW-BUGFIX-{YYMMDDHHMM}.md` | 最终验收报告 |
| 测试报告 | `PROJECT_ROOT/test/reports/summary/final-*.md` | 测试执行报告 |
## 执行流程

### Phase 1: 回归测试开发

读取修复方案中的回归测试章节和Bug分析报告中的复现步骤，生成回归测试。

**选择器策略**: E2E测试优先使用 `getByRole()` / `getByPlaceholder()` / `locator('[name=""]')` 定位元素，无需额外添加 `data-testid`。

| 测试类型 | 说明 |
|---------|------|
| Bug复现测试 | 验证Bug已修复 |
| 边界测试 | 测试边界条件 |
| 异常测试 | 测试异常场景 |
| 原有功能测试 | 确保未破坏原有功能 |

**自动化验证**:
```bash
cd PROJECT_ROOT/test/scripts
pnpm tsc --noEmit                                    # TypeScript编译无错误
grep -rn 'data-testid' . --include="*.ts" | wc -l   # 0行
pnpm playwright test --list                           # 所有用例可列出
```

### Phase 2: 测试评审 ⚠️【强制】

**立即自动调用** [731-bugfix-test-review](../731-bugfix-test-review/SKILL.md)，传入回归测试脚本和测试报告。

> 731 未通过前，禁止进入 Phase 3。评审不通过时，731 会自动回调本技能修复。

详细的评审检查清单见 [731 checklist](../731-bugfix-test-review/references/checklist.md)。

### Phase 3: 回归测试执行

| 测试类型 | 执行内容 | 通过标准 |
|---------|---------|---------|
| Bug复现测试 | 原Bug场景 | 100%修复 |
| 边界条件 | 边界场景 | 100%通过 |
| 异常处理 | 异常场景 | 100%通过 |
| 核心流程回归 | 主业务流程 + 关联功能 + 权限流程 | 100%通过 |

### Phase 4: 修复验收报告

生成修复验收报告到 `PROJECT_ROOT/issue/reviews/REVIEW-BUGFIX-{YYMMDDHHMM}.md`，包含：

| 报告章节 | 内容 |
|---------|------|
| Bug修复验证 | Bug复现/边界条件/异常处理验证结果 |
| 回归测试结果 | 核心流程/关联功能回归状态 |
| 修复统计 | 修改文件数、新增/删除代码行数、测试用例数 |
| 风险评估 | 风险项、等级、说明 |
| 验收结论 | Bug修复状态、回归测试状态、最终状态 |
| 人工确认 ★ | Bug已修复确认、无新问题确认、修复完成确认 |

**通过标准**: Bug场景100%修复、核心流程100%通过、无新缺陷

详细的验收检查清单见 [review-checklist.md](references/review-checklist.md)。

## 人工检查点 ★

**修复确认**（Phase 4 完成后暂停）:
- [ ] Bug是否已完全修复
- [ ] 是否引入新问题
- [ ] 是否可以关闭Bug

**确认后**: 流程结束，进入 [750-bugfix-doc](../750-bugfix-doc/SKILL.md) 更新文档

## 流转关系

```
输入: Bug分析 + 修复方案 + 各端修复代码（720-bugfix-dev）
    ↓
730-bugfix-test
    ↓
回归测试开发 → 测试评审(731) → 回归测试执行 → 验收报告 → 人工确认 ★
    ↓
输出: 回归测试 + 验收报告
    ↓
进入: [750-bugfix-doc](../750-bugfix-doc/SKILL.md) 更新文档
```

## 参考

- [评审报告模板](../0-init/references/review-report-template.md)
- [测试脚本开发](../230-test-case-dev/SKILL.md)
- [Playwright文档](https://playwright.dev/)
