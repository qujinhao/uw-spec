# 工作流模板

> **占位符说明**：
> - `{module-name}` — 模块目录名（如 `zihu-app`、`zihu-saas-web`、`zihu-guest-uni`）
> - `{module-path}` — 模块相对路径（如 `backend/zihu-app`、`frontend/zihu-saas-web`）
> - `{app-port}` — 应用服务端口
>
> 生成时将占位符替换为实际值。文件名 = `{module-name}.yml`。

---

## 1. Java-Shell

{module-name}.yml

```yaml
name: {module-name}
on:
  push:
    branches: [main]
    paths: ['{module-path}/**']

env:
  MODULE_PATH: {module-path}
  APP_NAME: {module-name}
  APP_PORT: {app-port}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: build & push
        run: |
          # 加载用户环境变量（SDKMAN/Java/Maven等）
          source ~/.profile

          # 通过gitea.token认证克隆仓库，自动适配http/https协议
          GIT_SERVER=${{gitea.server_url}}
          git clone -q ${GIT_SERVER%%://*}://gitea:${{gitea.token}}@${GIT_SERVER#*://}/${{gitea.repository}}.git .
          cd $MODULE_PATH

          # Maven构建，跳过测试
          mvn clean package -U -Dmaven.test.skip=true
          # 从pom.xml提取项目版本号
          APP_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

          # 注册QEMU多架构支持（ARM64模拟），已注册则跳过
          [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
          # 创建或复用buildx多架构构建器，使用buildkitd.toml中的镜像加速配置
          docker buildx use multiarch 2>/dev/null || docker buildx create --use --name multiarch --driver docker-container --driver-opt network=host --config /etc/docker/buildkitd.toml --platform linux/amd64,linux/arm64

          # 登录私有Docker Registry
          if [ -n "${{secrets.REGISTRY_USERNAME}}" ] && [ -n "${{secrets.REGISTRY_TOKEN}}" ]; then
            docker login ${{vars.REGISTRY_SERVER}} -u ${{secrets.REGISTRY_USERNAME}} --password-stdin <<< "${{secrets.REGISTRY_TOKEN}}"
          fi
          # 构建多架构镜像并推送到私有Registry
          docker buildx build --platform linux/amd64,linux/arm64 --provenance=false \
            -t ${{vars.REGISTRY_SERVER}}/${APP_NAME}:${APP_VERSION} --push .

          # 推送到公共Registry（可选）
          if [ -n "${{vars.PUBLIC_REGISTRY_SERVER}}" ] && [ -n "${{secrets.PUBLIC_REGISTRY_OWNER}}" ] && [ -n "${{secrets.PUBLIC_REGISTRY_USERNAME}}" ] && [ -n "${{secrets.PUBLIC_REGISTRY_TOKEN}}" ]; then
            docker login ${{vars.PUBLIC_REGISTRY_SERVER}} -u ${{secrets.PUBLIC_REGISTRY_USERNAME}} --password-stdin <<< "${{secrets.PUBLIC_REGISTRY_TOKEN}}"
            docker buildx imagetools create -t ${{vars.PUBLIC_REGISTRY_SERVER}}/${{secrets.PUBLIC_REGISTRY_OWNER}}/${APP_NAME}:${APP_VERSION} ${{vars.REGISTRY_SERVER}}/${APP_NAME}:${APP_VERSION} || echo "WARNING: push to public registry failed"
          fi

          # 调用部署脚本，将应用部署到目标服务器（可选）
          /home/gitea/runner/deploy/deploy-registry-app.sh ${APP_NAME} ${APP_VERSION} ${APP_PORT}
```

---

## 2. Java-Actions

{module-name}.yml

