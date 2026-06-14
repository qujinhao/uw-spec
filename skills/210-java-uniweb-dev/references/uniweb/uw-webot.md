# uw-webot — Web自动化框架

**Maven 坐标**: `com.umtone:uw-webot`

基于 Microsoft Playwright 的高性能 Web 自动化框架，采用 Hybrid 混合模式设计，支持浏览器实例复用和页签级隔离，提供验证码识别、反检测、代理池等企业级功能。

**配置前缀**: `uw.webot`

```yaml
uw:
  webot:
    enabled: true
    bot-pool:
      max-browsers-per-group: 5      # 每种浏览器类型最大实例数
      max-tabs-per-browser: 20       # 每个浏览器实例最大页签数
    session:
      distributed: false             # 是否启用分布式会话
      default-session:
        expire-time: P30D            # 会话默认过期时间（ISO-8601格式）
    # 验证码配置
    captcha:
      default:
        service-type: OCR            # OCR/TWOCAPTCHA/CAPSOLVER
        api-key: ""                  # 第三方服务API密钥
    # 代理配置
    proxy:
      default:
        type: HTTP                   # HTTP/HTTPS/SOCKS4/SOCKS5
        servers:
          - host: 127.0.0.1
            port: 8080
            username: ""             # 可选认证
            password: ""
    # 反检测配置
    stealth:
      default:
        enabled: true
        webdriver-hide: true
        webgl-spoof: true
        canvas-noise: true
```

## AI 决策速查

| 我要做什么 | 用什么 | 关键约束 |
|-----------|--------|---------|
| 获取实例 | `WebotManager.getInstance()` | 静态单例 |
| 创建会话 | `webotManager.createSession(SessionConfig)` | Builder 模式构建配置 |
| 关闭会话 | `webotManager.closeSession(session)` | — |
| 打开页签 | `webotManager.openBrowserTab(session)` | try-with-resources 自动关闭 |
| 执行操作（推荐） | `webotManager.execute(session, tab -> {...})` | 自动管理资源 |
| 导航 | `tab.navigate(url)` | — |
| 获取文本 | `tab.getInnerText(selector)` | — |
| 填写表单 | `tab.fill(selector, value)` | — |
| 点击 | `tab.click(selector)` | — |
| 截图 | `tab.screenshot()` | 返回 byte[] |
| 执行JS | `tab.evaluate(expression)` | — |
| 下拉框选择 | `tab.selectOption(selector, values)` | values 为 String[] |
| 复选框 | `tab.check(selector)` / `tab.uncheck(selector)` | — |
| 鼠标悬停 | `tab.hover(selector)` | — |
| 文件上传 | `tab.fileInput(selector, files)` | files 为 String[] 路径 |
| 下载文件 | `tab.download(url)` | 返回 byte[] |
| 生成PDF | `tab.pdf()` | 返回 byte[] |
| 识别验证码 | `webotManager.getCaptchaService("default").recognizeBase64Captcha(base64)` | — |

## 架构

```
WebotManager (单例)
    ├── BrowserBotPool
    │       ├── BrowserGroup (chromium) → BrowserInstance → BrowserTab
    │       ├── BrowserGroup (firefox)
    │       └── BrowserGroup (webkit)
    ├── CaptchaManager
    ├── StealthManager
    └── ProxyManager
```

## WebotManager 方法签名

> **包路径**：`uw.webot.WebotManager`

构造：`WebotManager.getInstance()` 静态单例

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `createSession(SessionConfig)` | WebotSession | 创建会话 |
| `getSession(sessionId)` | WebotSession | 获取会话 |
| `closeSession(WebotSession)` | void | 关闭会话并释放资源 |
| `listSessions()` | `List<WebotSession>` | 列出所有活跃会话 |
| `openBrowserTab(session)` | BrowserTab | 打开页签（需手动关闭） |
| `execute(session, WebotFunction)` | T | 执行操作（推荐，自动管理资源） |
| `getCaptchaService(configName)` | CaptchaService | 获取验证码服务 |
| `getProxyService(configName)` | ProxyService | 获取代理服务 |
| `getStealthService(configName)` | StealthService | 获取反检测服务 |
| `getBrowserBotPool()` | BrowserBotPool | 获取浏览器池 |
| `getConfig()` | WebotConfig | 获取全局配置 |

## WebotSession

> **包路径**：`uw.webot.WebotSession`

构造：由 `createSession()` 返回，不直接构造。

| 字段 | 类型 | 说明 |
|------|------|------|
| sessionId | String | 会话唯一标识 |
| state | int | 会话状态（0=活跃，1=过期，2=关闭） |
| createDate | Date | 创建时间 |
| lastAccessDate | Date | 最后访问时间 |
| expireDate | Date | 过期时间 |
| browserConfig | BrowserConfig | 浏览器配置 |
| captchaConfigKey | String | 验证码配置key |
| stealthConfigKey | String | 反检测配置key |
| proxyConfigKey | String | 代理配置key |

## SessionConfig

