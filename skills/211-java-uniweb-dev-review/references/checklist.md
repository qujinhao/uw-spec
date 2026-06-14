# UniWeb 后端开发评审检查清单

> **源技能**：[210-java-uniweb-dev/SKILL.md](../../210-java-uniweb-dev/SKILL.md)
>
> 本清单分两部分：**编译与测试验证**（grep 可覆盖）和**按维度评审**（需 AI 理解力）。
> 前置扫描在 SKILL.md 评审流程步骤 1 中执行，通过后才进入按维度评审。

---

## 编译与测试验证（grep 覆盖）

> 以下项由 grep 命令自动检查，评审流程步骤 1 执行。不通过直接进入修复循环。

| 扫描项 | grep 命令 | 通过标准 | 覆盖的评审维度 |
|--------|----------|---------|---------------|
| Lombok | `grep -rn '@Data\|@Getter\|@Setter\|@RequiredArgsConstructor'` | 0 行 | §8 技术栈合规 |
| 硬编码状态值 | `grep -rn 'setState(0)\|setState(1)\|setState(-1)'` | 0 行 | §10 代码质量 |
| 硬编码响应码 | `grep -rn 'warnCode("\|errorCode("'` | 0 行 | §10 代码质量 |
| ResponseData 泛型陷阱 | `grep -rn 'ResponseData\.warn("\|ResponseData\.error("'` | 0 行 | §8 技术栈合规 |
| DAO 方法名错误 | `grep -rn 'dao\.execute(\|GlobalCache\.delete(\|FusionCache\.invalidateAll('` | 0 行 | §8 技术栈合规 |
| 路径命名 | `grep -rn '@.*Mapping.*".*[-_].*"'` | 0 行 | §4 Controller 质量 |
| TODO 残留 | `grep -rn '// TODO:'` | 0 行 | §9 测试质量 |
| @Schema 缺 title | `grep -rn '@Schema(description' \| grep -v 'title'` | 0 行 | §10 代码质量 |
| 编译 + 测试 | `mvn compile && mvn test` | BUILD SUCCESS + 全绿 | §3 编译测试 |

---

## 按维度评审（需 AI 理解力）

> 以下项无法通过 grep 机械检查，需要评审者读代码、理解业务逻辑后判断。

### §1. README.md 完整性（15分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 模块总览 | 每个模块有名称、说明、复杂度、代码策略 | Phase 1 |
| 模块依赖关系 | Mermaid 图，无循环依赖 | Phase 1 |
| PRD 功能点映射 | 每个 PRD 功能点对应到模块和接口 | Phase 1 |
| 角色权限映射 | SAAS/MCH/ADMIN/ROOT × 模块的 R/W 矩阵 | Phase 1 |
| 全局缓存策略 | FusionCache/GlobalCache 选型、Key规范、TTL | Phase 1 |
| 性能预算 | 数据量估算、索引策略、RT/QPS 目标 | Phase 1 |

### §2. TASKS.md 完整性

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 并行分组 | 按依赖图拓扑排序 | Phase 1 |
| 模块分类 | 每个模块标注简单/复杂/横切 | Phase 1 |
| 进度状态 | 所有模块已标记完成 | Phase 1 |

### §4. Controller 质量（15分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 权限注解与角色映射一致 | `@MscPermDeclare` 的 user 类型与 README 角色映射一致 | Step 3 |
| Guest 特殊规则 | Guest 控制器使用 `AuthType.USER` | Step 3 |
| Javadoc 质量 | 每个方法有完整说明，非空泛描述 | Step 3 |
| Controller 包层级 | 最多2级：`controller/{role}/{module}` | 架构约定 |
| @RequestMapping 路径层级 | Guest 类级3级；非Guest 父级3级、子集4级 | 架构约定 |
| **方法体业务逻辑正确** | 复杂逻辑调 Helper，简单 CRUD 调 DaoManager，业务逻辑无错误 | Step 3 |
| 角色移动 | Controller 已移动到目标角色目录，无残留 admin 目录 | Step 3 |
| 响应格式 | 统一使用 ResponseData\<T\> | Step 3 |

