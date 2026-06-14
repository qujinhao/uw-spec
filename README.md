# uw-spec 开发流程规范

uw-spec 是一套完整的 AI 辅助开发流程规范（agents + Skills），采用 **harness-engineering（工程约束）** + **TDD（测试驱动开发）** 理念，让 AI 作为开发伙伴，与人机协作完成软件开发生命周期的各个阶段。

## 📦 安装与使用

### 方式一：Claude Code Plugin 安装（推荐）

Claude Code 通过 Plugin 机制同时安装 Skills 和 Agents。

#### 从 GitHub Marketplace 安装

```bash
# 第一步：添加 Marketplace
/plugin marketplace add axeon/uw-spec

# 第二步：安装插件
/plugin install uw-spec@uw-spec
```

#### 本地临时加载（适合开发调试）

直接读取源目录，修改文件后下次加载自动生效：

```bash
claude --plugin-dir /path/to/uw-spec
```

**验证安装**：

```
/skills    # 查看已安装的 Skills
/agents    # 查看已安装的 Agents
```

**作用域选择**：

| 作用域 | 安装位置 | 说明 |
|--------|----------|------|
| User（默认） | `~/.claude/` | 所有项目生效 |
| Project | `.claude/` | 仅当前项目生效 |

**更新与卸载**：

| 操作 | 命令 | 说明 |
|------|------|------|
| 更新索引 | `/plugin marketplace update uw-spec` | 拉取最新版本信息 |
| 更新插件 | `/plugin install uw-spec@uw-spec` | 覆盖安装即可 |
| 禁用插件 | `/plugin disable uw-spec` | 暂停使用，不卸载 |
| 卸载插件 | `/plugin uninstall uw-spec` | 彻底移除 |
| 查看插件 | `/plugin list` | 查看已安装的插件 |

### 方式二：npx skills 安装（仅 Skills）

`npx skills` 只能安装 Skills，**不支持安装 Agents**。如需 Agents 请使用方式一或方式三。

```bash
# 安装所有 Skills
npx skills add axeon/uw-spec --all -y

# 安装指定 Skill
npx skills add axeon/uw-spec --skill 0-init -y

# 查看已安装的 Skills
npx skills list

# 更新已安装的 Skills
npx skills update -y
```

**指定安装目标**：

```bash
# 安装到 Claude Code
npx skills add axeon/uw-spec --all -a claude-code -y

# 安装到 Trae
npx skills add axeon/uw-spec --all -a trae -y

# 安装到多个工具
npx skills add axeon/uw-spec --all -a claude-code -a trae -y

# 全局安装（跨项目生效）
npx skills add axeon/uw-spec --all -g -y
```

### 方式三：手动安装

```bash
# 克隆仓库
git clone https://github.com/axeon/uw-spec.git

# 安装 Skills（复制或 symlink 到目标目录）
# Claude Code
mkdir -p .claude/skills
ln -s $(pwd)/uw-spec/skills/* .claude/skills/

# Trae
mkdir -p .trae/skills
ln -s $(pwd)/uw-spec/skills/* .trae/skills/

# 安装 Agents（仅 Claude Code 支持）
mkdir -p .claude/agents
ln -s $(pwd)/uw-spec/agents/* .claude/agents/
```

### 三种方式对比

| 特性 | Plugin（方式一） | npx skills（方式二） | 手动（方式三） |
|------|-----------------|--------------------|-------------|
| 安装 Skills | ✅ | ✅ | ✅ |
| 安装 Agents | ✅ | ❌ | ✅ |
| 一键安装 | ✅ | ✅ | ❌ |
| 自动更新 | ✅ | ✅ | ❌ |
| 多工具支持 | Claude Code | 41+ 工具 | 任意 |

### 快速开始

安装完成后，在对话中直接说：

> "我想开发一个 XXX 应用"

`0-init` 技能会自动触发，引导你完成项目初始化并进入 uw-spec 开发流程。

## 🎯 核心理念

### harness-engineering（工程约束）

