# 安全扫描脚本

## 1. ZAP 扫描脚本 (zap-scan.sh)

```bash
#!/bin/bash
ZAP_PORT=${ZAP_PORT:-8090}
TARGET_URL=${TARGET_URL:-"http://localhost:8080"}
REPORT_DIR=${REPORT_DIR:-"test/reports/security"}
TIMESTAMP=$(date +%y%m%d%H%M)

echo "Starting ZAP scan for: $TARGET_URL"

zap-cli -p $ZAP_PORT quick-scan -s xss,sqli,pathtraversal "$TARGET_URL" \
  -f json -o "$REPORT_DIR/zap-scan-$TIMESTAMP.json"

zap-cli -p $ZAP_PORT report -f json -o "$REPORT_DIR/zap-report-$TIMESTAMP.json"
zap-cli -p $ZAP_PORT report -f html -o "$REPORT_DIR/zap-report-$TIMESTAMP.html"

echo "ZAP scan complete. Report: $REPORT_DIR/zap-report-$TIMESTAMP"
```

### ZAP 排除路径配置
```
- /static/*
- /health
- /actuator/*
- /swagger-ui/*
- /v3/api-docs/*
```

## 2. Trivy 扫描脚本 (trivy-scan.sh)

```bash
#!/bin/bash
REPORT_DIR=${REPORT_DIR:-"test/reports/security"}
TIMESTAMP=$(date +%y%m%d%H%M)

echo "Scanning backend dependencies..."
trivy fs --format json --output "$REPORT_DIR/trivy-backend-$TIMESTAMP.json" \
  backend/{project}/

echo "Scanning frontend dependencies..."
trivy fs --format json --output "$REPORT_DIR/trivy-frontend-$TIMESTAMP.json" \
  {project}-web/

echo "Scanning Docker image..."
trivy image --format json --output "$REPORT_DIR/trivy-image-$TIMESTAMP.json" \
  {project}:latest

echo "Generating summary..."
trivy fs --format table backend/{project}/ > "$REPORT_DIR/trivy-summary-$TIMESTAMP.txt"

echo "Trivy scan complete."
```

### Trivy 严重级别配置
```yaml
severity: CRITICAL,HIGH
exit-code: 1
ignorefile: .trivyignore
```

## 3. Playwright 安全测试脚本

```typescript
import { test, expect } from '@playwright/test';

test.describe('安全测试 - SQL注入', () => {
  test('登录接口SQL注入防护', async ({ request }) => {
    const response = await request.post('/api/auth/login', {
      data: {
        username: "admin' OR 1=1 --",
        password: "anything",
      },
    });
    expect(response.status()).toBe(401);
    const body = await response.json();
    expect(body.code).not.toBe(200);
  });

  test('查询接口SQL注入防护', async ({ request }) => {
    const response = await request.get('/api/v1/users?name=' + encodeURIComponent("' UNION SELECT * FROM users --"));
    expect([400, 403]).toContain(response.status());
  });
});

test.describe('安全测试 - XSS', () => {
  test('输入XSS脚本被转义', async ({ request }) => {
    const xssPayload = '<script>alert(1)</script>';
    const response = await request.post('/api/v1/comments', {
      data: { content: xssPayload },
    });
    const body = await response.json();
    expect(body.data.content).not.toContain('<script>');
  });
});

test.describe('安全测试 - 越权', () => {
  test('水平越权 - 访问他人订单', async ({ request }) => {
    const response = await request.get('/api/v1/orders/OTHER_USER_ORDER_ID', {
      headers: { Authorization: 'Bearer current-user-token' },
    });
    expect(response.status()).toBe(403);
  });

  test('垂直越权 - guest访问admin接口', async ({ request }) => {
    const response = await request.post('/api/v1/admin/users', {
      headers: { Authorization: 'Bearer guest-token' },
      data: { username: 'hacker', email: 'h@e.com', password: 'Hack@123' },
    });
    expect(response.status()).toBe(403);
  });
});

test.describe('安全测试 - 认证', () => {
  test('过期Token访问', async ({ request }) => {
    const response = await request.get('/api/v1/profile', {
      headers: { Authorization: 'Bearer expired-token' },
    });
    expect(response.status()).toBe(401);
  });

  test('无Token访问受保护接口', async ({ request }) => {
    const response = await request.get('/api/v1/profile');
    expect(response.status()).toBe(401);
  });
});
```
