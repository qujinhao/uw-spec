---
name: 630-feature-test
description: 功能测试与验收综合技能。当功能开发完成后触发：(1)开发并执行测试脚本, (2)安全与性能扫描, (3)生成验收报告并人工确认上线决策。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "2.0.0"
---

# 功能测试与验收

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 测试开发 + 执行 | `test-engineer` |
| 协作 | 场景验证 | `product-manager` |
| 协作 | 代码扫描 | `system-architect` |
| 决策 | 上线确认 | `product-manager` ★ |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| 功能需求文档 | `PROJECT_ROOT/issue/features/FEATURE-{YYMMDD}-{topic}.md` | 610阶段输出 |
| 技术方案 | 各端 `issue/FEATURE-DESIGN-*-tech-design.md` | 620阶段输出 |
| 测试方案 | `PROJECT_ROOT/test/issue/FEATURE-DESIGN-*-test-design.md` | 620阶段输出 |
| 各端代码 | 各端 `src/` | 620阶段输出 |
| 后端Swagger | `PROJECT_ROOT/backend/{project-name}-app/` | API接口定义 |
| 现有测试 | `PROJECT_ROOT/test/scripts/` | 现有测试基线 |

## 输出

| 输出项 | 位置 | 说明 |
|--------|------|------|
| API测试脚本 | `PROJECT_ROOT/test/scripts/api/` | Playwright API测试 |
| E2E测试脚本 | `PROJECT_ROOT/test/scripts/e2e/` | Playwright E2E测试 |
| 测试数据 | `PROJECT_ROOT/test/scripts/data/` | 测试数据文件 |
| 测试文档 | `PROJECT_ROOT/test/issue/FEATURE-DESIGN-*-test.md` | 测试记录 |
| 验收报告 | `PROJECT_ROOT/issue/reviews/REVIEW-FEATURE-{YYMMDDHHMM}.md` | 最终验收报告 |
| 测试报告 | `PROJECT_ROOT/test/reports/summary/final-*.md` | 测试执行报告 |
## 执行流程

### Phase 1: 测试脚本开发

读取技术方案中的测试章节和功能需求中的验收标准，生成自动化测试。

**选择器策略**: E2E测试优先使用 `getByRole()` / `getByPlaceholder()` / `locator('[name=""]')` 定位元素，无需额外添加 `data-testid`。

| 测试类型 | 生成位置 | 说明 |
|---------|---------|------|
| API测试 | `PROJECT_ROOT/test/scripts/api/{feature}.spec.ts` | 接口自动化测试 |
| E2E测试 | `PROJECT_ROOT/test/scripts/e2e/{feature}.spec.ts` | 端到端测试 |
| 测试数据 | `PROJECT_ROOT/test/scripts/data/{feature}.json` | 测试数据 |

**覆盖维度**: 正向流程、异常流程、边界条件、权限控制、数据验证

**自动化验证**:
```bash
cd PROJECT_ROOT/test/scripts
pnpm tsc --noEmit                                    # TypeScript编译无错误
grep -rn 'data-testid' . --include="*.ts" | wc -l   # 0行
pnpm playwright test --list                           # 所有用例可列出
```

### Phase 2: 测试评审 ⚠️【强制】

**立即自动调用** [631-feature-test-review](../631-feature-test-review/SKILL.md)，传入测试脚本和测试报告。

> 631 未通过前，禁止进入 Phase 3。评审不通过时，631 会自动回调本技能修复。

详细的评审检查清单见 [631 checklist](../631-feature-test-review/references/checklist.md)。

### Phase 3: 测试执行

| 测试类型 | 执行内容 | 通过标准 |
|---------|---------|---------|
| API测试 | 本功能相关API | 100%通过 |
| E2E测试 | 本功能相关流程 | 100%通过 |
| 核心流程回归 | 主业务流程 + 关联功能 + 权限流程 | 100%通过 |

### Phase 4: 安全与性能扫描

| 扫描类型 | 检查内容 |
|---------|---------|
| 安全漏洞 | SQL注入、XSS、依赖漏洞 |
| 敏感信息 | 密钥、密码泄露 |
| SQL性能 | 慢查询、索引使用 |
| API性能 | 响应时间、并发能力 |
| 前端性能 | 资源加载、渲染性能 |

### Phase 5: 验收报告

生成验收报告到 `PROJECT_ROOT/issue/reviews/REVIEW-FEATURE-{YYMMDDHHMM}.md`，包含：

| 报告章节 | 内容 |
|---------|------|
| 测试执行结果 | API/E2E/回归测试通过率 |
| 代码扫描结果 | 安全漏洞、依赖漏洞统计 |
| 性能扫描结果 | SQL/API/前端性能状态 |
| 风险评估 | 风险项、等级、缓解措施 |
| 验收结论 | 最终状态（通过/不通过） |
| 人工确认 ★ | 功能完整性、质量达标、上线决策 |

**通过标准**: 测试通过率≥95%、Critical漏洞0个、核心流程回归100%通过

详细的验收检查清单见 [review-checklist.md](references/review-checklist.md)。

## 人工检查点 ★

**上线决策**（Phase 5 完成后暂停）:
- [ ] 功能是否完整实现需求
- [ ] 测试通过率是否达标（≥95%）
- [ ] 是否存在Critical安全漏洞
- [ ] 是否接受已知风险
- [ ] **是否允许上线**

**确认后**: 流程结束，进入 [650-feature-doc](../650-feature-doc/SKILL.md) 更新文档

## 流转关系

```
输入: 功能需求 + 技术方案 + 各端代码（620-feature-dev）
    ↓
630-feature-test
    ↓
测试开发 → 测试评审(631) → 测试执行 → 安全扫描 → 验收报告 → 人工确认 ★
    ↓
输出: 测试脚本 + 验收报告
    ↓
进入: 650-feature-doc（文档更新）
```

## 参考

- [评审报告模板](../0-init/references/review-report-template.md)
- [测试脚本开发](../230-test-case-dev/SKILL.md)
- [Playwright文档](https://playwright.dev/)
