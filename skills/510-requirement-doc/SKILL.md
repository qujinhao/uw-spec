---
name: 510-requirement-doc
description: 需求文档整理技能。整理项目需求交付物时触发：(1)汇总PRD与用户故事地图, (2)归档业务流程图与验收标准, (3)整理需求变更记录与追溯矩阵。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# 需求文档整理

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 文档整理 | `product-manager` |
| 协作 | 文档完整性确认 | `project-manager` |
| 协作 | 需求与测试对应 | `test-engineer` |

## 交付物清单

| 序号 | 文档名称 | 说明 | 格式 | 必需 |
|------|----------|------|------|------|
| 1 | 产品需求文档(PRD) | 完整的产品需求描述 | Markdown | ✅ |
| 2 | 用户故事地图 | 用户故事全景图 | Markdown | ✅ |
| 3 | 业务流程图 | 核心业务流程可视化 | Mermaid | ✅ |
| 4 | 功能清单 | 功能模块详细清单 | Markdown | ✅ |
| 5 | 需求变更记录 | 需求变更历史记录 | Markdown | ✅ |
| 6 | 验收标准汇总 | 各功能验收标准 | Markdown | ✅ |

## PRD文档结构

详见 [PRD文档结构大纲](references/templates.md#prd-文档结构大纲)

## 整理流程

### 1. 收集资料
- 各终端需求文档
- 用户故事和验收标准
- 业务流程图和线框图
- 需求变更记录

### 2. 汇总PRD
- 按文档结构整理
- 确保内容完整准确
- 统一格式和术语

### 3. 整理用户故事地图
- 按用户角色组织
- 按优先级排序
- 标注完成状态

### 4. 归档业务流程图
- 确保图表清晰可读
- 补充必要的文字说明

### 5. 汇总验收标准
- 按功能模块组织
- 确保AC可测试
- 标注测试状态

## ⚠️ 完成验证（强制，全自动执行）

开发工作完成后，**立即按以下顺序自动执行**：

1. **强制调用** `511-requirement-doc-review`
2. 如果评审不通过（< 95），自动修复问题，然后回到步骤 1（最多 5 轮）
3. 直到评审通过（≥ 95），**才向用户报告最终结果**

> **此流程全自动执行：中间不暂停、不询问、不汇报。**
> **未收到通过确认前，禁止结束本技能任务。**

## 输出要求

**输出位置**: `PROJECT_ROOT/requirement/`

**目录结构**:
```
PROJECT_ROOT/requirement/
├── prds/                          # PRD产品文档
│   ├── README.md                  # PRD主文档
│   ├── CHANGELOG.md               # PRD变更历史
│   └── {role}-{platform}/      # 按角色和终端分目录
├── interviews/                    # 需求访谈记录
└── reviews/                       # 评审报告
    └── REVIEW-PRD-YYMMDDHHMM.md   # 按时间戳命名，24小时制
```

## 参考

- [PRD文档结构大纲](references/templates.md#prd-文档结构大纲) - 文档模板
- [需求文档评审技能](../511-requirement-doc-review/SKILL.md) - REVIEW评审技能
- [文档模板](references/templates.md) - PRD模板、用户故事地图模板、功能清单模板
