# uw-cache — 缓存管理

**Maven 坐标**: `com.umtone:uw-cache`

基于 Caffeine 和 Redis 的融合缓存类库。

**配置前缀**: `uw.cache.redis`

```yaml
uw:
  cache:
    redis:
      database: 9
      host: 192.168.88.21
      port: 6380
      password: redispasswd
      lettuce:
        pool:
          max-active: 100
          max-idle: 8
          max-wait: 5000ms
          min-idle: 1
      timeout: 30s
```

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 高频实体详情缓存 | `FusionCache`（本地+Redis融合） | 必须在 `static {}` 块中 config + CacheDataLoader |
| 临时数据/列表缓存 | `GlobalCache`（纯Redis） | 不需要 static 初始化，行内 CacheDataLoader |
| 分布式锁 | `GlobalLocker.tryLock/keepLock/unlock` | stamp > 0 才持有锁，finally 中 unlock |
| 高性能计数器 | `FusionCounter`（本地+Redis融合） | 必须 static config，支持回写数据库 |
| 纯Redis计数器 | `GlobalCounter` | increment/decrement/get/set/delete |
| 去重/随机抽取 | `GlobalHashSet` | add/remove/contains/random/pop |
| 延迟任务/定时触发 | `GlobalSortedSet` | 按score范围查询和删除 |
| 缓存失效（单key） | `FusionCache.invalidate(Class, key)` | 没有 invalidateAll，逐个失效 |
| 缓存失效（GlobalCache） | `GlobalCache.invalidate(cacheName, key)` | 方法名是 invalidate 不是 delete |
| 缓存列表数据 | 缓存 `ArrayList<Entity>` | 禁止缓存 PageList（Kryo序列化异常） |
| 判断缓存是否存在 | FusionCache: `getIfPresent(Class, key)`；GlobalCache: `containsKey(cacheName, key)` | GlobalCache 没有 getIfPresent |

**CacheDataLoader 约束**：是抽象类不是函数式接口，**不能用 lambda**，必须 `new CacheDataLoader<K,V>(){...}`。

**选型决策**：单条实体详情用 FusionCache；列表、临时数据用 GlobalCache。

**性能注意**：Caffeine 设过期时间后性能劣化 200 倍，建议仅设 Redis 过期时间。Kryo 序列化必须使用具体实现类（ArrayList/LinkedHashMap/HashSet），不能用接口类型。

> 完整陷阱列表见 [dev-standards.md](dev-standards.md)「AI Coding 禁忌清单」。

## FusionCache（本地 Caffeine + 全局 Redis）

> **包路径**：`uw.cache.FusionCache`

**初始化**：必须在 Helper 的 `static {}` 块中完成 `FusionCache.config()`。

| 方法 | 说明 |
|------|------|
| `config(Config, CacheDataLoader)` | 配置缓存+数据加载器（static块中调用） |
| `put(Class, key, value)` | 存入数据 |
| `put(Class, key, value, expireMillis)` | 存入+过期时间 |
| `putAll(Class, Map)` | 批量存入 |
| `get(Class, key)` | 获取（带自动加载） |
| `getIfPresent(Class, key)` | 获取（不触发加载） |
| `invalidate(Class, key)` | 按 key 失效（没有 invalidateAll） |

**FusionCache.Config 构造**：`new FusionCache.Config(Class, localCacheMaxNum, cacheExpireMillis)` — 位置参数构造。也支持 `new FusionCache.Config(String cacheName, localCacheMaxNum, cacheExpireMillis)`

| 属性 | 类型 | 说明 |
|------|------|------|
| cacheName / entityClass | Class 或 String | 缓存名称 |
| localCacheMaxNum | long | 本地缓存最大数量（Caffeine） |
| cacheExpireMillis | long | 缓存过期时间（毫秒） |
| globalCache | boolean | 是否启用全局缓存（Redis），默认 true |
| nullProtectMillis | long | 空值保护时间（防缓存穿透） |

## GlobalCache（纯 Redis）

> **包路径**：`uw.cache.GlobalCache`

构造：`GlobalCache.get(cacheName, key, CacheDataLoader, expireMillis)` — 不需要 static 初始化。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `put(Class, key, value, expireMillis)` | `CacheValueWrapper<V>` | 存入+过期时间 |
| `put(String cacheName, key, value, expireMillis)` | `CacheValueWrapper<V>` | 存入（自定义缓存名） |
| `get(Class, key, Class<V>)` | `CacheValueWrapper<V>` | 获取（不触发加载） |
| `get(Class, key, CacheDataLoader, expireMillis)` | V | 获取+自动加载（加 JVM 锁防击穿） |
| `get(String cacheName, key, CacheDataLoader, expireMillis)` | V | 获取+自动加载（自定义缓存名） |
| `containsKey(Class, key)` | boolean | 判断是否存在 |
| `invalidate(Class, key)` | boolean | 失效（方法名不是 delete） |
| `invalidate(String cacheName, key)` | boolean | 失效（自定义缓存名） |

## GlobalLocker（分布式锁）

> **包路径**：`uw.cache.GlobalLocker`

构造：`GlobalLocker.tryLock(Class, lockerId, lockTimeMillis)` — 返回 stamp（>0 表示获锁成功）。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `tryLock(Class, Object, long)` | long | 尝试加锁，返回 stamp |
| `keepLock(Class, Object, stamp, long)` | boolean | 续期锁 |
| `unlock(Class, Object, stamp)` | boolean | 释放锁 |

## FusionCounter（本地+全局融合计数器）

> **包路径**：`uw.cache.FusionCounter`

