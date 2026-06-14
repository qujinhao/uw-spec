# 管理端UniApp开发评审检查清单

> **源技能**：[220-admin-uni-dev/SKILL.md](../../220-admin-uni-dev/SKILL.md) — AI 原生开发，逐页面完整交付。

## 0. 编译与多端验证（源技能 → Phase 2 Step 9 + 完成标准）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| H5 编译 | `pnpm build:h5` 无编译错误 | Step 9 |
| 微信小程序编译 | `pnpm build:mp-weixin` 无编译错误 | Step 9 |
| **pnpm test** | **全绿。AI 原生要求一次通过，不存在 Red 骨架阶段** | Step 8 |
| any 类型 | `grep -rn ': any' src/` 结果为 0（排除 `@change`） | coding-principles.md |
| DataList 字段 | `grep -rn 'res\.data\?\.list\b' src/` 结果为 0 | 架构约定 |
| ref 双重调用 | `grep -rn 'ref<.*>(.*)(.*)' src/` 结果为 0 | coding-principles.md |
| v-for 无 key | `grep -rn 'v-for=' src/pages/ \| grep -v ':key='` 结果为 0 | coding-principles.md |
| 直接 uni.request | `grep -rn 'uni\.request(' src/pages/` 结果为 0 | 架构约定 |

## 1. README.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 页面总览 | 每个页面有名称、复杂度分类、涉及 API | Phase 1 |
| 角色权限映射 | root/ops/saas/mch × 页面访问矩阵 | Phase 1 |
| PRD 功能点映射 | 每个 PRD 功能点对应到模块和页面 | Phase 1 |
| 路由设计 | pages.json 页面路由配置完整 | Phase 1 |
| 字段一致性 | 表单字段 ↔ API Schema 字段对照表完整，字段名 camelCase | Phase 1 |
| 平台适配 | 微信小程序/H5/App 适配策略已确认 | Phase 1 |

## 2. TASKS.md 完整性（源技能 → Phase 1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 页面清单 | 每个页面标注简单/复杂分类 | Phase 1 |
| 进度状态 | 所有页面已标记完成 | Phase 1 |
| 页面卡片 | 每个页面含文件路径、PRD、API、类型、功能、交互、Store、复杂度、依赖 | Phase 1 |

## 3. 页面代码质量（源技能 → Phase 2 Step 2/3/5）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| **方法体完整实现** | **页面脚本直接包含完整 API 调用逻辑，无 TODO 标记，无空壳页面。发现空壳视为 Critical** | Step 2 + Step 5 |
| 角色路径移动 | 页面已从 `pages/` 移动到 `pages/{role}/{module}/`，导入路径已修正 | Step 3 |
| 字段一致 | 表单字段名与 API Schema 字段名一致（camelCase） | Step 1 |
| **DataList 规范** | **列表数据使用 `res.data?.results`，禁止 `res.data?.list`** | 架构约定 |
| 状态字段类型 | 状态/类型字段使用 `number` 值 | Step 1 |
| **API 调用规范** | **通过 `@/api/` 层调用，禁止直接 `uni.request`** | 架构约定 |
| 类型导入 | 从 `@/api/` 导入类型，页面内无重复类型定义 | Step 1 |
| 页面命名 | 页面 kebab-case，组件 PascalCase | 架构约定 |

## 4. 跨平台兼容（源技能 → Phase 2 Step 6）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| **条件编译** | **平台差异使用 `#ifdef MP-WEIXIN` / `#ifdef H5` / `#ifdef APP-PLUS` 处理，禁止运行时 `if (platform)` 判断** | Step 6 |
| 样式适配 | 使用 rpx（750rpx = 屏幕宽度），禁止微信小程序 px 硬编码 | Step 6 |
| API 兼容 | 无平台特定 API 硬编码（如 H5 调用 `uni.login`） | Step 6 |
| 功能降级 | 不支持平台有降级方案（如 H5 不支持扫码时隐藏入口） | Step 6 |
| 安全区 | 底部固定定位使用 `env(safe-area-inset-bottom)` | Step 6 |

**平台适配对照**：

| 适配项 | 微信小程序 | H5 | App |
|--------|-----------|-----|-----|
| 登录 | `uni.login({ provider: 'weixin' })` | 账号密码登录 | `plus.oauth.getServices()` |
| 扫码 | `uni.scanCode()` | 不支持→隐藏入口 | `uni.scanCode()` |
| 存储 | `uni.setStorageSync` | localStorage | `plus.io` |
| 样式 | rpx | px/rpx 均可 | px/rpx 均可 |

