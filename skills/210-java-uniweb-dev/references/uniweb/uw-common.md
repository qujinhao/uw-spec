# uw-common — 通用工具类库

**Maven 坐标**: `com.umtone:uw-common`

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 成功返回 | `ResponseData.success(data)` | — |
| 业务校验失败 | `ResponseData.warnCode(ResponseCode)` 或 `warnCode("CODE","msg")` | 禁止 `warn("CODE","msg")`（泛型陷阱） |
| 系统异常 | `ResponseData.errorCode(ResponseCode)` 或 `errorCode("CODE","msg")` | 禁止 `error("CODE","msg")`（泛型陷阱） |
| 致命错误 | `ResponseData.fatalCode(ResponseCode)` | — |
| 判断成功 | `result.isSuccess()` | — |
| 判断非成功 | `result.isNotSuccess()` | 不要再 `|| getData()==null` |
| 链式处理 | `result.onSuccess(data -> ...).onError(data -> ...)` | — |
| 货币计算 | `MoneyUtils` | 金额以 long（分）为单位，禁止浮点 |
| 数据校验 | `ValidateUtils.isXxx(value)` | 覆盖字符串/整数/身份证/手机号等 |
| JSON序列化 | `JsonUtils.toString(object)` | — |
| JSON反序列化 | `JsonUtils.parse(json, Class)` 或 `parse(json, new TypeReference<List<T>>(){})` | — |
| AES加密 | `AESUtils.encryptString(key, data)` | 推荐自动IV版本（密文自带IV） |
| 日期格式化 | `DateUtils.format(date)` 或 `format(date, pattern)` | — |
| 日期偏移 | `DateUtils.offsetDay(date, n)` | 方法名不是 addDays |
| 当天开始 | `DateUtils.beginOfToday(date)` | 方法名不是 getDayStart |
| 当天结束 | `DateUtils.endOfToday(date)` | 方法名不是 getDayEnd |
| 雪花ID | `SnowflakeIdGenerator.getInstance().generateId()` | — |
| 位运算开关 | `BitConfigUtils.isOn/On/Off(config, bitIndex)` | int 32位，long 64位 |

## ResponseData

> **包路径**：`uw.common.response.ResponseData`

构造：`ResponseData.success(data)` / `ResponseData.warnCode(code)` / `ResponseData.errorCode(code)` / `ResponseData.fatalCode(code)`

| 字段 | 类型 | 说明 |
|------|------|------|
| time | long | 时间戳 |
| state | String | 响应状态（SUCCESS/WARN/ERROR/FATAL） |
| code | String | 响应状态码 |
| msg | String | 响应消息 |
| data | T（泛型） | 响应数据 |
| type | String | 响应数据类型 |

**状态判断**：`isSuccess()` / `isWarn()` / `isError()` / `isFatal()` / `isNotSuccess()`

**链式回调**（核心设计 — 每个方法有 3 种重载）：

| 重载 | 签名 | 返回值 | 典型用途 |
|------|------|--------|---------|
| **Function 版（转换）** | `onSuccess(Function<T, ResponseData<R>>)` | 新的 `ResponseData<R>` | **链式类型转换**：`dao.load()` → 修改 → `dao.update()`，返回 update 的 ResponseData |
| **Consumer 版（回调）** | `onSuccess(Consumer<T>)` | 自身 `ResponseData<T>` | 副作用操作：缓存更新、日志记录、数据组装 |
| **Runnable 版（无参）** | `onSuccess(Runnable)` | 自身 `ResponseData<T>` | 不需要 data 的操作 |

**所有 onXxx 方法一览**（每个都有 3 种重载）：

| 方法 | 触发条件 |
|------|---------|
| `onSuccess` | state == SUCCESS |
| `onWarn` | state == WARN |
| `onError` | state == ERROR |
| `onFatal` | state == FATAL |
| `onNotSuccess` | state != SUCCESS |
| `onNotError` | state != ERROR |

