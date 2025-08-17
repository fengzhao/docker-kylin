
# This Dockerfile builds a base image from a custom Debian-based Linux distro ISO.

# Stage 1: Mount the ISO and extract the root filesystem.
# This stage is performed outside of this Dockerfile by a build script.
# The build script will mount the ISO and copy the root filesystem to a directory,
# which will then be used as the context for the Docker build.

# Stage 2: Create the Docker image from the extracted root filesystem.
FROM scratch

# Copy the extracted root filesystem into the Docker image.
COPY . /

# Set the command to run when the container starts.
CMD ["/bin/bash"]
