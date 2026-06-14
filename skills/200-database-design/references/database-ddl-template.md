# 数据库DDL模板

---

## 1. 建库语句

```sql
-- ============================================================
-- 创建数据库
-- 数据库名: 从 project-info.md 的 project-name 获取
-- 字符集: utf8mb4（支持emoji和完整Unicode）
-- 排序规则: utf8mb4_0900_ai_ci（不区分大小写）
-- ============================================================
CREATE DATABASE IF NOT EXISTS `{project_name}` 
    DEFAULT CHARACTER SET utf8mb4 
    DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE `{project_name}`;
```

---

## 2. 建表语句模板

### 2.1 标准表结构模板

```sql
-- ============================================================
-- 模块: {模块名称}
-- 实体: {实体名称}
-- 表名: {模块简称}_{实体简称_snake_case}
-- 说明: {表功能说明}
-- 数据规模: {初始量}/{年增长量}/{3年后}
-- ============================================================
CREATE TABLE `{模块简称}_{实体简称_snake_case}` (
    -- ========== 主键 ==========
    `id`            BIGINT            NOT NULL  COMMENT '主键',

    -- ========== 租户ID（SaaS必加）==========
    `saas_id`       BIGINT            NOT NULL                 COMMENT '租户ID',

    -- ========== 业务字段（根据实体定义填写）==========
    -- 示例字段，根据实际业务替换
    `field_name`    VARCHAR(100)      NOT NULL                 COMMENT '字段说明',
    `field_type`    INT           NOT NULL   DEFAULT 0     COMMENT '字段类型(0:类型A 1:类型B)',
    `field_amount`  BIGINT            NOT NULL   DEFAULT 0     COMMENT '金额字段(分)',
    `field_date`    DATETIME(3)          NULL       DEFAULT NULL  COMMENT '时间字段',

    -- ========== 外键字段（如有）==========
    `{关联实体}_id` BIGINT            NOT NULL                 COMMENT '关联{实体}ID',

    -- ========== 通用字段（所有表必须包含）==========
    `create_date`   DATETIME(3)          NOT NULL         COMMENT '创建时间',
    `modify_date`   DATETIME(3)          NOT NULL         COMMENT '修改时间',
    `state`         INT           NOT NULL DEFAULT 1       COMMENT '状态(0:禁用 1:启用)',

    -- ========== 索引 ==========
    PRIMARY KEY (`id`),
    
    -- 唯一索引
    UNIQUE KEY `uk_{表名缩写}_{字段名}` (`unique_field`),
    
    -- 普通索引
    KEY `idx_{表名缩写}_{字段名}` (`field_name`),
    
    -- 组合索引（最左前缀原则）
    KEY `idx_{表名缩写}_{字段1}_{字段2}` (`field1`, `field2`)

) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_0900_ai_ci 
  COMMENT='{模块名称}-{实体名称}';
```

### 2.2 建表字段说明

> 字段类型规范详见 [数据库设计指南 - 字段类型规范](database-design-guide.md#字段类型规范)

#### 主键字段
```sql
`id` BIGINT NOT NULL COMMENT '主键'
```

#### 租户字段（SaaS必加）
```sql
`saas_id` BIGINT NOT NULL COMMENT '租户ID'
```

#### 通用字段（所有表必须）
```sql
`create_date` DATETIME(3) NOT NULL COMMENT '创建时间'
`modify_date` DATETIME(3) NOT NULL COMMENT '修改时间'
`state` INT NOT NULL DEFAULT 1 COMMENT '状态(0:禁用 1:启用)'
```

### 2.3 多语言翻译表模板

> 适用场景：主表有需要多语言翻译的文本字段（名称、描述、标题等）。
> 完整设计规范见 [database-design-guide.md](database-design-guide.md) §8「多语言翻译表设计规范」。

```sql
-- ============================================================
-- 模块: {模块名称}
-- 实体: {实体名称}多语言
-- 表名: {主表名}_lang
-- 说明: {实体名称}多语言翻译表
-- ============================================================
CREATE TABLE `{主表名}_lang` (
    `id`            BIGINT NOT NULL  COMMENT '主键',
    `saas_id`       BIGINT NOT NULL           COMMENT '租户ID',
    `{entity}_id`   BIGINT NOT NULL  COMMENT '{实体名称}ID（关联{主表名}.id）',
    `lang`          VARCHAR(10) NOT NULL      COMMENT '语言代码(zh-CN/en-US/ja-JP...)',

    -- ========== 需要翻译的字段（仅文本类字段）==========
    `{field_name}`  VARCHAR(100) NULL         COMMENT '{字段说明}（翻译）',
    `{field_desc}`  TEXT NULL                  COMMENT '{字段说明}（翻译）',

    -- ========== 通用字段 ==========
    `create_date`   DATETIME(3) NOT NULL      COMMENT '创建时间',
    `modify_date`   DATETIME(3) NOT NULL      COMMENT '修改时间',
    `state`         INT NOT NULL DEFAULT 1    COMMENT '状态(0:禁用 1:启用)',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_{表名缩写}_{entity}_id_lang` (`{entity}_id`, `lang`),
    KEY `idx_{表名缩写}_lang` (`lang`)

) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_0900_ai_ci 
  COMMENT='{模块名称}-{实体名称}多语言';
