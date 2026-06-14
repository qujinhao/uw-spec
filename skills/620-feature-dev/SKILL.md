---
name: 620-feature-dev
description: 功能开发综合技能。当需求澄清完成后触发：(1)评审需求完整性并设计技术方案, (2)自主判断修改范围（DB/后端/前端）并按需开发各端代码, (3)自动评审修复循环。编码规范引用210/220的references
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "2.0.0"
---

# 功能开发

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 技术方案 + 全端开发 | `system-architect` |
| 协作 | 后端开发 | `java-developer` |
| 协作 | 前端开发 | `js-developer` |
| 协作 | 测试验证 | `test-engineer` |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| 功能需求文档 | `PROJECT_ROOT/issue/features/FEATURE-{YYMMDD}-{topic}.md` | 610阶段输出 |
| 现有DB设计 | `PROJECT_ROOT/database/database-design.md` | 现有数据库设计 |
| 各端现有代码 | `PROJECT_ROOT/backend/` + `PROJECT_ROOT/frontend/` | 各端代码基线 |
| 各端架构文档 | 各端 `README.md` | 编码规范 |

## 输出

| 输出项 | 位置 | 说明 |
|--------|------|------|
| DDL文件 | `PROJECT_ROOT/database/migrations/FEATURE-{YYMMDD}-{topic}.sql` | 数据库变更DDL |
| 技术方案 | `PROJECT_ROOT/backend/{project-name}-app/issue/FEATURE-DESIGN-{YYMMDD}-{topic}-tech-design.md`（后端）、`PROJECT_ROOT/frontend/{project-name}-{platform}/issue/FEATURE-DESIGN-{YYMMDD}-{topic}-tech-design.md`（前端） | 各端技术方案 |
| 测试方案 | `PROJECT_ROOT/test/issue/FEATURE-DESIGN-{YYMMDD}-{topic}-test-design.md` | 测试策略 |
| 功能代码 | 各端 `src/` | 各端功能代码 |
| 测试代码 | 各端 `src/test/` 或 `src/**/*.spec.ts` | 单元测试 |
| 开发文档 | 各端 `issue/FEATURE-DESIGN-{YYMMDD}-{topic}-{platform}.md` | 开发记录 |
| 评审报告 | 各端 `issue/reviews/REVIEW-CODE-{YYMMDDHHMM}.md` | AI评审报告 |
| 变更记录 | 各端 `CHANGELOG.md` | 代码变更历史 |

## 修改范围决策表

AI 读取需求后，按以下表格自主判断修改范围，**仅开发需要的端**：

| 判断条件 | 执行操作 | 编码规范引用 |
|---------|---------|-------------|
| 涉及新数据实体或字段变更 | 设计DDL → 执行DDL | [210 references](../210-java-uniweb-dev/references/uniweb/) |
| 涉及后端接口或业务逻辑 | 开发Java后端代码 | [210 dev-standards](../210-java-uniweb-dev/references/uniweb/dev-standards.md) |
| 涉及管理端Web界面 | 开发 admin-web 代码 | [220-admin-web](../220-admin-web-dev/references/coding-principles.md) |
| 涉及用户端Web界面 | 开发 guest-web 代码 | [220-guest-web](../220-guest-web-dev/references/coding-principles.md) |
| 涉及管理端移动端 | 开发 admin-uni 代码 | [220-admin-uni](../220-admin-uni-dev/references/coding-principles.md) |
| 涉及用户端移动端 | 开发 guest-uni 代码 | [220-guest-uni](../220-guest-uni-dev/references/coding-principles.md) |

> 各端天然独立可并行。DDL需先执行完毕后才能开始后端开发。

## 执行流程

### Phase 1: 技术方案设计

按"修改范围决策表"判断需要的端，为每端生成技术方案：

| 方案类型 | 输出位置 | 必要条件 |
|---------|---------|---------|
| DDL | `PROJECT_ROOT/database/migrations/FEATURE-*.sql` | 涉及DB变更 |
| 后端方案 | `PROJECT_ROOT/backend/{project-name}-app/issue/FEATURE-DESIGN-*-tech-design.md` | 涉及后端 |
| Web前端方案 | `PROJECT_ROOT/frontend/{project-name}-{role}-web/issue/FEATURE-DESIGN-*-tech-design.md` | 涉及Web |
| 移动端方案 | `PROJECT_ROOT/frontend/{project-name}-{role}-uni/issue/FEATURE-DESIGN-*-tech-design.md` | 涉及UniApp |
| 测试方案 | `PROJECT_ROOT/test/issue/FEATURE-DESIGN-*-test-design.md` | 始终生成 |

**DDL通用字段**: `id`(BIGINT NOT NULL) / `create_date`(DATETIME(3) NOT NULL) / `modify_date`(DATETIME(3)) / `state`(INT NOT NULL DEFAULT 1)

**后端方案内容**: 模块划分、API列表（路径/方法/请求/响应）、数据模型变更、权限设计、缓存策略、异常处理

**前端方案内容**: 页面结构、组件设计、状态管理、API对接、交互流程

**测试方案内容**: API测试场景、E2E测试场景、边界测试、异常测试、测试数据、回归范围

### Phase 2: 技术方案评审 ⚠️【强制】

**立即自动调用** [621-feature-dev-review](../621-feature-dev-review/SKILL.md)，传入技术方案、各端代码和需求文档。

