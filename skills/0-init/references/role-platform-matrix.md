# 用户角色与终端平台

> 跨技能共用的角色、平台和命名规则定义，被 110-requirement-planning、320-admin-web-dev 等技能引用。

## 核心概念

用户角色（谁在用）和终端平台（用什么设备）是 **N:N 关系**。先确定角色，再为每个角色选择平台。`{role}-{platform}` 组合对应一个前端项目。

## 用户角色

| 角色 | 代码 | 职责描述 |
|------|------|---------|
| 系统管理员 | root | 系统最高权限管理、系统配置与运维 |
| 总后台管理员 | admin | SaaS租户管理，SaaS平台公用数据管理、运营数据查看 |
| SAAS管理员 | saas | SaaS平台运营、租户与供应商管理，SaaS业务承载平台 |
| SAAS商户 | mch | 商家经营管理、商品与订单管理，依托SaaS平台上运营 |
| 用户 | guest | 普通消费者浏览、下单、互动 |

## 终端平台

| 平台 | 代码 | 说明 |
|------|------|------|
| Web | web | 浏览器端 |
| macOS | macos | macOS 桌面应用 |
| Linux | linux | Linux 桌面应用 |
| Windows | windows | Windows 桌面应用 |
| UniApp | uniapp | 跨平台移动应用 |
| Android | android | Android 原生应用 |
| iOS | ios | iOS 原生应用 |
| 微信小程序 | wxmp | 微信小程序 |

## 项目命名规则

| 用途 | 格式 | 示例（name=nova） |
|------|------|-------------------|
| 后端项目 | `{name}` | `nova` |
| 前端项目 | `{name}-{role}-{platform}` | `nova-mch-web`、`nova-guest-uni` |
| 数据库名 | `{name}_db` | `nova_db` |
| Git仓库 | `{name}` | `nova` |
| Docker镜像 | `{name}` | `nova` |

**一个角色可对应多个平台**：`guest-uni` + `guest-web` = 两套前端需求。

## 常见组合示例

| 角色 | 平台组合 | 典型场景 |
|------|---------|---------|
| guest | uniapp + web | 移动端和web端 |
| guest | wxmp | 纯微信生态 |
| guest | android + ios | 纯原生App |
| admin | web | 后台管理，仅Web |
| admin | web + android | 需移动端巡检 |
| mch | web | 商户后台 |
| mch | uniapp | 商户移动端 |

## 前端技能调用约束

前端技能按 **admin / guest** 分为两组，调用时必须根据用户角色选择对应技能：

| 技能前缀 | 适用角色 | 说明 |
|---------|---------|------|
| `admin-web` | root, ops, admin, saas, mch | 管理端PC（Vue3 + Element Plus） |
| `admin-uni` | root, ops, admin, saas, mch | 管理端移动端（UniApp） |
| `guest-web` | guest | 消费者端PC（Vue3 + Element Plus） |
| `guest-uni` | guest | 消费者端移动端（UniApp） |

**选择规则**：根据当前开发面向的用户角色，选择 `admin-*` 或 `guest-*` 技能。

| 用户角色 | Web技能 | UniApp技能 |
|---------|---------|-----------|
| root | admin-web | admin-uni |
| ops | admin-web | admin-uni |
| admin | admin-web | admin-uni |
| saas | admin-web | admin-uni |
| mch | admin-web | admin-uni |
| guest | guest-web | guest-uni |

**示例**：为 saas 角色开发 Web 端 → 调用 `220-admin-web-init` → `220-admin-web-gencode` → `220-admin-web-design` → ...

## 角色快速推荐

| 目标用户 | 推荐角色 | 理由 |
|---------|---------|------|
| 普通消费者(C端) | guest + admin | C端用户 + 后台管理 |
| 企业员工(B端) | mch + admin | 商户/员工端 + 后台管理 |
| 多租户SaaS | guest + mch + saas + admin | 全角色覆盖 |
| 内部系统 | admin 或 root | 仅需后台管理 |
