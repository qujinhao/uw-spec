# 开发规范

## 代码生成与开发流程

**代码生成机制**：

entity、dto、controller 基础代码通过 uw-code-center 工具自动生成。开发人员必须对自动生成的代码进行裁剪：

- **DTO 裁剪**：精确控制搜索条件字段和排序字段，确保接口参数符合业务需求
- **Controller 裁剪**：实现权限控制逻辑，移除不需要的功能接口，优化接口设计

**开发重点与代码组织**：

- 开发核心为 **service 层** 和 **controller 层**实现
- 针对非 CRUD 的复杂业务逻辑，必须封装在 **service 层**或 **Helper 工具类**中，供 controller 层调用

### Vo/Ex 规范

| 类型 | 命名 | 用途 | 约束 |
|------|------|------|------|
| 基础 Vo | `{Entity}Vo extends DataEntity` | 裁剪敏感字段（password/phone/openid 等） | 使用 `@TableMeta` + `@ColumnMeta`，仅标注需输出的字段，框架自动映射；敏感字段不加 `@ColumnMeta` 即不映射 |
| 扩展 Ex | `{Entity}Ex extends {Entity}` | 附加关联数据（如明细列表、附加计数） | 继承父 Entity，自动继承 `@TableMeta`/`@ColumnMeta`，框架可直接 `dao.load(ExClass, id)` |

- Vo/Ex 均可直接 `dao.load(VoClass/ExClass, id)`，无需手动 new + set
- Vo/Ex 统一在 **vo 包**下创建并管理

> 完整 Vo/Ex 代码模板见 [code-templates.md](code-templates.md)「Vo 模板」。

## Controller 规范

### 路径规范

**关键约束**：
- controller包层级最多两级，一级为用户角色名，二级为模块名（一级菜单）。
- 所有权限的第一级路径必须为用户角色名。
- **路径禁止使用 `-`（短横线）和 `_`（下划线）**。错误示例：`/user-profile`、`/order_item`；正确示例：`/userProfile`、`/orderItem`。

**GUEST用户权限**:
- **路径格式**：`/{role}/{一级菜单}/{二级菜单}/{功能权限}`

**非GUEST用户权限**：
- **路径格式**：`/{role}/{一级菜单}/{二级菜单}/{功能权限}` 或 `/{role}/{一级菜单}/{二级菜单}/{功能子集}/{功能子权限}`
- 一级菜单权限由包下面的$PackageInfo$.java类定义，此定义的路径必须为2级。
- 二级菜单权限由包下面的XXXController.java类定义，此定义的路径必须为3级。
- **1:N关系中的子集**需要定义为功能子集权限，由包下面的XXXController.java类定义，此定义的路径必须为4级。
- 每个URL路径必须存在父级路径定义，否则权限菜单无法正常显示。

### @Tag 命名规范

`@Tag(name = "本级功能名")`，只写当前 Controller 管理的功能名称，不包含角色和菜单层级前缀。路径层级已由 `@RequestMapping` 和 `$PackageInfo$` 定义，`@Tag` 仅用于 Swagger 分组展示。

```java
// ✅ 正确：name 只写本级功能，不带"-"/"_"
@Tag(name = "敏感词管理", description = "敏感词增删改查管理")

// ❌ 错误：name 包含完整菜单层级
@Tag(name = "SAAS-内容管理-敏感词管理", description = "SAAS端内容管理-敏感词增删改查列管理")
```

### 权限声明规范

所有接口必须使用 `@MscPermDeclare` 注解声明权限。**不同角色的 user 和 auth 参数不同**：

| 角色 | user | auth | 说明 |
|------|------|------|------|
| SAAS | `UserType.SAAS` | `AuthType.PERM` | 验证权限，注册菜单 |
| MCH | `UserType.MCH` | `AuthType.PERM` | 验证权限，注册菜单 |
| ADMIN | `UserType.ADMIN` | `AuthType.PERM` | 验证权限，注册菜单 |
| ROOT | `UserType.ROOT` | `AuthType.PERM` | 验证权限，注册菜单 |
| OPS | `UserType.OPS` | `AuthType.PERM` | 验证权限，注册菜单 |
| RPC | `UserType.RPC` | `AuthType.NONE` | 内部调用无需鉴权 |
| **GUEST** | `UserType.GUEST` | `AuthType.USER` | **仅验证登录，不验证权限** |

> 完整角色映射表、$PackageInfo$ 模板、Controller 方法体模板见 [code-templates.md](code-templates.md)「Controller 模板」。

### 响应格式规范

所有 Controller 方法返回值必须使用 `ResponseData` 包装（单对象 `ResponseData<T>`、分页列表 `ResponseData<PageList<T>>`、无数据 `ResponseData`）。

### 参数类型规范