> 621 未通过前，禁止进入 Phase 3。评审不通过时，621 会自动回调本技能修复。

### Phase 3: 代码开发

按修改范围决策结果，对每个需要的端执行开发。编码前**必读**对应端的技术规范文档。

**后端开发**（如涉及）:
- 编码前读取 [dev-standards.md](../210-java-uniweb-dev/references/uniweb/dev-standards.md)（API 陷阱 + 编码原则）
- 遵循 [210 架构约定](../210-java-uniweb-dev/SKILL.md)（static Helper / DaoManager.getInstance() / 禁用 Lombok）
- TDD Red-Green 内部循环：先写测试确认失败 → 写实现确认通过。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)
- 单元测试: `@SpringBootTest` + `BaseIntegrationTest` + `TestAuthUtil(saasId=666)`
- 编译验证: `mvn compile` + `mvn test -Dspring.profiles.active=debug`

**Web前端开发**（如涉及）:
- Admin Web: Vue3 + Element Plus + Pinia + `<script setup>`
- Guest Web: Nuxt 3 + Tailwind CSS + Shadcn Vue + Pinia
- 编码前读取对应端 [coding-principles.md]
- TDD Red-Green 内部循环：先写测试确认失败 → 写实现确认通过。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)
- 编译验证: `pnpm build` + `pnpm vue-tsc --noEmit`（Admin）/ `pnpm nuxi typecheck`（Guest）

**UniApp开发**（如涉及）:
- Vue3 + UniApp组件 + 条件编译（`#ifdef MP-WEIXIN`）+ uni-ui
- 编码前读取对应端 [coding-principles.md]
- TDD Red-Green 内部循环：先写测试确认失败 → 写实现确认通过。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)
- 编译验证: `pnpm build:h5` + `pnpm build:mp-weixin`

### Phase 4: 代码评审 ⚠️【强制】

Phase 3 完成后，**立即自动执行**代码评审：

| 维度 | 检查要点 |
|------|---------|
| 方案一致性 | 代码实现与技术方案完全一致，接口/DTO/Helper无偏差 |
| 代码规范 | 后端遵循uw-base规范，前端遵循Vue3/UniApp规范 |
| 测试覆盖 | 后端行≥80%/分支≥70%，前端核心业务≥70% |
| 安全性 | @Valid校验、SQL参数化、@MscPermDeclare、SaaS租户隔离（saas_id） |
| 影响范围 | 未修改无关模块，变更范围可控 |

**通过标准**: ≥95分（无Critical，Major≤2）
**不通过 → 自动修复循环**（最多5轮，全自动执行，中间不暂停、不询问、不汇报）

**立即自动调用** [621-feature-dev-review](../621-feature-dev-review/SKILL.md)，传入各端代码和技术方案。

> 621 未通过前，禁止进入 Phase 5。评审不通过时，621 会自动回调本技能修复代码。

详细的评审检查清单见 [621 checklist](../621-feature-dev-review/references/checklist.md)。

### Phase 5: 文档输出

| 文档 | 位置 | 说明 |
|------|------|------|
| 开发文档 | 各端 `issue/FEATURE-DESIGN-{YYMMDD}-{topic}-{platform}.md` | 实现概要、代码变更、测试覆盖、评审结果 |
| CHANGELOG | 各端 `CHANGELOG.md` | 追加变更记录 |
| 主文档更新 | 各端 `README.md` + `database-design.md` | 合并架构更新 |

## 人工检查点 ★

**技术方案确认**（Phase 1 通过评审后暂停）:
- [ ] 数据库设计合理（索引、字段类型）
- [ ] 接口设计完整（参数、响应）
- [ ] 前后端接口对齐
- [ ] 测试方案覆盖所有需求点
- [ ] 技术方案可实施

**确认后**: 进入 Phase 3 代码开发

## ⚠️ 完成验证（强制，全自动执行）

本技能采用**分阶段评审**机制（不同于其他技能的单次评审）：

1. Phase 2 技术方案完成后 → **强制调用** `621-feature-dev-review` 评审技术方案
2. Phase 4 代码开发完成后 → **强制调用** `621-feature-dev-review` 评审代码
3. 任一评审不通过（< 95）→ 自动修复 → 重新评审（最多 5 轮）
4. 两阶段评审均通过后 → 向用户报告最终结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 流转关系

```
输入: 功能需求文档（610 → 611评审通过）
    ↓
620-feature-dev
    ↓
技术方案设计 → 技术方案评审(621) → 人工确认 ★ → 代码开发 → 代码评审(621) → 文档输出
    ↓
输出: 各端代码 + 测试 + 文档
    ↓
等待: 630-feature-test
```

## 参考

- [UniWeb开发规范](../210-java-uniweb-dev/references/uniweb/dev-standards.md)
- [UniWeb技术栈](../210-java-uniweb-dev/references/uniweb/README.md)
- [Admin Web编码原则](../220-admin-web-dev/references/coding-principles.md)
- [Guest Web编码原则](../220-guest-web-dev/references/coding-principles.md)
- [Admin UniApp编码原则](../220-admin-uni-dev/references/coding-principles.md)
- [Guest UniApp编码原则](../220-guest-uni-dev/references/coding-principles.md)
- [评审报告模板](../0-init/references/review-report-template.md)
