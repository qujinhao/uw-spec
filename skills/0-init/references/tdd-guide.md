# TDD 驱动开发指南

> 跨技能共用的 TDD 方法论和通用示例。被 210-java-uniweb-dev、220-{四端}-dev、620-feature-dev、720-bugfix-dev 等所有开发技能引用。
>
> **范围说明**：TDD 仅覆盖**单元测试**（Helper/Controller/composable/Store/util）。API 测试、E2E 测试、压力测试、安全测试由测试工程师在 `630-feature-test`/`730-bugfix-test` 阶段执行，不属于 TDD 流程。

## 执行步骤

```
Step 1: 编写测试代码（基于设计/需求）
Step 2: 运行测试 → 确认失败（Red）     ← 验证测试有意义
Step 3: 编写实现代码
Step 4: 运行测试 → 确认通过（Green）   ← 验证实现正确
Step 5: 如需重构 → 运行测试确认仍通过
```

> 全自动执行，中间不暂停、不询问。全部通过后才向用户报告。

## Red 阶段验证规则

| 情况 | 含义 | 处理 |
|------|------|------|
| 测试失败（Red ✅） | 测试有效，能检测到缺失的实现 | 正常进入 Green |
| 测试意外通过 | 断言不够严格或测试无意义 | **必须加强断言后重新 Red** |

## 后端 Red-Green 执行命令

```bash
# Red 阶段：仅运行当前模块测试，确认失败
mvn test -Dtest={Module}HelperTest -pl {project-name}-app

# Green 阶段：运行当前模块测试，确认通过
mvn test -Dtest={Module}HelperTest,{role}/{module}/{Module}ControllerTest -pl {project-name}-app
```

## 前端 Red-Green 执行命令

```bash
# Red 阶段：运行当前测试文件，确认失败
pnpm vitest run src/composables/useXxx.spec.ts

# Green 阶段：运行当前测试文件，确认通过
pnpm vitest run src/composables/useXxx.spec.ts
```

## 后端 TDD 示例（Java）

### Red - 编写测试

```java
@Test
public void testQueryUserById_WithNullResult() {
    Long nonExistentUserId = 99999L;
    assertThrows(UserNotFoundException.class, () -> {
        userService.queryById(nonExistentUserId);
    });
}
```

### Green - 最少实现

```java
public User queryById(Long id) {
    User user = userMapper.selectById(id);
    if (user == null) {
        throw new UserNotFoundException("用户不存在: " + id);
    }
    return user;
}
```

### Refactor - 重构优化

```java
public User queryById(Long id) {
    return Optional.ofNullable(userMapper.selectById(id))
        .orElseThrow(() -> new UserNotFoundException("用户不存在: " + id));
}
```

## 前端 TDD 示例（TypeScript / Vitest）

### Red - 编写测试

```typescript
describe('calculateOrderAmount', () => {
  it('应该正确计算订单金额', () => {
    const items = [{ price: 100, quantity: 2 }]
    const result = calculateOrderAmount(items, 10)
    expect(result.totalAmount).toBe(210)
  })

  it('满199应免运费', () => {
    const items = [{ price: 100, quantity: 2 }]
    const result = calculateOrderAmount(items, 10)
    expect(result.shippingFee).toBe(0)
  })
})
```

### Green - 实现功能

```typescript
export function calculateOrderAmount(items: OrderItem[], shippingFee: number) {
  const goodsAmount = items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  const finalShippingFee = goodsAmount >= 199 ? 0 : shippingFee
  return { goodsAmount, shippingFee: finalShippingFee, totalAmount: goodsAmount + finalShippingFee }
}
```

## 前端测试范围

### ✅ 必须测试

| 测试对象 | 覆盖范围 | 示例 |
|---------|---------|------|
| composables / hooks | 业务逻辑分支、数据转换 | `useCart().addToCart()` 计算金额 |
| Store (Pinia) | 状态变更正确性、异步 action | `cartStore.addItem()` 状态更新 |
| 工具函数 | 边界条件、异常输入 | `formatPrice(undefined)` 返回默认值 |

### ❌ 不测试

| 不测试对象 | 原因 |
|-----------|------|
| 页面组件渲染 | UI 渲染属于框架职责，测试脆弱且维护成本高 |
| UI 样式 | 样式测试无实际价值 |
| 框架 API | Vue/UniApp 内部 API 无需测试 |
| 第三方库行为 | 第三方库自有测试 |
