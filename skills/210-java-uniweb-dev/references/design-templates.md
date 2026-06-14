# 设计模板

> 包含 README.md 总体设计模板和 TASKS.md 开发任务分工模板。代码模板见 [uniweb/code-templates.md](uniweb/code-templates.md)。

---

## 1. README.md 总体设计模板

```markdown
# {项目名称}

## 模块总览

| 模块名 | 说明 | 复杂度 | 代码策略 | 涉及实体 | 父子关系 |
|--------|------|--------|---------|---------|---------|
| {module} | {描述} | 简单/复杂 | 裁剪生成代码 / 新建Helper | {Entity列表} | - |
| {orderModule} | {描述} | 复杂 | 联查listEx / 懒加载子集Controller | {ParentEntity}, {ChildEntity} | {ParentEntity} 1:N {ChildEntity}（fk: {fk_column}） |

> **父子关系列**：标注 1:N 关系的父表、子表和外键字段。AI 根据此列自动选择查询方案（见 dev-standards.md「父子表查询方案」）。

> **多语言标注**：涉及实体列中标注 `_lang` 表和需要翻译的字段。AI 根据此列自动生成 `listLang`/`loadLang` 接口（见 dev-standards.md「多语言数据查询方案」）。

## 模块依赖关系

​```mermaid
graph TD
    A[模块A] --> B[模块B]
    A --> C[模块C]
    B --> D[模块D]
​```

依赖规则：禁止循环依赖，依赖方向只能从上层指向下层。

## PRD 功能点映射

| PRD功能点 | 模块 | 接口 | 说明 |
|-----------|------|------|------|
| {功能1} | {模块A} | POST /{role}/{module}/save | 新增{资源} |
| {功能2} | {模块B} | GET /{role}/{module}/list | 查询{资源}列表 |
| {订单列表含明细} | {OrderModule} | GET /{role}/{module}/listEx | 父子表联查列表（listEx方案） |
| {订单明细按需} | {OrderModule} | GET /{role}/{module}/{child}/list | 子集懒加载列表（独立Controller） |
| {商品列表多语言} | {ProductModule} | GET /{role}/{module}/listLang, GET /{role}/{module}/loadLang | 多语言列表+详情（LEFT JOIN _lang + COALESCE降级） |

## 角色权限映射

| 角色 | 模块A | 模块B | 模块C |
|------|-------|-------|-------|
| SAAS | R/W | R | - |
| MCH | R | R/W | R/W |
| ADMIN | R/W | R/W | R/W |
| ROOT | R/W | R/W | R/W |

R=只读（list/detail），W=写入（save/update/delete/enable/disable）

## 状态机设计

### {有状态实体} 状态流转

​```mermaid
stateDiagram-v2
    [*] --> 草稿
    草稿 --> 已提交: submit
    已提交 --> 已审核: approve
    已提交 --> 已驳回: reject
    已驳回 --> 草稿: edit
    已审核 --> [*]
