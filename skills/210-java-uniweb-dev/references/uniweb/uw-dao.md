# uw-dao — 数据访问层

**Maven 坐标**: `com.umtone:uw-dao`

**配置前缀**: `uw.dao`

```yaml
uw:
  dao:
    conn-pool:
      root:
        driver: com.mysql.cj.jdbc.Driver
        url: jdbc:mysql://localhost:3306/mydb?useSSL=false&serverTimezone=Asia/Shanghai
        username: root
        password: secret
        min-conn: 1
        max-conn: 10
```

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 获取实例 | `DaoManager.getInstance()` | 静态获取，无需 Spring 注入 |
| 保存 | `dao.save(entity)` | 先 `entity.setId(dao.getSequenceId(Class))`，再设 `createDate` |
| 批量保存 | `dao.save(List<Entity>)` | — |
| 更新 | `dao.update(entity)` | 必须 `.modifyDate(SystemClock.nowDate())`，差量更新只更新非null字段 |
| 条件更新 | `dao.update(entity, QueryParam)` | — |
| 按ID加载(SaaS实体) | `dao.queryForObject(Class, new AuthIdQueryParam(saasId, id))` | 禁止 `dao.load()` 无 saasId |
| 按ID加载(非SaaS实体) | `dao.load(Class, id)` | — |
| 加附带state条件 | `dao.queryForObject(Class, new AuthIdStateQueryParam(saasId, id, state))` | — |
| 列表查询(QueryParam) | `dao.list(Class, QueryParam)` 或 `dao.queryForList(Class, QueryParam)` | QueryParam 仅限 Controller 层 |
| 列表查询(SQL) | `dao.list(Class, "SELECT * FROM t WHERE ...", params)` | SQL 必须 SELECT * FROM 开头 |
| 查单条 | `dao.queryForObject(Class, "SELECT * FROM t WHERE ... LIMIT 1", params)` | 禁止 list + get(0) |
| 查计数值 | `dao.queryForValue(Long.class, "SELECT COUNT(*) FROM t WHERE ...", params)` | 禁止 list + size() |
| 查值列表 | `dao.queryForValueList(Class, "SELECT col FROM t WHERE ...", params)` | 替代旧 queryForSingleList |
| 查数据表 | `dao.queryForTable(Class, "SELECT * FROM t WHERE ...", params)` | 替代旧 queryForDataSet |
| 执行DML | `dao.execute(sql, params)` | — |
| 删除 | `dao.delete(entity)` | 先加载实体再删；不支持 `dao.delete(Class, id)` |
| 条件删除 | `dao.delete(Class, QueryParam)` | — |
| 序列ID | `dao.getSequenceId(Class)` | 插入前必须调用 |
| 批量更新 | `dao.getBatchUpdateManager(null)` | — |

**SaaS多租户安全规则**：仅当实体表包含 `saas_id` 字段时适用。CacheDataLoader 回源加载是唯一例外（按主键加载，无需 saasId）。

**load/list 返回值**：数据不存在时返回 WARN 状态。检查 `result.getData() != null` 而非 `isSuccess()`。

## DaoManager 方法签名

> **包路径**：`uw.dao.DaoManager`

