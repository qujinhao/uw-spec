# 代码模板

> 所有完整代码块集中于此文件。规范约束见 [dev-standards.md](dev-standards.md)，本文档仅提供可复制粘贴的代码模板。
> 本文档由 `210-java-uniweb-dev`、`211-java-uniweb-dev-review` 等技能共同引用。

## 产出结构

```
{后端项目根目录}/
├── README.md                         # 总体设计文档（Phase 1 产出）
├── TASKS.md                          # 开发任务分工（Phase 2 产出，`210-java-uniweb-dev` 消费）
├── src/main/java/{package}/
│   ├── controller/
│   │   ├── saas/                     # 裁剪 + Javadoc + $PackageInfo$
│   │   ├── mch/
│   │   ├── admin/
│   │   ├── guest/                    # Guest控制器（无 $PackageInfo$）
│   │   └── rpc/
│   ├── service/                      # 新建 Helper
│   │   ├── {ModuleA}Helper.java
│   │   └── {ModuleB}Helper.java
│   ├── constant/                     # 业务枚举（状态/类型/响应码）+ ResponseCode i18n
│   ├── entity/                       # 保留不动
│   ├── dto/                          # 裁剪后
│   │   └── guest/                    # Guest 专用 DTO（类名含 Guest 标识）
│   └── vo/                           # 新建（如需）
├── src/main/resources/
│   └── {ResponseCode全路径}/          # i18n 资源文件（12种语种）
├── src/test/java/{package}/
│   ├── BaseIntegrationTest.java       # 测试基类（共享 Context）
│   ├── TestContextConfig.java         # 测试配置（含 CustomBeanNameGenerator）
│   ├── TestAuthUtils.java             # Auth 注入工具
│   ├── service/                       # Helper 测试（TDD Red → Green）
│   │   ├── {ModuleA}HelperTest.java
│   │   └── {ModuleB}HelperTest.java
│   ├── {role}/                         # {role} Controller 测试
│   │   └── {role}ControllerTest.java # 用户角色测试基类（UserType.{role}）
│   │   └── {module}/
│   │       └── {Module}ControllerTest.java
└── pom.xml
```

角色路径对照：

| 角色 | @RequestMapping 路径层级 | 完整路径示例 | @MscPermDeclare user | @MscPermDeclare auth | controller 包名 | $PackageInfo$ |
|------|------------------------|-------------|---------------------|---------------------|----------------|-------------|
| SAAS运营商 | 父级3级 / 子集4级 | `/saas/product` 或 `/saas/product/sku` | `UserType.SAAS` | `AuthType.PERM` | `controller.saas` | 需要 |
| 商户 | 父级3级 / 子集4级 | `/mch/order` 或 `/mch/order/refund` | `UserType.MCH` | `AuthType.PERM` | `controller.mch` | 需要 |
| 平台管理员 | 父级3级 / 子集4级 | `/admin/content` 或 `/admin/content/word` | `UserType.ADMIN` | `AuthType.PERM` | `controller.admin` | 需要 |
| ROOT | 父级3级 / 子集4级 | `/root/system` | `UserType.ROOT` | `AuthType.PERM` | `controller.root` | 需要 |
| OPS | 父级3级 / 子集4级 | `/ops/monitor` | `UserType.OPS` | `AuthType.PERM` | `controller.ops` | 需要 |
| RPC内部调用 | 父级3级 / 子集4级 | `/rpc/data` | `UserType.RPC` | `AuthType.NONE` | `controller.rpc` | 需要 |
| **GUEST(C端)** | **固定3级** | `/guest/club/group` | `UserType.GUEST` | `AuthType.USER` | `controller.guest` | **不需要** |

> **路径层级规则**（权威来源：[dev-standards.md](dev-standards.md)「路径规范」）：
> - **controller 包层级**：最多2级 `controller/{role}/{module}`
> - **Guest 角色**：类级 `@RequestMapping` 必须为**3级**（`/{role}/{1st-menu}/{2nd-menu}`），方法级加1级 = 完整4级路径。Guest 无"功能子集"概念，禁止使用4级 `@RequestMapping`
> - **非Guest 角色**：父级 Controller `@RequestMapping` 为**3级**（`/{role}/{1st-menu}/{2nd-menu}`）；1:N子集 Controller `@RequestMapping` 为**4级**（`/{role}/{1st-menu}/{2nd-menu}/{subset}`），4级路径必须存在对应的3级父路径定义（Controller 或 `$PackageInfo$`）
> - **路径命名**：禁止 `-`（短横线）和 `_`（下划线），仅允许驼峰命名
> - **Guest 角色说明**：`AuthType.USER` 仅验证用户类型（已登录），不验证权限菜单。Guest 无后台菜单系统，不适用 `AuthType.PERM`。`$PackageInfo$` 仅用于标准角色（saas/mch/admin/root/ops/rpc），guest 不适用

## Vo 模板

> 规范约束见 [dev-standards.md](dev-standards.md)「Vo/Ex 规范」。
> 父子表联查的 Ex 用法（listEx 场景）见本文「DAO 数据访问模板」。

**基础 Vo（裁剪敏感字段）**：

> Vo 使用 `@TableMeta` + `@ColumnMeta` 注解，仅标注需要输出的字段，框架自动映射，敏感字段自然裁剪。直接 `dao.load(VoClass, id)` 即可。

