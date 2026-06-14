---
name: 750-bugfix-doc
description: Bug修复文档更新技能。当Bug修复测试通过后触发：(1)更新运维文档和故障处理手册, (2)更新用户手册（FAQ）, (3)更新需求文档并合并到5xx主文档。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# Bug修复文档更新

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 运维文档更新 | `devops-engineer` |
| 协作 | 用户手册更新 | `test-engineer` |
| 协作 | 需求文档更新 | `product-manager` |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| 修复验收报告 | `PROJECT_ROOT/issue/reviews/REVIEW-BUGFIX-{YYMMDDHHMM}.md` | 730阶段输出 |
| Bug分析报告 | `PROJECT_ROOT/issue/bugs/BUGFIX-{YYMMDD}-{topic}.md` | 710阶段输出 |
| 修复方案 | `PROJECT_ROOT/issue/bugs/BUGFIX-DESIGN-{YYMMDD}-{topic}.md` | 720阶段输出 |
| 现有5xx文档 | `manual/` | 现有交付文档 |

## 输出

| 输出项 | 位置 | 说明 |
|--------|------|------|
| 运维文档更新 | `manual/ops-manual/` | 运维更新记录 |
| 用户手册更新 | `manual/user-manual/` | 手册更新记录 |
| 需求文档更新 | `PROJECT_ROOT/requirement/` | 需求更新记录 |
| 更新后主文档 | `manual/xxx/README.md` | 合并后的主文档 |
| 变更记录 | `manual/xxx/CHANGELOG.md` | 文档变更历史 |

## 执行流程

### 1. 运维文档更新

**更新内容**:

| 文档 | 更新点 |
|------|--------|
| 故障处理手册 | 新增Bug故障场景处理 |
| 监控手册 | 新增Bug相关监控指标 |
| 已知问题 | 记录Bug及修复版本 |

**生成更新记录**:

**文件位置**: `manual/ops-manual/`

**内容**:
```markdown
# BUGFIX-{YYMMDD}-{Bug名称} - 运维文档更新

## 更新概要
- 更新日期: {YYYY-MM-DD}
- Bug名称: {Bug名称}

## 故障处理手册更新
### Bug场景
{Bug现象}

### 处理方法
1. {步骤1}
2. {步骤2}

### 修复版本
- 修复版本: {version}
- 发布时间: {date}

## 合并状态
- [x] 已合并到 troubleshooting.md
- [x] 已合并到 known-issues.md
```

### 2. 用户手册更新

**更新内容**:

| 文档 | 更新点 |
|------|--------|
| FAQ | 新增Bug相关FAQ |
| 已知问题 | 记录Bug及规避方法 |
| 版本说明 | 记录Bug修复版本 |

**生成更新记录**:

**文件位置**: `manual/user-manual/`

### 3. 需求文档更新

**更新内容**:

| 文档 | 更新点 |
|------|--------|
| 已知问题清单 | 记录Bug及状态 |
| 变更记录 | 记录Bug修复变更 |
| 版本历史 | 记录修复版本 |

**生成更新记录**:

**文件位置**: `PROJECT_ROOT/requirement/`

### 4. 文档合并

**合并规则**:

| 更新文档 | 合并位置 | 方式 |
|---------|---------|------|
| 运维更新 | `manual/ops-manual/*.md` | 追加章节 |
| 手册更新 | `manual/user-manual/*.md` | 追加章节 |
| 需求更新 | `PROJECT_ROOT/requirement/*.md` | 追加章节 |

**CHANGELOG更新**:

```markdown
## {YYYY-MM-DD} BUG-{Bug名称}
- 类型: Bug修复文档更新
- 运维文档: 已更新
- 用户手册: 已更新
- 需求文档: 已更新
- 状态: 文档同步完成
```

## 输出要求

**运维更新**: `manual/ops-manual/`

**手册更新**: `manual/user-manual/`

## 流转关系

```
输入: 修复验收报告 + Bug分析 + 修复方案
    ↓
750-bugfix-doc
    ↓
更新运维文档 → 更新用户手册 → 更新需求文档 → 合并到主文档
    ↓
输出: 更新的5xx文档
    ↓
751-bugfix-doc-review（自动评审）
```

## ⚠️ 完成验证（强制，全自动执行）

开发工作完成后，**立即按以下顺序自动执行**：

1. **强制调用** `751-bugfix-doc-review`
2. 如果评审不通过（< 95），自动修复问题，然后回到步骤 1（最多 5 轮）
3. 直到评审通过（≥ 95），**才向用户报告最终结果**

> **此流程全自动执行：中间不暂停、不询问、不汇报。**
> **未收到通过确认前，禁止结束本技能任务。**

## 完成标准

| 检查项 | 标准 |
|--------|------|
| 运维文档 | 故障处理、已知问题已更新 |
| 用户手册 | FAQ、版本说明已更新 |
| 需求文档 | 已知问题清单、变更记录已更新 |
| 主文档 | 所有变更已合并 |

## 完成验证（强制，全自动执行）

> ⚠️ 完成后必须调用 751-bugfix-doc-review，未通过前禁止声称完成。

1. 检查所有输出文件存在且非空
2. 自动调用 [751-bugfix-doc-review](../751-bugfix-doc-review/SKILL.md)
3. 评审通过（≥95分）→ 报告结果
4. 评审未通过 → 自动修复（最多5轮）→ 重新评审
