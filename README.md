
# Docker Kylin

This project converts a custom Debian-based Linux distro ISO to a Docker base image and provides a GitHub Action to automatically publish it to Docker Hub.

## Prerequisites

- A custom Debian-based Linux distro ISO file in the `iso` directory.
- Docker installed on your local machine.
- `sudo` privileges to mount the ISO file.

## Usage

1. **Place your ISO file in the `iso` directory or any of its subdirectories.**

2. **Run the build script:**

   ```bash
   sudo ./scripts/build.sh
   ```

   The script will automatically find the ISO file, determine the branch (e.g., `server`, `desktop`) and architecture (e.g., `amd64`, `arm64`) from the filename, and build a Docker image with a tag in the format `triatk/kylin:<branch>-<arch>`.

## GitHub Actions

This project includes a GitHub Actions workflow to automatically build and publish the Docker image to Docker Hub.

To use the workflow, you need to configure the following secrets in your GitHub repository settings:

- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: Your Docker Hub access token.

## Contributing

Contributions are welcome! Please feel free to submit a pull request.
