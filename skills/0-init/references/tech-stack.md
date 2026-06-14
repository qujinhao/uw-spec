# 通用技术栈

> 跨技能共用技术栈版本和组件表，被 0-init、210-java-uniweb-design、310-java-uniweb-dev 等技能引用。

## 后端

| 组件 | 版本 | 用途 |
|------|------|------|
| uw-base | 2026.x.x | UniWeb架构 |
| saas-base | 2026.x.x | Saas架构 |
| Spring Boot | 3.x | 微服务框架 |
| Nacos | 2.3.2 | 配置中心 |
| MySQL | 8.4 | 数据库 |
| Redis | 8.2 | 缓存 |
| RabbitMQ | - | 消息队列 |

### uw-base核心模块

| 模块 | 用途 |
|------|------|
| uw-common | 通用工具类库 |
| uw-common-app | Web应用公共类库 |
| uw-dao | 数据访问层 |
| uw-cache | 缓存管理 |
| uw-auth-service | 认证服务端 |
| uw-auth-client | 认证客户端 |
| uw-mfa | 多因素认证 |
| uw-task | 分布式任务框架 |
| uw-httpclient | HTTP客户端 |
| uw-log-es | Elasticsearch 日志客户端 |
| uw-logback-es | Logback ES Appender |
| uw-ai | AI集成模块 |
| uw-oauth2-client | OAuth2客户端 |
| uw-gateway-client | 网关客户端 |
| uw-mydb-client | 数据库客户端 |
| uw-notify-client | 通知客户端 |
| uw-tinyurl-client | 短链接客户端 |
| uw-webot | Web自动化框架 |

### saas-base核心模块
| 模块 | 用途 |
|------|------|
| saas-common | Saas应用基础类库 |

## 前端Web管理端

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue 3 + TypeScript | - | 前端框架 |
| Element Plus | - | UI组件库 |
| Vite 8 | - | 构建工具 |
| Pinia | - | 状态管理 |

## 前端移动端

| 技术 | 版本 | 用途 |
|------|------|------|
| UniApp + Vue3 | - | 跨平台框架 |
| TypeScript | - | 类型安全 |
| Pinia | - | 状态管理 |
| uni-ui | - | UI组件库 |

**支持平台**: H5、Android、iOS、微信小程序

## 测试工具

| 类型 | 工具 | 用途 |
|------|------|------|
| 单元测试 | JUnit 5 / Vitest | Java / TypeScript |
| 集成测试 | Spring Boot Test | 后端集成 |
| API测试 | Playwright (request API) | 接口自动化测试 |
| E2E测试 | Playwright (browser) | 端到端界面测试 |
| 跨终端E2E | Playwright (Multi-BrowserContext) | 多终端协作流程测试 |
| 性能测试 | JMeter | 压力/负载/稳定性测试 |
| 安全扫描 | OWASP ZAP | Web应用漏洞扫描 |
| 依赖扫描 | Trivy | 后端/前端/镜像漏洞扫描 |
| 安全测试 | Playwright + 自定义脚本 | SQL注入/XSS/越权测试 |
| 覆盖率 | JaCoCo / Vitest Coverage | 代码覆盖 |

## 字段一致性原则

本项目采用数据库驱动的全链路命名一致设计，数据库字段名作为唯一数据源头，贯穿后端参数和前端字段：

| 层级 | 命名规则 | 示例 |
|------|---------|------|
| 数据库字段 | snake_case | `user_name`, `email`, `order_status` |
| 后端参数（JSON） | camelCase（自动映射） | `userName`, `email`, `orderStatus` |
| 前端表单字段 | 与后端参数一致 | `userName`, `email`, `orderStatus` |
| 前端表格列 | 与后端参数一致 | `userName`, `email`, `orderStatus` |
| E2E测试选择器 | 基于语义属性定位（role/label/placeholder/text） | `getByLabel('用户名')`, `getByRole('button', { name: '提交' })` |

**设计约束**：任何层级不得引入与数据库字段不一致的命名。E2E测试不需要额外添加 `data-testid`，直接使用元素自身属性定位。