```yaml
name: {module-name}
on:
  push:
    branches: [main]
    paths: ['{module-path}/**']

env:
  MODULE_PATH: {module-path}
  APP_NAME: {module-name}
  APP_PORT: {app-port}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # 检出代码仓库
      - uses: actions/checkout@v4

      # 配置Java环境（BellSoft Liberica JDK 25），启用Maven依赖缓存
      - uses: actions/setup-java@v4
        with:
          distribution: liberica
          java-version: '25'
          cache: maven

      # 注册QEMU多架构支持（ARM64模拟）
      - uses: docker/setup-qemu-action@v3
      # 创建Docker Buildx多架构构建器
      - uses: docker/setup-buildx-action@v3

      # 登录私有Docker Registry（仅当REGISTRY_SERVER已配置时）
      - uses: docker/login-action@v3
        if: vars.REGISTRY_SERVER != ''
        with:
          registry: ${{ vars.REGISTRY_SERVER }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_TOKEN }}

      # Maven构建，跳过测试
      - name: Maven build
        working-directory: ${{ env.MODULE_PATH }}
        run: mvn clean package -U -Dmaven.test.skip=true

      # 从pom.xml提取项目版本号，输出到后续步骤
      - name: Get version
        id: ver
        working-directory: ${{ env.MODULE_PATH }}
        run: echo "v=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)" >> "$GITHUB_OUTPUT"

      # 构建多架构镜像并推送到私有Registry（同时打版本标签和latest标签）
      - uses: docker/build-push-action@v6
        working-directory: ${{ env.MODULE_PATH }}
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          provenance: false
          push: true
          tags: |
            ${{ vars.REGISTRY_SERVER }}/${{ env.APP_NAME }}:${{ steps.ver.outputs.v }}
            ${{ vars.REGISTRY_SERVER }}/${{ env.APP_NAME }}:latest

      # 将镜像同步推送到公共Registry（可选，失败不影响流水线）
      - name: Push to public registry
        if: vars.PUBLIC_REGISTRY_SERVER != ''
        working-directory: ${{ env.MODULE_PATH }}
        run: |
          docker login ${{ vars.PUBLIC_REGISTRY_SERVER }} -u ${{ secrets.PUBLIC_REGISTRY_USERNAME }} --password-stdin <<< "${{ secrets.PUBLIC_REGISTRY_TOKEN }}"
          docker buildx imagetools create \
            -t ${{ vars.PUBLIC_REGISTRY_SERVER }}/${{ secrets.PUBLIC_REGISTRY_OWNER }}/${{ env.APP_NAME }}:${{ steps.ver.outputs.v }} \
            ${{ vars.REGISTRY_SERVER }}/${{ env.APP_NAME }}:${{ steps.ver.outputs.v }} || true
```

---

## 3. Web-Shell

{module-name}.yml

```yaml
name: {module-name}
on:
  push:
    branches: [main]
    paths: ['{module-path}/**']

env:
  MODULE_PATH: {module-path}
  APP_NAME: {module-name}
  APP_PORT: {app-port}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: build & push
        run: |
          # 加载用户环境变量（Node.js等）
          source ~/.profile

          # 通过gitea.token认证克隆仓库，自动适配http/https协议
          GIT_SERVER=${{gitea.server_url}}
          git clone -q ${GIT_SERVER%%://*}://gitea:${{gitea.token}}@${GIT_SERVER#*://}/${{gitea.repository}}.git .
          cd $MODULE_PATH

          # 安装依赖并构建前端生产包
          pnpm install --frozen-lockfile
          pnpm build:prod
          # 从package.json提取项目版本号
          APP_VERSION=$(node -p "require('./package.json').version")

          # 注册QEMU多架构支持（ARM64模拟），已注册则跳过
          [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
          # 创建或复用buildx多架构构建器，使用buildkitd.toml中的镜像加速配置
          docker buildx use multiarch 2>/dev/null || docker buildx create --use --name multiarch --driver docker-container --driver-opt network=host --config /etc/docker/buildkitd.toml --platform linux/amd64,linux/arm64

          # 登录私有Docker Registry
          if [ -n "${{secrets.REGISTRY_USERNAME}}" ] && [ -n "${{secrets.REGISTRY_TOKEN}}" ]; then
            docker login ${{vars.REGISTRY_SERVER}} -u ${{secrets.REGISTRY_USERNAME}} --password-stdin <<< "${{secrets.REGISTRY_TOKEN}}"
          fi
          # 构建多架构镜像并推送到私有Registry
          docker buildx build --platform linux/amd64,linux/arm64 --provenance=false \
            -t ${{vars.REGISTRY_SERVER}}/${APP_NAME}:${APP_VERSION} --push .

          # 调用部署脚本，将应用部署到目标服务器（可选）
          /home/gitea/runner/deploy/deploy-registry-app.sh ${APP_NAME} ${APP_VERSION} ${APP_PORT}
```

---

## 4. Web-Actions

{module-name}.yml

