# uw-gateway-client — 网关客户端

**Maven 坐标**: `com.umtone:uw-gateway-client`

网关管理客户端，用于管理运营商限速策略。

**配置前缀**: `uw.gateway`

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 设置运营商限速 | `GatewayClientHelper.updateSaasRateLimit(...)` | 静态方法 |
| 清除运营商限速 | `GatewayClientHelper.clearSaasRateLimit(saasId, remark)` | 静态方法 |

## GatewayClientHelper 方法签名

> **包路径**：`uw.gateway.client.GatewayClientHelper`

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `updateSaasRateLimit(saasId, limitSeconds, limitRequests, limitBytes, expireDate, remark)` | ResponseData | 设置运营商限速 |
| `clearSaasRateLimit(saasId, remark)` | ResponseData | 清除运营商限速 |

## Helper 使用示例

```java
public class GatewayHelper {

    public static ResponseData setRateLimit(long saasId) {
        return GatewayClientHelper.updateSaasRateLimit(
            saasId, 1, 100, 1024 * 1024, null, "防止接口滥用");
    }

    public static ResponseData clearRateLimit(long saasId) {
        return GatewayClientHelper.clearSaasRateLimit(saasId, "恢复正常访问");
    }
}
```