方法参数一律使用基本类型（`long`、`int`、`boolean`），禁止使用包装类型（`Long`、`Integer`、`Boolean`）。仅当参数明确需要接受 `null` 值时（Javadoc 标注"可选"），才允许使用包装类型。

| 场景 | 类型 | 示例 |
|------|------|------|
| ID参数（必填） | `long` | `getById(long id)` |
| 数组参数（必填） | `long[]` | `batchPublish(long saasId, long[] ids)` |
| 可选筛选参数（需判null） | `Long` | `suggestQuestions(String keyword, Long categoryId)` |
| CacheDataLoader泛型 | `Long` | `CacheDataLoader<Long, Entity>` — 泛型必须用包装类型 |

此规范适用于 Controller 方法参数、Helper 方法参数、以及所有手写代码中的方法参数。代码生成器产出的 entity/dto 中的字段类型不在此规范约束范围内。

### 实体类规范

实体类继承 `DataEntity`，使用 `@TableMeta` 和 `@ColumnMeta` 注解。

### @Schema 注解规范

所有 Entity、Dto、Vo 类及其字段的 `@Schema` 注解**必须同时设置 `title` 和 `description`**：

```java
// ✅ 正确：同时设置 title 和 description
@Schema(title = "用户信息", description = "用户信息")
public class GuestInfoVo {
    @Schema(title = "主键", description = "主键")
    private long id;
}

// ❌ 错误：只有 description，缺少 title
@Schema(description = "用户信息")
public class GuestInfoVo {
    @Schema(description = "主键")
    private long id;
}
```

此规范适用于所有 `@Schema` 注解位置：Entity 类级/字段级、Dto 类级/字段级、Vo 类级/字段级。

## DAO 数据访问规范

- 优先使用 `DaoManager`（ResponseData 链式lambda风格），避免使用 `DaoFactory`（抛异常风格）
- `DaoManager` 通过 `DaoManager.getInstance()` 静态获取，无需 Spring 注入
- 查询参数使用 QueryParam 系列类（`IdQueryParam`、`AuthQueryParam`、`AuthIdStateQueryParam` 等），**仅限 Controller 层使用**（依赖 Auth 上下文）
- Helper 层按ID加载**SaaS实体（有saas_id字段）**时使用 `dao.queryForObject(Entity.class, new AuthIdQueryParam(saasId, id))`（自动拼接 `WHERE id=? AND saas_id=?`，无需手写SQL）。**对于无 saas_id 的非SaaS实体可直接 `dao.load(Entity.class, id)`。**需附带 state 条件时使用 `AuthIdStateQueryParam(saasId, id, state)`
- 批量操作使用 `BatchUpdateManager`

### 链式调用规范

DaoManager 所有方法返回 `ResponseData<T>`，这是框架的核心设计模式。通过链式 `onSuccess` / `onError` 回调，实现零中间变量、自动错误传播的简洁代码。

| 规则 | 说明 | 示例 |
|------|------|------|
| **直接返回** | 简单 CRUD 直接 `return dao.xxx()` | `return dao.list(User.class, param);` |
| **链式后处理** | 需要额外操作时用 `onSuccess` | `return dao.save(user).onSuccess(u -> cache.invalidate(u.getId()));` |
| **自动跳过** | 链中任何一步 WARN/ERROR，后续 `onSuccess` 自动跳过 | 无需 `if (result.isSuccess())` 判空 |
| **禁止 if-else 判断** | 禁止 `if (result.isSuccess()) { ... } else { ... }` | 用 `.onSuccess(...)` / `.onNotSuccess(...)` 替代 |
| **扁平链式** | 禁止嵌套 `onSuccess` 内再嵌套 `onSuccess`，用 `return dao.xxx()` 展平 | 见下方说明 |
| **日志前置** | `logRef()` 放在方法体开头（`return` 之前），不嵌套在 `onSuccess()` 内 | 避免漏记日志 |
| **空页检查** | `onSuccess` 内第一行 `if (list.isEmpty()) return;` | 父子表联查必须检查空页 |
| **原地设值** | `onSuccess` 内直接修改 ResponseData 中的对象引用 | `orders.forEach(o -> o.setItems(...))` |

> 完整链式调用代码范例见 [uw-dao.md](uw-dao.md)「DaoManager 链式调用设计」和 [uw-common.md](uw-common.md)「ResponseData 链式回调」。

### 父子表查询方案

当存在 1:N 父子表关系（如订单 OrderInfo + 订单明细 OrderItem）时，提供两种查询方案：

| 方案 | API 命名 | 实现位置 | 适用场景 |
|------|---------|---------|---------|
| **联查方案** | `listEx` | Controller 内 `onSuccess` 嵌套，无需 Helper | 父列表需直接嵌套子数据（如订单列表展示商品明细） |
| **懒加载方案** | `list` + 子集 Controller `list` | 父表标准 `list`，子表独立 4 级路径 Controller | 子数据量大或按需展开，前端二次请求 |