基于 AtomicLong 和 Redis 的复合计数器。本地高频写入，定时同步到 Redis。支持回写数据库。

**初始化**：在 Helper 的 `static {}` 块中 config。

| 方法 | 说明 |
|------|------|
| `config(Class, syncGlobalMillis)` | 配置基本计数器（同步间隔） |
| `config(String counterType, syncGlobalMillis)` | 配置基本计数器（String 类型名） |
| `config(Class, syncGlobalMillis, writeBackMillis, BiConsumer)` | 配置带回写的计数器（定期写入数据库） |
| `increment(Class, counterId)` | +1 |
| `increment(Class, counterId, long num)` | +N |
| `decrement(Class, counterId)` | -1 |
| `decrement(Class, counterId, long num)` | -N |

```java
static {
    // 基本计数器：每60秒同步到Redis
    FusionCounter.config(User.class, 60_000L);

    // 带回写的计数器：每60秒同步Redis，每300秒回写数据库
    FusionCounter.config(Order.class, 60_000L, 300_000L, (orderId, count) -> {
        dao.execute("UPDATE orders SET view_count=? WHERE id=?", new Object[]{count, orderId});
    });
}

// 使用
FusionCounter.increment(User.class, userId);
FusionCounter.increment(User.class, userId, 5);
```

## GlobalCounter（纯 Redis 计数器）

> **包路径**：`uw.cache.GlobalCounter`

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `increment(Class, counterId, long)` | long | 增加计数 |
| `decrement(Class, counterId, long)` | long | 减少计数 |
| `set(Class, counterId, long)` | void | 设置数值 |
| `setIfAbsent(Class, counterId, long)` | boolean | 仅在不存在时设置（初始化） |
| `get(Class, counterId)` | long | 获取数值 |
| `delete(Class, counterId)` | boolean | 删除计数器 |

## GlobalHashSet（Redis Set）

> **包路径**：`uw.cache.GlobalHashSet`

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `add(String setName, Object)` | boolean | 添加元素 |
| `remove(String setName, Object)` | long | 移除元素 |
| `size(String setName)` | long | 集合大小 |
| `contains(String setName, Object)` | boolean | 是否包含 |
| `random(String setName, Class<T>)` | T | 随机获取一个元素 |
| `random(String setName, long count, Class<T>)` | Set\<T\> | 随机获取多个元素 |
| `pop(String setName, Class<T>)` | T | 随机弹出（删除并返回） |
| `pop(String setName, long count, Class<T>)` | Set\<T\> | 随机弹出多个 |

## GlobalSortedSet（Redis ZSet，延迟任务场景）

> **包路径**：`uw.cache.GlobalSortedSet`

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `add(String setName, Object data, double score)` | boolean | 添加元素（score 通常为时间戳） |
| `remove(String setName, Object)` | long | 移除元素 |
| `remove(String setName, Object...)` | long | 批量移除 |
| `removeRangeByScore(String, double min, double max)` | long | 按分数范围删除 |
| `size(String setName)` | long | 集合大小 |
| `listRangeByScore(String, Class<T>, double min, double max)` | Set\<T\> | 按分数范围查询 |

```java
// 延迟任务示例：添加一个5分钟后执行的任务
GlobalSortedSet.add("delayedTasks", taskId, SystemClock.now() + 300_000L);

// 查询已到期的任务
Set<Long> readyTasks = GlobalSortedSet.listRangeByScore("delayedTasks", Long.class, 0, SystemClock.now());

// 删除已处理的到期任务
GlobalSortedSet.removeRangeByScore("delayedTasks", 0, SystemClock.now());
```

## Helper 使用示例

```java
public class UserHelper {
    private static final DaoManager dao = DaoManager.getInstance();

    // FusionCache 必须在 static 块中初始化
    static {
        FusionCache.config(new FusionCache.Config(
            User.class, 1000, 3600_000L
        ), new CacheDataLoader<Long, User>() {
            @Override
            public User load(Long userId) {
                return dao.load(User.class, userId).getData();
            }
        });
    }

    public static User getUser(long userId) {
        return FusionCache.get(User.class, userId);
    }

    public static void updateUser(User user) {
        dao.update(user);
        FusionCache.invalidate(User.class, user.getId());
    }

    // GlobalCache 使用（行内 CacheDataLoader，不需要 static 初始化）
    public static List<Product> listProducts(long saasId) {
        return GlobalCache.get("productList", saasId, new CacheDataLoader<Long, List<Product>>() {
            @Override
            public List<Product> load(Long sid) {
                return dao.list(Product.class, "SELECT * FROM product WHERE saas_id=?", new Object[]{sid}).getData();
            }
        }, 1800_000L);
    }

    // 分布式锁使用
    public static void processOrder(long orderId) {
        long stamp = GlobalLocker.tryLock(Order.class, orderId, 30000L);
        if (stamp > 0) {
            try {
                process(orderId);
                GlobalLocker.keepLock(Order.class, orderId, stamp, 30000L);
            } finally {
                GlobalLocker.unlock(Order.class, orderId, stamp);
            }
        }
    }
}
```

**重要注意事项**：
- Caffeine 设定过期时间后性能劣化 200 倍，建议仅设 Redis 过期时间
- Kryo 序列化**必须使用具体实现类**，不能使用接口类型（如 List/Map/Set），必须传 ArrayList/LinkedHashMap/HashSet 等

> 缓存使用的常见陷阱（CacheDataLoader 抽象类、GlobalCache 无 getIfPresent、FusionCache vs GlobalCache 选型）见 [dev-standards.md](dev-standards.md)「缓存使用常见陷阱」。
