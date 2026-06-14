---
name: 220-guest-uni-init
description: 消费者端UniApp项目初始化（UniApp+Vue3）。当创建消费者端跨平台项目时触发：(1)从模板解压项目结构, (2)全文替换模板关键字为项目名, (3)验证项目结构完整性。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "1.1.0"
---

# 移动端项目初始化

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 项目初始化 | `js-developer` |
| 协作 | 架构确认 | `system-architect` |

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
即将执行 UniApp 移动端项目初始化：
- 项目名: {project-name}
- 前端项目名: {project-name}-guest-uni
- 角色: guest
- 输出目录: PROJECT_ROOT/frontend/{project-name}-guest-uni/

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
# 初始化 guest-uni（默认角色）
bash scripts/init.sh /Users/user/project force

# 初始化 guest-uni，跳过已存在文件
bash scripts/init.sh /Users/user/project skip
```

**脚本输出说明**：
- `✓` 表示通过
- `⚠` 表示警告
- `ERROR` 表示错误，会终止执行

### 步骤4: 安装后配置

脚本完成后，**自动执行**以下配置：

| 配置项 | 操作 | 说明 |
|--------|------|------|
| vitest 配置 | 创建 `vitest.config.ts` | 预配置 happy-dom、alias、coverage 排除列表 |
| 测试目录 | 创建 `src/__tests__/` | 预创建测试目录 |
| TabBar 图标 | 创建 `src/static/tabbar/` | 放入 8 个占位 PNG 图标（4 tab × normal/active） |

**vitest.config.ts 模板**：
```typescript
import { defineConfig } from 'vitest/config'
import path from 'path'

export default defineConfig({
  test: {
    environment: 'happy-dom',
    globals: true,
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.{ts,vue}'],
      exclude: [
        'src/**/*.spec.ts',
        'src/**/*.test.ts',
        'src/types/**',
        'src/**/*.d.ts',
        'src/api/**',
        'src/components/**',
        'src/m-widgets/**',
        'src/mall-widgets/**',
        'src/schema/**',
        'src/template/**',
        'src/product/**',
        'src/poi/**',
        'src/packages/**',
        'src/pages/**',
        'src/user/**',
        'src/i18n/**',
        'src/config/**',
        'src/utils/areaInfo.ts',
        'src/utils/enumeration.ts',
        'src/utils/global.ts',
        'src/utils/loginUserInfo.ts',
        'src/utils/eventHandler.ts',
        'src/utils/tool.ts',
        'src/utils/coupon/**',
        'src/utils/PubSub/**',
        'src/App.vue',
        'src/main.ts',
        'src/store/index.ts',
        'src/store/main.ts'
      ]
    }
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src')
    }
  }
})
```

## 模板要求

模板 zip 必须满足以下条件：

### 必须包含

| 目录/文件 | 说明 |
|-----------|------|
| `src/api/request/` | 网络请求封装 |
| `src/api/type/API_TYPE.ts` | ResponseData、DataList 类型定义 |
| `src/store/user.ts` | 用户状态管理（仅依赖基础模块） |
| `src/utils/` | 工具函数（auth、storage、tokenManager） |
| `src/config/` | 配置文件 |
| `pages.json` | 页面路由配置（仅含模板基础页面） |
| `package.json` | 依赖配置（含 vitest@3.x） |

### 必须排除

| 目录 | 原因 |
|------|------|
| `src/product/` | 电商专属，非通用 |
| `src/poi/` | 景区专属，非通用 |
| `src/packages/coupon/` | 优惠券专属 |
| `src/packages/view/` | 景区详情专属 |
| `src/packages/setting/addressManage.vue` | 地址管理专属 |
| `src/template/` | 页面模板引擎，非通用 |
| `src/schema/` | 搜索组件，电商专属 |
| `src/user/orderDetail/` | 订单专属 |
| `src/user/orderList/` | 订单专属 |

> 如果模板 zip 暂时无法精简，init 脚本应在步骤 4 后自动执行清理，删除上述无关目录。

## 输出要求

**输出位置**: `PROJECT_ROOT/frontend/{project-name}-{role}-uni/` 目录

**包含内容**: 从模板解压并替换后的完整项目结构

**目录结构**:
```
项目根目录/
├── project-info.md
└── PROJECT_ROOT/frontend/
    └── {project-name}-{role}-uni/
        ├── src/
        │   ├── api/
        │   │   ├── request/          # 网络请求封装
        │   │   └── type/             # 类型定义
        │   ├── store/                 # Pinia 状态管理
        │   ├── utils/                 # 工具函数
        │   ├── config/                # 配置
        │   ├── static/tabbar/         # TabBar 图标
        │   ├── __tests__/             # 测试目录
        │   └── pages/                 # 基础页面
        ├── vitest.config.ts           # 测试配置
        ├── package.json
        ├── tsconfig.json
        └── vite.config.ts
```

**命名示例**（假设项目名为 `my-shop`）：
| 角色 | 前端项目名 | 目录 |
|------|-----------|------|
| guest | my-shop-guest-uni | PROJECT_ROOT/frontend/my-shop-guest-uni/ |

## 下一步

初始化完成后，提示用户进入 **`220-guest-uni-gencode`** 进行移动端代码生成（从后端Swagger生成api/router/page/i18n）。

**流程位置**：`220-guest-uni-init` → **`220-guest-uni-gencode`** → `220-guest-uni-dev` (+ `221-guest-uni-dev-review`)

## 参考

- [初始化脚本](scripts/init.sh) - 自动化初始化脚本
- [UniApp模板](assets/guest-uni-template.zip) - UniApp项目模板