**Function 版（转换）核心机制**：
- **成功时**：执行 `function.apply(data)`，返回新的 `ResponseData<R>`（类型从 T 变为 R）
- **失败时**：跳过 function，直接返回自身（`this.raw()`，自动转型为 `ResponseData<R>`）
- **这是"扁平链式"的真正实现**：`dao.queryForObject()` → `onSuccess(product -> dao.update(product))` 返回的是 update 的 ResponseData

**Consumer 版（回调）核心机制**：
- 执行 consumer 后返回自身，支持连续链式调用
- 适用于副作用操作（缓存失效、日志、数据组装）

**map 类型转换**：`<R> R map(Function<ResponseData<T>, R>)` — 将整个 ResponseData 转为任意类型 R。

**泛型陷阱**：`ResponseData.warn("CODE","msg")` 实际签名是 `warn(T t, String code)`，Java 推断 T=String，"CODE" 变成 data。✅ 正确：`warnCode("CODE","msg")`。

**使用示例**：
```java
// 1. 直接返回（最常见）
@GetMapping("/load")
public ResponseData<User> load(long id) {
    return dao.load(User.class, id);
}

// 2. Consumer 版：链式后处理（副作用）
@PostMapping("/save")
public ResponseData<User> save(@RequestBody User user) {
    user.setId(dao.getSequenceId(User.class));
    user.setCreateDate(SystemClock.nowDate());
    return dao.save(user).onSuccess(saved ->
        FusionCache.invalidate(User.class, saved.getId())
    );
}

// 3. Function 版：链式类型转换（加载→修改→更新，返回update的ResponseData）
@PostMapping("/enable")
public ResponseData<Integer> enable(long id) {
    AuthServiceHelper.logRef(Product.class, id);
    return dao.queryForObject(Product.class, new AuthIdQueryParam(getSaasId(), id))
        .onSuccess(product -> {       // Function版：返回新的ResponseData
            product.setState(CommonState.ENABLED.getValue());
            product.setModifyDate(SystemClock.nowDate());
            return dao.update(product);  // 返回update的ResponseData<Integer>
        });
}

// 4. map：将ResponseData转为其他类型
String json = dao.load(User.class, id).map(resp -> JsonUtils.toString(resp));

// 5. 链式数据组装（父子表联查）
@GetMapping("/listEx")
public ResponseData<PageList<OrderEx>> listEx(AuthQueryParam param) {
    return dao.list(OrderEx.class, param).onSuccess(orders -> {
        if (orders.isEmpty()) return;
        Object[] ids = orders.stream().map(OrderEx::getId).toArray();
        dao.list(OrderItem.class, "SELECT * FROM order_item WHERE order_id IN ("
            + String.join(",", Collections.nCopies(ids.length, "?")) + ")", ids)
            .onSuccess(items -> {
                Map<Long, List<OrderItem>> map = items.stream()
                    .collect(Collectors.groupingBy(OrderItem::getOrderId));
                orders.forEach(o -> o.setItemList(map.getOrDefault(o.getId(), List.of())));
            });
    });
}

// 6. 条件更新链（加载→修改→更新）
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

// 7. 多步骤业务流程（加载→修改→更新）
public static ResponseData<User> resetPassword(long userId, String newPassword) {
    AuthServiceHelper.logRef(User.class, userId);
    return dao.load(User.class, userId)
        .onSuccess(user -> {
            user.setPassword(DigestUtils.sha256(newPassword));
            user.setModifyDate(SystemClock.nowDate());
            return dao.update(user);
        });
}
```

### 链式调用模式对比

| 模式 | 使用方法 | 返回值 | 适用场景 |
|------|---------|--------|---------|
| 直接返回 | 无链式 | `dao.xxx()` 的 ResponseData | 简单 CRUD |
| Consumer 后处理 | `onSuccess(Consumer)` | 原始 ResponseData | 缓存失效、日志、数据组装 |
| Function 转换 | `onSuccess(Function)` | 新的 ResponseData | 加载→修改→更新，状态变更 |
| map 转换 | `map(Function)` | 任意类型 R | 提取/转换数据 |

