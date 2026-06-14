# 环境配置参考

## Git平台变量配置

CI/CD流水线依赖以下平台级变量和密钥，需在 Gitea/GitHub 的仓库设置中预先配置。

### 仓库变量（Variables）

| 变量名 | 说明 | Gitea 示例 | GitHub 示例 |
|--------|------|-----------|-------------|
| `REGISTRY_SERVER` | 私有Docker Registry地址 | `192.168.88.21:5000` | `${{ vars.REGISTRY_SERVER }}` |
| `PUBLIC_REGISTRY_SERVER` | 公共Docker Registry地址（可选） | `registry.cn-hangzhou.aliyuncs.com` | 同左 |
| `PUBLIC_REGISTRY_OWNER` | 公共Registry组织/用户名（可选） | `my-org` | 同左 |

**引用方式**： `${{ vars.REGISTRY_SERVER }}`

### 仓库密钥（Secrets）

| 密钥名 | 说明 | 用途 |
|--------|------|------|
| `REGISTRY_USERNAME` | 私有Registry用户名 | Docker登录 |
| `REGISTRY_TOKEN` | 私有Registry密码/Token | Docker登录 |
| `PUBLIC_REGISTRY_USERNAME` | 公共Registry用户名（可选） | 公共镜像推送 |
| `PUBLIC_REGISTRY_TOKEN` | 公共Registry密码/Token（可选） | 公共镜像推送 |

**引用方式**： `${{secrets.REGISTRY_USERNAME}}`

## 后端部署配置

| 变量 | 说明 | 示例 |
|------|------|------|
| `MODULE_PATH` | 后端模块路径 | `backend/zihu-app` |
| `APP_NAME` | 应用名称（镜像名） | `zihu-app` |
| `APP_PORT` | 应用服务端口 | `59999` |

**版本获取**：
```bash
APP_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
```

## 前端部署配置

### SaaS Web

| 变量 | 说明 | 示例 |
|------|------|------|
| `MODULE_PATH` | 前端模块路径 | `frontend/zihu-saas-web` |
| `APP_NAME` | 应用名称（镜像名） | `zihu-saas-web` |
| `APP_PORT` | Nginx监听端口 | `60001` |

**版本获取**：
```bash
APP_VERSION=$(node -p "require('./package.json').version")
```

**Nacos配置**（通过容器环境变量注入）：

| 变量 | 说明 |
|------|------|
| `NACOS_SERVER` | Nacos服务地址 |
| `NACOS_NAMESPACE` | Nacos命名空间ID |
| `NACOS_USERNAME` | Nacos用户名 |
| `NACOS_PASSWORD` | Nacos密码 |
| `APP_HOST` | 实例IP地址 |

### UniApp

| 变量 | 说明 | 示例 |
|------|------|------|
| `MODULE_PATH` | UniApp模块路径 | `frontend/zihu-guest-uni` |
| `APP_NAME` (build-h5) | H5应用名称 | `zihu-guest-h5` |
| `APP_PORT` (build-h5) | H5端口 | `60002` |
| `APP_NAME` (build-mp-weixin) | 小程序应用名称 | `zihu-guest-mp-weixin` |

## 镜像命名规则

| 项目类型 | 镜像标签格式 | 示例 |
|----------|-------------|------|
| 后端 | `{REGISTRY_SERVER}/{APP_NAME}:{VERSION}` | `192.168.88.21:5000/zihu:1.0.0` |
| 前端Web | `{REGISTRY_SERVER}/{APP_NAME}:{VERSION}` | `192.168.88.21:5000/zihu-saas-web:1.0.0` |
| H5 | `{REGISTRY_SERVER}/{APP_NAME}:{VERSION}` | `192.168.88.21:5000/zihu-guest-h5:1.0.0` |
| 公共镜像(可选) | `{PUBLIC_REGISTRY_SERVER}/{OWNER}/{APP_NAME}:{VERSION}` | `registry.cn-hangzhou.aliyuncs.com/my-org/zihu:1.0.0` |

## Gitea Runner 环境要求

Gitea自托管Runner需预装以下工具：

| 工具 | 用途 |
|------|------|
| Docker + Buildx | 多架构镜像构建 |
| `multiarch/qemu-user-static` | ARM64模拟支持 |
| Maven | Java项目构建 |
| Node.js | 前端项目构建 |
| `deploy-registry-app.sh` | 部署脚本（位于 `/home/gitea/runner/deploy/`） |

### 环境变量加载

act_runner 执行 job 时使用 `bash --noprofile --norc`，不会自动加载 `~/.profile`。Shell 模式模板中通过 `source ~/.profile` 加载用户环境（SDKMAN/Java/Maven等）。

### Git 克隆认证

Shell 模式通过 `gitea.token` 内置变量进行认证，无需手动配置凭据：

```bash
GIT_SERVER=${{gitea.server_url}}
git clone -q ${GIT_SERVER%%://*}://gitea:${{gitea.token}}@${GIT_SERVER#*://}/${{gitea.repository}}.git .
```

- `${GIT_SERVER%%://*}` — 提取协议（http/https）
- `${GIT_SERVER#*://}` — 提取 host:port
- `${{gitea.token}}` — Gitea 自动生成的临时 token，job 结束后失效

### Buildx 镜像加速配置

**`/etc/docker/buildkitd.toml`**：为 buildx 的 BuildKit 配置 Docker Hub 镜像加速，解决内网无法访问 Docker Hub 的问题。

```toml
[registry."docker.io"]
  mirrors = ["docker.1panel.live", "docker.nju.edu.cn", "docker.mirrors.ustc.edu.cn"]
```

修改后需重建 buildx 实例：`docker buildx rm multiarch`

### systemd 服务配置

act_runner 通过 systemd 启动时，建议使用 `bash -l` 加载 login shell 环境：

```ini
[Service]
ExecStart=/bin/bash -lc 'source /etc/profile || true;/home/gitea/runner/bin/act_runner daemon --config /home/gitea/runner/config/config.yaml'
```
