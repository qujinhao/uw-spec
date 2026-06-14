# uw-httpclient — HTTP客户端

**Maven 坐标**: `com.umtone:uw-httpclient`

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| JSON接口 | `JsonInterfaceHelper` | 构造 `new JsonInterfaceHelper()` 或 `new JsonInterfaceHelper(config)` |
| XML接口 | `XmlInterfaceHelper` | 同上 |
| GET请求 | `helper.getForEntity(url, Class)` | 返回 `HttpEntity<HttpData, T>`，取 `.getBody()` |
| 带参数GET | `helper.getForEntity(url, Class, queryParams)` | queryParams 为 `Map<String, String>` |
| POST请求 | `helper.postForEntity(url, Class, body)` | body 自动 JSON 序列化 |
| PUT请求 | `helper.putForEntity(url, Class, body)` | — |
| DELETE请求 | `helper.deleteForEntity(url, Class)` | — |
| 文件上传 | `helper.uploadForEntity(url, Class, formName, file)` | formName 为表单字段名 |
| 文件下载 | `helper.download(url)` | 返回 `byte[]` |
| 自定义请求 | `helper.requestForData(Request)` | OkHttp 原生 Request |
| 自定义配置 | `new JsonInterfaceHelper(HttpConfig.builder()...build())` | — |

## 核心入口类

| 类 | 说明 |
|---|---|
| `JsonInterfaceHelper` | JSON 接口帮助类（继承 HttpInterface） |
| `XmlInterfaceHelper` | XML 接口帮助类（继承 HttpInterface） |

构造：`new JsonInterfaceHelper()` 或 `new JsonInterfaceHelper(HttpConfig)`

## HttpInterface 方法签名

> **包路径**：`uw.httpclient.HttpInterface`

**带响应体转换（返回 HttpEntity）**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getForEntity(url, Class<T>)` | `HttpEntity<HttpData, T>` | GET 请求 |
| `getForEntity(url, Class<T>, Map params)` | `HttpEntity<HttpData, T>` | GET + 查询参数 |
| `getForEntity(url, Class<T>, Map headers, Map params)` | `HttpEntity<HttpData, T>` | GET + Header + 参数 |
| `postForEntity(url, Class<T>, Object body)` | `HttpEntity<HttpData, T>` | POST JSON |
| `postForEntity(url, Class<T>, Map headers, Object body)` | `HttpEntity<HttpData, T>` | POST + Header |
| `putForEntity(url, Class<T>, Object body)` | `HttpEntity<HttpData, T>` | PUT JSON |
| `deleteForEntity(url, Class<T>)` | `HttpEntity<HttpData, T>` | DELETE |
| `uploadForEntity(url, Class<T>, formName, File)` | `HttpEntity<HttpData, T>` | 文件上传 |
| `uploadForEntity(url, Class<T>, formName, File, Map extraParam)` | `HttpEntity<HttpData, T>` | 文件上传+额外参数 |

**不带响应体转换（返回 HttpData）**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getForData(url)` | `HttpData` | GET（不需要转换响应） |
| `getForData(url, Map params)` | `HttpData` | GET + 参数 |
| `getForData(url, Map headers, Map params)` | `HttpData` | GET + Header + 参数 |
| `postForData(url, Object body)` | `HttpData` | POST |
| `postForData(url, Map headers, Object body)` | `HttpData` | POST + Header |
| `putForData(url, Object body)` | `HttpData` | PUT |
| `deleteForData(url)` | `HttpData` | DELETE |
| `requestForData(Request)` | `HttpData` | 自定义 OkHttp Request |

**文件下载**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `download(url)` | `byte[]` | 文件下载 |
| `download(url, Map params)` | `byte[]` | 带参数文件下载 |

> 支持泛型响应：`getForEntity(url, new TypeReference<List<User>>(){}, params)`

## HttpEntity

> **包路径**：`uw.httpclient.HttpEntity`

构造：由 `*ForEntity` 方法返回，不直接构造。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getHttpData()` | `HttpData` | HTTP 日志数据（URL/状态码/响应数据等） |
| `getBody()` | T | 转换后的响应体 |

## HttpData 字段

requestUrl / requestMethod / requestHeader / requestData / requestSize / statusCode / responseData / responseSize / responseType / errorInfo / requestDate / responseDate

## HttpConfig

> **包路径**：`uw.httpclient.HttpConfig`

构造：`HttpConfig.builder().connectTimeout(5000).readTimeout(30000).build()`

| 属性 | 类型 | 说明 |
|------|------|------|
| connectTimeout | long | 连接超时（毫秒） |
| readTimeout | long | 读超时（毫秒） |
| writeTimeout | long | 写超时（毫秒） |
| retryOnConnectionFailure | boolean | 连接失败重试 |
| maxRequestsPerHost | int | 每主机最大并发 |
| maxRequests | int | 全局最大并发 |
| maxIdleConnections | int | 连接池最大空闲连接 |
| keepAliveTimeout | long | 空闲连接存活时间 |

## SSL 自签名证书

```java
SSLContext sslContext = SSLContextUtils.createTrustAllSSLContext();
HttpConfig config = HttpConfig.builder()
    .sslSocketFactory(sslContext.getSocketFactory())
    .trustManager(SSLContextUtils.TRUST_ALL_MANAGER)
    .hostnameVerifier(SSLContextUtils.ALLOW_ALL_HOSTNAME_VERIFIER)
    .build();
JsonInterfaceHelper helper = new JsonInterfaceHelper(config);
```

## Helper 使用示例

```java
public class HttpHelper {
    private static final JsonInterfaceHelper jsonHttpHelper = new JsonInterfaceHelper();

    public static User getUser(long userId) {
        return jsonHttpHelper.getForEntity("https://api.example.com/users/" + userId, User.class).getBody();
    }

    public static List<User> listUsers(String keyword, int page) {
        Map<String, String> params = new HashMap<>();
        params.put("keyword", keyword);
        params.put("page", String.valueOf(page));
        return jsonHttpHelper.getForEntity("https://api.example.com/users", new TypeReference<List<User>>() {}, params).getBody();
    }

    public static User createUser(CreateUserRequest request) {
        return jsonHttpHelper.postForEntity("https://api.example.com/users", User.class, request).getBody();
    }

    // 自定义 Header
    public static User requestWithHeaders() {
        Map<String, String> headers = new HashMap<>();
        headers.put("Authorization", "Bearer token123");
        return jsonHttpHelper.getForEntity("https://api.example.com/users/1", User.class, headers, null).getBody();
    }

    // 文件上传
    public static String uploadFile(File file) {
        return jsonHttpHelper.uploadForEntity("https://api.example.com/upload", UploadResult.class, "file", file).getBody().getUrl();
    }

    public static byte[] downloadFile(String fileUrl) {
        return jsonHttpHelper.download(fileUrl);
    }
}
```

## SSL自签名证书支持

```java
// 信任所有证书（仅测试使用）
HttpConfig config = HttpConfig.builder()
    .sslSocketFactory(SSLContextUtils.getTruestAllSocketFactory())
    .trustManager(SSLContextUtils.getTrustAllManager())
    .hostnameVerifier((hostName, sslSession) -> true)
    .build();

JsonInterfaceHelper jsonHttpHelper = new JsonInterfaceHelper(config);
```