```

---

## 3. 完整示例

### 3.1 用户表 (guest_user)

```sql
-- ============================================================
-- 模块: 用户中心
-- 实体: 用户
-- 表名: guest_user
-- 说明: C端用户信息
-- 数据规模: 10万/年增长50万/3年160万
-- ============================================================
CREATE TABLE `guest_user` (
    `id`            BIGINT NOT NULL  COMMENT '主键',
    `saas_id`       BIGINT NOT NULL                 COMMENT '租户ID',
    `username`      VARCHAR(100)      NOT NULL                 COMMENT '登录名',
    `password`      VARCHAR(100)      NOT NULL                 COMMENT '密码(BCrypt加密)',
    `mobile`        VARCHAR(20)       NULL     DEFAULT NULL    COMMENT '手机号(AES加密)',
    `email`         VARCHAR(100)      NULL     DEFAULT NULL    COMMENT '邮箱',
    `gender`        INT           NULL     DEFAULT NULL    COMMENT '性别(0:未知 1:男 2:女)',
    `birthday`      DATETIME(3)          NULL     DEFAULT NULL    COMMENT '生日',
    `user_icon`     VARCHAR(200)      NULL     DEFAULT NULL    COMMENT '头像URL',
    `create_date`   DATETIME(3)          NOT NULL         COMMENT '创建时间',
    `modify_date`   DATETIME(3)          NOT NULL COMMENT '修改时间',
    `state`         INT           NOT NULL DEFAULT 1       COMMENT '状态(0:禁用 1:启用)',
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_gu_mobile` (`mobile`),
    UNIQUE KEY `uk_gu_email` (`email`),
    KEY `idx_gu_state` (`state`)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_0900_ai_ci 
  COMMENT='用户中心-用户信息';
```

### 3.2 订单表 (order_info)

```sql
-- ============================================================
-- 模块: 订单中心
-- 实体: 订单
-- 表名: order_info
-- 说明: 订单主表
-- 数据规模: 100万/年增长1000万/3年3100万
-- 分表策略: 按月分表 order_info_YYYYMM
-- ============================================================
CREATE TABLE `order_info` (
    `id`              BIGINT NOT NULL  COMMENT '主键',
    `saas_id`         BIGINT NOT NULL                 COMMENT '租户ID',
    `guest_id`        BIGINT NOT NULL                 COMMENT '用户ID',
    `order_no`        VARCHAR(64)       NOT NULL                 COMMENT '订单编号',
    `order_state`     INT NOT NULL   DEFAULT 0     COMMENT '订单状态(0:待支付 1:已支付 2:已取消 3:已完成)',
    `order_amount`     BIGINT NOT NULL   DEFAULT 0     COMMENT '订单金额(分)',
    `pay_type`        INT NULL       DEFAULT NULL  COMMENT '支付类型(1:微信 2:支付宝)',
    `pay_amount`       BIGINT NULL       DEFAULT NULL  COMMENT '实付金额(分)',
    `pay_date`        DATETIME(3) NULL       DEFAULT NULL  COMMENT '支付时间',
    `create_date`     DATETIME(3) NOT NULL         COMMENT '创建时间',
    `modify_date`     DATETIME(3) NOT NULL COMMENT '修改时间',
    `state`           INT NOT NULL DEFAULT 1       COMMENT '状态(0:禁用 1:启用)',
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_oi_order_no` (`order_no`),
    KEY `idx_oi_guest_id` (`guest_id`),
    KEY `idx_oi_state` (`order_state`),
    KEY `idx_oi_create_date` (`create_date`)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_0900_ai_ci 
  COMMENT='订单中心-订单信息';
```

### 3.3 订单明细表 (order_item)

```sql
-- ============================================================
-- 模块: 订单中心
-- 实体: 订单明细
-- 表名: order_item
-- 说明: 订单商品明细
-- 数据规模: 300万/年增长3000万/3年9300万
-- 分表策略: 与order_info同维度分表
-- ============================================================
CREATE TABLE `order_item` (
    `id`                BIGINT NOT NULL  COMMENT '主键',
    `saas_id`           BIGINT NOT NULL                 COMMENT '租户ID',
    `order_id`          BIGINT NOT NULL                 COMMENT '订单ID',
    `product_id`        BIGINT NOT NULL                 COMMENT '商品ID',
    `quantity`          INT NOT NULL   DEFAULT 1     COMMENT '购买数量',
    `product_price`     BIGINT NOT NULL   DEFAULT 0     COMMENT '单价(分)',
    `create_date`       DATETIME(3) NOT NULL         COMMENT '创建时间',
    `modify_date`       DATETIME(3) NOT NULL COMMENT '修改时间',
    `state`             INT NOT NULL DEFAULT 1       COMMENT '状态(0:禁用 1:启用)',
    
    PRIMARY KEY (`id`),
    KEY `idx_oi_order_id` (`order_id`),
    KEY `idx_oi_product_id` (`product_id`)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_0900_ai_ci 
  COMMENT='订单中心-订单明细';
```

### 3.4 商品多语言表 (product_info_lang)

```sql
-- ============================================================
-- 模块: 商品管理
-- 实体: 商品多语言
-- 表名: product_info_lang
-- 说明: 商品信息多语言翻译
-- ============================================================
CREATE TABLE `product_info_lang` (
    `id`            BIGINT NOT NULL  COMMENT '主键',
    `saas_id`       BIGINT NOT NULL           COMMENT '租户ID',
    `product_id`    BIGINT NOT NULL  COMMENT '商品ID（关联product_info.id）',
    `lang`          VARCHAR(10) NOT NULL      COMMENT '语言代码(zh-CN/en-US/ja-JP...)',
    `product_name`  VARCHAR(100) NULL         COMMENT '商品名称（翻译）',
    `product_desc`  TEXT NULL                  COMMENT '商品描述（翻译）',
    `create_date`   DATETIME(3) NOT NULL      COMMENT '创建时间',
    `modify_date`   DATETIME(3) NOT NULL      COMMENT '修改时间',
    `state`         INT NOT NULL DEFAULT 1    COMMENT '状态(0:禁用 1:启用)',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_pil_product_id_lang` (`product_id`, `lang`),
    KEY `idx_pil_lang` (`lang`)

) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_0900_ai_ci 
  COMMENT='商品-商品信息多语言';
```

---

## 4. 索引DDL示例

> 索引设计规则详见 [数据库设计指南 - 索引设计规则](database-design-guide.md#索引设计规则)

### 4.1 常用索引DDL

```sql
-- 主键索引（必须）
PRIMARY KEY (`id`)

-- 唯一索引（业务唯一字段）
UNIQUE KEY `uk_{表名缩写}_{字段名}` (`order_no`)

-- 单字段索引（等值查询）
KEY `idx_{表名缩写}_{字段名}` (`state`)

-- 组合索引（范围查询+等值查询，最左前缀原则）
KEY `idx_{表名缩写}_{字段1}_{字段2}` (`saas_id`, `create_date`)

-- 覆盖索引（查询字段都在索引中，避免回表）
KEY `idx_{表名缩写}_{字段1}_{字段2}_{字段3}` (`saas_id`, `state`, `order_no`)
```

### 4.2 表名缩写规则

取各单词首字母，无下划线：
- guest_user → gu
- order_info → oi
- order_item → oitem（避免与oi冲突）

---

## 5. 分库分表DDL

### 5.1 按月分表示例

```sql
-- 创建当前月份表
CREATE TABLE `order_info_202401` LIKE `order_info`;

-- 创建下月份表（预创建）
CREATE TABLE `order_info_202402` LIKE `order_info`;

-- 修改表注释
ALTER TABLE `order_info_202401` COMMENT='订单中心-订单信息-2024年1月';
```

### 5.2 归档表结构

```sql
-- 创建归档表（与主表结构相同，但可去除部分索引以节省空间）
CREATE TABLE `order_info_archive` (
    -- 字段与主表相同
    ...
    -- 只保留主键和必要的查询索引
    PRIMARY KEY (`id`),
    KEY `idx_archive_order_no` (`order_no`)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COMMENT='订单中心-订单归档表';
```

---

## 6. DDL检查清单

- [ ] 数据库字符集为 utf8mb4
- [ ] 所有表包含 id/saas_id/create_date/modify_date/state 字段
- [ ] 主键为 BIGINT
- [ ] 金额/价格字段使用 BIGINT 类型（单位为分）
- [ ] 每个字段都有 COMMENT 注释
- [ ] 枚举字段注释中注明取值含义
- [ ] 索引命名符合规范（uk_/idx_前缀）
- [ ] 唯一索引用于业务唯一字段
- [ ] 外键关系由程序控制（不设置外键约束）
- [ ] 表注释格式为"模块-实体"