构造：`DaoManager.getInstance()` 静态单例

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getSequenceId(Class<?>)` | long | 根据实体类获取分布式序列 |
| `save(T entity)` | `ResponseData<T>` | 单条保存 |
| `save(List<T>)` | `ResponseData<List<T>>` | 批量保存 |
| `update(T entity)` | `ResponseData<T>` | 差量更新（只更新非null字段） |
| `update(T entity, QueryParam)` | `ResponseData<Integer>` | 条件更新 |
| `delete(T entity)` | `ResponseData<Integer>` | 删除实体 |
| `delete(Class<T>, QueryParam)` | `ResponseData<Integer>` | 条件删除 |
| `load(Class<T>, Serializable id)` | `ResponseData<T>` | 按主键加载 |
| `list(Class<T>, String sql)` | `ResponseData<PageList<T>>` | SQL列表查询 |
| `list(Class<T>, String sql, Object[])` | `ResponseData<PageList<T>>` | 带参数SQL列表查询 |
| `list(Class<T>, QueryParam)` | `ResponseData<PageList<T>>` | QueryParam列表查询 |
| `queryForObject(Class<T>, String sql, Object[])` | `ResponseData<T>` | 查单条（替代 list+LIMIT 1+get(0)） |
| `queryForObject(Class<T>, QueryParam)` | `ResponseData<T>` | QueryParam查单条 |
| `queryForValue(Class<T>, String sql, Object[])` | `ResponseData<T>` | 查标量值（替代 list+size()） |
| `queryForValueList(Class<T>, String sql, Object[])` | `ResponseData<List<T>>` | 查值列表 |
| `queryForTable(Class<T>, String sql, Object[])` | `ResponseData<PageRowSet>` | 查数据表（行列结构） |
| `queryForList(Class<T>, ...)` | `ResponseData<PageList<T>>` | 16个重载，委托调用 list() |
| `execute(String sql, Object[])` | `ResponseData<Integer>` | 执行DML |
| `getBatchUpdateManager(String)` | `BatchUpdateManager` | 获取批量更新管理器 |

> 所有方法均支持 `String connName` 重载（多数据源路由）和 `String tableName` 重载（分表路由）。

**方法命名体系**：
- **query 系列**（查询）：`queryForList` / `queryForObject` / `queryForValue` / `queryForValueList` / `queryForTable` — 完整的查询命名
- **CRUD 动词系列**（增删改查）：`save` / `update` / `delete` / `load` / `list` — 与 query 系列互补

## DaoManager 链式调用设计

DaoManager 所有方法返回 `ResponseData<T>`，这是整个框架链式调用的核心设计。Controller 可以直接 `return dao.xxx()`，一行代码完成数据操作 + 响应包装 + 错误处理。

**设计理念**：
- **零中间变量**：`return dao.list(Class, param)` 直接返回给前端，无需 `ResponseData<PageList<User>> result = dao.list(...); return result;`
- **链式后处理**：通过 `onSuccess` / `onError` 在返回前进行额外操作（缓存更新、日志记录、数据组装）
- **自动错误传播**：链中任何一步失败/WARN，后续 `onSuccess` 自动跳过，不会 NPE

### 直接返回模式（最常见）

```java
// Controller 直接返回，一行代码搞定
@GetMapping("/list")
public ResponseData<PageList<User>> list(AuthQueryParam param) {
    return dao.list(User.class, param);
}

@GetMapping("/load")
public ResponseData<User> load(long id) {
    return dao.queryForObject(User.class, new AuthIdQueryParam(getSaasId(), id));
}

@PostMapping("/save")
public ResponseData<User> save(@RequestBody User user) {
    user.setId(dao.getSequenceId(User.class));
    user.setCreateDate(SystemClock.nowDate());
    return dao.save(user);
}
```

### 链式后处理模式

```java
// 保存后清除缓存
@PostMapping("/save")
public ResponseData<User> save(@RequestBody User user) {
    user.setId(dao.getSequenceId(User.class));
    user.setCreateDate(SystemClock.nowDate());
    return dao.save(user).onSuccess(saved ->
        FusionCache.invalidate(User.class, saved.getId())
    );
}

// 更新后记录历史
@PostMapping("/update")
public ResponseData<User> update(@RequestBody User user) {
    user.setModifyDate(SystemClock.nowDate());
    return dao.update(user).onSuccess(updated ->
        SysDataHistoryHelper.saveHistory(updated, "更新用户")
    );
}

// 删除后清除缓存 + 记录日志
@PostMapping("/delete")
public ResponseData<Integer> delete(long id) {
    AuthServiceHelper.logRef(User.class, id);
    return dao.queryForObject(User.class, new AuthIdQueryParam(getSaasId(), id))
        .onSuccess(user -> dao.delete(user))
        .onSuccess(deleted -> FusionCache.invalidate(User.class, id));
}
```

### 链式数据组装模式（父子表联查）

```java
// listEx: 父表查询 + 子表IN查询 + 原地组装
@GetMapping("/listEx")
public ResponseData<PageList<OrderEx>> listEx(AuthQueryParam param) {
    return dao.list(OrderEx.class, param).onSuccess(orders -> {
        if (orders.isEmpty()) return;
        Object[] ids = orders.stream().map(OrderEx::getId).toArray();
        dao.list(OrderItem.class,
            "SELECT * FROM order_item WHERE order_id IN ("
            + String.join(",", Collections.nCopies(ids.length, "?")) + ")",
            ids
        ).onSuccess(items -> {
            Map<Long, List<OrderItem>> itemMap = items.stream()
                .collect(Collectors.groupingBy(OrderItem::getOrderId));
            orders.forEach(o -> o.setItemList(itemMap.getOrDefault(o.getId(), List.of())));
        });
    });
}
```

### 条件更新 + 日志模式

```java
// 启用/禁用操作
@PostMapping("/enable")
public ResponseData<Integer> enable(long id) {
    AuthServiceHelper.logRef(Product.class, id);
    return dao.queryForObject(Product.class, new AuthIdQueryParam(getSaasId(), id))
        .onSuccess(product -> {
            product.setState(CommonState.ENABLED.getValue());
            product.setModifyDate(SystemClock.nowDate());
            return dao.update(product);
        });
}
```

## DataEntity 接口

> **包路径**：`uw.dao.DataEntity`

实体类实现此接口，配合 `@TableMeta` / `@ColumnMeta` 注解。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `ENTITY_TABLE()` | String | 表名 |
| `ENTITY_NAME()` | String | 实体名称（用于日志） |
| `ENTITY_ID()` | Serializable | 主键值 |
| `GET_UPDATED_INFO()` | DataUpdateInfo | 字段更新信息（差量更新用） |
| `CLEAR_UPDATED_INFO()` | void | 清除更新信息 |

**实体类示例**：
```java
@TableMeta(tableName = "user", tableType = "table")
public class User implements DataEntity {
    @ColumnMeta(columnName = "id", primaryKey = true)
    private Long id;

