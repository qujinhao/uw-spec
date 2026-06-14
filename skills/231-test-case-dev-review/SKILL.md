---
name: 231-test-case-dev-review
description: 自动化测试开发评审。当测试脚本开发完成后触发：(1)评审API测试脚本质量和断言准确性, (2)评审E2E测试脚本和Page Object规范性, (3)评审JMeter压测脚本配置合理性, (4)评审安全扫描脚本覆盖完整性, (5)验证执行脚本齐全。当用户提及测试评审、Playwright评审、JMeter评审时使用此技能。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# 自动化测试开发评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [230-test-case-dev/SKILL.md](../230-test-case-dev/SKILL.md) | **必读全文**：架构约定速查表、逐类型交付流程、完成标准 |
| [230-test-case-dev/references/templates.md](../230-test-case-dev/references/templates.md) | 测试用例模板 |
| [230-test-case-dev/references/load-metrics.md](../230-test-case-dev/references/load-metrics.md) | SLA 指标定义 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 测试评审 | `test-lead` |
| 协作 | 后端可测试性 | `java-developer` |
| 协作 | 前端可测试性 | `js-developer` |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| 测试设计文档 | `PROJECT_ROOT/test/design/` | 四类测试用例设计 |
| API测试脚本 | `PROJECT_ROOT/test/scripts/api/` | Playwright request 脚本 |
| E2E测试脚本 | `PROJECT_ROOT/test/scripts/e2e/` | Playwright browser 脚本 |
| JMeter脚本 | `PROJECT_ROOT/test/scripts/load/` | .jmx 压测脚本 |
| 安全测试脚本 | `PROJECT_ROOT/test/scripts/security/` | ZAP/Trivy/Playwright 脚本 |
| 执行脚本 | `PROJECT_ROOT/test/scripts/bin/` | Bash 脚本 |
| PRD | `PROJECT_ROOT/requirement/prds/*` | 需求覆盖参考 |
| Controller代码 | `PROJECT_ROOT/backend/{project-name}-app/src/main/java/{package}/controller/` | 接口覆盖参考 |

## 输出

| 输出项 | 位置 |
|--------|------|
| 测试评审报告 | `PROJECT_ROOT/test/reviews/REVIEW-DEV-YYMMDDHHMM.md` |

格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

> 详细检查清单见 [checklist.md](references/checklist.md)。

| 维度 | 检查要点 | 分值 |
|------|---------|------|
| 设计完整性 | 接口覆盖、页面覆盖、场景覆盖、OWASP 覆盖 | 20 |
| API 测试质量 | 三重断言、数据驱动、权限覆盖、错误场景 | 20 |
| E2E 测试质量 | Page Object、字段一致性选择器、跨终端、独立性 | 20 |
| JMeter 质量 | 4 场景齐全、参数化、SLA 合理、断言完整 | 15 |
| 安全测试质量 | OWASP Top 10、ZAP/Trivy 配置、注入测试 | 10 |
| 执行脚本 | bin/ 齐全、参数化、报告输出 | 5 |
| 编译与可运行性 | tsc 通过、playwright test 通过、无 data-testid | 必须 |

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 | Critical=0，Major≤1，API 覆盖≥90%，E2E 核心 100%，JMeter 4 场景，OWASP 覆盖 |
| 不通过 | < 95 | 存在 Critical 或 Major>1 或覆盖率不达标 |

## 评审流程

> 开始前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 编译与可运行性验证

```bash
cd PROJECT_ROOT/test/scripts
pnpm tsc --noEmit
pnpm playwright test --list
grep -rn 'data-testid' . --include="*.ts" | wc -l
```

**全部通过后**才进入维度评审。

### 2. 按维度评审

逐项检查，记录问题。详细清单见 [checklist.md](references/checklist.md)。

### 3. 评审结论

**≥ 95（通过）**：输出评审报告，任务结束。

**< 95（不通过）→ 自动修复循环**：
1. 立即调用 `230-test-case-dev`，传入问题清单
2. 修复完成后重新评审（最多 5 轮）
3. 仅在通过或轮次耗尽时输出结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [评审检查清单](references/checklist.md)
- [评审报告模板](../0-init/references/review-report-template.md)
- [测试开发技能](../230-test-case-dev/SKILL.md)
