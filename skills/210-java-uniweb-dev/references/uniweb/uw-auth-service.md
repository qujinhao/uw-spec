# uw-auth-service — 认证服务端

**Maven 坐标**: `com.umtone:uw-auth-service`

为 Web 应用提供统一认证、授权和日志记录功能。包含全局异常处理、全局响应包裹、权限校验拦截器、操作日志自动记录等核心机制。

**配置前缀**: `uw.auth.service`

```yaml
uw:
  auth:
    service:
      auth-center-host: http://uw-auth-center
      app-label: 我的应用
```

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 声明Controller权限 | `@MscPermDeclare(user, auth, log)` | 类级别+方法级别 |
| 获取当前用户ID | `AuthServiceHelper.getUserId()` | 静态方法 |
| 获取saasId | `AuthServiceHelper.getSaasId()` | 静态方法 |
| 获取完整Token | `AuthServiceHelper.getContextToken()` | 返回 AuthTokenData |
| 生成匿名Token | `AuthServiceHelper.genAnonymousToken(saasId, mchId)` | — |
| 使Token失效 | `AuthServiceHelper.invalidToken(data)` | — |
| 记录业务日志 | `AuthServiceHelper.logRef()` / `logInfo()` | 依赖Web环境，绝大多数场景 |
| 记录系统日志 | `AuthServiceHelper.logSysInfo(...)` | 不依赖Web环境，定时任务/RPC回调 |
| 获取RPC实例 | `AuthServiceHelper.getAuthServiceRpc()` | 用户管理/权限管理 |
| 跳过响应包裹 | `@ResponseAdviceIgnore` | 类或方法级别 |

## GlobalResponseAdvice — 全局响应包裹

> **包路径**：`uw.auth.service.advice.GlobalResponseAdvice`

**这是框架最核心的机制之一。** 所有 Controller 返回值自动包裹为 `ResponseData`，开发者无需手动包装。

**行为**：

| 返回类型 | 自动包裹为 |
|---------|-----------|
| `null` | `ResponseData.warn()` |
| 非 ResponseData 对象 | `ResponseData.success(body)` |
| 已是 ResponseData | 直接透传，记录日志 |
| String 类型 | 先序列化 ResponseData 为 JSON 字符串（兼容 Spring MVC） |
| ResponseEntity（Spring 错误） | 自动转为 `ResponseData.errorCode(...)` |

**操作日志记录**：在包裹响应时，自动将 responseState / responseCode / responseMsg 写入 `MscActionLog`，配合 `ActionLog` 注解实现全自动日志。

**跳过包裹**：在类或方法上添加 `@ResponseAdviceIgnore`（`uw.auth.service.annotation.ResponseAdviceIgnore`）。

```java
// 正常写法：直接返回业务对象，框架自动包裹
@GetMapping("/info")
public UserInfo info() {
    return userInfo;  // 自动包裹为 ResponseData.success(userInfo)
}

// 跳过包裹（如文件下载等场景）
@GetMapping("/download")
@ResponseAdviceIgnore
public void download(HttpServletResponse response) { ... }
```

## GlobalExceptionAdvice — 全局异常处理

> **包路径**：`uw.auth.service.advice.GlobalExceptionAdvice`

**所有未捕获的异常自动转为 ResponseData 错误响应**，开发者无需在 Controller 中 try-catch。

**异常 → HTTP 状态码映射**：

| 异常类型 | HTTP 状态码 | 说明 |
|---------|------------|------|
| `TokenInvalidException` | 401 | Token 无效/被踢出 |
| `TokenExpiredException` | 419（自定义） | Token 过期 |
| `TokenPermException` | 403（自定义） | 权限不足 |
| `TokenPayException` | 402（自定义） | 付费功能未开通 |
| `TokenServiceException` | 503（自定义） | 服务不可用 |
| `TokenSudoException` | 426（自定义） | 需要超级权限 |
| `ErrorResponse`（Spring） | 按 statusCode | Spring 内置错误 |
| `IOException` | — | 客户端断开，不返回错误 |
| 其他异常 | 500 | 内部错误，打印完整堆栈 |