```java
package {项目包路径}.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import uw.dao.DataEntity;
import uw.dao.annotation.TableMeta;
import uw.dao.annotation.ColumnMeta;

@TableMeta(tableName = "{entity_table_name}")
@Schema(title = "{实体}视图对象", description = "{实体}视图对象，裁剪敏感字段")
public class {Entity}Vo extends DataEntity {

    @ColumnMeta
    @Schema(title = "主键", description = "主键")
    private long id;

    @ColumnMeta
    @Schema(title = "名称", description = "名称")
    private String name;

    // 不包含 password/phone/openid 等敏感字段 — 无 @ColumnMeta 即不映射

    // getters/setters 手写
}
```

**扩展 Ex（附加关联数据）**：

> Ex 继承 Entity，自动继承 `@TableMeta`/`@ColumnMeta` 注解，框架可直接 `dao.load(ExClass, id)` 映射所有父字段，无需手动 new + set。

```java
package {package}.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import {package}.entity.{Entity};
import java.util.List;

@Schema(title = "{实体}扩展视图对象", description = "{实体}扩展视图，包含关联数据")
public class {Entity}Ex extends {Entity} {

    @Schema(title = "明细列表", description = "关联明细列表")
    private List<{DetailEntity}> detailList;

    @Schema(title = "附加计数", description = "关联统计数据")
    private int commentCount;

    // getters/setters 手写
}
```

**Controller 中使用 Vo/Ex（直接 dao.load）**：

```java
// Vo — 仅映射 @ColumnMeta 标注的字段，敏感字段自然裁剪
@GetMapping("/loadVo")
public ResponseData<{Entity}Vo> loadVo(@RequestParam long id) {
    return dao.load({Entity}Vo.class, id);
}

// Ex — 自动映射所有父字段 + Ex 自身字段
@GetMapping("/loadEx")
public ResponseData<{Entity}Ex> loadEx(@RequestParam long id) {
    return dao.load({Entity}Ex.class, id);
}
```

## Controller 模板

> 规范约束见 [dev-standards.md](dev-standards.md)「Controller 规范」。
> 关键 import：`uw.dao.DaoManager`、`uw.common.app.dto.AuthQueryParam`、`uw.auth.service.annotation.MscPermDeclare.AuthType`、`uw.auth.service.annotation.MscPermDeclare.ActionLog`

### $PackageInfo$.java 模板

> 每个标准角色（saas/mch/admin/root/ops/rpc）的 controller 包中必须包含此文件。**guest 角色不适用**。
> `$PackageInfo$` 的 `@GetMapping` 路径必须为**2级**（`/{role}/{module}`），定义一级菜单权限。

```java
package {package}.controller.{role}.{module};

import io.swagger.v3.oas.annotations.Operation;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import uw.auth.service.annotation.MscPermDeclare;
import uw.auth.service.annotation.MscPermDeclare.AuthType;
import uw.auth.service.constant.UserType;

/**
 * {模块功能描述} - 角色级权限声明
 */
@RestController
public class $PackageInfo$ {

    @MscPermDeclare(user = UserType.{SAAS/MCH/ADMIN}, auth = AuthType.PERM)
    @Operation(summary = "{模块功能描述}", description = "{模块功能描述}")
    @GetMapping("/{role}/{module}")
    public void info() {
    }
}
```

> **auth 参数说明**：标准角色（saas/mch/admin/root/ops）使用 `AuthType.PERM`；RPC 使用 `AuthType.NONE`；Guest 使用 `AuthType.USER`。详见 [dev-standards.md](dev-standards.md)「Controller 规范」。

**角色权限速查**：

| 角色 | user | auth | $PackageInfo$ |
|------|------|------|---------------|
| SAAS/MCH/ADMIN/ROOT/OPS | `UserType.{role}` | `AuthType.PERM` | 需要 |
| RPC | `UserType.RPC` | `AuthType.NONE` | 需要 |
| **GUEST** | `UserType.GUEST` | `AuthType.USER` | **不需要** |

### Controller 类级 Javadoc

```java
/**
 * {ModuleName}Controller - {模块功能描述}
 *
 * <p>设计思路：{说明该Controller在整体架构中的角色，负责哪些业务场景的接口暴露}</p>
 *
 * <p>简单CRUD：直接调 dao</p>
 * <p>复杂逻辑：调用 {Module}Helper.xxx() 静态方法</p>
 *
 * <p>需求映射：README.md 中 {module} 模块，PRD功能点 {xxx}</p>
 *
 * @author {author}
 * @since 1.0.0
 */
@RestController
@RequestMapping("/{role}/{1st-menu}/{2nd-menu}")  // 非Guest: 父级3级, 子集4级; Guest: 固定3级
@Tag(name = "{ModuleName}", description = "{模块功能描述}")
@MscPermDeclare(name = "{模块功能}", user = UserType.{SAAS/MCH/ADMIN}, auth = AuthType.PERM, log = ActionLog.NONE)
public class {ModuleName}Controller {

    // 简单CRUD直接调 dao
    // 复杂逻辑调 {Module}Helper.xxx() 静态方法，无需注入
}
```

**路径层级示例**：
```java
// Guest 角色 — @RequestMapping 固定3级
@RequestMapping("/guest/club/group")        // ✅ 3级: /{role}/{1st-menu}/{2nd-menu}
@RequestMapping("/guest/club/group/member") // ❌ 4级: Guest 禁止使用4级路径

// 非Guest 父级 Controller — @RequestMapping 3级
@RequestMapping("/saas/club/group")          // ✅ 3级父级

// 非Guest 子集 Controller — @RequestMapping 4级（必须存在3级父路径）
@RequestMapping("/saas/club/group/member")   // ✅ 4级子集, 父级 /saas/club/group 已存在
```