harness-engineering 是一种**以人为本的 AI 协作开发范式**，强调通过合理的工程约束来引导 AI 发挥最大效能，同时保持开发者的主导权和创造力。

#### 核心原则

| 原则 | 说明 | 实践方式 |
|------|------|----------|
| **人机协作** | AI 不是替代开发者，而是作为开发伙伴 | 开发者负责业务洞察和架构决策，AI 负责代码实现和细节处理 |
| **约束引导** | 通过预设的工程规范约束 AI 行为 | 使用 Skills 定义清晰的开发流程、代码规范和评审标准 |
| **轻松高效** | 在轻松、高效的氛围中进行开发 | 自动化重复性工作，让开发者专注于创造性任务 |
| **迭代优化** | 持续改进，快速迭代 | 短周期开发循环，快速验证和反馈 |
| **知识共享** | AI 解释代码逻辑，开发者提供业务洞察 | 代码即文档，AI 辅助生成和更新文档 |

#### 优势详解

**1. 可控性优势**
- 通过 Skills 预设开发流程，确保每次 AI 输出都符合项目规范
- 评审机制（review skills）作为质量闸门，防止低质量代码进入主干
- 开发者始终掌握最终决策权，AI 作为执行助手

**2. 效率优势**
- 串行开发模式确保依赖关系正确，减少返工
- 代码生成 Skills 自动化 boilerplate 代码编写，开发者专注业务逻辑
- 自动化测试和文档生成减少重复劳动

**3. 质量优势**
- 每个开发 Skill 完成后强制自动执行对应评审，形成多层质量防护网
- 固定的技术栈（uw-base + Vue3/UniApp）确保技术一致性
- 测试驱动开发确保代码可测试性和功能正确性

**4. 可维护性优势**
- 标准化的项目结构和编码规范降低维护成本
- 完整的文档体系（需求文档、运维文档、用户手册）保障知识传承
- 功能开发和 Bug 修复都有独立的流程 Skills，确保变更可控

---

### TDD（测试驱动开发）

TDD（Test-Driven Development）是一种**先写测试、后写实现**的开发方法论，通过测试来驱动设计，确保代码质量和功能正确性。

#### TDD 循环（红-绿-重构）

```
┌─────────┐    ┌─────────┐    ┌─────────┐
│  编写测试  │ → │  运行失败  │ → │  编写实现  │
│  (Red)   │    │  (Red)   │    │  (Green) │
└─────────┘    └─────────┘    └────┬────┘
     ↑                               │
     └───────────────────────────────┘
              ┌─────────┐
              │  重构优化  │
              │(Refactor)│
              └─────────┘
```

| 阶段 | 目标 | 产出 |
|------|------|------|
| **红（Red）** | 编写失败的测试 | 明确的验收标准和测试用例 |
| **绿（Green）** | 编写最简单的实现让测试通过 | 可运行的功能代码 |
| **重构（Refactor）** | 优化代码结构，消除重复 | 高质量的整洁代码 |

#### 核心实践

| 实践 | 说明 | 在本流程中的体现 |
|------|------|------------------|
| **测试先行** | 先写测试，再写实现 | 230-test-case-dev 在开发前完成测试设计 |
| **验收标准** | 每个需求都要有可验证的验收标准 | 需求规划阶段明确测试验收点 |
| **持续测试** | 测试贯穿整个开发周期 | 开发阶段编写单元测试，测试阶段执行 API/E2E/压测/安全扫描 |
| **自动化** | 测试自动运行，快速反馈 | 230-test-case-dev 和 310-test-report 形成自动化流水线 |

#### 在本流程中的具体实践

| 阶段 | TDD 实践 | 对应 Skills |
|------|----------|-------------|
| 设计开发 | 测试用例设计 | 230-test-case-dev |
| 设计开发 | 单元测试开发（内置） | 210-java-uniweb-dev, 220-{四端}-dev |
| 测试执行 | API/E2E/压测/安全测试 | 230-test-case-dev, 310-test-report |
| 功能开发 | 功能测试先行 | 630-feature-test |
| Bug 修复 | 回归测试验证 | 730-bugfix-test |

