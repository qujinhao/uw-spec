---
name: 230-test-case-dev
description: 自动化测试开发。当需要开发自动化测试时触发：(1)按类型逐批交付测试脚本, (2)覆盖API/E2E/压力/安全测试, (3)执行脚本并验证通过。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# 自动化测试开发

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 测试开发 | `test-engineer` |
| 协作 | 验收标准确认 | `product-manager` |
| 协作 | 接口/前端确认 | `java-developer` / `js-developer` |

## 输入

| 输入项 | 来源路径 | 说明 |
|--------|----------|------|
| PRD | `PROJECT_ROOT/requirement/prds/*` | 功能模块及验收标准 |
| 后端设计文档 | `PROJECT_ROOT/backend/{project-name}-app/README.md` | 接口设计、角色权限映射 |
| Controller代码 | `PROJECT_ROOT/backend/{project-name}-app/src/main/java/{package}/controller/` | 接口路径、请求/响应格式 |
| 前端代码 | `PROJECT_ROOT/frontend/{project-name}-*/src/` | API定义、页面组件、表单字段 |

## 字段一致性原则

| 层级 | 命名规则 | 示例 |
|------|---------|------|
| 后端参数（JSON） | camelCase | `userName`, `email`, `orderStatus` |
| 前端表单字段 | 与后端参数一致 | `userName`, `email`, `orderStatus` |
| 测试选择器 | 基于字段名或语义属性定位 | `getByLabel('用户名')`, `locator('[name="userName"]')` |

> 全链路字段命名一致，E2E 测试无需额外 `data-testid`。

## 四类测试技术栈

| 类型 | 工具 | 脚本格式 | 产出目录 |
|------|------|---------|---------|
| API测试 | Playwright request API | `.spec.ts` | `test/scripts/api/` |
| E2E测试 | Playwright browser | `.spec.ts` | `test/scripts/e2e/{project-name}/` |
| 跨终端E2E | Playwright multi-context | `.spec.ts` | `test/scripts/e2e/cross-case/` |
| 压力测试 | JMeter | `.jmx` | `test/scripts/load/` |
| 安全测试 | ZAP + Trivy + Playwright | `.sh` / `.spec.ts` | `test/scripts/security/` |
| 执行脚本 | Bash | `.sh` | `test/scripts/bin/` |

## 架构约定速查表

### 选择器策略

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `page.getByRole('button', { name: '提交' })` | `page.locator('.submit-btn')` |
| `page.getByPlaceholder('请输入用户名')` | `page.locator('#username')` |
| `page.locator('[name="userName"]')` | `page.locator('[data-testid="username"]')` |
| `page.getByText('确认删除')` | `page.locator('.confirm-text')` |

### API 测试断言

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 状态码 + 业务code + 数据字段三重断言 | 只断言状态码 200 |
| `expect(res.data?.results).toBeDefined()` | `expect(res).toBeTruthy()` |
| 参数化数据使用 fixture 文件 | 测试数据硬编码在脚本中 |

### JMeter 配置

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 服务器地址 `${__P(host,localhost)}` | 硬编码 `192.168.1.100` |
| CSV 数据文件在 `load/data/` 目录 | CSV 路径含绝对路径或中文名 |
| 4 种场景：基准/负载/压力/稳定性 | 只有 1 种场景 |

## 工作流程

### Phase 0: 需求分析

| 确认项 | 数据来源 |
|--------|---------|
| 接口清单 | Controller 代码 + 后端 README.md |
| 页面清单 | 前端代码 + PRD |
| 角色×模块矩阵 | 后端 README.md 权限映射 |
| 性能指标基线 | PRD 验收标准 + system-architect 确认 |
| 安全检查范围 | OWASP Top 10 + 业务敏感接口 |

### Phase 1: 环境准备

```bash
cd PROJECT_ROOT/test/scripts
pnpm init
pnpm add @playwright/test @faker-js/faker
pnpm playwright install
```

Playwright 配置（API + E2E 双项目）：

```typescript
export default defineConfig({
  projects: [
    { name: 'api', testDir: './api', use: { baseURL: process.env.API_BASE_URL } },
    { name: 'e2e', testDir: './e2e', use: { baseURL: process.env.WEB_BASE_URL, ...devices['Desktop Chrome'] } },
  ],
});
```

### Phase 2: 逐类型完整交付

> 四类测试天然独立（不同目录），按类型逐批交付。每类测试的用例设计和脚本实现同步完成。

#### 2.1 API 测试