### 方法体模板

```java
// 简单 CRUD - 直接调 DaoManager
@GetMapping("/list")
@MscPermDeclare(name = "列表", auth = AuthType.PERM, log = ActionLog.REQUEST)
public ResponseData<PageList<Xxx>> list(AuthQueryParam param) {
    return dao.list(Xxx.class, param);
}

// 复杂逻辑 - 调用 Helper 静态方法
@PostMapping("/save")
@MscPermDeclare(name = "新增", auth = AuthType.PERM, log = ActionLog.ALL)
public ResponseData<Xxx> save(@RequestBody Xxx entity) {
    return XxxHelper.saveXxx(entity);
}
```

**角色移动示例**：
```bash
mv controller/admin/product/ controller/saas/product/
# 修正包名: my.shop.controller.admin.product → my.shop.controller.saas.product
# 修正权限注解: UserType.ADMIN → UserType.SAAS
```

### 方法级 Javadoc

```java
/**
 * 分页查询{资源}列表
 *
 * <p>设计思路：基于AuthQueryParam分页参数查询当前租户下的{资源}列表，支持关键词模糊搜索</p>
 *
 * <p>实现要求：</p>
 * <ol>
 *   <li>[校验] 检查分页参数合法性</li>
 *   <li>[查询] 调用 {module}Helper.list{Entity}(param) 获取分页数据</li>
 * </ol>
 *
 * @param param 权限查询参数，自动注入saasId，含分页/排序/模糊搜索
 * @return 分页{资源}列表
 */
@Operation(summary = "分页查询{资源}")
@GetMapping("/list")
@MscPermDeclare(name = "{资源}列表", auth = AuthType.PERM, log = ActionLog.REQUEST)
public ResponseData<PageList<{Entity}>> list(AuthQueryParam param) {
    return ResponseData.success(null);
}
```

## 链式调用模式模板

> 规范约束见 [dev-standards.md](dev-standards.md)「链式调用规范」。核心设计：DaoManager 所有方法返回 `ResponseData<T>`，配合 `onSuccess` / `onError` 链式回调实现零中间变量代码。

### 直接返回模式（简单 CRUD）

```java
// 列表查询 — 一行代码
@GetMapping("/list")
@MscPermDeclare(name = "列表", auth = AuthType.PERM, log = ActionLog.REQUEST)
public ResponseData<PageList<Product>> list(AuthQueryParam param) {
    return dao.list(Product.class, param);
}

// 按ID加载
@GetMapping("/load")
@MscPermDeclare(name = "详情", auth = AuthType.PERM, log = ActionLog.BASE)
public ResponseData<Product> load(long id) {
    return dao.queryForObject(Product.class, new AuthIdQueryParam(getSaasId(), id));
}

// 新增保存
@PostMapping("/save")
@MscPermDeclare(name = "新增", auth = AuthType.PERM, log = ActionLog.ALL)
public ResponseData<Product> save(@RequestBody Product product) {
    product.setId(dao.getSequenceId(Product.class));
    product.setCreateDate(SystemClock.nowDate());
    return dao.save(product);
}
```

### 链式后处理模式（保存 + 缓存/日志/历史）

```java
// 保存 + 清缓存
@PostMapping("/save")
@MscPermDeclare(name = "新增", auth = AuthType.PERM, log = ActionLog.ALL)
public ResponseData<Product> save(@RequestBody Product product) {
    product.setId(dao.getSequenceId(Product.class));
    product.setCreateDate(SystemClock.nowDate());
    product.setSaasId(getSaasId());
    return dao.save(product)
        .onSuccess(saved -> FusionCache.invalidate(Product.class, saved.getId()));
}

// 更新 + 数据历史
@PostMapping("/update")
@MscPermDeclare(name = "修改", auth = AuthType.PERM, log = ActionLog.ALL)
public ResponseData<Product> update(@RequestBody Product product) {
    product.setModifyDate(SystemClock.nowDate());
    return dao.update(product)
        .onSuccess(updated -> SysDataHistoryHelper.saveHistory(updated, "更新产品"));
}

// 删除 = 加载 + 删除 + 清缓存 + 日志
@PostMapping("/delete")
@MscPermDeclare(name = "删除", auth = AuthType.PERM, log = ActionLog.ALL)
public ResponseData<Integer> delete(long id) {
    AuthServiceHelper.logRef(Product.class, id);
    return dao.queryForObject(Product.class, new AuthIdQueryParam(getSaasId(), id))
        .onSuccess(product -> dao.delete(product))
        .onSuccess(deleted -> FusionCache.invalidate(Product.class, id));
}
```

### 状态变更模式（enable / disable）

```java
@PostMapping("/enable")
@MscPermDeclare(name = "启用", auth = AuthType.PERM, log = ActionLog.ALL)
public ResponseData<Integer> enable(long id) {
    AuthServiceHelper.logRef(Product.class, id);
    return dao.queryForObject(Product.class, new AuthIdStateQueryParam(getSaasId(), id, CommonState.DISABLED.getValue()))
        .onSuccess(product -> {
            product.setState(CommonState.ENABLED.getValue());
            product.setModifyDate(SystemClock.nowDate());
            return dao.update(product);
        });
}

@PostMapping("/disable")
@MscPermDeclare(name = "禁用", auth = AuthType.PERM, log = ActionLog.ALL)
public ResponseData<Integer> disable(long id) {
    AuthServiceHelper.logRef(Product.class, id);
    return dao.queryForObject(Product.class, new AuthIdStateQueryParam(getSaasId(), id, CommonState.ENABLED.getValue()))
        .onSuccess(product -> {
            product.setState(CommonState.DISABLED.getValue());
            product.setModifyDate(SystemClock.nowDate());
            return dao.update(product);
        });
}
```