## 🏗️ 固定技术栈

### 后端技术栈

#### 基础框架
| 技术 | 版本 | 说明 |
|------|------|------|
| Java | 21+ | 运行环境 |
| Spring Boot | 3.5 | 微服务基础框架 |
| Spring Cloud | 2025 | 微服务框架 |
| Spring Cloud Alibaba | 2023.0.1.2 | Nacos 注册/配置中心 |
| Maven | 3.8+ | 构建工具 |

#### 基础设施
| 技术 | 版本 | 用途 |
|------|------|------|
| MySQL | 8.4+ | 数据存储 |
| Redis | 8.2+ | 缓存/分布式锁/序列 |
| RabbitMQ | 3.10+ | 消息队列 |
| Elasticsearch | 8.x | 日志存储与搜索 |
| Nacos | 2.3.2+ | 服务注册与配置中心 |

#### 核心类库（uw-base）
| 模块 | 用途 |
|------|------|
| uw-dao | 数据访问层（DaoManager、DataEntity、QueryParam） |
| uw-cache | 缓存管理（FusionCache） |
| uw-auth-service | 认证服务端 |
| uw-auth-client | 认证客户端（Token自动管理） |
| uw-mfa | 多因素认证（TOTP） |
| uw-task | 分布式任务框架（TaskCroner、TaskRunner） |
| uw-httpclient | HTTP客户端（连接池管理） |
| uw-log-es | Elasticsearch 日志客户端 |
| uw-logback-es | Logback ES Appender |
| uw-ai | AI集成模块（Spring AI、Ollama、RAG） |
| uw-oauth2-client | OAuth2客户端 |
| uw-gateway-client | 网关客户端 |
| uw-mydb-client | 数据库客户端（分库分表） |
| uw-notify-client | 通知客户端（SSE推送） |
| uw-tinyurl-client | 短链接客户端 |
| uw-webot | Web自动化框架 |
| uw-common | 通用工具类库（ResponseData、JsonUtils、AESUtils、SnowflakeIdGenerator） |
| uw-common-app | Web应用公共类库 |

#### 微服务平台
| 微服务 | 功能说明 |
|--------|----------|
| uw-gateway | API网关（SSL、ACL、限流、负载均衡、HTTP/2） |
| uw-gateway-center | 网关管理中心（灰度发布、监控、SSL证书） |
| uw-auth-center | 统一鉴权中心（Token分发、API权限、MFA认证） |
| uw-task-center | 任务管理中心 |
| uw-ops-center | 运维管理中心（Docker全自动部署） |
| uw-code-center | 代码生成服务 |
| uw-mydb-center | 数据库运维中心 |
| uw-mydb-proxy | MySQL分库分表代理（基于Netty） |
| uw-tinyurl-center | 短链接服务 |
| uw-notify-center | 实时通知推送中心（SSE） |
| uw-ai-center | AI服务中心（向量数据库、RAG） |

---

### SaaS 技术栈

SaaS 技术栈基于 UniWeb 框架构建的多租户 SaaS 架构体系，提供租户管理、产品授权计费、支付结算等 SaaS 核心能力。

#### SaaS 微服务
| 微服务 | 功能说明 |
|--------|----------|
| saas-base | SaaS 平台核心基础设施服务，负责租户管理、商户管理、产品授权计费（AIP）、应用接口服务（AIS）等 |
| saas-finance | SaaS 平台财务核心服务，负责支付通道管理、余额账户管理、对账管理、汇率管理等 |

#### SaaS 核心类库
| 类库 | Maven坐标 | 功能说明 |
|------|-----------|----------|
| saas-base-common | `saas:saas-base-common` | SaaS 基础公共模块，提供租户管理、商户管理、消息通知、对象存储等基础能力 |
| saas-finance-client | `saas:saas-finance-client` | SaaS 财务客户端，提供支付通道、余额管理、对账管理等财务功能 |

