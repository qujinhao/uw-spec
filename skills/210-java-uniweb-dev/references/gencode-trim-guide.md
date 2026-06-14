# Controller 与 DTO 裁剪规则

> 本文档为 `210-java-uniweb-dev` Step 1「裁剪 DTO」和 Step 2「裁剪 Controller」的权威依据。Agent 按三层规则顺序执行裁剪，每层独立判断，互不依赖。
> 评审阶段（211/311）按本规则逐条核查裁剪完整性。

---

## A. DTO 裁剪规则

> DTO 由代码生成器自动生成，裁剪时仅裁剪不新建（Guest DTO 除外，需在 `dto/guest/` 包下新建）。
> DTO 裁剪必须与 Controller 裁剪联动：Controller 删除了某个方法，对应的 DTO 查询字段也应同步裁剪。

### A.1 搜索字段裁剪

代码生成器产出的 DTO `@QueryMeta` 字段包含所有可能的搜索条件，需按业务场景裁剪：

| 裁剪类型 | 操作 |
|----------|------|
| 搜索字段 | 删除不需要的 `@QueryMeta` 字段（含注释+注解+声明+getter+setter+链式调用，共6部分） |
| 排序字段 | **不裁剪** `ALLOWED_SORT_PROPERTY`，保留无害，裁剪风险大于收益 |

**SAAS 端的管理查询需要更多搜索条件，按 PRD 需求保留，谨慎裁剪**

### A.2 Guest DTO 隔离

**Guest 角色不可复用管理角色 DTO**，必须在 `dto/guest/` 包下创建 Guest 专用 DTO：

| 规则 | 说明 |
|------|------|
| 包路径 | `dto/guest/{Entity}GuestQueryParam.java` |
| 类名 | 必须包含 `Guest` 标识（如 `TripInfoGuestQueryParam`），防止与管理角色 DTO 同名导致 import 歧义 |
| 继承 | `AuthPageQueryParam`（与管理角色 DTO 相同） |
| 字段 | 管理角色 DTO 的限制性版本，删除管理角色专属字段 |

**Guest DTO 应删除的管理角色专属字段**：

| 字段类型 | 示例 | 删除理由 |
|---------|------|---------|
| 修改时间范围 | `modifyDateRange` | Guest 不需要按修改时间范围搜索 |
| 版本号查询 | `version`/`versionRange` | Guest 不需要版本号搜索 |
| 其他管理端字段 | 按具体业务判断 | 管理端特有的筛选条件 |
| 排序字段 | `ALLOWED_SORT_PROPERTY` 仅保留必要的排序字段，如 `state`/`createDate` |

### A.3 裁剪验证

| 检查项 | 验证方法 |
|--------|---------|
| Guest DTO 存在 | 每个 Guest Controller 引用的 QueryParam 都在 `dto/guest/` 包下 |
| Guest DTO 类名含 Guest | `find dto/guest/ -name '*Guest*'` 匹配所有文件 |
| 搜索字段合理性 | DTO 中每个 `@QueryMeta` 字段都能在 PRD 或业务场景中找到使用理由 |
| `mvn compile` 通过 | 编译无错误 |

---

## B. Controller 裁剪规则

### 第零层：代码生成器产出预处理

> 代码生成器将所有 Controller 产出到 `controller/admin/{module}/`，统一使用 `UserType.ADMIN + AuthType.PERM`。裁剪前必须先完成角色移动和基础修正。

