---
name: 210-java-uniweb-dev
description: UniWeb后端开发（AI原生，一次完成）。当基于PRD进行后端开发时触发：(1)确认模块划分与外部集成, (2)编写架构蓝图, (3)逐模块完整交付（DTO+Controller+Helper+Test一次通过）。
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "3.0.0"
---

# UniWeb后端开发（AI 原生）

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 技术栈来源

| 技术栈 | 文档入口 | 用途 |
|--------|----------|------|
| UniWeb + SaaS 框架 | [uniweb/README.md](references/uniweb/README.md) | uw-base类库、SaaS模块、微服务、开发规范 |

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 技术设计 + 编码 + 测试（一次完成） | `system-architect` |
| 协作 | 业务需求确认 | `product-manager` |

> **职责边界**：单元测试由架构师负责，与代码同步完成。测试工程师专职于 API/E2E/压力/安全测试（`230-test-case-dev` 及后续阶段）。

**实现原则**：所有非平凡技术实现必须具体编码——外部服务调用（AI/通知/第三方API）、异步任务、跨模块编排、分布式锁、缓存策略、降级方案。Javadoc 步骤必须具体到 SDK 类和方法签名，禁止"调用外部服务"等抽象描述。**不确定的技术决策必须与人类确认。**

## 输入

| 输入项 | 来源路径 | 说明 |
|--------|----------|------|
| PRD | `PROJECT_ROOT/requirement/prds/*` | 产品需求文档 |
| 数据库设计文档 | `PROJECT_ROOT/database/database-design.md` | 表结构、实体关系、索引策略 |
| 项目代码 | `PROJECT_ROOT/backend/{project-name}-app/` | init+gencode 产出的 entity/dto/controller |

## 前置条件

| 前置技能 | 说明 |
|---------|------|
| `200-database-design` | 数据库设计已完成并通过评审 |
| `210-java-uniweb-init` | 项目已通过模板初始化 |
| `210-java-uniweb-gencode` | entity/dto/controller 全量 CRUD 已由代码生成器生成在 admin 角色下 |

**已生成代码**：代码生成器已产出 entity、dto、controller，在此基础上裁剪和补充。

## 架构约定速查表

### Controller 约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `controller/{role}/{module}/` 最多两级 | `controller/{role}/{module}/{module}/` 三级及以上 |
| `@RequestMapping("/userProfile")` 驼峰路径 | `@RequestMapping("/user-profile")` 或 `/user_profile` |
| 路径第一级为角色：`/saas/`、`/mch/`、`/admin/`、`/root/`、`/ops/`、`/rpc/`、`/guest/` | 路径第一级为业务名：`/order/`、`/product/` |
| Guest: 类级3级 + 方法级1级 = 4级完整路径 | Guest: 路径少于4级 |
| 非Guest: 父Controller 3级，子集Controller 4级 | 非Guest: 无3级父路径直接建4级 |
| 代码生成器产出在 `admin/`，按角色映射移动 | 直接在 `admin/` 下使用非admin角色的接口 |
| 标准角色包下 `{module}/` 含 `$PackageInfo$.java` | Guest角色包下放 `$PackageInfo$.java` |

### Helper 约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `service/{Module}Helper.java`，命名含模块名 | `service/{module}Service.java` 或 `Helper` 前缀无模块名 |
| 全部 `static` 方法，无 `@Component` | 加 `@Component` 或实例方法 |
| `DaoManager.getInstance()` 静态获取 | `@Autowired DaoManager` 注入 |
| 三条件满足其一才创建：(1)逻辑复杂 (2)功能性 (3)多处调用 | 简单CRUD也建Helper |
| 简单CRUD直接在Controller调 `DaoManager.getInstance()` | 所有操作都走Helper |
| 缓存用 `static {}` 块初始化 `FusionCache.config(...)` | 运行时动态初始化缓存 |

### 代码风格约定

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| 禁用 Lombok，getter/setter/构造器手写 | 使用 `@Data`、`@Getter`、`@Setter` 等 |
| Entity 保留代码生成器产出，不修改 | 手动修改 Entity 类 |
| DTO 仅裁剪不新建（管理角色）；Guest DTO 在 `dto/guest/` 新建 | 修改管理角色 DTO 结构或新建管理角色 DTO |
| Helper Javadoc 含 `<ol>` 编号步骤 + `[类别]` 标注 | Javadoc 只有"实现业务逻辑"等抽象描述 |
| 外部集成步骤指定 SDK 类+方法签名 | `[调用AI] 调用AI服务获取回复` 等抽象描述 |

### Controller 目录结构

