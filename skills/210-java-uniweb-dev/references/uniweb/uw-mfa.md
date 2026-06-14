# uw-mfa — 多因素认证

**Maven 坐标**: `com.umtone:uw-mfa`

融合 IP 限制、验证码、设备码的多重认证库。

**配置前缀**: `uw.mfa`

```yaml
uw:
  mfa:
    # IP白名单，支持CIDR格式
    ip-white-list: "127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
    # IP限制配置
    ip-limit-seconds: 600          # 错误检查过期时间（秒）
    ip-limit-warn-times: 3         # 警告阈值次数
    ip-limit-error-times: 10       # 错误屏蔽阈值次数
    # 验证码配置
    captcha-expired-seconds: 180   # 验证码过期时间
    captcha-send-limit-seconds: 60 # 发送限制时间
    captcha-send-limit-times: 10   # 发送限制次数
    captcha-strategies: "StringCaptchaStrategy,CalculateCaptchaStrategy,SlidePuzzleCaptchaStrategy,ClickWordCaptchaStrategy,RotatePuzzleCaptchaStrategy"
    # 设备验证码配置
    device-code-expired-seconds: 300      # 过期时间
    device-code-default-length: 6         # 默认长度
    device-code-send-limit-seconds: 1800  # 发送限制时间
    device-code-send-limit-times: 10      # 发送限制次数
    device-code-verify-limit-seconds: 600 # 校验限制时间
    device-code-verify-error-times: 10    # 校验错误次数
    device-notify-subject: "设备验证码"
    device-notify-content: "设备验证码[$DEVICE_CODE$]，$EXPIRE_MINUTES$分钟后过期"
    # TOTP配置
    totp-algorithm: SHA1           # 算法：SHA1/SHA256/SHA512
    totp-secret-length: 32         # 密钥长度
    totp-code-length: 6            # 验证码长度
    totp-time-period: 30           # 时间窗口（秒）
    totp-time-period-discrepancy: 2 # 时间偏移量
    totp-verify-limit-seconds: 600  # 校验限制时间
    totp-verify-error-times: 10     # 校验错误次数
    totp-gen-qr: true              # 是否生成二维码
    totp-qr-size: 350              # 二维码尺寸
    totp-issuer: "uw-mfa"          # 签发人
    # Redis配置
    redis:
      database: 0
      host: 127.0.0.1
      port: 6379
```

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 检查IP白名单 | `MfaFusionHelper.checkIpWhiteList(ip)` | 返回 boolean |
| 检查IP错误限制 | `MfaFusionHelper.checkIpErrorLimit(ip)` | warn=需验证码，error=已屏蔽 |
| 递增IP错误次数 | `MfaFusionHelper.incrementIpErrorTimes(ip, remark)` | 密码错误时调用 |
| 生成验证码 | `MfaFusionHelper.generateCaptcha(ip, captchaId)` | warn 状态才生成 |
| 验证验证码 | `MfaFusionHelper.verifyCaptcha(ip, captchaId, captchaSign)` | — |
| 发送设备验证码 | `MfaFusionHelper.sendDeviceCode(ip, saasId, deviceType, deviceId)` | 自动IP检测 |
| 校验设备验证码 | `MfaFusionHelper.verifyDeviceCode(ip, deviceType, deviceId, code)` | — |
| 生成TOTP密钥 | `MfaFusionHelper.issueTotpSecret(label)` | 返回含 QR Base64 |
| 校验TOTP | `MfaFusionHelper.verifyTotpCode(ip, userInfo, secret, code)` | — |
| 生成恢复码 | `MfaFusionHelper.generateRecoveryCode(amount)` | — |

## MfaFusionHelper 方法签名

> **包路径**：`uw.mfa.MfaFusionHelper`

全部静态方法，无需实例化。

**IP限制**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `checkIpWhiteList(ip)` | boolean | IP是否在白名单 |
| `checkIpErrorLimit(ip)` | ResponseData | warn=需验证码，error=已屏蔽 |
| `incrementIpErrorTimes(ip, remark)` | void | 递增IP错误次数 |
| `clearIpErrorLimit(ip)` | boolean | 清除IP限制 |
| `getIpErrorLimitList()` | `Set<String>` | 获取IP限制列表 |

**验证码**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `generateCaptcha(ip, captchaId)` | `ResponseData<CaptchaQuestion>` | 生成验证码（warn状态才生成） |
| `verifyCaptcha(ip, captchaId, captchaSign)` | ResponseData | 验证验证码 |
| `getCaptchaSendLimitList()` | `Set<String>` | 获取验证码发送限制列表 |
| `clearCaptchaSendLimit(ip)` | boolean | 清除验证码发送限制 |

