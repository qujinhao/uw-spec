# saas-finance-client — SaaS财务客户端

**Maven 坐标**: `saas:saas-finance-client`

提供支付通道、余额管理、汇率管理和对账等财务功能。

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 查询余额 | `FinBalanceHelper.getBalance(saasId, mchId, currency)` | 静态方法 |
| 预存消费 | `FinBalanceHelper.depositConsume(param)` | — |
| 预存退款 | `FinBalanceHelper.depositConsumeRefund(param)` | — |
| 佣金收入 | `FinBalanceHelper.rebateIncomeStart(param)` | — |
| 授信消费 | `FinBalanceHelper.creditConsume(param)` | — |
| 创建支付 | `FinPaymentHelper.payOrder(FinPayOrderRequest)` | 静态方法 |
| 支付退款 | `FinPaymentHelper.payRefund(FinPayRefundRequest)` | — |
| 查询汇率 | `FinCurrencyHelper.getCurrencyRate(saasId, from, to)` | — |
| 汇率计算 | `FinCurrencyHelper.calcCurrencyRate(rate, money)` | — |
| 对账 | 实现 `FinOrderBillInterface` | 业务系统实现 |
| 支付回调 | 实现 `FinPaymentNotifyInterface` | 业务系统实现 |

## 余额类型

| 类型 | 说明 | 操作 |
|------|------|------|
| 预存款 | 可充值、消费、退款、取现 | depositConsume / depositConsumeRefund / depositIncomeStart |
| 授信 | 永久/临时授信，需还款 | creditConsume / creditConsumeRefund |
| 佣金 | 仅收入、退款、取现 | rebateIncomeStart / rebateIncomeNotifySuccess |

## FinBalanceHelper 方法签名

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getBalance(saasId, mchId, currency)` | `ResponseData<FinBalanceInfoData>` | 查询指定币种余额 |
| `listBalance(saasId, mchId)` | `ResponseData<List<FinBalanceInfoData>>` | 查询所有币种余额 |
| `depositConsume(param)` | `ResponseData<FinBalanceLogData>` | 预存消费 |
| `depositConsumeRefund(param)` | `ResponseData<FinBalanceLogData>` | 预存退款 |
| `depositIncomeStart(param)` | `ResponseData<FinBalanceLogData>` | 存款收入（发起） |
| `depositIncomeNotifySuccess(param)` | ResponseData | 存款收入成功通知 |
| `depositIncomeNotifyFail(param)` | ResponseData | 存款收入失败通知 |
| `depositIncomeNotifyRefund(param)` | `ResponseData<FinBalanceLogData>` | 存款收入退款 |
| `creditConsume(param)` | `ResponseData<FinBalanceLogData>` | 授信消费 |
| `creditConsumeRefund(param)` | `ResponseData<FinBalanceLogData>` | 授信退款 |
| `rebateIncomeStart(param)` | `ResponseData<FinBalanceLogData>` | 佣金收入（发起） |
| `rebateIncomeNotifySuccess(param)` | ResponseData | 佣金收入成功通知 |
| `rebateIncomeNotifyFail(param)` | ResponseData | 佣金收入失败通知 |
| `rebateIncomeNotifyRefund(param)` | `ResponseData<FinBalanceLogData>` | 佣金收入退款 |
| `enable(saasId, mchId, currency)` | ResponseData | 启用账户 |
| `disable(saasId, mchId, currency)` | ResponseData | 停用账户 |

## FinPaymentHelper 方法签名

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `payOrder(FinPayOrderRequest)` | `ResponseData<FinPayOrderResponse>` | 创建支付 |
| `payRefund(FinPayRefundRequest)` | `ResponseData<FinPayRefundResponse>` | 支付退款 |

**支付通道**：通过 AIS Linker 机制，支持微信支付(WechatPaymentLinker)、支付宝(AliPayMentPaymentLinker)、合利宝(HelipayPaymentLinker)

## FinCurrencyHelper 方法签名

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getCurrencyRate(saasId, from, to)` | String | 获取汇率 |
| `calcCurrencyRate(rate, money)` | long | 汇率计算（money 为 long） |
| `calcCurrencyRate(rate, BigDecimal)` | long | 汇率计算（money 为 BigDecimal） |
| `queryCurrencyRateByDate(saasId, from, to, datePoint)` | `ResponseData<String>` | 查询历史汇率 |
| `updateCache(saasId)` | void | 更新缓存 |

## 对账接口（业务系统实现）

实现 `FinOrderBillInterface`：listSupplierPaymentSummary / listDistributorReceiptSummary / listOrderForVerify / batchVerify / batchCancelVerify / batchReceipt / batchPay

## 支付回调接口（业务系统实现）

实现 `FinPaymentNotifyInterface`：payNotify / refundNotify

## Helper 使用示例

```java
public class OrderPayHelper {

    // 创建支付订单
    public static ResponseData<FinPayOrderResponse> createPayment(long saasId, long mchId,
            long orderId, long amountFen) {
        // FinPayOrderRequest 使用 new + setter 构造
        FinPayOrderRequest request = new FinPayOrderRequest();
        request.setSaasId(saasId);
        request.setMchId(mchId);
        request.setBizOrderId(orderId);
        request.setBizOrderType("MALL_ORDER");
        request.setPayChannel(TypeFinPayChannel.WECHAT.getValue());
        request.setPayTradeType(TypeFinPayTrade.NATIVE.getValue());
        request.setOrderAmount(amountFen);  // 单位：分
        request.setOrderSubject("商品购买");

        ResponseData<FinPayOrderResponse> response = FinPaymentHelper.payOrder(request);
        response.onSuccess(payResponse -> {
            String payUrl = payResponse.getPayUrl();  // 支付链接或二维码
        });
        return response;
    }

    // 汇率计算
    public static long convertUsdToCny(long saasId, long usdAmount) {
        String rate = FinCurrencyHelper.getCurrencyRate(saasId, "USD", "CNY");
        return FinCurrencyHelper.calcCurrencyRate(rate, usdAmount);
    }
}
```
