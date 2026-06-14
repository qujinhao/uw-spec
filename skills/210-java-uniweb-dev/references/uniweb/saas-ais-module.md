# saas-ais-module — AIS 应用接口服务模块

AIS 模块提供可插拔的应用接口服务管理框架，通过 Linker（链接器）机制实现不同服务提供商的统一接入。

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 获取链接器实例(按Linker类) | `AisHelper.getFitLinkerInstanceByLinker(saasId, LinkerClass, mchId, configSid)` | 静态方法 |
| 获取链接器实例(按Type类) | `AisHelper.getFitLinkerInstanceByType(saasId, TypeClass, mchId, configSid)` | — |
| 列出所有链接器实例 | `AisHelper.listLinkerInstanceByLinker(...)` | 返回 List |
| 按配置ID获取 | `AisHelper.getLinkerInstance(configId)` | — |
| 自定义Linker | 继承 `BaseAisLinker` + `@Service` | Linker 是 Spring Bean |
| 刷新缓存 | `AisHelper.linkerConfigChangeNotify(configId)` | — |

## AIS 架构

| 概念 | 说明 |
|------|------|
| **LinkerType（链接器类型）** | 定义一类接口的抽象，如邮件、短信、支付 |
| **Linker（链接器）** | 具体的接口实现，如 SMTP 邮件、AWS SES 邮件 |
| **LinkerConfig（链接器配置）** | 运营商/商户的具体配置参数 |

## AisHelper 方法签名

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `listLinkerConfigMetaByLinker(saasId, Class, mchId, configSid)` | `List<AisLinkerConfigMeta>` | 按Linker类查配置列表 |
| `listLinkerInstanceByLinker(saasId, Class, mchId, configSid)` | `List<A>` | 按Linker类获取实例列表 |
| `getFitLinkerInstanceByLinker(saasId, Class, mchId, configSid)` | A | 按Linker类获取单个实例 |
| `getFitLinkerInstanceByType(saasId, Class, mchId, configSid)` | A | 按Type类获取单个实例 |
| `getLinkerConfigData(configId)` | AisLinkerConfigData | 按配置ID获取 |
| `getLinkerInstance(configId)` | A | 按配置ID获取实例 |
| `linkerConfigChangeNotify(configId)` | void | 配置变更通知 |
| `linkerMetaChangeNotify(saasId)` | void | 元数据变更通知 |

## AisLinker 接口

构造：继承 `BaseAisLinker` + `@Service` — 框架自动扫描注册。

| 方法 | 说明 |
|------|------|
| `typeName()` | 类型名称 |
| `typeVersion()` | 类型版本 |
| `name()` | 链接器名称 |
| `version()` | 链接器版本 |
| `pubParam()` | 公开配置参数（所有人可见） |
| `apiParam()` | API配置参数（运营商可见） |
| `sysParam()` | 系统配置参数（管理员可见） |
| `logParam()` | 日志配置参数 |

**BaseAisLinker 参数获取**：`getParam(name)` / `getIntParam(name)` / `getLongParam(name)` / `getBooleanParam(name)`

## JsonConfigParam

构造：`new JsonConfigParam(name, ParamType, defaultValue, desc, children)`

| 字段 | 类型 | 说明 |
|------|------|------|
| name | String | 参数名称 |
| paramType | ParamType | 参数类型：STRING / INT / LONG / DOUBLE / BOOLEAN / SELECT / GROUP |
| defaultValue | String | 默认值 |
| desc | String | 参数描述 |
| children | `List<JsonConfigParam>` | 子参数（GROUP 类型时使用） |
| required | boolean | 是否必填 |
| options | `List<String>` | 可选项（SELECT 类型时使用） |

## AisLinkerConfigMeta

| 字段 | 类型 | 说明 |
|------|------|------|
| configId | long | 配置ID |
| linkerName | String | 链接器名称 |
| configSid | String | 配置标识 |
| configData | String | 配置数据（JSON） |

## AisLinkerConfigData

| 字段 | 类型 | 说明 |
|------|------|------|
| configId | long | 配置ID |
| configName | String | 配置名称 |
| mchId | long | 商户ID |
| linkerClass | String | 链接器类名 |
| pubData | String | 公开参数（JSON） |
| apiData | String | API参数（JSON） |
| sysData | String | 系统参数（JSON） |

## Linker 实现示例

```java
// Linker 实现类是 Spring Bean（由框架自动扫描注册），必须加 @Service。
// 这与 Helper（纯静态工具类，禁止 @Component）不同。
@Service
public class WechatPaymentLinker extends BaseAisLinker {
    @Override public String typeName() { return "支付网关接口"; }
    @Override public String typeVersion() { return "1.0.0"; }
    @Override public String name() { return "微信支付"; }
    @Override public String version() { return "1.0.0"; }
    @Override public String devInfo() { return "axeon"; }
    @Override public String typeDevInfo() { return "axeon"; }

    @Override
    public List<JsonConfigParam> apiParam() {
        return Arrays.asList(
            new JsonConfigParam("appId", ParamType.STRING, "", "应用ID", null),
            new JsonConfigParam("mchId", ParamType.STRING, "", "商户号", null),
            new JsonConfigParam("apiKey", ParamType.STRING, "", "API密钥", null)
        );
    }

    @Override public List<JsonConfigParam> pubParam() { return Collections.emptyList(); }
    @Override public List<JsonConfigParam> sysParam() { return Collections.emptyList(); }
    @Override public List<JsonConfigParam> logParam() { return Collections.emptyList(); }

    // 业务方法：调用微信支付API处理支付
    public ResponseData<FinPayOrderResponse> payOrder(PayOrderInfo payOrderInfo) {
        // 实现微信支付逻辑
    }
```

## Helper 使用示例

```java
public class PaymentHelper {

    public static ResponseData pay(long saasId, long mchId, PayOrderInfo orderInfo) {
        WechatPaymentLinker linker = AisHelper.getFitLinkerInstanceByLinker(
            saasId, WechatPaymentLinker.class, mchId, null);
        return linker.payOrder(orderInfo);
    }
}
```
