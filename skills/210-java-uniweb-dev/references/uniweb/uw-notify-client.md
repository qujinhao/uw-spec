# uw-notify-client — 通知客户端

**Maven 坐标**: `com.umtone:uw-notify-client`

基于 SSE（Server-Sent Events）的实时通知推送客户端，用于向指定用户或运营商推送 Web 通知。

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `pushNotify(WebNotifyMsg)` | ResponseData | 推送 Web 通知 |

## WebNotifyMsg

> **包路径**：`uw.notify.client.WebNotifyMsg`

构造：`new WebNotifyMsg(long userId, long saasId, NotifyBody body)` — userId=0 广播，saasId=0 所有运营商

### NotifyBody

构造：`new WebNotifyMsg.NotifyBody(String type, Object data)` 或 setter 配置

| 字段 | 类型 | 说明 |
|------|------|------|
| type | String | 通知类型 |
| subject | String | 消息标题 |
| content | String | 消息内容 |
| data | Object | 消息数据（任意对象） |

## Helper 使用示例

```java
public class NotificationHelper {

    public static ResponseData notifyUser(long userId, long saasId, String title, String message) {
        WebNotifyMsg.NotifyBody body = new WebNotifyMsg.NotifyBody();
        body.setType("SYSTEM");
        body.setSubject(title);
        body.setContent(message);
        body.setData(Map.of("timestamp", System.currentTimeMillis()));
        return NotifyClientHelper.pushNotify(new WebNotifyMsg(userId, saasId, body));
    }

    public static void broadcast(String type, Object data) {
        NotifyClientHelper.pushNotify(new WebNotifyMsg(0L, 0L, new WebNotifyMsg.NotifyBody(type, data)));
    }
}
```