## ResponseCode 接口

> **包路径**：`uw.common.response.ResponseCode`

业务枚举实现此接口实现类型安全的响应码管理，替代硬编码字符串。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| getCode() | String | 响应码 |
| getMessage() | String | 默认消息 |
| messageSource() | MessageSource | 国际化消息源（可选） |
| codePrefix() | String | 码前缀（可选） |
| getFullCode() | String | 完整码（prefix + code） |
| getMessage(Object... args) | String | 格式化消息 |
| getLocalizedMessage(Locale, Object... args) | String | 国际化消息 |

**枚举定义模板**（在 `{package}/constant/` 包下）：
```java
public enum GuestResponseCode implements ResponseCode {
    USER_NOT_FOUND("用户不存在"),
    PHONE_EXISTS("该手机号已注册"),
    ;

    private final String code;
    private final String message;

    GuestResponseCode(String message) {
        this.code = EnumUtils.enumNameToDotCase(this.name());
        this.message = message;
    }

    @Override
    public String getCode() { return code; }
    @Override
    public String getMessage() { return message; }
}
```

> 完整 ResponseCode 模板（含 i18n 12语种资源文件）见 [code-templates.md](code-templates.md) §4。

## PageList

> **包路径**：`uw.common.data.PageList<T>`

分页列表数据容器，组合分页信息与泛型列表数据，实现 `Iterable<T>` 接口。

**构造**：`new PageList<>(List<T>, int startIndex, int resultNum, int sizeAll)` 或 `PageList.empty()`

| 字段 | 类型 | 说明 |
|------|------|------|
| startIndex | int | 起始索引 |
| resultNum | int | 每页大小 |
| size | int | 当前页实际条数 |
| sizeAll | int | 总数据量 |
| page | int | 当前页码 |
| pageCount | int | 总页数 |
| list | ArrayList\<T\> | 数据列表 |

**访问方法**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `get(int index)` | T | 按索引获取（越界返回 null） |
| `getFirst()` | T | 第一个元素 |
| `getLast()` | T | 最后一个元素 |
| `size()` | int | 当前页条数 |
| `sizeAll()` | int | 总数据量 |
| `isEmpty()` | boolean | 是否为空 |
| `isNotEmpty()` | boolean | 是否非空 |
| `list()` | List\<T\> | 获取数据列表 |
| `stream()` | Stream\<T\> | 获取 Stream |
| `contains(Object)` | boolean | 是否包含元素 |
| `indexOf(Object)` | int | 查找元素索引 |
| `iterator()` | Iterator\<T\> | 实现 Iterable，支持 for-each |

> 所有 `@JsonIgnore` 的 getter 方法不序列化到 JSON。JSON 输出仅含 startIndex / resultNum / size / sizeAll / page / pageCount / list。

**PageList 链式调用模式**（配合 ResponseData + DaoManager）：

```java
// 1. 空结果提前返回（避免后续 NPE）
return dao.list(User.class, param).onSuccess(users -> {
    if (users.isEmpty()) return;  // 空页自动跳过
    // 处理非空数据...
});

// 2. 遍历处理（PageList 实现 Iterable<T>）
return dao.list(User.class, param).onSuccess(users -> {
    for (User user : users) {  // 支持 for-each
        user.setDisplayName(user.getNickName());
    }
});

// 3. Stream 操作
return dao.list(User.class, param).onSuccess(users -> {
    List<Long> ids = users.stream().map(User::getId).collect(Collectors.toList());
    // 批量查询关联数据...
});

// 4. getFirst/getLast 快捷访问
return dao.queryForObject(User.class, param).onSuccess(user -> {
    // 单条查询也返回 ResponseData，链式一致
});
```

## PageRowSet

> **包路径**：`uw.common.data.PageRowSet`

