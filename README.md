
# Docker Kylin

This project converts custom Debian-based Linux distro ISOs to Docker base images and provides a GitHub Action to automatically publish them to Docker Hub.

## Prerequisites

- One or more custom Debian-based Linux distro ISO files in the `iso` directory.
- Docker installed on your local machine.
- `sudo` privileges to mount the ISO files.

## Usage

1. **Place your ISO files in the `iso` directory or any of its subdirectories.**

2. **Run the build script:**

   ```bash
   sudo ./scripts/build.sh
   ```

   The script will automatically find all ISO files, determine the branch (e.g., `server`, `desktop`) and architecture (e.g., `amd64`, `arm64`) from each filename, and build Docker images with tags in the format `triatk/kylin:<branch>-<arch>`.

## GitHub Actions

This project includes a GitHub Actions workflow to automatically build and publish the Docker images to Docker Hub.

To use the workflow, you need to configure the following secrets in your GitHub repository settings:

- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: Your Docker Hub access token.

## Contributing

Contributions are welcome! Please feel free to submit a pull request.