### 父子表联查模式（listEx）

```java
@GetMapping("/listEx")
@MscPermDeclare(name = "列表（含明细）", auth = AuthType.PERM, log = ActionLog.REQUEST)
public ResponseData<PageList<OrderEx>> listEx(AuthQueryParam param) {
    return dao.list(OrderEx.class, param).onSuccess(orders -> {
        if (orders.isEmpty()) return;  // 空页必须检查
        Object[] ids = orders.stream().map(OrderEx::getId).toArray();
        String inSql = "SELECT * FROM order_item WHERE order_id IN ("
            + String.join(",", Collections.nCopies(ids.length, "?")) + ")";
        dao.list(OrderItem.class, inSql, ids).onSuccess(items -> {
            Map<Long, List<OrderItem>> itemMap = items.stream()
                .collect(Collectors.groupingBy(OrderItem::getOrderId));
            orders.forEach(o -> o.setItemList(itemMap.getOrDefault(o.getId(), List.of())));
        });
    });
}
```

## DAO 数据访问模板

> 规范约束见 [dev-standards.md](dev-standards.md)「DAO 数据访问规范」。

### 父子表联查（listEx 场景）

> 规范约束见 [dev-standards.md](dev-standards.md)「父子表查询方案」。

**Ex 定义**（继承父 Entity，仅添加子数据列表字段）：

```java
package {package}.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import {package}.entity.{ParentEntity};
import java.util.List;

@Schema(title = "{父实体}扩展视图对象", description = "{父实体}扩展视图，包含关联子数据")
public class {Parent}Ex extends {ParentEntity} {

    @Schema(title = "子数据列表", description = "关联子数据列表")
    private List<{ChildEntity}> itemList;

    public List<{ChildEntity}> getItemList() { return itemList; }
    public void setItemList(List<{ChildEntity}> itemList) { this.itemList = itemList; }
}
```

**联查方案 — Controller 内直接实现（listEx）**：

```java
@GetMapping("/listEx")
@MscPermDeclare(name = "{资源}列表（含明细）", auth = AuthType.PERM, log = ActionLog.REQUEST)
public ResponseData<PageList<{Parent}Ex>> listEx({Parent}QueryParam param) {
    return dao.list({Parent}Ex.class, param).onSuccess(parents -> {
        if (parents.size() == 0) return;
        Object[] ids = parents.stream().map({Parent}Ex::getId).toArray();
        String inSql = "SELECT * FROM {child_table} WHERE {fk_column} IN ("
            + String.join(",", Collections.nCopies(ids.length, "?")) + ")";
        dao.list({Child}.class, inSql, ids).onSuccess(children -> {
            Map<Long, List<{Child}>> childMap = children.stream()
                .collect(Collectors.groupingBy({Child}::get{FkMethod}));
            parents.forEach(p -> p.setItemList(childMap.getOrDefault(p.getId(), Collections.emptyList())));
        });
    });
}
```

**懒加载方案 — 父表标准 list + 子集独立 Controller**：

```java
// 父表 Controller — 标准 list（无子数据）
@GetMapping("/list")
@MscPermDeclare(name = "{资源}列表", auth = AuthType.PERM, log = ActionLog.REQUEST)
public ResponseData<PageList<{Parent}>> list({Parent}QueryParam param) {
    return dao.list({Parent}.class, param);
}

// 子集 Controller — 4级路径，前端按需调用
@RestController
@RequestMapping("/{role}/{parent}/{child}")
@Tag(name = "{Child}", description = "{子资源}管理")
@MscPermDeclare(name = "{子资源}", user = UserType.{ROLE}, auth = AuthType.PERM, log = ActionLog.NONE)
public class {Child}Controller {

    @GetMapping("/list")
    @MscPermDeclare(name = "{子资源}列表", auth = AuthType.PERM, log = ActionLog.REQUEST)
    public ResponseData<PageList<{Child}>> list({Child}QueryParam param) {
        return dao.list({Child}.class, param);
    }
}
```

### 多语言数据查询（listLang 场景）

> 规范约束见 [dev-standards.md](dev-standards.md)「多语言数据查询方案」。
> 数据库设计规范见 200-database-design skill。

**LocaleHelper 工具类**（位于 `{package}/service/LocaleHelper.java`）：

```java
package {package}.service;

import org.springframework.context.i18n.LocaleContextHolder;

import java.util.Arrays;
import java.util.List;

public class LocaleHelper {

    private static final String DEFAULT_LANGUAGE_TAG = "zh-CN";

    private static final List<String> SUPPORTED_LANGUAGE_TAGS = Arrays.asList(
            "en",
            "zh-CN",
            "zh-TW"
    );

    /**
     * 获取默认语言标签
     * @return 默认语言标签
     */
    public static String getDefaultLanguageTag() {
        return DEFAULT_LANGUAGE_TAG;
    }

    /**
     * 获取解析后的语言标签
     * @return 解析后的语言标签
     */
    public static String getResolvedLanguageTag() {
        String languageTag = LocaleContextHolder.getLocale().toLanguageTag();
        for (String supportedLanguageTag : SUPPORTED_LANGUAGE_TAGS) {
            if (supportedLanguageTag.startsWith(languageTag)) {
                return languageTag;
            }
        }
        return getDefaultLanguageTag();
    }
}
```
> `getDefaultLanguageTag` 实现可以根据情况，从saas系统配置中获取默认语言标签。
> `SUPPORTED_LANGUAGE_TAGS` 按项目实际支持的语种配置，与 ResponseCode i18n 资源文件语种保持一致。

