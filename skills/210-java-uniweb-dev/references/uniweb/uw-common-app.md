# uw-common-app — Web应用公共类库

**Maven 坐标**: `com.umtone:uw-common-app`

基于 uw-auth-service 和 uw-dao 的后台应用通用功能。

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 实体状态 | `CommonState.ENABLED/DISABLED/DELETED` | 禁止硬编码 0/1/-1 |
| 通用响应码 | `CommonResponseCode.ENTITY_NOT_FOUND_ERROR` 等 | 实现 ResponseCode 接口 |
| 校验响应码 | `ValidateResponseCode.NOT_NULL/NOT_EMPTY` 等 | 实现 ResponseCode 接口 |
| Schema校验 | `SchemaValidateHelper.validate(form)` | 基于 @Schema 注解 |
| 权限查询参数 | `AuthQueryParam`（自动注入saasId） | 仅限 Controller 层 |
| 指定ID查询 | `new AuthIdQueryParam(saasId, id)` | Helper 层可用 |
| 数据历史记录 | `SysDataHistoryHelper.saveHistory(entity, remark)` | 更新前保存 |
| JSON配置 | `JsonConfigHelper.buildParamBox(params, json)` | 返回 JsonConfigBox |
| URL参数构建 | `QueryParamHelper.buildUriWithParams(url, param)` | 自动展开查询参数 |

## AppBootStrap — 应用启动引导

> **包路径**：`uw.common.app.AppBootStrap`

自定义 Bean 命名策略，解决多模块同名的 Controller/Runner/Cronner 冲突。

```java
public static void main(String[] args) {
    AppBootStrap.run(MyApplication.class, args);
}
```

**命名规则**：
- 本项目包下：`$PackageInfo$` / `SwaggerConfig` / `Controller` / `Runner` / `Croner` 使用全限定类名
- 全局兼容：`ClientHttpConnectorAutoConfiguration` / `LoadBalancerAutoConfiguration` 使用全限定类名
- 其余走 Spring 默认策略

## CommonAppProperties — 配置项

