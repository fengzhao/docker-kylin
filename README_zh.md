# Docker Kylin

该项目将银河麒麟 ISO 转换为 Docker 基础镜像，并提供 GitHub Actions 自动发布到 Docker Hub。它支持 `amd64`、`arm64`、`loongarch64`、`mips64el` 和 `sw64` 架构。

## 工作原理

该项目使用 GitHub Actions 工作流自动下载 ISO、构建 Docker 镜像、验证它们并发布到 Docker Hub。工作流在推送到 `main` 分支时触发，但会忽略对文档文件（`README.md`、`README_zh.md`）的更改。

`scripts/build.sh` 脚本已重构为模块化函数，以提高可读性和可维护性。它还包含验证功能，以确保从 ISO 文件名中提取的信息符合预期模式，包括版本和发布日期的格式验证。

工作流在 `.github/workflows/docker-publish.yml` 文件中定义，包含以下步骤：

1.  **缓存 ISO：** 工作流缓存 `iso` 目录以加快后续运行。
2.  **下载和构建 ISO（逐个）：** 工作流读取 `iso_urls.txt` 文件并逐个处理每个 ISO URL。对于每个 ISO：
    *   `scripts/download-isos.sh` 脚本下载 ISO。
    *   `scripts/build.sh` 脚本从下载的 ISO 构建 Docker 镜像。该脚本还将打印提取的 ISO 信息和为每个镜像生成的 Docker 标签的摘要。
    *   `scripts/verify-image.sh` 脚本对构建的 Docker 镜像执行基本验证。
    *   验证后的 Docker 镜像被推送到 Docker Hub。
    *   处理完每个 ISO 后，会清理临时构建文件以释放磁盘空间。
3.  **清理旧的 Docker 镜像（计划任务）：** 工作流会定期（每周一次）运行 `scripts/cleanup-docker-images.sh` 脚本，以删除旧的 Docker 镜像并释放磁盘空间。

## 使用方法

要使用此项目，您可以分叉它或将其用作模板。您需要在 GitHub 仓库设置中配置以下密钥：

- `DOCKERHUB_USERNAME`：您的 Docker Hub 用户名。
- `DOCKERHUB_TOKEN`：您的 Docker Hub 访问令牌。

在运行工作流之前，如果使用自托管运行器，请确保已安装 `jq`。对于 GitHub 托管运行器，`jq` 通常是预安装的。

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