**单条详情查询（带多语言）**：

```java
@GetMapping("/loadLang")
@MscPermDeclare(name = "{资源}详情（多语言）", auth = AuthType.PERM, log = ActionLog.REQUEST)
public ResponseData<{Entity}> loadLang(@RequestParam long id) {
    String lang = LocaleHelper.getResolvedLanguageTag();
    if (lang.equals(LocaleHelper.getDefaultLanguageTag())) {
        return load(id);
    }
    String sql = "SELECT t.*, "
        + "COALESCE(l.{field1}, t.{field1}) AS {field1}, "
        + "COALESCE(l.{field2}, t.{field2}) AS {field2} "
        + "FROM {main_table} t "
        + "LEFT JOIN {main_table}_lang l ON l.{entity}_id = t.id AND l.lang = ? AND l.state = 1 "
        + "WHERE t.id = ?";
    return dao.queryForObject({Entity}.class, sql, new Object[]{lang, id});
}
```

**列表查询（带多语言）**：

```java
@GetMapping("/listLang")
@MscPermDeclare(name = "{资源}列表（多语言）", auth = AuthType.PERM, log = ActionLog.REQUEST)
public ResponseData<PageList<{Entity}>> listLang({Entity}QueryParam param) {
    String lang = LocaleHelper.getResolvedLanguageTag();
    if (lang.equals(LocaleHelper.getDefaultLanguageTag())) {
        return list(param);
    }
    String sql = "SELECT t.*, "
        + "COALESCE(l.{field1}, t.{field1}) AS {field1}, "
        + "COALESCE(l.{field2}, t.{field2}) AS {field2} "
        + "FROM {main_table} t "
        + "LEFT JOIN {main_table}_lang l ON l.{entity}_id = t.id AND l.lang = ? AND l.state = 1 "
        + "WHERE t.saas_id = ? ORDER BY t.create_date DESC LIMIT ?,?";
    return dao.list({Entity}.class, sql,
        new Object[]{lang, param.getSaasId(), param.getStartIndex(), param.getResultNum()});
}
```

**优化逻辑说明**：

```
LocaleHelper.getResolvedLanguageTag() 返回当前请求语言
  → 与 getDefaultLanguageTag() 一致 → 直接调标准 list/load（无需 LEFT JOIN）
  → 不一致 → LEFT JOIN _lang + COALESCE 降级查询
```

**_lang 表 CRUD**：由代码生成器生成标准 Entity/DTO/Controller，作为子集实体（4 级路径，如 `/{role}/{module}/lang`）处理。

## Helper 模板

> 规范约束见 [dev-standards.md](dev-standards.md)「Helper 设计规范」。
> 创建前提：三条件满足至少一项（逻辑复杂/功能性/多处调用），简单 CRUD 不建 Helper。
> Helper 两种类型：**模块级 Helper**（按数据库表/模块识别）和**横切 Helper**（按跨模块公共业务规则识别）。

```java
package {package}.service;

import {package}.constant.{Module}ResponseCode;
import {package}.entity.*;
import uw.cache.FusionCache;
import uw.cache.CacheDataLoader;
import uw.common.app.constant.CommonResponseCode;
import uw.common.app.constant.CommonState;
import uw.common.app.dto.AuthIdQueryParam;
import uw.common.response.ResponseData;
import uw.common.util.SystemClock;
import uw.dao.DaoManager;
import uw.common.data.PageList;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;

/**
 * {ModuleName}Helper - {module}复杂业务逻辑
 *
 * <p>设计思路：{说明该Helper负责的核心业务逻辑范围，处理哪些业务场景}</p>
 *
 * <p>创建理由：{说明为什么需要Helper，满足三条件中哪些项}</p>
 * <ul>
 *   <li>逻辑复杂：{如状态机、多步流程等}</li>
 *   <li>功能性：{如缓存、分布式锁等}</li>
 *   <li>多处调用：{如N个Controller调用}</li>
 * </ul>
 *
 * <p>需求映射：README.md 中 {module} 模块</p>
 *
 * @author {author}
 * @since 1.0.0
 */
public class {Module}Helper {

    private static final Logger log = LoggerFactory.getLogger({Module}Helper.class);
    private static final DaoManager dao = DaoManager.getInstance();

    // ==================== 缓存配置（按需） ====================

    private static final int CACHE_MAX_NUM = 500;
    private static final long CACHE_EXPIRE_MILLIS = 1800_000L;

    static {
        FusionCache.config(new FusionCache.Config(
            {Entity}.class,
            CACHE_MAX_NUM,
            CACHE_EXPIRE_MILLIS
        ), new CacheDataLoader<Long, {Entity}>() {
            @Override
            public {Entity} load(Long key) {
                return dao.load({Entity}.class, key).getData();
            }
        });
    }

    /**
     * {方法功能概述}
     *
     * <p>实现步骤：</p>
     * <ol>
     *   <li>[校验] {校验逻辑}</li>
     *   <li>[保存] {保存逻辑}</li>
     *   <li>[缓存] {缓存失效/更新逻辑}</li>
     * </ol>
     *
     * @param param {参数说明}
     * @return {返回值说明}
     */
    public static ResponseData<{Entity}> {methodName}({params}) {
        // {实现完整业务逻辑}
    }
}
```

