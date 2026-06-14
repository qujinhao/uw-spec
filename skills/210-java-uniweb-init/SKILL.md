---
name: 210-java-uniweb-init
description: Java后端项目初始化技能。当需要创建Java后端API项目时触发：(1)从模板解压项目结构, (2)全文替换模板关键字为实际项目名, (3)验证项目结构完整性。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# 后端项目初始化

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 项目初始化 | `java-developer` |
| 协作 | 架构确认 | `system-architect` |


## 模板

使用 `uw-app-template.zip` 模板，基于 uw-base 框架的通用API应用。

## 初始化流程

**执行前必须询问用户确认**。

### 步骤1: 展示后端项目目录

**目标目录**：直接使用当前项目根目录（包含 `PROJECT_ROOT/project-info.md` 的目录）。

检查并展示后端目录状态：

```bash
ls -la PROJECT_ROOT/backend/ 2>/dev/null || echo "PROJECT_ROOT/backend/ 目录不存在，将自动创建"
```

**后端项目将初始化在**：`PROJECT_ROOT/backend/{project-name}-app/`

### 步骤2: 询问用户参数

```
AskUserQuestion({
  questions: [{
    question: "如果目录已存在，如何处理？",
    header: "覆盖模式",
    options: [
      { label: "force", description: "强制覆盖已有文件" },
      { label: "skip", description: "跳过已存在文件" }
    ],
    multiSelect: false
  }]
})
```

### 步骤3: 用户确认

**必须**向用户展示以下信息并等待确认：

```
即将执行 Java 后端项目初始化：
- 项目名: {project-name}
- 输出目录: PROJECT_ROOT/backend/{project-name}-app/
- 覆盖模式: {用户选择的模式}

确认执行吗？
```

用户确认后，再执行脚本。

### 步骤4: 执行脚本

用户确认后，执行命令（确保在技能目录下执行）：
```bash
bash scripts/init.sh [目标目录] [模式]
```

**参数说明**：

| 参数 | 说明 | 是否必填 | 默认值 |
|------|------|----------|--------|
| 目标目录 | 项目根目录（包含 `PROJECT_ROOT/project-info.md`） | 是 | 当前目录 |
| 模式 | `force`(强制覆盖), `skip`(跳过已存在文件) | 否 | force |

**执行示例**：

```bash
# 强制覆盖模式（默认）
bash scripts/init.sh /Users/user/project

# 强制覆盖模式（显式指定）
bash scripts/init.sh /Users/user/project force

# 跳过已存在文件
bash scripts/init.sh /Users/user/project skip
```

**脚本输出说明**：
- `✓` 表示通过
- `⚠` 表示警告
- `ERROR` 表示错误，会终止执行

## 输出要求

**输出位置**: `PROJECT_ROOT/backend/{project-name}-app/` 目录

**包含内容**: 从模板解压并替换后的完整项目结构

**目录结构**:
```
项目根目录/
├── project-info.md
└── PROJECT_ROOT/backend/
    └── {project-name}-app/
        ├── src/
        └── pom.xml
```

## 下一步

初始化完成后，提示用户进入 **`210-java-uniweb-gencode`** 进行代码生成（从数据库生成 entity/dto/controller）。

**流程位置**：`210-java-uniweb-init` → **`210-java-uniweb-gencode`** → `210-java-uniweb-dev`

## 参考

- [初始化脚本](scripts/init.sh) - 自动化初始化脚本
- [UniWeb模板](assets/uw-app-template.zip) - UniWeb后端项目模板