> **包路径**：`uw.common.app.conf.CommonAppProperties`
> **前缀**：`uw.common.app`

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enableCritLog` | boolean | true | 开启 CritLog 数据记录 |
| `localeDefault` | Locale | zh_CN | 默认语言 |
| `localeList` | List\<Locale\> | 全部可用 | 可选语言列表 |
| `shutdownTimeout` | Duration | 3s | 优雅关闭超时 |
| `disableSwagger` | boolean | false | 禁用 Swagger |

## 预置常量/枚举

### CommonConstants — 常用常量

> **包路径**：`uw.common.app.constant.CommonConstants`

| 常量 | 值 | 说明 |
|------|-----|------|
| `EMPTY` | `""` | 空字符串 |
| `SPACE` | `" "` | 空格字符串 |
| `NULL` | `"null"` | null 字符串 |
| `EMPTY_JSON` | `"{}"` | 空 JSON |
| `COLON` / `COMMA` / `SEMICOLON` | `:` / `,` / `;` | 分隔符 |
| `COMMA_CHAR` / `STAR` / `DOT` | 字符常量 | 单字符 |
| `SLASH` / `BACK_SLASH` | `/` / `\` | 斜杠 |
| `NEWLINE` / `TAB` | `\n` / `\t` | 控制符 |
| `IO_BUFFER_SIZE` | 16384 | IO 缓冲区大小 |
| `ACCEPT_LANG` | `"Accept-Language"` | 请求头语言 |
| `UTF_8` | `"UTF-8"` | 字符编码 |

### CommonState — 通用状态枚举

| 值 | 含义 |
|------|------|
| DELETED(-1) | 标记删除 |
| DISABLED(0) | 禁用 |
| ENABLED(1) | 启用 |

方法：`valueOf(int)` — 匹配不上返回 DELETED / `getValue()` / `getLabel()`

```java
entity.setState(CommonState.ENABLED.getValue());
if (user.getState() == CommonState.DISABLED.getValue()) { ... }
```

### CommonResponseCode — 通用响应码

实现 ResponseCode 接口，codePrefix = `uw.common`，i18n 资源：`i18n/messages/uw_common`。

| 枚举值 | 默认消息 |
|--------|---------|
| ENTITY_LIST_ERROR | 数据列表失败 |
| ENTITY_LOAD_ERROR | 数据加载失败 |
| ENTITY_SAVE_ERROR | 数据保存失败 |
| ENTITY_UPDATE_ERROR | 数据更新失败 |
| ENTITY_DELETE_ERROR | 数据删除失败 |
| ENTITY_EXISTS_ERROR | 数据已存在 |
| ENTITY_NOT_FOUND_ERROR | 数据未找到 |
| ENTITY_STATE_ERROR | 数据状态错误 |

```java
return ResponseData.warnCode(CommonResponseCode.ENTITY_NOT_FOUND_ERROR);
```

### ValidateResponseCode — 校验响应码

实现 ResponseCode 接口，codePrefix = `uw.validate`，i18n 资源：`i18n/messages/uw_validate`。

| 枚举值 | 默认消息 |
|--------|---------|
| NOT_NULL | 不能为NULL |
| NOT_EMPTY | 不能为空 |
| VALUE_TOO_SMALL | 不能小于最小值 |
| VALUE_TOO_LARGE | 不能大于最大值 |
| LENGTH_TOO_SHORT | 不能小于最小长度 |
| LENGTH_TOO_LONG | 不能大于最大长度 |
| DATA_FORMAT_ERROR | 数据格式错误 |
| REGEX_FORMAT_ERROR | 正则校验格式错误 |

## 预置 QueryParam

> **包路径**：`uw.common.app.dto`
> **基类**：`QueryParam` / `PageQueryParam`（来自 `uw.common.dto`）

### 继承体系

```
QueryParam (uw.common.dto)
├── IdQueryParam          — id / ids
├── IdStateQueryParam     — id / ids + state / states / stateGte / stateLte
├── AuthQueryParam        — saasId / mchId / userId / userType（自动绑定）
├── AuthIdQueryParam      — Auth + id / ids
└── AuthIdStateQueryParam — Auth + id / ids + state

PageQueryParam (uw.common.dto)
├── AuthPageQueryParam    — saasId / mchId / userId / userType（自动绑定）
├── SysCritLogQueryParam  — 系统关键日志查询
└── SysDataHistoryQueryParam — 数据历史查询
```

### AuthQueryParam — 权限查询参数

构造：`new AuthQueryParam()` 自动注入 saasId，或 `new AuthQueryParam(saasId)` 手动指定。

链式绑定方法：`bindUserId()` / `bindMchId()` / `bindUserType()`

```java
@GetMapping("/list")
public ResponseData<PageList<User>> list(AuthQueryParam param) {
    return dao.list(User.class, param);
}

