# Docker Kylin

该项目将银河麒麟 ISO 转换为 Docker 基础镜像，并提供 GitHub Actions 自动发布到 Docker Hub。它支持 `amd64`、`arm64`、`loongarch64`、`mips64el` 和 `sw64` 架构。

## 工作原理

该项目使用 GitHub Actions 工作流自动下载 ISO、构建 Docker 镜像、验证它们并发布到 Docker Hub。

`scripts/build.sh` 脚本已重构为模块化函数，以提高可读性和可维护性。

工作流在 `.github/workflows/docker-publish.yml` 文件中定义，包含以下步骤：

1.  **下载 ISO：** 工作流运行 `scripts/download-isos.sh` 脚本，从 `iso_urls.txt` 文件中指定的 URL 下载 ISO。
2.  **构建 Docker 镜像：** 工作流运行 `scripts/build.sh` 脚本，从下载的 ISO 构建 Docker 镜像。
3.  **验证 Docker 镜像：** 工作流运行 `scripts/verify-image.sh` 脚本，对构建的 Docker 镜像执行基本验证。
4.  **发布到 Docker Hub：** 工作流将验证后的 Docker 镜像推送到 Docker Hub。

## 使用方法

要使用此项目，您可以分叉它或将其用作模板。您需要在 GitHub 仓库设置中配置以下密钥：

- `DOCKERHUB_USERNAME`：您的 Docker Hub 用户名。
- `DOCKERHUB_TOKEN`：您的 Docker Hub 访问令牌。

您可以通过编辑 `iso_urls.txt` 文件来自定义要下载的 ISO 列表。

### 自定义 Docker 镜像标签前缀

默认情况下，Docker 镜像使用 `triatk/kylin` 前缀进行标记。您可以通过修改 `.github/workflows/docker-publish.yml` 文件中的 `DOCKER_IMAGE_PREFIX` 环境变量来自定义此前缀。

例如，要将前缀更改为 `myusername/myrepo`：

```yaml
    - name: Build and Verify Docker images
      env:
        DOCKER_IMAGE_PREFIX: myusername/myrepo
      run: |
        # The build script requires sudo, so we need to run it with sudo
        # and make sure the environment variables are passed.
        sudo -E ./scripts/build.sh
```

## 贡献

欢迎贡献！请随时提交拉取请求。