> 所有异常类在 `uw.auth.service.exception` 包下。

```java
// 无需 try-catch，GlobalExceptionAdvice 自动处理
@PostMapping("/save")
public ResponseData<User> save(@RequestBody User user) {
    return userService.save(user);
    // 如果抛出异常，GlobalExceptionAdvice 自动转为 ResponseData.error(...)
}
```

## @MscPermDeclare 权限声明注解

> **包路径**：`uw.auth.service.annotation.MscPermDeclare`

```java
@MscPermDeclare(
    user = UserType.ADMIN,
    auth = AuthType.PERM,
    log = ActionLog.ALL
)
```

### UserType — 用户类型

> **包路径**：`uw.auth.service.constant.UserType`

| 类型 | 值 | 说明 | URL路径 |
|------|-----|------|---------|
| ANY | 0 | 任意用户 | `/open/*` |
| GUEST | 1 | C端访客 | `/guest/*` |
| RPC | 10 | 内部RPC | `/rpc/*` |
| ROOT | 100 | 超级管理员（强制MFA） | `/root/*` |
| OPS | 110 | 开发运维（强制MFA） | `/ops/*` |
| ADMIN | 200 | 平台管理员 | `/admin/*` |
| SAAS | 300 | SAAS运营商 | `/saas/*` |
| MCH | 310 | SAAS商户 | `/mch/*` |

### AuthType — 授权类型

> **包路径**：`uw.auth.service.constant.AuthType`

| 类型 | 值 | 说明 |
|------|-----|------|
| NONE | 0 | 不验证（公开接口） |
| TEMP | 1 | 临时授权（MFA登录前） |
| USER | 2 | 仅验证用户类型 |
| PERM | 3 | 验证类型+权限（注册为菜单） |
| SUDO | 6 | 超级权限（注册为菜单） |

### ActionLog — 日志级别

> **包路径**：`uw.auth.service.constant.ActionLog`

| 类型 | 值 | 说明 |
|------|-----|------|
| NONE | -1 | 不记录日志 |
| BASE | 0 | 记录基础信息，仅包含IP,请求方法、路径、状态码、响应时间 |
| REQUEST | 1 | 仅记录请求日志 |
| RESPONSE | 2 | 仅记录响应日志 |
| ALL | 3 | 记录请求和响应日志 |
| CRIT | 9 | 记录全部数据,同时使用AuthCriticalLogStorage记录到关键存储器 |

### 使用范例

```java
// 示例1：Controller 类级别声明
@RestController
@RequestMapping("/admin/user")
@MscPermDeclare(name = "用户管理", user = UserType.ADMIN, auth = AuthType.PERM)
public class UserController {

    // 示例2：方法级别声明（继承类配置，可覆盖）
    @GetMapping("/list")
    @MscPermDeclare(name = "用户列表", auth = AuthType.PERM, log = ActionLog.REQUEST)
    public ResponseData<PageList<User>> list(AuthQueryParam param) {
        return userService.list(param);
    }

    // 示例3：关键操作记录完整日志
    @PostMapping("/save")
    @MscPermDeclare(name = "保存用户", auth = AuthType.PERM, log = ActionLog.ALL)
    public ResponseData<User> save(@RequestBody User user) {
        return userService.save(user);
    }

    // 示例4：不验证权限（仅用于特殊场景）
    @GetMapping("/public/info")
    @MscPermDeclare(user = UserType.ANY, auth = AuthType.NONE)
    public ResponseData<String> publicInfo() {
        return ResponseData.success("公开信息");
    }
}
```