| 操作 | 说明 |
|------|------|
| **角色移动** | 根据 README.md 角色权限映射，将 `{module}/` 从 `admin/` 移动到目标角色目录（`saas/`、`guest/` 等），并修正 package 声明和 import 路径 |
| **修正权限注解** | 按角色修正 `@MscPermDeclare` 的 `user` 和 `auth` 参数（代码生成器全部为 `UserType.ADMIN + AuthType.PERM`）。映射表见 [code-templates.md](uniweb/code-templates.md) §1-§2 |
| **@RequestMapping 路径修正** | 角色移动后 `@RequestMapping` 路径第一级必须改为目标角色名（如 `/admin/xxx` → `/saas/xxx`）。路径层级规范详见 [dev-standards.md](uniweb/dev-standards.md)「Controller 路径规范」 |
| **补充 $PackageInfo$.java** | 仅管理角色（saas/mch/admin/root/ops）的 `{role}/{module}/` 目录下新建 $PackageInfo$.java，声明角色级权限。**guest 角色不适用** |
| **角色目录清理** | **删除 README 角色权限映射表中未出现的角色目录**（含其下的 `$PackageInfo$.java`）。如项目无 ADMIN 角色，admin 目录是残留应整体删除。同步清理 `SwaggerConfig` 中对应的 `GroupedOpenApi` Bean |

### 第一层：角色级通用规则

> 基于角色和 CRUD 标准方法组合判断，不需要看具体业务。代码生成器产出的标准方法：list / liteList / load / listDataHistory / listCritLog / save / update / enable / disable / delete。

#### 1.1 Guest 角色通用删除

以下方法在 **Guest Controller** 中**一律删除**：

| 方法 | 删除理由 |
|------|---------|
| `listDataHistory` | 后台数据历史审计，Guest 不需要 |
| `listCritLog` | 后台操作日志审计，Guest 不需要 |

`liteList` 方法选择性删除，根据业务场景判断是否需要Select下拉列表。

#### 1.2 SAAS 只读模块通用删除

当 README 角色权限映射表中某模块对 SAAS 标记为 **R（只读）** 时，SAAS Controller 中以下方法**一律删除**：

| 方法 | 删除理由 |
|------|---------|
| `save` | 只读无创建权限 |
| `update` | 只读无修改权限 |
| `delete` | 只读无删除权限 |
| `enable` | 只读无状态变更权限 |
| `disable` | 只读无状态变更权限 |

#### 1.3 SAAS 无权限模块

当 README 角色权限映射表中某模块对 SAAS 标记为 **-（无权限）** 时，**不创建 SAAS Controller**。

### 第二层：业务实体分类规则

> 基于实体的业务性质判断。每个实体归类到以下一种或多种类型，按对应规则裁剪。实体分类依据 README 模块总览、状态机设计、PRD 功能点描述。

#### 2.A 状态机实体

**识别条件**：README 状态机设计中出现的实体（有明确的状态值定义和状态流转规则）。

**典型实体**：行程（TripInfo）、促销活动（PromoActivity）、组团（ClubGroup）等。

| 方法 | 处理 | 理由 |
|------|------|------|
| `enable` / `disable` | **删除** | 状态流转通过业务方法（如 audit、cancel、book）实现，不走通用 enable/disable |
| `delete` | **按 PRD 判断** | 有些仅特定状态可删除（如 TripInfo 仅规划中可删），需走 Helper 而非直接 dao.delete |
| `listDataHistory` | **删除** | 后台数据历史审计 |
| `listCritLog` | **删除** | 后台操作日志审计 |

#### 2.B 幂等操作记录

**识别条件**：无修改概念、操作幂等的记录型实体。每个用户对同一目标只有一条记录（有则更新、无则创建）。

**典型实体**：点赞（ClubLike）、收藏（ClubFavorite）、关注（ClubFollowRef）等。

| 方法 | 处理 | 理由 |
|------|------|------|
| `update` | **删除** | 记录不可修改，只能创建和取消 |
| `delete` | **删除** | 取消操作用 disable，不物理/逻辑删除 |
| `enable` | **删除** | 重新操作用 save（幂等） |
| `list` / `load` | **按 PRD 判断** | 有些不需要独立列表（如点赞列表通过分享详情间接获取） |
| `listDataHistory` | **删除** | 后台数据历史审计 |
| `listCritLog` | **删除** | 后台操作日志审计 |

