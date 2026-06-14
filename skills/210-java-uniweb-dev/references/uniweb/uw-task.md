# uw-task — 分布式任务框架

**Maven 坐标**: `com.umtone:uw-task`

支持定时任务和队列任务的分布式任务框架，依赖 RabbitMQ + Redis。

**配置前缀**: `uw.task`

```yaml
uw:
  task:
    task-project: com.demo.task
    croner-thread-num: 3
    rabbitmq:
      host: 127.0.0.1
      port: 5672
      username: guest
      password: guest
      publisher-confirms: true
      virtual-host: /
    redis:
      database: 0
      host: 127.0.0.1
      port: 6379
      password: password
      lettuce:
        pool:
          max-active: 20
          max-idle: 8
          max-wait: -1ms
          min-idle: 0
      timeout: 30s
```

## AI 决策速查

| 我要做什么 | 用什么                                                                         | 关键约束                                            |
|-----------|-----------------------------------------------------------------------------|-------------------------------------------------|
| 定时任务 | 继承 `TaskCroner`，加 `@Component`                                              | TaskCroner/TaskRunner 是 Spring Bean，与 Helper 不同 |
| 队列任务 | 继承 `TaskRunner<P,R>`，加 `@Component`                                         | 同上                                              |
| 发送到队列 | `TaskFactory.getInstance().sendToQueue(taskData)`                           | Helper 中静态获取 TaskFactory                        |
| 同步执行任务 | `taskFactory.runTask(taskData)`                                             | 阻塞等待结果                                          |
| 构建任务数据 | `new TaskData()/TaskData.builder(TaskClass.class, param).refId(id).build()` | 构造器/Builder 模式                                  |
| 延迟执行 | `TaskData.builder(...).taskDelay(5000).build()`                             | 毫秒                                              |
| 触发重试 | 抛 `TaskPartnerException`                                                    | 第三方接口错误重试                                       |
| 不重试 | 抛 `TaskDataException`                                                       | 数据错误不重试                                         |

## TaskCroner 定时任务

> **包路径**：`uw.task.TaskCroner`

构造：继承 `TaskCroner` 抽象类 + `@Component` — 实现 `runTask`/`initConfig`/`initContact` 三个抽象方法。

**TaskCronerConfig 构造**：`new TaskCronerConfig()` setter 链式配置，或 `TaskCronerConfig.builder(taskName, cron)`

| 属性 | 类型 | 说明 |
|------|------|------|
| taskName | String | 任务名称（必填） |
| taskCron | String | cron 表达式，默认 `*/5 * * * * ?` |
| runType | int | 运行类型（见 TaskCronerConfig 常量） |
| runTarget | String | 运行目标，默认 "default" |
| logLevel | int | 日志级别（见 TASK_LOG_TYPE 常量） |
| logLimitSize | int | 日志大小限制，0=无限制 |
| alertRunTimeout | int | 运行超时告警（秒） |
| alertFailRate | int | 失败率告警阈值 |

**TaskCronerConfig.runType 常量**：

| 常量 | 值 | 说明 |
|------|-----|------|
| RUN_TYPE_DIRECT | 0 | 直接运行 |
| RUN_TYPE_SINGLETON | 1 | 全局单例执行 |

**TaskCronerConfig.logLevel 常量（TASK_LOG_TYPE）**：

| 常量 | 值 | 说明 |
|------|-----|------|
| TASK_LOG_TYPE_NONE | -1 | 不记录日志 |
| TASK_LOG_TYPE_BASE | 0 | 基础信息 |
| TASK_LOG_TYPE_RECORD_PARAM | 1 | 含参数 |
| TASK_LOG_TYPE_RECORD_RESULT | 2 | 含返回 |
| TASK_LOG_TYPE_RECORD_ALL | 3 | 全部（参数+返回） |

**TaskCronerLog 字段**：id / taskId / taskClass / taskParam / runType / runTarget / taskCron / scheduleDate / runDate / finishDate / nextDate / resultData / state

**示例**：
```java
// TaskCroner 是 Spring Bean（由框架管理生命周期），必须加 @Component。
// 这与 Helper（纯静态工具类，禁止 @Component）不同。
@Component
public class OrderTimeoutCheckTask extends TaskCroner {

    @Override
    public String runTask(TaskCronerLog taskCronerLog) throws Exception {
        // 获取任务参数（如果有）
        String taskParam = taskCronerLog.getTaskParam();
        
        // 执行业务逻辑
        int timeoutCount = orderService.checkTimeoutOrders();
        
        // 返回执行结果
        return "检查完成，处理超时订单: " + timeoutCount + " 条";
    }

    @Override
    public TaskCronerConfig initConfig() {
        TaskCronerConfig config = new TaskCronerConfig();
        config.setTaskName("订单超时检查");
        config.setTaskDesc("每5分钟检查一次超时未支付订单");
        config.setTaskCron("0 */5 * * * ?");  // 每5分钟执行一次
        config.setRunType(TaskCronerConfig.RUN_TYPE_SINGLETON);  // 全局单例执行
        config.setLogLevel(TaskCronerConfig.TASK_LOG_TYPE_RECORD_ALL);
        config.setAlertRunTimeout(300);  // 运行超过300秒告警
        return config;
    }

    @Override
    public TaskContact initContact() {
        return TaskContact.builder("运维负责人")
            .email("ops@example.com")
            .mobile("13800138000")
            .build();
    }
}
```

