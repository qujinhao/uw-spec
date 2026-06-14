---
name: 720-bugfix-dev
description: Bug修复开发综合技能。当Bug分析完成后触发：(1)评审Bug分析报告并设计修复方案, (2)自主判断修改范围（DB/后端/前端）并按需修复各端代码, (3)自动评审修复循环。编码规范引用210/220的references
alwaysApply: false
author: "axeon(23231269@qq.com)"
version: "2.0.0"
---

# Bug修复开发

## 项目环境检测

从当前目录向上查找 `project-info.md`，最多 3 层，找到后记为 `PROJECT_ROOT`。详见 [检测方法与前置检查](../0-init/references/project-env-check.md)。**未找到** → 提示用户先执行 `0-init`。

## 角色职责

| 角色 | 职责 | 智能体 |
|------|------|--------|
| 主导 | 修复方案 + 全端修复 | `system-architect` |
| 协作 | 后端修复 | `java-developer` |
| 协作 | 前端修复 | `js-developer` |
| 协作 | 测试验证 | `test-engineer` |

## 输入

| 输入项 | 来源 | 说明 |
|--------|------|------|
| Bug分析报告 | `PROJECT_ROOT/issue/bugs/BUGFIX-{YYMMDD}-{topic}.md` | 710阶段输出 |
| 相关代码 | 代码仓库 | 需要修复的代码 |
| 各端架构文档 | 各端 `README.md` | 编码规范 |

## 输出

| 输出项 | 位置 | 说明 |
|--------|------|------|
| 修复方案 | `PROJECT_ROOT/issue/bugs/BUGFIX-DESIGN-{YYMMDD}-{topic}.md` | 修复方案文档 |
| DDL文件 | `PROJECT_ROOT/database/migrations/BUGFIX-{YYMMDD}-{topic}.sql` | 数据库变更（如有） |
| 修复代码 | 各端 `src/` | 各端修复代码 |
| 回归测试 | 各端 `src/test/` 或 `src/**/*.spec.ts` | 回归测试代码 |
| 修复文档 | 各端 `issue/BUGFIX-DESIGN-{YYMMDD}-{topic}-{platform}.md` | 修复记录 |
| 评审报告 | 各端 `issue/reviews/` | AI评审报告 |
| 变更记录 | 各端 `CHANGELOG.md` | 代码变更历史 |

## 修改范围决策表

AI 读取Bug分析报告后，按以下表格自主判断修复范围，**仅修复需要的端**：

| 判断条件 | 执行操作 | 编码规范引用 |
|---------|---------|-------------|
| 涉及数据库结构变更 | 设计DDL → 执行DDL | [210 references](../210-java-uniweb-dev/references/uniweb/) |
| 涉及后端代码缺陷 | 修复Java后端代码 | [210 dev-standards](../210-java-uniweb-dev/references/uniweb/dev-standards.md) |
| 涉及管理端Web缺陷 | 修复 admin-web 代码 | [220-admin-web](../220-admin-web-dev/references/coding-principles.md) |
| 涉及用户端Web缺陷 | 修复 guest-web 代码 | [220-guest-web](../220-guest-web-dev/references/coding-principles.md) |
| 涉及管理端移动端缺陷 | 修复 admin-uni 代码 | [220-admin-uni](../220-admin-uni-dev/references/coding-principles.md) |
| 涉及用户端移动端缺陷 | 修复 guest-uni 代码 | [220-guest-uni](../220-guest-uni-dev/references/coding-principles.md) |

> 各端天然独立可并行。DDL需先执行完毕后才能开始后端修复。

## 执行流程

### Phase 1: 修复评审

1. 读取Bug分析报告，确认根因分析正确性和复现步骤
2. 检查根因理解、影响范围、安全性

### Phase 2: 修复方案设计

按"修改范围决策表"判断需要的端，生成修复方案：

**方案要素**: 修复思路、修改范围（文件/行数）、数据库变更（如有）、接口变更影响、兼容性评估、回滚方案、测试策略、风险评估

**方案文档输出**: `PROJECT_ROOT/issue/bugs/BUGFIX-DESIGN-{YYMMDD}-{topic}.md`

### Phase 3: 修复方案评审 ⚠️【强制】

**立即自动调用** [721-bugfix-dev-review](../721-bugfix-dev-review/SKILL.md)，传入修复方案和Bug分析报告。

> 721 未通过前，禁止进入 Phase 4。评审不通过时，721 会自动回调本技能重新设计修复方案。

