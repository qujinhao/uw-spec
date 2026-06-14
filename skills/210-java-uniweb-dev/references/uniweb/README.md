# UniWeb 技术栈参考文档

> ⚠️ **按需加载**：以下文档包含大量 API 细节，**仅在当前任务涉及对应模块时才读取**，不要一次性全部加载。每个文件都是独立的，可单独引用。

## 架构概览

UniWeb 是一套基于 **Spring Boot 3.5** 和 **Spring Cloud 2025** 构建的企业级微服务架构体系。采用模块化设计，由基础类库集合（uw-base）和多个微服务组成，提供从数据访问、缓存管理、认证授权到任务调度、日志收集、运维管理等全方位的基础设施支持。

### 整体架构

业务应用 → uw-gateway 统一入口（SSL/ACL/限流/负载均衡/HTTP2） → UniWeb微服务层（11个微服务） → 基础类库层（uw-base，10个模块） → 基础设施层（MySQL/Redis/RabbitMQ/Nacos/ES）。微服务通过 Nacos 注册发现，引入 uw-base 类库依赖。

### 技术版本基线

| 技术 | 版本 | 说明 |
|------|------|------|
| Java | 21+ | 必须 Java 21 或更高 |
| Spring Boot | 3.5 | 基础框架 |
| Spring Cloud | 2025 | 微服务框架 |
| Spring Cloud Alibaba | 2023.0.1.2 | Nacos 注册/配置中心 |
| Maven | 3.8+ | 构建工具 |
| MySQL | 8.4+ | 数据存储 |
| Redis | 8.2+ | 缓存/分布式锁/序列 |
| RabbitMQ | 3.10+ | 任务队列 |
| Elasticsearch | 8.x | 日志存储与搜索 |
| Docker | - | 容器化部署 |
| Nacos | - | 服务注册与配置中心 |

## UniWeb微服务

以下微服务基于 uw-base 类库构建，通过 uw-ops-center 统一部署，业务开发无需关注其内部实现，仅需按需引入对应的客户端依赖即可使用。

| 微服务 | 功能说明 |
|---|---|
| uw-auth-center | 统一鉴权中心，负责用户 Token 分发（AES-256 加密）、API 权限管理、多方式登录、MFA 认证和鉴权日志 |
| uw-gateway | API 网关，提供全局访问日志、ACME SSL、ACL 访问控制、全局限流和 SAAS 负载均衡，支持 HTTP/2 |
| uw-gateway-center | 网关管理中心，管理灰度发布、请求监控、SSL 证书、Web ACL 和限速策略 |
| uw-code-center | 代码生成服务，基于数据库/JSON/Swagger 元数据自动生成 Entity/Controller/DTO/Mapper 和前端代码 |
| uw-mydb-center | 数据库运维中心，管理 MySQL 集群、慢查询统计、库表空间监控、数据备份恢复和 SAAS 动态建库 |
| uw-mydb-proxy | MySQL 分库分表代理（基于 Netty），支持多种分库分表算法和 HINT 语法路由 |
| uw-ops-center | 运维管理中心，基于 Docker 的全自动部署工具，管理宿主机、部署方案、镜像仓库和发布环境 |
| uw-task-center | 任务管理中心，管理定时任务和队列任务的运维监控、报警规则和动态配置 |
| uw-tinyurl-center | 短链接生成与解析服务 |
| uw-notify-center | 基于 SSE 的实时通知推送中心 |
| uw-ai-center | AI 服务中心，集成 Spring AI，支持 Ollama 本地模型、向量数据库和 RAG 检索增强生成 |

## 核心基础类库（uw-base）