**设备验证码**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `sendDeviceCode(ip, saasId, deviceType, deviceId)` | ResponseData | 发送设备验证码 |
| `sendDeviceCode(ip, saasId, deviceType, deviceId, captchaId, captchaSign)` | ResponseData | 发送+验证码校验 |
| `verifyDeviceCode(deviceType, deviceId, code)` | ResponseData | 校验设备验证码 |
| `verifyDeviceCode(ip, deviceType, deviceId, code)` | ResponseData | 校验设备验证码（同时验证IP） |
| `getDeviceCodeSendLimitList()` | `Set<String>` | 获取发送限制列表 |
| `getDeviceCodeVerifyLimitList()` | `Set<String>` | 获取校验限制列表 |
| `clearDeviceCodeSendLimit(ip)` | boolean | 清除发送限制 |
| `clearDeviceCodeVerifyLimit(deviceId)` | boolean | 清除校验限制 |

**TOTP**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `issueTotpSecret(label)` | `ResponseData<TotpSecretData>` | 生成TOTP密钥 |
| `issueTotpSecret(label, issuer, qrSize)` | `ResponseData<TotpSecretData>` | 自定义签发人+二维码尺寸 |
| `verifyTotpCode(userInfo, secret, code)` | ResponseData | 校验TOTP |
| `verifyTotpCode(ip, userInfo, secret, code)` | ResponseData | 校验TOTP（同时验证IP） |
| `verifyTotpCode(ip, userInfo, secret, code, captchaId, captchaSign)` | ResponseData | 校验TOTP+验证码 |
| `generateRecoveryCode(amount)` | String[] | 生成恢复码 |
| `getTotpVerifyLimitList()` | `Set<String>` | 获取TOTP校验限制列表 |
| `clearTotpVerifyLimit(userInfo)` | boolean | 清除TOTP校验限制 |

## CaptchaQuestion

> **包路径**：`uw.mfa.CaptchaQuestion`

| 字段 | 类型 | 说明 |
|------|------|------|
| captchaId | String | 验证码ID |
| captchaTTL | long | 有效期（秒） |
| captchaType | String | 类型：String/Calculate/SlidePuzzle/ClickWord/RotatePuzzle |
| mainImageBase64 | String | 主图片 Base64 |
| subImageBase64 | String | 子图片 Base64（滑动/旋转用） |
| subData | String | 附加数据（AES加密） |

## TotpSecretData

> **包路径**：`uw.mfa.TotpSecretData`

| 字段 | 类型 | 说明 |
|------|------|------|
| secret | String | 密钥 |
| uri | String | 二维码URI（otpauth://） |
| qr | String | 二维码图片Base64 |

## MfaDeviceType 枚举

| 值 | 说明 |
|------|------|
| MOBILE_CODE(1) | 手机短信 |
| EMAIL_CODE(2) | 邮件 |

## 独立 Helper 类

| 类 | 功能 |
|------|------|
| `MfaIPLimitHelper` | IP限制（checkIpWhiteList/checkIpErrorLimit/incrementIpErrorTimes/clearIpErrorLimit） |
| `MfaCaptchaHelper` | 验证码（generateCaptcha/verifyCaptcha） |
| `MfaDeviceCodeHelper` | 设备验证码（sendDeviceCode/verifyDeviceCode） |
| `MfaTotpHelper` | TOTP（issue/verifyCode/generateRecoveryCode） |

## Helper 使用示例

```java
public class LoginHelper {

    // 完整登录流程（IP检测 + 验证码 + MFA）
    public static ResponseData login(String username, String password, String ip,
                              String captchaId, String captchaSign) {
        ResponseData ipCheck = MfaFusionHelper.checkIpErrorLimit(ip);
        if (ipCheck.isError()) return ipCheck;
        if (ipCheck.isWarn()) {
            ResponseData captchaCheck = MfaFusionHelper.verifyCaptcha(ip, captchaId, captchaSign);
            if (captchaCheck.isNotSuccess()) return captchaCheck;
        }
        User user = UserHelper.verifyPassword(username, password);
        if (user == null) {
            MfaFusionHelper.incrementIpErrorTimes(ip, "密码错误");
            return ResponseData.errorMsg("用户名或密码错误");
        }
        MfaFusionHelper.clearIpErrorLimit(ip);
        return ResponseData.success(user);
    }

    // 发送短信验证码（自动IP检测）
    public static ResponseData sendSmsCode(String mobile, String ip) {
        return MfaFusionHelper.sendDeviceCode(ip, 1001L, MfaDeviceType.MOBILE_CODE.getValue(), mobile);
    }

    // 校验短信验证码（同时验证IP）
    public static ResponseData verifySmsCode(String mobile, String code, String ip) {
        return MfaFusionHelper.verifyDeviceCode(ip, MfaDeviceType.MOBILE_CODE.getValue(), mobile, code);
    }

    // 生成TOTP密钥（绑定Google Authenticator）
    public static ResponseData<TotpSecretData> generateTotp(Long userId) {
        return MfaFusionHelper.issueTotpSecret("user:" + userId, "MyApp", 300);
    }

    // 校验TOTP验证码
    public static ResponseData verifyTotp(Long userId, String totpSecret, String totpCode, String ip) {
        return MfaFusionHelper.verifyTotpCode(ip, "user:" + userId, totpSecret, totpCode);
    }
}
```