> **按需引入**：`uw.cache.GlobalCache`、`uw.cache.GlobalLocker`、`uw.common.app.constant.CommonState`、`uw.common.app.constant.CommonResponseCode` 等按实际业务需要引入。
> FusionCache Config（缓存容量、过期时间）和 CacheDataLoader（数据加载器签名）在 Helper 的 `static {}` 块中一次性完成。GlobalCache 不需要 static 初始化（直接用 `GlobalCache.get(...)` 带行内 CacheDataLoader），但 FusionCache 必须在类加载时完成 config。

### Helper 间调用参考示例

> 本节为 Helper 间调用的参考示例，展示静态方法调用、SaaS 实体校验、缓存失效等典型模式。

```java
public class OrderHelper {
    private static final DaoManager dao = DaoManager.getInstance();

    public static ResponseData<Void> acceptAnswer(long saasId, long answerId) {
        ResponseData<Answer> answerResult = dao.queryForObject(
            Answer.class, new AuthIdQueryParam(saasId, answerId));
        if (answerResult.isNotSuccess()) {
            return ResponseData.warnCode(CommonResponseCode.ENTITY_NOT_FOUND);
        }

        Answer answer = answerResult.getData();
        answer.setAccepted(true);
        answer.setModifyDate(SystemClock.nowDate());
        dao.update(answer);

        PostQuestionHelper.resolveQuestion(saasId, answer.getQuestionId());
        GuestPointHelper.earnPoint(saasId, answer.getGuestId(), PointType.ACCEPT_ANSWER);
        MsgNotifyHelper.sendNotice(saasId, answer.getGuestId(),
            "您的回答已被采纳", NoticeType.ANSWER_ACCEPTED);

        return ResponseData.success(null);
    }
}
```

## 枚举与响应码模板

> 规范约束见 [dev-standards.md](dev-standards.md)「枚举与响应码规范」。

### 状态/类型枚举

```java
// 位于 {package}/constant/ 包下
public enum AuditState {
    PENDING(0, "待审核"),
    APPROVED(1, "审核通过"),
    REJECTED(-1, "审核拒绝");

    private final int value;
    private final String label;

    AuditState(int value, String label) {
        this.value = value;
        this.label = label;
    }

    public int getValue() { return value; }
    public String getLabel() { return label; }
}
```

### 响应码枚举

```java
// 位于 {package}/constant/ 包下
package {package}.constant;

import com.fasterxml.jackson.annotation.JsonFormat;
import org.springframework.context.MessageSource;
import org.springframework.context.support.ResourceBundleMessageSource;
import uw.common.response.ResponseCode;
import uw.common.util.EnumUtils;

@JsonFormat(shape = JsonFormat.Shape.OBJECT)
public enum {Module}ResponseCode implements ResponseCode {
    ENTITY_NOT_FOUND( "实体未找到"),
    ;

    /**
     * 国际化信息MESSAGE_SOURCE。
     */
    private static final ResourceBundleMessageSource MESSAGE_SOURCE = new ResourceBundleMessageSource() {{
        setBasename( "i18n/messages/{module}" );
        setDefaultEncoding( "UTF-8" );
    }};

    /**
     * 响应码。
     */
    private final String code;
    /**
     * 错误信息。
     */
    private final String message;

    {Module}ResponseCode(String message) {
        this.code = EnumUtils.enumNameToDotCase( this.name() );
        this.message = message;
    }
    /**
     * 获取配置前缀.
     *
     * @return
     */
    @Override
    public String codePrefix() {
        return "{package}.{module}";
    }
    /**
     * 获取响应码
     *
     * @return
     */
    @Override
    public String getCode() {
        return code;
    }
    /**
     * 获取错误信息
     *
     * @return
     */
    @Override
    public String getMessage() {
        return message;
    }
    /**
     * 获取消息源.
     *
     * @return
     */
    @Override
    public MessageSource messageSource() {
        return MESSAGE_SOURCE;
    }
}
```

### i18n 资源文件

```
src/main/resources/{枚举类全路径}/
├── messages.properties           # 默认（中文简体）
├── messages_zh_CN.properties     # 中文简体
├── messages_zh_TW.properties     # 中文繁体
├── messages_en.properties        # 英语
├── messages_ja.properties        # 日语
├── messages_de.properties        # 德语
├── messages_fr.properties        # 法语
├── messages_ko.properties        # 韩语
├── messages_it.properties        # 意大利语
├── messages_ru.properties        # 俄语
├── messages_es.properties        # 西班牙语
├── messages_pt.properties        # 葡萄牙语
└── messages_ar.properties        # 阿拉伯语
```

```properties
# messages_zh_CN.properties
entity.not.found=实体未找到

# messages_en.properties
entity.not.found=Entity not found

# messages_ja.properties
entity.not.found=エンティティが見つかりません
```

## 缓存使用模板

> 规范约束见 [dev-standards.md](dev-standards.md)「缓存使用规范」。
> 完整 Helper 代码模板（含 FusionCache static 块）见本文「Helper 模板」。

**FusionCache（实体详情缓存）**：必须在 Helper 的 `static {}` 块中初始化。

```java
static {
    FusionCache.config(new FusionCache.Config(
        {Entity}.class,
        CACHE_MAX_NUM,
        CACHE_EXPIRE_MILLIS
    ), new CacheDataLoader<Long, {Entity}>() {
        @Override
        public {Entity} load(Long key) {
            return dao.load({Entity}.class, key).getData();
        }
    });
}

// 读取
ResponseData<{Entity}> result = FusionCache.get({Entity}.class, id);

// 失效
FusionCache.invalidate({Entity}.class, id);
```