#### SaaS 核心模块
| 模块 | 核心概念 | 功能说明 |
|------|----------|----------|
| **AIP** (Application Infrastructure Provider) | Vendor, Product, Order, License, Balance | 应用基础设施与产品授权计费，支持 License/App/AppLicense/Task 四种计费模式 |
| **AIS** (Application Interface Service) | LinkerType, Linker, LinkerConfig | 应用接口服务框架，通过 Linker 机制实现不同服务提供商的统一接入（邮件/短信/支付） |

---

### 前端 Web 技术栈
| 技术 | 版本 | 用途 |
|------|------|------|
| Vue | 3.x | 前端框架 |
| TypeScript | - | 类型安全 |
| Element Plus | - | UI组件库 |
| Vite | 8.x | 构建工具 |
| Pinia | - | 状态管理 |
| Vue Router | 4.x | 路由管理 |
| Axios | - | HTTP客户端 |

**内置功能**: 多角色登录、MFA鉴权

---

### 前端移动端技术栈
| 技术 | 版本 | 用途 |
|------|------|------|
| UniApp | - | 跨平台框架 |
| Vue | 3.x | 前端框架 |
| TypeScript | - | 类型安全 |
| Pinia | - | 状态管理 |
| uni-ui | - | UI组件库 |

**支持平台**: H5、Android、iOS、微信小程序

**HTTP客户端**: uni.request / Axios

---

### 测试工具链
| 类型 | 工具 | 用途 |
|------|------|------|
| 单元测试 | JUnit 5 / Vitest | Java / TypeScript 单元测试 |
| 集成测试 | Spring Boot Test | 后端集成测试 |
| API测试 | Playwright (request API) | 接口自动化测试 |
| E2E测试 | Playwright (browser) | 端到端界面测试 |
| 跨终端E2E | Playwright (Multi-BrowserContext) | 多终端协作流程测试 |
| 性能测试 | JMeter | 压力/负载/稳定性测试 |
| 安全扫描 | OWASP ZAP / Trivy | Web漏洞/依赖漏洞扫描 |
| 覆盖率 | JaCoCo / Vitest Coverage | 代码覆盖率统计 |

## 👥 角色团队

| 角色 | 职责 | 对应智能体 | 主导阶段 |
|------|------|-----------|---------|
| **产品经理** | 需求分析、产品设计、需求文档整理 | `product-manager` | 需求规划、项目收尾 |
| **系统架构师** | 架构设计、技术选型 | `system-architect` | 设计开发 |
| **项目经理** | 项目规划、进度管理、技术实施协调 | `project-manager` | 项目实施 |
| **Java后端工程师** | 后端服务开发（基于uw-base） | `java-developer` | 后端开发 |
| **JS前端工程师** | 前端应用开发（Vue3/UniApp） | `js-developer` | 原型开发、前端开发 |
| **测试工程师** | 测试设计、测试执行、质量保证、用户手册编写 | `test-engineer` | 测试执行、项目收尾 |
| **Java负责人** | Java代码质量审计 | `java-lead` | 代码审计 |
| **JS前端负责人** | JavaScript代码质量审计 | `js-lead` | 代码审计 |
| **安全审计员** | 安全漏洞审计 | `security-auditor` | 安全审计 |
| **测试负责人** | 测试评审、测试质量把控 | `test-lead` | 测试评审 |
| **运维负责人** | 运维文档评审、发布把控 | `devops-lead` | 文档评审 |
| **原型评审员** | 原型设计评审 | `prototype-reviewer` | 前端评审 |

## 🔄 软件开发流程

### 流程概览

