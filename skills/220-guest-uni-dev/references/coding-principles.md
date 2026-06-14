# Guest UniApp 编码原则

> version: "1.1.0"
> 被 220-guest-uni-dev、221-guest-uni-dev-review、620-feature-dev、720-bugfix-dev 共同引用。
> 本文件是编码规范的**唯一权威来源**，其他文件不再重复列举规则。

## 四条核心原则

### 原则一：集中管理（Single Source of Truth）

**判断标准**：如果一个配置在多个地方可能被使用，或者属于字典/枚举/映射类数据，它应该集中管理。

| 集中到哪里 | 管什么 | 格式 |
|-----------|--------|------|
| `composables/` | 组合函数（分享、通用逻辑） | `useXxx()` 函数 |
| `store/` | 全局客户端状态（用户、应用配置） | Pinia setup 风格 |
| `components/` | 通用 UI 组件 | 可复用组件 |
| `utils/` | 工具函数（request、auth、format） | 纯函数 |
| `api/` | API 调用封装 | 代码生成器产出，只读不改 |

**具体做法**：
- 页面内**禁止**定义重复的类型接口，应从 `@/api/` 的类型中导入
- 相同的数据获取逻辑抽取到 `composables/useXxx.ts`，禁止多页面重复请求代码
- 跨页面状态统一用 `store/`
- API 调用只通过 `api/` 层，禁止页面内直接 `uni.request`
- 分享逻辑统一封装到 `composables/useShare.ts`

### 原则二：类型安全（No Escape Hatches）

**判断标准**：如果 TypeScript 编译器无法推断类型，说明代码有问题。

| 禁止 | 替代方案 |
|------|---------|
| `any` 类型 | 定义具体类型或使用泛型 |
| 无类型 Props | 使用 `defineProps<T>()` 泛型风格 |
| 无类型 Emits | 使用 `defineEmits<T>()` 泛型风格 |
| 隐式 any 参数 | 使用具体的接口类型 |
| `@ts-ignore` | 修正类型定义 |

> **UniApp 框架限制**：`switch` 组件的 `@change` 事件回调参数类型在 UniApp 中为 `any`，此为框架限制，可保留。

### 原则三：项目一致性（Use What Exists）

**判断标准**：在编写任何代码前，先检查项目中是否已有相同或类似功能的实现。

| 场景 | 做法 |
|------|------|
| 网络请求 | 使用 `api/request/` 封装，禁止直接 `uni.request` |
| 导航跳转 | Tab 切换用 `uni.switchTab`，详情页用 `uni.navigateTo`，登录覆盖用 `uni.redirectTo` |
| 列表数据 | 统一使用 `res.data?.results`（非 `res.data?.list`） |
| 表单校验 | 前端提交前校验，不等后端返回 |
| Toast 提示 | 使用 `uni.showToast`，统一格式 |
| 分享功能 | 微信小程序配置 `onShareAppMessage`/`onShareTimeline`，App 用 `uni.share` |
| 页面生命周期 | 页面级用 `onLoad`/`onShow`，组件级用 `onMounted`/`onUnmounted` |

### 原则四：代码可读性（Self-Documenting Code）

**判断标准**：一个新团队成员能否在不看注释的情况下理解代码意图。

| 禁止 | 替代方案 |
|------|---------|
| v-for 单字母变量 `v-for="i in"` | 描述性名称 `v-for="item in"` |
| 数组方法单字母参数 `(a, b) =>` | `(item, index) =>` |
| 硬编码魔法数字/字符串 | 提取为命名常量 |
| 嵌套三元 `a ? b : c ? d : e` | computed 属性或方法 |
| 超长单文件组件 | 拆分为子组件和 composables |

## 数据结构规范

> 所有 API 响应遵循统一的包装类型，解析时必须按以下规则。

| API 类型 | 返回类型 | 取值方式 |
|---------|---------|---------|
| 列表 API | `ResponseData<DataList<T>>` | `res.data?.results` → `T[]` |
| 实体 API | `ResponseData<T>` | `res.data` → `T` |
| 无返回值 API | `ResponseData<void>` | 检查 `res.state === 'success'` |

**禁止使用**：`res.data?.list`（DataList 的字段是 `results`）

## 自动化验证

开发完成后，执行以下命令验证编码规范：

```bash
cd frontend/{project-name}-guest-uni

# 1. any 类型检查（应为 0，框架限制的 switch 事件除外）
grep -rn ': any' src/ --include="*.vue" --include="*.ts" | grep -v 'node_modules' | grep -v '@change' | wc -l

# 2. 直接 uni.request 调用（应为 0，应使用封装的 request）
grep -rn 'uni\.request(' src/pages/ --include="*.vue" | wc -l

# 3. DataList 字段错误（应为 0，禁止用 list 用 results）
grep -rn 'res\.data\?\.list\b' src/ --include="*.vue" --include="*.ts" | wc -l

# 4. ref 双重调用（应为 0，运行时必崩）
grep -rn 'ref<.*>(.*)(.*)' src/ --include="*.vue" --include="*.ts" | wc -l

# 5. v-for 无 key（应为 0）
grep -rn 'v-for=' src/pages/ --include="*.vue" | grep -v ':key=' | wc -l

# 6. TypeScript 编译检查
pnpm vue-tsc --noEmit

# 7. 多端编译验证
pnpm build:h5
pnpm build:mp-weixin
```

## 项目基础架构速查

### 目录结构
```
src/pages/{module}/              # 消费者端不分角色目录
src/components/                # 通用组件
src/composables/               # 组合函数
src/store/                     # Pinia 状态管理
src/api/                       # API 调用（代码生成器产出）
src/utils/                     # 工具函数
pages.json                     # 页面路由配置
```

### 导航模式
- **TabBar 模式**：底部固定 Tab 导航（首页/分类/发现/我的）
- **Tab 切换**：`uni.switchTab`
- **详情页**：`uni.navigateTo`（栈式导航）
- **登录覆盖**：`uni.redirectTo`
