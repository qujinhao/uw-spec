# uw-oauth2-client — OAuth2客户端

**Maven 坐标**: `com.umtone:uw-oauth2-client`

轻量级 OAuth2 客户端，支持 Google/Apple/GitHub/微信/支付宝等平台，提供扫码登录和用户信息获取能力。

**配置前缀**: `uw.oauth2.client`

```yaml
uw:
  oauth2:
    client:
      redirect-uri: http://localhost:8080/ui/oauth2/redirect
      qrcode-uri: http://localhost:8080/oauth2/qrcode/
      providers:
        google:
          clientId: your-google-client-id
          clientSecret: your-google-client-secret
          # authUri, tokenUri, userInfoUri, authScope 使用默认值
        github:
          clientId: your-github-client-id
          clientSecret: your-github-client-secret
        apple:
          clientId: your-apple-client-id
          clientSecret: your-apple-client-secret
          extParam:
            privateKey: -----BEGIN EC PRIVATE KEY-----\n...
        wechat:
          clientId: your-wechat-appid
          clientSecret: your-wechat-secret
        alipay:
          clientId: your-alipay-appid
          clientSecret: your-alipay-private-key
          extParam:
            publicKey: your-alipay-public-key
```

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 网页授权登录 | `OAuth2ClientHelper.buildAuthUrl(provider, stateId)` | 先生成 stateId（格式：providerCode_authType_seqId） |
| 扫码登录 | `OAuth2ClientHelper.buildQrCode(provider)` | 轮询 `getAuthState(stateId)` 检查状态 |
| 获取令牌 | `OAuth2ClientHelper.getToken(provider, code, stateId, null)` | 在授权回调中调用 |
| 获取用户信息 | `OAuth2ClientHelper.getUserInfo(provider, token)` | 先 getToken 再 getUserInfo |
| 查询扫码状态 | `OAuth2ClientHelper.getAuthState(stateId)` | 返回 WAITING/SCANNED/CONFIRMED/EXPIRED/FAILED |
| 失效授权状态 | `OAuth2ClientHelper.invalidateAuthState(stateId)` | — |

## OAuth2ClientHelper 方法签名

> **包路径**：`uw.oauth2.client.OAuth2ClientHelper`

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `buildAuthUrl(provider, stateId)` | `ResponseData<String>` | 构建授权URL（跳转第三方登录页） |
| `buildQrCode(provider)` | `ResponseData<String>` | 构建二维码URL（扫码登录） |
| `getToken(provider, code, stateId, extParam)` | `ResponseData<OAuth2Token>` | 获取访问令牌（回调后调用） |
| `getUserInfo(provider, token)` | `ResponseData<OAuth2UserInfo>` | 获取用户信息 |
| `getAuthState(stateId)` | `OAuth2ClientAuthStatus` | 获取扫码状态（轮询用） |
| `invalidateAuthState(stateId)` | void | 失效授权状态 |
| `registerProvider(code, provider)` | void | 注册自定义 Provider |
| `getProvider(code)` | `OAuth2Provider` | 获取 Provider |
| `getConfigMap()` | `Map<String, ProviderConfig>` | 获取所有 Provider 配置 |

## OAuth2Token

> **包路径**：`uw.oauth2.client.OAuth2Token`

构造：`OAuth2Token.builder()` 或 `OAuth2Token.builder(copy)` — Builder 模式。也支持 `new OAuth2Token()` + setter

| 字段 | 类型 | 说明 |
|------|------|------|
| accessToken | String | 访问令牌 |
| refreshToken | String | 刷新令牌 |
| tokenType | String | 令牌类型（Bearer） |
| expiresIn | long | 过期时间（秒） |
| scope | String | 授权作用域 |
| idToken | String | ID令牌（OpenID Connect） |
| openId | String | 三方用户ID |
| unionId | String | 三方统一ID（微信等） |
| username | String | 用户名 |
| email | String | 邮箱 |
| phone | String | 手机号 |
| avatar | String | 头像 |
| error | String | 错误代码 |
| errorDescription | String | 错误描述 |
| rawParams | `Map<String, Object>` | 原始响应参数 |

## OAuth2UserInfo

> **包路径**：`uw.oauth2.client.OAuth2UserInfo`

构造：`OAuth2UserInfo.builder()` 或 `OAuth2UserInfo.builder(copy)` — Builder 模式。也支持 `new OAuth2UserInfo()` + setter

| 字段 | 类型 | 说明 |
|------|------|------|
| providerCode | String | 认证提供者（google/wechat等） |
| openId | String | 三方用户ID |
| unionId | String | 三方统一ID（微信等） |
| username | String | 用户名 |
| email | String | 邮箱 |
| phone | String | 手机号 |
| avatar | String | 头像URL |
| gender | String | 性别 |
| area | String | 地区 |
| address | String | 地址 |
| rawParams | `Map<String, Object>` | 原始用户信息 |

## OAuth2StateId

> **包路径**：`uw.oauth2.client.OAuth2StateId`

构造：`new OAuth2StateId(providerCode, authType, seqId)` — 格式：`providerCode_authType_seqId`

解析：`OAuth2StateId.parse(authStateId)` — 从字符串解析

| 字段 | 类型 | 说明 |
|------|------|------|
| providerCode | String | 提供者编码（google/wechat等） |
| authType | String | 授权类型（web/qrcode） |
| seqId | String | 序列ID |