## TaskRunner 队列任务

> **包路径**：`uw.task.TaskRunner`

构造：继承 `TaskRunner<TP, RD>` 抽象类 + `@Component` — 泛型 TP=参数类型，RD=返回类型。

**TaskRunnerConfig 构造**：`new TaskRunnerConfig()` setter 链式配置

| 属性 | 类型 | 说明 |
|------|------|------|
| taskName | String | 任务名称（必填） |
| queueType | int | 队列类型（见 TYPE_QUEUE 常量） |
| consumerNum | int | 消费者数量 |
| prefetchNum | int | 预取数量 |
| rateLimitType | int | 限流类型（见 RATE_LIMIT 常量） |
| rateLimitValue | long | 限流值 |
| rateLimitTime | long | 限流时间窗口（秒） |
| retryTimesByPartner | int | 第三方异常重试次数 |
| retryTimesByProgram | int | 程序异常重试次数 |
| runType | int | 运行模式（见 TaskData 运行模式常量） |
| logLevel | int | 日志级别（见 TASK_LOG_TYPE 常量） |
| logLimitSize | int | 日志大小限制 |
| alertRunTimeout | int | 超时告警（秒） |
| alertFailRate | int | 失败率告警阈值 |

**TaskRunnerConfig.queueType 常量（TYPE_QUEUE）**：

| 常量 | 值 | 说明 |
|------|-----|------|
| TYPE_QUEUE_PROJECT | 0 | 项目级队列 |
| TYPE_QUEUE_PROJECT_PRIORITY | 1 | 项目级优先队列 |
| TYPE_QUEUE_TASK_GROUP | 2 | 任务组队列 |
| TYPE_QUEUE_TASK | 5 | 任务级队列 |

**TaskRunnerConfig.rateLimitType 常量（RATE_LIMIT）**：

| 常量 | 值 | 说明 |
|------|-----|------|
| RATE_LIMIT_NONE | 0 | 不限速 |
| RATE_LIMIT_GLOBAL_TASK | 1 | 全局任务级限速 |
| RATE_LIMIT_GLOBAL | 2 | 全局限速 |

**TaskData 构造**：`TaskData.builder(TaskClass.class, param).refId(id).taskDelay(5000).build()` — Builder 模式

也支持 `new TaskData<TP, RD>()` + setter

**TaskRunner 实现示例**：
```java
// TaskRunner 是 Spring Bean（由框架管理生命周期），必须加 @Component。
@Component
public class OrderNotifyTask extends TaskRunner<OrderNotifyParam, NotifyResult> {
    
    @Autowired
    private NotificationService notificationService;
    
    @Override
    public NotifyResult runTask(TaskData<OrderNotifyParam, NotifyResult> taskData) throws Exception {
        OrderNotifyParam param = taskData.getTaskParam();
        
        // 执行业务逻辑
        boolean success = notificationService.sendNotify(param.getUserId(), param.getNotifyType());
        
        NotifyResult result = new NotifyResult();
        result.setSuccess(success);
        result.setMessage(success ? "发送成功" : "发送失败");
        return result;
    }

    @Override
    public TaskRunnerConfig initConfig() {
        TaskRunnerConfig config = new TaskRunnerConfig();
        config.setTaskName("订单通知任务");
        config.setTaskDesc("发送订单状态变更通知给用户");
        config.setQueueType(TaskRunnerConfig.TYPE_QUEUE_PROJECT);
        config.setConsumerNum(5);          // 5个消费者
        config.setPrefetchNum(1);          // 每次预取1条
        config.setRateLimitType(TaskRunnerConfig.RATE_LIMIT_GLOBAL_TASK);  // 全局任务限速
        config.setRateLimitValue(100);     // 限速100次
        config.setRateLimitTime(60);       // 每60秒
        config.setRetryTimesByPartner(3);  // 第三方错误重试3次
        config.setLogLevel(TaskRunnerConfig.TASK_LOG_TYPE_RECORD_ALL);
        return config;
    }

    @Override
    public TaskContact initContact() {
        return TaskContact.builder("通知服务负责人").email("notify@example.com").build();
    }
}
```

