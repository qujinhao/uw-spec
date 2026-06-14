---
name: 300-cicd-init
description: CI/CD流水线初始化技能。配置持续集成/部署流水线时触发：(1)选择Git平台与执行模式, (2)选择目标项目(后端/前端多选), (3)生成CI/CD配置脚本。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# CI/CD 流水线初始化

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | CI/CD设计与配置 | `devops-engineer` |
| 协作 | 架构确认 | `system-architect` |

## 前置条件

读取 `PROJECT_ROOT/project-info.md`，确认以下信息：

| 字段 | 用途 |
|------|------|
| `project-name` | 整体项目名称（如 `zihu`），用于各模块名的前缀 |
| `project-mode` | 项目模式（uniweb/saas），影响部署配置 |
| `current-stage` | 当前阶段，确认项目已进入开发阶段 |

## 关键概念：project-name vs module-name

**`project-name`** 是整体项目名（来自 `project-info.md`），如 `zihu`。

**`module-name`** 是各前后端项目的目录名，也是 CI/CD 文件名的主体。规则：

```
module-name = 项目目录名（backend/ 或 frontend/ 下的子目录名）
cicd文件名 = {module-name}.yml
```

**示例**（project-name=zihu）：

| 目录 | module-name | cicd文件名 | 类型 |
|------|-------------|-----------|------|
| `backend/zihu-app` | `zihu-app` | `zihu-app.yml` | Java |
| `frontend/zihu-saas-web` | `zihu-saas-web` | `zihu-saas-web.yml` | Web |
| `frontend/zihu-guest-uni` | `zihu-guest-uni` | `zihu-guest-uni.yml` | UniApp |

## 项目类型

CI/CD 模板按项目类型分为 **3 类**：

| 类型 | 说明 | 构建方式 |
|------|------|---------|
| **Java** | 后端项目，Maven构建 | `mvn package` → Docker多架构镜像 |
| **Web** | 前端项目，目录名以 `-web` 结尾 | `pnpm build` → Nginx Docker镜像 |
| **UniApp** | 前端项目，目录名以 `-uni` 结尾 | `pnpm build:h5` → H5 Docker镜像 + `pnpm build:mp-weixin` → 小程序产物 |

**类型识别规则**：根据模块目录的位置和后缀自动判断：
- `backend/*` → Java
- `frontend/*-web` → Web
- `frontend/*-uni` → UniApp

## 初始化流程

### 步骤1: 选择 Git 平台

```
AskUserQuestion({
  questions: [{
    question: "项目使用哪个 Git 平台？",
    header: "Git平台",
    options: [
      { label: "Gitea", description: "自托管Git平台，支持Shell和Actions两种执行模式，.gitea/workflows/" },
      { label: "GitHub", description: "GitHub平台，使用Actions执行模式，.github/workflows/" }
    ],
    multiSelect: false
  }]
})
```

### 步骤2: 选择执行模式（仅 Gitea）

当 Git 平台选择 **Gitea** 时，需进一步选择执行模式。**GitHub** 固定使用 Actions 模式，跳过此步。

```
AskUserQuestion({
  questions: [{
    question: "选择 Gitea 流水线执行模式？",
    header: "执行模式",
    options: [
      { label: "Shell", description: "纯Shell脚本模式，自托管Runner预装环境，使用gitea.*上下文变量，支持deploy-registry-app.sh部署" },
      { label: "Actions", description: "Gitea Actions模式，兼容GitHub Actions语法，使用actions/*和docker/*等标准Action" }
    ],
    multiSelect: false
  }]
})
```

### 步骤3: 选择目标项目

扫描 `PROJECT_ROOT` 下已有的项目目录，动态生成选项：

```bash
ls -d PROJECT_ROOT/backend/*/ 2>/dev/null
ls -d PROJECT_ROOT/frontend/*/ 2>/dev/null
```

对每个发现的模块目录，自动识别类型（Java/Web/UniApp），展示给用户选择。

```
AskUserQuestion({
  questions: [{
    question: "选择需要配置CI/CD的项目（可多选）？",
    header: "目标项目",
    options: [
      { label: "{module-name}", description: "Java后端，Maven构建+Docker多架构镜像推送" },
      ...
    ],
    multiSelect: true
  }]
})
```

**过滤规则**：仅展示 `PROJECT_ROOT` 下实际存在的模块目录。

### 步骤4: 确认并生成

**展示配置摘要**：

```
即将生成 CI/CD 配置：
- Git平台: {Gitea/GitHub}
- 执行模式: {Shell/Actions}（GitHub固定Actions）
- 目标项目:
  - zihu-app (Java) → zihu-app.yml
  - zihu-saas-web (Web) → zihu-saas-web.yml
  - zihu-guest-uni (UniApp) → zihu-guest-uni.yml

确认生成吗？
```