代码生成器产出全部在 `controller/admin/{module}/`，按角色权限映射移动到目标角色目录，修正 package 和 import。详细示例见 [code-templates.md §1](references/uniweb/code-templates.md)。

## 工作流程

### Phase 0: 需求理解与确认

技术栈已限定（UniWeb + SaaS），确认聚焦业务层面。

| 确认项 | 启发式问题 |
|--------|-----------|
| 模块清单 | "PRD 涉及哪些数据库表？每个表的复杂度？" |
| 定制 API | "除标准 CRUD+enable+disable 外，各模块还有哪些接口？" |
| 外部集成 | "哪些功能涉及 AI/通知/异步/第三方调用？SDK 类是什么？" |
| 横切关注点 | "哪些业务规则跨模块？（敏感词、通知、权限校验等）" |

**外部集成识别表**：

| 集成类型 | SDK 类 | 识别关键词 |
|---------|--------|-----------|
| AI对话/生成/翻译 | `AiClientHelper`（uw-ai） | AI、智能、对话、推荐、生成、降级 |
| 实时通知推送 | `NotifyClientHelper`（uw-notify-client） | 推送、通知、SSE、实时提醒 |
| 异步/定时任务 | `TaskCroner`、`TaskRunner<P,R>`（uw-task） | 异步、定时、延迟、队列 |
| HTTP外部调用 | `JsonInterfaceHelper`（uw-httpclient） | 第三方API、外部接口 |
| AIP授权计费 | `AipHelper`（saas-aip） | 计费、授权、配额 |
| AIS接口服务 | `AisHelper`（saas-ais） | 接口管理、数据同步 |
| 财务服务 | `FinBalanceHelper`（saas-finance） | 支付、余额、扣款、退款 |

**模块分类决策**：

| 分类 | 条件 | 代码策略 |
|------|------|---------|
| 简单模块 | 仅标准CRUD+enable+disable | Controller 直接调 `DaoManager`，不建 Helper |
| 复杂模块 | 含业务流程、状态机、多表联动、缓存、外部调用 | 提取到 Helper（static） |

**⚠️ 外部集成人工确认（强制）**：

识别出外部集成后，**必须向用户展示清单并逐项确认**：SDK 选型、调用参数、降级策略、跨模块调用链路。**禁止跳过**。确认结果写入 TASKS.md。

### Phase 1: 架构蓝图

**读取技术栈**：先读取 [uniweb/README.md](references/uniweb/README.md) 建立全局认知。

**输出两个文件**：

| 文件 | 定位 | 内容 |
|------|------|------|
| `README.md` | 架构蓝图（给人+AI 读） | 模块总览、依赖图（Mermaid）、角色权限映射、缓存策略、外部集成清单 |
| `TASKS.md` | 进度清单（仅追踪） | 并行分组（拓扑排序）、模块清单（简单/复杂分类）、状态复选框 |

模板见 [references/design-templates.md](references/design-templates.md)

### Phase 2: 逐模块完整交付

按 TASKS.md 的拓扑分组顺序，**每组内可并行，组间串行**。每个模块执行以下步骤：

#### Step 1: 加载上下文

| 操作 | 说明 |
|------|------|
| 读技术栈文档 | 按模块需要读取 [references/uniweb/](references/uniweb/) 下对应文档 |
| 读数据库表结构 | 确认字段、索引、关联关系 |

**技术栈文档索引**：

| 场景 | 文档 |
|------|------|
| Controller 权限注解 | [uw-auth-service.md](references/uniweb/uw-auth-service.md) |
| 响应格式、QueryParam | [uw-common.md](references/uniweb/uw-common.md) |
| DaoManager 数据访问 | [uw-dao.md](references/uniweb/uw-dao.md) |
| 缓存 FusionCache | [uw-cache.md](references/uniweb/uw-cache.md) |
| 异步/队列任务 | [uw-task.md](references/uniweb/uw-task.md) |
| 外部HTTP调用 | [uw-httpclient.md](references/uniweb/uw-httpclient.md) |
| AI对话/生成 | [uw-ai.md](references/uniweb/uw-ai.md) |
| 通知推送 | [uw-notify-client.md](references/uniweb/uw-notify-client.md) |
| AIP授权计费 | [saas-aip-module.md](references/uniweb/saas-aip-module.md) |
| AIS接口服务 | [saas-ais-module.md](references/uniweb/saas-ais-module.md) |
| 财务服务 | [saas-finance-client.md](references/uniweb/saas-finance-client.md) |

#### Step 2: DTO 裁剪

> **权威规则**：[gencode-trim-guide.md](references/gencode-trim-guide.md)「A. DTO 裁剪规则」。

