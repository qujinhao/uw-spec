# UniApp 管理端开发示例

> 展示 API 对接、页面开发、平台适配等通用模式。类型从 `@/api/` 导入。

## API 调用模式

> API 调用已由 `src/api/` 封装，页面中禁止直接使用 `uni.request`。

### 列表页 API 对接

```typescript
import { adminProductList } from '@/api/adminProduct'
import type { ProductInfo } from '@/api/adminProduct'

const fetchList = async (isRefresh = false) => {
  if (loading.value) return
  loading.value = true
  try {
    if (isRefresh) pageNum.value = 1
    const res = await adminProductList({
      param: {
        $pg: pageNum.value,
        $rn: 20,
        keyword: keyword.value || undefined,
        status: currentFilter.value === 'all' ? undefined : currentFilter.value,
      }
    })
    const results = res.data?.results || []
    if (isRefresh) {
      listData.value = results
    } else {
      listData.value.push(...results)
    }
    hasMore.value = results.length >= 20
    pageNum.value++
  } finally {
    loading.value = false
  }
}
```

### 详情页 API 对接

```typescript
import { adminProductLoad } from '@/api/adminProduct'
import type { ProductInfo } from '@/api/adminProduct'

const loadDetail = async (id: number) => {
  const res = await adminProductLoad({ id })
  detail.value = res.data ?? null
}
```

### 表单提交

```typescript
import { adminProductCreate, adminProductUpdate } from '@/api/adminProduct'
import type { ProductForm } from '@/api/adminProduct'

const handleSubmit = async () => {
  if (!form.value.productName.trim()) {
    uni.showToast({ title: '请输入名称', icon: 'none' })
    return
  }
  if (isEdit.value) {
    await adminProductUpdate({ data: form.value })
  } else {
    await adminProductCreate({ data: form.value })
  }
  uni.showToast({ title: '保存成功', icon: 'success' })
  setTimeout(() => uni.navigateBack(), 1500)
}
```

## 平台适配

### 条件编译

```typescript
// #ifdef MP-WEIXIN
// 微信小程序专用代码
// #endif

// #ifdef H5
// H5 专用代码
// #endif

// #ifdef APP-PLUS
// App 专用代码
// #endif
```

### 平台差异对照

| 特性 | 微信小程序 | H5 | App |
|-----|-----------|-----|-----|
| 登录 | `uni.login({ provider: 'weixin' })` | 账号密码登录 | `plus.oauth.getServices()` |
| 扫码 | `uni.scanCode()` | 不支持 | `uni.scanCode()` |
| 推送 | 微信模板消息 | WebSocket | `plus.push.addEventListener()` |

## TDD 示例

```typescript
import { describe, it, expect } from 'vitest'

describe('calculateOrderAmount', () => {
  it('应该正确计算订单金额', () => {
    const items = [{ price: 100, quantity: 2 }, { price: 50, quantity: 1 }]
    const amount = calculateOrderAmount(items, 10)
    expect(amount.totalAmount).toBe(260)
  })
})

export function calculateOrderAmount(items: OrderItem[], shippingFee: number) {
  const goodsAmount = items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  const finalShippingFee = goodsAmount >= 199 ? 0 : shippingFee
  return { goodsAmount, shippingFee: finalShippingFee, totalAmount: goodsAmount + finalShippingFee }
}
```