分页行集数据容器。存储行列结构的二维数据，支持游标遍历和按列名/列索引访问。不依赖 `java.sql`，由 DAO 层负责 `ResultSet` 到 `PageRowSet` 的转换。

**构造**：`new PageRowSet(String[] columnNames, List<Object[]> list, int startIndex, int resultNum, int sizeAll)` 或 `PageRowSet.empty()`

**分页字段**：与 PageList 相同（startIndex / resultNum / size / sizeAll / page / pageCount）

**游标遍历**：

| 方法 | 说明 |
|------|------|
| `next()` | 移到下一行，返回是否有数据 |
| `previous()` | 移到上一行 |
| `absolute(int index)` | 定位到指定位置 |
| `remove()` | 删除当前行 |

**按列名取值**（游标模式，需先 `next()`）：

| 方法 | 返回类型 |
|------|---------|
| `get(String colName)` | Object |
| `getBoolean(String colName)` | boolean |
| `getInt(String colName)` | int |
| `getLong(String colName)` | long |
| `getDouble(String colName)` | double |
| `getFloat(String colName)` | float |
| `getString(String colName)` | String |
| `getBigInteger(String colName)` | BigInteger |
| `getBigDecimal(String colName)` | BigDecimal |
| `getBytes(String colName)` | byte[] |
| `getDate(String colName)` | java.util.Date |

> 同名方法也支持按列索引（int colIndex）访问。

**类型转换**：

```java
// PageRowSet → PageList（游标遍历 + Function 映射）
PageList<UserVO> result = pageRowSet.map(row -> {
    UserVO vo = new UserVO();
    vo.setId(row.getLong("id"));
    vo.setName(row.getString("user_name"));
    vo.setCreateDate(row.getDate("create_date"));
    return vo;
});
```

## MoneyUtils

> **包路径**：`uw.common.util.MoneyUtils`

所有金额以 **分（long）** 为单位，避免浮点误差。溢出或除零时抛出 `ArithmeticException`。提供静态方法和链式调用（Chain）两套 API。

**静态方法**：

| 方法 | 说明 |
|------|------|
| `add(long a, long b)` | 安全相加 |
| `subtract(long a, long b)` | 安全相减 |
| `sum(long... values)` | 多值求和 |
| `multiply(long amount, long factor)` | 乘以整数倍数 |
| `multiplyBps(long amount, long rateBps)` | 乘以万分比（850 = 8.5%） |
| `multiplyRatio(long amount, long num, long den)` | 乘以比率（分子/分母） |
| `multiplyRate(long amount, double rate)` | 乘以 double 倍率（汇率） |
| `multiplyRate(long amount, String rate)` | 乘以 String 倍率（汇率，避免精度丢失） |
| `divideHalfUp(long dividend, long divisor)` | 四舍五入除法 |
| `ceilDiv(long dividend, long divisor)` | 向上取整除法（天花板） |
| `divideRate(long amount, double rate)` | 除以倍率 |
| `allocate(long total, long[] weights)` | 按比例分摊（尾差兜底，合计=total） |
| `toYuan(long cents)` | 分 → 元字符串（"1.99"） |
| `fromYuan(String yuan)` | 元字符串 → 分（199） |
| `toChinese(long cents)` | 分 → 中文大写（"贰佰伍拾伍元伍角整"） |

**链式调用（Chain）**：

```java
// 链式入口：of(分) 或 ofYuan("元")
long fee = MoneyUtils.of(10000L)       // 100.00 元
    .multiply(3)                        // × 3 件
    .multiplyRate("0.85")               // 85 折
    .add(500)                           // + 5 元手续费
    .cent();                            // → 25550（255.50 元）

String display = MoneyUtils.of(19900)
    .multiplyBps(850)                   // 85 折
    .yuan();                            // → "169.15"

String cn = MoneyUtils.of(214748364700L)
    .chinese();                         // → "贰拾壹亿肆仟柒佰肆拾捌万叁仟陆佰肆拾柒元整"
```

