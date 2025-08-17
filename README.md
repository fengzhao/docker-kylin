# Docker Kylin

[English](README.md) | [简体中文](README_zh.md)

This project converts KylinOS ISOs to Docker base images and provides a GitHub Action to automatically publish them to Docker Hub. It supports `amd64`, `arm64`, `loongarch64`, `mips64el`, and `sw64` architectures.

## How it works

The project uses a GitHub Actions workflow to automatically download the ISOs, build the Docker images, verify them, and publish them to Docker Hub.

The `scripts/build.sh` script has been refactored into modular functions for better readability and maintainability.

The workflow is defined in the `.github/workflows/docker-publish.yml` file and consists of the following steps:

1.  **Cache ISOs:** The workflow caches the `iso` directory to speed up subsequent runs.
2.  **Download ISOs:** The workflow runs the `scripts/download-isos.sh` script to download any missing ISOs from the URLs specified in the `iso_urls.txt` file.
2.  **Build Docker images:** The workflow runs the `scripts/build.sh` script to build the Docker images from the downloaded ISOs.
3.  **Verify Docker images:** The workflow runs the `scripts/verify-image.sh` script to perform basic verification of the built Docker images.
4.  **Publish to Docker Hub:** The workflow pushes the verified Docker images to Docker Hub.

## Usage

To use this project, you can either fork it or use it as a template. You will need to configure the following secrets in your GitHub repository settings:

- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: Your Docker Hub access token.

You can customize the list of ISOs to be downloaded by editing the `iso_urls.txt` file.

### Customizing the Docker Image Tag Prefix

By default, the Docker images are tagged with the prefix `triatk/kylin`. You can customize this prefix by modifying the `DOCKER_IMAGE_PREFIX` environment variable in the `.github/workflows/docker-publish.yml` file.

For example, to change the prefix to `myusername/myrepo`:

```yaml
    - name: Build and Verify Docker images
      env:
        DOCKER_IMAGE_PREFIX: myusername/myrepo
      run: |
        # The build script requires sudo, so we need to run it with sudo
        # and make sure the environment variables are passed.
        sudo -E ./scripts/build.sh
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request.