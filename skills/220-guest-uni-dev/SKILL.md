---
name: 220-guest-uni-dev
description: 消费者端UniApp移动端开发（AI原生，逐页面完整交付）。当需要基于PRD进行消费者端移动端开发时触发：(1)确认页面清单与TabBar配置, (2)编写架构蓝图README.md, (3)逐页面完整交付（创建页面+pages.json+API对接+平台适配+编译验证）。当用户提及消费者小程序、电商App、内容App、UniApp前端、跨平台应用开发时使用此技能。适用于guest（消费者）角色 ⚠️【强制】完成后必须调用 221-guest-uni-dev-review，未通过前禁止声称完成。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# UniApp移动端开发（AI 原生）

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 技术栈

| 技术栈 | 版本 | 用途 |
|--------|------|------|
| UniApp | 最新 | 跨平台框架 |
| Vue 3 | 3.x | 组合式 API |
| TypeScript | 5.x | 类型安全 |
| Pinia | 2.x | 状态管理 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 页面开发 + API对接 + 编译验证（一次完成） | `js-developer` |
| 协作 | 业务需求确认 | `product-manager` |

## 输入

| 输入项 | 来源路径 | 说明 |
|--------|----------|------|
| PRD | `PROJECT_ROOT/requirement/prds/*` | 产品需求文档，功能模块及页面需求 |
| API定义 | `PROJECT_ROOT/frontend/{project-name}-guest-uni/src/api/` | gencode 生成的 API 调用函数和类型定义 |
| 前端项目 | `PROJECT_ROOT/frontend/{project-name}-guest-uni/` | init + gencode 生成的代码 |

## 前置条件

| 前置技能 | 说明 |
|---------|------|
| [220-guest-uni-init](../220-guest-uni-init/SKILL.md) | 移动端项目已通过模板初始化 |
| [220-guest-uni-gencode](../220-guest-uni-gencode/SKILL.md) | api/types 已由代码生成器生成 |

## 架构约定速查表

### 页面路径约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `src/pages/{module}/{page}.vue` | `src/pages/guest/{module}/{page}.vue`（不需要角色目录） |
| 模块名 kebab-case：`user-profile` | 模块名 PascalCase：`UserProfile` |
| 页面名 kebab-case：`order-detail` | 页面名含角色前缀：`guest-order-detail` |

### TabBar 配置约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 4 Tab：首页/分类/发现/我的 | 3 Tab 或 5 Tab |
| Tab 页面使用 `uni.switchTab()` | Tab 页面使用 `uni.navigateTo()` |
| TabBar 图标使用 `static/tabbar/` 目录 | 图标放 `src/assets/` 目录 |

### pages.json 配置约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| TabBar 页面在 `tabBar.list` 中配置 | TabBar 页面仅在 `pages` 中配置 |
| 首页路径为 `pages/index/index` | 首页路径为 `pages/home/index` |
| 每个页面配置 `navigationBarTitleText` | 页面缺少导航栏标题 |

### 字段一致性约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 表单字段名与 API DTO 字段名一致（camelCase） | 自行命名表单字段 |
| 列表项名与 API 返回字段名一致 | 前端字段名与后端不同 |
| 使用 label 显示中文，字段名保持英文 | 字段名直接用中文 |

### DataList 字段约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `res.data?.results`（列表数据） | `res.data?.list` |
| `res.data?.total`（分页总数） | `res.data?.count` |
| `res.data!`（实体数据） | `res.data?.data` |

### 导航方式约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| Tab 切换：`uni.switchTab()` | Tab 切换：`uni.navigateTo()` |
| 详情页栈式：`uni.navigateTo()` | 详情页：`uni.redirectTo()` |
| 登录覆盖：`uni.redirectTo()` | 登录：`uni.navigateTo()`（会保留历史） |
| 返回：`uni.navigateBack()` | 返回：`uni.redirectTo()` |

### 分享能力约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 微信小程序：`onShareAppMessage` + `onShareTimeline` | 仅配置 `onShareAppMessage` |
| App 端：`uni.share()` | App 端无分享能力 |
| 分享参数包含 path + imageUrl + title | 分享参数缺少 path |

### 平台适配约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 条件编译：`#ifdef MP-WEIXIN` / `#ifdef H5` | 运行时 `uni.getSystemInfoSync()` 判断平台 |
| 安全区域：`safe-area-inset-bottom` | 固定 padding-bottom 值 |
| rpx 单位布局 | px 单位布局 |

