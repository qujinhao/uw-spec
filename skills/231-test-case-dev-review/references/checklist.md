# 自动化测试开发评审检查清单

> **源技能**：[230-test-case-dev/SKILL.md](../../230-test-case-dev/SKILL.md) — 逐类型完整交付

## 0. 编译与可运行性（源技能 → Phase 3）

| 检查项 | 命令/方式 | 通过标准 | 依据 |
|--------|----------|---------|------|
| TypeScript 编译 | `pnpm tsc --noEmit` | 无错误 | Phase 3 |
| 用例可列出 | `pnpm playwright test --list` | 全部列出 | Phase 3 |
| 无 data-testid | `grep -rn 'data-testid' . --include="*.ts" \| wc -l` | 0 行 | 架构约定 |
| 用例ID唯一 | `grep -r 'TC-' test/design/ \| sort \| uniq -d` | 无重复 | Phase 2 |

## 1. 设计完整性（源技能 → Phase 0 + Phase 2）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 接口覆盖 | 所有 Controller 接口在 `test/design/api/README.md` 有对应用例 | Phase 2.1 |
| 页面覆盖 | 所有页面/路由在 `test/design/e2e/README.md` 有导航测试 | Phase 2.2 |
| 场景覆盖 | 基准/负载/压力/稳定性 4 种场景在 `test/design/load/README.md` | Phase 2.3 |
| OWASP 覆盖 | Top 10 类别在 `test/design/security/README.md` 有检查项 | Phase 2.4 |
| 角色×模块矩阵 | 每个角色×接口的权限验证用例 | Phase 0 |
| 用例ID规范 | `TC-{API/E2E/LOAD/SEC}-{module}-{seq}` 格式 | Phase 2 |

## 2. API 测试质量（源技能 → Phase 2.1）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 三重断言 | 状态码 + 业务code + 数据字段断言 | 架构约定 |
| 数据驱动 | 参数化数据使用 fixture 或 JSON 文件 | 架构约定 |
| 权限覆盖 | 每个角色均有认证测试 | Phase 2.1 |
| 错误场景 | 400/401/403/404/500 异常场景覆盖 | Phase 2.1 |
| 脚本位置 | `test/scripts/api/{module}.spec.ts` | Phase 2.1 |
| 每接口用例数 | ≥ 1 正常 + 1 异常 | Phase 2.1 |

## 3. E2E 测试质量（源技能 → Phase 2.2）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 选择器策略 | 优先 getByRole/getByPlaceholder/locator([name])，禁止 data-testid | 架构约定 |
| Page Object | 共享组件封装为 Page Object | Phase 2.2 |
| 跨终端 | 多终端用例使用 MultiTerminalTest | Phase 2.2 |
| 独立性 | beforeEach 准备数据，无测试间依赖 | Phase 2.2 |
| 脚本位置 | `test/scripts/e2e/{project-name}/{module}.spec.ts` | Phase 2.2 |
| 每页面用例数 | ≥ 1 冒烟用例 | Phase 2.2 |

## 4. JMeter 质量（源技能 → Phase 2.3）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 场景齐全 | 基准/负载/压力/稳定性 4 个 .jmx 文件 | 架构约定 |
| 参数化 | 服务器地址 `${__P(host,localhost)}` | 架构约定 |
| 数据文件 | CSV 在 `load/data/` 目录 | 架构约定 |
| SLA 指标 | P95/P99/错误率/TPS 目标值合理 | Phase 2.3 |
| 断言 | HTTP 状态码 + 业务code + 响应时间 | Phase 2.3 |
| 线程组 | 线程数、ramp-up、持续时间与设计一致 | Phase 2.3 |

## 5. 安全测试质量（源技能 → Phase 2.4）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| ZAP 配置 | 扫描目标、排除路径、输出格式 | Phase 2.4 |
| Trivy 配置 | 扫描范围（后端/前端/镜像）、严重级别 | Phase 2.4 |
| 注入测试 | SQL 注入、XSS、越权测试脚本 | Phase 2.4 |
| OWASP 覆盖 | Top 10 类别均有对应检查项 | Phase 2.4 |

## 6. 执行脚本（源技能 → Phase 3）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 脚本齐全 | setup/run-api/run-e2e/run-load/run-security/run-all | Phase 3 |
| 参数化 | 环境变量引用正确 | Phase 3 |
| 报告输出 | 报告路径和命名规范（YYMMDDHHMM 后缀） | Phase 3 |

## 7. 通用质量

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 独立性 | 每个用例独立可执行 | Phase 2 |
| 可重复性 | 明确测试数据，多次执行结果一致 | Phase 2 |
| 前置条件 | 登录角色、初始数据明确 | Phase 2 |
| 无硬编码 | URL、Token、测试数据不硬编码 | 架构约定 |
