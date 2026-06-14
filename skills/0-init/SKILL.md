---
name: 0-init
description: uw-spec流程入口技能。当用户开始软件开发项目时触发：(1)保存项目信息到project-info.md, (2)协调各阶段任务调度, (3)管理完整开发生命周期。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# 项目初始化 - uw-spec流程入口

## 触发检查

**第一层：检查用户输入**

| 条件 | 操作 |
|------|------|
| 用户已描述具体项目/产品 | 进入第二层检查 |
| 用户仅触发技能，未提供任何信息 | 使用 `AskUserQuestion` 提示用户输入项目描述 |

**提示话术**（无输入时）：

```
AskUserQuestion({
  questions: [{
    question: "请描述你想开发的产品或项目。例如：一个SaaS多租户的电商后台管理系统、面向餐饮商家的点餐小程序等",
    header: "项目描述",
    type: "text",
    options: [
      { label: "提交描述", description: "使用上方输入框中的内容继续" },
      { label: "先看示例", description: "查看一些项目示例帮助我思考" }
    ],
    multiSelect: false
  }]
})
```

用户回答后，将描述内容作为 `project-desc` 进入第二层检查。

**第二层：检查 `PROJECT_ROOT/project-info.md` 是否存在**

| 条件 | 操作 |
|------|------|
| `PROJECT_ROOT/project-info.md` 存在 | 展示项目信息，询问用户从哪个阶段开始 |
| `PROJECT_ROOT/project-info.md` 不存在 | 进入「项目信息初始化」流程，使用用户输入的描述填充第3步 |

**存储规则**：
- **≤300字**：直接存入 YAML 头部的 `project-desc`
- **>300字**：`project-desc` 存储摘要（前100字+"..."），完整内容存入正文「项目概述」章节

**从 100/110 跳转而来的场景**：
当从 100-rapid-idea-check 或 110-requirement-planning 跳转而来时，0-init 完成初始化后**自动触发回到来源技能**继续执行。

| 来源 | 初始化完成后 |
|------|-------------|
| 100-rapid-idea-check | 自动回到 100 执行五维分析 |
| 110-requirement-planning | 自动回到 110 执行 Phase 1 需求访谈 |

## 项目环境检测

执行 [project-env-check.md](references/project-env-check.md) 中的前置检查流程。未通过时暂停执行，引导用户修复。

## 阶段模型

| 阶段 | 编号 | 说明 |
|------|------|------|
| 阶段0 | 0-init | 主流程控制 |
| 阶段1 | 1-requirement | 需求规划 - 明确做什么 |
| 阶段2 | 2-design-dev | 设计开发 - 数据库→后端→前端→测试（严格串行） |
| 阶段3 | 3-test | 测试执行 - CI/CD + 测试执行与报告 |
| 阶段5 | 5-manual | 文档交付 - 文档整理与项目归档 |
| 阶段6 | 6-feature | 功能开发 - 新功能开发（按需） |
| 阶段7 | 7-bugfix | Bug修复 - Bug修复（按需） |

> **通用规则**：每个开发 Skill 完成后**强制自动执行**对应评审（`xx1`-review），评审不通过则自动修复循环（≥95分通过），无需单独调度。

## 角色团队

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 产品经理 | 需求分析、产品设计 | `product-manager` |
| 系统架构师 | 架构设计、技术选型 | `system-architect` |
| 项目经理 | 项目规划、进度管理 | `project-manager` |
| Java后端工程师 | 基于uw-base的后端开发 | `java-developer` |
| Java负责人 | 后端代码评审、架构把控 | `java-lead` |
| JS前端工程师 | Vue3/UniApp前端开发 | `js-developer` |
| JS前端负责人 | 前端代码评审、规范把控 | `js-lead` |
| 测试工程师 | 测试设计、质量保证 | `test-engineer` |
| 测试负责人 | 测试评审、测试质量把控 | `test-lead` |
| 运维工程师 | 运维文档、部署、监控 | `devops-engineer` |
| 运维负责人 | 运维评审、发布把控 | `devops-lead` |
| 安全审计员 | 安全漏洞审计 | `security-auditor` |
| 原型评审员 | 原型质量评审 | `prototype-reviewer` |

## 技术栈

### 后端
- **基础架构**: UniWeb + SaaS技术栈 (Spring Boot + Spring Cloud)
- **数据库**: MySQL 8.4
- **缓存**: Redis 8.2
- **消息队列**: RabbitMQ

### 前端Web
- **框架**: Vue 3 + TypeScript
- **UI组件库**: Element Plus
- **构建工具**: Vite 8
- **状态管理**: Pinia

### 前端移动端
- **框架**: UniApp + Vue 3
- **跨平台**: H5、Android、iOS、微信小程序
- **UI组件库**: uni-ui

## 指令

### 启动流程