​```

| 状态 | 说明 | 允许操作 |
|------|------|---------|
| 草稿 | 初始状态 | 编辑、提交、删除 |
| 已提交 | 待审核 | 撤回 |
| 已审核 | 审核通过 | - |
| 已驳回 | 审核驳回 | 编辑、重新提交 |

## 全局缓存策略

### 缓存组件选型

| 组件 | 适用场景 | 本项目使用 |
|------|---------|-----------|
| FusionCache | 高频读 + 需要本地加速 | 详情查询、配置数据 |
| GlobalCache | 中频读 + 不占JVM内存 | 列表缓存、计数器 |
| GlobalLocker | 分布式锁 | 订单处理、库存扣减 |

### Key 命名规范

```
{服务名}:{业务标识}:{实体ID}
```

以 Class 作为 cacheName，FusionCache/GlobalCache 自动管理 Key 前缀。

### 缓存场景

| 缓存对象 | 组件 | 本地缓存 | 过期时间 | 更新机制 |
|---------|------|---------|---------|---------|
| {对象A}详情 | FusionCache | 500条 | 30min | 写后失效 invalidate |
| {对象B}计数 | GlobalCache | - | 10min | 写后失效 delete |

### FusionCache 配置要求

- localCacheMaxNum：按数据量设定，单实体缓存 500-1000
- cacheExpireMillis：按变更频率设定（30min/1h/24h）
- Caffeine 不设过期时间（性能劣化200倍），仅设 Redis 过期时间
- Kryo 序列化必须使用具体实现类（ArrayList/LinkedHashMap/HashSet），不可用接口类型

## 性能预算

### 数据量估算

| 核心表 | 3个月 | 1年 | 3年 | 增长率 |
|--------|-------|-----|-----|--------|
| {table_a} | {n}万 | {n}万 | {n}万 | {x}%/月 |

### 索引策略

| 表 | 索引 | 覆盖查询 |
|----|------|---------|
| {table_a} | idx_{col1}_{col2} | {查询场景} |

### 性能指标

| 接口 | 目标 RT (P99) | 目标 QPS | 告警阈值 |
|------|-------------|---------|---------|
| {核心接口} | ≤ 200ms | 100 | RT > 500ms |

## 外部依赖

| 依赖 | 类型 | 用途 | 调用方式 |
|------|------|------|---------|
| saas-finance | 内部服务 | 支付/余额 | FinPaymentHelper / FinBalanceHelper |
| {第三方} | 外部API | {用途} | uw-httpclient |

## 全局错误码

| 错误码范围 | 模块 | 说明 |
|-----------|------|------|
| 10000-10099 | {模块A} | {模块A}业务错误 |
| 10100-10199 | {模块B} | {模块B}业务错误 |

## 测试策略

### 测试分层

| 测试层级 | 工具 | 覆盖范围 | 负责角色 |
|---------|------|---------|---------|
| 单元测试 | JUnit 5 + @SpringBootTest | Helper 所有公共方法（全链路） | 开发工程师 |
| 集成测试 | Spring Boot Test + MockMvc | Controller → Helper → Dao 链路 | 开发工程师 |
| API/E2E测试 | Playwright | 接口全量验证 + 端到端流程 | 测试工程师 |

### 覆盖率目标

| 指标 | 目标值 |
|------|--------|
| Helper 方法覆盖率 | ≥ 90% |
| 分支覆盖率 | ≥ 80% |
| 核心 CRUD 方法 | 100%（每个 ≥ 2 个测试用例） |

### 关键测试场景

| 模块 | 方法 | 测试场景 | 优先级 |
|------|------|---------|--------|
| {模块A} | saveXxx | 唯一性冲突 | P0 |
| {模块A} | updateXxx | 状态不允许修改 | P0 |
| {模块B} | processXxx | 并发冲突（分布式锁） | P0 |
| {模块B} | getXxx | 缓存命中/未命中 | P1 |
```

---

## 2. TASKS.md 开发任务模板

```markdown
# 开发任务

## 模块分类

| 模块 | 分类 | Helper | 说明 |
|------|------|--------|------|
| {ModuleA} | 简单 | - | 仅标准CRUD |
| {ModuleB} | 复杂 | {ModuleB}Helper | 状态机+缓存 |
| {ModuleC} | 横切 | {ModuleC}Helper | 跨模块公共规则（如敏感词过滤） |
| {ModuleD} | 复杂（含外部集成） | {ModuleD}Helper | AI调用+通知推送 |
| {OrderModule} | 复杂（父子表） | - | 联查listEx直接在Controller实现 + 懒加载子集Controller（见dev-standards.md「父子表查询方案」） |
| {ProductModule} | 复杂（多语言） | - | listLang/loadLang直接在Controller实现 + _lang子集标准CRUD（见dev-standards.md「多语言数据查询方案」） |

## 并行分组

| 组别 | 任务 | 说明 |
|------|------|------|
| 组1 | {ModuleA}, {ModuleC} | 无依赖，可并行 |
| 组2 | {ModuleB} | 依赖组1 |
| 组3 | {ModuleD} | 依赖组1（依赖{ModuleA}数据） |

## 进度

- [ ] T1: {ModuleA}（简单）
- [ ] T2: {ModuleC}（横切Helper）
- [ ] T3: {ModuleB}（复杂，含缓存）
- [ ] T4: {ModuleD}（复杂，含AI集成）
- [ ] T5: {OrderModule}（复杂-父子表，含listEx联查 + 懒加载子集Controller）
```
