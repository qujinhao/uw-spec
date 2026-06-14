# saas-aip-module — AIP 产品授权计费模块

AIP 模块是整个 SaaS 平台的针对应用基础设施与产品授权的计费和授权核心，负责管理产品、服务、订单、授权许可、余额和发票等业务流程。
## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 查询授权 | `AipHelper.getLicense(saasId, licenseCode)` | 静态方法 |
| 按Vendor类查询 | `AipHelper.getLicense(VendorClass, saasId)` | — |
| 获取授权值 | `AipHelper.getLicenseValue(saasId, licenseCode)` | 返回 long |
| 扣减授权 | `AipHelper.checkAndDeductLicense(saasId, code, value)` | 先检查再扣减 |
| 批量扣减 | `AipHelper.batchCheckAndDeductLicense(saasId, code, batchValue, deductValue)` | 高性能场景 |
| 自定义Vendor | 实现 `AipAppVendor` 等接口 + `@Service` | Vendor 是 Spring Bean |

## Vendor 类型

| 类型 | 接口 | 计费方式 | 说明 |
|------|------|----------|------|
| License | `AipLicenseVendor` | LicenseValue 计数 | 按次数计费（短信、邮件） |
| App | `AipAppVendor` | LicensePeriod 周期 | 按时间计费（功能模块订阅） |
| AppLicense | `AipAppLicenseVendor` | 混合计费 | 时间+次数 |
| Task | `AipTaskVendor` | 单次任务计价 | 一次性任务 |

## AipHelper 方法签名

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getLicenseCodeByVendor(Class)` | String | 获取 LicenseCode |
| `getSaasLicenseMap(saasId)` | `Map<String, AipLicenseInfoVo>` | 获取租户所有授权 |
| `getLicense(saasId, licenseCode)` | AipLicenseInfoVo | 获取指定授权 |
| `getLicense(VendorClass, saasId)` | AipLicenseInfoVo | 按 Vendor 类获取 |
| `getLicenseValue(saasId, licenseCode)` | long | 获取授权值 |
| `checkAndDeductLicense(saasId, code, deductValue)` | ResponseData | 检查并扣减 |
| `batchCheckAndDeductLicense(saasId, code, batchValue, deductValue)` | ResponseData | 批量扣减 |
| `addLicense(saasId, licenseCode, value)` | ResponseData | 增加授权值 |
| `refundLicense(saasId, licenseCode, value)` | ResponseData | 退还授权值 |

## AipLicenseInfoVo

| 字段 | 类型 | 说明 |
|------|------|------|
| licenseCode | String | 授权编码 |
| licenseValue | long | 授权值（次数/金额） |
| licensePeriod | int | 授权周期类型 |
| startDate | Date | 开始日期 |
| endDate | Date | 结束日期 |
| state | int | 状态 |

## AipVendorExecuteParam

| 字段 | 类型 | 说明 |
|------|------|------|
| saasId | long | 租户ID |
| mchId | long | 商户ID |
| vendorCode | String | Vendor编码 |
| orderId | long | 订单ID |
| orderData | String | 订单数据（JSON） |

## AipVendor 接口

构造：实现对应接口 + `@Service` — 框架自动扫描注册。

| 接口 | 方法 | 说明 |
|------|------|------|
| `AipVendor` | `name()` / `code()` | 基础接口 |
| `AipAppVendor` | + `initData()` / `destroyData()` | App 类型 |
| `AipLicenseVendor` | + `initData()` / `destroyData()` | License 类型 |

## Vendor 实现示例

```java
// Vendor 实现类是 Spring Bean（由框架自动扫描注册），必须加 @Service。
// 这与 Helper（纯静态工具类，禁止 @Component）不同。
@Service
public class MallAppBaseVendor implements AipAppVendor {
    @Override
    public ResponseData initData(AipVendorExecuteParam runParam) {
        // 初始化商城所需的数据表和默认数据
        return ResponseData.success();
    }

    @Override
    public ResponseData destroyData(AipVendorExecuteParam runParam) {
        // 清理商城数据
        return ResponseData.success();
    }

    @Override
    public String name() { return "商城系统"; }

    @Override
    public String code() { return ""; }
}
```

## Helper 使用示例

```java
public class LicenseCheckHelper {

    public static ResponseData checkSmsLicense(long saasId) {
        AipLicenseInfoVo license = AipHelper.getLicense(saasId, "saas-base-app:sms");
        if (license == null || license.getLicenseValue() <= 0) {
            return ResponseData.warn("SMS_LICENSE_EXHAUSTED", "短信授权已用完");
        }
        return AipHelper.checkAndDeductLicense(saasId, "saas-base-app:sms", 1);
    }
}
```