**联查方案（`listEx`）规范**：

| 约束 | 说明 |
|------|------|
| Ex 类继承父 Entity | `OrderInfoEx extends OrderInfo`，ORM 通过继承的 `@TableMeta` 自动映射所有父字段 |
| API 命名 `listEx` | 与标准 `list` 区分，表示返回扩展数据（含子表） |
| 直接写在 Controller | 逻辑简单（2次查询+组装），无需 Helper |
| `onSuccess` 链式嵌套 | 外层查父表，内层 IN 查子表，失败/WARN 时链自动跳过 |
| 原地设值 | `forEach(o -> o.setItems(...))` 修改 ResponseData 内部同一引用 |
| SQL 模式 | 1次 `dao.list(ExClass, param)` + 1次 `dao.list(ChildClass, inSql, ids)`，共2次查询 |

**懒加载方案规范**：

| 约束 | 说明 |
|------|------|
| 父表标准 `list` | 无子数据，直接 `dao.list(Entity, param)` |
| 子集独立 Controller | 4 级路径（如 `/saas/order/item`），前端按需调用 |
| 遵循 gencode-trim-guide §2.D 子集实体裁剪规则 | |

**方案选择决策**：

| 条件 | 选择 |
|------|------|
| 父列表页面需要直接展示子数据 | **联查方案**（`listEx`） |
| 子数据量大（>20条/父记录）或按需展开 | **懒加载方案**（独立子集 Controller） |
| 两种都需要（不同页面/角色） | **两个都提供**：`list`（标准）+ `listEx`（联查） |

完整代码示例见 [code-templates.md](code-templates.md)「DAO 数据访问模板」。

### 多语言数据查询方案

系统多语言统一方案，涵盖程序层和数据层：

| 层级 | 类型 | 实现方式 | 说明 |
|------|------|---------|------|
| **程序层** | 错误码/枚举标签 | ResponseCode + i18n 资源文件（12种语种） | 见 code-templates.md「枚举与响应码模板」 |
| **数据层** | 用户业务数据 | `_lang` 翻译表 + LEFT JOIN + COALESCE 自动降级 | 本节 + code-templates.md「DAO 数据访问模板」 |

> **程序层多语言**已在 code-templates.md「枚举与响应码模板」完整定义（ResponseCode 枚举 + `ResourceBundleMessageSource` + 12 种语种资源文件），此处不再重复。

**数据层多语言规范**：

| 约束 | 说明 |
|------|------|
| 翻译表命名 | `{主表名}_lang`，如 `product_info_lang` |
| 不需要 Ex 类 | COALESCE 别名与主表字段同名，ORM 自动映射回主 Entity 同名字段 |
| API 命名 `listLang` / `loadLang` | 与标准 `list`/`load`、父子表 `listEx` 区分 |
| lang 通过 `LocaleHelper.getResolvedLanguageTag()` 获取 | 从 `Accept-Language` 请求头自动解析，白名单校验，不通过 `@RequestParam` 传入 |
| 默认语言优化 | `getResolvedLanguageTag()` 与 `getDefaultLanguageTag()` 一致时，直接调标准 `list`/`load`，无需 LEFT JOIN |
| LocaleHelper 位于 `service/` 包 | 纯 static 工具类，与 Helper 同包，按项目语种配置 `SUPPORTED_LANGUAGE_TAGS` |
| LEFT JOIN 条件含 `lang` + `state=1` | `l.{entity}_id=t.id AND l.lang=? AND l.state=1` |
| 外键字段使用 `{实体}_id` | 如 `product_id`，不用 `ref_id` |
| 降级逻辑 | COALESCE：翻译表无记录时自动返回主表默认语言值 |
| _lang 表标准 CRUD | 由代码生成器生成，作为子集实体（4 级路径 Controller）处理 |

完整代码示例见 [code-templates.md](code-templates.md)「DAO 数据访问模板」。

## Helper 设计规范

Helper 是纯静态工具类，**不是 Spring Bean**，不加 `@Component`，不使用构造器注入。

**创建条件**（三条件满足至少一项才创建 Helper）：

| 条件 | 说明 | 示例 |
|------|------|------|
| 逻辑复杂 | 状态机、多步流程、计算、复杂校验 | 内容审核（多状态流转）、回答采纳（锁+状态+积分） |
| 功能性 | 缓存、分布式锁、事务等横切关注点 | 详情缓存（FusionCache）、并发操作（GlobalLocker） |
| 多处调用 | 2个以上 Controller 或其他 Helper 调用 | 发送通知（多处触发）、用户信息查询（多处引用） |

**不建 Helper 的场景**：简单 CRUD（list/get/save/update/delete/enable/disable）直接在 Controller 中调 `DaoManager.getInstance()` 即可。

**Helper 两种类型**：