## ProviderConfig

> **包路径**：`uw.oauth2.client.ProviderConfig`

| 字段 | 类型 | 说明 |
|------|------|------|
| clientId | String | 应用ID |
| clientSecret | String | 应用密钥 |
| extParam | `Map<String, Object>` | 扩展参数（如支付宝publicKey） |
| authUrl | String | 授权URL |
| tokenUrl | String | 令牌URL |
| userInfoUrl | String | 用户信息URL |
| scope | String | 授权范围 |

## OAuth2ClientAuthStatus 枚举

| 值 | 说明 |
|------|------|
| WAITING | 等待扫码 |
| SCANNED | 已扫码，等待确认 |
| CONFIRMED | 登录已确认 |
| EXPIRED | 已过期 |
| FAILED | 登录失败 |

## Controller 使用示例

```java
@RestController
@RequestMapping("/oauth2")
public class OAuth2Controller {
    
    /**
     * 获取授权URL（网页登录）
     */
    @GetMapping("/auth-url")
    public ResponseData<String> getAuthUrl(@RequestParam String provider) {
        // 生成stateId（格式：providerCode_authType_seqId）
        String stateId = generateStateId(provider, "web");
        
        ResponseData<String> response = OAuth2ClientHelper.buildAuthUrl(provider, stateId);
        return response;
    }
    
    /**
     * 获取二维码URL（扫码登录）
     */
    @GetMapping("/qrcode")
    public ResponseData<String> getQrCode(@RequestParam String provider) {
        return OAuth2ClientHelper.buildQrCode(provider);
    }
    
    /**
     * 授权回调处理
     */
    @GetMapping("/callback")
    public ResponseData<OAuth2UserInfo> callback(
            @RequestParam(required = false) String provider,
            @RequestParam String code,
            @RequestParam String state) {
        
        // 1. 获取访问令牌
        ResponseData<OAuth2Token> tokenResponse = OAuth2ClientHelper.getToken(
            provider, code, state, null);
        
        if (tokenResponse.isNotSuccess()) {
            return tokenResponse.raw();
        }
        
        OAuth2Token token = tokenResponse.getData();
        
        // 2. 获取用户信息
        ResponseData<OAuth2UserInfo> userInfoResponse = OAuth2ClientHelper.getUserInfo(
            provider, token);
        
        if (userInfoResponse.isNotSuccess()) {
            return userInfoResponse;
        }
        
        OAuth2UserInfo userInfo = userInfoResponse.getData();
        
        // 3. 处理登录逻辑（绑定用户或创建新用户）
        handleOAuth2Login(userInfo);
        
        return ResponseData.success(userInfo);
    }
    
    /**
     * 轮询扫码状态
     */
    @GetMapping("/status")
    public ResponseData<String> checkStatus(@RequestParam String stateId) {
        OAuth2ClientAuthStatus status = OAuth2ClientHelper.getAuthState(stateId);
        
        switch (status) {
            case CONFIRMED:
                // 登录成功，获取用户信息
                return ResponseData.success("CONFIRMED");
            case SCANNED:
                return ResponseData.success("SCANNED");
            case WAITING:
                return ResponseData.success("WAITING");
            case EXPIRED:
                return ResponseData.warn("EXPIRED", "二维码已过期");
            case FAILED:
                return ResponseData.error("FAILED", "登录失败");
            default:
                return ResponseData.error("UNKNOWN", "未知状态");
        }
    }
    
    /**
     * 自定义Provider示例（扩展支持其他平台）
     */
    @PostConstruct
    public void registerCustomProvider() {
        OAuth2Provider customProvider = new AbstractOAuth2Provider(
            "custom", providerConfig, redirectUri, qrcodeUri) {
            
            @Override
            public String buildAuthUrl(String authStateId) {
                // 自定义授权URL构建逻辑
                return "https://custom.com/oauth/authorize?...";
            }
            
            @Override
            public ResponseData<OAuth2Token> getToken(String authCode, String authStateId, 
                                                       Map<String, String> extParam) {
                // 自定义获取令牌逻辑
                return ResponseData.success(OAuth2Token.builder()...build());
            }
            
            @Override
            public ResponseData<OAuth2UserInfo> getUserInfo(OAuth2Token oAuth2Token) {
                // 自定义获取用户信息逻辑
                return ResponseData.success(OAuth2UserInfo.builder()...build());
            }
        };
        
        OAuth2ClientHelper.registerProvider("custom", customProvider);
    }
    
    private String generateStateId(String provider, String authType) {
        String seqId = System.currentTimeMillis() + "";
        return new OAuth2StateId(provider, authType, seqId).toString();
    }
    
    private void handleOAuth2Login(OAuth2UserInfo userInfo) {
        // 根据openId查询是否已绑定用户
        // 未绑定则创建新用户或引导绑定
        // 已绑定则直接登录
    }
}
```

## 支持的Provider

| Provider | 说明 | 特点 |
|---|---|---|
| `google` | Google登录 | 标准OAuth2，支持openid email profile |
| `github` | GitHub登录 | 标准OAuth2，支持user:email |
| `apple` | Apple登录 | Sign in with Apple，需处理privateKey |
| `wechat` | 微信登录 | 扫码登录，snsapi_login作用域 |
| `alipay` | 支付宝登录 | 需配置公钥/私钥 |
| `standard` | 标准OAuth2 | 用于其他标准OAuth2平台 |

