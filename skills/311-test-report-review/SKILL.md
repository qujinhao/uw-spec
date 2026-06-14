---
name: 311-test-report-review
description: 测试执行评审技能。测试执行完成后触发：(1)审计API与E2E测试结果及覆盖率, (2)评审压力测试SLA指标与安全扫描结果, (3)评估发布风险并输出评审结论。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# 测试执行评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责
| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 测试评审 | `project-manager` |
| 协作 | 测试数据说明 | `test-engineer` |
| 协作 | 技术风险评估 | `system-architect` |
| 协作 | 缺陷修复确认 | `java-developer` / `js-developer` |

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，再基于约定进行评审，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [310-test-report/SKILL.md](../310-test-report/SKILL.md) | **必读全文**：执行流程、SLA标准、报告规范 |
| [230-test-case-dev/references/load-metrics.md](../230-test-case-dev/references/load-metrics.md) | SLA 指标定义 |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| API测试报告 | `PROJECT_ROOT/test/reports/api/report-YYMMDDHHMM.html` | API测试结果 |
| E2E测试报告 | `PROJECT_ROOT/test/reports/e2e/report-YYMMDDHHMM.html` | E2E测试结果 |
| 压测报告 | `PROJECT_ROOT/test/reports/load/report-YYMMDDHHMM.html` | 压测结果 |
| 安全报告 | `PROJECT_ROOT/test/reports/security/` | ZAP/Trivy扫描结果 |
| 缺陷记录 | `PROJECT_ROOT/test/reports/summary/summary-YYMMDDHHMM.md` | 缺陷汇总 |

## 输出
| 输出项 | 位置 | 说明 |
|--------|------|------|
| 测试执行评审报告 | `PROJECT_ROOT/test/reviews/REVIEW-EXECUTION-YYMMDDHHMM.md` | 评审结论和问题清单 |

报告格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

### API 测试结果评审
| 维度 | 检查要点 |
|------|---------|
| 通过率 | ≥98% 通过率 |
| 覆盖率 | 设计文档中 ≥90% 用例已执行 |
| 失败分析 | 每个失败用例有缺陷记录和根因分析 |

### E2E 测试结果评审
| 维度 | 检查要点 |
|------|---------|
| 通过率 | ≥98% 通过率 |
| 跨终端流程 | 核心业务流程100%通过 |
| 跨终端执行覆盖 | 跨终端脚本（cross-case/）全部执行且通过 |
| 截图证据 | 失败用例有自动截图 |

### 压测结果评审
| 维度 | 检查要点 |
|------|---------|
| SLA达标 | P95/P99/TPS/错误率是否达标 |
| 性能拐点 | 压力测试找到的性能拐点记录 |
| 稳定性 | 长时间运行无内存泄漏 |

### 安全扫描结果评审
| 维度 | 检查要点 |
|------|---------|
| ZAP结果 | 无 High 级别漏洞 |
| Trivy结果 | 无 Critical 级别依赖漏洞 |
| 修复状态 | 已发现漏洞的修复或规避措施 |

## 通过标准

| 等级 | 评分 | 条件 |
|------|------|------|
| 通过 | ≥ 95 分 | 无 Critical 缺陷，API 通过率 ≥ 98%，E2E 通过率 ≥ 98%，SLA 达标，安全无 Critical/High 漏洞，缺陷修复率 100% |
| 不通过 | < 95 分 | 存在 Critical 缺陷或通过率不达标 |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始评审前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 执行评审
按维度检查，记录问题。评审发现记录格式和评审报告结构详见 [评审报告模板](../0-init/references/review-report-template.md)。

详细的评审检查清单见 [checklist.md](references/checklist.md)。

**评审对象**: `PROJECT_ROOT/test/reports/`
**参与人员**: @project-manager @test-engineer @system-architect


### 2. 评审结论

计算最终评分后，按以下规则执行：

**评分 ≥ 95（通过）：**
1. 标记评审状态为「通过」
2. 输出评审报告，任务结束

**评分 < 95（不通过）→ 自动修复循环：**
1. 立即调用 `310-test-report`，传入问题清单
2. 修复完成后立即重新执行本技能评审
3. 若仍 < 95，回到步骤 1（最多 5 轮）
4. 仅在通过或轮次耗尽时输出结果

> 此流程全自动执行：中间不暂停、不询问、不汇报。
> 未收到通过确认前，禁止结束本技能任务。

## 参考

- [评审报告模板](../0-init/references/review-report-template.md) - 通用评审报告格式
- [评审检查清单](references/checklist.md) - 测试执行评审检查项
- [测试执行技能](../310-test-report/SKILL.md) - 被评审的上游技能