| 类型 | 识别维度 | 示例 |
|------|---------|------|
| **模块级 Helper** | 按数据库表/模块识别，一个模块一个 Helper | PostQuestionHelper、PostAnswerHelper |
| **横切 Helper** | 按 PRD 中跨模块的公共业务规则识别，一个规则一个 Helper | SensitiveWordHelper、MsgNotifyHelper |

> 横切 Helper 识别方法：通读 PRD，找出"在多个模块中出现相同描述"的业务规则。

> 完整 Helper 代码模板（含 import/类结构/缓存/方法签名）见 [code-templates.md](code-templates.md)「Helper 模板」。

**核心约束**：纯静态工具类，`DaoManager.getInstance()` 静态获取，禁止 `@Component` + 构造器注入。

## 枚举与响应码规范

### 枚举类组织

在 `{package}/constant/` 包下定义业务枚举类，替代代码中的硬编码数字和字符串。

**必须定义枚举的场景**：
- **状态值**：`state` 字段的 0/1/2 等数字 → 使用 `CommonState` 或自定义枚举
- **类型值**：`noticeType`、`refType`、`penaltyType` 等分类字段
- **响应码**：`warnCode`/`errorCode` 的字符串参数 → 使用 `ResponseCode` 枚举

> 完整枚举定义模板、ResponseCode 模板、i18n 资源文件模板见 [code-templates.md](code-templates.md)「枚举与响应码模板」。

### CommonState 使用规范

`uw-common-app` 提供的 `CommonState` 枚举（ENABLED=1, DISABLED=0, DELETED=-1），**Helper 和 Controller 中必须使用此枚举替代硬编码**：

```java
// ❌ 错误：硬编码数字
entity.setState(1);
entity.setState(0);

// ✅ 正确：使用 CommonState
entity.setState(CommonState.ENABLED.getValue());
entity.setState(CommonState.DISABLED.getValue());
```

### ResponseCode 使用规范

`ResponseData.warnCode()` 和 `ResponseData.errorCode()` 支持传入 `ResponseCode` 枚举，**业务响应码必须定义为枚举，禁止硬编码字符串**：

```java
// ❌ 错误：硬编码字符串，散落在各 Helper 中无法集中管理
return ResponseData.warnCode("USER_NOT_FOUND", "用户不存在");
return ResponseData.errorCode("UPDATE_FAILED", "更新失败");

// ✅ 正确：使用 ResponseCode 枚举，类型安全、集中管理
return ResponseData.warnCode(GuestResponseCode.USER_NOT_FOUND);
return ResponseData.errorCode(CommonResponseCode.ENTITY_UPDATE_ERROR);
```

**枚举分层**：
- 通用场景（实体不存在、保存失败等）→ 使用 `CommonResponseCode`（uw-common-app 提供）
- 业务场景（密码错误、积分不足等）→ 在 `{package}/constant/` 包下定义业务 `ResponseCode` 枚举
- 同一业务的响应码放在同一个枚举类中（如 `GuestResponseCode`、`PostResponseCode`、`CmsResponseCode`）

### ResponseCode i18n 资源文件规范

每个业务 `ResponseCode` 枚举必须配套 i18n 资源文件（12 种语种），资源文件位置：`src/main/resources/{枚举类全路径}/`。

> 完整 i18n 资源文件目录结构和示例见 [code-templates.md](code-templates.md)「枚举与响应码模板」。

## 缓存使用规范

- 高频读取场景使用 `FusionCache`（本地 + Redis 融合缓存）
- Kryo 序列化**必须使用具体实现类**，不能使用接口类型（如 List/Map/Set），必须传 ArrayList/LinkedHashMap/HashSet 等
- Caffeine 设定过期时间后性能劣化 200 倍，建议仅设 Redis 过期时间，不设 Caffeine 本地过期
- **FusionCache 必须在 static 块中初始化**：所有使用 FusionCache 的 Helper 必须在 `static {}` 块中一次性完成 `FusionCache.config(new FusionCache.Config(...), new CacheDataLoader<>() {...})` 初始化，包括缓存参数（容量、过期时间）和 CacheDataLoader.load() 实现。GlobalCache 不需要 static 初始化（使用行内 CacheDataLoader）。

**FusionCache vs GlobalCache 选型**：

| 维度 | FusionCache | GlobalCache |
|------|------------|-------------|
| 存储 | 本地 + Redis 融合 | 纯 Redis |
| 适用 | 单条实体详情（高频读取） | 列表、临时数据 |
| 初始化 | 必须在 `static {}` 块 | 行内 CacheDataLoader |
| 失效 | `FusionCache.invalidate(Class, key)` | `GlobalCache.invalidate(cacheName, key)` |

## 认证授权规范

- 内部 RPC 调用使用 `@Qualifier("authRestClient")` 注入带鉴权的 RestClient
- Token 自动管理（自动 login/refresh/重试），无需手动设置 Authorization 请求头
- 收到 401 或 498 时自动刷新 Token 并重试一次