**一级菜单权限声明**（每个模块一个）：
```java
@RestController
public class $PackageInfo$ {
    @MscPermDeclare(user = UserType.ADMIN)
    @Operation(summary = "订单管理模块", description = "订单管理模块")
    @GetMapping("/admin/order")
    public void info() {}
}
```

## AuthServiceHelper 方法签名

> **包路径**：`uw.auth.service.AuthServiceHelper`

全部静态方法。使用 ThreadLocal 管理当前请求的 Token 和日志上下文。内部使用 Caffeine 按 UserType 分层缓存 Token，每个 Token 按自身 expireAt 独立过期。

### 当前用户信息

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getContextToken()` | AuthTokenData | 获取完整Token数据 |
| `getUserId()` | long | 当前用户ID（无上下文返回 -1） |
| `getUserName()` | String | 登录名 |
| `getRealName()` | String | 真实姓名 |
| `getNickName()` | String | 昵称 |
| `getMobile()` | String | 手机号 |
| `getEmail()` | String | 邮箱 |
| `getSaasId()` | long | SAAS ID |
| `getMchId()` | long | 商户ID |
| `getGroupId()` | long | 用户组ID |
| `getUserType()` | int | 用户类型 |
| `getUserGrade()` | int | 用户等级 |
| `getLoginIp()` | String | 登录IP |
| `getRemoteIp()` | String | 远程IP（考虑代理） |
| `getTokenType()` | int | 当前Token类型（Access/Refresh） |

### 应用信息

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getAppId()` | long | 当前应用ID |
| `getAppLabel()` | String | 应用标签 |
| `getAppName()` | String | 应用名称 |
| `getAppVersion()` | String | 应用版本 |
| `getAppHost()` | String | 应用主机 |
| `getAppPort()` | int | 应用端口 |
| `getAppInfo()` | String | `appName:appVersion` |
| `getAppHostInfo()` | String | `appName:appVersion/appHost:appPort` |
| `getAppPermMap()` | `Map<String, Integer>` | 当前应用权限Map |

### Token管理

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `invalidToken(InvalidTokenData)` | void | 使Token失效（从缓存清除+加入黑名单） |
| `genAnonymousToken(saasId, mchId)` | String | 生成匿名Token（ANY类型） |
| `destroyContextToken()` | void | 主动销毁上下文Token（防内存泄漏） |

### 操作日志机制

**日志自动记录流程**（由框架完成，开发者无需关心）：

1. **请求进入** → `AuthServiceFilter` 根据 `@MscPermDeclare(log=...)` 创建 `MscActionLog`，设置用户信息/IP/API信息
2. **Controller/Helper 执行** → 开发者通过 `logRef()` / `logInfo()` 设置业务类型、业务ID、业务日志
3. **响应输出** → `GlobalResponseAdvice` 自动写入 responseState/responseCode/responseMsg
4. **请求结束** → `AuthServiceFilter.finally` 自动发送日志到 ES，CRIT 级别同时写入数据库

> 开发者只需在关键操作处调用 `logRef()` / `logInfo()`，其余全部由框架自动完成。

### logRef — 绑定业务引用（最常用）

> 在 Controller/Helper 中绑定业务类型和业务ID到当前请求日志。绝大多数场景使用此方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `logRef(Class<?> bizTypeClass)` | MscActionLog | 绑定业务类型（Class） |
| `logRef(String bizType)` | MscActionLog | 绑定业务类型（String） |
| `logRef(Class<?> bizTypeClass, Serializable bizId)` | MscActionLog | 绑定业务类型+业务ID |
| `logRef(String bizType, Serializable bizId)` | MscActionLog | 绑定业务类型+业务ID |

```java
// Controller 中启用产品时记录业务引用
public ResponseData<Integer> enable(long id) {
    AuthServiceHelper.logRef(Product.class, id);  // 绑定业务类型+ID
    return dao.queryForObject(Product.class, new AuthIdQueryParam(getSaasId(), id))
        .onSuccess(product -> {
            product.setState(CommonState.ENABLED.getValue());
            product.setModifyDate(SystemClock.nowDate());
            return dao.update(product);
        });
}
```