```yaml
name: {module-name}
on:
  push:
    branches: [main]
    paths: ['{module-path}/**']

env:
  MODULE_PATH: {module-path}
  APP_NAME: {module-name}
  APP_PORT: {app-port}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # 检出代码仓库
      - uses: actions/checkout@v4

      # 配置Node.js 20环境，启用npm依赖缓存
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: pnpm
          cache-dependency-path: ${{ env.MODULE_PATH }}/pnpm-lock.yaml

      # 注册QEMU多架构支持（ARM64模拟）
      - uses: docker/setup-qemu-action@v3
      # 创建Docker Buildx多架构构建器
      - uses: docker/setup-buildx-action@v3

      # 登录私有Docker Registry（仅当REGISTRY_SERVER已配置时）
      - uses: docker/login-action@v3
        if: vars.REGISTRY_SERVER != ''
        with:
          registry: ${{ vars.REGISTRY_SERVER }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_TOKEN }}

      # 安装依赖并构建前端生产包
      - name: Build
        working-directory: ${{ env.MODULE_PATH }}
        run: |
          pnpm install --frozen-lockfile
          pnpm build:prod

      # 从package.json提取项目版本号，输出到后续步骤
      - name: Get version
        id: ver
        working-directory: ${{ env.MODULE_PATH }}
        run: echo "v=$(node -p 'require(\"./package.json\").version')" >> "$GITHUB_OUTPUT"

      # 构建多架构镜像并推送到私有Registry（同时打版本标签和latest标签）
      - uses: docker/build-push-action@v6
        working-directory: ${{ env.MODULE_PATH }}
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          provenance: false
          push: true
          tags: |
            ${{ vars.REGISTRY_SERVER }}/${{ env.APP_NAME }}:${{ steps.ver.outputs.v }}
            ${{ vars.REGISTRY_SERVER }}/${{ env.APP_NAME }}:latest
```

---

## 5. UniApp-Shell

{module-name}.yml

```yaml
name: {module-name}
on:
  push:
    branches: [main]
    paths: ['{module-path}/**']

env:
  MODULE_PATH: {module-path}
  APP_NAME: {module-name}
  APP_PORT: {app-port}

jobs:
  build-h5:
    runs-on: ubuntu-latest
    env:
    steps:
      - name: build & push
        run: |
          # 加载用户环境变量（Node.js等）
          source ~/.profile

          # 通过gitea.token认证克隆仓库，自动适配http/https协议
          GIT_SERVER=${{gitea.server_url}}
          git clone -q ${GIT_SERVER%%://*}://gitea:${{gitea.token}}@${GIT_SERVER#*://}/${{gitea.repository}}.git .
          cd $MODULE_PATH

          # 安装依赖并构建H5生产包
          pnpm install --frozen-lockfile
          pnpm build:h5
          # 从package.json提取项目版本号
          APP_VERSION=$(node -p "require('./package.json').version")

          # 注册QEMU多架构支持（ARM64模拟），已注册则跳过
          [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
          # 创建或复用buildx多架构构建器，使用buildkitd.toml中的镜像加速配置
          docker buildx use multiarch 2>/dev/null || docker buildx create --use --name multiarch --driver docker-container --driver-opt network=host --config /etc/docker/buildkitd.toml --platform linux/amd64,linux/arm64

          # 登录私有Docker Registry
          if [ -n "${{secrets.REGISTRY_USERNAME}}" ] && [ -n "${{secrets.REGISTRY_TOKEN}}" ]; then
            docker login ${{vars.REGISTRY_SERVER}} -u ${{secrets.REGISTRY_USERNAME}} --password-stdin <<< "${{secrets.REGISTRY_TOKEN}}"
          fi
          # 构建多架构镜像并推送到私有Registry
          docker buildx build --platform linux/amd64,linux/arm64 --provenance=false \
            -t ${{vars.REGISTRY_SERVER}}/${APP_NAME}:${APP_VERSION} --push .

          # 调用部署脚本，将H5应用部署到目标服务器（可选）
          /home/gitea/runner/deploy/deploy-registry-app.sh ${APP_NAME} ${APP_VERSION} ${APP_PORT}

  build-mp-weixin:
    runs-on: ubuntu-latest
    env:
      APP_NAME: {module-name}-mp-weixin
    steps:
      - name: build
        run: |
          # 通过gitea.token认证克隆仓库
          git clone -q ${{gitea.server_url}}/${{gitea.repository}}.git .
          cd $MODULE_PATH

          # 安装依赖并构建微信小程序包
          pnpm install --frozen-lockfile
          pnpm build:mp-weixin
          # 从package.json提取项目版本号
          APP_VERSION=$(node -p "require('./package.json').version")

          # 将小程序构建产物打包为tar.gz归档文件
          tar -czf "/tmp/${APP_NAME}-${APP_VERSION}.tar.gz" -C dist/build/mp-weixin .
          echo "Built: ${APP_NAME}-${APP_VERSION}.tar.gz"
          echo "微信小程序需通过微信开发者工具上传，CI 仅产出构建产物"
```

---

## 6. UniApp-Actions

{module-name}.yml

