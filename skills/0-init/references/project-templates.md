# 项目模板与规范

## 项目信息文件格式

**文件位置**: `project-info.md`

```markdown
---
project-name: project-name（限定英文小写字母+数字+下划线，下划线只能出现在中间，长度1-32个字符，例如：nova_app）
project-label: 项目标签（项目中文名，例如：Nova应用）
project-desc: 项目描述信息（例如：Nova应用是一个基于Java的Web应用，用于管理用户信息和订单。）
project-mode: uniweb（项目模式：uniweb=UniWeb基础项目，saas=SaaS多租户项目）
created-at: 2024-01-01T00:00:00+08:00（项目创建时间，ISO8601格式）
updated-at: 2024-01-01T00:00:00+08:00（最后更新时间，ISO8601格式）
current-stage: 0-init（当前流程阶段）
current-skill: 0-init（当前执行技能）
---

# 项目信息

## 项目概述
...

## 技术栈
...

## 项目结构
...
```

## 完整项目结构

```
project/
├── project-info.md           # 项目信息文件
├── requirement/              # 需求规划文档
│   ├── prds/                 # PRD产品需求文档
│   │   ├── README.md         # 项目总览（唯一汇总文档）
│   │   ├── domains/          # 业务领域（多端共享的业务对象和规则）
│   │   │   └── M{seq}-{name}.md
│   │   ├── {role}-{platform}/    # 前端项目
│   │   │   ├── M{seq}-{name}/
│   │   │   │   └── M{seq}P{seq}-{name}.md
│   │   │   └── ...
│   ├── interviews/           # 需求访谈记录
│   │   └── INTERVIEW-{YYMMDDHHMM}-{topic}.md
│   └── reviews/              # 需求评审报告
│       └── REVIEW-PRD-{YYMMDDHHMM}.md
├── database/                 # 数据库设计文档
│   ├── database-design.md
│   ├── database-ddl.sql
│   ├── migrations/           # 日期开头的DDL文件
│   │   ├── FEATURE-{YYMMDD}-{topic}.sql
│   │   └── BUGFIX-{YYMMDD}-{topic}.sql
│   ├── deploy/               # DDL执行产物
│   │   ├── DDL-EXECUTION-REPORT-{YYMMDDHHMM}.md
│   │   └── reviews/          # DDL执行评审报告
│   │       └── REVIEW-DDL-EXECUTION-{YYMMDDHHMM}.md
│   └── reviews/              # 数据库设计评审报告
│       └── REVIEW-DB-{YYMMDDHHMM}.md
├── backend/                  # 后端项目（Java + uw-base）
│   └── {project-name}-app/
│       ├── README.md     # 后端架构文档
│       ├── CHANGELOG.md  # 代码变更历史
│       ├── issue/     # 功能级技术文档（6xx/7xx阶段）
│       │    ├── FEATURE-DESIGN-{YYMMDD}-{topic}.md
│       │    └── BUGFIX-DESIGN-{YYMMDD}-{topic}.md
│       ├── reviews/      # 评审报告
│       │   ├── REVIEW-DESIGN-{YYMMDDHHMM}.md
│       │   └── REVIEW-CODE-{YYMMDDHHMM}.md
│       └── src/              # 源代码
├── frontend/                 # 前端项目
│   └── {project-name}-{role}-{platform}/
│       ├── README.md
│       ├── CHANGELOG.md
│       ├── issue/     # 功能级技术文档（6xx/7xx阶段）
│       │    ├── FEATURE-DESIGN-{YYMMDD}-{topic}.md
│       │    └── BUGFIX-DESIGN-{YYMMDD}-{topic}.md
│       ├── reviews/      # 评审报告
│       │   ├── REVIEW-DESIGN-{YYMMDDHHMM}.md
│       │   └── REVIEW-CODE-{YYMMDDHHMM}.md
│       └── src/              # 源代码
├── test/                     # 测试项目
│   ├── README.md
│   ├── CHANGELOG.md
│   ├── design/               # 测试设计文档
│   │   ├── api/              # API测试设计
│   │   ├── e2e/              # E2E测试设计
│   │   ├── load/             # 压测设计
│   │   └── security/         # 安全测试设计
│   ├── scripts/              # 测试脚本
│   │   ├── api/              # API测试脚本（Playwright）
│   │   │   └── *.spec.ts
│   │   ├── e2e/              # E2E测试脚本（Playwright）
│   │   │   ├── {project-name}/      # 单终端E2E
│   │   │   ├── cross-case/   # 跨终端E2E
│   │   │   └── shared/       # 共享工具和Page Object
│   │   ├── load/             # 压测脚本（JMeter .jmx）
│   │   │   └── data/         # CSV测试数据
│   │   ├── security/         # 安全测试脚本
│   │   ├── utils/            # 共享工具函数
│   │   ├── fixtures/         # 测试固件
│   │   ├── data/             # 测试数据
│   │   └── bin/              # 执行脚本
│   ├── reports/              # 汇总测试报告
│   │   └── test-report-{YYMMDDHHMM}/
│   │       ├── api/
│   │       ├── e2e/
│   │       ├── load/
│   │       ├── security/
│   │       └── README.md
│   ├── issue/      # 功能级测试设计（6xx阶段）
│   │   ├── FEATURE-DESIGN-{YYMMDD}-{topic}.md
│   │   └── BUGFIX-DESIGN-{YYMMDD}-{topic}.md
│   └── reviews/
│       ├── REVIEW-DESIGN-{YYMMDDHHMM}.md
│       └── REVIEW-CODE-{YYMMDDHHMM}.md
├── issue/              # Bug修复文档（7xx阶段）
│   ├── features/                 # 功能修复方案
│   │   ├── FEATURE-{YYMMDD}-{topic}.md
│   ├── bugs/                 # Bug分析与修复方案
│   │   ├── BUGFIX-{YYMMDD}-{topic}.md
│   └── reviews/              # 验收评审报告
│       ├── REVIEW-FEATURE-{YYMMDD}-{topic}-{HHMM}.md
│       └── REVIEW-BUGFIX-{YYMMDD}-{topic}-{HHMM}.md
└── manual/                 # 文档交付阶段（5xx）
    ├── ops-manual/           # 运维文档
    │   ├── README.md         # 运维文档主文档
    │   ├── CHANGELOG.md
    ├── user-manual/          # 用户手册
    │   ├── README.md
    │   ├── CHANGELOG.md
    │   └── {role}-{platform}/   # 按用户角色和终端类型分目录
    │        └── README.md
    └── reviews/              # 验收评审报告
        ├── REVIEW-OPS-MANUAL-{YYMMDDHHMM}.md
        └── REVIEW-USERS-MANUAL-{YYMMDDHHMM}.md
```