#### 2.C 审计/举报/日志类实体

**识别条件**：只追加不修改的实体。创建后内容不可变更，仅允许状态流转（如处理状态）。

**典型实体**：举报（ClubReport）、评论（ClubComment）等。

| 方法 | 处理 | 理由 |
|------|------|------|
| `update` | **删除** | 审计数据不可修改 |
| `delete` | **删除** | 审计数据不可删除 |
| `enable` / `disable` | **删除** | 无启用禁用概念 |
| `listDataHistory` | **删除** | 后台数据历史审计 |
| `listCritLog` | **删除** | 后台操作日志审计 |

#### 2.D 子集实体

**识别条件**：1:N 关系中的子表数据，依赖父实体存在。在 Controller 路径层级上表现为 4 级路径（父实体的子集）。

**典型实体**：行程项（TripItem）、行程同行人（TripMate）、行程版本（TripVersion）、组团成员（ClubGroupMember）等。

| 方法 | 处理 | 理由 |
|------|------|------|
| SAAS 子集 Controller `list` / `load` | **保留** | SAAS 管理需要查看子数据 |

#### 2.E 配置类实体

**识别条件**：每用户一条记录的配置数据。不存在多条记录，不适用列表查询。

**典型实体**：通知设置（GuestNotifyConfig）、用户偏好（GuestPreference）等。

| 方法 | 处理 | 理由 |
|------|------|------|
| `save` | **删除** | 配置由系统初始化，不存在手动新建 |
| `delete` | **删除** | 配置不允许删除 |
| `enable` / `disable` | **删除** | 配置无启用禁用概念 |
| `list` / `load` | **按 PRD 判断** | 单条配置可能不需要列表，SAAS 查看可能需要 |

### 第三层：PRD 功能点交叉验证

> 前两层覆盖了通用判断。本层确保 PRD 定义的每个接口都被实现，没有遗漏。

#### 3.1 PRD 接口必须存在

1. 读取 README PRD 功能点映射表的每个接口
2. 该接口在对应角色 Controller 中**必须存在**
3. 当前缺失的接口**必须新增**（如 audit、handle、feedList、detail 等业务方法）

#### 3.2 非 PRD 接口确认

不在 PRD 映射表中、也不被前两层规则覆盖的方法，**逐个确认**：
- 有合理业务场景 → 保留，并在 README PRD 映射表中补充
- 无合理业务场景 → 删除

#### 3.3 裁剪验证清单

裁剪完成后，按以下清单逐项检查：

| 检查项 | 验证方法 |
|--------|---------|
| Guest 无 listDataHistory / listCritLog | `grep -r "listDataHistory\|listCritLog" controller/guest/` 结果为空 |
| Guest liteList 合理性 | Guest Controller 中如保留 liteList，需在 README PRD 映射表中有对应功能点 |
| SAAS 只读模块无写入方法 | 对照 README 权限映射表 R 标记，检查无 save/update/delete/enable/disable/listDataHistory/listCritLog |
| PRD 每个接口都有对应实现 | README PRD 功能点映射表逐条核对 Controller 方法 |
| 无多余方法 | Controller 中每个方法都能在 PRD 或第一二层规则中找到保留理由 |
| Guest DTO 隔离 | 每个 Guest Controller import 指向 `dto/guest/` 包 |
| `mvn compile` 通过 | 编译无错误 |

## 裁剪执行顺序

```
1. 裁剪 DTO 搜索字段（管理角色 DTO）
2. 新建 Guest DTO（dto/guest/ 包下）
3. Controller 角色移动 + 权限注解/路径修正 + $PackageInfo$ + 目录清理（第零层）
4. Controller 方法裁剪（第一层 → 第二层 → 第三层），最后删除裁剪过程中产生的空目录
5. 运行裁剪验证清单
6. mvn compile 确认
```