| 步骤 | 产出 |
|------|------|
| 读 Controller 代码，建立接口→用例映射 | `test/design/api/README.md` |
| 编写 `.spec.ts`（请求参数、三重断言、数据驱动） | `test/scripts/api/{module}.spec.ts` |
| 验证 | `pnpm playwright test api/` 通过 |

用例规范：`TC-API-{module}-{seq}`，每个接口 ≥ 1 正常 + 1 异常用例。

#### 2.2 E2E 测试

| 步骤 | 产出 |
|------|------|
| 读前端代码，建立页面→用例映射 | `test/design/e2e/README.md` |
| 编写 `.spec.ts`（Page Object + 字段一致性选择器） | `test/scripts/e2e/{project-name}/{module}.spec.ts` |
| 跨终端用例（MultiTerminalTest） | `test/scripts/e2e/cross-case/{flow}.spec.ts` |
| 验证 | `pnpm playwright test e2e/` 通过 |

用例规范：`TC-E2E-{module}-{seq}`，每个页面 ≥ 1 冒烟用例。

#### 2.3 JMeter 压测

| 步骤 | 产出 |
|------|------|
| 定义 4 种场景（基准/负载/压力/稳定性）+ SLA 指标 | `test/design/load/README.md` |
| 编写 `.jmx` + CSV 数据文件 | `test/scripts/load/{scenario}.jmx` + `load/data/` |
| 验证 | JMeter GUI 打开无报错，线程组配置与设计一致 |

SLA 指标模板见 [load-metrics.md](references/load-metrics.md)，JMeter 完整模板见 [jmeter-template.md](references/jmeter-template.md)。

#### 2.4 安全测试

| 步骤 | 产出 |
|------|------|
| 按 OWASP Top 10 建立检查清单 | `test/design/security/README.md` |
| ZAP 扫描脚本 + Trivy 扫描脚本 + Playwright 注入测试 | `test/scripts/security/` |
| 验证 | `bash bin/run-security.sh` 执行无报错 |

安全检查清单见 [security-checklist.md](references/security-checklist.md)，脚本示例见 [security-scan.md](references/security-scan.md)。

### Phase 3: 执行脚本 + 全量验证

| 脚本 | 功能 |
|------|------|
| `bin/setup.sh` | 安装依赖、初始化环境 |
| `bin/run-api.sh` | 执行 API 测试 |
| `bin/run-e2e.sh` | 执行 E2E 测试（支持指定项目名） |
| `bin/run-load.sh` | 执行 JMeter 压测 |
| `bin/run-security.sh` | 执行安全扫描 |
| `bin/run-all.sh` | 按顺序执行全部测试 |

**全量验证**：

```bash
cd PROJECT_ROOT/test/scripts
pnpm tsc --noEmit                                    # TypeScript 编译无错误
grep -rn 'data-testid' . --include="*.ts" | wc -l   # 0 行
pnpm playwright test --list                           # 所有用例可列出
```

## 开发模式

| 模式 | 触发方式 | 说明 |
|------|---------|------|
| 单类型 | "只开发API测试" | 指定一种测试类型 |
| 并行全类型 | "并行开发全部测试"（**默认**） | 四类天然可并行 |
| 顺序全量 | "开发全部测试脚本" | 按类型逐个开发 |

## 完成标准

- [ ] `test/design/` 下四类测试设计文档齐全
- [ ] API 测试覆盖所有 Controller 接口，三重断言
- [ ] E2E 测试覆盖所有页面，字段一致性选择器
- [ ] JMeter 4 种场景齐全，SLA 指标合理
- [ ] 安全测试 OWASP Top 10 覆盖
- [ ] bin/ 执行脚本齐全
- [ ] `pnpm tsc --noEmit` 通过，无 `data-testid`
- [ ] `pnpm playwright test` 全部通过

## ⚠️ 完成验证（强制，全自动执行）

1. **强制执行全量验证**（Phase 3 检查项）
2. **强制调用** `231-test-case-dev-review`
3. 不通过（< 95）→ 自动修复 → 重新评审（最多 5 轮）
4. 通过（≥ 95）→ 向用户报告最终结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [测试用例模板](references/templates.md)
- [设计方法](references/methods.md)
- [压测SLA指标模板](references/load-metrics.md)
- [安全测试检查清单](references/security-checklist.md)
- [脚本示例](references/dev-examples.md)
- [JMeter脚本模板](references/jmeter-template.md)
- [安全扫描脚本](references/security-scan.md)
