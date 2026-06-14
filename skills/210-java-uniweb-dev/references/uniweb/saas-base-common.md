# saas-base-common — SaaS核心基础模块

**Maven 坐标**: `saas:saas-base-common`

**核心依赖**: uw-common / uw-common-app / uw-cache / uw-httpclient / uw-task / uw-mydb-client / uw-notify-client

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 获取租户信息 | `SaasInfoHelper.getSaasInfo(saasId)` | 静态方法 |
| 获取租户名称 | `SaasInfoHelper.getSaasName(saasId)` | — |
| 获取商户信息 | `SaasMchHelper.getMchInfo(saasId, mchId)` | — |
| 发送短信 | `MsgHelper.sendSms(MsgSmsVo)` | MsgSmsVo 需设 saasId/phone/content |
| 发送邮件 | `MsgHelper.sendMail(MsgMailVo)` | MsgMailVo 需设 saasId/to/subject/content |
| 获取上传参数 | `SysOssHelper.genUploadParam(...)` | — |
| 获取下载链接 | `SysOssHelper.getDownloadUrl(...)` | — |
| 查询字典 | `SysDictHelper.listDictByParentCode(code)` | 系统级 |
| SAAS字典 | `SaasDictHelper.listDictByParentCode(code)` | 租户级 |
| 国际化 | `LocaleHelper.getResolvedLocale()` | — |

## 核心 Helper 类

| Helper 类 | 功能 | 主要方法 |
|-----------|------|----------|
| `SaasInfoHelper` | 租户信息 | `getSaasInfo()` / `getSaasName()` / `getSaasCurrency()` / `getAllSaasIdList()` |
| `SaasMchHelper` | 商户信息 | `getMchInfo()` / `getMchName()` / `incrementSaleStats()` |
| `MsgHelper` | 消息通知 | `sendSms()` / `sendMail()` |
| `SysOssHelper` | 对象存储 | `genUploadParam()` / `getDownloadUrl()` / `getOssSite()` |
| `SysDictHelper` | 系统字典 | `listDictByParentCode()` |
| `SaasDictHelper` | SAAS字典 | `listDictByParentCode()` |
| `SysAreaHelper` | 地区信息 | `getSaasAreaInfoByAreaCode()` / `getCityAreaCode()` |
| `LocaleHelper` | 国际化 | `getResolvedLocale()` |

## SaasInfoHelper 方法签名

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getAllSaasIdList()` | `List<Long>` | 获取所有租户ID |
| `getSaasInfo(saasId)` | SaasInfoVo | 获取租户信息 |
| `getSaasName(saasId)` | String | 获取租户名称 |
| `getSaasCurrency(saasId)` | String | 获取租户币种 |
| `enable(saasId)` | void | 启用租户 |
| `disable(saasId)` | void | 停用租户 |
| `publishChangeNotify(saasId)` | void | 缓存变更通知 |

## SaasMchHelper 方法签名

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getMchInfo(saasId, mchId)` | SaasMchInfoVo | 获取商户信息 |
| `getMchName(saasId, mchId)` | String | 获取商户名称 |
| `getMchCurrency(saasId, mchId)` | String | 获取商户币种 |
| `saveMchInfo(SaasMchInfoVo)` | ResponseData | 保存商户信息 |
| `incrementSaleStats(...)` | void | 增加销量统计 |
| `publishChangeNotify(saasId, mchId)` | void | 缓存变更通知 |

## MsgHelper 方法签名

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `sendSms(MsgSmsVo)` | ResponseData | 发送短信 |
| `sendMail(MsgMailVo)` | ResponseData | 发送邮件 |

**MsgSmsVo 必填字段**：saasId / phone / content

**MsgMailVo 必填字段**：saasId / to / subject / content

## SysOssHelper 方法签名

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `genUploadParam(saasId, configSid, refType, refId, fileName, fileSize, accessType, expireDate)` | ResponseData | 获取预上传参数 |
| `getDownloadUrl(saasId, configSid, filename, ttl)` | ResponseData | 获取下载链接 |
| `getOssSite(saasId, configSid)` | ResponseData | 获取 OSS 站点地址 |

## Helper 使用示例

```java
public class SmsHelper {

    public static ResponseData sendVerifyCode(long saasId, String phone, String code) {
        MsgSmsVo sms = new MsgSmsVo();
        sms.setSaasId(saasId);
        sms.setPhone(phone);
        sms.setContent("您的验证码是：" + code);
        return MsgHelper.sendSms(sms);
    }
}
```