## 单元测试规范

> TDD 通用方法论（Red-Green-Refactor、AI 原生循环）见 [tdd-guide.md](../../0-init/references/tdd-guide.md)。本节仅描述 210 专属的测试策略和约束。

### 测试原则

| 原则 | 说明 |
|------|------|
| **全链路测试** | 使用 `@SpringBootTest` 启动完整 Spring 上下文，测试真实数据库交互 |
| **单 Context** | 所有测试继承 `BaseIntegrationTest`，共享同一个 Spring Context，只启动一次 |
| **数据隔离** | 使用测试数据前缀（`TEST_` + 时间戳）+ `@AfterEach` 手动清理，不用事务回滚 |
| **测试用户** | 使用 `TestAuthUtils.setTestUser()` 设置测试用户（saasId=mchId=userId=666） |
| **真实依赖** | DaoManager/FusionCache/GlobalLocker 均使用真实实例，测试真实数据库读写 |
| **禁止 Mock** | 禁止 MockMvc/TestRestTemplate/Mockito，所有测试使用真实数据库交互 |

### 测试分层

| 层级 | 测试目标 | 技术方案 |
|------|---------|---------|
| Helper 测试 | 业务逻辑 + 数据访问 | `@SpringBootTest` + 真实数据库，继承 `BaseIntegrationTest` |
| Controller 测试 | API 契约 + SQL 正确性 | `@SpringBootTest` + 直接注入 Controller Bean + 反射注入 AuthTokenData，继承 `{role}ControllerTest` |

> **Controller 测试架构**：**禁止 MockMvc 和 TestRestTemplate**。`AuthServiceFilter` 拦截所有 HTTP 请求要求 RPC Token 验证，测试环境无法提供。正确方式是直接注入 Controller Bean + 通过反射 `AuthServiceHelper.setContextToken()` 注入 AuthTokenData。详见 [code-templates.md](code-templates.md)「单元测试模板」。

### 按方法类型测试用例数

| 方法类型 | 基础用例 | 边界用例 | 异常用例 | 合计 |
|---------|---------|---------|---------|------|
| listXxx | 正常分页查询 1 | 空结果 1 | - | 2 |
| getXxx | 正常查询 1 | 不存在ID 1 | - | 2 |
| saveXxx | 正常新增 1 | 唯一性冲突 1 | 必填字段缺失 1 | 3 |
| updateXxx | 正常修改 1 | 不存在ID 1 | 状态不允许修改 1 | 3 |
| deleteXxx | 正常删除 1 | 不存在ID 1 | 关联数据阻止删除 1 | 3 |
| enableXxx / disableXxx | 正常操作 1 | 不存在ID 1 | 重复操作 1 | 3 |
| 业务流程方法 | 正常流程 1 | 每个分支 1 | 每个异常 1 | 3-5 |

### 测试命名规范

| 规则 | 格式 | 示例 |
|------|------|------|
| 测试类 | `{Class}Test` | `ProductHelperTest` |
| 测试方法 | `test{Method}_{Scenario}_{ExpectedResult}` | `testSaveProduct_NameDuplicate_ThrowException` |
| 测试方法（简化） | `test{Method}_{ExpectedResult}` | `testGetById_NotFound_ReturnWarn` |

## AI Coding 禁忌清单（全局生效）

> 以下陷阱来自各模块文档汇总，AI 编码时**必须逐条检查**，违反即为 Bug。

### 禁止重复造轮子（优先使用框架工具类）

> AI 编码时**必须优先使用** `uw-common` 和 `uw-common-app` 提供的工具类，**禁止自行实现**相同功能。以下场景已有现成方案：

