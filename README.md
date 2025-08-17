# Docker Kylin

[English](README.md) | [简体中文](README_zh.md)

This project converts KylinOS ISOs to Docker base images and provides a GitHub Action to automatically publish them to Docker Hub. It supports `amd64`, `arm64`, `loongarch64`, `mips64el`, and `sw64` architectures.

## How it works

The project uses a GitHub Actions workflow to automatically download ISOs, build Docker images, verify them, and publish them to Docker Hub. The workflow is triggered on pushes to the `main` branch, but ignores changes to documentation files (`README.md`, `README_zh.md`).

The `scripts/build.sh` script has been refactored into modular functions for better readability and maintainability. It also includes validation to ensure extracted information from ISO filenames conforms to expected patterns, including format validation for version and release date.

The workflow is defined in the `.github/workflows/docker-publish.yml` file and consists of the following steps:

1.  **Cache ISOs:** The workflow caches the `iso` directory to speed up subsequent runs.
2.  **Download and Build ISOs (one by one):** The workflow reads the `iso_urls.txt` file and processes each ISO URL individually. For each ISO:
    *   The `scripts/download-isos.sh` script downloads the ISO.
    *   The `scripts/build.sh` script builds the Docker image from the downloaded ISO. The script will also print a summary of the extracted ISO information and the generated Docker tag for each image.
    *   The `scripts/verify-image.sh` script performs basic verification of the built Docker image.
    *   The verified Docker image is pushed to Docker Hub.
    *   Temporary build files are cleaned up after each ISO to free up disk space.
3.  **Clean up old Docker images (scheduled):** The workflow runs the `scripts/cleanup-docker-images.sh` script periodically (once a week) to remove old Docker images and free up disk space.

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
