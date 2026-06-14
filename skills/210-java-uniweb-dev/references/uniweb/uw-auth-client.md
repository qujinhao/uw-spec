# uw-auth-client — 认证客户端

**Maven 坐标**: `com.umtone:uw-auth-client`

内部 RPC 鉴权客户端。

**配置前缀**: `uw.auth.client`

```yaml
uw:
  auth:
    client:
      login-id: rpc-user
      login-pass: rpc-pass
```

**注入 Bean**：
- `authRestClient` — 自动注入 Token 的 RestClient（@Primary）
- `authWebClient` — 自动注入 Token 的 WebClient（@Primary）


**使用示例**：

```java
@Service
public class RemoteService {
    
    // 注入带鉴权的 RestClient（自动管理 Token）
    public RemoteService(RestClient authRestClient) {
        this.authRestClient = authRestClient;
    }
    
    public String callRemoteApi() {
        return authRestClient.get()
            .uri("http://uw-other-center/api/data")
            .retrieve()
            .body(String.class);
    }
}
```
