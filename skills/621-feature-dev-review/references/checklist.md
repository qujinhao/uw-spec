# 功能开发评审检查清单

> **源技能**：[620-feature-dev/SKILL.md](../../620-feature-dev/SKILL.md) — 评审时必须回到源技能核实。

## 技术方案检查

| # | 检查项 | 标准 | 严重程度 |
|---|--------|------|---------|
| 1 | DB设计 | 表结构合理、命名规范、索引充分、DDL可执行 | Critical |
| 2 | 接口设计 | RESTful、权限注解、DTO/Helper签名完整 | Critical |
| 3 | 前端设计 | 页面结构、路由、组件、字段一致性 | Major |
| 4 | 测试策略 | API+E2E+单元测试，场景完整 | Major |
| 5 | PRD覆盖 | 技术方案覆盖所有需求点 | Critical |
| 6 | 兼容性 | DDL向后兼容、接口向后兼容 | Critical |

## 方案一致性检查

| # | 检查项 | 标准 | 严重程度 |
|---|--------|------|---------|
| 1 | 接口实现 | 路径/方法/参数与技术方案完全一致 | Critical |
| 2 | DTO字段 | 与技术方案完全一致 | Critical |
| 3 | DDL已执行 | 表结构与设计一致 | Critical |

## 后端代码检查

| # | 检查项 | 标准 | 严重程度 |
|---|--------|------|---------|
| 1 | UniWeb规范 | DaoManager/ResponseData/AuthQueryParam/FusionCache正确 | Critical |
| 2 | 禁用Lombok | 无Lombok注解 | Critical |
| 3 | API陷阱 | 16条API陷阱全部检查 | Critical |
| 4 | 分层清晰 | Controller/Service/Helper/Dao分层正确 | Major |

## 前端代码检查

| # | 检查项 | 标准 | 严重程度 |
|---|--------|------|---------|
| 1 | Vue3规范 | `<script setup>`、Composition API | Critical |
| 2 | TypeScript | 无 `as any`（除proxy as any），API响应类型声明 | Critical |
| 3 | 编码原则 | 集中管理、类型安全、项目一致性、代码可读性 | Major |
| 4 | 字段一致性 | 表单/表格字段名与API Schema一致 | Critical |

## TDD覆盖检查

| # | 检查项 | 标准 | 严重程度 |
|---|--------|------|---------|
| 1 | 后端行覆盖 | ≥80% | Major |
| 2 | 后端分支覆盖 | ≥70% | Major |
| 3 | 前端核心覆盖 | ≥70% | Major |
| 4 | 测试可运行 | 所有测试通过 | Critical |

## 安全性检查

| # | 检查项 | 标准 | 严重程度 |
|---|--------|------|---------|
| 1 | 参数校验 | @Valid + 前端表单校验 | Critical |
| 2 | SQL安全 | 参数化查询 | Critical |
| 3 | 权限控制 | @MscPermDeclare + 路由守卫 | Critical |
| 4 | 租户隔离 | saas_id条件 | Critical |