| 禁止自己写 | 必须用 | 所在包 |
|-----------|--------|--------|
| `System.currentTimeMillis()` | `SystemClock.now()` / `SystemClock.nowDate()` | `uw.common.util.SystemClock` |
| `new SimpleDateFormat(...)` | `DateUtils.format()` / `DateUtils.parse()` | `uw.common.util.DateUtils` |
| `new ObjectMapper()` / 手写 JSON 序列化 | `JsonUtils.toString()` / `JsonUtils.parse()` | `uw.common.util.JsonUtils` |
| 手写 MD5/SHA256 | `DigestUtils.md5()` / `DigestUtils.sha256()` | `uw.common.util.DigestUtils` |
| 手写 AES 加密 | `AESUtils.encryptString()` / `BizAESBox` | `uw.common.util` |
| 手写金额计算（double/BigDecimal） | `MoneyUtils`（long 分单位） | `uw.common.util.MoneyUtils` |
| 手写邮箱/手机号/身份证正则 | `ValidateUtils.isEmail()` / `isChinaMobile()` 等 | `uw.common.util.ValidateUtils` |
| 手写 IP 匹配/CIDR | `IpMatchUtils.match()` / `isInRange()` | `uw.common.util.IpMatchUtils` |
| `Math.random()` / `Random` 生成 ID | `SnowflakeIdGenerator.getInstance().generateId()` | `uw.common.util.SnowflakeIdGenerator` |
| 手写位运算开关 | `BitConfigUtils.isOn()` / `on()` / `off()` | `uw.common.util.BitConfigUtils` |
| 硬编码状态值 0/1/-1 | `CommonState.ENABLED/DISABLED/DELETED` | `uw.common.app.constant.CommonState` |
| 硬编码错误消息字符串 | `ResponseData.warnCode(CommonResponseCode.XXX)` | `uw.common.app.constant.CommonResponseCode` |
| 手写 `@Schema` 校验逻辑 | `SchemaValidateHelper.validate(entity)` | `uw.common.app.helper.SchemaValidateHelper` |
| 手写分页参数解析 | `QueryParamHelper.buildQuerySql(param)` | `uw.common.app.helper.QueryParamHelper` |
| 手写数据变更历史记录 | `SysDataHistoryHelper.saveHistory(entity, "操作")` | `uw.common.app.helper.SysDataHistoryHelper` |
| 手写 JSON 配置管理 | `JsonConfigHelper` / `JsonConfigBox` | `uw.common.app.helper` / `uw.common.app.vo` |
| `UUID.randomUUID()` 做业务 ID | `dao.getSequenceId(Class)` — 分布式序列 | `uw.dao.DaoManager` |
| 手写日志记录（Web 场景） | `AuthServiceHelper.logRef()` / `logInfo()` | `uw.auth.service.AuthServiceHelper` |

### ResponseData 模块

| ❌ 错误写法 | ✅ 正确写法 |
|------------|-----------|
| `ResponseData.warn("CODE","msg")` | `ResponseData.warnCode("CODE","msg")` 或 `warnCode(ResponseCode)` — 实际签名是 `warn(T t, String code)`，"CODE"变成data而非状态码 |
| `ResponseData.error("CODE","msg")` | `ResponseData.errorCode("CODE","msg")` 或 `errorCode(ResponseCode)` — 同 warn 泛型陷阱 |
| `isNotSuccess() \|\| getData()==null` | `if (result.isNotSuccess())` — getData()==null 不会额外为 true |

**ResponseData 状态选择决策**：

| 场景 | 使用 | 示例 |
|------|------|------|
| 操作成功（有数据） | `success(data)` | `ResponseData.success(entity)` |
| 操作成功（无数据） | `success()` | `ResponseData.success()` |
| 业务校验失败 | `warnCode()` | `ResponseData.warnCode(CommonResponseCode.ENTITY_NOT_FOUND_ERROR)` |
| 系统异常 | `errorCode()` | `ResponseData.errorCode(CommonResponseCode.ENTITY_SAVE_ERROR)` |
| 致命错误 | `fatalCode()` | `ResponseData.fatalCode(...)` |
| 数据不存在（dao.load/list 查无结果） | 框架自动返回 WARN | 检查 `result.getData() != null` 而非 `isSuccess()` |

### DaoManager 模块

| ❌ 错误写法 | ✅ 正确写法 |
|------------|-----------|
| `dao.executeCommand(sql, params)` | `dao.execute(sql, params)` — 方法已重命名 |
| `dao.list("WHERE ...")` | `dao.list(Class, "SELECT * FROM table WHERE ...")` — SQL 必须完整 |
| `DataList.isEmpty()` | `data.size() == 0` — PageList 没有 isEmpty() |
| `dao.load(SaaSEntity, id)` 无 saasId | `dao.queryForObject(Class, new AuthIdQueryParam(saasId, id))` |
| `dao.list + LIMIT 1 + get(0)` | `dao.queryForObject(Class, "SELECT * FROM t WHERE ... LIMIT 1", params)` |
| `dao.list("SELECT *") + size()` 计数 | `dao.queryForValue(Long.class, "SELECT COUNT(*) FROM t WHERE ...", params)` |
| `dao.delete(Class, id)` | 先 `dao.load`/`queryForObject` 获取实体，再 `dao.delete(entity)` |
| `dao.update(entity)` 不设 modifyDate | 必须 `.modifyDate(SystemClock.nowDate())` |
| `dao.save(entity)` 不设 ID | 必须 `entity.setId(dao.getSequenceId(Entity.class))` |
| `dao.update` 部分字段不设 modifyDate | `new Entity().id(id).field(value)` 只更新非 null 字段，必须同时 `.modifyDate()` |
| `modifyDate` 在 `dao.save()` 时必填 | `dao.save()` 时可设 `modifyDate(null)` 或不设（框架不强制）；`dao.update()` 时必须设 |
| `if (result.isSuccess()) { ... } else { ... }` | `result.onSuccess(...)` / `.onNotSuccess(...)` — 禁止 if-else 判断 ResponseData 状态 |
| `var result = dao.load(...); return result;` | `return dao.load(...);` — 零中间变量直接返回 |
| `result.getData() != null` 判断成功 | `result.isSuccess()` 或直接用 `onSuccess` / `onNotSuccess` 链式处理 |