| 文档 | 模块 | 核心类 | 适用场景 |
|------|------|--------|---------|
| [uw-common.md](uw-common.md) | 通用工具类库 | ResponseData, JsonUtils, MoneyUtils, ValidateUtils | 使用统一响应、JSON处理、货币计算、数据校验 |
| [uw-common-app.md](uw-common-app.md) | Web应用公共类库 | AuthQueryParam, SysDataHistoryHelper, JsonConfigHelper | 权限查询、数据历史、配置管理 |
| [uw-dao.md](uw-dao.md) | 数据访问层 | DaoManager, DataEntity, QueryParam, BatchUpdateManager | 数据库CRUD、分页查询、批量操作 |
| [uw-cache.md](uw-cache.md) | 缓存管理 | FusionCache | Redis缓存、本地+分布式融合缓存 |
| [uw-auth-service.md](uw-auth-service.md) | 认证服务端 | @MscPermDeclare, AuthServiceHelper | 权限声明、角色管理、鉴权 |
| [uw-auth-client.md](uw-auth-client.md) | 认证客户端 | authRestClient, Token管理 | 服务间鉴权调用、Token自动管理 |
| [uw-mfa.md](uw-mfa.md) | 多因素认证 | MFA验证、TOTP | 多因素认证集成 |
| [uw-task.md](uw-task.md) | 分布式任务框架 | TaskCroner, TaskRunner | 定时任务、队列任务 |
| [uw-httpclient.md](uw-httpclient.md) | HTTP客户端 | JsonInterfaceHelper, XmlInterfaceHelper | HTTP调用、连接池管理 |
| [uw-log-es.md](uw-log-es.md) | ES日志客户端 | LogHelper | Elasticsearch日志写入与查询 |
| [uw-logback-es.md](uw-logback-es.md) | Logback ES Appender | logback配置 | 日志自动推送到ES |
| [uw-ai.md](uw-ai.md) | AI集成模块 | Spring AI, Ollama | AI服务集成、RAG |
| [uw-oauth2-client.md](uw-oauth2-client.md) | OAuth2客户端 | OAuth2认证 | 第三方OAuth2登录 |
| [uw-gateway-client.md](uw-gateway-client.md) | 网关客户端 | 网关API | 网关路由配置 |
| [uw-mydb-client.md](uw-mydb-client.md) | 数据库客户端 | 分库分表中间件 | 数据库运维操作 |
| [uw-notify-client.md](uw-notify-client.md) | 通知客户端 | SSE推送 | 实时通知 |
| [uw-tinyurl-client.md](uw-tinyurl-client.md) | 短链接客户端 | 短链生成/解析 | 短链接功能 |
| [uw-webot.md](uw-webot.md) | Web自动化框架 | 浏览器自动化 | Web自动化、爬虫 |

## SaaS 业务框架

SaaS 开发技术栈是基于 **UniWeb** 框架构建的多租户 SaaS 架构体系。采用微服务设计，由基础服务（saas-base）、财务服务（saas-finance）等多个微服务组成，提供租户管理、支付结算解决方案。

### 微服务架构

SaaS 应用 → 引入 saas-base-common / saas-finance-client → SaaS 基础服务层（saas-base + saas-finance） → UniWeb 基础框架层（uw-base，详见上方核心类库）。

### SaaS 微服务

| 微服务 | 功能说明 |
|--------|---------|
| saas-base | SaaS 平台核心基础设施服务，负责租户管理、商户管理、产品授权计费（AIP）、应用接口服务（AIS）等基础能力 |
| saas-finance | SaaS 平台财务核心服务，负责支付通道管理、余额账户管理、对账管理、汇率管理等财务相关业务 |

### SaaS 核心类库

| 文档 | 模块 | 核心概念 | 适用场景 |
|------|------|---------|---------|
| [saas-base-common.md](saas-base-common.md) | 基础公共模块 | Maven依赖、uw-base依赖列表 | 了解SaaS公共依赖配置 |
| [saas-aip-module.md](saas-aip-module.md) | AIP授权计费 | Vendor, License, AipHelper | 产品授权、计费扣减 |
| [saas-ais-module.md](saas-ais-module.md) | AIS接口服务 | LinkerType, Linker, AisHelper | 第三方接口集成（支付/短信/邮件） |
| [saas-finance-client.md](saas-finance-client.md) | Saas财务客户端 | FinBalanceHelper, FinPaymentHelper | 提供支付通道，在线支付，退款，余额管理、对账等财务相关功能 |

## 使用建议

| 阶段 | 加载策略 |
|------|---------|
| 早期设计/全局了解 | 仅读取本 README.md 建立全局认知 |
| 模块设计 | 读取本 README 索引 + 对应模块的详细文档 |
| 编码开发 | 读取 `dev-standards.md` + 当前使用的核心类库文档 |
| 创建新项目 | 读取 `code-templates.md` §1 产出结构 |

## 开发规范

> 以下规范文档由 `210-java-uniweb-dev`、`211-java-uniweb-dev-review`、`620-feature-dev`、`720-bugfix-dev` 等技能**共同引用**，是编码规范的唯一权威来源。

| 文档 | 内容 | 引用技能 |
|------|------|---------|
| [dev-standards.md](dev-standards.md) | 编码规范（约束、陷阱、原则） | 210/211/620/720/721 |
| [code-templates.md](code-templates.md) | 代码模板（POM/YAML/Java/测试） | 210/211/620/720/721 |
