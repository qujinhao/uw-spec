# uw-log-es — Elasticsearch 日志客户端

**Maven 坐标**: `com.umtone:uw-log-es`

**配置前缀**: `uw.log.es`

```yaml
uw:
  log:
    es:
      server: http://localhost:9200
      username: admin
      password: admin
```

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 获取实例 | `LogClient.getInstance()` | 静态获取 |
| 注册日志类型 | `logClient.regLogObject(Class)` | 必须在 static 块中完成 |
| 自定义索引名 | `logClient.regLogObjectWithIndexName(Class, index)` | — |
| 写入单条日志 | `logClient.log(logObject)` | 日志对象须继承 LogBaseVo |
| 批量写入 | `logClient.bulkLog(List)` | — |
| DSL查询 | `logClient.dslQuery(Class, dsl)` | 返回 SearchResponse |
| SQL转DSL | `logClient.translateSqlToDsl(sql, start, size, trueCount)` | — |
| 大数据量查询 | scrollQueryOpen → scrollQueryNext → scrollQueryClose | 必须关闭 scroll |
| 聚合值提取 | `LogClient.getAggValue(aggMap, aggName)` | 静态工具方法 |

## LogClient 方法签名

> **包路径**：`uw.log.es.LogClient`

构造：`LogClient.getInstance()` 静态单例

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `regLogObject(Class)` | void | 注册日志类型（类名作索引） |
| `regLogObjectWithIndexName(Class, index)` | void | 自定义索引名 |
| `regLogObjectWithIndexPattern(Class, indexPattern)` | void | 自定义索引模式 |
| `regLogObjectWithIndexNameAndPattern(Class, index, indexPattern)` | void | 自定义索引名+模式 |
| `getRawIndexName(Class)` | String | 原始索引名 |
| `getQuotedRawIndexName(Class)` | String | 带引号的原始索引名 |
| `getQueryIndexName(Class)` | String | 查询索引名 |
| `getQuotedQueryIndexName(Class)` | String | 带引号的查询索引名 |
| `log(LogBaseVo)` | void | 单条写入 |
| `bulkLog(List<LogBaseVo>)` | void | 批量写入 |
| `dslQuery(Class, String dsl)` | `SearchResponse<T>` | DSL 查询 |
| `dslQuery(Class, String index, String dsl)` | `SearchResponse<T>` | 指定索引 DSL 查询 |
| `translateSqlToDsl(sql, start, size, trueCount)` | String | SQL 转 DSL |
| `scrollQueryOpen(Class, index, expireSeconds, dsl)` | `ScrollResponse<T>` | 开启 scroll 查询 |
| `scrollQueryNext(Class, index, scrollId, expireSeconds)` | `ScrollResponse<T>` | 获取下一批 |
| `scrollQueryClose(scrollId, index)` | `DeleteScrollResponse` | 关闭 scroll |

**静态工具方法**：`mapQueryResponseToPageList(response, start, size)` / `getAggValue(aggMap, name)` / `convertAggBucketListMap(aggMap)` / `convertAggBucketAggBucketFlatMap(aggMap)` / `convertAggBucketFlatMap(aggMap)`

## LogBaseVo

> **包路径**：`uw.log.es.LogBaseVo`

构造：继承此类，添加业务字段。日志对象须继承 LogBaseVo。

| 字段 | 类型 | 说明 |
|------|------|------|
| logLevel | int | 日志级别：-1不记录，0普通，1详细 |
| logDate | Date | 日志时间 |

## SearchResponse

> **包路径**：`uw.log.es.SearchResponse`

| 字段 | 类型 | 说明 |
|------|------|------|
| hitResponse | `HitResponse<T>` | 命中结果 |
| aggregations | `Map<String, Aggregation>` | 聚合结果 |

**HitResponse**：total(Long) / hits(List<Hit<T>>) — 每个 Hit 含 id(String) + source(T)

**Aggregation**：value(double) / buckets(List<Bucket>) / subAggregations — 每个 Bucket 含 key(String) + docCount(long)

## ScrollResponse

> **包路径**：`uw.log.es.ScrollResponse`

| 字段 | 类型 | 说明 |
|------|------|------|
| scrollId | String | Scroll ID |
| dataList | List<T> | 数据列表 |
| total | long | 总数 |
| hasMore | boolean | 是否有更多数据 |

## PageList

| 字段 | 类型 | 说明 |
|------|------|------|
| data | List<T> | 数据列表 |
| startIndex | int | 起始位置 |
| pageSize | int | 每页大小 |
| total | long | 总数 |

## Helper 使用示例

```java
public class AccessLogHelper {
    private static final LogClient logClient = LogClient.getInstance();

    @Data
    public static class UserAccessLog extends LogBaseVo {
        private Long userId;
        private String action;
        private String ip;
        private Date accessTime;
        private String result;
    }

    static {
        logClient.regLogObject(UserAccessLog.class);
    }

    // 写入单条日志
    public static void recordAccess(long userId, String action, String ip, String result) {
        UserAccessLog log = new UserAccessLog();
        log.setLogLevel(0);
        log.setLogDate(new Date());
        log.setUserId(userId);
        log.setAction(action);
        log.setIp(ip);
        log.setResult(result);
        logClient.log(log);
    }

    // 批量写入
    public static void batchRecord(List<UserAccessLog> logs) {
        logClient.bulkLog(logs);
    }

    // DSL 查询
    public static PageList<UserAccessLog> queryLogs(long userId, int page, int size) {
        String dsl = "{\"query\":{\"term\":{\"userId\":" + userId + "}},\"sort\":[{\"accessTime\":\"desc\"}],\"from\":" + (page - 1) * size + ",\"size\":" + size + "}";
        SearchResponse<UserAccessLog> response = logClient.dslQuery(UserAccessLog.class, dsl);
        return LogClient.mapQueryResponseToPageList(response, (page - 1) * size, size);
    }

    // Scroll 查询（大数据量导出）
    public static void exportAllLogs(Date startDate, Date endDate) {
        String dsl = "{\"query\":{\"range\":{\"accessTime\":{\"gte\":\"" + startDate.getTime() + "\",\"lte\":\"" + endDate.getTime() + "\"}}},\"size\":1000}";
        String index = logClient.getQueryIndexName(UserAccessLog.class);
        ScrollResponse<UserAccessLog> scroll = logClient.scrollQueryOpen(UserAccessLog.class, index, 60, dsl);
        try {
            while (scroll != null && !scroll.getDataList().isEmpty()) {
                processLogs(scroll.getDataList());
                if (scroll.isHasMore()) {
                    scroll = logClient.scrollQueryNext(UserAccessLog.class, index, scroll.getScrollId(), 60);
                } else {
                    break;
                }
            }
        } finally {
            if (scroll != null) {
                logClient.scrollQueryClose(scroll.getScrollId(), index);
            }
        }
    }
}
```