    @ColumnMeta(columnName = "user_name")
    private String userName;

    @JsonIgnore
    private DataUpdateInfo dataUpdateInfo;

    @Override public String ENTITY_TABLE() { return "user"; }
    @Override public String ENTITY_NAME() { return "用户"; }
    @Override public Serializable ENTITY_ID() { return id; }
    @Override public DataUpdateInfo GET_UPDATED_INFO() { return dataUpdateInfo; }
    @Override public void CLEAR_UPDATED_INFO() { dataUpdateInfo = null; }

    // setter 中记录差量更新信息（只更新非null字段的关键机制）
    public void setUserName(String userName) {
        if (dataUpdateInfo == null) dataUpdateInfo = new DataUpdateInfo();
        dataUpdateInfo.addUpdate("user_name", this.userName, userName);
        this.userName = userName;
    }
}
```

## QueryParam

> **包路径**：`uw.common.dto.QueryParam`

构造：`new XxxQueryParam()` — 继承 `QueryParam<XxxQueryParam>`，用 `@QueryMeta` 注解标注查询字段。

**排序常量**：`SORT_NONE=0` / `SORT_ASC=1` / `SORT_DESC=2`

**链式方法**：`SORT_NAME(String...)` / `SORT_TYPE(int...)` / `SELECT_SQL(String)` / `LIKE_QUERY_ENABLE(boolean)` / `ADD_EXT_COND_SQL(String)` / `ADD_EXT_COND(String, Object)`

**@QueryMeta 注解**：
```java
@QueryMeta(expr = "user_name like ?")     // LIKE 查询
@QueryMeta(expr = "status = ?")           // 等值查询
@QueryMeta(expr = "create_date >= ? and create_date <= ?")  // 范围查询
```

**QueryParam 定义示例**：
```java
public class UserQueryParam extends QueryParam<UserQueryParam> {
    @QueryMeta(expr = "user_name like ?")
    private String userName;

    @QueryMeta(expr = "status = ?")
    private Integer status;

    @QueryMeta(expr = "create_date >= ?")
    private Date startDate;

    @QueryMeta(expr = "create_date <= ?")
    private Date endDate;

    // 允许的排序属性映射
    @Override
    public Map<String, String> ALLOWED_SORT_PROPERTY() {
        Map<String, String> map = new HashMap<>();
        map.put("userName", "user_name");
        map.put("createDate", "create_date");
        return map;
    }
}
```

**Controller 中使用**：`AuthQueryParam` 自动注入 saasId，仅限 Controller 层。Helper 层用原生 SQL。

## BatchUpdateManager

> **包路径**：`uw.dao.BatchUpdateManager`

构造：`dao.getBatchUpdateManager(null)` — 参数为 connName，null 表示默认数据源。

| 方法 | 说明 |
|------|------|
| `setBatchSize(int)` | 设置批量大小（默认100） |
| `getBatchList()` | 获取待执行 SQL 列表（`List<String>`） |
| `submit()` | 提交执行，返回 `Map<String, List<Integer>>` |

## Helper 使用示例

```java
// Helper 风格（纯静态工具类，禁止 @Service/@Component）
public class UserHelper {
    private static final DaoManager dao = DaoManager.getInstance();

    public static ResponseData<User> createUser(User user) {
        // 必须先获取分布式序列ID
        user.setId(dao.getSequenceId(User.class));
        // 必须设置创建时间
        user.setCreateDate(SystemClock.nowDate());
        return dao.save(user);
    }

    public static ResponseData<User> updateUser(User user) {
        // 必须设置修改时间（差量更新只更新非null字段）
        user.setModifyDate(SystemClock.nowDate());
        return dao.update(user);
    }

    public static ResponseData<User> getById(long saasId, long id) {
        return dao.queryForObject(User.class, new AuthIdQueryParam(saasId, id));
    }

    public static ResponseData<PageList<User>> listByStatus(int status) {
        return dao.list(User.class, "SELECT * FROM user WHERE status=?", new Object[]{status});
    }

    public static ResponseData<Integer> updateStatus(long id, int status) {
        return dao.execute("UPDATE user SET status=? WHERE id=?", new Object[]{status, id});
    }
}
```
