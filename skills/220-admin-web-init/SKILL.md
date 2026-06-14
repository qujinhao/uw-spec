---
name: 220-admin-web-init
description: 管理端Web项目初始化（Vue3+TS+Vite+ElementPlus）。当创建后台管理Web前端时触发：(1)从模板解压项目结构, (2)全文替换模板关键字为项目名, (3)验证项目结构完整性。适用于admin/saas/mch/root/ops角色。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# Web端项目初始化

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 项目初始化 | `js-developer` |
| 协作 | 架构确认 | `system-architect` |


## 模板选择

| 模板文件 | 适用场景 | 说明 |
|---------|---------|------|
| `saas-admin-web-template.zip` | SaaS多租户管理后台 | 基于 saas-base 框架，含租户/商户管理 |
| `uw-admin-web-template.zip` | UniWeb管理后台 | 基于 uw-base 框架，通用Web应用 |

**选择时机**：在 `0-init` 阶段通过 `PROJECT_ROOT/project-info.md` 的 `project-mode` 字段（`uniweb`/`saas`）确定，本脚本自动读取。

## 初始化流程

**执行前必须询问用户确认**。

### 步骤1: 询问用户参数

```
AskUserQuestion({
  questions: [
    {
      question: "这个Web端面向哪个用户角色类别？",
      header: "角色类别",
      options: [
        { label: "root", description: "系统管理员" },
        { label: "ops", description: "运维管理" },
        { label: "admin", description: "总后台" },
        { label: "saas", description: "SAAS管理" },
        { label: "mch", description: "SAAS商户" }
      ],
      multiSelect: false
    }
  ]
})
AskUserQuestion({
  questions: [
    {
      question: "如果目录已存在，如何处理？",
      header: "覆盖模式",
      options: [
        { label: "force", description: "强制覆盖已有文件" },
        { label: "skip", description: "跳过已存在文件" }
      ],
      multiSelect: false
    }
  ]
})
```

### 步骤2: 用户确认

**必须**向用户展示以下信息并等待确认：

```
即将执行 Web 前端项目初始化：
- 项目名: {project-name}
- 前端项目名: {project-name}-{role}-web
- 角色: {用户选择的角色}
- 输出目录: PROJECT_ROOT/frontend/{project-name}-{role}-web/

确认执行吗？
```

用户确认后，再执行脚本。

### 步骤3: 执行脚本

用户确认后，执行命令（确保在技能目录下执行）：
```bash
bash scripts/init.sh [目标目录] [模式] [角色]
```

**参数说明**：

| 参数 | 说明 | 是否必填 | 默认值 |
|------|------|----------|--------|
| 目标目录 | 项目根目录（包含 `project-info.md`） | 是 | 当前目录 |
| 模式 | `force`(强制覆盖), `skip`(跳过已存在文件) | 否 | force |
| 角色 | 用户角色（admin/saas/mch/guest/root） | 否 | admin |

**执行示例**：

```bash
# 初始化 admin-web（默认角色）
bash scripts/init.sh /Users/user/project force

# 初始化 saas-web
bash scripts/init.sh /Users/user/project force saas

# 初始化 mch-web，跳过已存在文件
bash scripts/init.sh /Users/user/project skip mch
```

**脚本输出说明**：
- `✓` 表示通过
- `⚠` 表示警告
- `ERROR` 表示错误，会终止执行

## 输出要求

**输出位置**: `PROJECT_ROOT/frontend/{project-name}-{role}-web/` 目录

**包含内容**: 从模板解压并替换后的完整项目结构

**目录结构**:
```
项目根目录/
├── project-info.md
└── PROJECT_ROOT/frontend/
    └── {project-name}-{role}-web/
        ├── src/
        ├── package.json
        ├── tsconfig.json
        └── vite.config.ts
```

**命名示例**（假设项目名为 `my-shop`）：
| 角色 | 前端项目名 | 目录 |
|------|-----------|------|
| root | my-shop-root-web | PROJECT_ROOT/frontend/my-shop-root-web/ |
| ops | my-shop-ops-web | PROJECT_ROOT/frontend/my-shop-ops-web/ |
| admin | my-shop-admin-web | PROJECT_ROOT/frontend/my-shop-admin-web/ |
| saas | my-shop-saas-web | PROJECT_ROOT/frontend/my-shop-saas-web/ |
| mch | my-shop-mch-web | PROJECT_ROOT/frontend/my-shop-mch-web/ |
| guest | my-shop-guest-web | PROJECT_ROOT/frontend/my-shop-guest-web/ |

## 下一步

初始化完成后，提示用户进入 **`220-admin-web-gencode`** 进行前端代码生成（从后端Swagger生成api/router/page/i18n）。

**流程位置**：`220-admin-web-init` → **`220-admin-web-gencode`** → `220-admin-web-dev` (+ `221-admin-web-dev-review`)

## 参考

- [初始化脚本](scripts/init.sh) - 自动化初始化脚本
- [SaaS模板](assets/saas-admin-web-template.zip) - SaaS Web前端模板
- [UniWeb模板](assets/uw-admin-web-template.zip) - UniWeb Web前端模板