## 阶段流转规则

### 流转原则

```
阶段间串行 → 必须完成前一阶段才能进入下一阶段
阶段内按序串行 → 同一阶段内按序号执行（阶段2: 200→210→220→230）
评审强制执行 → 每个主流程完成后自动执行对应评审（≥95分通过）
按需执行 → 阶段6/7根据需求触发，不强制流转
```

### 阶段编号对照

| 编号 | 阶段名称 | 说明 |
|------|----------|------|
| 0 | 主流程控制 | 项目初始化、流程协调 |
| 1 | 需求规划 | 需求收集、分析、规划 |
| 2 | 设计开发 | 数据库→后端→前端→测试（严格串行） |
| 3 | 测试执行 | CI/CD初始化、测试执行与报告 |
| 5 | 文档交付 | 运维文档、需求文档、用户手册（并行） |
| 6 | 功能开发 | 新功能开发（按需执行） |
| 7 | Bug修复 | Bug修复（按需执行） |

### 阶段流转条件

| 从阶段 | 到阶段 | 流转条件 | 说明 |
|--------|--------|----------|------|
| 阶段0 | 阶段1 | 项目信息确认 | 完成项目初始化 |
| 阶段1 | 阶段2 | 需求评审通过（≥95分） | 需求明确且可执行 |
| 阶段2 | 阶段3 | 设计评审全部通过（≥95分） | 数据库+后端+前端+测试设计完成 |
| 阶段3 | 阶段5 | 测试评审全部通过（≥95分） | 系统可发布 |
| 阶段5 | - | 文档整理完成 | 项目文档归档 |
| *按需* | 阶段6 | 新功能需求 | 触发610-feature-clarify |
| *按需* | 阶段7 | Bug报告 | 触发710-bugfix-analysis |

### 阶段内执行规则

| 阶段 | 执行方式 | 说明 |
|------|---------|------|
| 阶段1 | 串行 | 100 → 110 |
| 阶段2 | 严格串行 | Step1 DB(200) → Step2 后端(210) → Step3 前端(220四端并行) → Step4 测试(230) |
| 阶段3 | 串行 | 300 → 310 |
| 阶段5 | 并行 | 500 / 510 / 520 三路并行 |
| 阶段6 | 串行 | 610 → 620 → 630 |
| 阶段7 | 串行 | 710 → 720 → 730 |

### 阶段回退规则

| 回退场景 | 回退到 | 触发条件 |
|----------|--------|----------|
| 设计阶段发现需求问题 | 1-requirement | 需求评审不通过 |
| 测试阶段发现设计问题 | 2-design | 设计评审不通过 |
| 测试阶段发现需求问题 | 1-requirement | 严重需求缺陷 |

### 特殊流转