### logInfo — 追加业务日志

> 在当前请求日志上追加业务日志描述。可多次调用，日志自动追加（换行分隔）。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `logInfo(String bizLog)` | MscActionLog | 仅追加日志 |
| `logInfo(Class<?> bizTypeClass, String bizLog)` | MscActionLog | 业务类型+日志 |
| `logInfo(String bizType, String bizLog)` | MscActionLog | 业务类型+日志 |
| `logInfo(Class<?> bizTypeClass, Serializable bizId, String bizLog)` | MscActionLog | 业务类型+ID+日志 |
| `logInfo(String bizType, Serializable bizId, String bizLog)` | MscActionLog | 业务类型+ID+日志 |

```java
// 删除时记录引用+日志
public ResponseData<Integer> delete(long id) {
    AuthServiceHelper.logRef(User.class, id);
    AuthServiceHelper.logInfo("删除用户");
    return dao.queryForObject(User.class, new AuthIdQueryParam(getSaasId(), id))
        .onSuccess(user -> dao.delete(user))
        .onSuccess(deleted -> FusionCache.invalidate(User.class, id));
}

// 复杂场景：先 logRef 绑定引用，操作成功后 logInfo 追加详情
public ResponseData<Order> createOrder(Order order) {
    AuthServiceHelper.logRef(Order.class);  // 先绑定类型，此时还没有ID
    return dao.save(order)
        .onSuccess(saved -> {
            AuthServiceHelper.logRef(Order.class, saved.getData().getId());
            AuthServiceHelper.logInfo("创建订单成功");
        });
}
```

### logSysInfo — 系统日志（不依赖Web环境）

> 用于定时任务、RPC回调等非 Web 请求场景。手动创建完整的 `MscActionLog`，不依赖 `AuthServiceFilter` 创建的上下文。

| 方法 | 说明 |
|------|------|
| `logSysInfo(apiCode, apiName, apiIp, saasId, bizTypeClass, bizId, bizLog, responseData)` | bizType 传 Class |
| `logSysInfo(apiCode, apiName, apiIp, saasId, bizType, bizId, bizLog, responseData)` | bizType 传 String |
| `logSysInfo(apiCode, apiName, apiIp, saasId, bizTypeClass, bizId, bizLog, requestBody, responseBody, responseData)` | 含请求/响应体 |
| `logSysInfo(apiCode, apiName, apiIp, saasId, bizType, bizId, bizLog, requestBody, responseBody, responseData)` | 含请求/响应体 |

参数说明：
- `apiCode` — 接口编码（记录在 apiUri 中）
- `apiName` — 接口名称
- `apiIp` — 来源IP
- `saasId` — 操作对应的 SaasId
- `bizTypeClass` / `bizType` — 业务类型（Class 取类名或 String）
- `bizId` — 业务主键
- `bizLog` — 业务日志描述
- `requestBody` / `responseBody` — 请求/响应报文（第三方交互场景）
- `responseData` — 响应数据

```java
// 定时任务中记录系统日志
@Scheduled(cron = "0 0 2 * * ?")
public void syncData() {
    ResponseData<?> result = dataSyncHelper.sync();
    AuthServiceHelper.logSysInfo("SYNC_DATA", "数据同步", "127.0.0.1", saasId,
        Order.class, null, "定时同步订单数据", result);
}
```

### 日志上下文管理

| 方法 | 说明 |
|------|------|
| `getContextLog()` | 获取当前请求日志对象 |
| `setContextLog(MscActionLog)` | 设置日志对象 |
| `destroyContextLog()` | 销毁日志上下文（防内存泄漏） |

### AuthServiceRpc — RPC管理方法