@GetMapping("/my-list")
public ResponseData<PageList<Order>> myList(AuthQueryParam param) {
    param.bindUserId().bindMchId();
    return dao.list(Order.class, param);
}
```

### AuthPageQueryParam — 权限分页查询参数

继承 PageQueryParam，默认构造自动绑定 saasId。支持 `bindUserId()` / `bindMchId()` / `bindUserType()`。

### IdQueryParam — ID查询参数

字段：`id(Serializable)` / `ids(Serializable[])`，`@QueryMeta` 自动映射 `id=?` / `id in (?)`。

### IdStateQueryParam — ID+状态查询参数

额外字段：`state` / `states` / `stateGte` / `stateLte`

### AuthIdQueryParam — Auth+ID查询参数

构造器：
- `new AuthIdQueryParam(id)` — 自动绑定 saasId
- `new AuthIdQueryParam(saasId, id)` — 手动指定 saasId
- `new AuthIdQueryParam(ids)` / `new AuthIdQueryParam(saasId, ids)` — 数组版本

### AuthIdStateQueryParam — Auth+ID+状态查询参数

构造器：
- `(id, state)` / `(id, states...)` / `(ids, state)` / `(ids, states...)` — 自动绑定
- `(saasId, id, state)` / `(saasId, id, states...)` 等 — 手动指定

### SysCritLogQueryParam — 系统关键日志查询

继承 AuthPageQueryParam，支持按以下条件查询：

| 字段 | @QueryMeta 表达式 | 类型 |
|------|-------------------|------|
| id | `id=?` | Long |
| ids | `id in (?)` | Long[] |
| mchId | `mch_id=?` | Long |
| userId | `user_id=?` | Long |
| userType | `user_type=?` | Integer |
| groupId | `group_id=?` | Long |
| userName | `user_name like ?` | String |
| nickName | `nick_name like ?` | String |
| realName | `real_name like ?` | String |
| userIp | `user_ip like ?` | String |
| apiUri | `api_uri like ?` | String |
| apiName | `api_name like ?` | String |
| bizType | `biz_type like ?` | String |
| bizTypeClass | 设置 `bizType` 为类名 | Class |
| bizId | `biz_id like ?` | String |
| requestDateRange | `request_date between ? and ?` | Date[] |
| responseState | `response_state like ?` | String |
| responseCode | `response_code like ?` | String |
| responseMillis | `response_millis=?` | Long |
| responseMillisRange | `response_millis between ? and ?` | Long[] |
| statusCode | `status_code=?` | Integer |
| statusCodeRange | `status_code between ? and ?` | Integer[] |
| appInfo | `app_info like ?` | String |
| appHost | `app_host like ?` | String |

### SysDataHistoryQueryParam — 数据历史查询

继承 AuthPageQueryParam，支持按以下条件查询：

| 字段 | @QueryMeta 表达式 | 类型 |
|------|-------------------|------|
| id | `id=?` | Long |
| ids | `id in (?)` | Long[] |
| mchId | `mch_id=?` | Long |
| userId | `user_id=?` | Long |
| userType | `user_type=?` | Integer |
| groupId | `group_id=?` | Long |
| userName | `user_name like ?` | String |
| nickName | `nick_name like ?` | String |
| realName | `real_name like ?` | String |
| entityClass | `entity_class like ?` | String / Class |
| entityId | `entity_id like ?` | String |
| entityName | `entity_name like ?` | String |
| userIp | `user_ip like ?` | String |
| createDateRange | `create_date between ? and ?` | Date[] |

## Helper 工具类

### SysDataHistoryHelper — 数据历史记录

> **包路径**：`uw.common.app.helper.SysDataHistoryHelper`

全部静态方法。自动从 AuthServiceHelper 获取当前用户信息。

| 方法 | 说明 |
|------|------|
| `saveHistory(DataEntity)` | 保存实体历史（自动提取ID和名称） |
| `saveHistory(DataEntity, String remark)` | 保存 + 备注 |
| `saveHistory(entityId, dataEntity, entityName, remark)` | 完整参数 |

自动记录：saasId / mchId / userId / groupId / userType / userName / nickName / realName / userIp / entityData（JSON）/ entityUpdateInfo（差异Map）。保存后自动调用 `CLEAR_UPDATED_INFO()`。

```java
SysDataHistoryHelper.saveHistory(user, "更新前");
ResponseData<User> result = dao.update(user);
result.onSuccess(updated -> SysDataHistoryHelper.saveHistory(updated, "更新后"));
```

### JsonConfigHelper — JSON配置参数

> **包路径**：`uw.common.app.helper.JsonConfigHelper`

全部静态方法。通过 JsonConfigParam 定义配置参数，构建 JsonConfigBox 获取结构化和类型化参数。

**构建方法**：

| 方法 | 说明 |
|------|------|
| `buildParamBox(List<JsonConfigParam>, String json)` | 从 JSON 数据构建 |
| `buildParamBox(List<JsonConfigParam>, Map data)` | 从 Map 构建 |
| `buildParamBox(String paramJson, String dataJson)` | 从两个 JSON 字符串构建 |

**校验方法**：

| 方法 | 说明 |
|------|------|
| `validateConfigData(List<JsonConfigParam>, Map data)` | 校验配置数据 |
| `validateConfigData(List<JsonConfigParam>, String json)` | 校验配置数据 |
| `validateConfigData(String paramJson, String dataJson)` | 校验配置数据 |

返回 `ResponseData<List<ValidateResult>>`，校验通过返回空列表。

### SchemaValidateHelper — Schema注解校验

> **包路径**：`uw.common.app.helper.SchemaValidateHelper`

基于 `@Schema` 注解自动校验 VO 对象。使用 Caffeine 缓存反射元数据。

```java
List<ValidateResult> errors = SchemaValidateHelper.validate(form);
if (!errors.isEmpty()) {
    return ResponseData.error(errors, "", "数据校验失败！");
}
```

支持的 `@Schema` 校验规则：

| 属性 | 校验行为 |
|------|---------|
| `requiredMode = REQUIRED` | 非空校验 |
| `minimum` / `maximum` | 数值范围校验 |
| `minLength` / `maxLength` | 字符串长度校验 |
| `pattern` | 正则校验 |

### QueryParamHelper — URL查询参数构建

> **包路径**：`uw.common.app.helper.QueryParamHelper`

将 QueryParam 对象属性展开为 URI 查询参数。使用 Caffeine 缓存反射元数据。

```java
String url = QueryParamHelper.buildUriWithParams("/api/list", queryParam);
// → /api/list?name=foo&$pg=1&$rn=20
```

**特性**：
- 自动映射 PageQueryParam 魔法参数（PAGE→$pg, RESULT_NUM→$rn, START_INDEX→$si, REQUEST_TYPE→$rt, SORT_NAME→$sn, SORT_TYPE→$st）
- 过滤 Auth 系参数（saasId / userId / mchId / userType）
- 支持 数组 / Iterable 类型展开为多值参数

## VO 值对象

### JsonConfigBox — JSON配置参数盒子

> **包路径**：`uw.common.app.vo.JsonConfigBox`

从 `Map<String, String>` 获取强类型参数值。`EMPTY_PARAM_BOX` 常量用于空配置。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getParam(name)` | String | 默认空字符串 |
| `getParam(name, default)` | String | 带默认值 |
| `getParams(name)` | String[] | 数组 |
| `getIntParam(name)` / `getIntParam(name, default)` | int | 整数 |
| `getIntParams(name)` | int[] | 整数数组 |
| `getLongParam(name)` / `getLongParam(name, default)` | long | 长整数 |
| `getLongParams(name)` | long[] | 长整数数组 |
| `getFloatParam(name)` / `getFloatParam(name, default)` | float | 浮点 |
| `getFloatParams(name)` | float[] | 浮点数组 |
| `getDoubleParam(name)` / `getDoubleParam(name, default)` | double | 双精度 |
| `getDoubleParams(name)` | double[] | 双精度数组 |
| `getBooleanParam(name)` / `getBooleanParam(name, default)` | boolean | 布尔 |
| `getBooleanParams(name)` | boolean[] | 布尔数组 |
| `getMapParam(name)` | `Map<String, String>` | Map |

