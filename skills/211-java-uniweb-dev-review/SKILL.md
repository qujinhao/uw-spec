---
name: 211-java-uniweb-dev-review
description: UniWeb后端开发评审（AI原生）。当Java后端开发完成后触发：(1)评审架构蓝图与代码质量, (2)验证测试全部通过, (3)确认安全性与Javadoc完整性。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# UniWeb 后端开发评审

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 源技能引用

评审**必须先读取源技能文件**获取原始约定，禁止仅凭模型自身知识评审。

| 源技能文件 | 评审时读取的内容 |
|-----------|----------------|
| [210-java-uniweb-dev/SKILL.md](../210-java-uniweb-dev/SKILL.md) | **必读全文**：架构约定、逐模块交付流程、完成标准 |
| [210-java-uniweb-dev/references/uniweb/README.md](../210-java-uniweb-dev/references/uniweb/README.md) | UniWeb 技术栈规范 |
| [210-java-uniweb-dev/references/uniweb/dev-standards.md](../210-java-uniweb-dev/references/uniweb/dev-standards.md) | **必读"数据访问常见陷阱"**：16 条 API 陷阱 + 外部集成陷阱 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 架构评审 + 代码评审 | `system-architect` / `java-lead` |
| 协作 | 代码质量 | `java-developer` |
| 协作 | 业务确认 | `product-manager` |

## 输入

| 输入项 | 位置 | 说明 |
|--------|------|------|
| **目标模块** | 调用方传入 | 指定评审的模块名。不传则评审全部 |
| README.md | 后端项目根目录 | 架构蓝图 |
| TASKS.md | 后端项目根目录 | 进度清单 |
| Controller 代码 | `src/main/java/{package}/controller/` | 完整实现 |
| Helper 代码 | `src/main/java/{package}/service/` | 完整实现 |
| DTO/VO 代码 | `src/main/java/{package}/dto/`、`vo/` | 裁剪后 |
| 测试代码 | `src/test/java/{package}/` | Helper + Controller 测试 |
| PRD 文档 | `PROJECT_ROOT/requirement/` | 功能需求参考 |
| 数据库设计 | `PROJECT_ROOT/database/` | 数据模型参考 |

## 输出

| 类型 | 报告位置 |
|------|---------|
| 评审报告 | `issue/reviews/REVIEW-CODE-{module}-YYMMDDHHMM.md` |

格式详见 [评审报告模板](../0-init/references/review-report-template.md)。

## 评审维度

> 详细检查清单见 [checklist.md](references/checklist.md)。

| 维度 | 检查要点 | 分值 |
|------|---------|------|
| 架构蓝图完整性 | README.md 模块总览、依赖图、权限映射、缓存策略 | 15分 |
| Controller 质量 | 权限注解与角色映射一致性、Javadoc 质量、方法体业务逻辑正确性 | 15分 |
| Helper 质量 | 三条件合理性、Javadoc 步骤覆盖代码、外部集成具体性、方法体完整 | 15分 |
| DTO/VO 质量 | 搜索字段裁剪合理性、Guest DTO 隔离、VO 必要性 | 5分 |
| PRD 覆盖度 | 所有功能点有对应接口、角色覆盖 | 5分 |
| 测试质量 | 测试用例覆盖度、断言有效性、基类继承正确 | 10分 |
| 代码质量 | 分层清晰、复杂度、i18n 资源文件完整性 | 10分 |
| 安全性 | SQL 参数化、SaaS 租户隔离、modifyDate、归属权校验 | 5分 |
| 外部集成实现 | AI/通知未退化、降级逻辑、configId 动态获取 | 3分 |
| Javadoc 一致性 | 步骤覆盖代码、时序正确、modifyDate 覆盖 | 2分 |

## 通过标准

| 等级 | 分值 | Critical | Major |
|------|------|----------|-------|
| 通过 | ≥ 95 | 0 | ≤1 |
| 不通过 | < 95 | 存在 或 Major >1 | — |