**Chain 方法**：`add(long)` / `add(Chain)` / `subtract(long)` / `subtract(Chain)` / `multiply(long)` / `multiplyBps(long)` / `multiplyRate(double)` / `multiplyRate(String)` / `divideHalfUp(long)` / `ceilDiv(long)` / `divideRate(double)` / `divideRate(String)` / `cent()` → long / `yuan()` → String / `chinese()` → String

## ValidateUtils

> **包路径**：`uw.common.util.ValidateUtils`

所有方法返回 `boolean`，不抛异常。null 输入统一返回 false。

**字符串校验**：

| 方法 | 说明 |
|------|------|
| `isNotEmpty(String)` | 非空字符串 |
| `isNotBlank(String)` | 非空白字符串 |
| `isLengthInRange(String, int min, int max)` | 长度在闭区间内（null视为0） |
| `isDigits(String)` | 纯数字（0~9） |
| `isLetters(String)` | 纯英文字母 |
| `isAlphanumeric(String)` | 字母+数字组合 |
| `isStrongPassword(String, int min, int max)` | 密码强度（至少含字母+数字） |

**数值校验**：

| 方法 | 说明 |
|------|------|
| `isInteger(String)` | 合法整数（含正负号，long范围内） |
| `isPositiveInteger(String)` | 正整数（>0，无前导零） |
| `isNonNegativeInteger(String)` | 非负整数（>=0） |
| `isDecimal(String)` | 合法浮点数 |
| `isPositiveDecimal(String)` | 正浮点数 |
| `isDecimalWithScale(String, int maxScale)` | 浮点数且小数位不超过 maxScale |
| `isInRange(String, double min, double max)` | 数值在闭区间内 |

**日期时间校验**：

| 方法 | 说明 |
|------|------|
| `isDate(String)` | 日期 yyyy-MM-dd（含闰年校验） |
| `isDate(String, String pattern)` | 指定格式日期 |
| `isDateInRange(String, LocalDate start, LocalDate end)` | 日期范围 |
| `isTime(String)` | 时间 HH:mm:ss |
| `isTime(String, String pattern)` | 指定格式时间 |
| `isDateTime(String)` | 日期时间 yyyy-MM-dd HH:mm:ss（严格解析） |
| `isDateTime(String, String pattern)` | 指定格式日期时间 |

**网络校验**：

| 方法 | 说明 |
|------|------|
| `isEmail(String)` | 邮箱（RFC 5321，<=254字符） |
| `isUrl(String)` | URL（http/https/ftp，<=2048字符） |
| `isIpv4(String)` | IPv4 地址 |
| `isIpv6(String)` | IPv6 地址（标准8段全称） |

**中国业务校验**：

| 方法 | 说明 |
|------|------|
| `isChinaMobile(String)` | 中国手机号（11位，1开头） |
| `isChinaIdCard(String)` | 中国身份证号（18位，含校验位） |
| `isChinaName(String)` | 中文姓名（2-20个汉字） |
| `isChinaUscc(String)` | 统一社会信用代码（18位） |
| `isChinaPlateNo(String)` | 车牌号（含新能源） |

**使用示例**：
```java
if (!ValidateUtils.isChinaMobile(phone)) {
    return ResponseData.warnCode(BizResponseCode.INVALID_PHONE);
}
if (!ValidateUtils.isChinaIdCard(idCard)) {
    return ResponseData.warnCode(BizResponseCode.INVALID_ID_CARD);
}
```

## JsonUtils

> **包路径**：`uw.common.util.JsonUtils`

| 方法 | 说明 |
|------|------|
| `toString(Object)` | 对象 → JSON字符串 |
| `toPrettyString(Object)` | 美化输出 |
| `parse(String, Class<T>)` | JSON → 对象 |
| `parse(String, TypeReference<T>)` | JSON → 泛型对象（如 List<User>） |
| `parseTree(String)` | JSON → JsonNode 树模型 |
| `convert(Object, Class<T>)` | 对象类型转换（如 Map → POJO） |