本流程采用**阶段间串行、阶段内按序号串行**的执行策略。每个开发 Skill 完成后**强制自动执行**对应评审（`xx1`-review），评审不通过则自动修复循环（≥95分通过），无需单独调度。

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI 软件开发流程 (uw-spec)                     │
├─────────────────────────────────────────────────────────────────┤
│  0. 主流程控制  →  0-init 协调整个流程                            │
├─────────────────────────────────────────────────────────────────┤
│  1. 需求规划 (串行)                                               │
│     100-rapid-idea-check → 110-requirement-planning               │
├─────────────────────────────────────────────────────────────────┤
│  2. 设计开发 (严格串行)                                           │
│     Step1: 200-database-design → 200-database-deploy              │
│     Step2: 210-java-uniweb-init → 210-gencode → 210-dev          │
│     Step3: 220-{四端}-init → 220-gencode → 220-dev (四端并行)     │
│     Step4: 230-test-case-dev                                     │
├─────────────────────────────────────────────────────────────────┤
│  3. 测试执行 (串行)                                               │
│     300-cicd-init → 310-test-report                               │
│     【API + E2E + 压测 + 安全扫描】                                │
├─────────────────────────────────────────────────────────────────┤
│  5. 文档交付 (并行)                                               │
│     500-ops-manual / 510-requirement-doc / 520-user-manual        │
├─────────────────────────────────────────────────────────────────┤
│  6. 功能开发 (按需)                                               │
│     610-feature-clarify → 620-feature-dev → 630-feature-test → 650-feature-doc │
├─────────────────────────────────────────────────────────────────┤
│  7. Bug修复 (按需)                                                │
│     710-bugfix-analysis → 720-bugfix-dev → 730-bugfix-test → 750-bugfix-doc │
└─────────────────────────────────────────────────────────────────┘
```

### 并行执行策略

| 阶段 | 并行组 | 并行度 | 说明 |
|------|--------|--------|------|
| 阶段2-Step3 | 前端四端 | 4 | 220-admin-web/guest-web/admin-uni/guest-uni 并行 |
| 阶段5 | 文档三路 | 3 | 500/510/520 并行 |
| 阶段6/7 | 与首次交付独立 | - | 运维期按需执行 |

### 特殊说明

**编号跳跃**：阶段编号中无阶段4（保留编号，未使用），阶段3之后直接为阶段5。

**部署发布环节**：测试阶段之后的部署发布采用Git驱动的自动化执行机制（CI/CD流水线），不纳入AI流程管理范畴。该环节通过Git标签、分支合并等操作触发自动化部署流程。

## 🔢 技能编码规则

本项目的技能采用**三位数字编码规则**：

| 位数 | 含义 | 说明 |
|------|------|------|
| **第一位** | 主流程编号 | 按项目阶段推进逻辑依次编排 |
| **第二位** | 子流程编号 | 同一主流程下的子流程按执行顺序编号 |
| **第三位** | 流程类型 | `0` = 主流程，`1` = 审计/评审流程 |

### 编码示例

```
200-database-design           # 2=设计开发, 0=数据库, 0=主流程
201-database-design-review    # 2=设计开发, 0=数据库, 1=评审流程

210-java-uniweb-dev           # 2=设计开发, 1=Java开发, 0=主流程
211-java-uniweb-dev-review    # 2=设计开发, 1=Java开发, 1=评审流程

310-test-report               # 3=测试执行, 1=测试报告, 0=主流程