**异常处理示例**：
```java
@Override
public NotifyResult runTask(TaskData<OrderNotifyParam, NotifyResult> taskData) throws Exception {
    OrderNotifyParam param = taskData.getTaskParam();
    try {
        Response response = thirdPartyApi.send(param);
        if (response.getCode() == 429) {
            throw new TaskPartnerException("第三方接口限流");  // 会重试
        }
        if (response.getCode() == 400) {
            throw new TaskDataException("参数错误: " + response.getMessage());  // 不重试
        }
        return new NotifyResult(true, "成功");
    } catch (IOException e) {
        throw new TaskPartnerException("网络异常", e);  // 会重试
    }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| taskParam | TP | 任务参数 |
| resultData | RD | 结果数据 |
| state | int | 任务状态 |
| runType | int | 运行模式 |
| taskDelay | long | 延迟时间（毫秒） |
| refId | long | 关联ID |
| refSubId | long | 关联子ID |
| refTag | String | 关联TAG |
| ranTimes | int | 已执行次数 |
| errorInfo | String | 错误信息 |

**TaskData 状态常量**：STATE_UNKNOWN=0 / STATE_SUCCESS=1 / STATE_FAIL_PROGRAM=2 / STATE_FAIL_CONFIG=3 / STATE_FAIL_PARTNER=4 / STATE_FAIL_DATA=5

**TaskData 运行模式**：

| 常量 | 值 | 说明 |
|------|-----|------|
| RUN_TYPE_LOCAL | 1 | 本地执行 |
| RUN_TYPE_GLOBAL | 3 | 全局执行 |
| RUN_TYPE_GLOBAL_RPC | 5 | 全局RPC执行 |
| RUN_TYPE_AUTO_RPC | 6 | 自动选择本地或远程 |

## TaskFactory

> **包路径**：`uw.task.TaskFactory`

构造：`TaskFactory.getInstance()` 静态获取

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `sendToQueue(TaskData)` | void | 发送到队列（异步） |
| `sendToLocalQueue(TaskData)` | void | 发送到本地队列 |
| `runQueue(TaskData)` | void | 本地优先执行（线程池满转队列） |
| `runTask(TaskData)` | `TaskData<TP, RD>` | 同步执行（阻塞等待） |
| `runTaskLocal(TaskData)` | `TaskData<TP, RD>` | 本地同步执行 |
| `runTaskAsync(TaskData)` | `Future<TaskData<TP, RD>>` | 异步执行 |
| `getQueueInfo(queueName)` | int[] | 获取队列信息 [消息数, 消费者数] |
| `purgeQueue(queueName)` | int | 清除队列 |

## 异常处理

| 异常类 | 触发重试 | 使用场景 |
|--------|---------|---------|
| `TaskPartnerException(msg)` | ✅ 会重试 | 第三方接口限流、网络异常 |
| `TaskDataException(msg)` | ❌ 不重试 | 参数错误、数据格式错误 |

## TaskContact

> **包路径**：`uw.task.TaskContact`

构造：`TaskContact.builder(contactName).email("...").mobile("...").build()` — Builder 模式

| 字段 | 类型 | 说明 |
|------|------|------|
| contactName | String | 联系人姓名 |
| mobile | String | 联系电话 |
| email | String | 联系邮箱 |
| wechat | String | 微信 |
| notifyUrl | String | 通知链接（钉钉/微信等） |

## Helper 调用示例

```java
public class OrderHelper {
    private static final TaskFactory taskFactory = TaskFactory.getInstance();

    public static void sendOrderNotify(long orderId, long userId) {
        OrderNotifyParam param = new OrderNotifyParam();
        param.setOrderId(orderId);
        param.setUserId(userId);
        param.setNotifyType("ORDER_CREATED");

        TaskData<OrderNotifyParam, NotifyResult> taskData = TaskData
            .builder(OrderNotifyTask.class, param)
            .refId(orderId)           // 设置关联ID
            .refTag("ORDER_NOTIFY")   // 设置关联TAG
            .taskDelay(5000)          // 延迟5秒执行
            .build();
        
        // 发送到队列
        taskFactory.sendToQueue(taskData);
    }

    public static NotifyResult syncNotify(long orderId, long userId) {
        OrderNotifyParam param = new OrderNotifyParam();
        param.setOrderId(orderId);
        param.setUserId(userId);
        param.setNotifyType("ORDER_URGENT");

        TaskData<OrderNotifyParam, NotifyResult> taskData = TaskData
            .builder(OrderNotifyTask.class, param)
            .runType(TaskData.RUN_TYPE_AUTO_RPC)  // 自动选择本地或远程
            .build();

        TaskData<OrderNotifyParam, NotifyResult> result = taskFactory.runTask(taskData);
        if (result.getState() == TaskData.STATE_SUCCESS) {
            return result.getResultData();
        }
        throw new RuntimeException("通知失败: " + result.getErrorInfo());
    }
}
```
