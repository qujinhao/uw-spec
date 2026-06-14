# 测试执行示例

## 1. API 测试执行

```bash
cd test/scripts

pnpm playwright test api/ --project=api \
  --reporter=html,json \
  --output=../reports/api/results-$(date +%y%m%d%H%M).json

# 输出报告
# test/reports/api/report-YYMMDDHHMM.html
```

### API 测试报告摘要模板
```markdown
# API测试报告

## 统计
| 指标 | 值 |
|------|-----|
| 总用例数 | {N} |
| 通过 | {N} |
| 失败 | {N} |
| 跳过 | {N} |
| 通过率 | {N}% |
| 执行时间 | {N}s |

## 失败用例
| 用例ID | 接口 | 错误信息 |
|--------|------|---------|
| TC-API-XXX | POST /api/v1/xxx | Expected 201, got 500 |
```

## 2. E2E 测试执行

```bash
cd test/scripts

# 单终端 - 指定前端项目
pnpm playwright test e2e/guest-uni/ --project=e2e \
  --reporter=html,json

# 跨终端
pnpm playwright test e2e/cross-case/ --project=e2e \
  --reporter=html,json

# 输出报告
# test/reports/e2e/report-YYMMDDHHMM.html
```

## 3. JMeter 压测执行

```bash
cd test/scripts

# 基准测试
jmeter -n -t load/order-baseline.jmx \
  -Jhost=api.example.com -Jport=8080 \
  -l ../reports/load/baseline-$(date +%y%m%d%H%M).jtl \
  -e -o ../reports/load/baseline-report-$(date +%y%m%d%H%M)

# 负载测试
jmeter -n -t load/order-load.jmx \
  -Jthreads=200 -Jrampup=60 -Jduration=300 \
  -l ../reports/load/load-$(date +%y%m%d%H%M).jtl \
  -e -o ../reports/load/load-report-$(date +%y%m%d%H%M)

# 压力测试
jmeter -n -t load/order-stress.jmx \
  -Jthreads=1000 -Jrampup=120 -Jduration=600 \
  -l ../reports/load/stress-$(date +%y%m%d%H%M).jtl \
  -e -o ../reports/load/stress-report-$(date +%y%m%d%H%M)
```

### 压测报告摘要模板
```markdown
# 压力测试报告

## 场景: {场景名}
| 指标 | 目标值 | 实际值 | 结果 |
|------|--------|--------|------|
| P95响应时间 | < 200ms | 180ms | ✅ |
| P99响应时间 | < 500ms | 420ms | ✅ |
| TPS | > 500 | 620 | ✅ |
| 错误率 | < 0.1% | 0.05% | ✅ |
```

## 4. 安全扫描执行

```bash
cd test/scripts

# ZAP扫描
bash security/zap-scan.sh

# Trivy扫描
bash security/trivy-scan.sh

# Playwright安全测试
pnpm playwright test security/ --project=api \
  --reporter=html,json

# 输出报告
# test/reports/security/zap-report-YYMMDDHHMM.html
# test/reports/security/trivy-report-YYMMDDHHMM.json
```

### 安全扫描报告摘要模板
```markdown
# 安全扫描报告

## ZAP 扫描结果
| 风险级别 | 数量 |
|---------|------|
| High | 0 |
| Medium | 2 |
| Low | 5 |
| Informational | 10 |

## Trivy 扫描结果
| 严重级别 | 后端 | 前端 | 镜像 |
|---------|------|------|------|
| Critical | 0 | 0 | 0 |
| High | 1 | 0 | 0 |
| Medium | 3 | 2 | 1 |
```

## 5. 缺陷记录模板

```markdown
### BUG-API-001
**标题**: 创建用户接口返回500
**严重程度**: 严重
**优先级**: 高
**关联用例**: TC-API-USER-003
**复现步骤**:
1. POST /api/v1/users
2. Body: {"username": "test", "email": "t@e.com", "password": "Test@123"}
**预期结果**: 201 Created
**实际结果**: 500 Internal Server Error
**错误日志**: NullPointerException in UserController.java:45
**环境**: http://api.example.com:8080
```

## 6. 汇总报告模板

```markdown
# 测试执行汇总报告

## 执行概要
| 测试类型 | 总用例 | 通过 | 失败 | 跳过 | 通过率 |
|---------|--------|------|------|------|--------|
| API测试 | 80 | 78 | 2 | 0 | 97.5% |
| E2E单终端 | 45 | 44 | 1 | 0 | 97.8% |
| E2E跨终端 | 8 | 8 | 0 | 0 | 100% |
| 压力测试 | 4场景 | 4 | 0 | 0 | 100% |
| 安全扫描 | 3扫描 | 3 | 0 | 0 | 100% |

## 缺陷统计
| 级别 | 数量 | 已修复 | 待修复 |
|------|------|--------|--------|
| 致命 | 0 | 0 | 0 |
| 严重 | 1 | 1 | 0 |
| 一般 | 3 | 2 | 1 |
| 轻微 | 2 | 2 | 0 |

## 结论
- [x] 通过，可以发布
- [ ] 不通过
```