> **包路径**：`uw.webot.SessionConfig`

构造：`SessionConfig.builder().browserConfig(...).stealthConfigKey("default").build()` — Builder 模式。也支持 `new SessionConfig()` + setter

| 字段 | 类型 | 说明 |
|------|------|------|
| browserConfig | BrowserConfig | 浏览器配置 |
| captchaConfigKey | String | 验证码配置key |
| stealthConfigKey | String | 反检测配置key |
| proxyConfigKey | String | 代理配置key |

## BrowserConfig

> **包路径**：`uw.webot.BrowserConfig`

构造：`BrowserConfig.builder().browserType(CHROMIUM).headless(true).build()` — Builder 模式。也支持 `new BrowserConfig()` + setter

| 属性 | 类型 | 说明 |
|------|------|------|
| browserType | BrowserType | CHROMIUM / FIREFOX / WEBKIT |
| headless | boolean | 无头模式，默认 true |
| viewportWidth | int | 视口宽度，默认 1920 |
| viewportHeight | int | 视口高度，默认 1080 |
| userAgent | String | 自定义 UA |
| locale | String | 语言设置 |
| timezone | String | 时区 |
| args | List<String> | 启动参数 |
| ignoreHTTPSErrors | boolean | 忽略HTTPS错误 |
| javaScriptEnabled | boolean | 是否启用JS，默认 true |
| slowMo | double | 操作减速（毫秒，调试用） |

## LoadState 枚举

| 值 | 说明 |
|------|------|
| LOAD | DOMContentLoaded 触发 |
| DOMCONTENTLOADED | DOM 解析完成 |
| NETWORKIDLE | 500ms 无网络请求（推荐等待） |

## BrowserTab

构造：由 `openBrowserTab()` 或 `execute()` 返回，实现 Closeable。

**导航与加载**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `navigate(url)` | void | 导航到URL |
| `waitForLoadState(LoadState)` | void | 等待加载完成 |
| `waitForNavigation()` | void | 等待导航完成 |
| `waitForTimeout(timeout)` | void | 等待指定时间（毫秒） |
| `goBack()` | void | 后退 |
| `goForward()` | void | 前进 |
| `reload()` | void | 刷新页面 |
| `getUrl()` | String | 获取当前URL |
| `getTitle()` | String | 获取页面标题 |

**元素操作**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `click(selector)` | void | 点击元素 |
| `dblclick(selector)` | void | 双击元素 |
| `fill(selector, value)` | void | 填写表单（清空后输入） |
| `type(selector, text)` | void | 输入文本（追加模式） |
| `press(key)` | void | 按键（如 Enter/Tab/Escape） |
| `selectOption(selector, String[])` | void | 下拉框选择 |
| `check(selector)` | void | 勾选复选框 |
| `uncheck(selector)` | void | 取消勾选 |
| `hover(selector)` | void | 鼠标悬停 |
| `fileInput(selector, String[])` | void | 文件上传（参数为文件路径数组） |

**元素查询与等待**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `querySelector(selector)` | ElementHandle | 查找单个元素 |
| `querySelectorAll(selector)` | List<ElementHandle> | 查找所有元素 |
| `waitForSelector(selector)` | void | 等待元素出现 |
| `waitForFunction(expression)` | void | 等待JS函数返回true |
| `isVisible(selector)` | boolean | 元素是否可见 |
| `isEnabled(selector)` | boolean | 元素是否可用 |