620-feature-dev               # 6=功能开发, 2=设计开发, 0=主流程
630-feature-test              # 6=功能开发, 3=测试执行, 0=主流程
720-bugfix-dev                # 7=Bug修复, 2=设计开发, 0=主流程
750-bugfix-doc                # 7=Bug修复, 5=文档交付, 0=主流程
```

### 主流程编号对照表

| 编号 | 阶段名称 | 说明 |
|------|----------|------|
| 0 | 主流程控制 | 项目初始化、流程协调 |
| 1 | 需求规划 | 需求收集、分析、规划 |
| 2 | 设计开发 | 数据库→后端→前端→测试（严格串行） |
| 3 | 测试执行 | CI/CD初始化、测试执行与报告 |
| 5 | 文档交付 | 运维文档、需求文档、用户手册（并行） |
| 6 | 功能开发 | 新功能开发（按需执行） |
| 7 | Bug修复 | Bug修复（按需执行） |

## 📝 技能清单

> **通用规则**：每个开发 Skill 完成后**强制自动执行**对应评审（`xx1`-review），评审不通过则自动修复循环（≥95分通过），无需单独调度。下表不列出评审 Skill。

> **例外**：以下类型的 Skill **不触发自动评审**：init（项目初始化）、gencode（代码生成）、100-rapid-idea-check（想法验证）、300-cicd-init（CI/CD初始化）。

### 阶段 0: 主流程控制
| 编号 | 技能名 | 说明 |
|------|--------|------|
| 0 | 0-init | uw-spec 软件开发流程入口技能 |

### 阶段 1: 需求规划
| 编号 | 技能名 | 说明 |
|------|--------|------|
| 100 | 100-rapid-idea-check | 快速判断产品想法是否值得落地 |
| 110 | 110-requirement-planning | 需求规划（PRD、流程图、线框图） |

**流程**: 100 → 110

### 阶段 2: 设计开发（严格串行）

> 按200→210→220→230序号执行，前一步完成后才能开始下一步。

**Step 1: 数据库（200）**

> 200-database-design 完成后自动触发 201-database-design-review 评审，通过后才能执行 200-database-deploy。200-database-deploy 完成后自动触发 201-database-deploy-review 评审。

| 编号 | 技能名 | 说明 |
|------|--------|------|
| 200 | 200-database-design | 数据库设计 |
| 200 | 200-database-deploy | 数据库DDL执行与验证 |

**Step 2: 后端（210）**

| 编号 | 技能名 | 说明 |
|------|--------|------|
| 210 | 210-java-uniweb-init | Java后端项目初始化 |
| 210 | 210-java-uniweb-gencode | Java代码生成 |
| 210 | 210-java-uniweb-dev | UniWeb后端设计与开发（TDD） |

**Step 3: 前端（220，四端并行）**

| 编号 | 技能名 | 说明 | 适用角色 |
|------|--------|------|---------|
| 220 | 220-admin-web-init → 220-admin-web-gencode → 220-admin-web-dev | Admin Web端 | root/ops/saas/mch |
| 220 | 220-guest-web-init → 220-guest-web-gencode → 220-guest-web-dev | Guest Web端 | guest |
| 220 | 220-admin-uni-init → 220-admin-uni-gencode → 220-admin-uni-dev | Admin UniApp端 | root/ops/saas/mch |
| 220 | 220-guest-uni-init → 220-guest-uni-gencode → 220-guest-uni-dev | Guest UniApp端 | guest |

**Step 4: 测试设计（230）**

| 编号 | 技能名 | 说明 |
|------|--------|------|
| 230 | 230-test-case-dev | 测试用例设计（API/E2E/压测/安全） |

### 阶段 3: 测试执行

> 300-cicd-init 为基础设施配置类技能，不触发自动评审。310-test-report 完成后自动触发 311-test-report-review 评审。

| 编号 | 技能名 | 说明 |
|------|--------|------|
| 300 | 300-cicd-init | CI/CD流水线初始化（Shell/Actions） |
| 310 | 310-test-report | 测试执行与报告（API/E2E/压测/安全） |

**流程**: 300 → 310

**执行内容**: 安全扫描 → API测试 → E2E单终端测试 → E2E跨终端测试 → 压力测试

### 阶段 5: 文档交付（并行）
| 编号 | 技能名 | 说明 | 主导角色 |
|------|--------|------|---------|
| 500 | 500-ops-manual | 运维文档编写 | 运维工程师 |
| 510 | 510-requirement-doc | 需求文档整理 | 产品经理 |
| 520 | 520-user-manual | 用户使用手册编写 | 测试工程师 |

**流程（三路并行）**: 500 / 510 / 520

### 阶段 6: 功能开发（按需）

当需要开发新功能时：

| 编号 | 技能名 | 说明 |
|------|--------|------|
| 610 | 610-feature-clarify | 功能需求澄清 ★人工确认 |
| 620 | 620-feature-dev | 功能开发（技术方案+全端代码）★人工确认 |
| 630 | 630-feature-test | 功能测试与验收 ★人工确认 |
| 650 | 650-feature-doc | 5xx文档更新（运维/用户/需求）★人工确认 |

**流程**: 610-feature-clarify → 620-feature-dev → 630-feature-test → 650-feature-doc

> 每个 `xx0` 开发技能完成后自动执行对应的 `xx1` 评审（611/621/631/651），无需单独调度。

### 阶段 7: Bug修复（按需）

当需要修复Bug时：

| 编号 | 技能名 | 说明 |
|------|--------|------|
| 710 | 710-bugfix-analysis | Bug分析 ★人工确认 |
| 720 | 720-bugfix-dev | Bug修复开发（修复方案+全端代码）★人工确认 |
| 730 | 730-bugfix-test | Bug修复测试与验收 ★人工确认 |
| 750 | 750-bugfix-doc | 5xx文档更新（运维/用户/需求）★人工确认 |

**流程**: 710-bugfix-analysis → 720-bugfix-dev → 730-bugfix-test → 750-bugfix-doc

> 每个 `xx0` 开发技能完成后自动执行对应的 `xx1` 评审（711/721/731/751），无需单独调度。

### 交付物总览

| 类别 | 交付物 | 责任人 | 存储位置 |
|------|--------|--------|----------|
| **运维文档** | 系统架构说明、部署手册、监控手册、故障处理手册、应急预案 | 运维工程师 | `manual/ops-manual/` |
| **需求文档** | PRD、用户故事地图、业务流程图、功能清单、验收标准 | 产品经理 | `requirement/` |
| **用户文档** | 用户使用手册、快速入门指南、FAQ、故障排除指南 | 测试工程师 | `manual/user-manual/` |

## 🚀 使用方式

1. **开始新项目**：调用 `0-init` 技能
2. **特定阶段**：直接调用对应阶段的技能
3. **技能触发**：AI 根据用户输入自动识别并调用合适的技能

## 📄 文档输出规范

所有设计文档统一输出到项目根目录：

```
project/
├── project-info.md           # 项目信息
├── requirement/              # 需求文档
│   ├── prds/
│   ├── interviews/
│   └── reviews/
├── backend/                  # 后端项目
│   └── {project-name}-app/
│       ├── database/
│       ├── issues/
│       ├── reviews/
│       └── src/
├── frontend/                 # 前端项目
│   └── {role}-{platform}/
│       ├── issues/
│       ├── reviews/
│       └── src/
├── test/                     # 测试项目
│   ├── design/
│   ├── scripts/
│   ├── reports/
│   ├── issues/
│   └── reviews/
├── issue/                    # Bug修复文档
│   ├── features/
│   ├── bugs/
│   └── reviews/
└── manual/                   # 文档交付
    ├── ops-manual/
    ├── user-manual/
    └── reviews/
```

## 🎨 设计原则

### 技能设计原则
1. **单一职责**：每个技能只负责一个明确的任务
2. **可组合**：技能之间可以灵活组合
3. **可扩展**：易于添加新技能
4. **可测试**：每个技能都有明确的输入输出

### TDD 实践
1. **测试先行**：在编写实现代码前先写测试
2. **小步快跑**：小步提交，频繁验证
3. **重构优化**：测试通过后进行代码重构
4. **持续集成**：自动化测试贯穿始终

### 技术栈约束
1. **后端必须使用uw-base**：所有后端项目基于uw-base架构开发
2. **Web端必须使用Vue3+ElementPlus**：固定前端技术栈
3. **移动端必须使用UniApp+Vue3**：固定移动端技术栈
4. **数据库必须使用MySQL 8.4**：固定数据库版本
5. **配置必须使用Nacos 2.3.2**：统一配置中心

## 🤝 贡献指南

欢迎提交 Issue 和 PR 来完善这套 uw-spec 流程。

## 📄 License

MIT License
