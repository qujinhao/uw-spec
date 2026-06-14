# uw-ai — AI集成模块

**Maven 坐标**: `com.umtone:uw-ai`

**配置前缀**: `uw.ai`

```yaml
uw:
  ai:
    ai-center-host: http://uw-ai-center
```

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 同步对话 | `AiClientHelper.generate(param)` | 返回 `ResponseData<String>` |
| 流式对话(SSE) | `AiClientHelper.chatGenerate(param)` | 返回 `Flux<String>` |
| 结构化输出 | `AiClientHelper.generateEntity(param, Class)` | 返回 `ResponseData<T>` |
| 带工具对话 | param 设置 `.toolList(...)` + `.toolContext(...)` | — |
| 多轮对话 | `AiChatSessionParam` + `windowSize` | 保留历史消息数 |
| 批量翻译(数组) | `AiClientHelper.translateList(param)` | — |
| Map翻译 | `AiClientHelper.translateMap(param)` | key保留，value翻译 |
| 自定义AI工具 | 实现 `AiTool<P,R>` 接口 + `@Component` | 工具类是 Spring Bean |
| 绑定用户信息 | `param.bindAuthInfo()` | 自动绑定当前登录用户 |

## AiClientHelper 方法签名

全部静态方法，无需实例化。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `generate(AiChatGenerateParam)` | `ResponseData<String>` | 同步生成 |
| `chatGenerate(AiChatGenerateParam)` | `Flux<String>` | 流式生成（SSE） |
| `generateEntity(AiChatGenerateParam, Class<T>)` | `ResponseData<T>` | 生成并转换为对象 |
| `listToolMeta(appName)` | `ResponseData<List<AiToolMeta>>` | 获取工具元数据 |
| `updateToolMeta(AiToolMeta)` | `ResponseData` | 更新工具元数据 |
| `translateList(AiTranslateListParam)` | `ResponseData<AiTranslateResultData[]>` | 数组翻译 |
| `translateMap(AiTranslateMapParam)` | `ResponseData<AiTranslateResultData[]>` | Map翻译 |

## AiChatGenerateParam

构造：`AiChatGenerateParam.builder().configId(1L).userPrompt("...").build()` — Builder 模式，也支持 `new AiChatGenerateParam()` + setter

| 字段 | 类型 | 说明 |
|------|------|------|
| configId | long | AI配置ID（必填） |
| userPrompt | String | 用户输入（必填） |
| systemPrompt | String | 系统提示 |
| saasId | long | 租户ID（bindAuthInfo自动填充） |
| userId | long | 用户ID（bindAuthInfo自动填充） |
| userType | int | 用户类型（bindAuthInfo自动填充） |
| userInfo | String | 用户信息（bindAuthInfo自动填充） |
| toolList | `List<AiToolCallInfo>` | 工具列表 |
| toolContext | `Map<String,Object>` | 工具上下文 |
| ragLibIds | `long[]` | RAG知识库ID列表 |
| fileList | `MultipartFile[]` | 文件列表 |

## AiChatSessionParam（多轮对话）

构造：`AiChatSessionParam.builder().configId(1L).userPrompt("...").windowSize(10).build()` — Builder 模式，也支持 `new AiChatSessionParam()` + setter

| 字段 | 类型 | 说明 |
|------|------|------|
| configId | long | AI配置ID |
| userPrompt | String | 用户输入 |
| systemPrompt | String | 系统提示 |
| windowSize | int | 窗口大小（保留历史消息数） |
| saasId | long | 租户ID（bindAuthInfo自动填充） |
| userId | long | 用户ID（bindAuthInfo自动填充） |
| userType | int | 用户类型（bindAuthInfo自动填充） |
| userInfo | String | 用户信息（bindAuthInfo自动填充） |
| toolList | `List<AiToolCallInfo>` | 工具列表 |
| ragLibIds | `long[]` | RAG知识库ID列表 |

## AiToolCallInfo

构造：`new AiToolCallInfo(toolName, toolVersion)`

| 字段 | 类型 | 说明 |
|------|------|------|
| toolName | String | 工具名称 |
| toolVersion | String | 工具版本 |

## AiTranslateBaseParam（翻译参数基类）

AiTranslateListParam 和 AiTranslateMapParam 的共同基类。

| 字段 | 类型 | 说明 |
|------|------|------|
| configId | long | AI配置ID |
| sourceLang | String | 源语言（auto表示自动检测） |
| targetLang | String | 目标语言 |
| systemPrompt | String | 系统提示 |

## AiTranslateListParam

继承 AiTranslateBaseParam。构造：`new AiTranslateListParam()` + setter

| 字段 | 类型 | 说明 |
|------|------|------|
| sourceArray | String[] | 待翻译文本数组 |

## AiTranslateMapParam

继承 AiTranslateBaseParam。构造：`new AiTranslateMapParam()` + setter

| 字段 | 类型 | 说明 |
|------|------|------|
| sourceMap | `Map<String, String>` | 待翻译Map（key保留，value翻译） |