> 所有 getXxx 方法也支持传入 `JsonConfigParam` 枚举作为参数。

### JsonConfigParam — 配置参数定义接口

> **包路径**：`uw.common.app.vo.JsonConfigParam`

使用枚举实现此接口定义配置参数。

**ParamType 枚举**：

| 类型 | 值 | 说明 |
|------|-----|------|
| STRING | string | 字符串 |
| SET_STRING | set\<string\> | 字符串集合 |
| TEXT | text | 长文本 |
| TEXT_RICH | textRich | 富文本 |
| INT | int | 整数 |
| SET_INT | set\<int\> | 整数集合 |
| LONG | long | 长整数 |
| SET_LONG | set\<long\> | 长整数集合 |
| BOOLEAN | boolean | 布尔 |
| SET_BOOLEAN | set\<boolean\> | 布尔集合 |
| FLOAT | float | 浮点 |
| SET_FLOAT | set\<float\> | 浮点集合 |
| DOUBLE | double | 双精度 |
| SET_DOUBLE | set\<double\> | 双精度集合 |
| DATE | date | 日期 |
| SET_DATE | set\<date\> | 日期集合 |
| TIME | time | 时间 |
| SET_TIME | set\<time\> | 时间集合 |
| DATETIME | datetime | 日期时间 |
| SET_DATETIME | set\<datetime\> | 日期时间集合 |
| ENUM | enum | 枚举 |
| SET_ENUM | set\<enum\> | 枚举集合 |
| MAP | map | Map 类型 |