**GlobalCache（列表/临时数据缓存）**：行内 CacheDataLoader，不需要 static 初始化。

```java
GlobalCache.get("{cacheName}", key, new CacheDataLoader<String, List<{Entity}>>() {
    @Override
    public List<{Entity}> load(String key) {
        return dao.list({Entity}.class, sql, params).getData();
    }
}, expireMillis);

// 失效
GlobalCache.invalidate("{cacheName}", key);
```

## 认证授权模板

> 规范约束见 [dev-standards.md](dev-standards.md)「认证授权规范」。

**内部 RPC 调用**：

```java
@Autowired
@Qualifier("authRestClient")
private RestClient authRestClient;

// Token 自动管理（自动 login/refresh/重试），无需手动设置 Authorization 请求头
ResponseData<Result> result = authRestClient.postForObject(url, request, ResponseData.class);
```

## 单元测试模板

> 测试规范见 [dev-standards.md](dev-standards.md)「单元测试规范」。
> TDD 通用方法论见 [tdd-guide.md](../../0-init/references/tdd-guide.md)。
> **禁止 Mock 测试**，所有测试使用 `@SpringBootTest` 全链路测试，真实数据库交互。
> 数据清理使用 `dao.execute(sql)` 执行 DELETE 语句。
> 测试使用 `spring.profiles.active=debug`，加载项目初始化阶段生成的 `application-debug.yml`。

### 测试基础设施

项目初始化提供基础设施：
- **BaseIntegrationTest**：所有测试的基类，共享 Spring Context
- **TestContextConfig**：解决同一 Controller 类名在不同角色目录（guest/saas）下的 Bean 名称冲突
- **TestAuthUtils**：通过反射调用 `AuthServiceHelper.setContextToken(AuthTokenData)` 注入测试用户认证信息。支持设置所有用户角色，包括 RPC/ROOT/OPS/ADMIN/SAAS/MCH/GUEST/ANY

数据清理使用 `DaoManager.execute(sql)`，禁止使用 JdbcTemplate。

继承体系：
- 常规测试：`BaseIntegrationTest` → 各模块 Test
- Controller 测试：`BaseIntegrationTest` → `{role}ControllerTest` → 各模块 ControllerTest

**{role}ControllerTest（以 Guest 角色为例，其它角色类推）**：

```java
package {package}.controller.guest;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import {package}.BaseIntegrationTest;
import {package}.TestAuthUtils;

public abstract class GuestControllerTest extends BaseIntegrationTest {

    @BeforeEach
    void setUpGuestAuth() {
        TestAuthUtils.setGuestUser();
    }

    @AfterEach
    void tearDownGuestAuth() {
        TestAuthUtils.clear();
    }
}
```

### Helper 单元测试

**Red 阶段（先写测试，确认失败）**：

```java
class ProductHelperTest extends BaseIntegrationTest {

    private final List<Long> createdProductIds = new ArrayList<>();

    @Override
    protected void cleanTestData() {
    }

    @Test
    @DisplayName("保存商品 - 正常保存并返回ID")
    void testSaveProduct_Success_ReturnWithId() {
        fail("TDD Red: [T1] saveProduct 正常创建");
    }

    @Test
    @DisplayName("查询商品 - 存在则返回，不存在返回warn")
    void testGetProduct_Exists_ReturnEntity_NotExists_ReturnWarn() {
        fail("TDD Red: [T1] getProduct 存在/不存在");
    }
}
```

**Green 阶段（写实现，确认通过）**：

```java
class ProductHelperTest extends BaseIntegrationTest {

    private static final long TEST_SAAS_ID = TestAuthUtils.TEST_SAAS_ID;
    private final List<Long> createdProductIds = new ArrayList<>();

    @Override
    protected void cleanTestData() {
        if (!createdProductIds.isEmpty()) {
            String ids = createdProductIds.stream()
                .map(String::valueOf)
                .collect(Collectors.joining(","));
            dao.execute("DELETE FROM product WHERE id IN (" + ids + ")");
            createdProductIds.clear();
        }
    }

    @Test
    @DisplayName("保存商品 - 正常保存并返回ID")
    void testSaveProduct_Success_ReturnWithId() {
        Product product = new Product();
        product.setName(testName("iPhone"));
        product.setPrice(new BigDecimal("5999.00"));

        ResponseData<Product> result = ProductHelper.saveProduct(TEST_SAAS_ID, product);

        assertTrue(result.isSuccess());
        assertNotNull(result.getData().getId());
        createdProductIds.add(result.getData().getId());
    }

    @Test
    @DisplayName("查询商品 - 存在则返回，不存在返回warn")
    void testGetProduct_Exists_ReturnEntity_NotExists_ReturnWarn() {
        Product product = new Product();
        product.setName(testName("MacBook"));
        ResponseData<Product> saved = ProductHelper.saveProduct(TEST_SAAS_ID, product);
        long productId = saved.getData().getId();
        createdProductIds.add(productId);

        ResponseData<Product> found = ProductHelper.getProduct(productId);
        assertTrue(found.isSuccess());

        ResponseData<Product> notFound = ProductHelper.getProduct(99999999L);
        assertFalse(notFound.isSuccess());
    }
}
```

### Controller 全流程测试

> **测试架构**：直接注入 Controller Bean + 反射注入 AuthTokenData。**禁止 MockMvc 和 TestRestTemplate**。