## DateUtils

> **包路径**：`uw.common.util.DateUtils`

| 方法 | 说明 | 注意 |
|------|------|------|
| `format(Date)` | 格式化为 yyyy-MM-dd HH:mm:ss | — |
| `format(Date, String)` | 按指定格式格式化 | — |
| `parse(String)` | 解析默认格式 | — |
| `parse(String, String)` | 按指定格式解析 | — |
| `offsetDay(Date, int)` | 偏移天数 | 不是 addDays |
| `offsetMonth(Date, int)` | 偏移月数 | — |
| `offsetHour(Date, int)` | 偏移小时 | — |
| `beginOfToday(Date)` | 当天开始 00:00:00 | 不是 getDayStart |
| `endOfToday(Date)` | 当天结束 23:59:59 | 不是 getDayEnd |
| `daysDiff(Date, Date)` | 相差天数 | — |
| `now()` | 当前时间戳（毫秒） | — |
| `nowDate()` | 当前 Date | 常用于 createDate/modifyDate |

**日期格式常量**：`FORMAT_DEFAULT`="yyyy-MM-dd HH:mm:ss"、`FORMAT_DATE`="yyyy-MM-dd"、`FORMAT_TIME`="HH:mm:ss"

## AESUtils

> **包路径**：`uw.common.util.AESUtils`

| 方法 | 说明 |
|------|------|
| `generateKey(int keySize)` | 生成密钥（128/192/256位） |
| `generateIv()` | 生成IV（16字节） |
| `encryptString(byte[] key, String data)` | 自动IV加密（推荐，密文自带IV） |
| `decryptString(byte[] key, String encrypted)` | 自动IV解密 |
| `encryptString(byte[] key, byte[] iv, String data)` | 指定IV加密 |
| `decryptString(byte[] key, byte[] iv, String encrypted)` | 指定IV解密 |

## BitConfigUtils

> **包路径**：`uw.common.util.BitConfigUtils`

| 方法 | 说明 |
|------|------|
| `isOn(int/long config, int bitIndex)` | 检查开关是否开启 |
| `on(int/long config, int... bitIndex)` | 开启开关 |
| `off(int/long config, int bitIndex)` | 关闭开关 |
| `countOn(int/long config)` | 已开启数量 |

## BizAESBox

> **包路径**：`uw.common.util.BizAESBox`

业务 AES 加解密盒子。通过配置文件管理密钥和向量，确保多次加密结果一致。

| 方法 | 说明 |
|------|------|
| `getInstance(String configPath)` | 获取实例（配置文件缓存，线程安全） |
| `encrypt(String data)` | 加密 |
| `decrypt(String encrypted)` | 解密 |
| `genAesConfig()` | 生成 AES 密钥+向量配置字符串（静态） |

**配置文件格式**（如 `bizaes.properties`）：
```properties
aes.key=Base64编码的密钥
aes.iv=Base64编码的向量（可选）
```

```java
BizAESBox aesBox = BizAESBox.getInstance("bizaes.properties");
String encrypted = aesBox.encrypt("敏感数据");
String decrypted = aesBox.decrypt(encrypted);
```

## ChineseUtils

> **包路径**：`uw.common.util.ChineseUtils`

汉字拼音与相似度工具类。

| 方法 | 说明 |
|------|------|
| `convertToPinyin(String, String separator)` | 转拼音 |
| `getShortPinyin(String)` | 拼音首字母缩写 |
| `hasMultiPinyin(char)` | 多音字检测 |
| `similarDegree(String, String)` | N-gram 相似度（0~10000） |
| `lcsSimilarDegree(String, String)` | LCS 最长公共子序列相似度（0~10000） |
| `ngramSimilarDegree(String, String)` | N-gram 余弦相似度（0~10000） |
| `toSBC(String)` | 半角 → 全角 |
| `toDBC(String)` | 全角 → 半角 |

