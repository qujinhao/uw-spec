# uw-spec 技能清单

## 流程执行策略

本流程采用**阶段间串行、阶段内按序号串行**的执行策略：

| 阶段 | 编号 | 执行方式 | 说明 |
|------|------|---------|------|
| 阶段0 | 0-init | 串行 | 主流程控制 |
| 阶段1 | 1xx | 串行 | 需求规划 |
| 阶段2 | 2xx | 严格串行 | 200→210→220→230 按序执行 |
| 阶段3 | 3xx | 串行 | 测试执行 |
| 阶段5 | 5xx | 文档并行 | 文档交付 |
| 阶段6 | 6xx | 按需执行 | 功能开发 |
| 阶段7 | 7xx | 按需执行 | Bug修复 |

> **通用规则**：每个开发 Skill 完成后**强制自动执行**对应评审（`xx1`-review），评审不通过则自动修复循环（≥95分通过），无需单独调度。下表不列出评审 Skill。

## 阶段 0: 主流程控制

| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 0 | 0-init | uw-spec 软件开发流程入口 | 全角色 |

## 阶段 1: 需求规划

| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 100 | 100-rapid-idea-check | 快速想法验证 | 产品经理 |
| 110 | 110-requirement-planning | 需求规划（PRD、流程图、线框图） | 产品经理 |

**流程**: 100-rapid-idea-check → 110-requirement-planning

## 阶段 2: 设计开发（严格串行）

> 按200→210→220→230序号执行，前一步完成后才能开始下一步。

**Step 1: 数据库（200）**

| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 200 | 200-database-design | 数据库设计 | 系统架构师 |
| 200 | 200-database-deploy | 数据库DDL执行与验证 | Java后端工程师 |

**Step 2: 后端（210）**

| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 210 | 210-java-uniweb-init | Java后端项目初始化 | Java后端工程师 |
| 210 | 210-java-uniweb-gencode | Java代码生成 | Java后端工程师 |
| 210 | 210-java-uniweb-dev | UniWeb后端设计与开发（TDD） | Java后端工程师 |

**Step 3: 前端（220，四端并行）**

> **角色约束**：`admin-*` 技能用于 root/ops/saas/mch 角色，`guest-*` 技能用于 guest 角色。详见 [角色-平台矩阵](role-platform-matrix.md)

| 编号 | 技能名 | 说明 | 适用角色 | 主导角色 |
|------|--------|------|---------|---------|
| 220 | 220-admin-web-init → 220-admin-web-gencode → 220-admin-web-dev | Admin Web端 | root/ops/saas/mch | JS前端工程师 |
| 220 | 220-guest-web-init → 220-guest-web-gencode → 220-guest-web-dev | Guest Web端 | guest | JS前端工程师 |
| 220 | 220-admin-uni-init → 220-admin-uni-gencode → 220-admin-uni-dev | Admin UniApp端 | root/ops/saas/mch | JS前端工程师 |
| 220 | 220-guest-uni-init → 220-guest-uni-gencode → 220-guest-uni-dev | Guest UniApp端 | guest | JS前端工程师 |

**Step 4: 测试设计（230）**

| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 230 | 230-test-case-dev | 测试用例设计（API/E2E/压测/安全） | 测试工程师 |

## 阶段 3: 测试执行

| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 300 | 300-cicd-init | CI/CD流水线初始化（Shell/Actions） | 运维工程师 |
| 310 | 310-test-report | 测试执行与报告（API/E2E/压测/安全） | 测试工程师 |

**流程**: 300-cicd-init → 310-test-report

**执行内容**: 安全扫描 → API测试 → E2E单终端测试 → E2E跨终端测试 → 压力测试

## 阶段 5: 文档交付（并行）

| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 500 | 500-ops-manual | 运维文档编写 | 运维工程师 |
| 510 | 510-requirement-doc | 需求文档整理 | 产品经理 |
| 520 | 520-user-manual | 用户手册编写 | 测试工程师 |

**流程（三路并行）**: 500-ops-manual / 510-requirement-doc / 520-user-manual

## 阶段 6: 功能开发（按需执行）

| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 610 | 610-feature-clarify | 功能需求澄清 ★人工确认 | 产品经理 |
| 620 | 620-feature-dev | 功能开发（技术方案+全端代码） ★人工确认 | 系统架构师 |
| 630 | 630-feature-test | 功能测试与验收 ★人工确认 | 测试工程师 |
| 650 | 650-feature-doc | 5xx文档更新（运维/用户/需求） | 运维工程师 |

**流程**: 610-feature-clarify → 620-feature-dev → 630-feature-test → 650-feature-doc

**说明**: 620-feature-dev 由 AI 自主判断修改范围（DB/Backend/Admin-Web/Guest-Web/Admin-UniApp/Guest-UniApp），仅开发涉及的部分。

## 阶段 7: Bug修复（按需执行）

| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 710 | 710-bugfix-analysis | Bug分析 ★人工确认 | 开发工程师 |
| 720 | 720-bugfix-dev | Bug修复开发（修复方案+全端代码） ★人工确认 | 系统架构师 |
| 730 | 730-bugfix-test | Bug修复测试与验收 ★人工确认 | 测试工程师 |
| 750 | 750-bugfix-doc | 5xx文档更新（运维/用户/需求） | 运维工程师 |

**流程**: 710-bugfix-analysis → 720-bugfix-dev → 730-bugfix-test → 750-bugfix-doc

**说明**: 720-bugfix-dev 由 AI 自主判断修改范围，与 620 同构设计。