### Cache 模块

| ❌ 错误写法 | ✅ 正确写法 |
|------------|-----------|
| `FusionCache.invalidateAll()` | 逐个 `FusionCache.invalidate(Class, key)` — 没有 invalidateAll |
| `FusionCache` 缓存 `DataList` | 缓存 `ArrayList<Entity>` — DataList 序列化异常 |
| `GlobalCache.delete()` | `GlobalCache.invalidate(cacheName, key)` — 方法名是 invalidate |
| `CacheDataLoader` 用 lambda | `new CacheDataLoader<K,V>(){@Override public V load(K key){...}}` — 是抽象类 |
| `GlobalCache.getIfPresent()` | `GlobalCache.get(cacheName, key, CacheDataLoader, expireMillis)` — 没有 getIfPresent |
| FusionCache/GlobalCache 选错 | 单条实体详情用 FusionCache；列表、临时数据用 GlobalCache |

### Helper/通用模块

| ❌ 错误写法 | ✅ 正确写法 |
|------------|-----------|
| Helper 加 `@Component` / `@Service` | Helper 是纯静态工具类，禁止 Spring 注解，用 `DaoManager.getInstance()` 静态获取 |
| Helper 层使用 `AuthQueryParam` | AuthQueryParam 依赖 Spring Security 上下文，Helper 层用 `dao.list(Entity, sql, params)` |

### 枚举模块

| ❌ 错误写法 | ✅ 正确写法 |
|------------|-----------|
| `entity.setState(0/1)` 硬编码 | `CommonState.ENABLED/DISABLED.getValue()` |
| `warnCode("USER_NOT_FOUND", "用户不存在")` 硬编码 | `warnCode(GuestResponseCode.USER_NOT_FOUND)` — 定义 ResponseCode 枚举 |
| 枚举类散落在 entity/service 包 | 统一放在 `{package}/constant/` 包下 |

### @Schema/DateUtils 模块

| ❌ 错误写法 | ✅ 正确写法 |
|------------|-----------|
| `@Schema(description="xxx")` 缺 title | `@Schema(title="xxx", description="xxx")` — 必须同时设置 |
| `DateUtils.getDayStart/getDayEnd/addDays` | `DateUtils.beginOfToday(date)` / `endOfToday(date)` / `offsetDay(date, n)` |

### 外部集成模块

> Helper 的 Javadoc 步骤中标注了 `[调用AI]`、`[推送通知]`、`[外部调用]`、`[跨模块调用]`、`[降级处理]` 的步骤，**必须使用对应 SDK 实现，禁止替换为数据库操作或省略**。

| ❌ 错误写法 | ✅ 正确写法 |
|------------|-----------|
| AI 调用退化为数据库查询 | `AiClientHelper.generate(AiChatGenerateParam.builder().configId(configId).userPrompt(content).build())` |
| 通知推送退化为数据库 INSERT | `dao.save(msgNotice)` 后必须调用 `NotifyClientHelper.pushNotify(new WebNotifyMsg(...))` |
| AiClientHelper 不检查结果 | `ResponseData<String> aiResult = AiClientHelper.generate(param); if (aiResult.isNotSuccess()) { 降级处理 }` |
| AiChatGenerateParam 未 bindAuthInfo | `param.bindAuthInfo()` 自动绑定当前用户认证信息，禁止手动 `setSaasId` |
| configId 硬编码 | 从 AiConfig 表动态读取：`dao.queryForObject(AiConfig.class, ...)` |
| 流式对话用同步方式 | 对话场景用 `AiClientHelper.chatGenerate()` 返回 `Flux<String>` |
| 跨模块调用被省略 | 如 `acceptAnswer()` 必须：PostQuestionHelper.resolveQuestion() + GuestPointHelper.earnPoint() + MsgNotifyHelper.sendNotice() |

**降级原则**：外部服务不可用时的降级是写降级逻辑（如返回提示信息），不是直接删除该步骤。

## 四条编码原则

> 被 210-java-uniweb-dev、211-java-uniweb-dev-review、620/621/720/721 共同引用。
> 本文件是编码规范的**唯一权威来源**，其他技能文件不再重复列举规则。

### 原则一：集中管理（Single Source of Truth）

一个配置在多个地方可能被使用，或属于字典/枚举/映射类数据，应集中管理。

| 集中到哪里 | 管什么 | 详见 |
|-----------|--------|------|
| `constant/` | 业务枚举（状态/类型/响应码） | 详见「枚举与响应码规范」 |
| `service/` | 业务逻辑（Helper） | 详见「Helper 设计规范」 |
| `vo/` | 视图对象（裁剪/聚合输出） | 详见「Vo/Ex 规范」 |
| `dto/` | 数据传输对象（代码生成器产出，仅裁剪） | 详见「代码生成与开发流程」 |

