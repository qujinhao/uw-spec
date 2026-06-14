---
name: 220-guest-web-init
description: Web前端项目初始化（Nuxt3+Vue3+TS）。当创建Web前端项目时触发：(1)通过脚手架初始化项目, (2)配置项目名称和基础设置, (3)安装依赖并验证。
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

## 模板说明

本技能使用 `pnpm dlx nuxi@latest init` 官方脚手架创建项目，不使用 zip 模板。角色固定为 `guest`，无需模板选择。

## 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Nuxt | 3.x | 全栈Vue框架（SSR/SSG/SPA） |
| Vue | 3.x | 前端框架 |
| TypeScript | 5.x | 类型安全 |
| Tailwind CSS | 4.x | 原子化CSS |

## 初始化流程

**执行前必须询问用户确认**。

### 步骤1: 询问用户参数

```
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
- 前端项目名: {project-name}-guest-web
- 角色: guest
- 技术栈: Nuxt 3 + Vue 3 + TypeScript + Tailwind CSS
- 输出目录: PROJECT_ROOT/frontend/{project-name}-guest-web/

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
| 角色 | 用户角色（guest固定） | 否 | guest |

**执行示例**：

```bash
# 初始化 guest-web（默认角色）
bash scripts/init.sh /Users/user/project force

# 初始化 guest-web，跳过已存在文件
bash scripts/init.sh /Users/user/project skip guest
```

**脚本输出说明**：
- `✓` 表示通过
- `⚠` 表示警告
- `ERROR` 表示错误，会终止执行

## 输出要求

**输出位置**: `PROJECT_ROOT/frontend/{project-name}-{role}-web/` 目录

**包含内容**: 通过 `pnpm dlx nuxi@latest init` 脚手架创建的完整 Nuxt 3 项目

**目录结构**:
```
项目根目录/
├── project-info.md
└── PROJECT_ROOT/frontend/
    └── {project-name}-{role}-web/
        ├── pages/
        ├── components/
        ├── composables/
        ├── nuxt.config.ts
        ├── package.json
        ├── tsconfig.json
        └── tailwind.config.ts
```

**命名示例**（假设项目名为 `my-shop`）：
| 角色 | 前端项目名 | 目录 |
|------|-----------|------|
| guest | my-shop-guest-web | PROJECT_ROOT/frontend/my-shop-guest-web/ |

## 下一步

初始化完成后，提示用户进入 **`220-guest-web-gencode`** 进行前端代码生成（从后端Swagger生成api/router/page/i18n）。

**流程位置**：`220-guest-web-init` → **`220-guest-web-gencode`** → `220-guest-web-dev` (+ `221-guest-web-dev-review`)

## 参考

- [初始化脚本](scripts/init.sh) - 自动化初始化脚本