## AiTranslateResultData

| 字段 | 类型 | 说明 |
|------|------|------|
| source | String | 原文 |
| target | String | 译文 |

## AI工具扩展

构造：实现 `AiTool<P, R>` 接口 + `@Component` — P 继承 `AiToolParam`，R 为返回类型。

| 方法 | 说明 |
|------|------|
| `toolName()` | 工具名称 |
| `toolDesc()` | 工具描述 |
| `toolVersion()` | 工具版本 |
| `apply(P param)` | 工具执行逻辑 |

**AiTool 实现示例**：
```java
// AiTool 实现类是 Spring Bean（由框架管理生命周期），必须加 @Component。
@Component
public class WeatherTool implements AiTool<WeatherToolParam, ResponseData<WeatherInfo>> {

    @Override
    public String toolName() { return "getWeather"; }

    @Override
    public String toolDesc() { return "获取指定城市的天气信息"; }

    @Override
    public String toolVersion() { return "1.0"; }

    @Override
    public ResponseData<WeatherInfo> apply(WeatherToolParam param) {
        WeatherInfo info = WeatherHelper.getWeather(param.getCity(), param.getDate());
        return ResponseData.success(info);
    }
}
```

## AiToolMeta

| 字段 | 类型 | 说明 |
|------|------|------|
| appName | String | 应用名称 |
| toolName | String | 工具名称 |
| toolDesc | String | 工具描述 |
| toolVersion | String | 工具版本 |
| paramSchema | String | 参数JSON Schema |

## Helper 使用示例

```java
public class AiCallHelper {

    // 简单对话
    public static String chat(String message) {
        AiChatGenerateParam param = AiChatGenerateParam.builder()
            .configId(1L)
            .userPrompt(message)
            .build();
        param.bindAuthInfo();
        return AiClientHelper.generate(param).getData();
    }

    // 带系统提示的对话
    public static String chatWithSystemPrompt(String message) {
        AiChatGenerateParam param = AiChatGenerateParam.builder()
            .configId(1L)
            .systemPrompt("你是一个专业的Java开发助手，请用简洁的语言回答问题。")
            .userPrompt(message)
            .build();
        param.bindAuthInfo();
        return AiClientHelper.generate(param).getData();
    }

    // 流式对话（SSE）
    public static Flux<String> streamChat(String message) {
        AiChatGenerateParam param = AiChatGenerateParam.builder()
            .configId(1L)
            .userPrompt(message)
            .build();
        param.bindAuthInfo();
        return AiClientHelper.chatGenerate(param);
    }

    // 结构化输出（生成Java对象）
    public static UserIntent analyzeIntent(String message) {
        AiChatGenerateParam param = AiChatGenerateParam.builder()
            .configId(1L)
            .systemPrompt("分析用户意图，提取关键信息")
            .userPrompt(message)
            .build();
        param.bindAuthInfo();
        return AiClientHelper.generateEntity(param, UserIntent.class).getData();
    }

    // 使用工具
    public static String chatWithTools(String message) {
        List<AiToolCallInfo> tools = Arrays.asList(
            new AiToolCallInfo("getWeather", "1.0"),
            new AiToolCallInfo("sendEmail", "1.0")
        );
        AiChatGenerateParam param = AiChatGenerateParam.builder()
            .configId(1L)
            .userPrompt(message)
            .toolList(tools)
            .toolContext(Map.of("userId", AuthServiceHelper.getUserId()))
            .build();
        param.bindAuthInfo();
        return AiClientHelper.generate(param).getData();
    }

    // 批量翻译（数组）
    public static Map<String, String> translateProducts(List<String> productNames) {
        AiTranslateListParam param = new AiTranslateListParam();
        param.setConfigId(2L);
        param.setSourceLang("zh");
        param.setTargetLang("en");
        param.setSourceArray(productNames.toArray(new String[0]));

        ResponseData<AiTranslateResultData[]> response = AiClientHelper.translateList(param);

        Map<String, String> result = new HashMap<>();
        for (AiTranslateResultData data : response.getData()) {
            result.put(data.getSource(), data.getTarget());
        }
        return result;
    }

    // 翻译Map（key保留，value翻译）
    public static Map<String, String> translateMap(Map<String, String> contentMap) {
        AiTranslateMapParam param = new AiTranslateMapParam();
        param.setConfigId(2L);
        param.setSourceLang("auto");
        param.setTargetLang("en");
        param.setSourceMap(contentMap);

        ResponseData<AiTranslateResultData[]> response = AiClientHelper.translateMap(param);

        Map<String, String> result = new HashMap<>();
        for (AiTranslateResultData data : response.getData()) {
            result.put(data.getSource(), data.getTarget());
        }
        return result;
    }
}

// 结构化输出示例
@Data
public class UserIntent {
    private String intent;         // 意图类型
    private double confidence;     // 置信度
    private List<String> entities; // 实体列表
    private Map<String, String> params;  // 参数
}
```