> **包路径**：`uw.auth.service.rpc.AuthServiceRpc`
> 通过 `AuthServiceHelper.getAuthServiceRpc()` 获取实例。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `verifyToken(token)` | `ResponseData<AuthTokenData>` | 验证 Token |
| `genUserId()` | `ResponseData<Long>` | 生成用户ID |
| `genGuestToken(...)` | TokenResponse | 生成访客 Token |
| `notifyGuestLoginFail(...)` | ResponseData | 通知登录失败 |
| `kickoutGuest(loginAgent, saasId, userId, remark)` | ResponseData | 踢出访客 |
| `createUser(MscUserRegister)` | `ResponseData<Long>` | 注册用户 |
| `loadUser(userId)` | `ResponseData<MscUserVo>` | 获取用户信息 |
| `listUser(saasId, userType, mchId, groupId, userId, userName, nickName, realName, mobile, email)` | `ResponseData<List<MscUserVo>>` | 查询用户列表 |
| `listUserGroup(saasId, userType, mchId, groupId, groupName)` | `ResponseData<List<MscUserGroupVo>>` | 查询用户组列表 |
| `getSaasUserLimit(saasId)` | `ResponseData<Integer>` | 获取 Saas 用户数限制 |
| `updateSaasUserLimit(saasId, limit, remark)` | ResponseData | 修改用户数限制 |
| `initSaasPerm(saasId, saasName, appNames, adminPasswd, adminMobile, adminEmail)` | ResponseData | 初始化 Saas 权限 |
| `updateSaasName(saasId, saasName)` | ResponseData | 更新 Saas 名称 |
| `getSaasIdByHost(saasHost)` | `ResponseData<Long>` | 根据 Host 获取 SaasId |
| `grantSaasPerm(saasId, permIds, remark)` | ResponseData | 授予 Saas 权限 |
| `revokeSaasPerm(saasId, permIds, remark)` | ResponseData | 撤销 Saas 权限 |
| `enableSaasPerm(saasId, remark)` | ResponseData | 启用 Saas 权限 |
| `disableSaasPerm(saasId, remark)` | ResponseData | 停用 Saas 权限 |
| `getAppSaasPerm(appNames)` | `ResponseData<String>` | 获取应用权限列表 |

```java
// 创建用户
MscUserRegister register = new MscUserRegister();
register.setSaasId(saasId);
register.setUserName("user001");
ResponseData<Long> result = AuthServiceHelper.getAuthServiceRpc().createUser(register);
long userId = result.getData();
```

## AuthTokenData

> **包路径**：`uw.auth.service.token.AuthTokenData`

| 字段 | 类型 | 说明 |
|------|------|------|
| tokenType | int | Token类型（Access/Refresh） |
| userType | int | 用户类型 |
| userId | long | 用户ID |
| saasId | long | SAAS运营商ID |
| mchId | long | 商户ID |
| groupId | long | 用户组ID |
| isMaster | int | 是否管理员（0/1） |
| userName | String | 登录名 |
| realName | String | 真实姓名 |
| nickName | String | 昵称 |
| mobile | String | 手机号 |
| email | String | 邮箱 |
| userIp | String | 登录IP |
| userGrade | int | 用户等级 |
| expireAt | long | 过期时间戳 |
| permSet | `Set<Integer>` | 权限ID集合 |
| configMap | `Map<String, String>` | 用户配置 |

## 异常类

> **包路径**：`uw.auth.service.exception`

| 异常类 | 触发场景 |
|--------|---------|
| `TokenInvalidException` | Token 无效或被踢出 |
| `TokenExpiredException` | Token 过期 |
| `TokenPermException` | 权限不足 |
| `TokenPayException` | 付费功能未开通 |
| `TokenServiceException` | 服务不可用（如 Auth Center 不可达） |
| `TokenSudoException` | 需要超级权限（SUDO 模式） |

> 这些异常由框架 Filter 自动抛出，GlobalExceptionAdvice 自动捕获并转为对应的 HTTP 状态码。开发者一般不需要手动抛出。
