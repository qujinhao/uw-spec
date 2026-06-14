---
name: 200-database-deploy
description: 数据库部署与验证技能。当需要执行数据库DDL时触发：(1)执行DDL建表语句, (2)执行增量迁移脚本, (3)验证表结构一致性。完成后自动调用 201-database-deploy-review。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# 数据库DDL执行与验证

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md) **第一步、第二步**。**第三步**（uniweb system 环境检测）：从 `~/.uniweb/uniweb-system.config` 读取 MySQL 连接参数。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | DDL执行与验证 | `java-developer` |
| 协作 | 架构确认 | `system-architect` |

## 输入

| 输入项 | 来源路径 | 说明 |
|--------|----------|------|
| DDL文件 | `PROJECT_ROOT/database/database-ddl.sql` | 200阶段产出的全量建表语句 |
| 迁移脚本 | `PROJECT_ROOT/database/migrations/*.sql` | 增量DDL变更文件 |
| 设计文档 | `PROJECT_ROOT/database/database-design.md` | 表结构设计文档（验证参照） |
| 评审报告 | `PROJECT_ROOT/database/reviews/REVIEW-DB-*.md` | 201评审通过的报告 |

### 前置条件

- [ ] 201-database-design-review 评审通过（评分 ≥ 95分）
- [ ] 目标数据库可连接
- [ ] DDL文件存在且非空

## 执行流程

### 1. 环境检查

| 检查项 | 方式 | 预期 |
|--------|------|------|
| 数据库连接 | `mysql -h {host} -u {user} -p{pass} -e "SELECT 1"` | 连接成功 |
| 数据库存在 | `SHOW DATABASES LIKE '{db_name}'` | 已存在或可创建 |
| DDL文件存在 | 检查文件路径 | 文件存在且非空 |
| 迁移目录存在 | 检查目录 | 目录存在（可为空） |

### 2. 获取数据库连接信息

#### 2.1 读取配置文件

尝试从 `~/.uniweb/uniweb-system.config` 读取 MySQL 连接参数：

| 参数 | 配置项 | 说明 |
|------|--------|------|
| 主机 | `MYSQL_HOST` | 数据库主机地址 |
| 端口 | `MYSQL_PORT` | 数据库端口（默认3306） |
| 用户名 | `MYSQL_ROOT_USERNAME` | 管理员用户名 |
| 密码 | `MYSQL_ROOT_PASSWORD` | 管理员密码 |

**读取逻辑**：
```
if (配置文件存在) {
  读取参数
  向用户确认（密码显示为 ***）
} else {
  提示用户手动输入
}
```

#### 2.2 确认连接信息

```
AskUserQuestion({
  questions: [
    {
      question: "请确认数据库连接信息（地址: {host}:{port}, 数据库: {project_name}, 用户: {user}）",
      header: "连接信息",
      options: [
        { label: "全部确认", description: "参数正确，继续执行" },
        { label: "需要修改", description: "有参数需要修改" }
      ],
      multiSelect: false
    },
    {
      question: "选择执行模式？",
      header: "执行模式",
      options: [
        { label: "首次建库", description: "全新数据库，执行完整DDL" },
        { label: "增量迁移", description: "已有数据库，执行迁移文件" }
      ],
      multiSelect: false
    }
  ]
})
```

### 3. DDL执行

**数据库名生成规则**：
```
db_name = project_name.replace('-', '_')
```

**首次全量执行**：

```bash
mysql -h {host} -P {port} -u {user} -p{pass} {db_name} < PROJECT_ROOT/database/database-ddl.sql
```

**增量迁移执行**：

1. 列出 `migrations/` 目录下最新的5个 SQL 文件（按修改时间倒序）
2. 使用 `AskUserQuestion` 让用户选择或手动输入：

```
AskUserQuestion({
  questions: [{
    question: "请选择要执行的迁移文件？",
    header: "迁移文件",
    options: [
      { label: "最新文件", description: "使用最新的迁移文件" },
      { label: "手动输入", description: "输入自定义文件路径" }
    ],
    multiSelect: false
  }]
})
```

3. 执行选中的 SQL 文件：

```bash
mysql -h {host} -P {port} -u {user} -p{pass} {db_name} < "{selected_file}"
```

**执行原则**：

| 原则 | 说明 |
|------|------|
| 先建库再建表 | 确保数据库存在后再执行DDL |
| 按顺序执行 | 迁移文件按文件名时间戳排序 |
| 失败即停 | 任一SQL执行失败，停止后续执行并报告 |
| 不自动删库 | 禁止 `DROP DATABASE`，需人工确认 |

### 4. Schema验证

| 验证项 | SQL | 预期 |
|--------|-----|------|
| 表数量 | `SHOW TABLES` | 与设计文档一致 |
| 表结构 | `SHOW CREATE TABLE {table}` | 字段、类型、索引与DDL一致 |
| 字段数量 | `DESCRIBE {table}` | 每张表字段数与设计文档匹配 |
| 索引 | `SHOW INDEX FROM {table}` | 索引存在且类型正确 |
| 通用字段 | 检查每张表 | id/saas_id/state/create_date/modify_date 齐全 |

### 5. 初始数据（如有）

检查 `PROJECT_ROOT/database/` 下是否有初始数据脚本（如 `init-data.sql`），有则执行。

### 6. 生成执行报告

**报告位置**：`PROJECT_ROOT/database/deploy/DDL-EXECUTION-REPORT-{YYMMDDHHMM}.md`

```markdown
# DDL执行报告

## 执行信息
- 执行日期: {YYYY-MM-DD HH:mm}
- 目标数据库: {host}/{db_name}
- 执行模式: 全量/增量

## 执行结果
| 文件 | 状态 | 耗时 | 说明 |
|------|------|------|------|
| database-ddl.sql | ✅/❌ | {ms} | {说明} |

## Schema验证
| 验证项 | 结果 | 详情 |
|--------|------|------|
| 表数量 | ✅/❌ | 预期{N}张，实际{M}张 |
| 字段一致性 | ✅/❌ | {不一致的表} |
| 索引完整性 | ✅/❌ | {缺失的索引} |

## 执行统计
- 成功SQL: {N}条
- 失败SQL: {N}条
- 警告: {N}条
```

## ⚠️ 完成验证（强制，全自动执行）

开发工作完成后，**立即按以下顺序自动执行**：

1. **强制调用** `201-database-deploy-review`
2. 如果评审不通过（< 95），自动修复问题，然后回到步骤 1（最多 5 轮）
3. 直到评审通过（≥ 95），**才向用户报告最终结果**

> **此流程全自动执行：中间不暂停、不询问、不汇报。**
> **未收到通过确认前，禁止结束本技能任务。**

## 输出要求

**执行报告**: `PROJECT_ROOT/database/deploy/DDL-EXECUTION-REPORT-{YYMMDDHHMM}.md`

**评审报告**: `PROJECT_ROOT/database/deploy/reviews/REVIEW-DDL-EXECUTION-{YYMMDDHHMM}.md`

## 流转关系

```
输入: 200设计产出 + 201评审通过
    ↓
200-database-deploy
    ↓
201-database-deploy-review
    ↓
通过 → 进入阶段2-Step2（210-java-uniweb-init 等）
不通过 → 修复DDL并重新执行
```

## 参考

- [数据库设计技能](../200-database-design/SKILL.md) - 上游设计阶段
- [数据库设计评审技能](../201-database-design-review/SKILL.md) - 上游评审阶段
- [DDL执行评审技能](../201-database-deploy-review/SKILL.md) - REVIEW评审技能
