# uw-mydb-client — 数据库客户端

**Maven 坐标**: `com.umtone:uw-mydb-client`

MyDB 数据库运维中心客户端，用于动态分配 SAAS 数据节点，实现分库分表路由。

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 分配SAAS节点(自动) | `MydbClientHelper.assignSaasNode(saasId)` | 静态方法 |
| 分配SAAS节点(指定节点) | `MydbClientHelper.assignSaasNode(saasId, preferNode)` | — |
| 分配SAAS节点(指定配置组) | `MydbClientHelper.assignSaasNode(configKey, saasId, preferNode)` | configKey 默认 "default" |

## MydbClientHelper 方法签名

> **包路径**：`uw.mydb.client.MydbClientHelper`

全部静态方法。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `assignSaasNode(Serializable saasId)` | `ResponseData<DataNode>` | 自动分配节点 |
| `assignSaasNode(saasId, String preferNode)` | `ResponseData<DataNode>` | 指定预设节点 |
| `assignSaasNode(configKey, saasId, preferNode)` | `ResponseData<DataNode>` | 指定配置组 |

返回值：SUCCESS=新建 / WARN=已存在 / ERROR=失败

## DataNode

> **包路径**：`uw.mydb.client.DataNode`

构造：`new DataNode(long clusterId, String database)` 或 `new DataNode("clusterId.database")`

| 字段 | 类型 | 说明 |
|------|------|------|
| clusterId | long | MySQL集群ID |
| database | String | 数据库名 |

`toString()` 返回 `"clusterId.database"`

## Helper 使用示例

```java
public class DatabaseHelper {
    /**
     * 为新租户分配数据库节点
     */
    public void initSaasDatabase(long saasId) {
        // 自动分配节点
        ResponseData<DataNode> response = MydbClientHelper.assignSaasNode(saasId);
        if (response.isSuccess()) {
            DataNode node = response.getData();
            log.info("创建新节点: 集群={}, 库名={}", node.getClusterId(), node.getDatabase());
        } else if (response.isWarn()) {
            DataNode node = response.getData();
            log.warn("节点已存在: 集群={}, 库名={}", node.getClusterId(), node.getDatabase());
        } else {
            log.error("节点分配失败: {}", response.getMsg());
        }
        throw new RuntimeException("节点分配失败: " + response.getMsg());
    }
    
    /**
     * 指定集群和预设节点名分配
     */
    public void assignToSpecificCluster(long saasId) {
        ResponseData<DataNode> response = MydbClientHelper.assignSaasNode(
            "cluster-a",      // 配置组
            saasId,           // 运营商ID
            "db_shard_01"     // 预设节点名
        );
    }
```