### Phase 4: 代码修复

按修改范围决策结果，对每个需要的端执行修复。编码前**必读**对应端的技术规范文档。

**后端修复**（如涉及）:
- 编码前读取 [dev-standards.md](../210-java-uniweb-dev/references/uniweb/dev-standards.md)（API 陷阱 + 编码原则）
- 遵循 [210 架构约定](../210-java-uniweb-dev/SKILL.md)（static Helper / DaoManager / 禁用 Lombok）
- TDD Red-Green 内部循环：先写回归测试确认失败 → 写修复确认通过。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)
- 回归测试: Bug复现测试 + 边界测试 + 异常测试 + 原有功能验证
- 编译验证: `mvn compile` + `mvn test -Dspring.profiles.active=debug`

**Web前端修复**（如涉及）:
- Admin Web: Vue3 + Element Plus + Pinia
- Guest Web: Nuxt 3 + Tailwind CSS + Shadcn Vue
- 编码前读取对应端 [coding-principles.md]
- TDD Red-Green 内部循环：先写回归测试确认失败 → 写修复确认通过。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)
- 编译验证: `pnpm build` + `pnpm vue-tsc --noEmit`（Admin）/ `pnpm nuxi typecheck`（Guest）

**UniApp修复**（如涉及）:
- Vue3 + UniApp组件 + 条件编译 + uni-ui
- 编码前读取对应端 [coding-principles.md]
- TDD Red-Green 内部循环：先写回归测试确认失败 → 写修复确认通过。详见 [tdd-guide.md](../0-init/references/tdd-guide.md)
- 编译验证: `pnpm build:h5` + `pnpm build:mp-weixin`

### Phase 5: 代码评审 ⚠️【强制】

**立即自动调用** [721-bugfix-dev-review](../721-bugfix-dev-review/SKILL.md)，传入各端修复代码和修复方案。

> 721 未通过前，禁止进入 Phase 6。评审不通过时，721 会自动回调本技能修复代码。

详细的评审检查清单见 [721 checklist](../721-bugfix-dev-review/references/checklist.md)。

### Phase 6: 文档输出

| 文档 | 位置 | 说明 |
|------|------|------|
| 修复文档 | 各端 `issue/BUGFIX-DESIGN-{YYMMDD}-{topic}-{platform}.md` | 修复概要、代码变更、回归测试、评审结果 |
| CHANGELOG | 各端 `CHANGELOG.md` | 追加变更记录 |

## 人工检查点 ★

**修复方案确认**（Phase 3 评审通过后暂停）:
- [ ] 修复方案是否针对根因
- [ ] 变更影响是否评估完整
- [ ] 回滚方案是否可行
- [ ] 风险是否可接受

**确认后**: 进入 Phase 4 代码修复

## ⚠️ 完成验证（强制，全自动执行）

本技能采用**分阶段评审**机制（不同于其他技能的单次评审）：

1. Phase 3 修复方案完成后 → **强制调用** `721-bugfix-dev-review` 评审修复方案
2. Phase 5 代码修复完成后 → **强制调用** `721-bugfix-dev-review` 评审修复代码
3. 任一评审不通过（< 95）→ 自动修复 → 重新评审（最多 5 轮）
4. 两阶段评审均通过后 → 向用户报告最终结果

> **全自动执行：中间不暂停、不询问、不汇报。未通过前禁止结束。**

## 流转关系

```
输入: Bug分析报告（710 → 711评审通过）
    ↓
720-bugfix-dev
    ↓
修复方案设计 → 开发评审(721) → 人工确认 ★ → 代码修复 → 代码评审(721) → 文档输出
    ↓
输出: 各端修复代码 + 回归测试 + 文档
    ↓
等待: 730-bugfix-test
```

## 参考

- [UniWeb开发规范](../210-java-uniweb-dev/references/uniweb/dev-standards.md)
- [UniWeb技术栈](../210-java-uniweb-dev/references/uniweb/README.md)
- [Admin Web编码原则](../220-admin-web-dev/references/coding-principles.md)
- [Guest Web编码原则](../220-guest-web-dev/references/coding-principles.md)
- [Admin UniApp编码原则](../220-admin-uni-dev/references/coding-principles.md)
- [Guest UniApp编码原则](../220-guest-uni-dev/references/coding-principles.md)
- [评审报告模板](../0-init/references/review-report-template.md)