| 操作 | 说明 |
|------|------|
| 删除不需要的搜索字段 | 删除 `@QueryMeta` 字段（注释+注解+声明+getter/setter+链式调用，共6部分） |
| 排序字段 | **不裁剪** `ALLOWED_SORT_PROPERTY` |
| 校验注解 | 按需求补充 `@NotNull`、`@Size` 等 |
| Guest DTO | **必须在 `dto/guest/` 包下新建**，类名含 `Guest`，是管理 DTO 的限制性版本 |

裁剪后 `mvn compile` 验证。

#### Step 3: Controller 完整编写

> **权威规则**：[gencode-trim-guide.md](references/gencode-trim-guide.md)「B. Controller 裁剪规则」。

| 操作 | 说明 |
|------|------|
| 按角色映射移动 | 从 `admin/` 移到目标角色目录，修正 package 和 import |
| 裁剪方法 | 仅保留业务需要的接口 |
| **完整方法体** | 复杂逻辑：`return {Module}Helper.{method}(...)`，简单 CRUD：`return DaoManager.getInstance().{method}(...)` |
| Javadoc | 每个方法添加完整说明 |
| @MscPermDeclare | 按角色映射添加权限注解 |

模板见 [code-templates.md §2-§3](references/uniweb/code-templates.md)。

#### Step 4: Helper 完整编写（仅复杂模块）

> **一次写完，不建空壳**。Helper 方法体直接包含完整业务逻辑，无 TODO 标记。

| 内容 | 说明 |
|------|------|
| 类结构 | 无注解，纯 static 工具类 |
| 方法签名 | `public static`，入参出参明确 |
| **方法体** | **直接实现完整业务逻辑**，包括数据库操作、缓存、外部调用、降级处理 |
| 缓存 | `static {}` 块初始化 `FusionCache.config(...)` |
| Javadoc | 设计思路 + `<ol>` 编号实现步骤 + `[类别]` 标注 |

**Javadoc `[类别]` 标注规范**：

| 标注 | 必须指定的信息 |
|------|-------------|
| `[调用AI]` | configId 来源、systemPrompt、userPrompt、是否RAG |
| `[推送通知]` | userId、saasId、type、subject/data |
| `[外部调用]` | URL、参数、响应类型 |
| `[异步任务]` | 任务类名、触发条件 |
| `[跨模块调用]` | 目标 Helper 类名和方法签名 |
| `[降级处理]` | 降级逻辑（如退化为关键词搜索） |
| `[父子表查询]` | 父表Ex类、子表Entity、关联字段（fk_column）、查询方案（联查listEx/懒加载） |

**外部集成代码示例**：

| ❌ 错误 | ✅ 正确 |
|--------|--------|
| `[调用AI] 调用AI服务获取回复` | `AiClientHelper.generate(AiChatGenerateParam.builder().configId(aiConfigId).userPrompt(content).systemPrompt(sysPrompt).build())` |
| `[推送通知] 发送通知给用户` | `NotifyClientHelper.pushNotify(new WebNotifyMsg(userId, saasId, new WebNotifyMsg.NotifyBody("TYPE", data)))` |

FusionCache 初始化模板见 [code-templates.md §5](references/uniweb/code-templates.md)。

#### Step 5: VO 创建（按需）

| 场景 | 示例 |
|------|------|
| Entity 含敏感字段 | GuestInfo → GuestInfoVO |
| 需附加关联数据 | OrderInfo + List\<OrderDetail\> → OrderInfoEx |
| 聚合多 Entity 字段 | 文章详情 = CmsArticle + 作者昵称 + 标签列表 |
| 父子表联查列表 | OrderInfo + List\<OrderItem\> → OrderInfoEx（listEx场景，批量IN+onSuccess嵌套） | Controller 内直接实现 |
| 多语言数据查询 | ProductInfo（listLang/loadLang场景，LEFT JOIN _lang + COALESCE自动降级） | Controller 内直接实现 |

**禁止 Controller 直接返回含敏感字段的 Entity。** 模板见 [code-templates.md §6](references/uniweb/code-templates.md)。

#### Step 6: 测试驱动开发（Red-Green 内部循环）

> **AI 原生 TDD**：内部自动执行 Red-Green 循环，用户只看到最终通过的结果。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)。

**6.1 Red 阶段**：
- 为当前模块编写测试代码
- 执行 `mvn test -Dtest={Module}HelperTest -pl {project-name}-app` → **确认测试失败**
- ⚠️ 如果测试意外通过 → 说明断言不够严格，需加强