### §5. Helper 质量（15分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| Helper 三条件 | 仅当满足至少一项才创建：逻辑复杂/功能性/多处调用 | Step 4 |
| **方法体完整实现** | Helper 方法体直接包含完整业务逻辑，无 TODO，无 `return null` 骨架。发现 `return null` 视为 Critical | Step 4 |
| 类级 Javadoc | 包含设计思路、创建理由、依赖关系 | Step 4 |
| **方法级 Javadoc** | 每个方法有 `<ol>` 编号步骤 + `[类别]` 标注 + `@param`/`@return` | Step 4 |
| **外部集成步骤具体性** | 外部调用步骤包含具体 SDK 类和方法签名。抽象描述视为 Critical | Step 4 |
| **FusionCache 初始化** | 使用 FusionCache 的 Helper 有 `static {}` 初始化块 | Step 4 |
| 缓存 API 正确性 | FusionCache/GlobalCache/GlobalLocker 方法名正确，Kryo 用具体实现类 | uw-cache.md |

### §6. DTO/VO 质量（5分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 搜索字段裁剪合理性 | 每个保留的 `@QueryMeta` 字段有业务场景支撑 | Step 2 |
| **Guest DTO 隔离** | Guest DTO 在 `dto/guest/` 包下，类名含 Guest，删除管理角色专属字段 | Step 2 |
| **VO 必要性** | 含敏感字段的 Entity 必须创建 VO；复合对象用 `{Entity}Ex` | Step 5 |
| Entity 不修改 | entity 包下文件未修改 | 架构约定 |

### §7. PRD 覆盖度（5分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 功能点全覆盖 | 每个 PRD 功能点在 README 映射表中有对应接口 | Phase 1 |
| 接口全覆盖 | 映射表中的接口在 Controller 中有实现 | Phase 1 |
| 角色覆盖 | README 权限映射表中的角色在 Controller 注解中体现 | Phase 1 |

### §9. 测试质量（10分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| Helper 测试存在 | 每个 Helper 有对应 `{Module}HelperTest.java` | Step 6 |
| Controller 测试存在 | 每个 Controller 有对应 `{Module}ControllerTest.java` | Step 6 |
| **无 fail() 残留** | `grep "fail(" src/test/java/` 结果为空 | Step 6 |
| 测试方法数 | Helper 每方法 ≥ 2 测试，Controller 每方法 ≥ 1 测试 | Step 6 |
| 测试基类 | 继承 `BaseIntegrationTest` + 真实数据库交互，禁止 MockMvc | Step 6 |
| **断言有效性** | 测试断言验证具体返回值/状态变化，非空泛的 `assertTrue(true)` | Step 6 |

### §10. 代码质量（10分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| 分层清晰 | Controller → Helper → DaoManager，无跨层调用 | Step 4 |
| 复杂度 | 圈复杂度≤10，方法行数≤50 | Step 4 |
| i18n 资源文件 | 每个业务 ResponseCode 枚举配套 12 种语种 i18n 资源文件 | dev-standards.md |

### §11. 安全性（5分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| **SaaS 租户隔离** | 所有查询 SQL 包含 `WHERE saas_id = ?`，操作前校验归属 | dev-standards.md |
| SQL 参数化 | 所有查询使用 `?` 占位符，禁止字符串拼接 | Step 4 |
| **modifyDate 必设** | 所有 `dao.save()/dao.update()` 调用包含 modifyDate | dev-standards.md |
| **VO 使用** | Controller 禁止直接返回含敏感字段的 Entity | dev-standards.md |
| **返回值处理** | 跨 Helper 调用后必须检查返回值，禁止忽略 | Step 4 |

### §12. 外部集成实现（3分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| **AI调用未退化** | 使用 AiClientHelper SDK，未退化为数据库 LIKE 查询。退化为 Critical | Step 4 |
| **通知推送未省略** | 使用 `NotifyClientHelper.pushNotify()`，未省略。省略为 Critical | Step 4 |
| **降级逻辑存在** | 外部服务调用后有降级处理。无降级为 Major | Step 4 |
| **configId 动态获取** | AI 调用的 configId 从 AiConfig 表动态读取。硬编码为 Major | Step 4 |

### §13. Javadoc 一致性（2分）

| 检查项 | 要求 | 依据 |
|--------|------|------|
| **步骤覆盖** | Javadoc 编号步骤都有对应代码实现，无遗漏 | Step 4 |
| **时序正确** | `[ID分配]` 在 `[审核]` 之前，refId 使用已分配的 ID | Step 4 |
| **modifyDate 覆盖** | 所有 `[保存]` 和 `[关联更新]` 步骤已设置 modifyDate | Step 4 |