> 评分 < 95 进入修复循环，无"有条件通过"中间态。

## 评审流程

> 开始前，先按"源技能引用"读取源技能，按"输入"读取所有评审对象。

### 1. 前置机械扫描

在项目目录 `backend/{project-name}-app/` 下执行 grep 快速扫描，覆盖可模式匹配的规范项：

```bash
cd backend/{project-name}-app

# Lombok（应为 0）
grep -rn '@Data\|@Getter\|@Setter\|@RequiredArgsConstructor' src/main/java/ --include="*.java" | wc -l

# 硬编码状态值（应为 0）
grep -rn 'setState(0)\|setState(1)\|setState(-1)' src/main/java/ --include="*.java" | wc -l

# 硬编码响应码（应为 0）
grep -rn 'warnCode("\|errorCode("' src/main/java/ --include="*.java" | wc -l

# ResponseData 泛型陷阱（应为 0）
grep -rn 'ResponseData\.warn("\|ResponseData\.error("' src/main/java/ --include="*.java" | wc -l

# DAO 方法名错误（应为 0）
grep -rn 'dao\.execute(\|GlobalCache\.delete(\|FusionCache\.invalidateAll(' src/main/java/ --include="*.java" | wc -l

# 路径命名（应为 0）
grep -rn '@.*Mapping.*".*[-_].*"' src/main/java/ --include="*.java" | wc -l

# TODO 残留（应为 0）
grep -rn '// TODO:' src/main/java/ --include="*.java" | wc -l

# @Schema 缺 title（应为 0）
grep -rn '@Schema(description' src/main/java/ --include="*.java" | grep -v 'title' | wc -l

# 编译 + 测试
mvn compile && mvn test
```

**任何 grep 扫描项不为 0 或 mvn test 非全绿** → 记录问题，进入步骤 3 自动修复。

### 2. 按维度评审

前置扫描通过后，逐项检查需要 AI 理解力的维度。详细清单见 [checklist.md](references/checklist.md)。

深度评审聚焦以下维度（前置扫描已覆盖的不再重复）：

| 维度 | 检查要点 | 分值 |
|------|---------|------|
| 架构蓝图完整性 | README.md 模块总览、依赖图、权限映射、缓存策略 | 15分 |
| Controller 质量 | 权限注解与角色映射一致性、Javadoc 质量、方法体业务逻辑正确性 | 15分 |
| Helper 质量 | 三条件合理性、Javadoc 步骤覆盖代码、外部集成具体性、方法体完整 | 15分 |
| DTO/VO 质量 | 搜索字段裁剪合理性、Guest DTO 隔离、VO 必要性 | 5分 |
| PRD 覆盖度 | 所有功能点有对应接口、角色覆盖 | 5分 |
| 测试质量 | 测试用例覆盖度、断言有效性、基类继承正确 | 10分 |
| 代码质量 | 分层清晰、复杂度、i18n 资源文件完整性 | 10分 |
| 安全性 | SQL 参数化、SaaS 租户隔离、modifyDate、归属权校验 | 5分 |
| 外部集成实现 | AI/通知未退化、降级逻辑、configId 动态获取 | 3分 |
| Javadoc 一致性 | 步骤覆盖代码、时序正确、modifyDate 覆盖 | 2分 |

### 3. 评审结论

**≥ 95（通过）**：输出评审报告，任务结束。

**< 95（不通过）→ 自动修复循环**：
1. 立即调用 `210-java-uniweb-dev`，传入问题清单
2. 修复完成后重新评审（最多 5 轮）
3. 仅在通过或轮次耗尽时输出结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [评审检查清单](references/checklist.md)
- [评审报告模板](../0-init/references/review-report-template.md)
- [UniWeb 技术栈](../210-java-uniweb-dev/references/uniweb/README.md)
- [API 陷阱清单](../210-java-uniweb-dev/references/uniweb/dev-standards.md)
