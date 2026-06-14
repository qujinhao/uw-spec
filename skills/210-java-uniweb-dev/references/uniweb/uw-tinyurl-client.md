# uw-tinyurl-client — 短链接客户端

**Maven 坐标**: `com.umtone:uw-tinyurl-client`

短链接生成与解析客户端，支持密语保护和过期时间。

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 生成短链接 | `TinyurlClientHelper.generate(TinyurlParam)` | 静态方法，返回短链接码 |
| 带密语 | param 设置 `.secretData(secret)` | 访问时需输入密语 |
| 带过期 | param 设置 `.expireDate(date)` | — |

## TinyurlClientHelper 方法签名

> **包路径**：`uw.tinyurl.client.TinyurlClientHelper`

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `generate(TinyurlParam)` | `ResponseData<String>` | 生成短链接（返回短码） |

## TinyurlParam

> **包路径**：`uw.tinyurl.client.TinyurlParam`

构造：`TinyurlParam.builder().saasId(saasId).url(longUrl).build()` — Builder 模式。也支持 `new TinyurlParam()` + setter

| 字段 | 类型 | 说明 |
|------|------|------|
| saasId | long | 运营商ID |
| objectType | String | 对象类型（分类统计用） |
| objectId | long | 对象ID |
| url | String | 原始长URL（必填） |
| secretTips | String | 密语提示 |
| secretData | String | 密语（访问时需输入） |
| expireDate | Date | 过期时间 |

## Helper 使用示例

```java
public class ShortUrlHelper {

    public static String createShortUrl(long saasId, String longUrl) {
        TinyurlParam param = TinyurlParam.builder()
            .saasId(saasId).objectType("LINK").url(longUrl).build();
        ResponseData<String> response = TinyurlClientHelper.generate(param);
        return response.isSuccess() ? "https://t.example.com/" + response.getData() : null;
    }

    public static String createSecretUrl(long saasId, String longUrl, String secret) {
        TinyurlParam param = TinyurlParam.builder()
            .saasId(saasId).objectType("SECRET_LINK").url(longUrl)
            .secretTips("请输入访问密码").secretData(secret)
            .expireDate(new Date(System.currentTimeMillis() + 7L * 24 * 3600 * 1000))
            .build();
        return TinyurlClientHelper.generate(param).getData();
    }
}
```