> 相似度返回值范围 0~10000（10000 = 完全相同）。`ngramSimilarDegree` 对少量字符差异更敏感，适合区分高度相似但不同的名称。

## HmacUtils

> **包路径**：`uw.common.util.HmacUtils`

HMAC-SHA256 签名工具类。

| 方法 | 说明 |
|------|------|
| `sign(String message, String secret)` | HMAC-SHA256 签名，返回十六进制字符串 |
| `verify(String message, String secret, String signature)` | 验证签名 |

## CurrencyUtils

> **包路径**：`uw.common.util.CurrencyUtils`

货币币种工具类。

| 字段/方法 | 说明 |
|----------|------|
| `CURRENCY_DEFAULT` | 默认币种 CNY |
| `getAvailableCurrencies()` | 获取可用货币集合 |
| `getCurrency(String code)` | 获取指定币种（异常返回 null） |
| `getCurrency(String code, Currency default)` | 获取指定币种（异常返回默认值） |

## LimitedVirtualThreadExecutor

> **包路径**：`uw.common.util.LimitedVirtualThreadExecutor`

背压限制虚拟线程执行器。基于虚拟线程 + Semaphore 实现最大并发数限制。

| 构造 | 说明 |
|------|------|
| `new LimitedVirtualThreadExecutor(int maxConcurrency)` | 默认阻塞等待策略 |
| `new LimitedVirtualThreadExecutor(int maxConcurrency, CallPolicy)` | 自定义策略 |

| 方法 | 说明 |
|------|------|
| `submit(Runnable)` | 提交任务 |
| `getActiveCount()` | 活跃任务数 |
| `getQueuedTasks()` | 等待任务数 |
| `getAvailablePermits()` | 可用许可数 |
| `getRejectedCount()` | 拒绝任务数 |
| `shutdown()` | 关闭执行器 |

**调用策略**：

| 策略类 | 行为 |
|--------|------|
| `BlockPolicy`（默认） | 阻塞等待直到获取许可 |
| `FailFastPolicy` | 快速失败，抛出 RejectedExecutionException |
| `CallerRunsPolicy` | 由调用者线程直接执行 |
| `DiscardPolicy` | 静默丢弃任务 |

```java
LimitedVirtualThreadExecutor executor = new LimitedVirtualThreadExecutor(100);
executor.submit(() -> doSomething());
executor.shutdown();
```

## 其他工具类

| 类名 | 核心方法 | 用途 |
|------|---------|------|
| `RSAUtils` | `generateKeyPair()` / `encrypt()` / `decrypt()` / `sign()` / `verify()` | RSA 非对称加密签名 |
| `DigestUtils` | `md5()` / `sha1()` / `sha256()` / `hmacSha256()` / `bytesToHex()` | 哈希摘要计算 |
| `IpMatchUtils` | `match(ip, pattern)` / `isInRange(ip, cidr)` | IP 匹配，支持 CIDR |
| `ByteArrayUtils` | `toHex()` / `fromHex()` / `concat()` / `slice()` | 字节数组操作 |
| `NumCodeUtils` | `encode()` / `decode()` | 数字编码混淆 |
| `EnumUtils` | `getEnum()` / `getEnumMap()` / `getEnumList()` / `enumNameToDotCase()` | 枚举转换工具 |
| `SnowflakeIdGenerator` | `getInstance().generateId()` | 分布式雪花ID（synchronized） |
| `ResponseCodeUtils` | `toPropertyString(Class)` / `toProperties(Class)` | 将 ResponseCode 枚举导出为 Properties |
| `SystemClock` | `now()` / `nowDate()` / `elapsedMillis(long)` | 高性能系统时钟（高频场景自动切换定时器模式），用于 `createDate`/`modifyDate` |
| `ExceptionUtils` | `exceptionToString(Throwable)` | 过滤框架堆栈的异常格式化（GlobalExceptionAdvice 使用） |