**内容获取**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getInnerText(selector)` | String | 获取文本 |
| `getTextContent(selector)` | String | 获取textContent |
| `getInnerHTML(selector)` | String | 获取内部HTML |
| `getOuterHTML(selector)` | String | 获取外部HTML |
| `getAttribute(selector, name)` | String | 获取属性 |

**页面操作**：

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `screenshot()` | byte[] | 全页截图 |
| `screenshot(selector)` | byte[] | 元素截图 |
| `download(url)` | byte[] | 下载文件 |
| `pdf()` | byte[] | 生成PDF |
| `evaluate(expression)` | Object | 执行JS表达式 |
| `setContent(html)` | void | 设置页面内容 |
| `addScriptTag(url)` | void | 注入脚本 |
| `addStyleTag(url)` | void | 注入样式 |
| `setExtraHTTPHeaders(Map)` | void | 设置额外请求头 |
| `close()` | void | 归还到连接池 |

## ElementHandle

构造：由 `querySelector()` / `querySelectorAll()` 返回。

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `click()` | void | 点击此元素 |
| `fill(value)` | void | 填写值 |
| `type(text)` | void | 输入文本 |
| `getInnerText()` | String | 获取文本 |
| `getTextContent()` | String | 获取textContent |
| `getAttribute(name)` | String | 获取属性 |
| `isVisible()` | boolean | 是否可见 |
| `isEnabled()` | boolean | 是否可用 |
| `isChecked()` | boolean | 是否勾选 |
| `screenshot()` | byte[] | 元素截图 |
| `evaluate(expression)` | Object | 在元素上执行JS |
| `querySelector(selector)` | ElementHandle | 在子树中查找 |
| `querySelectorAll(selector)` | List<ElementHandle> | 在子树中查找所有 |

## CaptchaService

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `recognizeImageCaptcha(byte[])` | CaptchaResult | 识别图片验证码 |
| `recognizeBase64Captcha(base64)` | CaptchaResult | 识别Base64图片 |
| `solveRecaptchaV2(siteKey, url)` | CaptchaResult | ReCaptcha V2 |
| `solveRecaptchaV3(siteKey, url, minScore)` | CaptchaResult | ReCaptcha V3 |
| `solveHCaptcha(siteKey, url)` | CaptchaResult | hCaptcha |
| `solveFuncaptcha(publicKey, url)` | CaptchaResult | FunCaptcha |
| `solveGeeTest(gt, challenge, url)` | CaptchaResult | 极验验证码 |

服务类型：OCR(本地) / TWOCAPTCHA / CAPSOLVER

## CaptchaResult

| 字段 | 类型 | 说明 |
|------|------|------|
| text | String | 识别结果文本 |
| code | String | 验证码解决方案（ReCaptcha等） |
| isValid | boolean | 是否识别成功 |
| cost | long | 耗时（毫秒） |

## ProxyService

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `getProxy()` | ProxyInfo | 获取一个代理 |
| `getProxy(ProxyType)` | ProxyInfo | 获取指定类型代理 |
| `getProxyList()` | `List<ProxyInfo>` | 获取代理列表 |
| `getProxyStats()` | ProxyStats | 获取代理统计 |
| `reportFailure(ProxyInfo)` | void | 报告代理失败 |
| `reportSuccess(ProxyInfo)` | void | 报告代理成功 |

**ProxyInfo**：host / port / username / password / type / alive / failCount / successCount

## StealthService

| 方法 | 说明 |
|------|------|
| `applyStealth(BrowserTab)` | 应用默认反检测脚本 |
| `applyStealth(BrowserTab, String configKey)` | 指定配置应用反检测 |

反检测功能：webdriver隐藏 / navigator伪装 / WebGL欺骗 / Canvas噪音 / Chrome插件伪装 / 语言/时区伪装

## Helper 使用示例

```java
public class WebCrawlerHelper {
    private static final WebotManager webotManager = WebotManager.getInstance();

    // 基础爬取
    public static String crawlPage(String url) throws Exception {
        SessionConfig config = SessionConfig.builder()
            .browserConfig(BrowserConfig.builder()
                .browserType(BrowserType.CHROMIUM)
                .headless(true).build())
            .stealthConfigKey("default")
            .build();
        WebotSession session = webotManager.createSession(config);
        return webotManager.execute(session, tab -> {
            tab.navigate(url);
            tab.waitForLoadState(LoadState.NETWORKIDLE);
            return tab.getInnerText("article");
        });
    }

    // 截图（手动管理页签）
    public static byte[] takeScreenshot(String url) throws Exception {
        WebotSession session = webotManager.createSession(SessionConfig.builder().build());
        try (BrowserTab tab = webotManager.openBrowserTab(session)) {
            tab.navigate(url);
            tab.waitForLoadState(LoadState.NETWORKIDLE);
            return tab.screenshot();
        }
    }

    // 表单填写 + 下拉框 + 文件上传
    public static void submitForm(String url, String name, String email, String filePath) throws Exception {
        SessionConfig config = SessionConfig.builder()
            .browserConfig(BrowserConfig.builder().browserType(BrowserType.CHROMIUM).build())
            .build();
        WebotSession session = webotManager.createSession(config);
        webotManager.execute(session, tab -> {
            tab.navigate(url);
            tab.waitForLoadState(LoadState.NETWORKIDLE);
            tab.fill("#name", name);
            tab.fill("#email", email);
            tab.selectOption("#country", new String[]{"CN"});
            tab.fileInput("#avatar", new String[]{filePath});
            tab.click("#submit");
            tab.waitForLoadState(LoadState.NETWORKIDLE);
            return null;
        });
    }

    // 验证码识别 + 登录
    public static String loginWithCaptcha(String url, String username, String password) throws Exception {
        SessionConfig config = SessionConfig.builder()
            .captchaConfigKey("default")
            .build();
        WebotSession session = webotManager.createSession(config);
        return webotManager.execute(session, tab -> {
            tab.navigate(url + "/login");
            tab.waitForLoadState(LoadState.NETWORKIDLE);
            tab.fill("#username", username);
            tab.fill("#password", password);
            // 获取验证码图片并识别
            byte[] captchaImg = tab.screenshot("#captcha-img");
            CaptchaResult result = webotManager.getCaptchaService("default").recognizeImageCaptcha(captchaImg);
            if (result.isValid()) {
                tab.fill("#captcha", result.getText());
            }
            tab.click("#login-btn");
            tab.waitForLoadState(LoadState.NETWORKIDLE);
            return tab.getUrl();
        });
    }
}
```
