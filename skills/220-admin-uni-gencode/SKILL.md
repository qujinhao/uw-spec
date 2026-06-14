---
name: 220-admin-uni-gencode
description: 管理端UniApp代码生成（UniApp + Vue3）。当需要为管理端跨平台项目生成或更新代码时触发：(1)首次生成TypeScript接口定义和API调用, (2)库表变动后增量更新代码并生成变更报告, (3)备份旧文件供后续裁剪恢复。适用于root/ops/saas/mch角色。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.0.0"
---

# UniApp移动端代码生成

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md) **第一步、第二步**。**第三步**（uniweb system 环境检测）：从 `~/.uniweb/uniweb-system.config` 读取服务器配置。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 代码生成 | `js-developer` |


## 初始化流程

**执行前必须询问用户确认**。

### 步骤1: 扫描可用移动端项目

**目标目录**：直接使用当前项目根目录（包含 `PROJECT_ROOT/project-info.md` 的目录）。

从 `PROJECT_ROOT/project-info.md` 读取 `project-name`，扫描所有 Admin 系 UniApp 移动端项目：

```bash
PN=$(grep 'project-name' project-info.md | head -1 | awk '{print $2}'); ls -1d PROJECT_ROOT/frontend/${PN}-admin-uni/ PROJECT_ROOT/frontend/${PN}-saas-uni/ PROJECT_ROOT/frontend/${PN}-mch-uni/ PROJECT_ROOT/frontend/${PN}-root-uni/ PROJECT_ROOT/frontend/${PN}-ops-uni/ 2>/dev/null
```

**情况处理**：

| 情况 | 操作 |
|------|------|
| 有移动端项目 | 使用 `AskUserQuestion` 让用户选择目标项目 |
| 没有移动端项目 | 报错，提示先执行 220-admin-uni-init |

### 步骤2: 询问用户参数

```
AskUserQuestion({
  questions: [
    {
      question: "要为哪个Admin UniApp移动端项目生成代码？",
      header: "目标移动端项目",
      options: [
        { label: "{实际扫描到的项目名}", description: "自动查找可用的Admin UniApp项目" },
        { label: "手动输入", description: "手动指定Admin UniApp项目目录名" }
      ],
      multiSelect: false
    },
    {
      question: "选择API文档对应的类型？",
      header: "API类型",
      options: [
        { label: "root", description: "ROOT后台" },
        { label: "admin", description: "总后台" },
        { label: "saas", description: "SAAS管理" },
        { label: "mch", description: "SAAS商户" }
      ],
      multiSelect: false
    },
    {
      question: "需要生成哪些类型？",
      header: "生成类型",
      options: [
        { label: "api", description: "API调用" },
        { label: "router", description: "路由" },
        { label: "page", description: "页面" },
        { label: "i18n", description: "国际化" }
      ],
      multiSelect: true
    }
  ]
})
```

**Swagger地址构建规则**：
- 从 `project-info.md` 读取 `project-name`
- 从 `~/.uniweb/uniweb-system.config` 读取 `SYSTEM_SERVER`
- 选择角色时：构建 `http://{SYSTEM_SERVER}/{project-name}-app/v3/api-docs/{role}Api`
  - 例如选择 `admin` → `http://{SYSTEM_SERVER}/{project-name}-app/v3/api-docs/adminApi`
  - 例如选择 `mch` → `http://{SYSTEM_SERVER}/{project-name}-app/v3/api-docs/mchApi`
- 选择"自定义地址"时：让用户输入完整的 Swagger URL

### 步骤3: 用户确认

**必须**向用户展示以下信息并等待确认：

```
即将执行 UniApp 移动端代码生成：
- 项目根目录: {当前项目根目录}
- 目标移动端项目: {用户选择的项目名}
- Swagger地址: {用户输入的地址}
- 生成类型: {用户选择的类型}

确认执行吗？
```

用户确认后，再执行脚本。

### 步骤4: 执行脚本

用户确认后，执行命令（确保在技能目录下执行）：
```bash
bash scripts/gencode.sh [目标目录] [Swagger地址] [生成类型] [前端项目名]
```

**参数说明**：

| 参数 | 说明 | 是否必填 | 默认值 |
|------|------|----------|--------|
| 目标目录 | 项目根目录（包含 `PROJECT_ROOT/project-info.md`） | 是 | 当前目录 |
| Swagger地址 | Swagger API 文档地址 | **是** | - |
| 生成类型 | `api,router,page,i18n` 的组合 | 否 | `api,router,page,i18n` |
| 前端项目名 | 指定具体的移动端项目目录名 | 否 | 自动查找 |