用户确认后，按配置生成对应文件。

## 输出结构

```
PROJECT_ROOT/
├── .gitea/workflows/          # Gitea (Shell 或 Actions)
│   ├── zihu-app.yml
│   ├── zihu-saas-web.yml
│   └── zihu-guest-uni.yml
├── .github/workflows/         # GitHub (Actions)
│   ├── zihu-app.yml
│   ├── zihu-saas-web.yml
│   └── zihu-guest-uni.yml
```

**注意**：
- workflow文件统一放在项目根的 `.gitea/workflows/` 或 `.github/workflows/` 下
- 通过 `paths` 过滤实现 monorepo 各模块独立触发
- 每个模块一个 yml 文件，文件名 = 模块目录名

## 模板体系

3 种项目类型 × 2 种执行模式 = **6 个模板**（GitHub 共用 Actions 模板）：

| | Shell 模式 | Actions 模式 |
|------|-----------|-------------|
| **Java** | Java-Shell | Java-Actions |
| **Web** | Web-Shell | Web-Actions |
| **UniApp** | UniApp-Shell | UniApp-Actions |

详见 [工作流模板](references/workflow-templates.md)

## 变量替换规则

生成模板时，将 `{module-name}` 替换为实际的模块目录名：

| 占位符 | 说明 | Java 示例 | Web 示例 | UniApp 示例 |
|--------|------|-----------|----------|-------------|
| `{module-name}` | 模块目录名 | `zihu-app` | `zihu-saas-web` | `zihu-guest-uni` |
| `{module-path}` | 模块相对路径 | `backend/zihu-app` | `frontend/zihu-saas-web` | `frontend/zihu-guest-uni` |
| `{app-port}` | 应用服务端口 | `59999` | `60001` | `60002` |

**替换后的效果**：

| 字段 | Java | Web | UniApp |
|------|------|-----|--------|
| 文件名 | `zihu-app.yml` | `zihu-saas-web.yml` | `zihu-guest-uni.yml` |
| `name` | `zihu-app` | `zihu-saas-web` | `zihu-guest-uni` |
| `paths` | `['backend/zihu-app/**']` | `['frontend/zihu-saas-web/**']` | `['frontend/zihu-guest-uni/**']` |
| `MODULE_PATH` | `backend/zihu-app` | `frontend/zihu-saas-web` | `frontend/zihu-guest-uni` |
| `APP_NAME` | `zihu-app` | `zihu-saas-web` | H5: `zihu-guest-h5` / MP: `zihu-guest-mp-weixin` |

## 核心流程说明

### 通用流程

```
push to main → paths过滤 → 构建产物 → Docker多架构镜像(amd64+arm64) → 推送到私有Registry → 部署
```

### Shell vs Actions 差异

| 阶段 | Shell 模式 | Actions 模式 |
|------|-----------|-------------|
| 环境加载 | `source ~/.profile`（SDKMAN/Java等） | `actions/setup-java@v4` (liberica, Java 25) |
| 检出 | `git clone` + `gitea.token`认证，自动适配http/https | `actions/checkout@v4` |
| Java | Runner预装 | `actions/setup-java@v4` (liberica, Java 25) |
| Node | Runner预装 | `actions/setup-node@v4` (Node 20) |
| QEMU | 手动 `docker run multiarch/qemu-user-static` | `docker/setup-qemu-action@v3` |
| Buildx | 手动 `docker buildx create` | `docker/setup-buildx-action@v3` |
| Docker登录 | Shell `docker login` | `docker/login-action@v3` |
| Docker构建 | Shell `docker buildx build` | `docker/build-push-action@v6` |
| 小程序产物 | `tar -czf` 打包 | `actions/upload-artifact@v4` |
| 部署 | `deploy-registry-app.sh` | 无（仅推送镜像） |
| Nginx基础镜像 | 私有Registry镜像 | `nginx:stable-alpine`（Docker Hub） |
| 版本输出 | Shell变量 `APP_VERSION` | `$GITHUB_OUTPUT` |
| 变量引用 | `${{vars.XXX}}` 无空格 | `${{ vars.XXX }}` 有空格 |

### Web 项目特殊说明

Web 项目在构建时内联生成 `Dockerfile` 和 `nacos-entrypoint.sh`，通过 Nacos 实现服务注册/注销。

### UniApp 项目特殊说明

UniApp 项目包含两个并行 Job：
- `build-h5`：构建 H5 版本 → Docker 镜像推送
- `build-mp-weixin`：构建微信小程序 → 产物打包

## 环境配置变量

详见 [环境配置参考](references/env-config.md)