## 5. 交互规范（源技能 → Phase 2 Step 5 + 交互规范约定）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 下拉刷新 | `onPullDownRefresh` → 重置页码 → 请求 → `uni.stopPullDownRefresh()` | 交互规范约定 |
| 上拉加载 | `onReachBottom` → 追加数据 → `hasMore` 控制 | 交互规范约定 |
| 加载反馈 | `loading` ref 控制骨架屏/加载动画 | 交互规范约定 |
| 空状态 | 列表为空展示空状态组件 | 交互规范约定 |
| 错误处理 | `try/catch` + `uni.showToast` 错误提示 | 交互规范约定 |
| 表单校验 | 提交前逐项校验，`uni.showToast` 提示具体字段 | 交互规范约定 |
| 危险操作确认 | 删除等危险操作使用 `uni.showModal` 二次确认 | 交互规范约定 |
| 触摸交互 | 按钮点击区域≥44px，间距合理，点击态反馈 | md-design-spec.md |

## 6. 权限控制（源技能 → Phase 2 Step 5 + 架构约定）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| **按钮权限** | **`v-if="menuStore.hasPermission('xxx:add')"` 控制按钮显示** | Step 5 |
| **页面权限** | **`onLoad` 中检查 `menuStore.hasMenu(path)`，无权限则 `navigateBack`** | Step 5 |
| 数据权限 | API 自动按用户角色过滤，前端无需额外处理 | Step 5 |
| 角色覆盖 | root/ops/saas/mch 各角色页面路径与 README 映射一致 | Phase 1 |
| pages.json | 路由路径包含角色层级 `pages/{role}/{module}/{page}`，无 TabBar | Step 4 |
| 菜单动态加载 | 后端返回菜单权限列表，前端动态控制页面访问 | 架构约定 |

## 7. UniApp 技术栈合规（源技能 → 架构约定 + coding-principles.md）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| script setup | 必须使用组合式 API | 架构约定 |
| **类型安全** | **无 any 类型（框架限制除外）** | coding-principles.md |
| Pinia setup 风格 | `defineStore('name', () => { ... })`，State 用 ref，Getters 用 computed | 架构约定 |
| 状态管理 | 共享状态用 Pinia Store，禁止 `uni.$emit`/`uni.$on` 全局事件 | 架构约定 |
| 导航模式 | 导航栈模式，无 TabBar，顶部 navigationBar + 返回按钮 | 架构约定 |
| 编码原则 | 遵循 coding-principles.md 四条核心原则 | coding-principles.md |

## 8. 测试质量（源技能 → Phase 2 Step 8）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| composables 测试 | 核心业务 composables 有对应测试文件 | Step 8 |
| Store 测试 | Pinia Store 有状态变更测试 | Step 8 |
| 工具函数测试 | 工具函数有边界值测试 | Step 8 |
| **测试全绿** | **`pnpm test` 全部通过。AI 原生要求一次写完直接通过** | Step 8 |
| 覆盖率 | 核心业务行覆盖≥70% | Step 8 |
| **无 TODO 残留** | **`grep "// TODO:" src/` 结果为空** | 完成标准 |

## 9. PRD 覆盖度（源技能 → Phase 0/1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 功能点全覆盖 | 每个 PRD 功能点在 README 映射表中有对应页面 | Phase 0 + Phase 1 |
| 页面全覆盖 | README 映射表中的页面在 `src/pages/` 中有实现 | Phase 1 |
| 角色覆盖 | README 权限映射表中的角色在页面路径中体现 | Phase 1 |

## 10. 安全性（源技能 → Phase 2 Step 5 + 架构约定）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| Token 安全 | Token 安全存储（`uni.setStorageSync` + 加密），自动刷新 | 架构约定 |
| 输入校验 | 表单输入有前端校验 | Step 5 |
| 敏感数据 | 密码等敏感信息不明文展示 | 安全规范 |

## 11. 性能优化（源技能 → Phase 2 Step 9）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 分包加载 | 主包≤2MB | Step 9 |
| 图片优化 | 使用压缩/懒加载 | Step 9 |
| 列表渲染 | 分页加载，页面销毁时资源释放 | Step 9 |