```yaml
name: {module-name}
on:
  push:
    branches: [main]
    paths: ['{module-path}/**']

env:
  MODULE_PATH: {module-path}
  APP_NAME: {module-name}-h5
  APP_PORT: {app-port}

jobs:
  build-h5:
    runs-on: ubuntu-latest
    steps:
      # 检出代码仓库
      - uses: actions/checkout@v4

      # 配置Node.js 20环境，启用npm依赖缓存
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: pnpm
          cache-dependency-path: ${{ env.MODULE_PATH }}/pnpm-lock.yaml

      # 注册QEMU多架构支持（ARM64模拟）
      - uses: docker/setup-qemu-action@v3
      # 创建Docker Buildx多架构构建器
      - uses: docker/setup-buildx-action@v3

      # 登录私有Docker Registry（仅当REGISTRY_SERVER已配置时）
      - uses: docker/login-action@v3
        if: vars.REGISTRY_SERVER != ''
        with:
          registry: ${{ vars.REGISTRY_SERVER }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_TOKEN }}

      # 安装依赖并构建H5生产包
      - name: Build H5
        working-directory: ${{ env.MODULE_PATH }}
        run: |
          pnpm install --frozen-lockfile
          pnpm build:h5

      # 从package.json提取项目版本号，输出到后续步骤
      - name: Get version
        id: ver
        working-directory: ${{ env.MODULE_PATH }}
        run: echo "v=$(node -p 'require(\"./package.json\").version')" >> "$GITHUB_OUTPUT"

      # 构建多架构镜像并推送到私有Registry（同时打版本标签和latest标签）
      - uses: docker/build-push-action@v6
        working-directory: ${{ env.MODULE_PATH }}
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          provenance: false
          push: true
          tags: |
            ${{ vars.REGISTRY_SERVER }}/${{ env.APP_NAME }}:${{ steps.ver.outputs.v }}
            ${{ vars.REGISTRY_SERVER }}/${{ env.APP_NAME }}:latest

  build-mp-weixin:
    runs-on: ubuntu-latest
    steps:
      # 检出代码仓库
      - uses: actions/checkout@v4

      # 配置Node.js 20环境，启用npm依赖缓存
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: pnpm
          cache-dependency-path: ${{ env.MODULE_PATH }}/pnpm-lock.yaml

      # 安装依赖并构建微信小程序包
      - name: Build WeChat Mini Program
        working-directory: ${{ env.MODULE_PATH }}
        run: |
          pnpm install --frozen-lockfile
          pnpm build:mp-weixin

      # 从package.json提取项目版本号，输出到后续步骤
      - name: Get version
        id: ver
        working-directory: ${{ env.MODULE_PATH }}
        run: echo "v=$(node -p 'require(\"./package.json\").version')" >> "$GITHUB_OUTPUT"

      # 上传小程序构建产物为Artifact，保留30天
      - uses: actions/upload-artifact@v4
        with:
          name: {module-name}-mp-weixin-${{ steps.ver.outputs.v }}
          path: ${{ env.MODULE_PATH }}/dist/build/mp-weixin/
          retention-days: 30
```

---

## Shell vs Actions 差异对照

| 特性 | Shell 模式 | Actions 模式 |
|------|-----------|-------------|
| 适用平台 | Gitea | Gitea / GitHub |
| 环境加载 | `source ~/.profile` | `actions/setup-*` |
| 检出方式 | `git clone` + `gitea.token`认证，自动适配http/https | `actions/checkout@v4` |
| 变量引用 | `${{vars.XXX}}` 无空格 | `${{ vars.XXX }}` 有空格 |
| 密钥引用 | `${{secrets.XXX}}` 无空格 | `${{ secrets.XXX }}` 有空格 |
| Java环境 | Runner预装 | `actions/setup-java@v4` |
| Node环境 | Runner预装 | `actions/setup-node@v4` |
| QEMU | 手动 `docker run multiarch/qemu-user-static` | `docker/setup-qemu-action@v3` |
| Buildx | 手动 `docker buildx create` | `docker/setup-buildx-action@v3` |
| Docker登录 | Shell `docker login` | `docker/login-action@v3` |
| Docker构建 | Shell `docker buildx build` | `docker/build-push-action@v6` |
| 小程序产物 | `tar -czf` 打包 | `actions/upload-artifact@v4` |
| 部署 | `deploy-registry-app.sh` | 无（仅推送镜像） |
| Nginx基础镜像 | `192.168.88.21:5000/nginx:stable-alpine`（私有Registry） | `nginx:stable-alpine`（Docker Hub） |
| 版本输出 | Shell变量 `APP_VERSION` | `$GITHUB_OUTPUT` + `steps.ver.outputs.v` |