1. **项目信息初始化**（最先执行）

   **逐个询问，一问一答**：

   | 步骤 | 操作 |
   |------|------|
   | 1 | 检查 `PROJECT_ROOT/project-info.md` 是否存在 |
   | 2 | **如不存在**：使用 `AskUserQuestion` 逐个询问以下4项 |
   | 3 | **如已存在**：展示现有信息，询问是否继续使用 |

   **项目信息四问（逐个提问）**：

   使用 `AskUserQuestion` 工具逐一询问，每问一题等待用户回答：

   | # | header | question | 参考选项 | multiSelect |
   |---|--------|----------|----------|-------------|
   | 1 | 项目名称 | 请设置项目名称（英文小写+数字+下划线） | 根据用户输入动态生成建议 | false |
   | 2 | 项目标签 | 项目中文名称是什么？ | 根据项目名称自动生成建议 | false |
   | 3 | 项目描述 | 请简要描述这个项目 | 让用户自由录入 | false |
   | 4 | 项目模式 | 项目使用哪种技术模式？ | uniweb（UniWeb基础项目）、saas（SaaS多租户项目） | false |

   > **说明**：开发服务器地址在 `uniweb-system.config` 中统一管理，初始化时无需配置。

   **执行规则**：
   - 必须逐个提问，等待用户回答后再问下一个
   - 禁止使用纯文本列出所有问题让用户批量回答
   - 每个问题提供参考选项，同时支持用户自由录入

   **创建项目信息文件**：
   - 4个问题全部回答后，创建 `PROJECT_ROOT/project-info.md`
   - 使用YAML头部格式保存所有信息
   - 复制 `assets/.gitignore` 到 `PROJECT_ROOT/.gitignore`（如目标已存在则跳过）
   - 告知用户项目信息已保存

   **初始化完成后的跳转**：

   | 触发来源 | 完成后的操作 |
   |----------|-------------|
   | 用户直接触发 0-init | 询问用户从哪个阶段开始 |
   | 从 100-rapid-idea-check 跳转 | **自动回到 100** 执行五维分析 |
   | 从 110-requirement-planning 跳转 | **自动回到 110** 执行 Phase 1 需求访谈 |

2. **欢迎与确认**
   - 介绍uw-spec流程和TDD理念
   - 确认项目意向和基本信息
   - 询问从哪个阶段开始

3. **阶段执行策略**

   **执行原则**：阶段间串行，阶段2内严格串行（200→210→220→230），阶段5并行
   - 阶段间串行：必须完成前一阶段才能进入下一阶段
   - 阶段2严格串行：按200→210→220→230序号执行，前一步完成后才能开始下一步
   - 阶段5并行：500/510/520 三路并行

4. **阶段执行**

   **阶段1 - 需求规划**（产品经理主导，串行）
   - 100-rapid-idea-check → 110-requirement-planning

   **阶段2 - 设计开发**（严格串行：200→210→220→230）

   | Step | 流程 | 说明 |
   |------|------|------|
   | Step1 | 200-database-design → 200-database-deploy | 数据库设计+DDL执行 |
   | Step2 | 210-java-uniweb-init → 210-java-uniweb-gencode → 210-java-uniweb-dev | 后端初始化+代码生成+开发 |
   | Step3 | 220-{四端}-init → 220-{四端}-gencode → 220-{四端}-dev | 前端四端并行（admin-web/guest-web/admin-uni/guest-uni） |
   | Step4 | 230-test-case-dev | 测试用例设计 |

   **阶段3 - 测试执行**（串行）
   - 300-cicd-init → 310-test-report
   - 执行内容：安全扫描 → API测试 → E2E单终端测试 → E2E跨终端测试 → 压力测试

   **阶段5 - 文档交付**（文档并行）
   - 500-ops-manual / 510-requirement-doc / 520-user-manual（三路并行）

   **阶段6 - 功能开发**（按需执行）
   - 610-feature-clarify → 620-feature-dev → 630-feature-test → 650-feature-doc
   - 620-feature-dev 由 AI 自主判断修改范围，仅开发涉及的部分
   - 每步自动执行对应 xx1 评审（611/621/631/651）

  **阶段7 - Bug修复**（按需执行）
   - 710-bugfix-analysis → 720-bugfix-dev → 730-bugfix-test → 750-bugfix-doc
   - 720-bugfix-dev 由 AI 自主判断修改范围，与 620 同构设计
   - 每步自动执行对应 xx1 评审（711/721/731/751）

## 阶段流转规则

详见 [阶段流转规则](references/project-templates.md#阶段流转规则)

5. **阶段流转**
   - 每个阶段完成后确认是否进入下一阶段
   - 允许跳转到特定阶段
   - 支持返回修改之前的阶段

## 项目信息文件格式

详见 [项目信息文件格式](references/project-templates.md#项目信息文件格式)

## 项目命名规范

详见 [项目命名规范](references/project-templates.md#项目命名规范)

## TDD驱动开发原则

1. **测试先行**：先写测试，再写实现
2. **红-绿-重构**：测试失败 → 实现通过 → 重构优化
3. **验收标准**：每个需求都要有可验证的验收标准
4. **持续测试**：测试贯穿整个开发周期

## 项目结构

详见 [项目结构](references/project-templates.md#项目结构)

## 参考

- [技能清单](references/skills-reference.md) - 完整技能列表和评审流程
- [项目模板与规范](references/project-templates.md) - 项目信息格式、命名规范、项目结构、阶段流转规则
