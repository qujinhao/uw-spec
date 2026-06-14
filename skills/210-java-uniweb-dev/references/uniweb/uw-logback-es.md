# uw-logback-es — Logback ES Appender

**Maven 坐标**: `com.umtone:uw-logback-es`

无需 Logstash，直接将日志批量发送到 Elasticsearch。基于 Logback 的自定义 Appender，支持批量提交、JMX监控和异常堆栈压缩。

**配置方式**: 在 `logback-spring.xml` 中配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE configuration>
<configuration>
    <springProfile name="prod">
        <appender name="ES" class="uw.logback.es.appender.ElasticSearchAppender">
            <!-- ES服务器地址 -->
            <esServer>http://localhost:9200</esServer>
            <!-- 索引名称 -->
            <esIndex>my-app-logs</esIndex>
            <!-- 索引后缀模式（支持时间格式） -->
            <esIndexSuffix>_yyyy-MM-dd</esIndexSuffix>
            <!-- ES用户名（如启用认证） -->
            <esUsername>elastic</esUsername>
            <!-- ES密码 -->
            <esPassword>changeme</esPassword>
            <!-- 应用名称 -->
            <appInfo>${APP_NAME:-unknown}</appInfo>
            <!-- 主机名 -->
            <appHost>${HOSTNAME:-unknown}</appHost>
            <!-- 批量提交最大线程数 -->
            <maxBatchThreads>5</maxBatchThreads>
            <!-- 批量线程队列大小 -->
            <maxBatchQueueSize>20</maxBatchQueueSize>
            <!-- 批量最大字节数（KB） -->
            <maxKiloBytesOfBatch>8192</maxKiloBytesOfBatch>
            <!-- 最大刷新间隔（秒） -->
            <maxFlushInSeconds>10</maxFlushInSeconds>
            <!-- 异常堆栈最大深度 -->
            <maxDepthPerThrowable>20</maxDepthPerThrowable>
            <!-- 排除的异常关键字（逗号分隔） -->
            <excludeThrowableKeys>java.base,org.spring,jakarta</excludeThrowableKeys>
            <!-- 开启JMX监控 -->
            <jmxMonitoring>true</jmxMonitoring>
        </appender>
        <root level="INFO">
            <appender-ref ref="ES"/>
        </root>
    </springProfile>
</configuration>
```

