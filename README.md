
# Docker Kylin

This project converts custom Debian-based Linux distro ISOs to Docker base images and provides a GitHub Action to automatically publish them to Docker Hub.

## How it works

The project uses a GitHub Actions workflow to automatically download the ISOs, build the Docker images, verify them, and publish them to Docker Hub.

The workflow is defined in the `.github/workflows/docker-publish.yml` file and consists of the following steps:

1.  **Download ISOs:** The workflow runs the `scripts/download-isos.sh` script to download the ISOs from the URLs specified in the `iso_urls.txt` file.
2.  **Build Docker images:** The workflow runs the `scripts/build.sh` script to build the Docker images from the downloaded ISOs.
3.  **Verify Docker images:** The workflow runs the `scripts/verify-image.sh` script to perform basic verification of the built Docker images.
4.  **Publish to Docker Hub:** The workflow pushes the verified Docker images to Docker Hub.

## Usage

To use this project, you can either fork it or use it as a template. You will need to configure the following secrets in your GitHub repository settings:

- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: Your Docker Hub access token.

You can customize the list of ISOs to be downloaded by editing the `iso_urls.txt` file.

## Contributing

Contributions are welcome! Please feel free to submit a pull request.