```java
package {package}.controller.saas.product;

import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import {package}.controller.saas.SaasControllerTest;
import {package}.TestAuthUtils;
import {package}.dto.ProductQueryParam;
import {package}.entity.Product;
import uw.common.response.ResponseData;
import uw.dao.DaoManager;
import uw.common.data.PageList;

public class ProductControllerTest extends SaasControllerTest {

    private static final DaoManager dao = DaoManager.getInstance();

    @Autowired
    @Qualifier("saasProductController")
    private {your.base.package}.controller.saas.product.ProductController controller;

    @Test
    @DisplayName("list - 正常调用")
    void testList_Success() {
        ProductQueryParam param = new ProductQueryParam(TestAuthUtils.TEST_SAAS_ID);
        ResponseData<PageList<Product>> result = controller.list(param);
        assertTrue(result.isSuccess());
    }

    @Test
    @DisplayName("save - 正常创建")
    void testSave_Success() {
        Product entity = buildTestProduct();
        ResponseData<Product> result = controller.save(entity);
        assertTrue(result.isSuccess());
        assertNotNull(result.getData());
    }

    @Test
    @DisplayName("update - 正常更新")
    void testUpdate_Success() {
        Product entity = buildTestProduct();
        ResponseData<Product> saveResult = controller.save(entity);
        assertTrue(saveResult.isSuccess());
        Product toUpdate = new Product();
        toUpdate.setId(saveResult.getData().getId());
        toUpdate.setProductName("已更新商品");
        ResponseData<Product> result = controller.update(toUpdate, "测试更新");
        assertTrue(result.isSuccess());
    }

    @Override
    protected void cleanTestData() {
        try {
            dao.execute("DELETE FROM product WHERE saas_id=?", new Object[]{TestAuthUtils.TEST_SAAS_ID});
        } catch (Exception e) { /* ignore */ }
    }

    private Product buildTestProduct() {
        Product entity = new Product();
        entity.setProductName("测试商品_" + System.currentTimeMillis());
        entity.setPrice(new java.math.BigDecimal("99.00"));
        return entity;
    }
}
```

## 业务场景→模块映射

> AI 编码时根据当前业务场景，加载对应文档。

| 业务场景 | 需要加载的文档 | 核心类 |
|---------|-------------|--------|
| 带权限的CRUD接口 | dev-standards + uw-dao + uw-auth-service | DaoManager, AuthQueryParam, @MscPermDeclare |
| 带缓存的详情查询 | uw-dao + uw-cache | DaoManager, FusionCache, CacheDataLoader |
| 异步任务处理 | uw-task | TaskRunner, TaskCroner, TaskFactory |
| 服务间RPC调用 | uw-auth-client | authRestClient |
| 文件上传下载 | saas-base-common | SysOssHelper |
| 支付订单 | saas-finance-client + saas-ais-module | FinPaymentHelper, AisHelper |
| 多语言接口 | dev-standards（多语言章节）+ code-templates（DAO 数据访问模板） | LocaleHelper |
| 实时通知推送 | uw-notify-client | NotifyClientHelper, WebNotifyMsg |
| 第三方登录 | uw-oauth2-client | OAuth2ClientHelper |
| 短链接 | uw-tinyurl-client | TinyurlClientHelper |
| HTTP外部调用 | uw-httpclient | JsonInterfaceHelper, XmlInterfaceHelper |
| ES日志记录/查询 | uw-log-es | LogClient |
| AI对话/翻译 | uw-ai | AiClientHelper |
| 浏览器自动化 | uw-webot | WebotManager, BrowserTab |
| 多因素认证 | uw-mfa | MfaFusionHelper |
| 产品授权计费 | saas-aip-module | AipHelper, AipVendor |
| 第三方接口集成 | saas-ais-module | AisHelper, BaseAisLinker |
| 数据库分库分表 | uw-mydb-client | MydbClientHelper |
| 网关限速管理 | uw-gateway-client | GatewayClientHelper |

## POM 依赖速查

groupId：`com.umtone`（以下标注 ★ 的为 `saas`）

| 需求 | artifactId |
|------|-----------|
| 通用工具（ResponseData/JsonUtils/DateUtils） | uw-common |
| Web应用基础（AuthQueryParam/CommonState/CommonResponseCode） | uw-common-app |
| 数据库操作（DaoManager/DataEntity） | uw-dao |
| 缓存（FusionCache/GlobalCache/GlobalLocker） | uw-cache |
| 认证服务端（@MscPermDeclare/AuthServiceHelper） | uw-auth-service |
| 认证客户端（authRestClient） | uw-auth-client |
| 定时/队列任务（TaskCroner/TaskRunner） | uw-task |
| HTTP外部调用（JsonInterfaceHelper） | uw-httpclient |
| ES日志（LogClient） | uw-log-es |
| Logback→ES日志推送 | uw-logback-es |
| AI集成（AiClientHelper） | uw-ai |
| 多因素认证（MfaFusionHelper） | uw-mfa |
| OAuth2客户端（OAuth2ClientHelper） | uw-oauth2-client |
| 网关管理（GatewayClientHelper） | uw-gateway-client |
| 数据库运维（MydbClientHelper） | uw-mydb-client |
| 实时通知（NotifyClientHelper） | uw-notify-client |
| 短链接（TinyurlClientHelper） | uw-tinyurl-client |
| 浏览器自动化（WebotManager） | uw-webot |
| ★ SaaS基础（SaasInfoHelper/MsgHelper/SysOssHelper） | saas-base-common |
| ★ SaaS财务（FinPaymentHelper/FinBalanceHelper） | saas-finance-client |