### 原则二：类型安全（No Escape Hatches）

如果 Java 编译器无法推断类型，说明代码有问题。

| 禁止 | 替代方案 | 详见 |
|------|---------|------|
| `ResponseData.warn/error("CODE","msg")` | `warnCode`/`errorCode` | 详见「AI Coding 禁忌清单」 |
| Lombok（`@Data`/`@Getter`/`@Setter`） | 手写 getter/setter/构造器 | 详见「Helper 设计规范」 |
| 方法参数使用包装类型 | 使用基本类型 | 详见「Controller 规范」 |
| `@Schema` 只设 `description` | 必须同时设置 `title` 和 `description` | 详见「Controller 规范」 |

### 原则三：项目一致性（Use What Exists）

编写任何代码前，先检查项目中是否已有相同或类似功能的实现。

| 场景 | 做法 | 详见 |
|------|------|------|
| 数据访问 / 分页查询 | DaoManager + AuthQueryParam | 详见「DAO 数据访问规范」 |
| 缓存 | FusionCache（实体）/ GlobalCache（列表） | 详见「缓存使用规范」 |
| 权限声明 / 响应格式 | @MscPermDeclare + ResponseData\<T\> | 详见「Controller 规范」 |
| Helper 依赖获取 / 方法风格 | 静态获取 + public static | 详见「Helper 设计规范」 |
| 枚举 / 响应码 | CommonState + ResponseCode | 详见「枚举与响应码规范」 |

### 原则四：代码可读性（Self-Documenting Code）

一个新团队成员能否在不看注释的情况下理解代码意图。

| 禁止 | 替代方案 | 详见 |
|------|---------|------|
| 硬编码数字 `setState(0)` | `setState(CommonState.DISABLED.getValue())` | 详见「枚举与响应码规范」 |
| 硬编码字符串 `warnCode("CODE","msg")` | `warnCode(ResponseCode.XXX)` | 详见「枚举与响应码规范」 |
| 方法超过 50 行 / 圈复杂度超过 10 | 拆分子方法 / 简化条件 | — |
| 缺少 `@Schema` 注解 | 所有 Entity/Dto/Vo 有完整 @Schema | 详见「Controller 规范」 |

## 自动化验证

开发完成后，在 `backend/{project-name}-app/` 目录下依次执行以下检查：

```bash
# 1. Lombok 检查（应为 0）
grep -rn '@Data\|@Getter\|@Setter\|@RequiredArgsConstructor' src/main/java/ --include="*.java" | wc -l

# 2. 硬编码状态值检查（应为 0）
grep -rn 'setState(0)\|setState(1)\|setState(-1)' src/main/java/ --include="*.java" | wc -l

# 3. 硬编码响应码检查（应为 0）
grep -rn 'warnCode("\|errorCode("' src/main/java/ --include="*.java" | wc -l

# 4. ResponseData 泛型陷阱检查（应为 0）
grep -rn 'ResponseData\.warn("\|ResponseData\.error("' src/main/java/ --include="*.java" | wc -l

# 5. DAO 方法名错误检查（应为 0）
grep -rn 'dao\.executeCommand(\|GlobalCache\.delete(\|FusionCache\.invalidateAll(' src/main/java/ --include="*.java" | wc -l

# 6. Controller Mapping 路径命名检查（应为 0）
grep -rn '@.*Mapping.*".*[-_].*"' src/main/java/ --include="*.java" | wc -l

# 7. TODO 残留检查（应为 0）
grep -rn '// TODO:' src/main/java/ --include="*.java" | wc -l

# 8. @Schema 完整性检查（缺少 title 的行应为 0）
grep -rn '@Schema(description' src/main/java/ --include="*.java" | grep -v 'title' | wc -l

# 9. ResponseCode i18n 资源文件检查（每个 ResponseCode 枚举必须配套 ≥3 个语种文件）
for enum_file in $(grep -rln 'implements ResponseCode' src/main/java/ --include="*.java"); do
    enum_class=$(echo "$enum_file" | sed 's|src/main/java/||;s|\.java||;s|/|.|g')
    resource_dir="src/main/resources/$(echo $enum_class | tr '.' '/')"
    if [ ! -d "$resource_dir" ]; then
        echo "MISSING i18n: $resource_dir (for $enum_class)"
    else
        file_count=$(ls "$resource_dir"/messages*.properties 2>/dev/null | wc -l)
        if [ "$file_count" -lt 3 ]; then
            echo "INCOMPLETE i18n: $resource_dir has $file_count files (need ≥3)"
        fi
    fi
done

# 10. 编译 + 全量测试
mvn compile && mvn test -Dspring.profiles.active=debug
```