> 完整开发规范见 [md-dev-standards.md](references/md-dev-standards.md)
> 编码原则见 [coding-principles.md](references/coding-principles.md)
> 设计规范见 [md-design-spec.md](references/md-design-spec.md)

## ResponseData\<T\> 解析规范

```
列表 API 返回：ResponseData<DataList<T>>
  - 列表数据：res.data?.results     → 类型 T[]
  - 分页总数：res.data?.total

实体 API 返回：ResponseData<T>
  - 实体数据：res.data              → 类型 T
```

```typescript
const res = await guestQuestionList({ param: { $pg: 1, $rn: 20 } })
const list: PostQuestion[] = res.data?.results || []

const res = await guestQuestionLoad({ id: 1 })
const detail: PostQuestion = res.data!
```

> **禁止使用 `res.data?.list`**，DataList 的数组字段固定为 `results`。

## 工作流程

### Phase 0: 需求确认

确认聚焦业务层面。消费者端（guest）只有一个角色，跳过角色权限映射。

| 确认项 | 启发式问题 |
|--------|-----------|
| 页面清单 + 复杂度分类 | "根据PRD，识别到N个页面[列出]，是否有遗漏？" |
| TabBar 配置 | "确认4个Tab页面：首页/分类/发现/我的，是否需要调整？" |
| 平台适配 | "需要支持哪些平台？默认微信小程序+H5" |
| 定制页面 | "除标准CRUD页面外，还有哪些定制页面？" |

### Phase 1: 架构蓝图

**输入**：PRD 文档 + Phase 0 确认结果

**输出两个文件**：

| 文件 | 定位 | 内容 |
|------|------|------|
| `README.md` | 架构蓝图（给人+AI 读） | 页面总览、TabBar配置、PRD功能点映射、路由设计、字段一致性检查表、平台适配策略 |
| `TASKS.md` | 进度清单（仅追踪） | 并行分组、页面清单（简单/复杂分类）、状态复选框 |

**README.md 必须包含的章节**：

| 章节 | 内容 | 必要性 |
|------|------|--------|
| 页面总览 | 页面清单、复杂度分类、涉及API | 必须 |
| TabBar 配置 | Tab 定义、图标、页面路径 | 必须 |
| PRD功能点映射 | 功能点 → 模块 → 页面的映射表 | 必须 |
| 路由设计 | pages.json 页面路由配置 | 必须 |
| 字段一致性检查 | 表单字段 ↔ API Schema字段对照表 | 必须 |
| 平台适配 | 微信小程序/H5/App 适配策略 | 必须 |
| 组件清单 | 复用组件列表 | 按需 |

模板见 [references/design-templates.md](references/design-templates.md)

### Phase 2: 逐页面完整交付

按 TASKS.md 的分组顺序，**每组内可并行，组间串行**。每个页面执行以下步骤：

#### Step 1: 加载上下文

| 操作 | 说明 |
|------|------|
| 读 PRD 功能点 | 确认页面功能需求和交互要求 |
| 读 API 类型定义 | 从 `src/api/` 确认可用的 API 函数和类型 |
| 读 README.md | 确认路由、TabBar、字段映射 |

#### Step 2: 创建页面

> 基于 gencode 产出的 API 类型定义，按业务需求创建页面。

| 策略 | 条件 | 操作 |
|------|------|------|
| 裁剪 gencode 页面 | gencode 生成了对应页面且质量可接受 | 调整字段、样式、交互 |
| 基于类型新建 | gencode 未生成页面，或生成页面质量差 | 导入 gencode API 类型和函数，从零创建 |

**消费者端页面组织**：所有页面放在 `src/pages/{module}/` 下，不按角色分目录（guest 端只有一个角色）。

**每个页面必须完整包含**：

| 内容 | 说明 |
|------|------|
| 模板（template） | 完整 UI 结构，含条件编译的平台适配代码 |
| 逻辑（script setup） | 完整交互逻辑 + API 调用 + 状态管理 + 分享配置 |
| 样式（style scoped） | 完整样式，rpx 单位，安全区域适配 |

代码模板见 [references/code-templates.md](references/code-templates.md)

#### Step 3: 配置路由

