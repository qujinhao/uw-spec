# 项目根目录检测与前置检查

## 问题

AI Coding 工具可能从项目任意子目录启动（如 `frontend/my-shop-admin-web/`），但 skill 中的项目文件路径（`project-info.md`、`database/`、`backend/`、`frontend/`）都是相对于项目根目录的。

## 第一步：定位项目根目录

从当前目录向上逐层查找 `project-info.md`，最多查找 3 层。

| 步骤 | 操作 |
|------|------|
| 1 | 依次检查 `./project-info.md`、`../project-info.md`、`../../project-info.md`、`../../../project-info.md` |
| 2 | 找到后，将该文件所在目录记为 `PROJECT_ROOT`（后续所有项目文件路径基于此） |
| 3 | 4 层均未找到 → 提示用户先在项目根目录执行 0-init |

**0-init 特殊规则**：未找到时使用当前工作目录作为 `PROJECT_ROOT`（新项目场景，`project-info.md` 将在此目录创建）。

## 第二步：检查项目信息完整性

读取 `PROJECT_ROOT/project-info.md`，检查 YAML 头部是否包含以下 4 个参数，值不能为空或占位符：

| 参数 | 格式要求 | 示例 |
|------|---------|------|
| `project-name` | 英文小写+数字+下划线，1-32字符，下划线仅在中间 | `nova_app` |
| `project-label` | 项目中文名称 | `Nova应用` |
| `project-desc` | 项目描述 | `Nova应用是一个基于Java的Web应用` |
| `project-mode` | 项目模式：`uniweb` 或 `saas` | `uniweb` |

| 检查结果 | 操作 |
|---------|------|
| 文件存在且 4 个参数完整 | 继续当前技能 |
| 文件不存在或参数缺失 | 暂停当前技能，引导用户执行 0-init |

### 引导话术

当检查不通过时，向用户说明：

```
当前技能需要项目信息（project-info.md）才能继续执行。

请先使用 /0-init 技能完成项目信息初始化，完成后可继续当前技能。
```

## 第三步：uniweb system 环境检测（可选）

> **使用场景**：仅在需要连接开发服务器时使用（如代码生成、部署等开发流程）。纯设计类技能可跳过此步骤。

### 检测方法

读取 `~/.uniweb/uniweb-system.config`，检查是否包含 `SYSTEM_SERVER`：

> **⚠️ 安全约束**：该文件包含数据库密码、Redis密码、Nacos密码等生产凭据。**严禁**在对话中使用 `cat`、`head`、`tail` 等命令完整输出该文件内容。应使用 `source` 加载或 `grep`/`awk` 仅提取所需的非敏感变量（如 `SYSTEM_SERVER`），密码类字段一律不展示。

| 参数 | 格式要求 | 示例 |
|------|---------|------|
| `SYSTEM_SERVER` | 开发服务器IP或域名 | `192.168.88.21` |

| 检查结果 | 操作 |
|---------|------|
| `SYSTEM_SERVER` 已配置 | 继续当前技能 |
| 配置文件不存在 | 输出引导话术，暂停执行 |
| `SYSTEM_SERVER` 未配置 | 引导用户检查 `~/.uniweb/uniweb-system.config` |

### 引导话术

```
未检测到 uniweb system 开发环境配置信息。

请先阅读开发环境搭建说明：https://github.com/axeon/uw-system-init

请将已搭建的服务器 /root/.uniweb/uniweb-system.config 文件复制到本机当前用户的 ~/uniweb/ 目录下。

或使用以下命令先完成开发环境搭建：
  curl -fsSL https://raw.githubusercontent.com/axeon/uw-system-init/main/install.sh | sudo bash

最后，重新触发当前技能继续执行。
```
