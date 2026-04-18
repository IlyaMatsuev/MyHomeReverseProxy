#!/bin/bash

# This script builds and publishes the reverse-proxy multi-arch (linux/amd64 + linux/arm64)
# Docker image to Docker Hub under the :latest tag. Use it as a manual fallback when the
# GitHub Actions "Publish Package" workflow (.github/workflows/publish.yaml) is unavailable.

# Prerequisites:
#  - docker with buildx (any recent Docker Desktop / Docker Engine v20.10+)
#  - qemu/binfmt set up for cross-platform builds (one-time setup):
#      docker run --privileged --rm tonistiigi/binfmt --install all
#  - Logged in to Docker Hub:
#      docker login -u <username>

# The script need to have executable permissions:
# chmod +x ./scripts/docker/publish.sh

# Usage Example:
# $ ./scripts/docker/publish.sh <docker_username>
# Or set DOCKER_USERNAME in the environment:
# $ DOCKER_USERNAME=<docker_username> ./scripts/docker/publish.sh

set -euo pipefail

DOCKER_REGISTRY="docker.io"
DOCKER_USERNAME="ilyamatsuev"
DOCKER_IMAGE_NAME="reverse-proxy"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

IMAGE="$DOCKER_REGISTRY/$DOCKER_USERNAME/$DOCKER_IMAGE_NAME:latest"
BUILDER="reverse-proxy-publish"

if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
  docker buildx create --name "$BUILDER" --driver docker-container >/dev/null
fi

docker buildx build \
  --builder "$BUILDER" \
  --platform linux/amd64,linux/arm64 \
  --tag "$IMAGE" \
  --push \
  "$PROJECT_DIR"

echo "Published $IMAGE"
