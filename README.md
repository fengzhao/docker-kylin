
# Docker Kylin

This project converts a custom Debian-based Linux distro ISO to a Docker base image and provides a GitHub Action to automatically publish it to Docker Hub.

## Prerequisites

- A custom Debian-based Linux distro ISO file.
- Docker installed on your local machine.
- `sudo` privileges to mount the ISO file.

## Usage

1. **Place your ISO file in the `iso` directory.** The ISO file should be named `custom-distro.iso`.

2. **Run the build script:**

   ```bash
   ./scripts/build.sh
   ```

   This will build a Docker image with the tag `custom-distro:latest`.

## GitHub Actions

This project includes a GitHub Actions workflow to automatically build and publish the Docker image to Docker Hub.

To use the workflow, you need to configure the following secrets in your GitHub repository settings:

- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: Your Docker Hub access token.

## Customization

- **ISO file name:** If your ISO file has a different name, you can change the `ISO_FILE` variable in the `scripts/build.sh` file.
- **Docker image tag:** You can change the Docker image tag in the `scripts/build.sh` and `.github/workflows/docker-publish.yml` files.

## Contributing

Contributions are welcome! Please feel free to submit a pull request.