**阶段6/7**:
- 功能开发: `610-feature-clarify` → `620-feature-dev` → `630-feature-test`
- Bug修复: `710-bugfix-analysis` → `720-bugfix-dev` → `730-bugfix-test`
- 阶段6/7可独立循环，不影响主线流程

**快速通道**:
- 紧急修复: 可跳过部分评审，但需事后补评审
- 文档更新: 可直接进入阶段5

## 项目信息更新规则

### 元数据更新时机

| 触发时机 | 更新字段 | 说明 |
|----------|----------|------|
| 任何技能执行完成 | `updated-at` | 更新为当前时间（ISO8601格式） |
| 任何技能执行完成 | `current-skill` | 更新为刚完成的技能ID |
| 阶段流转完成 | `current-stage` | 更新为新阶段ID |

### 项目结构更新规则

每个流程完成后，必须在 `project-info.md` 的「项目结构」章节更新已明确的目录位置：

| 完成流程 | 更新内容 | 示例 |
|----------|----------|------|
| 0-init | 确认项目根目录结构 | `project-name: my-shop` → `backend/my-shop-app/` |
| 110-requirement | 添加PRD文档路径 | `requirement/prds/README.md` |
| 200-database-design | 添加数据库文档路径 | `database/database-design.md` |
| 210-java-uniweb-init | 确认后端项目路径 | `backend/my-shop-app/`（已初始化） |
| 220-admin-web-init | 确认前端项目路径 | `frontend/my-shop-admin-web/`（已初始化） |
| 610-feature-clarify | 添加功能需求文档 | `requirement/prds/README.md`（更新主文档） |
| 620-feature-dev | 添加技术方案与代码文档 | `backend/my-shop-app/issue/FEATURE-DESIGN-*.md` |
| 710-bugfix-analysis | 添加Bug分析报告 | `issue/bugs/BUGFIX-240115-登录失败.md` |

### 更新示例

**初始状态**（0-init完成后）：
```markdown
## 项目结构

```
my-shop/
├── project-info.md
├── requirement/
└── backend/
    └── my-shop-app/          # 待初始化
```
```

**需求规划完成后**（110-requirement完成后）：
```markdown
## 项目结构

```
my-shop/
├── project-info.md
├── requirement/
│   ├── prds/
│   │   ├── README.md           # 项目总览（唯一汇总文档）
│   │   ├── domains/            # 业务领域
│   │   │   └── M01-用户与认证.md
│   │   ├── guest-uni/       # 游客-移动端
│   │   │   └── M01-首页/
│   │   │       └── M01P01-首页.md
│   │   └── admin-web/          # 管理员-Web端
│   │       └── M01-用户管理/
│   │           └── M01P01-用户管理.md
│   ├── interviews/
│   │   └── INTERVIEW-2401011430-初始需求.md
│   └── reviews/
└── backend/
    └── my-shop-app/          # 待初始化
```
```

**设计开发完成后**（200-database-design + 210-java-uniweb-init完成后）：
```markdown
## 项目结构

```
my-shop/
├── project-info.md
├── requirement/
│   └── prds/
│       └── ...
└── backend/
    └── my-shop/          # 已初始化
        ├── pom.xml
        ├── README.md
        ├── CHANGELOG.md
        ├── issue/
        └── reviews/
└── database/
    ├── database-design.md
    ├── database-ddl.sql
    ├── migrations/
    ├── deploy/
    │   └── reviews/
    └── reviews/
```
```

**功能开发完成后**（`610-feature-clarify` → `620-feature-dev` → `630-feature-test` 完成后）：
```markdown
## 项目结构

```
my-shop/
├── project-info.md
├── requirement/
│   └── prds/
│       ├── README.md  # 功能需求已合并到主文档
│       └── ...
├── database/
│   └── migrations/
│       └── FEATURE-240115-订单导出.sql
├── backend/
│   └── my-shop-app/
│       ├── issue/
│       │   └── FEATURE-DESIGN-240115-订单导出.md
│       ├── reviews/
│       │   └── REVIEW-CODE-2401151430.md
│       └── src/
├── frontend/
│   └── my-shop-guest-web/
│       ├── issue/
│       │   └── FEATURE-DESIGN-240115-订单导出.md
│       ├── reviews/
│       │   └── REVIEW-CODE-2401151430.md
│       └── src/
├── test/
│   ├── issue/
│   │   └── FEATURE-DESIGN-240115-订单导出.md
│   ├── reviews/
│   │   └── REVIEW-CODE-2401151430.md
│   └── scripts/
├── issue/
│   ├── features/
│   │   └── FEATURE-240115-订单导出.md
│   └── reviews/
│       └── REVIEW-FEATURE-240115-订单导出-1430.md
└── manual/
    ├── ops-manual/
    │   ├── README.md
    │   └── CHANGELOG.md
    └── user-manual/
        ├── README.md
        ├── CHANGELOG.md
        └── guest-web/
            └── README.md
```
```