| 内容 | 说明 |
|------|------|
| 页面路径 | 在 `pages.json` 中添加 `pages/{module}/{page}` |
| 导航栏 | 配置 `navigationBarTitleText` |
| TabBar | TabBar 页面在 `tabBar.list` 中配置（4 Tab：首页/分类/发现/我的） |

#### Step 4: 字段一致性检查

| 检查项 | 要求 |
|--------|------|
| 表单字段名 | 与后端 DTO 字段名一致（camelCase） |
| 列表项名 | 与后端返回字段名一致 |
| 显示文本 | 使用 label 显示中文，字段名保持英文 |

#### Step 5: 平台适配

| 平台 | 适配内容 |
|------|---------|
| 微信小程序 | `onShareAppMessage` + `onShareTimeline`、安全区域、条件编译 |
| H5 | 响应式布局、浏览器 API 兼容 |
| App | `uni.share()`、原生组件适配 |

> 多端适配规范详见 [md-dev-standards.md](references/md-dev-standards.md)

#### Step 6: 测试驱动开发（Red-Green 内部循环）

> **AI 原生 TDD**：内部自动执行 Red-Green 循环，用户只看到最终通过的结果。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)。

**6.1 Red 阶段**：
- 为 composable/Store/工具函数编写测试代码
- 执行 `pnpm vitest run tests/composables/useXxx.spec.ts` → **确认测试失败**
- ⚠️ 如果测试意外通过 → 说明断言不够严格，需加强

**6.2 Green 阶段**：
- 编写实现代码
- 执行 `pnpm vitest run tests/composables/useXxx.spec.ts` → **确认测试通过**

**6.3 Refactor 阶段**（按需）：
- 优化代码结构
- 执行 `pnpm vitest run` → 确认仍然通过

| 测试对象 | 测试内容 | 文件位置 |
|---------|---------|---------|
| composables | 业务逻辑计算、数据转换 | `tests/composables/useXxx.spec.ts` |
| Store | 状态变更、异步 action | `tests/store/xxx.spec.ts` |
| 工具函数 | 纯函数输入输出 | `tests/utils/xxx.spec.ts` |

| ❌ 不测试 | ✅ 测试 |
|----------|--------|
| 页面组件渲染 | composable 业务逻辑 |
| UI 样式 | Store 状态变更 |
| 框架 API | 工具函数边界值 |

#### Step 7: 编译验证

| 检查项 | 命令 |
|--------|------|
| H5 编译通过 | `pnpm build:h5` |
| 微信小程序编译通过 | `pnpm build:mp-weixin` |
| 无 ref 双重调用 | `grep -rn 'ref<.*>(.*)(.*)' src/ --include="*.vue" --include="*.ts"` |
| 无 DataList 字段错误 | `grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts"` |

**全部通过后**，在 TASKS.md 中标记该页面为已完成，进入下一个页面。

## 完成标准

- [ ] README.md 覆盖所有页面和 PRD 功能点映射
- [ ] TASKS.md 包含并行分组，所有页面已标记完成
- [ ] 所有 PRD 功能点都有对应页面
- [ ] 表单字段名与 API Schema 字段名一致（camelCase）
- [ ] 列表数据使用 `res.data?.results`（非 `res.data?.list`）
- [ ] pages.json 路由配置正确，TabBar 已配置（4 Tab）
- [ ] H5 和微信小程序编译通过
- [ ] 无 `ref<...>(null)(null)` 双重调用
- [ ] 微信小程序分享能力已配置（`onShareAppMessage` + `onShareTimeline`）
- [ ] 平台适配代码使用条件编译（`#ifdef`）

## ⚠️ 完成验证（强制，全自动执行）

1. **强制执行编译验证**（Phase 2 Step 6 的所有检查项）
2. **强制调用** `221-guest-uni-dev-review`
3. 不通过（< 95）→ 自动修复 → 重新评审（最多 5 轮）
4. 通过（≥ 95）→ 向用户报告最终结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [UniApp 开发规范](references/md-dev-standards.md) - Vue3+TS 多端开发规范
- [设计模板](references/design-templates.md) - README页面清单 + TASKS.md模板
- [代码模板](references/code-templates.md) - 页面组件代码模板
- [移动端开发评审技能](../221-guest-uni-dev-review/SKILL.md)