**Swagger地址格式**：
- 标准格式：`http://{SYSTEM_SERVER}/{project-name}-app/v3/api-docs/{role}Api`
- 示例：`http://192.168.88.21/my-shop-app/v3/api-docs/adminApi`

**执行示例**：

```bash
# 自动查找唯一的移动端项目，使用指定 Swagger 地址
bash scripts/gencode.sh /Users/user/project "http://192.168.88.21/my-shop-app/v3/api-docs/adminApi"

# 指定 Swagger 地址和生成类型
bash scripts/gencode.sh /Users/user/project "http://192.168.88.21/my-shop-app/v3/api-docs/adminApi" "page,i18n"

# 指定移动端项目名（多个项目时）
bash scripts/gencode.sh /Users/user/project "http://192.168.88.21/my-shop-app/v3/api-docs/mchApi" "api,page" "my-shop-mch-uni"
```

**脚本输出说明**：
- `✓` 表示通过
- `⚠` 表示警告
- `ERROR` 表示错误，会终止执行

## 生成流程

脚本自动完成：
1. 登录 `uw-auth-center` 获取访问 token
2. 调用 `uw-code-center` API 下载 UniApp 代码生成文件（zip），通过 `swaggerUrl` 参数指定后端 API 文档地址
3. 解压代码文件
4. 根据生成类型选择处理：
   - `api` - API 调用模块
   - `router` - 路由配置
   - `page` - 页面组件（.vue/.ts）
   - `i18n` - 国际化翻译文件（.json）
5. 替换模块路径为项目实际路径
6. 将文件移动到前端项目对应目录
7. 执行 TypeScript 编译验证

## 配置项

**从 project-info.md 读取**：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `project-name` | 项目英文名（短横线分隔） | `my-shop` |

**从 ~/.uniweb/uniweb-system.config 读取**：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `SYSTEM_SERVER` | 开发服务器地址 | `192.168.88.21` |
| `MSC_OPS_PASSWORD` | ops 用户密码 | `your_password` |

**Swagger地址**:
- **必填参数**，执行时必须提供
- 标准格式：`http://{SYSTEM_SERVER}/{project-name}-app/v3/api-docs/{role}Api`
- 地址会被自动 URL 编码后传递给代码生成服务

## 输出结构

```
项目根目录/
├── project-info.md
└── PROJECT_ROOT/frontend/
    └── {project-name}-{role}-uni/           # 例如: my-shop-admin-uni
        ├── .gencode-backup/              # 增量更新时自动创建
        │   └── {timestamp}/
        │       ├── api/
        │       ├── router/
        │       ├── page/
        │       └── i18n/
        ├── .gencode-diff.md              # 变更报告
        └── src/
            ├── api/                      # API 调用模块
            │   └── {module}/             # 按模块子目录
            │       └── index.ts
            ├── router/                   # 路由配置
            │   └── {module}/
            │       └── index.ts
            ├── page/                     # 页面组件
            │   └── {module}/
            │       ├── index.vue
            │       └── detail.vue
            └── i18n/                     # 国际化翻译
                ├── zh-CN/
                │   └── {module}.json
                └── en-US/
                    └── {module}.json
```

**目录查找规则**：
脚本从 `project-info.md` 读取 `project-name`，查找 `PROJECT_ROOT/frontend/{project-name}-(root|ops|admin|saas|mch)-uni` 目录（如 `my-shop-admin-uni`、`my-shop-saas-uni`），找到的第一个匹配目录即为目标前端项目。

### 模块目录规则

**目录层级**：`api/{module}/`、`router/{module}/`、`page/{module}/`、`i18n/{lang}/`

| 层级 | 来源 | 示例 |
|------|------|------|
| 模块 | 代码生成器 zip 中已有的子目录 | `product/`、`order/`、`guest/` |
| 文件 | 代码生成器产出 | `index.ts`、`index.vue`、`zh-CN.json` |

## 下一步

代码生成完成后，提示用户进入 **`220-admin-uni-dev`** 进行移动端开发（裁剪页面 + 配置路由）。

**流程位置**：`220-admin-uni-init` → `220-admin-uni-gencode` → **`220-admin-uni-dev`** (+ `221-admin-uni-dev-review`)

## 参考

- [代码生成脚本](scripts/gencode.sh) - 支持 `--update` 增量更新模式