**6.2 Green 阶段**：
- 编写实现代码（Step 4/Step 5 产出）
- 执行 `mvn test -Dtest={Module}HelperTest,{role}/{module}/{Module}ControllerTest -pl {project-name}-app` → **确认测试通过**
- ⚠️ 如果测试仍失败 → 修复实现，重新执行

**6.3 Refactor 阶段**（按需）：
- 优化代码结构，消除重复
- 执行 `mvn test` → 确认仍然通过

**测试基础设施**：确认 TestContextConfig.java、BaseIntegrationTest.java、TestAuthUtils.java、{role}ControllerTest.java 已就位。模板见 [code-templates.md §8](references/uniweb/code-templates.md)。

##### Helper 单元测试

| 内容 | 说明 |
|------|------|
| 位置 | `src/test/java/{package}/service/{Module}HelperTest.java` |
| 覆盖 | 每个 Helper 方法 ≥ 2 个测试（正常 + 边界/异常） |
| 断言 | 验证返回值、数据库状态变化、缓存命中 |

##### Controller 单元测试

| 内容 | 说明 |
|------|------|
| 位置 | `src/test/java/{package}/controller/{role}/{module}/{Module}ControllerTest.java` |
| 覆盖 | 每个 Controller 方法 ≥ 1 个测试 |
| 架构 | 直接注入 Controller Bean + 反射注入 AuthTokenData，**禁止 MockMvc** |
| 重点 | SQL 正确性（参数占位符、WHERE、排序）、响应结构、状态码 |
| 角色差异 | Guest 继承 `GuestControllerTest`，SAAS 继承 `SaasControllerTest` |

#### Step 7: 模块验证

```bash
mvn compile && mvn test -Dtest={Module}HelperTest,{role}/{module}/{Module}ControllerTest -pl {project-name}-app
```

**全部通过后**，在 TASKS.md 中标记该模块为已完成，进入下一个模块。

### Phase 3: 全量联调

| 检查项 | 验证方式 | 预期 |
|--------|---------|------|
| 全量编译 | `mvn compile` | BUILD SUCCESS |
| 全量测试 | `mvn test` | 全绿 |
| 应用启动 | 启动 Spring Boot | 正常启动，无 Bean 注入异常 |
| Swagger UI | 浏览器访问 | 所有接口可展示 |
| 前端联调 | 前端基于 Swagger 调用 | 接口可用，响应格式正确 |

## 批量代码修改安全规则（Phase 2 全程适用）

| 规则 | 原因 |
|------|------|
| 用 Edit 工具逐块修改，`old_string` 精确匹配 | Edit 精确匹配，不破坏结构 |
| **禁用 Python re.sub** | 正则只删签名不删方法体，必留孤儿代码 |
| **禁用 sed 多行块替换** | 多行块边界匹配不可靠 |
| sed 仅允许单行替换，执行前 grep 确认范围 | 批量修改需先明确规则 |
| **禁用 rfind('}')** 定位类结尾 | `}` 位置不确定，容易插错 |
| 每修改完一个文件立即 `mvn compile` | 单点验证快速定位问题 |
| 写 Controller 前先 Read Helper 确认方法签名 | 避免调用签名错误 |
| 文件损坏时用代码生成器重新生成 | 手动修补易引入新错误 |

## 完成标准

- [ ] README.md 覆盖所有模块和全局策略
- [ ] TASKS.md 包含并行分组，所有模块已标记完成
- [ ] 所有 Controller 方法有 Javadoc + @MscPermDeclare
- [ ] 所有 Helper 方法有 Javadoc（`<ol>` 步骤 + `[类别]` 标注）
- [ ] **外部集成步骤指定具体 SDK 类和方法签名**
- [ ] **所有 Helper 方法体完整实现，无 TODO 残留**
- [ ] 所有 FusionCache 使用有 `static {}` 初始化块
- [ ] 所有 Helper + Controller 有对应测试，**全部通过**
- [ ] Guest DTO 已在 `dto/guest/` 创建
- [ ] `mvn compile` 通过，`mvn test` 全绿
- [ ] Swagger UI 可展示所有接口

## ⚠️ 完成验证（强制，全自动执行）

1. **强制调用** `211-java-uniweb-dev-review`
2. 不通过（< 95）→ 自动修复 → 重新评审（最多 5 轮）
3. 通过（≥ 95）→ 向用户报告最终结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 参考

- [设计模板](references/design-templates.md) + [代码模板](references/uniweb/code-templates.md)
- [UniWeb 技术栈](references/uniweb/README.md)
- [代码裁剪指南](references/gencode-trim-guide.md)