**枚举定义模板**：

```java
public enum SystemConfig implements JsonConfigParam {
    SITE_NAME("siteName", ParamType.STRING, "MySite", "站点名称", null),
    MAX_UPLOAD_SIZE("maxUploadSize", ParamType.INT, "10485760", "最大上传大小", null);

    private final ParamData paramData;

    SystemConfig(String key, ParamType type, String value, String desc, String regex) {
        this.paramData = new ParamData(key, type, value, desc, regex);
    }

    @Override
    public ParamData getParamData() { return paramData; }
}
```

### ValidateResult — 校验结果

> **包路径**：`uw.common.app.vo.ValidateResult`

| 字段 | 类型 | 说明 |
|------|------|------|
| name | String | 属性名 |
| title | String | 属性描述 |
| errorCode | String | 完整错误码（含前缀） |
| errorMsg | String | 国际化错误信息 |
| refData | String | 参考数据（如最小值/最大值） |

## Entity 实体类

### SysCritLog — 系统关键日志

> **包路径**：`uw.common.app.entity.SysCritLog`
> **表名**：`sys_crit_log`

| 字段 | 类型 | 说明 |
|------|------|------|
| id | long | ID（主键） |
| saasId | long | SaaS ID |
| mchId | long | 商户ID |
| userId | long | 用户ID |
| userType | int | 用户类型 |
| groupId | long | 用户组ID |
| userName | String | 用户名 |
| nickName | String | 昵称 |
| realName | String | 真实名称 |
| userIp | String | 用户IP |
| apiUri | String | 请求URI |
| apiName | String | API名称 |
| bizType | String | 业务类型 |
| bizId | String | 业务ID |
| bizLog | String | 业务日志 |
| requestDate | Date | 请求时间 |
| requestBody | String | 请求参数 |
| responseState | String | 响应状态 |
| responseCode | String | 响应代码 |
| responseMsg | String | 响应消息 |
| responseBody | String | 响应内容 |
| responseMillis | long | 请求耗时(ms) |
| statusCode | int | HTTP状态码 |
| appInfo | String | 应用信息 |
| appHost | String | 应用主机 |

### SysDataHistory — 系统数据历史

> **包路径**：`uw.common.app.entity.SysDataHistory`
> **表名**：`sys_data_history`

| 字段 | 类型 | 说明 |
|------|------|------|
| id | long | ID（主键） |
| saasId | long | SaaS ID |
| mchId | long | 商户ID |
| userId | long | 用户ID |
| userType | int | 用户类型 |
| groupId | long | 用户组ID |
| userName | String | 用户名 |
| nickName | String | 昵称 |
| realName | String | 真实名称 |
| entityClass | String | 实体类名 |
| entityId | String | 实体ID |
| entityName | String | 实体名 |
| entityData | String | 实体数据（JSON） |
| entityUpdateInfo | String | 修改信息（JSON） |
| remark | String | 备注 |
| userIp | String | 用户IP |
| createDate | Date | 创建日期 |
